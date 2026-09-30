// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

/// The currency every checkout widget uses unless you pass another: Kenyan shillings.
const String kitoCheckoutDefaultCurrency = 'KES';

/// Money in the checkout is always a whole number of minor units (cents) plus an ISO 4217 code,
/// so there's no floating-point drift. `125000` with `'KES'` is KES 1,250.
abstract final class KitoCheckoutMoney {
  /// Currencies without minor units in everyday use.
  static const Set<String> zeroDecimalCurrencies = {
    'UGX',
    'JPY',
    'KRW',
    'RWF',
    'BIF',
    'XAF',
    'XOF',
  };

  /// Minor units per major unit: 100 for KES, 1 for UGX.
  static int unitsPerMajor(String currencyCode) =>
      zeroDecimalCurrencies.contains(currencyCode.toUpperCase()) ? 1 : 100;

  /// Cents from a major amount: `fromMajor(1250)` is `125000` for KES.
  static int fromMajor(num major,
          {String currencyCode = kitoCheckoutDefaultCurrency}) =>
      (major * unitsPerMajor(currencyCode)).round();

  /// "KES 1,250", or "KES 1,250.50" when there are cents. [alwaysShowCents] gives "KES 1,250.00".
  /// Negative amounts read "−KES 200" (a true minus sign).
  static String format(
    int cents, {
    String currencyCode = kitoCheckoutDefaultCurrency,
    bool alwaysShowCents = false,
  }) {
    final code = currencyCode.toUpperCase();
    final per = unitsPerMajor(code);
    final negative = cents < 0;
    final abs = cents.abs();
    final major = abs ~/ per;
    final minor = abs % per;
    final grouped = group(major);
    final showCents = per > 1 && (alwaysShowCents || minor != 0);
    final digits =
        showCents ? '$grouped.${minor.toString().padLeft(2, '0')}' : grouped;
    return '${negative ? '−' : ''}$code $digits';
  }

  /// Whole units rounded half up: "KES 1,251" for 125050 cents.
  static String formatWhole(int cents,
          {String currencyCode = kitoCheckoutDefaultCurrency}) =>
      format(roundToWhole(cents, currencyCode: currencyCode),
          currencyCode: currencyCode);

  /// [cents] rounded half away from zero to whole units, still in cents.
  static int roundToWhole(int cents,
      {String currencyCode = kitoCheckoutDefaultCurrency}) {
    final per = unitsPerMajor(currencyCode);
    if (per == 1) return cents;
    final sign = cents < 0 ? -1 : 1;
    final abs = cents.abs();
    return sign * ((abs + per ~/ 2) ~/ per) * per;
  }

  /// "1,250,000".
  static String group(int value) {
    final s = value.abs().toString();
    final out = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  /// [percent] of [cents], rounded half up to the cent. `percentOf(10, 125000)` is `12500`.
  static int percentOf(num percent, int cents) =>
      (cents * percent / 100).round();
}
