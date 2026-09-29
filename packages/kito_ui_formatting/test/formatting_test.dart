// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kito_ui_formatting/kito_ui_formatting.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  tearDown(() => KitoFormattingStrings.provider = null);

  group('decimal rounding and grouping', () {
    test('rounds half up on the decimal form', () {
      expect(kitoFixedDecimal(1.005, 2), '1.01');
      expect(kitoFixedDecimal(2.675, 2), '2.68');
      expect(kitoFixedDecimal(1250, 2), '1250.00');
      expect(kitoFixedDecimal(0.995, 2), '1.00');
      expect(kitoFixedDecimal(999.5, 0), '1000');
      expect(kitoFixedDecimal(-3.14159, 3), '3.142');
      expect(kitoFixedDecimal(1e21, 2), '1000000000000000000000.00');
    });

    test('groups thousands', () {
      expect(kitoGroup('1234567.5'), '1,234,567.5');
      expect(kitoGroup('999'), '999');
      expect(kitoGroup('1000'), '1,000');
    });
  });

  group('numbers', () {
    test('compact', () {
      expect(KitoNumberFormatting.compact(999), '999');
      expect(KitoNumberFormatting.compact(47200), '47.2K');
      expect(KitoNumberFormatting.compact(2100000), '2.1M');
      expect(KitoNumberFormatting.compact(1000), '1K');
      expect(KitoNumberFormatting.compact(1040), '1K');
      expect(KitoNumberFormatting.compact(999950), '1M');
      expect(KitoNumberFormatting.compact(3.4e9), '3.4B');
      expect(KitoNumberFormatting.compact(-1500), '-1.5K');
      expect(KitoNumberFormatting.compact(12.34), '12.3');
    });

    test('grouped is fixed whatever the locale', () {
      expect(KitoNumberFormatting.grouped(1250000), '1,250,000');
      expect(
          KitoNumberFormatting.grouped(1250.5, fractionDigits: 2), '1,250.50');
      expect(KitoNumberFormatting.grouped(-1250.456, fractionDigits: 2),
          '-1,250.46');
      expect(KitoNumberFormatting.grouped(-0.001, fractionDigits: 2), '0.00');
    });

    test('percent and signed percent', () {
      expect(
          KitoNumberFormatting.percent(0.847, fractionDigits: 1, locale: 'en'),
          '84.7%');
      expect(KitoNumberFormatting.percent(0.5, locale: 'en'), '50%');
      expect(KitoNumberFormatting.signedPercent(0.124, locale: 'en'), '+12.4%');
      expect(KitoNumberFormatting.signedPercent(-0.032, locale: 'en'), '−3.2%');
      expect(KitoNumberFormatting.signedPercent(0.00001, locale: 'en'), '0.0%');
      expect(
          KitoNumberFormatting.signedPercent(0.125,
              fractionDigits: 0, locale: 'en'),
          '+13%');
      // Locale digits and separators.
      expect(
          KitoNumberFormatting.percent(0.847, fractionDigits: 1, locale: 'fr'),
          contains(','));
    });

    test('localized decimal and compact', () {
      expect(KitoNumberFormatting.decimal(1250.5, locale: 'en'), '1,250.5');
      expect(
          KitoNumberFormatting.decimal(1250.5, fractionDigits: 2, locale: 'de'),
          '1.250,50');
      expect(
          KitoNumberFormatting.compactLocalized(47200, locale: 'en'), '47.2K');
      expect(KitoNumberFormatting.decimal(3, locale: 'xx_YY'), '3');
    });

    test('ordinals', () {
      expect(
          [1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 101, 111, 112]
              .map(KitoNumberFormatting.ordinal),
          [
            '1st',
            '2nd',
            '3rd',
            '4th',
            '11th',
            '12th',
            '13th',
            '21st',
            '22nd',
            '23rd',
            '101st',
            '111th',
            '112th'
          ]);
    });

    test('trend with tolerance', () {
      expect(KitoFormattedTrend.of(0.1), KitoFormattedTrend.up);
      expect(KitoFormattedTrend.of(-0.1), KitoFormattedTrend.down);
      expect(KitoFormattedTrend.of(0.0001), KitoFormattedTrend.flat);
    });
  });

  group('money', () {
    test('currencies', () {
      expect(KitoCurrency.kes.prefix(KitoCurrencyDisplay.code), 'KES ');
      expect(KitoCurrency.kes.prefix(KitoCurrencyDisplay.symbol), 'KSh ');
      expect(KitoCurrency.usd.prefix(KitoCurrencyDisplay.symbol), r'$');
      expect(KitoCurrency.ugx.minorUnits, 0);
      expect(KitoCurrency.fromCode('kes'), KitoCurrency.kes);
      expect(KitoCurrency.fromCode('XYZ'), isNull);
      expect(KitoCurrency.values.map((c) => c.flag).toSet(), hasLength(8));
    });

    test('fixed amounts with cents on demand', () {
      expect(1250.kitoAmount(KitoCurrency.kes), 'KES 1,250');
      expect(
          1250.5.kitoAmount(KitoCurrency.kes,
              display: KitoCurrencyDisplay.symbol),
          'KSh 1,250.50');
      expect(
          KitoMoneyFormatting.string(1250, KitoCurrency.kes,
              cents: KitoMoneyCents.always),
          'KES 1,250.00');
      expect(
          KitoMoneyFormatting.string(1250.5, KitoCurrency.kes,
              cents: KitoMoneyCents.never),
          'KES 1,251');
      expect(
          KitoMoneyFormatting.string(42, KitoCurrency.usd,
              display: KitoCurrencyDisplay.symbol),
          r'$42');
      expect(
          KitoMoneyFormatting.string(1500.75, KitoCurrency.ugx), 'UGX 1,501');
      expect(KitoMoneyFormatting.string(-99.9, KitoCurrency.kes), '-KES 99.90');
      expect(
          KitoMoneyFormatting.string(1250.001, KitoCurrency.kes), 'KES 1,250');
    });

    test('signed and compact', () {
      expect(KitoMoneyFormatting.signed(500, KitoCurrency.kes), '+KES 500');
      expect(KitoMoneyFormatting.signed(-1200, KitoCurrency.kes), '−KES 1,200');
      expect(KitoMoneyFormatting.signed(0, KitoCurrency.kes), 'KES 0');
      expect(1200000.kitoCompactAmount(KitoCurrency.kes), 'KES 1.2M');
      expect(
          KitoMoneyFormatting.compact(3400, KitoCurrency.usd,
              display: KitoCurrencyDisplay.symbol),
          r'$3.4K');
      expect(
          KitoMoneyFormatting.compact(-1250.5, KitoCurrency.kes), '-KES 1.3K');
    });

    test('localized via intl', () {
      expect(
          KitoMoneyFormatting.localized(1250.5, KitoCurrency.kes,
              locale: 'en_KE'),
          contains('1,250.50'));
      expect(
          KitoMoneyFormatting.localized(1250.5, KitoCurrency.eur, locale: 'de'),
          contains('1.250,50'));
      expect(KitoMoneyFormatting.localizedCode(1250, 'JPY', locale: 'en'),
          contains('1,250'));
      expect(
          KitoMoneyFormatting.localizedCompact(1200000, KitoCurrency.kes,
              locale: 'en'),
          contains('1.2M'));
      expect(1250.5.kitoLocalizedAmount(KitoCurrency.usd, locale: 'en_US'),
          r'$1,250.50');
    });
  });

  group('dates', () {
    final now = DateTime(2026, 9, 29, 14, 30);

    test('relative', () {
      String rel(Duration d, [String locale = 'en']) =>
          KitoDateFormatting.relative(now.add(d), now: now, locale: locale);
      expect(rel(const Duration(seconds: -10)), 'just now');
      expect(rel(const Duration(minutes: -2)), '2 minutes ago');
      expect(rel(const Duration(minutes: -1)), '1 minute ago');
      expect(rel(const Duration(hours: 3)), 'in 3 hours');
      expect(rel(const Duration(days: -1)), 'yesterday');
      expect(rel(const Duration(days: 1)), 'tomorrow');
      expect(rel(const Duration(days: -4)), '4 days ago');
      expect(rel(const Duration(days: -15)), '2 weeks ago');
      expect(rel(const Duration(days: -70)), '2 months ago');
      expect(rel(const Duration(days: -800)), '2 years ago');
      expect(rel(const Duration(minutes: -5), 'sw'), 'dakika 5 zilizopita');
      expect(rel(const Duration(hours: 2), 'sw'), 'baada ya saa 2');
      expect(rel(const Duration(minutes: -5), 'fr'), 'il y a 5 minutes');
    });

    test('abbreviated', () {
      String ab(Duration d) => KitoDateFormatting.abbreviated(now.subtract(d),
          now: now, locale: 'en');
      expect(ab(const Duration(seconds: 20)), 'now');
      expect(ab(const Duration(minutes: 5)), '5m');
      expect(ab(const Duration(hours: 3)), '3h');
      expect(ab(const Duration(days: 2)), '2d');
      expect(ab(const Duration(days: 21)), '3w');
      expect(ab(const Duration(days: 60)), 'Jul 31');
    });

    test('day labels', () {
      String day(int d, [String locale = 'en']) =>
          KitoDateFormatting.dayLabel(now.add(Duration(days: d)),
              now: now, locale: locale);
      expect(day(0), 'Today');
      expect(day(-1), 'Yesterday');
      expect(day(1), 'Tomorrow');
      expect(day(-3), 'Saturday');
      expect(day(-10), 'Sep 19, 2026');
      expect(day(0, 'sw'), 'Leo');
      expect(day(-1, 'fr'), 'Hier');
    });

    test('times, ranges and greetings', () {
      final nine = DateTime(2026, 9, 29, 9);
      expect(KitoDateFormatting.shortTime(nine, locale: 'en'),
          matches(RegExp(r'^9:00\sAM$')));
      final range = KitoDateFormatting.timeRange(
          nine, DateTime(2026, 9, 29, 10, 30),
          locale: 'en');
      expect(range, startsWith('9:00 – 10:30'));
      expect(range, endsWith('AM'));
      expect('AM'.allMatches(range), hasLength(1));
      final across = KitoDateFormatting.timeRange(
          DateTime(2026, 9, 29, 11), DateTime(2026, 9, 29, 13),
          locale: 'en');
      expect(across, contains('AM'));
      expect(across, contains('PM'));
      expect(KitoDateFormatting.timeRange(nine, nine, locale: 'en'),
          KitoDateFormatting.shortTime(nine, locale: 'en'));
      expect(KitoDateFormatting.greeting(at: nine), 'Good morning');
      expect(KitoDateFormatting.greeting(at: DateTime(2026, 1, 1, 13)),
          'Good afternoon');
      expect(
          KitoDateFormatting.greeting(
              at: DateTime(2026, 1, 1, 22), locale: 'sw'),
          'Habari za jioni');
      expect(KitoDateFormatting.mediumDate(nine, locale: 'en'), 'Sep 29, 2026');
      expect(KitoDateFormatting.full(nine, locale: 'en'),
          startsWith('September 29, 2026'));
      // An unknown locale falls back instead of throwing.
      expect(KitoDateFormatting.mediumDate(nine, locale: 'zz'), 'Sep 29, 2026');
    });
  });

  group('durations, sizes, distances', () {
    test('durations', () {
      expect(KitoDurationFormatting.short(const Duration(seconds: 45)), '45s');
      expect(
          KitoDurationFormatting.short(const Duration(minutes: 12, seconds: 5)),
          '12m 5s');
      expect(
          KitoDurationFormatting.short(const Duration(seconds: 3900)), '1h 5m');
      expect(
          KitoDurationFormatting.short(
              const Duration(days: 2, hours: 3, minutes: 9)),
          '2d 3h');
      expect(KitoDurationFormatting.short(const Duration(hours: 1, seconds: 4)),
          '1h');
      expect(KitoDurationFormatting.short(Duration.zero), '0s');
      expect(KitoDurationFormatting.short(const Duration(seconds: -90)),
          '-1m 30s');
      expect(
          KitoDurationFormatting.clock(const Duration(seconds: 245)), '4:05');
      expect(KitoDurationFormatting.clock(const Duration(seconds: 3729)),
          '1:02:09');
      expect(
          KitoDurationFormatting.spelledOut(const Duration(seconds: 3900),
              locale: 'en'),
          '1 hour, 5 minutes');
      expect(
          KitoDurationFormatting.spelledOut(
              const Duration(days: 1, hours: 2, minutes: 3),
              maximumUnits: 3,
              locale: 'en'),
          '1 day, 2 hours, 3 minutes');
      expect(
          KitoDurationFormatting.spelledOut(const Duration(minutes: 2),
              locale: 'sw'),
          'dakika 2');
      expect(KitoDurationFormatting.spelledOut(Duration.zero, locale: 'en'),
          '0 seconds');
    });

    test('file sizes', () {
      expect(KitoFileSizeFormatting.string(1), '1 byte');
      expect(KitoFileSizeFormatting.string(845), '845 bytes');
      expect(KitoFileSizeFormatting.string(12400), '12 KB');
      expect(KitoFileSizeFormatting.string(1200000), '1.2 MB');
      expect(KitoFileSizeFormatting.string(3456000000), '3.46 GB');
      expect(KitoFileSizeFormatting.string(2000000), '2 MB');
      expect(KitoFileSizeFormatting.string(1048576, binary: true), '1 MB');
      expect(KitoFileSizeFormatting.progress(1200000, 4500000, locale: 'en'),
          '1.2 MB of 4.5 MB');
    });

    test('distances', () {
      expect(KitoDistanceFormatting.string(42), '40 m');
      expect(KitoDistanceFormatting.string(850), '850 m');
      expect(KitoDistanceFormatting.string(996), '1 km');
      expect(KitoDistanceFormatting.string(1240), '1.2 km');
      expect(KitoDistanceFormatting.string(12400), '12 km');
      expect(KitoDistanceFormatting.string(-5), '0 m');
      expect(
          KitoDistanceFormatting.string(97,
              system: KitoDistanceSystem.imperial),
          '320 ft');
      expect(
          KitoDistanceFormatting.string(805,
              system: KitoDistanceSystem.imperial),
          '0.5 mi');
      expect(
          KitoDistanceFormatting.string(19312,
              system: KitoDistanceSystem.imperial),
          '12 mi');
    });
  });

  group('Kenyan phone numbers', () {
    test('parses every common way of writing one', () {
      for (final raw in [
        '0712 345 678',
        '712345678',
        '+254 712 345 678',
        '254712345678',
        '(0712) 345-678',
      ]) {
        expect(KitoKenyanPhoneNumber.tryParse(raw)?.nationalNumber, '712345678',
            reason: raw);
      }
      expect(KitoKenyanPhoneNumber.tryParse('0110 123 456')?.e164,
          '+254110123456');
      for (final bad in [
        '',
        '0812345678',
        '071234567',
        '+1 712 345 678',
        '2547123456789'
      ]) {
        expect(KitoKenyanPhoneNumber.isValid(bad), isFalse, reason: bad);
      }
    });

    test('prints every way', () {
      final p = KitoKenyanPhoneNumber.tryParse('0712345678')!;
      expect(p.e164, '+254712345678');
      expect(p.international, '+254 712 345 678');
      expect(p.local, '0712 345 678');
      expect(p.masked, '+254 7•• ••• 678');
      expect(p.callUri.toString(), 'tel:+254712345678');
      expect(p.toString(), '+254712345678');
      expect(p, KitoKenyanPhoneNumber.tryParse('+254 712 345 678'));
    });

    test('guesses the carrier', () {
      KitoKenyanCarrier c(String n) =>
          KitoKenyanPhoneNumber.tryParse(n)!.carrier;
      expect(c('0712345678'), KitoKenyanCarrier.safaricom);
      expect(c('0110345678'), KitoKenyanCarrier.safaricom);
      expect(c('0733345678'), KitoKenyanCarrier.airtel);
      expect(c('0100345678'), KitoKenyanCarrier.airtel);
      expect(c('0772345678'), KitoKenyanCarrier.telkom);
      expect(c('0760345678'), KitoKenyanCarrier.unknown);
      expect(KitoKenyanCarrier.safaricom.walletName, 'M-Pesa');
      expect(KitoKenyanCarrier.unknown.walletName, isNull);
    });

    test('as you type', () {
      expect(KitoPhoneFormatting.kenyanAsYouType('071234'), '0712 34');
      expect(
          KitoPhoneFormatting.kenyanAsYouType('0712345678999'), '0712 345 678');
      expect(KitoPhoneFormatting.kenyanAsYouType('+2547123'), '+254 712 3');
      expect(KitoPhoneFormatting.kenyanAsYouType('254712345678'),
          '+254 712 345 678');
      expect(KitoPhoneFormatting.kenyanAsYouType('+2'), '+2');
      expect(KitoPhoneFormatting.kenyanAsYouType(''), '');
    });

    test('the input formatter keeps the caret after the same digit', () {
      final f = KitoKenyanPhoneInputFormatter();
      TextEditingValue type(String text, [int? caret]) => f.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
              text: text,
              selection:
                  TextSelection.collapsed(offset: caret ?? text.length)));
      final end = type('0712345');
      expect(end.text, '0712 345');
      expect(end.selection.baseOffset, 8);
      final middle = type('0712345', 5); // after "07123"
      expect(middle.selection.baseOffset, 6); // "0712 3|45"
      final intl = type('254712');
      expect(intl.text, '+254 712');
      expect(intl.selection.baseOffset, 8);
    });
  });

  test('strings: bundled languages match and the provider wins', () {
    final en = KitoFormattingStrings.bundled['en']!.keys.toSet();
    for (final lang in KitoFormattingStrings.bundled.values) {
      expect(lang.keys.toSet(), en);
    }
    expect(KitoFormattingStrings.lookup('today', locale: 'sw_KE'), 'Leo');
    expect(KitoFormattingStrings.lookup('today', locale: 'de'), 'Today');
    KitoFormattingStrings.provider = (k, l) => k == 'today' ? 'Heute' : null;
    expect(KitoFormattingStrings.lookup('today', locale: 'de'), 'Heute');
    expect(KitoFormattingStrings.unit('day', 1, locale: 'en'), '1 day');
    expect(KitoFormattingStrings.unit('day', 3, locale: 'fr'), '3 jours');
  });
}
