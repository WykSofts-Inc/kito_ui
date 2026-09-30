// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';

import 'delivery.dart';
import 'models.dart';
import 'money.dart';

/// Card networks the payment tiles know.
enum KitoCheckoutCardBrand {
  /// Visa.
  visa('Visa'),

  /// Mastercard.
  mastercard('Mastercard'),

  /// American Express.
  amex('Amex'),

  /// Anything else.
  other('Card');

  const KitoCheckoutCardBrand(this.title);

  /// "Visa".
  final String title;

  /// Guesses the brand from the first digits of a card number.
  static KitoCheckoutCardBrand detect(String number) {
    final d = number.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('34') || d.startsWith('37')) return amex;
    if (d.startsWith('4')) return visa;
    final two = int.tryParse(d.length >= 2 ? d.substring(0, 2) : '') ?? 0;
    final four = int.tryParse(d.length >= 4 ? d.substring(0, 4) : '') ?? 0;
    if ((two >= 51 && two <= 55) || (four >= 2221 && four <= 2720)) {
      return mastercard;
    }
    return other;
  }
}

/// The kinds of payment method.
enum KitoCheckoutPaymentKind {
  /// An M-Pesa prompt (STK push) to a phone.
  mpesa,

  /// A saved or new card.
  card,

  /// Apple Pay.
  applePay,

  /// Google Pay.
  googlePay,

  /// Pay the rider on arrival.
  cash,

  /// Store credit.
  wallet,
}

/// A way to pay. The kit only draws the choice — charging is up to your payment provider.
@immutable
class KitoCheckoutPaymentMethod {
  /// Creates a method. Prefer the named constructors.
  const KitoCheckoutPaymentMethod({
    required this.id,
    required this.kind,
    this.phone,
    this.brand,
    this.last4,
    this.expiry,
    this.limit,
    this.balance,
    this.customTitle,
    this.unavailableNote,
  });

  /// M-Pesa to [phone].
  const KitoCheckoutPaymentMethod.mpesa(String phone, {String id = 'mpesa'})
      : this(id: id, kind: KitoCheckoutPaymentKind.mpesa, phone: phone);

