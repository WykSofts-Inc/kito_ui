// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

typedef R = KitoValidationRule;

void main() {
  group('presence and length', () {
    test('required ignores whitespace and treats null as empty', () {
      expect(R.required().validate(null), 'This field is required');
      expect(R.required().validate('  \n'), isNotNull);
      expect(R.required().validate(' a '), isNull);
      expect(R.required(message: 'Needed').validate(''), 'Needed');
    });

    test('lengths count characters, not code units', () {
      expect(R.minLength(3).validate('ab'), 'Must be at least 3 characters');
      expect(R.minLength(3).validate('abc'), isNull);
      expect(R.maxLength(2).validate('abc'), 'Must be 2 characters or fewer');
      expect(R.exactLength(2).validate('🇰🇪👍🏽'), isNull);
      expect(R.exactLength(4).validate('abc'), 'Must be exactly 4 characters');
    });
  });

  group('formats', () {
    test('email', () {
      expect(R.email().validate('a@b.co'), isNull);
      expect(R.email().validate(' a@b.co '), isNull);
      for (final bad in ['a@b', 'a b@c.d', '@b.co', 'plain']) {
        expect(R.email().validate(bad), isNotNull, reason: bad);
      }
    });

    test('phone counts digits in any script', () {
      expect(R.phone().validate('+254 712 345 678'), isNull);
      expect(R.phone().validate('٠٧١٢٣٤٥٦٧٨'), isNull);
      expect(R.phone().validate('12345'), isNotNull);
      expect(R.phone().validate('1' * 16), isNotNull);
    });

    test('url needs http(s) and a dotted host', () {
      expect(R.url().validate('https://wyksoftsinc.com'), isNull);
      expect(R.url().validate('http://a.b/c?d'), isNull);
      expect(R.url().validate('ftp://a.com'), isNotNull);
      expect(R.url().validate('https://localhost'), isNotNull);
      expect(R.url().validate('not a url'), isNotNull);
    });

    test('numeric and alphanumeric', () {
      expect(R.numeric().validate('0123'), isNull);
      expect(R.numeric().validate('۱۲۳'), isNull);
      expect(R.numeric().validate('12a'), 'Digits only');
      expect(R.numeric().validate(''), isNotNull);
      expect(R.alphanumeric().validate('abc123'), isNull);
      expect(R.alphanumeric().validate('مرحبا1'), isNull);
      expect(R.alphanumeric().validate('a-b'), isNotNull);
    });

    test('pattern', () {
      final rule = R.pattern(RegExp(r'^[A-Z]{3}$'), message: 'Three capitals');
      expect(rule.validate('KES'), isNull);
      expect(rule.validate('kes'), 'Three capitals');
    });

    test('numberInRange accepts grouping and other digit scripts', () {
      final rule = R.numberInRange(1, 1500);
      expect(rule.validate('1,200.50'), isNull);
      expect(rule.validate('١٢٠٠'), isNull);
      expect(rule.validate('0'), 'Enter a number from 1 to 1500');
      expect(rule.validate('abc'), isNotNull);
      expect(R.numberInRange(0.5, 2).message, 'Enter a number from 0.5 to 2');
    });

    test('luhn', () {
      expect(R.luhn().validate('4242 4242 4242 4242'), isNull);
      expect(R.luhn().validate('4242-4242-4242-4241'), isNotNull);
      expect(R.luhn().validate('4242'), isNotNull);
      expect(kitoPassesLuhn('٤٢٤٢٤٢٤٢٤٢٤٢٤٢٤٢'), isTrue);
      expect(kitoPassesLuhn('4242x4242x4242x4242'), isFalse);
    });

    test('cardExpiry is valid through the end of its month', () {
      DateTime now() => DateTime(2026, 9, 29);
      final rule = R.cardExpiry(now: now);
      expect(rule.validate('09/26'), isNull);
      expect(rule.validate('12/2030'), isNull);
      expect(rule.validate('08/26'), isNotNull);
      expect(rule.validate('13/30'), isNotNull);
      expect(rule.validate('1/3'), isNotNull);
      expect(kitoParseCardExpiry('0731'), DateTime(2031, 7));
    });

    test('cvv', () {
      expect(R.cvv().validate('123'), isNull);
      expect(R.cvv().validate('1234'), isNull);
      expect(R.cvv().validate('12'), isNotNull);
      expect(R.cvv().validate('12a'), isNotNull);
    });
  });

  group('character classes', () {
    test('each class', () {
      expect(R.containsUppercase().validate('abc'), isNotNull);
      expect(R.containsUppercase().validate('aBc'), isNull);
      expect(R.containsLowercase().validate('ABC'), isNotNull);
      expect(R.containsLowercase().validate('ABc'), isNull);
      expect(R.containsDigit().validate('abc'), isNotNull);
      expect(R.containsDigit().validate('ab٣'), isNull);
      expect(R.containsSymbol().validate('ab c1'), isNotNull);
      expect(R.containsSymbol().validate('ab#'), isNull);
      expect(R.noWhitespace().validate('a b'), 'No spaces');
      expect(R.noWhitespace().validate('ab'), isNull);
    });

    test('strongPassword is one rule per requirement', () {
      final rules = R.strongPassword(minLength: 10);
      expect(rules, hasLength(5));
      expect(rules.first.message, 'At least 10 characters');
      expect(kitoValidate('Abcdefghi1!', rules), isNull);
      expect(kitoValidateAll('abc', rules), [
        'At least 10 characters',
        'At least one uppercase letter',
        'At least one number',
        'At least one symbol',
      ]);
    });
  });

  group('lists and comparisons', () {
    test('matches reads the other value when it runs', () {
      var password = 'one';
      final rule = R.matches(() => password);
      expect(rule.validate('one'), isNull);
      password = 'two';
      expect(rule.validate('one'), "Values don't match");
    });

    test('oneOf and notOneOf ignore case', () {
      expect(R.oneOf(['KE', 'UG']).validate('ke'), isNull);
      expect(R.oneOf(['KE']).validate('TZ'), 'Not a recognised value');
      expect(R.notOneOf(['admin']).validate('Admin'), isNotNull);
      expect(R.notOneOf(['admin']).validate('wycliff'), isNull);
    });

    test('custom', () {
      final even = R.custom('Even only', (v) => (int.tryParse(v) ?? 1).isEven);
      expect(even.validate('4'), isNull);
      expect(even.validate('3'), 'Even only');
    });
  });

  group('composition', () {
    test('first failure wins', () {
      final rules = [R.required(), R.email()];
      expect(kitoValidate('', rules), 'This field is required');
      expect(kitoValidate('a', rules), 'Enter a valid email address');
      expect(kitoValidate('a@b.co', rules), isNull);
    });

    test('& reports whichever side fails', () {
      final rule = R.minLength(3) & R.numeric();
      expect(rule.validate('ab'), 'Must be at least 3 characters');
      expect(rule.validate('abc'), 'Digits only');
      expect(rule.validate('123'), isNull);
    });

    test('| passes when either side does', () {
      final rule = R.email() | R.phone();
      expect(rule.validate('a@b.co'), isNull);
      expect(rule.validate('0712345678'), isNull);
      expect(rule.validate('nope'), 'Enter a valid email address');
    });

    test('optional passes empty values only', () {
      final rule = R.url().optional;
      expect(rule.validate(''), isNull);
      expect(rule.validate('  '), isNull);
      expect(rule.validate('nope'), isNotNull);
      final both = (R.minLength(3) & R.numeric()).optional;
      expect(both.validate('ab1'), 'Digits only');
    });

    test('when only applies while its condition holds', () {
      var business = false;
      final rule = R.required().when(() => business);
      expect(rule.validate(''), isNull);
      business = true;
      expect(rule.validate(''), isNotNull);
    });

    test('withMessage keeps the check', () {
      final rule = R.email().withMessage('Email, please');
      expect(rule.validate('x'), 'Email, please');
      expect(rule.validate('a@b.co'), isNull);
    });

    test('formValidator and combined plug into Flutter', () {
      final rules = [R.required(), R.minLength(2)];
      final validator = rules.formValidator;
      expect(validator(null), 'This field is required');
      expect(validator('a'), 'Must be at least 2 characters');
      expect(validator('ab'), isNull);
      expect(rules.combined.validate('a'), 'Must be at least 2 characters');
      expect(rules.combined.passes('ab'), isTrue);
      expect(rules.validate(''), 'This field is required');
    });

    test('evaluate reports every rule for checklists', () {
      final results = kitoEvaluate('abc', [R.minLength(2), R.containsDigit()]);
      expect(results, const [
        KitoRuleResult(
            index: 0, message: 'Must be at least 2 characters', passed: true),
        KitoRuleResult(index: 1, message: 'At least one number', passed: false),
      ]);
    });
  });

  group('digits', () {
    test('normalises other scripts and keeps everything else', () {
      expect('٠١٢٣٤٥٦٧٨٩'.kitoNormalizedDigits, '0123456789');
      expect('۰۱۲-۳'.kitoNormalizedDigits, '012-3');
      expect('०१२ ０１２'.kitoNormalizedDigits, '012 012');
      expect('+254 (7)'.kitoAsciiDigits, '2547');
      expect(kitoDigitValue('x'.codeUnitAt(0)), isNull);
    });

    test('parseNumber', () {
      expect(kitoParseNumber('1,234.5'), 1234.5);
      expect(kitoParseNumber('٣٫٥'), 3.5);
      expect(kitoParseNumber(' -7 '), -7);
      expect(kitoParseNumber(''), isNull);
      expect(kitoParseNumber('x'), isNull);
    });
  });
}
