// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'money.dart';

/// The stages of a checkout, in order. [done] is the confirmation after the order is placed.
enum KitoCheckoutStep {
  /// The bag / cart review.
  cart('Cart', Icons.shopping_bag_rounded),

  /// Address, delivery option and slot.
  delivery('Delivery', Icons.local_shipping_rounded),

  /// How the customer pays.
  payment('Payment', Icons.credit_card_rounded),

  /// A last look before placing the order.
  review('Review', Icons.fact_check_rounded),

  /// The order has been placed.
  done('Done', Icons.verified_rounded);

  const KitoCheckoutStep(this.title, this.icon);

  /// "Delivery".
  final String title;

  /// A matching icon.
  final IconData icon;

  /// The four steps the progress header shows.
  static const List<KitoCheckoutStep> standard = [
    cart,
    delivery,
    payment,
    review
  ];
}

/// One line item in the order.
@immutable
class KitoCheckoutItem {
  /// Creates an item. [unitPrice] is in cents.
  const KitoCheckoutItem({
    required this.id,
    required this.title,
    required this.unitPrice,
    this.quantity = 1,
    this.subtitle,
    this.icon,
    this.color,
    this.image,
  });

  /// A stable id.
  final String id;

  /// "Kenyan AA coffee beans".
  final String title;

  /// A variant or size: "500 g · Medium roast".
  final String? subtitle;

  /// The price of one, in cents.
  final int unitPrice;

  /// How many.
  final int quantity;

  /// Drawn in the thumbnail when there's no [image].
  final IconData? icon;

  /// The thumbnail's colour.
  final Color? color;

  /// A product photo.
  final ImageProvider? image;

  /// [unitPrice] × [quantity], in cents.
  int get lineTotal => unitPrice * math.max(quantity, 0);

  /// A copy with another quantity.
  KitoCheckoutItem withQuantity(int quantity) => KitoCheckoutItem(
        id: id,
        title: title,
        unitPrice: unitPrice,
        quantity: quantity,
        subtitle: subtitle,
        icon: icon,
        color: color,
        image: image,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutItem &&
      other.id == id &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice;

  @override
  int get hashCode => Object.hash(id, quantity, unitPrice);
}

/// What a promo code takes off.
enum KitoCheckoutPromoKind {
  /// A percentage of the subtotal, optionally capped.
  percent,

  /// A fixed amount, never more than the subtotal.
  fixed,

  /// Delivery is free.
  freeDelivery,
}

/// A promo code the customer can apply.
@immutable
class KitoCheckoutPromo {
  /// A percentage off: `KitoCheckoutPromo.percent('KARIBU10', 10)`.
  KitoCheckoutPromo.percent(String code, this.value,
      {this.cap, this.minimumSubtotal, this.expiresAt, String? title})
      : code = code.trim().toUpperCase(),
        kind = KitoCheckoutPromoKind.percent,
        title = title ?? '${_trim(value)}% off';

  /// A fixed amount off, in cents.
  KitoCheckoutPromo.fixed(String code, int cents,
      {this.minimumSubtotal,
      this.expiresAt,
      String? title,
      String currencyCode = kitoCheckoutDefaultCurrency})
      : code = code.trim().toUpperCase(),
        kind = KitoCheckoutPromoKind.fixed,
        value = cents,
        cap = null,
        title = title ??
            '${KitoCheckoutMoney.format(cents, currencyCode: currencyCode)} off';

  /// Free delivery.
  KitoCheckoutPromo.freeDelivery(String code,
      {this.minimumSubtotal, this.expiresAt, String? title})
      : code = code.trim().toUpperCase(),
        kind = KitoCheckoutPromoKind.freeDelivery,
        value = 0,
        cap = null,
        title = title ?? 'Free delivery';