  /// A saved card. [expiry] is "MM/YY".
  KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand brand, String last4,
      {String? expiry, String? id})
      : this(
            id: id ?? 'card-$last4',
            kind: KitoCheckoutPaymentKind.card,
            brand: brand,
            last4: last4.length > 4 ? last4.substring(last4.length - 4) : last4,
            expiry: expiry);

  /// A new card, entered at payment time.
  const KitoCheckoutPaymentMethod.newCard({String id = 'new-card'})
      : this(
            id: id,
            kind: KitoCheckoutPaymentKind.card,
            customTitle: 'Credit or debit card');

  /// Apple Pay.
  const KitoCheckoutPaymentMethod.applePay({String id = 'apple-pay'})
      : this(id: id, kind: KitoCheckoutPaymentKind.applePay);

  /// Google Pay.
  const KitoCheckoutPaymentMethod.googlePay({String id = 'google-pay'})
      : this(id: id, kind: KitoCheckoutPaymentKind.googlePay);

  /// Cash on delivery, up to an optional [limit] in cents.
  const KitoCheckoutPaymentMethod.cash({int? limit, String id = 'cash'})
      : this(id: id, kind: KitoCheckoutPaymentKind.cash, limit: limit);

  /// Store credit with a [balance] in cents.
  const KitoCheckoutPaymentMethod.wallet(int balance, {String id = 'wallet'})
      : this(id: id, kind: KitoCheckoutPaymentKind.wallet, balance: balance);

  /// A stable id.
  final String id;

  /// What kind it is.
  final KitoCheckoutPaymentKind kind;

  /// The M-Pesa phone.
  final String? phone;

  /// The card network.
  final KitoCheckoutCardBrand? brand;

  /// The card's last four digits.
  final String? last4;

  /// "MM/YY".
  final String? expiry;

  /// The most cash accepted, in cents.
  final int? limit;

  /// The wallet balance, in cents.
  final int? balance;

  /// Replaces the default title.
  final String? customTitle;

  /// Switches the method off with your reason.
  final String? unavailableNote;

  /// "M-Pesa", "Visa •••• 4242", "Apple Pay".
  String get title {
    if (customTitle != null) return customTitle!;
    return switch (kind) {
      KitoCheckoutPaymentKind.mpesa => 'M-Pesa',
      KitoCheckoutPaymentKind.card =>
        '${(brand ?? KitoCheckoutCardBrand.other).title} •••• ${last4 ?? ''}',
      KitoCheckoutPaymentKind.applePay => 'Apple Pay',
      KitoCheckoutPaymentKind.googlePay => 'Google Pay',
      KitoCheckoutPaymentKind.cash => 'Cash on delivery',
      KitoCheckoutPaymentKind.wallet => 'Wallet',
    };
  }

  /// The second line: "Prompt sent to 0712 ••• 678", "Expires 08/28".
  String subtitle({String currencyCode = kitoCheckoutDefaultCurrency}) =>
      switch (kind) {
        KitoCheckoutPaymentKind.mpesa =>
          'Prompt sent to ${KitoCheckoutPhone.masked(phone ?? '') ?? phone ?? ''}',
        KitoCheckoutPaymentKind.card => expiry != null
            ? 'Expires $expiry'
            : last4 == null
                ? 'Visa, Mastercard or Amex'
                : 'Saved card',
        KitoCheckoutPaymentKind.applePay => 'Pay with Face ID or Touch ID',
        KitoCheckoutPaymentKind.googlePay => 'Pay with your Google account',
        KitoCheckoutPaymentKind.cash => 'Pay the rider when it arrives',
        KitoCheckoutPaymentKind.wallet =>
          'Balance ${KitoCheckoutMoney.format(balance ?? 0, currencyCode: currencyCode)}',
      };

  /// Why this method can't pay [total] (cents), or null when it can.
  String? unavailableReason(int total,
      {String currencyCode = kitoCheckoutDefaultCurrency, DateTime? now}) {
    if (unavailableNote != null) return unavailableNote;
    switch (kind) {
      case KitoCheckoutPaymentKind.wallet:
        final b = balance ?? 0;
        if (b >= total) return null;
        return 'Balance too low — top up ${KitoCheckoutMoney.format(total - b, currencyCode: currencyCode)}';
      case KitoCheckoutPaymentKind.cash:
        if (limit == null || total <= limit!) return null;
        return 'Cash is accepted up to ${KitoCheckoutMoney.format(limit!, currencyCode: currencyCode)}';
      case KitoCheckoutPaymentKind.card:
        if (expiry == null || !isExpired(expiry!, now: now ?? DateTime.now())) {
          return null;
        }
        return 'This card has expired';
      case KitoCheckoutPaymentKind.mpesa:
        return KitoCheckoutPhone.normalize(phone ?? '') == null
            ? 'Add a valid M-Pesa number'
            : null;
      case KitoCheckoutPaymentKind.applePay:
      case KitoCheckoutPaymentKind.googlePay:
        return null;
    }
  }

  /// "MM/YY" — a card is valid to the end of its expiry month.
  static bool isExpired(String expiry, {required DateTime now}) {
    final parts = expiry.split('/').map((p) => p.trim()).toList();
    if (parts.length != 2) return false;
    final month = int.tryParse(parts[0]);
    final raw = int.tryParse(parts[1]);
    if (month == null || raw == null || month < 1 || month > 12) return false;
    final year = raw < 100 ? 2000 + raw : raw;
    return year < now.year || (year == now.year && month < now.month);
  }

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutPaymentMethod && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Readable order numbers.
abstract final class KitoCheckoutOrderNumber {
  /// Letters and digits that can't be mistaken for each other: no 0/O, 1/I/L, 5/S, 2/Z, 8/B.
  static const String alphabet = '34679ACDEFGHJKMNPQRTUVWXY';

