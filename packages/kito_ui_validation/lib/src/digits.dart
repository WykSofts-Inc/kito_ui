// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

/// Digit helpers shared by the rules and by `kito_ui_fields`.
extension KitoValidationDigits on String {
  /// This string with digits from other scripts converted to ASCII: Arabic-Indic `٠١٢`,
  /// Persian `۰۱۲`, Devanagari `०१२` and the full-width `０１２` all become `012`. Every other
  /// character is kept as it is.
  ///
  /// A number pad set to Arabic numerals then still types into phone, card and code fields.
  String get kitoNormalizedDigits {
    final buffer = StringBuffer();
    for (final rune in runes) {
      final digit = kitoDigitValue(rune);
      if (digit != null && rune > 0x7F) {
        buffer.writeCharCode(0x30 + digit);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Only the decimal digits in this string, as ASCII — separators, spaces and letters are
  /// dropped, digits from other scripts are converted.
  String get kitoAsciiDigits {
    final buffer = StringBuffer();
    for (final rune in runes) {
      final digit = kitoDigitValue(rune);
      if (digit != null) buffer.writeCharCode(0x30 + digit);
    }
    return buffer.toString();
  }
}

/// Zero-points of the decimal digit blocks worth supporting in form input.
const List<int> _digitZeros = [
  0x0030, // ASCII
  0x0660, // Arabic-Indic
  0x06F0, // Extended Arabic-Indic (Persian, Urdu)
  0x0966, // Devanagari
  0x09E6, // Bengali
  0x0E50, // Thai
  0xFF10, // Full-width
];

/// The value 0–9 of [rune] when it is a decimal digit in a supported script, otherwise null.
int? kitoDigitValue(int rune) {
  for (final zero in _digitZeros) {
    if (rune >= zero && rune <= zero + 9) return rune - zero;
  }
  return null;
}
