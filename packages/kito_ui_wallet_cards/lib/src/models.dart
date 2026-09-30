// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'number.dart';

int _ids = 0;

String _newId() =>
    'card-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_ids++}';

/// The issuer or network mark in a card's corner. Drawn, not bundled: bring your own brand by
/// passing its wordmark, an icon, or a pair of overlapping circles.
@immutable
sealed class KitoWalletCardMark {
  const KitoWalletCardMark();

  /// A word in heavy type, e.g. `KitoWalletCardMark.wordmark('NOVA', italic: true)`.
  const factory KitoWalletCardMark.wordmark(String text, {bool italic}) =
      KitoWalletWordmark;

  /// An icon.
  const factory KitoWalletCardMark.icon(IconData icon) = KitoWalletIconMark;

  /// Two overlapping circles.
  const factory KitoWalletCardMark.circles(Color first, Color second) =
      KitoWalletCirclesMark;

  /// No mark.
  static const KitoWalletCardMark none = KitoWalletNoMark();

  /// A neutral mark for a detected brand: its name as a wordmark, circles for Mastercard, a
  /// phone icon for mobile money. Swap in your own artwork where you have the rights to it.
  static KitoWalletCardMark forBrand(KitoWalletCardBrand brand) =>
      switch (brand) {
        KitoWalletCardBrand.visa =>
          const KitoWalletCardMark.wordmark('VISA', italic: true),
        KitoWalletCardBrand.mastercard => const KitoWalletCardMark.circles(
            Color(0xE6FFFFFF), Color(0x99FFFFFF)),
        KitoWalletCardBrand.amex => const KitoWalletCardMark.wordmark('AMEX'),
        KitoWalletCardBrand.discover =>
          const KitoWalletCardMark.wordmark('DISCOVER'),
        KitoWalletCardBrand.dinersClub =>
          const KitoWalletCardMark.wordmark('DINERS'),
        KitoWalletCardBrand.jcb => const KitoWalletCardMark.wordmark('JCB'),
        KitoWalletCardBrand.unionPay =>
          const KitoWalletCardMark.wordmark('UnionPay'),
        KitoWalletCardBrand.verve =>
          const KitoWalletCardMark.wordmark('verve', italic: true),
        KitoWalletCardBrand.mobileMoney =>
          const KitoWalletCardMark.icon(Icons.phone_iphone_rounded),
        KitoWalletCardBrand.unknown =>
          const KitoWalletCardMark.icon(Icons.credit_card_rounded),
      };
}

/// A wordmark.
final class KitoWalletWordmark extends KitoWalletCardMark {
  /// Creates a wordmark.
  const KitoWalletWordmark(this.text, {this.italic = false});

  /// The word.
  final String text;

  /// Slants it.
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is KitoWalletWordmark &&
      other.text == text &&
      other.italic == italic;

  @override
  int get hashCode => Object.hash(text, italic);
}

/// An icon mark.
final class KitoWalletIconMark extends KitoWalletCardMark {
  /// Creates an icon mark.
  const KitoWalletIconMark(this.icon);

  /// The icon.
  final IconData icon;

  @override
  bool operator ==(Object other) =>
      other is KitoWalletIconMark && other.icon == icon;

  @override
  int get hashCode => icon.hashCode;
}

/// Two overlapping circles.
final class KitoWalletCirclesMark extends KitoWalletCardMark {
  /// Creates a circles mark.
  const KitoWalletCirclesMark(this.first, this.second);

  /// The circle at the start.
  final Color first;

  /// The circle at the end.
  final Color second;

  @override
  bool operator ==(Object other) =>
      other is KitoWalletCirclesMark &&
      other.first == first &&
      other.second == second;

  @override
  int get hashCode => Object.hash(first, second);
}

/// No mark.
final class KitoWalletNoMark extends KitoWalletCardMark {
  /// Creates the empty mark.
  const KitoWalletNoMark();

