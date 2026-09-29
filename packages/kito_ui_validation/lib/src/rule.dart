// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'digits.dart';

/// The test a [KitoValidationRule] runs: true when [value] passes.
typedef KitoValidationPredicate = bool Function(String value);

/// A single check over a `String`, with the message shown when it fails.
///
/// Rules compose: run a list with [kitoValidate] and the first failure wins, so a field that
/// says "This field is required" doesn't also flash "Enter a valid email address" the moment
/// it has one character in it. Combine two with `&` (both must pass) or `|` (either may).
///
/// ```dart
/// final rules = [KitoValidationRule.required(), KitoValidationRule.email()];
/// TextFormField(validator: rules.formValidator);
/// ```
@immutable
class KitoValidationRule {
  /// A rule that fails with [message] whenever [test] returns false.
  const KitoValidationRule(this.message, this.test);

  /// What to show when the rule fails.
  final String message;

  /// Returns true when the value passes.
  final KitoValidationPredicate test;

  /// The [message] when [value] fails, otherwise null. A null value is treated as empty.
  String? validate(String? value) => test(value ?? '') ? null : message;

  /// True when [value] passes.
  bool passes(String? value) => test(value ?? '');

  /// The same check with a different message.
  KitoValidationRule withMessage(String message) =>
      KitoValidationRule(message, test);

  /// Passes empty values, and runs this rule on anything else — for optional fields that must
  /// still be well formed when filled in ("website, if you have one").
  KitoValidationRule get optional => _ReportingRule(
        message,
        (v) => v.trim().isEmpty || test(v),
        (v) => v.trim().isEmpty ? null : validate(v),
      );

  /// Only runs while [condition] is true; passes otherwise.
  KitoValidationRule when(bool Function() condition) => _ReportingRule(
        message,
        (v) => !condition() || test(v),
        (v) => condition() ? validate(v) : null,
      );

  /// Both rules must pass; reports whichever fails first.
  KitoValidationRule operator &(KitoValidationRule other) => _ReportingRule(
        message,
        (v) => test(v) && other.test(v),
        (v) => validate(v) ?? other.validate(v),
      );

  /// Either rule may pass; reports this rule's message when both fail.
  KitoValidationRule operator |(KitoValidationRule other) =>
      KitoValidationRule(message, (v) => test(v) || other.test(v));

  // MARK: - Presence and length

  /// Something other than whitespace.
  factory KitoValidationRule.required(
          {String message = 'This field is required'}) =>
      KitoValidationRule(message, (v) => v.trim().isNotEmpty);

  /// At least [length] characters.
  factory KitoValidationRule.minLength(int length, {String? message}) =>
      KitoValidationRule(message ?? 'Must be at least $length characters',
          (v) => v.characters.length >= length);

  /// At most [length] characters.
  factory KitoValidationRule.maxLength(int length, {String? message}) =>
      KitoValidationRule(message ?? 'Must be $length characters or fewer',
          (v) => v.characters.length <= length);

  /// Exactly [length] characters.
  factory KitoValidationRule.exactLength(int length, {String? message}) =>
      KitoValidationRule(message ?? 'Must be exactly $length characters',
          (v) => v.characters.length == length);

  // MARK: - Formats

  /// Something shaped like `name@domain.tld`.
  factory KitoValidationRule.email(
          {String message = 'Enter a valid email address'}) =>
      KitoValidationRule(message, (v) => _emailPattern.hasMatch(v.trim()));

  /// 9–15 digits once separators are stripped; digits in any script count.
  factory KitoValidationRule.phone(
          {String message = 'Enter a valid phone number'}) =>
      KitoValidationRule(message, (v) {
        final digits = v.kitoAsciiDigits.length;
        return digits >= 9 && digits <= 15;
      });

  /// An http or https address with a dotted host.
  factory KitoValidationRule.url(
          {String message = 'Enter a valid web address'}) =>
      KitoValidationRule(message, (v) {
        final uri = Uri.tryParse(v.trim());
        if (uri == null) return false;
        final scheme = uri.scheme.toLowerCase();
        return (scheme == 'http' || scheme == 'https') &&
            uri.host.contains('.');
      });

  /// Digits only (any script), and not empty.
  factory KitoValidationRule.numeric({String message = 'Digits only'}) =>
      KitoValidationRule(message, (v) => v.isNotEmpty && _allDigits(v));

  /// Letters and numbers only, and not empty.
  factory KitoValidationRule.alphanumeric(
          {String message = 'Letters and numbers only'}) =>
      KitoValidationRule(
          message, (v) => v.isNotEmpty && _alphanumeric.hasMatch(v));

