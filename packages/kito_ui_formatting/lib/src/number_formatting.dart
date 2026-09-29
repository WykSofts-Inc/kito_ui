// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:intl/intl.dart';

/// A true minus sign (U+2212), used for signed amounts and changes.
const kitoMinus = '−';

/// Picks a locale intl knows for numbers, falling back to English.
String kitoNumberLocale(String? locale) => Intl.verifiedLocale(
    locale ?? Intl.getCurrentLocale(), NumberFormat.localeExists,
    onFailure: (_) => 'en')!;

/// Rounds [value] half-up to [digits] decimals using its shortest decimal form, so typed
/// amounts like 1.005 round the way people expect (1.01), then returns the digits as text
/// with no grouping ("1234.50").
String kitoFixedDecimal(num value, int digits) {
  final v = value.abs();
  final text = v.toString();
  if (v is double && (v.isNaN || v.isInfinite)) return v.toString();
  if (text.contains('e') || text.contains('E')) {
    if (v >= 1) {
      final whole = BigInt.from(v).toString();
      return digits == 0 ? whole : '$whole.${'0' * digits}';
    }
    return v.toStringAsFixed(digits);
  }
  final parts = text.split('.');
  var whole = parts[0];
  var frac = parts.length > 1 ? parts[1] : '';
  if (frac.length <= digits) {
    frac = frac.padRight(digits, '0');
  } else {
    final roundUp = frac.codeUnitAt(digits) >= 0x35; // '5'
    frac = frac.substring(0, digits);
    if (roundUp) {
      final joined = BigInt.parse('$whole$frac') + BigInt.one;
      final s = joined.toString().padLeft(whole.length + digits, '0');
      whole = s.substring(0, s.length - digits);
      frac = s.substring(s.length - digits);
      if (whole.isEmpty) whole = '0';
    }
  }
  return digits == 0 ? whole : '$whole.$frac';
}

/// Adds comma thousands separators to a plain digit string: "1234567.5" → "1,234,567.5".
String kitoGroup(String plain) {
  final parts = plain.split('.');
  final whole = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return parts.length > 1 ? '$buf.${parts[1]}' : buf.toString();
}

/// Numbers for UI: compact, grouped, percent, signed percent and ordinals.
abstract final class KitoNumberFormatting {
  /// "1.2K" / "3.4M" / "2.1B" — for list rows, chart axes and stat tiles. Plain below 1,000; one
  /// decimal at most, with a trailing ".0" dropped. Fixed format, the same on every device.
  static String compact(num value) {
    final sign = value < 0 ? '-' : '';
    var v = value.abs().toDouble();
    const units = ['', 'K', 'M', 'B', 'T'];
    var i = 0;
    while (v >= 1000 && i < units.length - 1) {
      v /= 1000;
      i++;
    }
    var text = _oneDecimal(v);
    // 999,950 rounds to "1000.0K": promote it to "1M".
    if (text == '1000' && i < units.length - 1) {
      text = '1';
      i++;
    }
    return '$sign$text${units[i]}';
  }

  static String _oneDecimal(double v) {
    final t = kitoFixedDecimal(v, 1);
    return t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
  }

  /// "47K", "4,7 k", "47 elfu" — compact in the user's [locale], via intl.
  static String compactLocalized(num value, {String? locale}) =>
      NumberFormat.compact(locale: kitoNumberLocale(locale)).format(value);

  /// "1,250,000" / "1,250.50" — fixed comma grouping and a dot, whatever the device region.
  static String grouped(num value, {int fractionDigits = 0}) {
    final sign = value < 0 &&
            kitoFixedDecimal(value, fractionDigits).contains(RegExp('[1-9]'))
        ? '-'
        : '';
    return sign + kitoGroup(kitoFixedDecimal(value, fractionDigits));
  }

  /// "1,250.5" / "1 250,5" / "1.250,5" — a number in the user's [locale].
  static String decimal(num value, {int? fractionDigits, String? locale}) {
    final f = NumberFormat.decimalPattern(kitoNumberLocale(locale));
    if (fractionDigits != null) {
      f
        ..minimumFractionDigits = fractionDigits
        ..maximumFractionDigits = fractionDigits;
    }
    return f.format(value);
  }

  /// "85%" from 0.847 — a fraction as a percentage in [locale].
  static String percent(num fraction,
      {int fractionDigits = 0, String? locale}) {
    final f = NumberFormat.percentPattern(kitoNumberLocale(locale))
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return f.format(fraction);
  }

  /// "+12.5%" / "−3.2%" / "0.0%" from a fraction — the sign always shows so a change reads as a
  /// change, with a true minus. Zero after rounding has no sign.
  static String signedPercent(num fraction,
      {int fractionDigits = 1, String? locale}) {
    final digits = fractionDigits < 0 ? 0 : fractionDigits;
    final magnitude =
        percent(fraction.abs(), fractionDigits: digits, locale: locale);
    final isZero = !kitoFixedDecimal(fraction.abs() * 100, digits)
        .contains(RegExp('[1-9]'));
    final sign = isZero ? '' : (fraction > 0 ? '+' : kitoMinus);
    return '$sign$magnitude';
  }

  /// "1st", "2nd", "3rd", "11th", "22nd" — English ordinals for ranks and streaks.
  static String ordinal(int value) {
    final tens = value.abs() % 100;
    final ones = value.abs() % 10;
    final suffix = (tens >= 11 && tens <= 13)
        ? 'th'
        : switch (ones) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
    return '$value$suffix';
  }
}

/// Which way a change went — drives the arrow and colour of `KitoFormattedChangeBadge`.
enum KitoFormattedTrend {
  /// Went up.
  up,

  /// Went down.
  down,

  /// Stayed (within tolerance).
  flat;

  /// The trend of [change]; anything within [tolerance] of zero is flat, so "+0.0%" never shows
  /// a green arrow.
  static KitoFormattedTrend of(num change, {double tolerance = 0.0005}) {
    if (change > tolerance) return up;
    if (change < -tolerance) return down;
    return flat;
  }
}
