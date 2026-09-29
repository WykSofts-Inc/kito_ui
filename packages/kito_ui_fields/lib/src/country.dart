// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/foundation.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'mask.dart';

part 'country_data.dart';

/// A calling region: ISO code, dial code and how its national numbers are written.
@immutable
class KitoFieldCountry {
  /// Creates a region. Masks use `#` for a digit; lengths default to the masks' digit counts.
  factory KitoFieldCountry({
    required String isoCode,
    required String dialCode,
    required String englishName,
    List<String> formats = const [],
    int? minLength,
    int? maxLength,
    String? trunkPrefix,
    String? exampleNumber,
    List<String> leadingDigits = const [],
    bool isMainCountryForDialCode = true,
  }) {
    final sorted = [...formats]..sort((a, b) => _slots(a).compareTo(_slots(b)));
    final min = minLength ?? (sorted.isEmpty ? 4 : _slots(sorted.first));
    final max = maxLength ??
        (sorted.isEmpty
            ? (15 - dialCode.length).clamp(4, 15)
            : _slots(sorted.last));
    return KitoFieldCountry._(
      isoCode: isoCode.toUpperCase(),
      dialCode: dialCode,
      englishName: englishName,
      formats: List.unmodifiable(sorted),
      minLength: min,
      maxLength: max,
      trunkPrefix: trunkPrefix,
      exampleNumber:
          exampleNumber ?? '2345678901234'.substring(0, max.clamp(1, 13)),
      leadingDigits: List.unmodifiable(leadingDigits),
      isMainCountryForDialCode: isMainCountryForDialCode,
    );
  }

  const KitoFieldCountry._({
    required this.isoCode,
    required this.dialCode,
    required this.englishName,
    required this.formats,
    required this.minLength,
    required this.maxLength,
    required this.trunkPrefix,
    required this.exampleNumber,
    required this.leadingDigits,
    required this.isMainCountryForDialCode,
  });

  static int _slots(String mask) => '#'.allMatches(mask).length;

  /// ISO 3166-1 alpha-2, uppercase ("KE").
  final String isoCode;

  /// Calling code without "+" ("254").
  final String dialCode;

  /// The English name ("Kenya").
  final String englishName;

  /// National-number masks, shortest first; `#` is a digit.
  final List<String> formats;

  /// Fewest digits in a national number.
  final int minLength;

  /// Most digits in a national number.
  final int maxLength;

  /// The domestic prefix dropped in international form ("0" in Kenya and the UK).
  final String? trunkPrefix;

  /// A plausible national number, for placeholders.
  final String exampleNumber;

  /// National-number prefixes that pick this region when several share a dial code.
  final List<String> leadingDigits;

  /// The region chosen when a shared dial code can't be told apart.
  final bool isMainCountryForDialCode;

  /// The flag emoji built from the ISO code ("🇰🇪").
  String get flag =>
      String.fromCharCodes(isoCode.codeUnits.map((c) => 0x1F1E6 + (c - 0x41)));

  /// "+254".
  String get formattedDialCode => '+$dialCode';

  /// The mask for [digits]: the shortest that holds them, or the longest.
  String? maskFor(String digits) {
    if (formats.isEmpty) return null;
    for (final f in formats) {
      if (_slots(f) >= digits.length) return f;
    }
    return formats.last;
  }

  /// [nationalNumber] written the national way ("712 345 678"). Digits beyond the mask are
  /// appended; without masks digits are grouped in threes.
  String formatNational(String nationalNumber) {
    final digits = nationalNumber.kitoAsciiDigits;
    if (digits.isEmpty) return '';
    final mask = maskFor(digits);
    if (mask == null) return kitoFieldGroupDigits(digits);
    return KitoFieldMask(mask).apply(digits);
  }

  /// The example number, formatted ("712 345 678").
  String get formattedExampleNumber => formatNational(exampleNumber);