  /// Matches [pattern] anywhere in the value. Anchor it with `^…$` for a full match.
  factory KitoValidationRule.pattern(RegExp pattern,
          {required String message}) =>
      KitoValidationRule(message, pattern.hasMatch);

  /// A number between [min] and [max], inclusive. Accepts `1,200.50`-style grouping and
  /// digits in any script.
  factory KitoValidationRule.numberInRange(num min, num max,
          {String? message}) =>
      KitoValidationRule(
        message ?? 'Enter a number from ${_fmt(min)} to ${_fmt(max)}',
        (v) {
          final n = kitoParseNumber(v);
          return n != null && n >= min && n <= max;
        },
      );

  /// The Luhn checksum every payment card number passes; spaces and dashes are ignored.
  factory KitoValidationRule.luhn({String message = 'Check the card number'}) =>
      KitoValidationRule(message, kitoPassesLuhn);

  /// A card expiry as `MM/YY` (or `MM/YYYY`) that hasn't passed. [now] is for tests.
  factory KitoValidationRule.cardExpiry(
          {String message = 'Check the expiry date',
          DateTime Function()? now}) =>
      KitoValidationRule(message, (v) {
        final expiry = kitoParseCardExpiry(v);
        if (expiry == null) return false;
        final today = (now ?? DateTime.now)();
        // Cards are valid through the last day of their expiry month.
        final firstInvalid = DateTime(expiry.year, expiry.month + 1);
        return today.isBefore(firstInvalid);
      });

  /// A 3- or 4-digit security code.
  factory KitoValidationRule.cvv(
          {String message = 'Check the security code'}) =>
      KitoValidationRule(message, (v) {
        final digits = v.kitoAsciiDigits;
        return digits.length == v.trim().length &&
            (digits.length == 3 || digits.length == 4);
      });

  // MARK: - Character classes

  /// At least one uppercase letter.
  factory KitoValidationRule.containsUppercase(
          {String message = 'At least one uppercase letter'}) =>
      KitoValidationRule(message, _uppercase.hasMatch);

  /// At least one lowercase letter.
  factory KitoValidationRule.containsLowercase(
          {String message = 'At least one lowercase letter'}) =>
      KitoValidationRule(message, _lowercase.hasMatch);

  /// At least one digit, in any script.
  factory KitoValidationRule.containsDigit(
          {String message = 'At least one number'}) =>
      KitoValidationRule(message, (v) => v.kitoAsciiDigits.isNotEmpty);

  /// At least one character that isn't a letter, number or space.
  factory KitoValidationRule.containsSymbol(
          {String message = 'At least one symbol'}) =>
      KitoValidationRule(message, _symbol.hasMatch);

  /// No spaces, tabs or line breaks.
  factory KitoValidationRule.noWhitespace({String message = 'No spaces'}) =>
      KitoValidationRule(message, (v) => !_whitespace.hasMatch(v));

  // MARK: - Lists and comparisons

  /// Equal to [other], read when the rule runs — for "confirm password".
  factory KitoValidationRule.matches(String Function() other,
          {String message = "Values don't match"}) =>
      KitoValidationRule(message, (v) => v == other());

  /// One of [allowed], ignoring case: promo codes, country codes.
  factory KitoValidationRule.oneOf(Iterable<String> allowed,
      {String message = 'Not a recognised value'}) {
    final lowered = {for (final a in allowed) a.toLowerCase()};
    return KitoValidationRule(
        message, (v) => lowered.contains(v.toLowerCase()));
  }

  /// None of [blocked], ignoring case: reserved usernames, taken handles.
  factory KitoValidationRule.notOneOf(Iterable<String> blocked,
      {String message = "That one isn't available"}) {
    final lowered = {for (final b in blocked) b.toLowerCase()};
    return KitoValidationRule(
        message, (v) => !lowered.contains(v.toLowerCase()));
  }

  /// Your own check.
  factory KitoValidationRule.custom(
          String message, KitoValidationPredicate test) =>
      KitoValidationRule(message, test);

  /// A strong password: length plus every character class, one rule each so a checklist can
  /// tick them off one by one.
  static List<KitoValidationRule> strongPassword({int minLength = 8}) => [
        KitoValidationRule.minLength(minLength,
            message: 'At least $minLength characters'),
        KitoValidationRule.containsUppercase(),
        KitoValidationRule.containsLowercase(),
        KitoValidationRule.containsDigit(),
        KitoValidationRule.containsSymbol(),
      ];

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _alphanumeric = RegExp(r'^[\p{L}\p{Nd}]+$', unicode: true);
  static final _uppercase = RegExp(r'\p{Lu}', unicode: true);
  static final _lowercase = RegExp(r'\p{Ll}', unicode: true);
  static final _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final _whitespace = RegExp(r'\s');

