// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/foundation.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'country.dart';

/// Ways to write a phone number.
enum KitoFieldPhoneFormat {
  /// "+254712345678"
  e164,

  /// "+254 712 345 678"
  international,

  /// "712 345 678"
  national,

  /// "0712 345 678" — national with the trunk prefix, where the region uses one.
  nationalWithTrunkPrefix,

  /// "tel:+254-712-345-678"
  rfc3966,
}

/// A phone number: a region and its national significant number (digits only, no trunk prefix).
@immutable
class KitoFieldPhoneNumber {
  /// Creates a number. The trunk prefix is dropped when [nationalNumber] starts with it.
  KitoFieldPhoneNumber({required this.country, required String nationalNumber})
      : nationalNumber =
            country.stripTrunkPrefix(nationalNumber.kitoAsciiDigits);

  /// Reads free-form input. A leading "+" or "00" picks its own region; anything else is read
  /// as a national number in [defaultCountry] (the device's region when null). Null when
  /// there are no digits or the dial code isn't known.
  ///
  /// ```dart
  /// KitoFieldPhoneNumber.parse('+254 712 345 678')!.country.isoCode; // KE
  /// KitoFieldPhoneNumber.parse('0712 345678', defaultCountry: KitoFieldCountries.kenya);
  /// ```
  static KitoFieldPhoneNumber? parse(String input,
      {KitoFieldCountry? defaultCountry}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final international = internationalDigits(trimmed);
    if (international != null) {
      final match = KitoFieldCountries.match(international);
      if (match == null) return null;
      return KitoFieldPhoneNumber(country: match.$1, nationalNumber: match.$2);
    }
    final digits = trimmed.kitoAsciiDigits;
    if (digits.isEmpty) return null;
    return KitoFieldPhoneNumber(
        country: defaultCountry ?? KitoFieldCountries.current(),
        nationalNumber: digits);
  }

  /// The digits after a "+" or "00" prefix, or null when [input] is national.
  static String? internationalDigits(String input) {
    final compact =
        input.kitoNormalizedDigits.replaceAll(RegExp(r'[\s\-().]'), '');
    if (compact.startsWith('+')) return compact.substring(1).kitoAsciiDigits;
    if (compact.startsWith('00') && compact.length > 4) {
      return compact.substring(2).kitoAsciiDigits;
    }
    return null;
  }

  /// The region.
  final KitoFieldCountry country;

  /// Digits only, without the trunk prefix ("712345678").
  final String nationalNumber;

  /// True when the length fits the region.
  bool get isValid =>
      nationalNumber.length >= country.minLength &&
      nationalNumber.length <= country.maxLength;

  /// True when there are no digits.
  bool get isEmpty => nationalNumber.isEmpty;

  /// "+254712345678".
  String get e164 => format(KitoFieldPhoneFormat.e164);

  /// The number written in [style].
  String format(KitoFieldPhoneFormat style) {
    final national = country.formatNational(nationalNumber);
    switch (style) {
      case KitoFieldPhoneFormat.e164:
        return '+${country.dialCode}$nationalNumber';
      case KitoFieldPhoneFormat.international:
        return national.isEmpty
            ? country.formattedDialCode
            : '${country.formattedDialCode} $national';
      case KitoFieldPhoneFormat.national:
        return national;
      case KitoFieldPhoneFormat.nationalWithTrunkPrefix:
        final trunk = country.trunkPrefix;
        if (trunk == null || national.isEmpty || national.startsWith('(')) {
          return national;
        }
        return '$trunk$national';
      case KitoFieldPhoneFormat.rfc3966:
        final dashed = national
            .replaceAll(RegExp(r'[^0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');
        return 'tel:+${country.dialCode}${dashed.isEmpty ? '' : '-$dashed'}';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is KitoFieldPhoneNumber &&
      other.country == country &&
      other.nationalNumber == nationalNumber;

  @override
  int get hashCode => Object.hash(country, nationalNumber);

  @override
  String toString() => e164;
}
