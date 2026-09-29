// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:intl/intl.dart';

import 'number_formatting.dart';

/// The currencies Kito's flows use most — Kenya-weighted, M-Pesa-adjacent — plus common
/// majors. [KitoMoneyFormatting.localizedCode] takes any ISO 4217 code.
enum KitoCurrency {
  /// Kenyan shilling.
  kes('KES', 'KSh', '🇰🇪'),

  /// US dollar.
  usd('USD', r'$', '🇺🇸'),

  /// Euro.
  eur('EUR', '€', '🇪🇺'),

  /// Pound sterling.
  gbp('GBP', '£', '🇬🇧'),

  /// Nigerian naira.
  ngn('NGN', '₦', '🇳🇬'),

  /// South African rand.
  zar('ZAR', 'R', '🇿🇦'),

  /// Ugandan shilling (no minor units).
  ugx('UGX', 'USh', '🇺🇬', 0),

  /// Tanzanian shilling.
  tzs('TZS', 'TSh', '🇹🇿');

  const KitoCurrency(this.code, this.symbol, this.flag, [this.minorUnits = 2]);

  /// The ISO 4217 code, "KES".
  final String code;

  /// The everyday symbol, "KSh".
  final String symbol;

  /// A flag for pickers and chips.
  final String flag;

  /// Digits after the decimal point in everyday use.
  final int minorUnits;

  /// The prefix before an amount: a space after lettered prefixes ("KES ", "KSh "), none after
  /// glyphs ("$", "€").
  String prefix(KitoCurrencyDisplay display) {
    final text = display == KitoCurrencyDisplay.code ? code : symbol;
    return text.runes.length > 1 ? '$text ' : text;
  }

  /// The currency for an ISO code, or null.
  static KitoCurrency? fromCode(String code) {
    final upper = code.toUpperCase();
    for (final c in values) {
      if (c.code == upper) return c;
    }
    return null;
  }
}

/// Whether an amount leads with the ISO code ("KES 1,250") or the symbol ("KSh 1,250").
enum KitoCurrencyDisplay {
  /// "KES 1,250".
  code,

  /// "KSh 1,250".
  symbol,
}

/// When cents are shown.
enum KitoMoneyCents {
  /// Only when there are some: "KES 1,250" but "KES 1,250.50".
  auto,

  /// Always the currency's minor units: "KES 1,250.00".
  always,

  /// Rounded to whole units: "KES 1,251".
  never,
}

/// Amounts that read the same on every device — fixed "1,234.56" grouping, so receipts, carts
/// and screenshots don't change with the phone's region. Use [localized] for the user's own
/// locale.
abstract final class KitoMoneyFormatting {
  /// "KES 1,250.50", "KSh 1,250", "$42".
  static String string(
    num amount,
    KitoCurrency currency, {
    KitoCurrencyDisplay display = KitoCurrencyDisplay.code,
    KitoMoneyCents cents = KitoMoneyCents.auto,
  }) {
    final d = digits(amount, currency, cents: cents);
    final sign = amount < 0 && d.contains(RegExp('[1-9]')) ? '-' : '';
    return sign + currency.prefix(display) + d;
  }

  /// "+KES 500" / "−KES 1,200" — transaction lists and balance changes.
  static String signed(
    num amount,
    KitoCurrency currency, {
    KitoCurrencyDisplay display = KitoCurrencyDisplay.code,
    KitoMoneyCents cents = KitoMoneyCents.auto,
  }) {
    final d = digits(amount, currency, cents: cents);
    final zero = !d.contains(RegExp('[1-9]'));
    final sign = zero ? '' : (amount > 0 ? '+' : kitoMinus);
    return sign + currency.prefix(display) + d;
  }

  /// "KES 1.2M", "$3.4K" — stat tiles and chart labels.
  static String compact(
    num amount,
    KitoCurrency currency, {
    KitoCurrencyDisplay display = KitoCurrencyDisplay.code,
  }) {
    final sign = amount < 0 ? '-' : '';
    return sign +
        currency.prefix(display) +
        KitoNumberFormatting.compact(amount.abs());
  }

  /// Just the number: "1,250.50".
  static String digits(num amount, KitoCurrency currency,
      {KitoMoneyCents cents = KitoMoneyCents.auto}) {
    final fraction = switch (cents) {
      KitoMoneyCents.always => currency.minorUnits,
      KitoMoneyCents.never => 0,
      KitoMoneyCents.auto =>
        _hasCents(amount, currency.minorUnits) ? currency.minorUnits : 0,
    };
    return kitoGroup(kitoFixedDecimal(amount, fraction));
  }

  static bool _hasCents(num amount, int minorUnits) {
    if (minorUnits == 0) return false;
    final fixed = kitoFixedDecimal(amount, minorUnits);
    final frac = fixed.split('.').last;
    return frac.contains(RegExp('[1-9]'));
  }

  /// "Ksh 1,250.50", "1.250,50 €" — in the user's [locale] via intl, using [currency]'s symbol.
  static String localized(num amount, KitoCurrency currency,
          {String? locale, int? decimalDigits}) =>
      NumberFormat.currency(
        locale: kitoNumberLocale(locale),
        name: currency.code,
        symbol: currency.prefix(KitoCurrencyDisplay.symbol),
        decimalDigits: decimalDigits ?? currency.minorUnits,
      ).format(amount);

  /// Any ISO 4217 [code] in the user's [locale], with intl's own symbol: "¥1,250", "CHF 12.00".
  static String localizedCode(num amount, String code,
          {String? locale, int? decimalDigits}) =>
      NumberFormat.simpleCurrency(
        locale: kitoNumberLocale(locale),
        name: code.toUpperCase(),
        decimalDigits: decimalDigits,
      ).format(amount);

  /// "KSh 1.2K" in the user's [locale], via intl.
  static String localizedCompact(num amount, KitoCurrency currency,
          {String? locale}) =>
      NumberFormat.compactCurrency(
        locale: kitoNumberLocale(locale),
        name: currency.code,
        symbol: currency.prefix(KitoCurrencyDisplay.symbol),
      ).format(amount);
}

/// Money shortcuts on numbers.
extension KitoMoneyNum on num {
  /// "KES 1,250.50" — fixed, device-independent; see [KitoMoneyFormatting.string].
  String kitoAmount(KitoCurrency currency,
          {KitoCurrencyDisplay display = KitoCurrencyDisplay.code,
          KitoMoneyCents cents = KitoMoneyCents.auto}) =>
      KitoMoneyFormatting.string(this, currency,
          display: display, cents: cents);

  /// "KES 1.2M" — fixed compact amount.
  String kitoCompactAmount(KitoCurrency currency,
          {KitoCurrencyDisplay display = KitoCurrencyDisplay.code}) =>
      KitoMoneyFormatting.compact(this, currency, display: display);

  /// "Ksh 1,250.50" in the user's locale.
  String kitoLocalizedAmount(KitoCurrency currency, {String? locale}) =>
      KitoMoneyFormatting.localized(this, currency, locale: locale);
}