  static String _trim(num v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  /// Stored in capitals; matching ignores case and surrounding spaces.
  final String code;

  /// What it takes off.
  final KitoCheckoutPromoKind kind;

  /// The percent (10 is 10%) or the fixed amount in cents.
  final num value;

  /// The most a percentage code takes off, in cents.
  final int? cap;

  /// The subtotal (cents) the order must reach before the code applies.
  final int? minimumSubtotal;

  /// When the code stops working.
  final DateTime? expiresAt;

  /// A short line for the applied chip: "10% off", "KES 200 off", "Free delivery".
  final String title;

  /// Whether the code applies to [subtotal] at [now].
  bool isEligible(int subtotal, {DateTime? now}) {
    if (expiresAt != null && (now ?? DateTime.now()).isAfter(expiresAt!)) {
      return false;
    }
    return minimumSubtotal == null || subtotal >= minimumSubtotal!;
  }

  /// The discount on [subtotal], in cents; zero when it isn't eligible or is free delivery.
  int discountOn(int subtotal, {DateTime? now}) {
    if (subtotal <= 0 || !isEligible(subtotal, now: now)) return 0;
    switch (kind) {
      case KitoCheckoutPromoKind.percent:
        var off = KitoCheckoutMoney.percentOf(value, subtotal);
        if (cap != null) off = math.min(off, cap!);
        return off.clamp(0, subtotal);
      case KitoCheckoutPromoKind.fixed:
        return value.round().clamp(0, subtotal);
      case KitoCheckoutPromoKind.freeDelivery:
        return 0;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutPromo &&
      other.code == code &&
      other.kind == kind &&
      other.value == value;

  @override
  int get hashCode => Object.hash(code, kind, value);
}

/// Why a promo code didn't apply.
sealed class KitoCheckoutPromoError {
  const KitoCheckoutPromoError();

  /// Nothing was typed.
  static const KitoCheckoutPromoError empty = _PromoEmpty();

  /// The code doesn't exist.
  static const KitoCheckoutPromoError notFound = _PromoNotFound();

  /// The code is past its date.
  static const KitoCheckoutPromoError expired = _PromoExpired();

  /// The order is below the code's minimum.
  const factory KitoCheckoutPromoError.minimumNotMet(int minimum) =
      KitoCheckoutPromoMinimum;

  /// Your own message, e.g. from the server.
  const factory KitoCheckoutPromoError.custom(String message) =
      KitoCheckoutPromoCustomError;

  /// The line shown under the field.
  String message({String currencyCode = kitoCheckoutDefaultCurrency});
}

class _PromoEmpty extends KitoCheckoutPromoError {
  const _PromoEmpty();
  @override
  String message({String currencyCode = kitoCheckoutDefaultCurrency}) =>
      'Enter a promo code.';
}

class _PromoNotFound extends KitoCheckoutPromoError {
  const _PromoNotFound();
  @override
  String message({String currencyCode = kitoCheckoutDefaultCurrency}) =>
      'That code isn’t valid.';
}

class _PromoExpired extends KitoCheckoutPromoError {
  const _PromoExpired();
  @override
  String message({String currencyCode = kitoCheckoutDefaultCurrency}) =>
      'That code has expired.';
}

/// The order is below the code's minimum.
class KitoCheckoutPromoMinimum extends KitoCheckoutPromoError {
  /// Creates the error; [minimum] is in cents.
  const KitoCheckoutPromoMinimum(this.minimum);

  /// The subtotal needed, in cents.
  final int minimum;

  @override
  String message({String currencyCode = kitoCheckoutDefaultCurrency}) =>
      'Spend ${KitoCheckoutMoney.format(minimum, currencyCode: currencyCode)} to use this code.';
}

/// A message of your own.
class KitoCheckoutPromoCustomError extends KitoCheckoutPromoError {
  /// Creates the error.
  const KitoCheckoutPromoCustomError(this.text);

  /// The message.
  final String text;

  @override
  String message({String currencyCode = kitoCheckoutDefaultCurrency}) => text;
}

/// The result of checking a code: the promo, or why it failed.
typedef KitoCheckoutPromoResult = ({
  KitoCheckoutPromo? promo,
  KitoCheckoutPromoError? error
});

/// Checks codes against a known list — for demos, offline catalogues, or the client-side check
/// before your server confirms.
class KitoCheckoutPromoValidator {
  /// Creates a validator.
  const KitoCheckoutPromoValidator(this.codes);

  /// The codes that exist.
  final List<KitoCheckoutPromo> codes;

  /// Finds [input] and checks it against [subtotal] (cents).
  KitoCheckoutPromoResult validate(String input,
      {required int subtotal, DateTime? now}) {
    final code = input.trim().toUpperCase();
    if (code.isEmpty) return (promo: null, error: KitoCheckoutPromoError.empty);
    final match = codes.where((c) => c.code == code).firstOrNull;
    if (match == null) {
      return (promo: null, error: KitoCheckoutPromoError.notFound);
    }
    if (match.expiresAt != null &&
        (now ?? DateTime.now()).isAfter(match.expiresAt!)) {
      return (promo: null, error: KitoCheckoutPromoError.expired);
    }
    final min = match.minimumSubtotal;
    if (min != null && subtotal < min) {
      return (promo: null, error: KitoCheckoutPromoError.minimumNotMet(min));
    }
    return (promo: match, error: null);
  }
}

/// A tip for the rider or staff.
@immutable
class KitoCheckoutTip {
  const KitoCheckoutTip._(this.percent, this.amount);

  /// No tip.
  static const KitoCheckoutTip none = KitoCheckoutTip._(null, null);

  /// A percentage of the subtotal: `KitoCheckoutTip.percentOf(10)`.
  const KitoCheckoutTip.percentOf(int percent) : this._(percent, null);

  /// A set amount, in cents.
  const KitoCheckoutTip.custom(int cents) : this._(null, cents);

  /// The percentage, for percentage tips.
  final int? percent;

  /// The amount in cents, for custom tips.
  final int? amount;

  /// The usual choices.
  static const List<int> standardPercents = [5, 10, 15];

  /// True for [none].
  bool get isNone => percent == null && amount == null;

  /// True for a custom amount.
  bool get isCustom => amount != null;

  /// The tip on [subtotal] (cents). Percentage tips round to whole units when [wholeUnits] is
  /// on — nobody tips KES 12.35.
  int amountOn(int subtotal,
      {bool wholeUnits = true,
      String currencyCode = kitoCheckoutDefaultCurrency}) {
    if (amount != null) return math.max(amount!, 0);
    if (percent == null) return 0;
    final raw = KitoCheckoutMoney.percentOf(
        math.max(percent!, 0), math.max(subtotal, 0));
    return wholeUnits
        ? KitoCheckoutMoney.roundToWhole(raw, currencyCode: currencyCode)
        : raw;
  }

  /// "No tip", "10%", "KES 150".
  String label({String currencyCode = kitoCheckoutDefaultCurrency}) {
    if (amount != null) {
      return KitoCheckoutMoney.format(amount!, currencyCode: currencyCode);
    }
    if (percent != null) return '$percent%';
    return 'No tip';
  }

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutTip &&
      other.percent == percent &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(percent, amount);
}

/// How the shop charges VAT.
@immutable
class KitoCheckoutVat {
  /// Creates a VAT rule. [percent] 16 is 16%.
  const KitoCheckoutVat({
    required this.percent,
    this.inclusive = true,
    this.appliesToFees = false,
  });

  /// No VAT line at all.
  static const KitoCheckoutVat none = KitoCheckoutVat(percent: 0);

  /// Kenya's 16%, already inside shelf prices.
  static const KitoCheckoutVat kenya = KitoCheckoutVat(percent: 16);

  /// The rate: 16 is 16%.
  final num percent;

  /// Prices already include VAT (shown, not added). When false, VAT is added on top.
  final bool inclusive;

  /// Also charge VAT on delivery and service fees.
  final bool appliesToFees;

  /// "VAT 16% (included)" or "VAT 16%".
  String get title {
    final rate = percent == percent.roundToDouble()
        ? percent.round().toString()
        : percent.toString();
    return inclusive ? 'VAT $rate% (included)' : 'VAT $rate%';
  }

  /// The VAT in [base] (cents): on top when exclusive, the part already inside when inclusive.
  int amountOn(int base) {
    if (percent <= 0 || base <= 0) return 0;
    return inclusive
        ? (base * percent / (100 + percent)).round()
        : KitoCheckoutMoney.percentOf(percent, base);
  }
}

/// A platform or service fee.
@immutable
class KitoCheckoutServiceFee {
  const KitoCheckoutServiceFee._(this.fixed, this.percent, this.min, this.max);

  /// No fee.
  static const KitoCheckoutServiceFee none =
      KitoCheckoutServiceFee._(0, null, null, null);

  /// A set fee, in cents.
  const KitoCheckoutServiceFee.fixed(int cents)
      : this._(cents, null, null, null);

  /// A percentage of the subtotal, kept between optional [minimum] and [maximum] (cents).
  const KitoCheckoutServiceFee.percentOf(num percent,
      {int? minimum, int? maximum})
      : this._(0, percent, minimum, maximum);

  /// The fixed fee.
  final int fixed;

  /// The percentage.
  final num? percent;

  /// The smallest percentage fee.
  final int? min;

  /// The largest percentage fee.
  final int? max;

  /// The fee on [subtotal] (cents).
  int amountOn(int subtotal) {
    if (subtotal <= 0) return 0;
    if (percent == null) return math.max(fixed, 0);
    var fee = KitoCheckoutMoney.percentOf(percent!, subtotal);
    if (min != null) fee = math.max(fee, min!);
    if (max != null) fee = math.min(fee, max!);
    return math.max(fee, 0);
  }
}

/// How fees, VAT and rounding work for your shop.
@immutable
class KitoCheckoutPricing {
  /// Creates the rules.
  const KitoCheckoutPricing({
    this.serviceFee = KitoCheckoutServiceFee.none,
    this.vat = KitoCheckoutVat.none,
    this.freeDeliveryThreshold,
    this.roundsToWholeUnits = true,
    this.currencyCode = kitoCheckoutDefaultCurrency,
  });

  /// The service fee.
  final KitoCheckoutServiceFee serviceFee;

  /// The VAT rule.
  final KitoCheckoutVat vat;

  /// The subtotal (cents) at which delivery becomes free; null for never.
  final int? freeDeliveryThreshold;

  /// Round tips and the total to whole units — on by default because M-Pesa only takes whole
  /// shillings.
  final bool roundsToWholeUnits;

  /// The ISO 4217 code for every amount.
  final String currencyCode;
}

/// The kind of a summary line.
enum KitoCheckoutLineKind {
  /// Items before anything else.
  subtotal,

  /// The promo code's discount.
  promo,

  /// Another discount.
  discount,

  /// Delivery.
  delivery,

  /// A service fee.
  serviceFee,

  /// VAT, added or included.
  vat,

  /// The tip.
  tip,

  /// What the customer pays.
  total,
}

/// A discount that isn't a promo code: loyalty points, a staff discount, a bundle deal.
@immutable
class KitoCheckoutDiscount {
  /// Creates a discount; [amount] is in cents.
  const KitoCheckoutDiscount(this.title, this.amount);

  /// "Bonga points".
  final String title;

  /// Cents off.
  final int amount;
}

/// One line of the order summary.
@immutable
class KitoCheckoutLine {
  /// Creates a line.
  const KitoCheckoutLine({
    required this.kind,
    required this.title,
    required this.amount,
    this.originalAmount,
    this.isIncluded = false,
  });

  /// What the line is.
  final KitoCheckoutLineKind kind;

  /// "Delivery", "Promo KARIBU10".
  final String title;

  /// Cents; negative for discounts.
  final int amount;

  /// The fee before it was waived, for a struck-through "KES 250 Free".
  final int? originalAmount;

  /// VAT already inside the prices: shown, not added.
  final bool isIncluded;

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutLine &&
      other.kind == kind &&
      other.title == title &&
      other.amount == amount &&
      other.originalAmount == originalAmount &&
      other.isIncluded == isIncluded;

  @override
  int get hashCode =>
      Object.hash(kind, title, amount, originalAmount, isIncluded);
}

/// Everything the customer pays, worked out once from the items, fees, VAT, promo and tip.
///
/// Order: subtotal → promo → other discounts → delivery (free past the threshold or with a
/// free-delivery code) → service fee on the subtotal → VAT on the discounted goods (plus fees
/// when configured) → tip on the subtotal → total, rounded to whole units when configured.
@immutable
class KitoCheckoutTotals {
  /// Works out the totals. [deliveryFee] is the chosen option's price in cents.
  factory KitoCheckoutTotals({
    required List<KitoCheckoutItem> items,
    KitoCheckoutPricing pricing = const KitoCheckoutPricing(),
    int deliveryFee = 0,
    KitoCheckoutPromo? promo,
    KitoCheckoutTip tip = KitoCheckoutTip.none,
    List<KitoCheckoutDiscount> discounts = const [],
    DateTime? now,
  }) {
    final subtotal =
        math.max(items.fold<int>(0, (sum, i) => sum + i.lineTotal), 0);
    final eligible = promo?.isEligible(subtotal, now: now) ?? false;
    final promoOff = promo?.discountOn(subtotal, now: now) ?? 0;
    final requested =
        discounts.fold<int>(0, (sum, d) => sum + math.max(d.amount, 0));
    final other = math.min(requested, subtotal - promoOff);
    final goods = subtotal - promoOff - other;
    final price = math.max(deliveryFee, 0);
    final threshold = pricing.freeDeliveryThreshold;
    final waived = price > 0 &&
        subtotal > 0 &&
        ((threshold != null && subtotal >= threshold) ||
            (eligible && promo?.kind == KitoCheckoutPromoKind.freeDelivery));
    final delivery = waived ? 0 : price;
    final service = pricing.serviceFee.amountOn(subtotal);
    final fees = delivery + service;
    final vat =
        pricing.vat.amountOn(goods + (pricing.vat.appliesToFees ? fees : 0));
    final tipAmount = tip.amountOn(subtotal,
        wholeUnits: pricing.roundsToWholeUnits,
        currencyCode: pricing.currencyCode);
    final raw = goods + fees + (pricing.vat.inclusive ? 0 : vat) + tipAmount;
    final total = pricing.roundsToWholeUnits
        ? KitoCheckoutMoney.roundToWhole(raw,
            currencyCode: pricing.currencyCode)
        : raw;
    return KitoCheckoutTotals._(
      items: List.unmodifiable(items),
      pricing: pricing,
      promo: promo,
      tip: tip,
      discounts: List.unmodifiable(discounts),
      deliveryPrice: price,
      subtotal: subtotal,
      promoDiscount: promoOff,
      isPromoEligible: eligible,
      otherDiscounts: other,
      deliveryFee: delivery,
      waivedDeliveryFee: waived ? price : 0,
      serviceFee: service,
      vat: vat,
      tipAmount: tipAmount,
      total: total,
      now: now,
    );
  }

  const KitoCheckoutTotals._({
    required this.items,
    required this.pricing,
    required this.promo,
    required this.tip,
    required this.discounts,
    required this.deliveryPrice,
    required this.subtotal,
    required this.promoDiscount,
    required this.isPromoEligible,
    required this.otherDiscounts,
    required this.deliveryFee,
    required this.waivedDeliveryFee,
    required this.serviceFee,
    required this.vat,
    required this.tipAmount,
    required this.total,
    required DateTime? now,
  }) : _now = now;

  /// The items.
  final List<KitoCheckoutItem> items;

  /// The rules used.
  final KitoCheckoutPricing pricing;

  /// The applied promo code.
  final KitoCheckoutPromo? promo;

  /// The tip choice.
  final KitoCheckoutTip tip;

  /// Other discounts.
  final List<KitoCheckoutDiscount> discounts;

  /// The delivery option's price before any free-delivery rule.
  final int deliveryPrice;

  /// Items before anything else.
  final int subtotal;

  /// What the promo code took off.
  final int promoDiscount;

  /// Whether the promo code applies to this order.
  final bool isPromoEligible;

  /// What other discounts took off (never more than what's left).
  final int otherDiscounts;

  /// What delivery costs after free-delivery rules.
  final int deliveryFee;

  /// The delivery fee that was waived, or zero.
  final int waivedDeliveryFee;

  /// The service fee.
  final int serviceFee;

  /// The VAT (added or included).
  final int vat;

  /// The tip.
  final int tipAmount;

  /// What the customer pays.
  final int total;

  final DateTime? _now;

  /// The currency code from [pricing].
  String get currencyCode => pricing.currencyCode;

  /// How many units in the order.
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Promo plus other discounts.
  int get discountTotal => promoDiscount + otherDiscounts;

  /// How much more to spend for free delivery, or null when it's already free or never is.
  int? get amountToFreeDelivery {
    final t = pricing.freeDeliveryThreshold;
    if (t == null || deliveryPrice == 0 || waivedDeliveryFee > 0) return null;
    return math.max(t - subtotal, 0);
  }

  /// The lines to show, in order. Zero lines are left out except subtotal, delivery and total.
  List<KitoCheckoutLine> get lines {
    final out = <KitoCheckoutLine>[
      KitoCheckoutLine(
          kind: KitoCheckoutLineKind.subtotal,
          title: 'Subtotal',
          amount: subtotal),
    ];
    if (promo != null && promoDiscount > 0) {
      out.add(KitoCheckoutLine(
          kind: KitoCheckoutLineKind.promo,
          title: 'Promo ${promo!.code}',
          amount: -promoDiscount));
    }
    var budget = otherDiscounts;
    for (final d in discounts) {
      if (d.amount <= 0 || budget <= 0) continue;
      final applied = math.min(d.amount, budget);
      budget -= applied;
      out.add(KitoCheckoutLine(
          kind: KitoCheckoutLineKind.discount,
          title: d.title,
          amount: -applied));
    }
    out.add(KitoCheckoutLine(
      kind: KitoCheckoutLineKind.delivery,
      title: 'Delivery',
      amount: deliveryFee,
      originalAmount: waivedDeliveryFee > 0 ? waivedDeliveryFee : null,
    ));
    if (serviceFee > 0) {
      out.add(KitoCheckoutLine(
          kind: KitoCheckoutLineKind.serviceFee,
          title: 'Service fee',
          amount: serviceFee));
    }
    if (vat > 0) {
      out.add(KitoCheckoutLine(
          kind: KitoCheckoutLineKind.vat,
          title: pricing.vat.title,
          amount: vat,
          isIncluded: pricing.vat.inclusive));
    }
    if (tipAmount > 0) {
      out.add(KitoCheckoutLine(
          kind: KitoCheckoutLineKind.tip, title: 'Tip', amount: tipAmount));
    }
    out.add(KitoCheckoutLine(
        kind: KitoCheckoutLineKind.total, title: 'Total', amount: total));
    return out;
  }

  /// The same maths with a different tip, for showing what each tip choice costs.
  KitoCheckoutTotals withTip(KitoCheckoutTip tip) => KitoCheckoutTotals(
        items: items,
        pricing: pricing,
        deliveryFee: deliveryPrice,
        promo: promo,
        tip: tip,
        discounts: discounts,
        now: _now,
      );

  /// The same maths with a different promo code.
  KitoCheckoutTotals withPromo(KitoCheckoutPromo? promo) => KitoCheckoutTotals(
        items: items,
        pricing: pricing,
        deliveryFee: deliveryPrice,
        promo: promo,
        tip: tip,
        discounts: discounts,
        now: _now,
      );
}