  @override
  bool operator ==(Object other) => other is KitoWalletNoMark;

  @override
  int get hashCode => 0;
}

/// A background texture on the card face.
enum KitoWalletCardPattern {
  /// Plain.
  none,

  /// Soft concentric waves from a corner.
  waves,

  /// Large translucent circles.
  circles,

  /// A fine diagonal line texture, like brushed metal.
  brushed,

  /// A dot grid.
  dots,

  /// A glossy diagonal sheen.
  gloss,
}

/// How a card looks: its fill, text colour, texture and corners.
@immutable
class KitoWalletCardStyle {
  /// Creates a style.
  const KitoWalletCardStyle({
    required this.colors,
    this.foreground = Colors.white,
    this.pattern = KitoWalletCardPattern.none,
    this.cornerRadius = 20,
    this.showsBorder = false,
    this.isGlass = false,
  });

  /// The gradient, from the top start corner to the bottom end corner.
  final List<Color> colors;

  /// Text and marks.
  final Color foreground;

  /// The texture.
  final KitoWalletCardPattern pattern;

  /// Corner radius at a 320-point-wide card; it scales with the card.
  final double cornerRadius;

  /// A thin inner border, for dark or glass cards.
  final bool showsBorder;

  /// Frosted glass: blurs what's behind the card and tints it with [colors].
  final bool isGlass;

  /// Blue to cyan with waves.
  static const ocean = KitoWalletCardStyle(
      colors: [Color(0xFF1A73F2), Color(0xFF1ABFF2)],
      pattern: KitoWalletCardPattern.waves);

  /// Orange to pink with circles.
  static const sunset = KitoWalletCardStyle(
      colors: [Color(0xFFFF8C33), Color(0xFFF2407F)],
      pattern: KitoWalletCardPattern.circles);

  /// Teal to blue with a gloss.
  static const aqua = KitoWalletCardStyle(
      colors: [Color(0xFF1ABFD9), Color(0xFF268CF2)],
      pattern: KitoWalletCardPattern.gloss);

  /// Near-black brushed metal with a hairline border.
  static const midnight = KitoWalletCardStyle(
      colors: [Color(0xFF1F1F1F), Color(0xFF050505)],
      pattern: KitoWalletCardPattern.brushed,
      showsBorder: true);

  /// Soft violet with dark text.
  static const lavender = KitoWalletCardStyle(
      colors: [Color(0xFFB8ADFA), Color(0xFF998CF2)], foreground: Colors.black);

  /// Lime with dots and dark text.
  static const lime = KitoWalletCardStyle(
      colors: [Color(0xFFC7F273), Color(0xFF9EE04D)],
      foreground: Colors.black,
      pattern: KitoWalletCardPattern.dots);

  /// Pearl white with a gloss.
  static const pearl = KitoWalletCardStyle(
      colors: [Color(0xFFF5F5F5), Color(0xFFDBDBDB)],
      foreground: Colors.black,
      pattern: KitoWalletCardPattern.gloss);

  /// Brushed gold.
  static const gold = KitoWalletCardStyle(
      colors: [Color(0xFFF2CC73), Color(0xFFBF8C33)],
      foreground: Color(0xFF402E0D),
      pattern: KitoWalletCardPattern.brushed);

  /// Mobile-money green with circles.
  static const safari = KitoWalletCardStyle(
      colors: [Color(0xFF16A34A), Color(0xFF0B6B3A)],
      pattern: KitoWalletCardPattern.circles);

  /// Frosted glass over whatever is behind it.
  static const glass = KitoWalletCardStyle(
      colors: [Color(0x59FFFFFF), Color(0x1AFFFFFF)],
      pattern: KitoWalletCardPattern.gloss,
      showsBorder: true,
      isGlass: true);

