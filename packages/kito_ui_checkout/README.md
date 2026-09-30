# kito_ui_checkout

Checkout screens for Flutter: a step progress header, an order summary with promo codes,
delivery options, saved addresses and delivery slots, payment method tiles (M-Pesa, cards,
Apple Pay, Google Pay, cash, wallet), tips, a place-order button that shows processing and
success, and a receipt. Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything
follows `KitoTheme` (light, dark, neon), right-to-left layouts, text scaling and Reduce Motion.

The kit draws the checkout and does the maths; it doesn't charge anyone. Payment tiles are UI
only — hand the chosen method to your payment provider (an M-Pesa STK push, a card SDK, Apple
Pay or Google Pay). There's no platform setup.

## Install

```yaml
dependencies:
  kito_ui_checkout: ^0.1.0
```

```dart
import 'package:kito_ui_checkout/kito_ui_checkout.dart';
```

## Money

Every amount is an `int` of minor units (cents) plus an ISO 4217 code — Kenyan shillings unless
you say otherwise — so there's no floating-point drift.

```dart
KitoCheckoutMoney.format(125000);                     // "KES 1,250"
KitoCheckoutMoney.format(125050);                     // "KES 1,250.50"
KitoCheckoutMoney.format(500000, currencyCode: 'UGX'); // "UGX 500,000"
KitoCheckoutMoney.fromMajor(1250);                    // 125000
```

## Totals

```dart
final totals = KitoCheckoutTotals(
  items: const [
    KitoCheckoutItem(id: 'aa', title: 'Kenyan AA coffee', unitPrice: 90000, quantity: 2),
    KitoCheckoutItem(id: 'mug', title: 'Enamel mug', unitPrice: 65000),
  ],
  deliveryFee: 25000,
  promo: promo,
  tip: tip,
  pricing: const KitoCheckoutPricing(
    vat: KitoCheckoutVat.kenya,             // 16%, already in the prices
    serviceFee: KitoCheckoutServiceFee.percentOf(1, minimum: 5000),
    freeDeliveryThreshold: 500000,
  ),
);

totals.total;   // what the customer pays, in cents
totals.lines;   // subtotal, promo, discounts, delivery, fees, VAT, tip, total
```

The order is subtotal → promo → other discounts → delivery (free past the threshold or with a
free-delivery code) → service fee → VAT (included or added) → tip → total, rounded to whole
shillings by default because M-Pesa only takes whole shillings.

## Progress and summary

```dart
KitoCheckoutProgress(
  current: KitoCheckoutStep.payment,               // cart → delivery → payment → review
  style: KitoCheckoutProgressStyle.dots,           // or segmented, text
  onStepTap: (step) => setState(() => this.step = step),
);

KitoCheckoutSummary(totals: totals);
```

The summary folds its items away, rolls amounts when they change, strikes through a waived
delivery fee next to "Free", and shows how far the order is from free delivery.

## Promo codes

```dart
final codes = KitoCheckoutPromoValidator([
  KitoCheckoutPromo.percent('KARIBU10', 10, cap: 50000),
  KitoCheckoutPromo.fixed('MASHUJAA', 30000, minimumSubtotal: 200000),
  KitoCheckoutPromo.freeDelivery('BODAFREE'),
]);

KitoCheckoutPromoField(
  applied: promo,
  onChanged: (p) => setState(() => promo = p),
  validate: (code) async => codes.validate(code, subtotal: totals.subtotal),
);
```

`validate` is async, so it can just as well call your server and return
`(promo: null, error: KitoCheckoutPromoError.custom('Limit one per customer'))`.

## Delivery

```dart
KitoCheckoutDeliveryOptions(
  options: const [
    KitoCheckoutDeliveryOption.standard(price: 20000),
    KitoCheckoutDeliveryOption.express(price: 35000),     // "Fastest", 30–45 min
    KitoCheckoutDeliveryOption.pickup(),                  // free, no address needed
    KitoCheckoutDeliveryOption.scheduled(price: 15000),
  ],
  selected: option,
  onChanged: (o) => setState(() => option = o),
);

KitoCheckoutAddressList(
  addresses: saved,          // KitoCheckoutAddress: building, street, area, town, landmark
  selected: address,
  onChanged: (a) => setState(() => address = a),
  onAdd: openAddressForm,
);

KitoCheckoutSlotPicker(
  schedule: const KitoCheckoutSchedule(
    windows: [KitoCheckoutTimeWindow(8, 10), KitoCheckoutTimeWindow(10, 12)],
    closedWeekdays: {DateTime.sunday},
    leadTime: Duration(hours: 1),
    booked: {'2026-10-01-0800': 6},
  ),
  selected: slot,
  onChanged: (s) => setState(() => slot = s),
);
```

Slots that are full, too close to start, past the same-day cut-off or already over are struck
out; ones with few places left say so. `KitoCheckoutSchedule.label(slot, now: now)` gives
"Tomorrow, 10 AM–12 PM" for the review screen.

## Payment and tips

```dart
KitoCheckoutPaymentPicker(
  methods: [
    const KitoCheckoutPaymentMethod.mpesa('0712 345 678'),
    KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand.visa, '4242', expiry: '08/28'),
    const KitoCheckoutPaymentMethod.applePay(),
    const KitoCheckoutPaymentMethod.googlePay(),
    const KitoCheckoutPaymentMethod.wallet(120000),
  ],
  selected: method,
  onChanged: (m) => setState(() => method = m),
  total: totals.total,                    // greys out a low wallet, expired card, cash limit
  style: KitoCheckoutPaymentStyle.tiles,  // or list
);

KitoCheckoutTipSelector(
  selected: tip,
  subtotal: totals.subtotal,
  onChanged: (t) => setState(() => tip = t),
);
```

## Placing the order

```dart
KitoCheckoutTotalBar(
  total: totals.total,
  caption: 'Includes VAT',
  hint: slot == null ? 'Choose a delivery slot' : null,   // disables the button
  state: state,
  onPlaceOrder: () async {
    setState(() => state = KitoCheckoutOrderState.processing);
    final ok = await api.placeOrder();
    setState(() => state = ok ? KitoCheckoutOrderState.success : KitoCheckoutOrderState.failure);
  },
);
```

`KitoCheckoutPlaceOrderButton` on its own shrinks into a spinner while processing, turns green
and draws a tick on success, and shakes red with "Try again" on failure.

## Receipt and confirmation

```dart
final placed = KitoCheckoutPlacedOrder.fromTotals(
  totals,
  number: KitoCheckoutOrderNumber.dated(42, date: DateTime.now()),   // "KC-260930-0042"
  placedAt: DateTime.now(),
  eta: option.eta.arrivalText,                                       // "Arrives in 30–45 min"
  destination: address.short,
  paymentTitle: method.title,
);

KitoCheckoutSuccess(order: placed, onTrackOrder: track, onContinueShopping: close);
KitoCheckoutReceipt(order: placed, merchant: 'Kahawa House');
placed.receiptText;   // plain text for sharing
```

## Right-to-left and accessibility

Layouts use directional insets and alignments, so the progress line, radios, badges and
receipt mirror in right-to-left. Every choice is a button with a full spoken label ("Express,
30–45 min, KES 350, Fastest") and selected state; promo errors and order states are announced.
Targets are at least 44 points. Reduce Motion turns the rolls, springs, shakes and the success
burst into plain changes.

## License

MIT — see [LICENSE](LICENSE).
