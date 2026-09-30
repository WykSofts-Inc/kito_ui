// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_checkout/kito_ui_checkout.dart';

import 'helpers.dart';

const _items = [
  KitoCheckoutItem(
      id: 'coffee',
      title: 'Kenyan AA coffee',
      subtitle: '500 g',
      unitPrice: 90000,
      quantity: 2),
  KitoCheckoutItem(id: 'mug', title: 'Enamel mug', unitPrice: 65000),
];

Widget _scroll(Widget child) => Scaffold(
    body:
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: child));

KitoCheckoutPlacedOrder _order() => KitoCheckoutPlacedOrder.fromTotals(
      KitoCheckoutTotals(items: _items, deliveryFee: 25000),
      number: 'KC-260930-0042',
      placedAt: DateTime(2026, 9, 30, 14, 5),
      eta: 'Arrives in 30–45 min',
      destination: 'Kilimani, Nairobi',
      paymentTitle: 'M-Pesa',
    );

void main() {
  testWidgets('progress reads its step and lets finished steps be tapped',
      (tester) async {
    final semantics = tester.ensureSemantics();
    KitoCheckoutStep? tapped;
    await tester.pumpWidget(testApp(_scroll(KitoCheckoutProgress(
        current: KitoCheckoutStep.payment, onStepTap: (s) => tapped = s))));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byType(KitoCheckoutProgress));
    expect(node.label, 'Checkout progress');
    expect(node.value, 'Step 3 of 4, Payment');
    await tester.tap(find.text('Cart'));
    expect(tapped, KitoCheckoutStep.cart);
    tapped = null;
    await tester.tap(find.text('Review'));
    expect(tapped, isNull);
    semantics.dispose();
  });

  testWidgets('progress styles build', (tester) async {
    for (final style in KitoCheckoutProgressStyle.values) {
      await tester.pumpWidget(testApp(_scroll(KitoCheckoutProgress(
          current: KitoCheckoutStep.delivery, style: style))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('STEP 2 OF 4'), findsOneWidget);
  });

  testWidgets('summary lists items and lines and folds away', (tester) async {
    await tester.pumpWidget(testApp(_scroll(KitoCheckoutSummary(
      totals: KitoCheckoutTotals(
        items: _items,
        deliveryFee: 25000,
        promo: KitoCheckoutPromo.percent('KARIBU10', 10),
        pricing: const KitoCheckoutPricing(
            vat: KitoCheckoutVat.kenya, freeDeliveryThreshold: 500000),
      ),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Kenyan AA coffee'), findsOneWidget);
    expect(find.text('KES 2,450'), findsOneWidget);
    expect(find.text('Promo KARIBU10'), findsOneWidget);
    expect(find.text('−KES 245'), findsOneWidget);
    expect(find.textContaining('more for free delivery'), findsOneWidget);
    await tester.tap(find.text('Order summary'));
    await tester.pumpAndSettle();
    expect(find.text('Kenyan AA coffee'), findsNothing);
  });

  testWidgets('waived delivery shows Free', (tester) async {
    await tester.pumpWidget(testApp(_scroll(KitoCheckoutSummary(
      totals: KitoCheckoutTotals(
          items: _items,
          deliveryFee: 25000,
          promo: KitoCheckoutPromo.freeDelivery('SHIPFREE')),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('KES 250'), findsOneWidget);
  });

  testWidgets('promo field applies good codes and explains bad ones',
      (tester) async {
    KitoCheckoutPromo? applied;
    final codes =
        KitoCheckoutPromoValidator([KitoCheckoutPromo.percent('KARIBU10', 10)]);
    await tester.pumpWidget(testApp(StatefulBuilder(
      builder: (context, setState) => _scroll(KitoCheckoutPromoField(
        applied: applied,
        onChanged: (p) => setState(() => applied = p),
        validate: (code) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return codes.validate(code, subtotal: 100000);
        },
      )),
    )));
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(find.bySemanticsLabel('Checking code'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('That code isn’t valid.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'karibu10');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(applied?.code, 'KARIBU10');
    expect(find.textContaining('KARIBU10', findRichText: true), findsOneWidget);
    await tester.tap(find.byTooltip('Remove KARIBU10'));
    await tester.pumpAndSettle();
    expect(applied, isNull);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('delivery options pick available ones only', (tester) async {
    KitoCheckoutDeliveryOption? picked;
    await tester.pumpWidget(testApp(_scroll(KitoCheckoutDeliveryOptions(
      options: const [
        KitoCheckoutDeliveryOption.standard(price: 20000),
        KitoCheckoutDeliveryOption(
            id: 'boda',
            kind: KitoCheckoutDeliveryKind.express,
            title: 'Boda express',
            price: 35000,
            eta: KitoCheckoutEta.minutes(20, 30),
            unavailableReason: 'Riders are busy'),
        KitoCheckoutDeliveryOption.pickup(),
      ],
      selected: null,
      onChanged: (o) => picked = o,
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Free'), findsOneWidget);
    await tester.tap(find.text('Boda express'));
    expect(picked, isNull);
    await tester.tap(find.text('Pick up'));
    expect(picked?.id, 'pickup');
  });

  testWidgets('address list selects and adds', (tester) async {
    KitoCheckoutAddress? picked;
    var added = false;
    await tester.pumpWidget(testApp(_scroll(KitoCheckoutAddressList(
      addresses: const [
        KitoCheckoutAddress(
            id: 'home',
            recipient: 'Amina',
            phone: '0712345678',
            street: 'Argwings Kodhek Road',
            area: 'Kilimani',
            town: 'Nairobi',
            landmark: 'Yaya Centre'),
      ],
      selected: null,
      onChanged: (a) => picked = a,
      onAdd: () => added = true,
    ))));
    expect(find.text('Near Yaya Centre'), findsOneWidget);
    expect(find.text('Amina · +254 712 345 678'), findsOneWidget);
    await tester.tap(find.text('Home'));
    expect(picked?.id, 'home');
    await tester.tap(find.text('Add a new address'));
    expect(added, isTrue);
  });

  testWidgets('slot picker switches days and skips closed slots',
      (tester) async {
    KitoCheckoutSlot? picked;
    final now = DateTime(2026, 9, 30, 10, 30);
    await tester.pumpWidget(testApp(_scroll(KitoCheckoutSlotPicker(
      schedule: const KitoCheckoutSchedule(daysAhead: 3),
      selected: null,
      now: now,
      onChanged: (s) => picked = s,
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.text('8–10 AM'));
    expect(picked, isNull);
    await tester.tap(find.text('12–2 PM'));
    expect(picked?.id, '2026-09-30-1200');
    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8–10 AM'));
    expect(picked?.id, '2026-10-01-0800');
  });

  testWidgets('payment picker greys out what cannot pay', (tester) async {
    for (final style in KitoCheckoutPaymentStyle.values) {
      KitoCheckoutPaymentMethod? picked;
      await tester.pumpWidget(testApp(_scroll(KitoCheckoutPaymentPicker(
        style: style,
        total: 250000,
        methods: [
          const KitoCheckoutPaymentMethod.mpesa('0712345678'),
          KitoCheckoutPaymentMethod.card(
              KitoCheckoutCardBrand.mastercard, '5555',
              expiry: '12/30'),
          const KitoCheckoutPaymentMethod.applePay(),
          const KitoCheckoutPaymentMethod.googlePay(),
          const KitoCheckoutPaymentMethod.wallet(100000),
        ],
        selected: null,
        onChanged: (m) => picked = m,
      ))));
      await tester.pumpAndSettle();
      expect(find.text('Balance too low — top up KES 1,500'), findsOneWidget);
      await tester.tap(find.text('Wallet'));
      expect(picked, isNull);
      await tester.tap(find.text('M-Pesa'));
      expect(picked?.kind, KitoCheckoutPaymentKind.mpesa);
    }
  });

  testWidgets('tip selector offers percents and a custom amount',
      (tester) async {
    var tip = KitoCheckoutTip.none;
    await tester.pumpWidget(testApp(StatefulBuilder(
      builder: (context, setState) => _scroll(KitoCheckoutTipSelector(
        selected: tip,
        subtotal: 200000,
        onChanged: (t) => setState(() => tip = t),
      )),
    )));
    expect(find.text('KES 200'), findsOneWidget); // 10%
    await tester.tap(find.text('10%'));
    await tester.pumpAndSettle();
    expect(tip, const KitoCheckoutTip.percentOf(10));
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '150');
    expect(tip, const KitoCheckoutTip.custom(15000));
  });

  testWidgets('place order button moves through its states', (tester) async {
    var taps = 0;
    var state = KitoCheckoutOrderState.idle;
    late StateSetter set;
    await tester.pumpWidget(testApp(StatefulBuilder(builder: (context, s) {
      set = s;
      return _scroll(KitoCheckoutPlaceOrderButton(
        state: state,
        amount: 245000,
        onPressed: () => taps++,
      ));
    })));
    expect(find.text('KES 2,450'), findsOneWidget);
    await tester.tap(find.byType(KitoCheckoutPlaceOrderButton));
    expect(taps, 1);
    set(() => state = KitoCheckoutOrderState.processing);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Placing your order'), findsOneWidget);
    await tester.tap(find.byType(KitoCheckoutPlaceOrderButton));
    expect(taps, 1);
    set(() => state = KitoCheckoutOrderState.failure);
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.byType(KitoCheckoutPlaceOrderButton));
    expect(taps, 2);
    set(() => state = KitoCheckoutOrderState.success);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Order placed'), findsOneWidget);
  });

  testWidgets('total bar hint disables the button', (tester) async {
    var taps = 0;
    await tester.pumpWidget(testApp(Scaffold(
      bottomNavigationBar: KitoCheckoutTotalBar(
        total: 270000,
        caption: 'Includes VAT',
        hint: 'Choose a delivery slot',
        onPlaceOrder: () => taps++,
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Choose a delivery slot'), findsOneWidget);
    await tester.tap(find.byType(KitoCheckoutPlaceOrderButton));
    expect(taps, 0);
  });

  testWidgets('receipt shows the order and copies the number', (tester) async {
    await tester.pumpWidget(testApp(_scroll(
        KitoCheckoutReceipt(order: _order(), merchant: 'Kahawa House'))));
    expect(find.text('Kahawa House'), findsOneWidget);
    expect(find.text('30 Sep 2026, 14:05'), findsOneWidget);
    expect(find.text('2 × Kenyan AA coffee'), findsOneWidget);
    expect(find.text('KES 2,700'), findsOneWidget);
    await tester.tap(find.text('KC-260930-0042'));
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('success animates in and settles', (tester) async {
    var tracked = false;
    await tester.pumpWidget(testApp(_scroll(KitoCheckoutSuccess(
        order: _order(), onTrackOrder: () => tracked = true))));
    await tester.pumpAndSettle();
    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.text('Arrives in 30–45 min'), findsOneWidget);
    await tester.ensureVisible(find.text('Track order'));
    await tester.tap(find.text('Track order'));
    expect(tracked, isTrue);
  });

  testWidgets('everything builds right-to-left and with reduce motion',
      (tester) async {
    await tester.pumpWidget(testApp(
      _scroll(Column(children: [
        const KitoCheckoutProgress(current: KitoCheckoutStep.review),
        KitoCheckoutSummary(totals: KitoCheckoutTotals(items: _items)),
        KitoCheckoutSlotPicker(
            schedule: const KitoCheckoutSchedule(),
            selected: null,
            onChanged: (_) {}),
        KitoCheckoutSuccess(order: _order()),
      ])),
      direction: TextDirection.rtl,
      reduceMotion: true,
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Order placed!'), findsOneWidget);
  });

  testWidgets('narrow phones: progress, addresses and the total bar fit',
      (tester) async {
    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          const KitoCheckoutProgress(current: KitoCheckoutStep.payment),
          KitoCheckoutAddressList(
            addresses: const [],
            selected: null,
            onChanged: (_) {},
            onAdd: () {},
          ),
          KitoCheckoutTotalBar(
            total: 24500000,
            caption: 'Includes VAT · 4 items',
            hint: 'Choose a delivery slot',
            onPlaceOrder: () {},
          ),
        ]),
      ),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