  /// "KC-260930-0042": a prefix, the date (yyMMdd) and a padded sequence.
  static String dated(int sequence,
      {required DateTime date, String prefix = 'KC', int digits = 4}) {
    String two(int v) => v.toString().padLeft(2, '0');
    final day = '${two(date.year % 100)}${two(date.month)}${two(date.day)}';
    final n = (sequence < 0 ? 0 : sequence).toString().padLeft(digits, '0');
    return _join(prefix, [day, n]);
  }

  /// "KC-7QHM-X9TP": characters from [alphabet] picked by [next] (e.g. `Random().nextInt`), in
  /// groups.
  static String random(int Function(int max) next,
      {String prefix = 'KC', int length = 8, int groupSize = 4}) {
    final chars = List.generate(
        length < 1 ? 1 : length, (_) => alphabet[next(alphabet.length)]).join();
    return _join(prefix, grouped(chars, size: groupSize).split(' '));
  }

  /// "10423381" → "1042 3381".
  static String grouped(String raw, {int size = 4, String separator = ' '}) {
    final compact = raw.replaceAll(RegExp(r'[\s-]'), '');
    final step = size < 1 ? 1 : size;
    return [
      for (var i = 0; i < compact.length; i += step)
        compact.substring(
            i, i + step > compact.length ? compact.length : i + step)
    ].join(separator);
  }

  static String _join(String prefix, List<String> parts) {
    final p = prefix.trim().toUpperCase();
    return [if (p.isNotEmpty) p, ...parts].join('-');
  }
}

/// A placed order, for the confirmation and the receipt.
@immutable
class KitoCheckoutPlacedOrder {
  /// Creates an order. [total] is in cents.
  const KitoCheckoutPlacedOrder({
    required this.number,
    required this.placedAt,
    required this.total,
    this.items = const [],
    this.lines = const [],
    this.eta,
    this.destination,
    this.deliveryTitle,
    this.paymentTitle,
    this.currencyCode = kitoCheckoutDefaultCurrency,
  });

  /// An order from the checkout's [totals]; the total line itself is left out of [lines].
  factory KitoCheckoutPlacedOrder.fromTotals(
    KitoCheckoutTotals totals, {
    required String number,
    required DateTime placedAt,
    String? eta,
    String? destination,
    String? deliveryTitle,
    String? paymentTitle,
  }) =>
      KitoCheckoutPlacedOrder(
        number: number,
        placedAt: placedAt,
        total: totals.total,
        items: totals.items,
        lines: totals.lines
            .where((l) => l.kind != KitoCheckoutLineKind.total)
            .toList(),
        eta: eta,
        destination: destination,
        deliveryTitle: deliveryTitle,
        paymentTitle: paymentTitle,
        currencyCode: totals.currencyCode,
      );

  /// "KC-260930-0042".
  final String number;

  /// When it was placed.
  final DateTime placedAt;

  /// What was bought.
  final List<KitoCheckoutItem> items;

  /// The summary lines, without the total.
  final List<KitoCheckoutLine> lines;

  /// What was paid, in cents.
  final int total;

  /// "Arrives in 30–45 min".
  final String? eta;

  /// "Mvuli Court, Kilimani, Nairobi".
  final String? destination;

  /// "Express".
  final String? deliveryTitle;

  /// "M-Pesa".
  final String? paymentTitle;

  /// The ISO 4217 code.
  final String currencyCode;

  /// How many units.
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// A plain-text receipt for sharing or printing.
  String get receiptText {
    String money(int c) =>
        KitoCheckoutMoney.format(c, currencyCode: currencyCode);
    final b = StringBuffer('Order $number\n');
    for (final i in items) {
      b.writeln('${i.quantity} × ${i.title}  ${money(i.lineTotal)}');
    }
    if (items.isNotEmpty) b.writeln();
    for (final l in lines) {
      b.writeln(
          '${l.title}  ${money(l.amount)}${l.isIncluded ? ' (included)' : ''}');
    }
    b.write('Total  ${money(total)}');
    if (paymentTitle != null) b.write('\nPaid with $paymentTitle');
    if (eta != null) b.write('\n$eta');
    return b.toString();
  }
}
