// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_fields/kito_ui_fields.dart';

TextEditingValue type(TextInputFormatter f, String old, String next,
        {int? caret}) =>
    f.formatEditUpdate(
      TextEditingValue(
          text: old, selection: TextSelection.collapsed(offset: old.length)),
      TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: caret ?? next.length)),
    );

void main() {
  group('KitoFieldMask', () {
    const phone = KitoFieldMask('(###) ###-####');

    test('applies without dangling literals and drops misfits', () {
      expect(phone.apply('2015550123'), '(201) 555-0123');
      expect(phone.apply('201'), '(201');
      expect(phone.apply('2015'), '(201) 5');
      expect(phone.apply('20a1'), '(201');
      expect(phone.apply(''), '');
      expect(phone.capacity, 10);
      expect(phone.isComplete('(201) 555-0123'), isTrue);
      expect(phone.isComplete('201555'), isFalse);
      expect(phone.apply('201555012399'), '(201) 555-0123');
      expect(phone.apply('201555012399', overflow: true), '(201) 555-012399');
    });

    test('normalises Arabic and Persian digits', () {
      expect(phone.apply('٢٠١٥٥٥٠١٢٣'), '(201) 555-0123');
      expect(phone.apply('۲۰۱۵۵۵۰۱۲۳'), '(201) 555-0123');
    });

    test('letter and any slots, uppercased', () {
      const plate = KitoFieldMask('AAA ###*');
      expect(plate.apply('kcb123x'), 'KCB 123X');
      expect(plate.raw('k-c-b'), 'KCB');
    });

    test('formatter keeps the caret after the same character', () {
      final f = phone.formatter;
      final v = type(f, '(201) 5', '(201) 55');
      expect(v.text, '(201) 55');
      expect(v.selection.baseOffset, 8);
      // Typing in the middle.
      final mid = type(f, '(201) 555', '(2019) 555', caret: 5);
      expect(mid.text, '(201) 955-5');
      expect(mid.selection.baseOffset, 7);
      // Backspacing over a literal removes the digit before it.
      final back = type(f, '(201) 5', '(201)5', caret: 5);
      expect(back.text, '(205');
    });

    test('digits formatter', () {
      final f = KitoFieldDigitsFormatter(digitsOnly: true, maxLength: 4);
      expect(type(f, '', '١٢a٣٤٥').text, '1234');
      expect(type(KitoFieldDigitsFormatter(), '', 'a٣').text, 'a3');
    });
  });

  group('countries', () {
    test('the database is complete and sorted, Kenya included', () {
      final all = KitoFieldCountries.all;
      expect(all.length, greaterThan(230));
      final names = all.map((c) => c.englishName).toList();
      expect(names, [...names]..sort());
      final ke = KitoFieldCountries.kenya;
      expect(ke.dialCode, '254');
      expect(ke.flag, '🇰🇪');
      expect(ke.trunkPrefix, '0');
      expect(ke.minLength, 9);
      expect(ke.maxLength, 9);
      expect(ke.formattedExampleNumber, '712 345 678');
      expect(KitoFieldCountries.byIsoCode('ke'), ke);
      expect(all.map((c) => c.isoCode).toSet().length, all.length);
    });

    test('shared dial codes: main first, leading digits disambiguate', () {
      expect(KitoFieldCountries.byDialCode('1').first.isoCode, 'US');
      expect(KitoFieldCountries.match('14165550123')!.$1.isoCode, 'CA');
      expect(KitoFieldCountries.match('12015550123')!.$1.isoCode, 'US');
      expect(KitoFieldCountries.match('77710009998')!.$1.isoCode, 'KZ');
      expect(KitoFieldCountries.match('79123456789')!.$1.isoCode, 'RU');
      final (ke, national) = KitoFieldCountries.match('254712345678')!;
      expect(ke.isoCode, 'KE');
      expect(national, '712345678');
      expect(KitoFieldCountries.match('999'), isNull);
    });

    test('search by name, ISO and dial code', () {
      expect(KitoFieldCountries.search('ken').first.isoCode, 'KE');
      expect(KitoFieldCountries.search('+254').first.isoCode, 'KE');
      expect(KitoFieldCountries.search('ug').first.isoCode, 'UG');
      expect(KitoFieldCountries.search(''),
          hasLength(KitoFieldCountries.all.length));
      expect(KitoFieldCountries.search('zzzz'), isEmpty);
    });

    test('generic grouping without masks', () {
      expect(kitoFieldGroupDigits('1234567'), '123 4567');
      expect(kitoFieldGroupDigits('12345678'), '123 456 78');
      final custom =
          KitoFieldCountry(isoCode: 'zz', dialCode: '999', englishName: 'Test');
      expect(custom.isoCode, 'ZZ');
      expect(custom.formatNational('1234'), '1234');
      expect(custom.maxLength, 12);
    });
  });

  group('KitoFieldPhoneNumber', () {
    test('parses international and national input', () {
      final a = KitoFieldPhoneNumber.parse('+254 712 345 678')!;
      expect(a.country.isoCode, 'KE');
      expect(a.nationalNumber, '712345678');
      expect(a.isValid, isTrue);
      final b = KitoFieldPhoneNumber.parse('00254712345678')!;
      expect(b, a);
      final c = KitoFieldPhoneNumber.parse('0712 345678',
          defaultCountry: KitoFieldCountries.kenya)!;
      expect(c.nationalNumber, '712345678', reason: 'trunk prefix dropped');
      final d = KitoFieldPhoneNumber.parse('+٢٥٤٧١٢٣٤٥٦٧٨')!;
      expect(d, a);
      expect(KitoFieldPhoneNumber.parse('  '), isNull);
      expect(KitoFieldPhoneNumber.parse('+999 1234'), isNull);
    });

    test('formats in every style', () {
      final n = KitoFieldPhoneNumber(
          country: KitoFieldCountries.kenya, nationalNumber: '712345678');
      expect(n.e164, '+254712345678');
      expect(n.format(KitoFieldPhoneFormat.international), '+254 712 345 678');
      expect(n.format(KitoFieldPhoneFormat.national), '712 345 678');
      expect(n.format(KitoFieldPhoneFormat.nationalWithTrunkPrefix),
          '0712 345 678');
      expect(n.format(KitoFieldPhoneFormat.rfc3966), 'tel:+254-712-345-678');
      final us = KitoFieldPhoneNumber(
          country: KitoFieldCountries.unitedStates,
          nationalNumber: '2015550123');
      expect(us.format(KitoFieldPhoneFormat.nationalWithTrunkPrefix),
          '(201) 555-0123');
      expect(us.toString(), '+12015550123');
      expect(
          KitoFieldPhoneNumber(
                  country: KitoFieldCountries.kenya, nationalNumber: '7123')
              .isValid,
          isFalse);
    });

    test('phone formatter keeps a typed trunk prefix and passes + through', () {
      final f = KitoFieldPhoneFormatter(KitoFieldCountries.kenya);
      expect(f.format('0712345678'), '0712 345 678');
      expect(f.format('712345678'), '712 345 678');
      expect(f.format('7123456789999'), '712 345 678');
      expect(f.format('+254 7'), '+2547');
      expect(f.format('0'), '0');
      expect(type(f, '712 34', '712 345').text, '712 345');
    });
  });

  group('amounts', () {
    test('normalise typed and pasted amounts', () {
      expect(kitoFieldNormalizeAmount('1,200.50'), '1200.50');
      expect(kitoFieldNormalizeAmount('1.200,50'), '1200.50');
      expect(kitoFieldNormalizeAmount('1,200'), '1200');
      expect(kitoFieldNormalizeAmount('20,5'), '20.5');
      expect(kitoFieldNormalizeAmount('12,345,678'), '12345678');
      expect(kitoFieldNormalizeAmount('١٬٢٠٠٫٥'), '1200.5');
      expect(kitoFieldNormalizeAmount('3.14159'), '3.14');
      expect(kitoFieldNormalizeAmount('.5'), '0.5');
      expect(kitoFieldNormalizeAmount('007'), '7');
      expect(kitoFieldNormalizeAmount('1 200'), '1200');
      expect(kitoFieldNormalizeAmount('abc'), '');
      expect(kitoFieldNormalizeAmount('12.', decimals: 0), '12');
      expect(kitoFieldNormalizeAmount('-5', allowNegative: true), '-5');
    });

    test('display groups the integer part', () {
      expect(kitoFieldDisplayAmount('1234567.5'), '1,234,567.5');
      expect(kitoFieldDisplayAmount('12.'), '12.');
      expect(
          kitoFieldDisplayAmount('1200',
              groupingSeparator: '.', decimalSeparator: ','),
          '1.200');
      expect(kitoFieldDisplayAmount(''), '');
    });

    test('formatter groups as you type without misreading its own commas', () {
      final f = KitoFieldAmountFormatter();
      var text = '';
      for (final key in '12005'.split('')) {
        text = type(f, text, text + key).text;
      }
      expect(text, '12,005');
      text = type(f, text, '$text,').text; // a comma typed as the decimal point
      expect(text, '12,005.');
      text = type(f, text, '${text}75').text;
      expect(text, '12,005.75');
      text = type(f, text, '${text}9').text;
      expect(text, '12,005.75', reason: 'two decimals');
      expect(type(f, '', '1.234.567,89').text, '1,234,567.89');
      expect(kitoFieldParseAmount('12,005.75'), 12005.75);
      expect(
          kitoFieldParseAmount('1.200,5',
              groupingSeparator: '.', decimalSeparator: ','),
          1200.5);
      expect(kitoFieldParseAmount(''), isNull);
    });

    test('comma-decimal locales', () {
      final f = KitoFieldAmountFormatter(
          groupingSeparator: '.', decimalSeparator: ',');
      var text = '';
      for (final key in '12345,6'.split('')) {
        text = type(f, text, text + key).text;
      }
      expect(text, '12.345,6');
    });
  });

  group('cards', () {
    test('brand detection', () {
      expect(KitoFieldCardBrand.detect('4242'), KitoFieldCardBrand.visa);
      expect(KitoFieldCardBrand.detect('5555'), KitoFieldCardBrand.mastercard);
      expect(KitoFieldCardBrand.detect('2221'), KitoFieldCardBrand.mastercard);
      expect(KitoFieldCardBrand.detect('3782'), KitoFieldCardBrand.amex);
      expect(KitoFieldCardBrand.detect('6011'), KitoFieldCardBrand.discover);
      expect(KitoFieldCardBrand.detect('645'), KitoFieldCardBrand.discover);
      expect(KitoFieldCardBrand.detect('3530'), KitoFieldCardBrand.jcb);
      expect(KitoFieldCardBrand.detect('3056'), KitoFieldCardBrand.dinersClub);
      expect(KitoFieldCardBrand.detect('6212'), KitoFieldCardBrand.unionPay);
      expect(KitoFieldCardBrand.detect(''), KitoFieldCardBrand.unknown);
      expect(KitoFieldCardBrand.detect('٤٢'), KitoFieldCardBrand.visa);
      expect(KitoFieldCardBrand.amex.cvvLength, 4);
      expect(KitoFieldCardBrand.visa.cvvLength, 3);
      expect(
          KitoFieldMask(KitoFieldCardBrand.amex.mask).apply('378282246310005'),
          '3782 822463 10005');
    });
  });

  group('codes', () {
    test('sanitize filters, converts and caps', () {
      expect(kitoCodeSanitize('12a-34 56', length: 6), '123456');
      expect(kitoCodeSanitize('١٢٣٤٥٦٧', length: 6), '123456');
      expect(
          kitoCodeSanitize('ab12cd', length: 6, alphanumeric: true), 'AB12CD');
      expect(kitoCodeSanitize('ab', length: 6), '');
    });

    test('group boundaries', () {
      expect(kitoCodeGroupBoundaries([3, 3], 6), {2});
      expect(kitoCodeGroupBoundaries([2, 2, 2], 6), {1, 3});
      expect(kitoCodeGroupBoundaries(null, 6), isEmpty);
      expect(kitoCodeGroupBoundaries([6], 6), isEmpty);
    });
  });

  group('theme', () {
    test('copyWith and equality', () {
      const a = KitoFieldTheme();
      final b = a.copyWith(style: KitoFieldStyle.filled);
      expect(b.style, KitoFieldStyle.filled);
      expect(b, isNot(a));
      expect(a.copyWith(), a);
      expect(a.copyWith().hashCode, a.hashCode);
    });
  });
}
