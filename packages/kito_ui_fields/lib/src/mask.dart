// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

/// An input mask: `#` takes a digit, `A` a letter, `*` a letter or digit; anything else is a
/// literal that's inserted for you ("(###) ###-####", "AA## ####").
///
/// Digits typed in other scripts (Arabic-Indic, Persian…) are converted to ASCII first.
///
/// ```dart
/// TextField(inputFormatters: [KitoFieldMask('#### #### #### ####').formatter]);
/// ```
@immutable
class KitoFieldMask {
  /// Creates a mask.
  const KitoFieldMask(this.pattern, {this.uppercase = true});

  /// The pattern.
  final String pattern;

  /// Uppercases letters placed in `A` and `*` slots.
  final bool uppercase;

  /// How many characters the mask takes.
  int get capacity => _slotCount(pattern);

  static bool _isSlot(String c) => c == '#' || c == 'A' || c == '*';

  static int _slotCount(String pattern) {
    var n = 0;
    for (final c in pattern.split('')) {
      if (_isSlot(c)) n++;
    }
    return n;
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);

  static bool _fits(String slot, String c) {
    final digit = c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
    return switch (slot) {
      '#' => digit,
      'A' => _letter.hasMatch(c),
      _ => digit || _letter.hasMatch(c),
    };
  }

  /// The characters of [input] the mask keeps, in order (literals and misfits dropped).
  String raw(String input) {
    final chars = input.kitoNormalizedDigits.split('');
    final slots = [
      for (final c in pattern.split(''))
        if (_isSlot(c)) c
    ];
    final out = StringBuffer();
    var slot = 0;
    for (final c in chars) {
      if (slot >= slots.length) break;
      if (_fits(slots[slot], c)) {
        out.write(slots[slot] == '#' || !uppercase ? c : c.toUpperCase());
        slot++;
      }
    }
    return out.toString();
  }

  /// [input]'s characters placed into the mask, stopping after the last one (no dangling
  /// separators). Characters beyond the mask are dropped unless [overflow] is true, in which
  /// case they're appended.
  String apply(String input, {bool overflow = false}) {
    final value = overflow ? input.kitoNormalizedDigits : raw(input);
    final out = StringBuffer();
    final pending = StringBuffer();
    var i = 0;
    for (final c in pattern.split('')) {
      if (i >= value.length) break;
      if (_isSlot(c)) {
        out
          ..write(pending)
          ..write(value[i]);
        pending.clear();
        i++;
      } else {
        pending.write(c);
      }
    }
    if (overflow && i < value.length) out.write(value.substring(i));
    return out.toString();
  }

  /// True when [input] fills every slot.
  bool isComplete(String input) => raw(input).length == capacity;

  /// A [TextInputFormatter] that applies the mask as the user types and keeps the caret after
  /// the same character it was after.
  TextInputFormatter get formatter => _KitoFieldMaskFormatter(this);
}

class _KitoFieldMaskFormatter extends TextInputFormatter {
  _KitoFieldMaskFormatter(this.mask);
  final KitoFieldMask mask;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Deleting just a literal ("123 |") should delete the character before it too.
    var text = newValue.text;
    var caret = newValue.selection.baseOffset;
    if (text.length < oldValue.text.length &&
        mask.raw(text) == mask.raw(oldValue.text) &&
        caret > 0) {
      final before = mask.raw(text.substring(0, caret.clamp(0, text.length)));
      final after = mask.raw(text.substring(caret.clamp(0, text.length)));
      if (before.isNotEmpty) {
        final trimmed = before.substring(0, before.length - 1);
        text = trimmed + after;
        caret = trimmed.length;
        final formatted = mask.apply(text);
        return TextEditingValue(
          text: formatted,
          selection:
              TextSelection.collapsed(offset: _offsetAfter(formatted, caret)),
        );
      }
    }
    final keptBefore = caret < 0
        ? mask.raw(text).length
        : mask.raw(text.substring(0, caret.clamp(0, text.length))).length;
    final formatted = mask.apply(text);
    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(offset: _offsetAfter(formatted, keptBefore)),
    );
  }

  /// The offset in [formatted] just after its [count]-th kept character.
  int _offsetAfter(String formatted, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    final pattern = mask.pattern;
    for (var i = 0; i < formatted.length; i++) {
      if (i < pattern.length && KitoFieldMask._isSlot(pattern[i])) seen++;
      if (seen == count) return i + 1;
    }
    return formatted.length;
  }
}

/// Converts digits typed in other scripts (Arabic-Indic `٣`, Persian `۳`…) to ASCII, and
/// optionally drops everything that isn't a digit.
class KitoFieldDigitsFormatter extends TextInputFormatter {
  /// Creates the formatter. With [digitsOnly], non-digits are removed; [maxLength] caps the
  /// number of digits.
  KitoFieldDigitsFormatter({this.digitsOnly = false, this.maxLength});

  /// Removes anything that isn't a digit.
  final bool digitsOnly;

  /// The most digits allowed.
  final int? maxLength;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = digitsOnly
        ? newValue.text.kitoAsciiDigits
        : newValue.text.kitoNormalizedDigits;
    if (maxLength != null && text.length > maxLength!) {
      text = text.substring(0, maxLength);
    }
    if (text == newValue.text) return newValue;
    final removed = newValue.text.length - text.length;
    final caret =
        (newValue.selection.baseOffset - removed).clamp(0, text.length);
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: caret));
  }
}