  /// [digits] without a leading trunk prefix, when there's one and something is left.
  String stripTrunkPrefix(String digits) {
    final trunk = trunkPrefix;
    if (trunk == null ||
        !digits.startsWith(trunk) ||
        digits.length <= trunk.length) {
      return digits;
    }
    return digits.substring(trunk.length);
  }

  @override
  bool operator ==(Object other) =>
      other is KitoFieldCountry && other.isoCode == isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => 'KitoFieldCountry($isoCode, +$dialCode)';
}

/// Groups of three, with a final group of four when one digit would be left alone.
String kitoFieldGroupDigits(String digits) {
  final groups = <String>[];
  var rest = digits;
  while (rest.isNotEmpty) {
    final take = rest.length == 4 ? 4 : (rest.length < 3 ? rest.length : 3);
    groups.add(rest.substring(0, take));
    rest = rest.substring(take);
  }
  return groups.join(' ');
}

/// Every ITU calling region, with lookups.
abstract final class KitoFieldCountries {
  static final List<KitoFieldCountry> _sorted = [..._countries]
    ..sort((a, b) => a.englishName.compareTo(b.englishName));
  static final Map<String, KitoFieldCountry> _byIso = {
    for (final c in _countries) c.isoCode: c
  };
  static final Map<String, List<KitoFieldCountry>> _byDial = () {
    final map = <String, List<KitoFieldCountry>>{};
    for (final c in _countries) {
      (map[c.dialCode] ??= []).add(c);
    }
    for (final list in map.values) {
      list.sort((a, b) =>
          (b.isMainCountryForDialCode ? 1 : 0) -
          (a.isMainCountryForDialCode ? 1 : 0));
    }
    return map;
  }();

  /// Every region, sorted by English name.
  static List<KitoFieldCountry> get all => List.unmodifiable(_sorted);

  /// The region for an ISO code ("ke" works too), or null.
  static KitoFieldCountry? byIsoCode(String isoCode) =>
      _byIso[isoCode.toUpperCase()];

  /// Every region using [dialCode], main region first.
  static List<KitoFieldCountry> byDialCode(String dialCode) =>
      List.unmodifiable(_byDial[dialCode] ?? const []);

  /// Kenya.
  static KitoFieldCountry get kenya => _byIso['KE']!;

  /// The United States.
  static KitoFieldCountry get unitedStates => _byIso['US']!;

  /// The device's region, falling back to [fallback] (the United States by default).
  static KitoFieldCountry current({String fallback = 'US'}) {
    final code = PlatformDispatcher.instance.locale.countryCode;
    return (code == null ? null : byIsoCode(code)) ??
        byIsoCode(fallback) ??
        unitedStates;
  }

  /// Regions whose name, ISO code or dial code matches [query], best matches first.
  static List<KitoFieldCountry> search(String query) {
    final q = query.trim().toLowerCase().replaceAll('+', '');
    if (q.isEmpty) return all;
    final starts = <KitoFieldCountry>[];
    final contains = <KitoFieldCountry>[];
    for (final c in _sorted) {
      final name = c.englishName.toLowerCase();
      if (name.startsWith(q) ||
          c.isoCode.toLowerCase() == q ||
          c.dialCode == q) {
        starts.add(c);
      } else if (name.contains(q) || c.dialCode.startsWith(q)) {
        contains.add(c);
      }
    }
    return [...starts, ...contains];
  }

  /// Splits international digits (no "+") into a region and its national number: the longest
  /// matching dial code wins, and leading digits pick between regions that share it.
  static (KitoFieldCountry, String)? match(String internationalDigits) {
    final digits = internationalDigits.kitoAsciiDigits;
    for (var length = digits.length < 3 ? digits.length : 3;
        length >= 1;
        length--) {
      final candidates = _byDial[digits.substring(0, length)];
      if (candidates == null || candidates.isEmpty) continue;
      final national = digits.substring(length);
      KitoFieldCountry? specific;
      for (final c in candidates) {
        if (!c.isMainCountryForDialCode &&
            c.leadingDigits.any(national.startsWith)) {
          specific = c;
          break;
        }
      }
      return (specific ?? candidates.first, national);
    }
    return null;
  }
}