  /// Every preset, for pickers.
  static const presets = [
    ocean,
    sunset,
    aqua,
    midnight,
    lavender,
    lime,
    pearl,
    gold,
    safari,
    glass,
  ];

  /// A copy with some fields replaced.
  KitoWalletCardStyle copyWith({
    List<Color>? colors,
    Color? foreground,
    KitoWalletCardPattern? pattern,
    double? cornerRadius,
    bool? showsBorder,
    bool? isGlass,
  }) =>
      KitoWalletCardStyle(
        colors: colors ?? this.colors,
        foreground: foreground ?? this.foreground,
        pattern: pattern ?? this.pattern,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        showsBorder: showsBorder ?? this.showsBorder,
        isGlass: isGlass ?? this.isGlass,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoWalletCardStyle &&
      _sameColors(other.colors, colors) &&
      other.foreground == foreground &&
      other.pattern == pattern &&
      other.cornerRadius == cornerRadius &&
      other.showsBorder == showsBorder &&
      other.isGlass == isGlass;

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(colors), foreground, pattern,
      cornerRadius, showsBorder, isGlass);
}

/// A payment card or wallet. It only ever holds the last four digits (or a masked phone
/// number) — never a full number.
@immutable
class KitoWalletCard {
  /// Creates a card from its last four digits.
  KitoWalletCard({
    String? id,
    required this.name,
    required String last4,
    this.holder = '',
    this.expiry = '',
    this.balance = 0,
    this.currencyCode = 'KES',
    this.brand = KitoWalletCardBrand.unknown,
    KitoWalletCardMark? mark,
    this.style = KitoWalletCardStyle.ocean,
    this.issuer,
  })  : id = id ?? _newId(),
        last4 = KitoWalletCardNumber.last4(last4),
        maskedNumber = KitoWalletCardNumber.masked(last4, brand: brand),
        mark = mark ?? KitoWalletCardMark.forBrand(brand);

  /// Creates a card from a full number: detects the brand, keeps the last four digits and
  /// throws the rest away.
  factory KitoWalletCard.fromNumber(
    String number, {
    String? id,
    required String name,
    String holder = '',
    String expiry = '',
    double balance = 0,
    String currencyCode = 'KES',
    KitoWalletCardMark? mark,
    KitoWalletCardStyle style = KitoWalletCardStyle.ocean,
    String? issuer,
  }) =>
      KitoWalletCard(
        id: id,
        name: name,
        last4: number,
        holder: holder,
        expiry: expiry,
        balance: balance,
        currencyCode: currencyCode,
        brand: KitoWalletCardNumber.brandOf(number),
        mark: mark,
        style: style,
        issuer: issuer,
      );

  /// A mobile-money wallet on a phone number, M-Pesa style; the number is shown as
  /// "0712 ••• 678".
  KitoWalletCard.mobileMoney({
    String? id,
    required String phone,
    this.name = 'Mobile money',
    this.holder = '',
    this.balance = 0,
    this.currencyCode = 'KES',
    KitoWalletCardMark? mark,
    this.style = KitoWalletCardStyle.safari,
    this.issuer,
  })  : id = id ?? _newId(),
        brand = KitoWalletCardBrand.mobileMoney,
        expiry = '',
        last4 = KitoWalletCardNumber.last4(phone),
        maskedNumber = KitoWalletCardNumber.maskedPhone(phone),
        mark = mark ??
            KitoWalletCardMark.forBrand(KitoWalletCardBrand.mobileMoney);

  const KitoWalletCard._copy({
    required this.id,
    required this.name,
    required this.last4,
    required this.maskedNumber,
    required this.holder,
    required this.expiry,
    required this.balance,
    required this.currencyCode,
    required this.brand,
    required this.mark,
    required this.style,
    required this.issuer,
  });

  /// Identifies the card.
  final String id;

  /// What the card is for: "Everyday", "Savings", "Travel".
  final String name;

  /// The last four digits.
  final String last4;

