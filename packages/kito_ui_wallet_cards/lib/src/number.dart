// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/services.dart';

/// A card network or wallet, detected from the number.
enum KitoWalletCardBrand {
  /// Visa (4…).
  visa('Visa', [4, 4, 4, 4], 3),

  /// Mastercard (51–55, 2221–2720).
  mastercard('Mastercard', [4, 4, 4, 4], 3),

  /// American Express (34, 37).
  amex('American Express', [4, 6, 5], 4),

  /// Discover (6011, 644–649, 65).
  discover('Discover', [4, 4, 4, 4], 3),

  /// Diners Club (300–305, 36, 38, 39).
  dinersClub('Diners Club', [4, 6, 4], 3),

  /// JCB (3528–3589).
  jcb('JCB', [4, 4, 4, 4], 3),

  /// UnionPay (62).
  unionPay('UnionPay', [4, 4, 4, 4], 3),

  /// Verve (5060–5061, 5078–5079, 6500).
  verve('Verve', [4, 4, 4, 4, 3], 3),

  /// A mobile-money wallet on a phone number, M-Pesa style (07…, 01…, +254…).
  mobileMoney('Mobile money', [4, 3, 3], 0),

  /// Not recognised (yet).
  unknown('Card', [4, 4, 4, 4], 3);

  const KitoWalletCardBrand(this.displayName, this.groups, this.cvvLength);

  /// "American Express".
  final String displayName;

  /// How the digits are grouped: `[4, 6, 5]` for Amex.
  final List<int> groups;

  /// How many digits the security code has; 0 for wallets without one.
  final int cvvLength;

  /// The most digits a number of this brand has.
  int get maxLength => groups.fold(0, (a, b) => a + b);

  /// True for the phone-number wallet.
  bool get isMobileMoney => this == mobileMoney;
}

/// Pure helpers for card and wallet numbers: brand detection, grouping, masking, Luhn and expiry.
///
/// ```dart
/// KitoWalletCardNumber.brandOf('4111 1111');           // visa
/// KitoWalletCardNumber.format('378282246310005');      // "3782 822463 10005"
/// KitoWalletCardNumber.masked('0005', brand: KitoWalletCardBrand.amex);  // "•••• •••••• •0005"
/// KitoWalletCardNumber.maskedPhone('0712345678');      // "0712 ••• 678"
/// KitoWalletCardNumber.isValid('4242424242424242');    // true (Luhn)
/// ```
abstract final class KitoWalletCardNumber {
  /// The masking dot.
  static const dot = '•';

