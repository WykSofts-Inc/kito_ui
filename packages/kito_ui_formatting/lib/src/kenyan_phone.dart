// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/services.dart';

/// The mobile network a Kenyan number was issued on — best-effort from its prefix. Numbers can
/// be ported, so never use this to decide where money goes.
enum KitoKenyanCarrier {
  /// Safaricom.
  safaricom('Safaricom', 'M-Pesa'),

  /// Airtel.
  airtel('Airtel', 'Airtel Money'),

  /// Telkom.
  telkom('Telkom', 'T-Kash'),

  /// Not recognised.
  unknown('Other network', null);

  const KitoKenyanCarrier(this.displayName, this.walletName);

  /// "Safaricom".
  final String displayName;

  /// The mobile-money wallet usually tied to this network, "M-Pesa".
  final String? walletName;
}

/// A Kenyan mobile number parsed from however it was typed — "0712 345 678", "712345678",
/// "+254 712 345 678", "254712345678" — and printable every common way.
///
/// ```dart
/// final phone = KitoKenyanPhoneNumber.tryParse('0712 345 678')!;
/// phone.e164;           // +254712345678
/// phone.international;  // +254 712 345 678
/// phone.masked;         // +254 7•• ••• 678
/// phone.carrier;        // KitoKenyanCarrier.safaricom
/// ```
class KitoKenyanPhoneNumber {
  const KitoKenyanPhoneNumber._(this.nationalNumber);

  /// A number, or null unless [raw] is a nine-digit mobile number starting 7 or 1.
  static KitoKenyanPhoneNumber? tryParse(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('254') && digits.length == 12) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }
    if (digits.length != 9 ||
        !(digits.startsWith('7') || digits.startsWith('1'))) {
      return null;
    }
    return KitoKenyanPhoneNumber._(digits);
  }

  /// True if [raw] parses.
  static bool isValid(String raw) => tryParse(raw) != null;

  /// The nine digits after the country code, "712345678".
  final String nationalNumber;

  /// "+254712345678" — for APIs and `tel:` links.
  String get e164 => '+254$nationalNumber';

  /// "+254 712 345 678".
  String get international => '+254 ${group(nationalNumber, const [3, 3, 3])}';

  /// "0712 345 678" — how Kenyans write it.
  String get local => group('0$nationalNumber', const [4, 3, 3]);

  /// "+254 7•• ••• 678" — for confirmation screens.
  String get masked {
    final hidden = StringBuffer();
    for (var i = 0; i < nationalNumber.length; i++) {
      hidden.write(i >= 1 && i <= 5 ? '•' : nationalNumber[i]);
    }
    return '+254 ${group(hidden.toString(), const [3, 3, 3])}';
  }

  /// The best-guess network.
  KitoKenyanCarrier get carrier {
    final p = int.tryParse(nationalNumber.substring(0, 3));
    if (p == null) return KitoKenyanCarrier.unknown;
    bool within(int a, int b) => p >= a && p <= b;
    if (within(700, 729) ||
        within(740, 748) ||
        within(757, 759) ||
        within(768, 769) ||
        within(790, 799) ||
        within(110, 115)) {
      return KitoKenyanCarrier.safaricom;
    }
    if (within(730, 739) ||
        within(750, 756) ||
        p == 762 ||
        within(780, 789) ||
        within(100, 102)) {
      return KitoKenyanCarrier.airtel;
    }
    if (within(770, 779)) return KitoKenyanCarrier.telkom;
    return KitoKenyanCarrier.unknown;
  }

  /// A `tel:` link for a call button.
  Uri get callUri => Uri(scheme: 'tel', path: e164);

  /// Splits [text] into groups of [sizes] joined by spaces; anything left over is a last group.
  static String group(String text, List<int> sizes) {
    final groups = <String>[];
    var rest = text;
    for (final size in sizes) {
      if (rest.isEmpty) break;
      final take = size < rest.length ? size : rest.length;
      groups.add(rest.substring(0, take));
      rest = rest.substring(take);
    }
    if (rest.isNotEmpty) groups.add(rest);
    return groups.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      other is KitoKenyanPhoneNumber && other.nationalNumber == nationalNumber;

  @override
  int get hashCode => nationalNumber.hashCode;

  @override
  String toString() => e164;
}

/// Phone formatting while typing.
abstract final class KitoPhoneFormatting {
  /// Formats a Kenyan number as it's typed: "0712 345 678" for local input, or
  /// "+254 712 345 678" once it starts with "+" or "254". Extra digits are dropped.
  static String kenyanAsYouType(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final international =
        raw.trimLeft().startsWith('+') || digits.startsWith('254');
    if (international) {
      final national = digits.substring(digits.length < 3 ? digits.length : 3);
      final nine = national.length > 9 ? national.substring(0, 9) : national;
      final head = digits.length >= 3 ? '+254' : '+$digits';
      return nine.isEmpty
          ? head
          : '$head ${KitoKenyanPhoneNumber.group(nine, const [3, 3, 3])}';
    }
    final ten = digits.length > 10 ? digits.substring(0, 10) : digits;
    return KitoKenyanPhoneNumber.group(ten, const [4, 3, 3]);
  }
}

/// A [TextInputFormatter] that groups a Kenyan number as it's typed (see
/// [KitoPhoneFormatting.kenyanAsYouType]), keeping the caret after the same digit.
///
/// ```dart
/// TextField(
///   keyboardType: TextInputType.phone,
///   inputFormatters: [KitoKenyanPhoneInputFormatter()],
/// )
/// ```
class KitoKenyanPhoneInputFormatter extends TextInputFormatter {
  static final _digit = RegExp(r'\d');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final formatted = KitoPhoneFormatting.kenyanAsYouType(text);
    // Where the caret was, counted in digits, mapped onto the formatted text.
    final caret = newValue.selection.baseOffset.clamp(0, text.length);
    final digitsBefore =
        text.substring(0, caret).replaceAll(RegExp(r'\D'), '').length;
    var seen = 0, offset = 0;
    while (offset < formatted.length && seen < digitsBefore) {
      if (_digit.hasMatch(formatted[offset])) seen++;
      offset++;
    }
    if (digitsBefore == 0 && formatted.startsWith('+')) offset = 1;
    return TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(offset: offset.clamp(0, formatted.length)),
    );
  }
}