  /// The number as shown: "•••• •••• •••• 4120", "0712 ••• 678".
  final String maskedNumber;

  /// The name on the card.
  final String holder;

  /// "MM/YY"; empty for wallets.
  final String expiry;

  /// The balance or available credit.
  final double balance;

  /// ISO 4217 code, e.g. "KES".
  final String currencyCode;

  /// The network.
  final KitoWalletCardBrand brand;

  /// The mark in the corner.
  final KitoWalletCardMark mark;

  /// How the face looks.
  final KitoWalletCardStyle style;

  /// The bank or provider, e.g. "Equity", "M-Pesa".
  final String? issuer;

  /// "KES 7,450".
  String get formattedBalance => KitoWalletMoney.format(balance, currencyCode);

  /// "•••• 4120".
  String get shortNumber =>
      brand.isMobileMoney ? maskedNumber : KitoWalletCardNumber.short(last4);

  /// What screen readers say: "Everyday Visa ending 4120".
  String get semanticLabel => brand.isMobileMoney
      ? '$name ${issuer ?? brand.displayName}, $maskedNumber'
      : '$name ${brand == KitoWalletCardBrand.unknown ? 'card' : brand.displayName} ending $last4';

  /// A copy with some fields replaced.
  KitoWalletCard copyWith({
    String? name,
    String? holder,
    double? balance,
    KitoWalletCardStyle? style,
    KitoWalletCardMark? mark,
  }) =>
      KitoWalletCard._copy(
        id: id,
        name: name ?? this.name,
        last4: last4,
        maskedNumber: maskedNumber,
        holder: holder ?? this.holder,
        expiry: expiry,
        balance: balance ?? this.balance,
        currencyCode: currencyCode,
        brand: brand,
        mark: mark ?? this.mark,
        style: style ?? this.style,
        issuer: issuer,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoWalletCard &&
      other.id == id &&
      other.name == name &&
      other.last4 == last4 &&
      other.maskedNumber == maskedNumber &&
      other.holder == holder &&
      other.expiry == expiry &&
      other.balance == balance &&
      other.currencyCode == currencyCode &&
      other.brand == brand &&
      other.mark == mark &&
      other.style == style &&
      other.issuer == issuer;

  @override
  int get hashCode => Object.hash(id, name, last4, maskedNumber, holder, expiry,
      balance, currencyCode, brand, mark, style, issuer);
}

/// Sums and formats balances.
extension KitoWalletCardTotals on Iterable<KitoWalletCard> {
  /// The sum of the balances. Mixed currencies are summed as-is; convert first if they differ.
  double get totalBalance => fold(0, (sum, c) => sum + c.balance);
}

/// Small, locale-free money formatting: "KES 7,450", "$1,204.50", "€12".
abstract final class KitoWalletMoney {
  static const _symbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'NGN': '₦',
  };

  /// [amount] with thousands separators and [decimals] places, after the currency's symbol
  /// (or its code and a space).
  static String format(double amount, String currencyCode, {int decimals = 0}) {
    final negative = amount < 0;
    final fixed = amount.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
      grouped.write(whole[i]);
    }
    final number =
        parts.length > 1 ? '$grouped.${parts[1]}' : grouped.toString();
    final symbol = _symbols[currencyCode.toUpperCase()];
    final body = symbol == null
        ? '${currencyCode.toUpperCase()} $number'
        : '$symbol$number';
    return negative ? '−$body' : body;
  }

  /// A value between [from] and [to] at [t] (0–1), for counting-up animations.
  static double lerp(double from, double to, double t) =>
      from + (to - from) * math.max(0, math.min(1, t));
}

/// Card faces are ID-1 sized: 85.6 × 53.98 mm.
abstract final class KitoWalletCardGeometry {
  /// Width over height.
  static const double aspectRatio = 85.6 / 53.98;

  /// The design width everything on a face is measured against.
  static const double designWidth = 320;
}