  static bool _allDigits(String v) {
    for (final rune in v.runes) {
      if (kitoDigitValue(rune) == null) return false;
    }
    return true;
  }

  static String _fmt(num n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();
}

class _ReportingRule extends KitoValidationRule {
  const _ReportingRule(super.message, super.test, this._reporter);
  final String? Function(String) _reporter;

  @override
  String? validate(String? value) => _reporter(value ?? '');
}

/// Runs [rules] in order and returns the first failure, or null when every rule passes.
String? kitoValidate(String? value, Iterable<KitoValidationRule> rules) {
  for (final rule in rules) {
    final error = rule.validate(value);
    if (error != null) return error;
  }
  return null;
}

/// Every failure message, in order — for an error summary rather than a single line.
List<String> kitoValidateAll(
        String? value, Iterable<KitoValidationRule> rules) =>
    [
      for (final rule in rules)
        if (rule.validate(value) case final error?) error
    ];

/// One rule's outcome, for checklists that show every rule rather than the first failure.
@immutable
class KitoRuleResult {
  /// Creates a result.
  const KitoRuleResult(
      {required this.index, required this.message, required this.passed});

  /// The rule's position in the list.
  final int index;

  /// The rule's message ("At least one number").
  final String message;

  /// Whether the value passed.
  final bool passed;

  @override
  bool operator ==(Object other) =>
      other is KitoRuleResult &&
      other.index == index &&
      other.message == message &&
      other.passed == passed;

  @override
  int get hashCode => Object.hash(index, message, passed);

  @override
  String toString() => 'KitoRuleResult($index, $message, passed: $passed)';
}

/// Every rule's outcome, in order.
List<KitoRuleResult> kitoEvaluate(
    String? value, Iterable<KitoValidationRule> rules) {
  var i = 0;
  return [
    for (final rule in rules)
      KitoRuleResult(
          index: i++, message: rule.message, passed: rule.passes(value)),
  ];
}

/// Plugs rules into Flutter's [Form] and `TextFormField`.
extension KitoValidationRuleList on Iterable<KitoValidationRule> {
  /// A `FormFieldValidator<String>` that returns the first failure.
  ///
  /// ```dart
  /// TextFormField(validator: [KitoValidationRule.required()].formValidator);
  /// ```
  String? Function(String?) get formValidator =>
      (value) => kitoValidate(value, this);

  /// The first failure for [value], or null.
  String? validate(String? value) => kitoValidate(value, this);

  /// All rules as one: passes when every rule does, reporting the first failure.
  KitoValidationRule get combined {
    final rules = toList(growable: false);
    return _ReportingRule(
      rules.isEmpty ? '' : rules.first.message,
      (v) => rules.every((r) => r.test(v)),
      (v) => kitoValidate(v, rules),
    );
  }
}

/// True when [number] (spaces and dashes ignored, any digit script) has 12–19 digits and a
/// valid Luhn checksum.
bool kitoPassesLuhn(String number) {
  final compact = number.replaceAll(RegExp(r'[\s-]'), '');
  final digits = compact.kitoAsciiDigits;
  if (digits.length != compact.runes.length) return false;
  if (digits.length < 12 || digits.length > 19) return false;
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var d = digits.codeUnitAt(digits.length - 1 - i) - 0x30;
    if (i.isOdd) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 == 0;
}

/// Parses `1,200.50`, ` 42 `, `٣٫٥` and `-7` into a number; null when it isn't one.
/// Commas are treated as grouping, so use it for dot-decimal input.
num? kitoParseNumber(String value) {
  final normalized = value.kitoNormalizedDigits
      .replaceAll('٫', '.') // Arabic decimal separator
      .replaceAll('٬', '') // Arabic thousands separator
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .trim();
  if (normalized.isEmpty) return null;
  return num.tryParse(normalized);
}

/// Parses a card expiry `MM/YY`, `MM / YY`, `MMYY` or `MM/YYYY` into the first day of that month.
DateTime? kitoParseCardExpiry(String value) {
  final digits = value.kitoAsciiDigits;
  if (digits.length != 4 && digits.length != 6) return null;
  final month = int.parse(digits.substring(0, 2));
  if (month < 1 || month > 12) return null;
  var year = int.parse(digits.substring(2));
  if (digits.length == 4) year += 2000;
  return DateTime(year, month);
}