  /// [input] without spaces, dashes or other non-digits.
  static String digits(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// The brand for a (possibly partial) number. Phone numbers (`07…`, `01…`, `+254…`, `254…`)
  /// are [KitoWalletCardBrand.mobileMoney].
  static KitoWalletCardBrand brandOf(String input) {
    final trimmed = input.trim();
    final d = digits(trimmed);
    if (d.isEmpty) return KitoWalletCardBrand.unknown;
    if (trimmed.startsWith('+') ||
        RegExp(r'^0[17]').hasMatch(d) ||
        (d.startsWith('254') && d.length >= 4 && '17'.contains(d[3]))) {
      return KitoWalletCardBrand.mobileMoney;
    }
    int prefix(int n) => d.length >= n ? int.parse(d.substring(0, n)) : -1;
    if (d.startsWith('4')) return KitoWalletCardBrand.visa;
    if (d.startsWith('34') || d.startsWith('37')) {
      return KitoWalletCardBrand.amex;
    }
    final p4 = prefix(4);
    if ((p4 >= 5060 && p4 <= 5061) ||
        (p4 >= 5078 && p4 <= 5079) ||
        p4 == 6500) {
      return KitoWalletCardBrand.verve;
    }
    final p2 = prefix(2);
    if (p2 >= 51 && p2 <= 55) return KitoWalletCardBrand.mastercard;
    if (p4 >= 2221 && p4 <= 2720) return KitoWalletCardBrand.mastercard;
    if (d.startsWith('6011') || d.startsWith('65')) {
      return KitoWalletCardBrand.discover;
    }
    final p3 = prefix(3);
    if (p3 >= 644 && p3 <= 649) return KitoWalletCardBrand.discover;
    if (d.startsWith('62')) return KitoWalletCardBrand.unionPay;
    if (p4 >= 3528 && p4 <= 3589) return KitoWalletCardBrand.jcb;
    if ((p3 >= 300 && p3 <= 305) || p2 == 36 || p2 == 38 || p2 == 39) {
      return KitoWalletCardBrand.dinersClub;
    }
    return KitoWalletCardBrand.unknown;
  }

  /// [input]'s digits grouped for its brand ("4111 1111 1111 1111", "3782 822463 10005",
  /// "0712 345 678"), cut at the brand's length.
  static String format(String input, {KitoWalletCardBrand? brand}) {
    final b = brand ?? brandOf(input);
    var d = digits(input);
    if (b.isMobileMoney) d = _localPhone(d);
    if (d.length > b.maxLength) d = d.substring(0, b.maxLength);
    return _group(d, b.groups);
  }

  static String _group(String d, List<int> groups) {
    final out = StringBuffer();
    var start = 0;
    for (final size in groups) {
      if (start >= d.length) break;
      if (out.isNotEmpty) out.write(' ');
      final end = start + size > d.length ? d.length : start + size;
      out.write(d.substring(start, end));
      start = end;
    }
    if (start < d.length) out.write(' ${d.substring(start)}');
    return out.toString();
  }

  /// "254712345678" or "712345678" → "0712345678".
  static String _localPhone(String d) {
    if (d.startsWith('254')) return '0${d.substring(3)}';
    if (d.length == 9 && '17'.contains(d[0])) return '0$d';
    return d;
  }

  /// The last four digits of [input] (fewer if it's shorter).
  static String last4(String input) {
    final d = digits(input);
    return d.length <= 4 ? d : d.substring(d.length - 4);
  }

  /// A number shown with only its last four digits, grouped for the brand:
  /// "•••• •••• •••• 4120", or "•••• •••••• •0005" for Amex.
  static String masked(String last4,
      {KitoWalletCardBrand brand = KitoWalletCardBrand.unknown}) {
    final tail = digits(last4);
    final shown = tail.length > 4 ? tail.substring(tail.length - 4) : tail;
    final total = brand.isMobileMoney ? 16 : brand.maxLength;
    final hidden = total - shown.length;
    return _group(
        '${dot * (hidden < 0 ? 0 : hidden)}$shown',
        brand.isMobileMoney
            ? KitoWalletCardBrand.unknown.groups
            : brand.groups);
  }

  /// "•••• 4120" — the short form for lists.
  static String short(String last4) =>
      '${dot * 4} ${KitoWalletCardNumber.last4(last4)}';

  /// A phone wallet number with its middle hidden, the way M-Pesa shows it: "0712 ••• 678".
  static String maskedPhone(String phone) {
    final d = _localPhone(digits(phone));
    if (d.length < 7) return d;
    final head = d.substring(0, 4);
    final tail = d.substring(d.length - 3);
    return '$head ${dot * (d.length - 7)} $tail';
  }

  /// True when [input] passes the Luhn check and has a plausible length (12–19 digits).
  static bool isValid(String input) {
    final d = digits(input);
    if (d.length < 12 || d.length > 19) return false;
    var sum = 0;
    var alternate = false;
    for (var i = d.length - 1; i >= 0; i--) {
      var n = d.codeUnitAt(i) - 0x30;
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// "0929" or "9/29" → "09/29".
  static String formatExpiry(String input) {
    var d = digits(input);
    if (d.isNotEmpty && int.parse(d[0]) > 1) d = '0$d';
    if (d.length > 4) d = d.substring(0, 4);
    return d.length <= 2 ? d : '${d.substring(0, 2)}/${d.substring(2)}';
  }

  /// True when "MM/YY" is a real month that hasn't passed yet (on [now], default today).
  static bool isExpiryValid(String expiry, {DateTime? now}) {
    final d = digits(expiry);
    if (d.length != 4) return false;
    final month = int.parse(d.substring(0, 2));
    final year = 2000 + int.parse(d.substring(2));
    if (month < 1 || month > 12) return false;
    final today = now ?? DateTime.now();
    return year > today.year || (year == today.year && month >= today.month);
  }
}

/// Formats a card (or wallet phone) number as it's typed, grouping digits for the detected
/// brand and keeping the cursor in place.
///
/// ```dart
/// TextField(inputFormatters: [KitoWalletCardNumberFormatter()])
/// ```
class KitoWalletCardNumberFormatter extends TextInputFormatter {
  /// Creates the formatter; set [allowsMobileMoney] to false to treat 07… as a card.
  KitoWalletCardNumberFormatter({this.allowsMobileMoney = true});

  /// Recognises phone numbers as mobile-money wallets.
  final bool allowsMobileMoney;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var brand = KitoWalletCardNumber.brandOf(newValue.text);
    if (!allowsMobileMoney && brand.isMobileMoney) {
      brand = KitoWalletCardBrand.unknown;
    }
    final formatted = KitoWalletCardNumber.format(
        newValue.text.replaceAll('+', ''),
        brand: brand);
    final digitsBefore = KitoWalletCardNumber.digits(newValue.text.substring(
            0, newValue.selection.end.clamp(0, newValue.text.length)))
        .length;
    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBefore) {
      if (formatted.codeUnitAt(offset) != 0x20) seen++;
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Formats an expiry as "MM/YY" as it's typed.
class KitoWalletExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final deleting = newValue.text.length < oldValue.text.length;
    var text = KitoWalletCardNumber.formatExpiry(newValue.text);
    if (deleting && oldValue.text.endsWith('/') && text.length == 2) {
      text = text.substring(0, 1);
    }
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
