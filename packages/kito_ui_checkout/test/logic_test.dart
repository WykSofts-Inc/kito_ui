// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_checkout/kito_ui_checkout.dart';

const _items = [
  KitoCheckoutItem(
      id: 'coffee', title: 'Coffee', unitPrice: 90000, quantity: 2),
  KitoCheckoutItem(id: 'mug', title: 'Mug', unitPrice: 65000),
];

void main() {
  group('KitoCheckoutMoney', () {
    test('formats cents with grouping and optional cents', () {
      expect(KitoCheckoutMoney.format(125000), 'KES 1,250');
      expect(KitoCheckoutMoney.format(125050), 'KES 1,250.50');
      expect(KitoCheckoutMoney.format(125000, alwaysShowCents: true),
          'KES 1,250.00');
      expect(KitoCheckoutMoney.format(-20000), '−KES 200');
      expect(KitoCheckoutMoney.format(123456789), 'KES 1,234,567.89');
      expect(KitoCheckoutMoney.format(5000, currencyCode: 'ugx'), 'UGX 5,000');
    });

    test('rounds to whole units and converts', () {
      expect(KitoCheckoutMoney.roundToWhole(125050), 125100);
      expect(KitoCheckoutMoney.roundToWhole(125049), 125000);
      expect(KitoCheckoutMoney.formatWhole(125050), 'KES 1,251');
      expect(KitoCheckoutMoney.fromMajor(12.5), 1250);
      expect(KitoCheckoutMoney.percentOf(10, 125000), 12500);
    });
  });

  group('KitoCheckoutTotals', () {
    test('adds items and delivery', () {
      final t = KitoCheckoutTotals(items: _items, deliveryFee: 25000);
      expect(t.subtotal, 245000);
      expect(t.itemCount, 3);
      expect(t.total, 270000);
      expect(t.lines.map((l) => l.kind), [
        KitoCheckoutLineKind.subtotal,
        KitoCheckoutLineKind.delivery,
        KitoCheckoutLineKind.total,
      ]);
    });

    test('percent promo with a cap', () {
      final t = KitoCheckoutTotals(
          items: _items,
          promo: KitoCheckoutPromo.percent('karibu20', 20, cap: 30000));
      expect(t.promoDiscount, 30000);
      expect(t.total, 215000);
      expect(t.lines[1].title, 'Promo KARIBU20');
      expect(t.lines[1].amount, -30000);
    });

    test('fixed promo never exceeds the subtotal', () {
      final t = KitoCheckoutTotals(items: const [
        KitoCheckoutItem(id: 'a', title: 'A', unitPrice: 10000)
      ], promo: KitoCheckoutPromo.fixed('BIG', 50000));
      expect(t.promoDiscount, 10000);
      expect(t.total, 0);
    });

    test('promo below its minimum is not eligible', () {
      final t = KitoCheckoutTotals(
          items: _items,
          promo: KitoCheckoutPromo.percent('X', 10, minimumSubtotal: 500000));
      expect(t.isPromoEligible, isFalse);
      expect(t.promoDiscount, 0);
    });

    test('free delivery past the threshold and with a code', () {
      final byThreshold = KitoCheckoutTotals(
          items: _items,
          deliveryFee: 25000,
          pricing: const KitoCheckoutPricing(freeDeliveryThreshold: 200000));
      expect(byThreshold.deliveryFee, 0);
      expect(byThreshold.waivedDeliveryFee, 25000);
      final line = byThreshold.lines
          .firstWhere((l) => l.kind == KitoCheckoutLineKind.delivery);
      expect(line.originalAmount, 25000);

      final byCode = KitoCheckoutTotals(
          items: _items,
          deliveryFee: 25000,
          promo: KitoCheckoutPromo.freeDelivery('SHIPFREE'));
      expect(byCode.deliveryFee, 0);
      expect(byCode.total, 245000);
    });

    test('distance to free delivery', () {
      final t = KitoCheckoutTotals(
          items: _items,
          deliveryFee: 25000,
          pricing: const KitoCheckoutPricing(freeDeliveryThreshold: 300000));
      expect(t.amountToFreeDelivery, 55000);
    });

    test('inclusive VAT is shown, exclusive VAT is added', () {
      final inc = KitoCheckoutTotals(
          items: _items,
          pricing: const KitoCheckoutPricing(vat: KitoCheckoutVat.kenya));
      expect(inc.vat, 33793);
      expect(inc.total, 245000);
      expect(
          inc.lines
              .firstWhere((l) => l.kind == KitoCheckoutLineKind.vat)
              .isIncluded,
          isTrue);

      final exc = KitoCheckoutTotals(
          items: _items,
          pricing: const KitoCheckoutPricing(
              vat: KitoCheckoutVat(percent: 16, inclusive: false),
              roundsToWholeUnits: false));
      expect(exc.vat, 39200);
      expect(exc.total, 284200);
    });

    test('service fee is clamped, tips round to whole units', () {
      final t = KitoCheckoutTotals(
        items: _items,
        pricing: const KitoCheckoutPricing(
            serviceFee: KitoCheckoutServiceFee.percentOf(1, minimum: 5000)),
        tip: const KitoCheckoutTip.percentOf(5),
      );
      expect(t.serviceFee, 5000);
      expect(t.tipAmount, 12300); // 12,250 rounded up to KES 123
      expect(t.total, 245000 + 5000 + 12300);
      expect(t.withTip(KitoCheckoutTip.none).total, 250000);
    });

    test('other discounts come off after the promo', () {
      final t = KitoCheckoutTotals(
        items: _items,
        promo: KitoCheckoutPromo.fixed('A', 200000),
        discounts: const [KitoCheckoutDiscount('Bonga points', 100000)],
      );
      expect(t.otherDiscounts, 45000);
      expect(t.total, 0);
      expect(
          t.lines
              .firstWhere((l) => l.kind == KitoCheckoutLineKind.discount)
              .amount,
          -45000);
    });
  });

  group('promo validator', () {
    final v = KitoCheckoutPromoValidator([
      KitoCheckoutPromo.percent('KARIBU10', 10),
      KitoCheckoutPromo.fixed('BIG500', 50000, minimumSubtotal: 300000),
      KitoCheckoutPromo.percent('OLD', 5, expiresAt: DateTime(2026)),
    ]);

    test('finds codes ignoring case and spaces', () {
      final r = v.validate('  karibu10 ', subtotal: 10000);
      expect(r.promo?.code, 'KARIBU10');
      expect(r.error, isNull);
    });

    test('explains failures', () {
      expect(v.validate('', subtotal: 1).error, KitoCheckoutPromoError.empty);
      expect(v.validate('NOPE', subtotal: 1).error,
          KitoCheckoutPromoError.notFound);
      expect(v.validate('OLD', subtotal: 1, now: DateTime(2026, 5)).error,
          KitoCheckoutPromoError.expired);
      final min = v.validate('BIG500', subtotal: 1000).error!;
      expect(min.message(), 'Spend KES 3,000 to use this code.');
    });
  });

  group('delivery', () {
    test('Kenyan phones', () {
      expect(KitoCheckoutPhone.normalize('0712 345 678'), '+254712345678');
      expect(KitoCheckoutPhone.normalize('+254 110 123 456'), '+254110123456');
      expect(KitoCheckoutPhone.normalize('0812345678'), isNull);
      expect(KitoCheckoutPhone.display('712345678'), '+254 712 345 678');
      expect(KitoCheckoutPhone.masked('0712345678'), '0712 ••• 678');
    });

    test('address formatting and validation', () {
      const a = KitoCheckoutAddress(
        id: '1',
        recipient: 'Amina',
        phone: '0712345678',
        building: 'Mvuli Court',
        street: 'Argwings Kodhek Road',
        area: 'Kilimani',
        town: 'Nairobi',
        landmark: 'Yaya Centre',
      );
      expect(
          a.singleLine, 'Mvuli Court, Argwings Kodhek Road, Kilimani, Nairobi');
      expect(a.short, 'Kilimani, Nairobi');
      expect(a.multiLine.split('\n').last, 'Near Yaya Centre');
      expect(a.isValid, isTrue);
      const bad = KitoCheckoutAddress(id: '2', phone: '123');
      expect(bad.validationErrors().keys,
          containsAll(KitoCheckoutAddressField.values));
    });

    test('ETA labels', () {
      expect(const KitoCheckoutEta.minutes(30, 45).label, '30–45 min');
      expect(const KitoCheckoutEta.hours(1, 1).label, '1 hour');
      expect(const KitoCheckoutEta.days(1, 1).label, 'Tomorrow');
      expect(const KitoCheckoutEta.days(1, 1).arrivalText, 'Arrives tomorrow');
      expect(
          const KitoCheckoutEta.days(2, 4).arrivalText, 'Arrives in 2–4 days');
      expect(const KitoCheckoutEta.days(0, 3).label, 'Within 3 days');
    });

    test('time windows', () {
      expect(const KitoCheckoutTimeWindow(8, 10).label(), '8–10 AM');
      expect(const KitoCheckoutTimeWindow(11, 13).label(), '11 AM–1 PM');
      expect(const KitoCheckoutTimeWindow(22, 24).label(), '10 PM–12 AM');
      expect(
          const KitoCheckoutTimeWindow.minutes(510, 630).label(use24Hour: true),
          '08:30–10:30');
    });

    test('schedule statuses', () {
      final now = DateTime(2026, 9, 30, 10, 30); // a Wednesday
      final schedule = KitoCheckoutSchedule(
        daysAhead: 5,
        closedWeekdays: const {DateTime.saturday},
        booked: {
          KitoCheckoutSchedule.slotId(
              DateTime(2026, 10, 1), const KitoCheckoutTimeWindow(8, 10)): 6,
          KitoCheckoutSchedule.slotId(
              DateTime(2026, 10, 1), const KitoCheckoutTimeWindow(10, 12)): 5,
        },
      );
      final days = schedule.days(from: now);
      expect(days.length, 4); // Sat skipped
      final today = days.first.slots;
      expect(schedule.status(today[0], now: now), KitoCheckoutSlotStatus.past);
      expect(
          schedule.status(today[1], now: now), KitoCheckoutSlotStatus.cutOff);
      expect(schedule.status(today[2], now: now),
          KitoCheckoutSlotStatus.available);
      final tomorrow = days[1].slots;
      expect(
          schedule.status(tomorrow[0], now: now), KitoCheckoutSlotStatus.full);
      expect(schedule.status(tomorrow[1], now: now),
          KitoCheckoutSlotStatus.fewLeft);
      expect(schedule.statusLabel(tomorrow[1], now: now), 'Last one');
      expect(schedule.firstAvailable(now: now)?.id, '2026-09-30-1200');
      expect(KitoCheckoutSchedule.label(tomorrow[1], now: now),
          'Tomorrow, 10 AM–12 PM');
      expect(KitoCheckoutSchedule.label(days[3].slots[0], now: now),
          'Sun 4, 8–10 AM');
    });

    test('same-day cut-off', () {
      final now = DateTime(2026, 9, 30, 12);
      const schedule = KitoCheckoutSchedule(sameDayCutoffMinutes: 11 * 60);
      final slot = schedule.slotsOn(now).last;
      expect(schedule.status(slot, now: now), KitoCheckoutSlotStatus.cutOff);
    });
  });

  group('payment', () {
    test('titles and subtitles', () {
      expect(const KitoCheckoutPaymentMethod.mpesa('0712345678').subtitle(),
          'Prompt sent to 0712 ••• 678');
      expect(
          KitoCheckoutPaymentMethod.card(
                  KitoCheckoutCardBrand.visa, '4242424242424242')
              .title,
          'Visa •••• 4242');
      expect(const KitoCheckoutPaymentMethod.googlePay().title, 'Google Pay');
    });

    test('brand detection', () {
      expect(KitoCheckoutCardBrand.detect('4242 4242'),
          KitoCheckoutCardBrand.visa);
      expect(KitoCheckoutCardBrand.detect('5555'),
          KitoCheckoutCardBrand.mastercard);
      expect(KitoCheckoutCardBrand.detect('2221 00'),
          KitoCheckoutCardBrand.mastercard);
      expect(KitoCheckoutCardBrand.detect('3782'), KitoCheckoutCardBrand.amex);
      expect(KitoCheckoutCardBrand.detect('6011'), KitoCheckoutCardBrand.other);
    });

    test('unavailable reasons', () {
      final now = DateTime(2026, 9, 30);
      expect(
          const KitoCheckoutPaymentMethod.wallet(100000)
              .unavailableReason(150000),
          'Balance too low — top up KES 500');
      expect(
          const KitoCheckoutPaymentMethod.cash(limit: 100000)
              .unavailableReason(150000),
          'Cash is accepted up to KES 1,000');
      expect(
          KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand.visa, '1111',
                  expiry: '08/26')
              .unavailableReason(1, now: now),
          'This card has expired');
      expect(
          KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand.visa, '1111',
                  expiry: '09/26')
              .unavailableReason(1, now: now),
          isNull);
      expect(const KitoCheckoutPaymentMethod.mpesa('123').unavailableReason(1),
          'Add a valid M-Pesa number');
      expect(const KitoCheckoutPaymentMethod.applePay().unavailableReason(1),
          isNull);
    });

    test('order numbers', () {
      expect(KitoCheckoutOrderNumber.dated(42, date: DateTime(2026, 9, 30)),
          'KC-260930-0042');
      var i = 0;
      final n = KitoCheckoutOrderNumber.random((max) => i++ % max);
      expect(n, 'KC-3467-9ACD');
      expect(KitoCheckoutOrderNumber.grouped('10423381'), '1042 3381');
    });

    test('placed order and receipt text', () {
      final totals = KitoCheckoutTotals(items: _items, deliveryFee: 25000);
      final order = KitoCheckoutPlacedOrder.fromTotals(totals,
          number: 'KC-1',
          placedAt: DateTime(2026, 9, 30),
          paymentTitle: 'M-Pesa');
      expect(order.lines.any((l) => l.kind == KitoCheckoutLineKind.total),
          isFalse);
      expect(order.total, 270000);
      expect(order.itemCount, 3);
      expect(order.receiptText, contains('2 × Coffee  KES 1,800'));
      expect(order.receiptText, contains('Total  KES 2,700'));
      expect(order.receiptText, endsWith('Paid with M-Pesa'));
    });
  });

  test('tips', () {
    expect(KitoCheckoutTip.none.label(), 'No tip');
    expect(const KitoCheckoutTip.percentOf(10).label(), '10%');
    expect(const KitoCheckoutTip.custom(15000).label(), 'KES 150');
    expect(
        const KitoCheckoutTip.percentOf(10).amountOn(123450, wholeUnits: false),
        12345);
  });
}
