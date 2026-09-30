// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kito_ui_checkout/kito_ui_checkout.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';
import '../gallery/phone_stage.dart';

const _items = [
  KitoCheckoutItem(
    id: 'aa',
    title: 'Kenyan AA coffee beans',
    subtitle: '500 g · Nyeri, medium roast',
    unitPrice: 95000,
    quantity: 2,
    icon: Icons.coffee_rounded,
    color: Color(0xFF8B5A2B),
  ),
  KitoCheckoutItem(
    id: 'mug',
    title: 'Enamel camp mug',
    subtitle: 'Maasai red',
    unitPrice: 65000,
    icon: Icons.local_cafe_rounded,
    color: Color(0xFFD13D6B),
  ),
  KitoCheckoutItem(
    id: 'mandazi',
    title: 'Coconut mandazi',
    subtitle: 'Box of 6',
    unitPrice: 30000,
    icon: Icons.bakery_dining_rounded,
    color: Color(0xFFF5A524),
  ),
];

const _pricing = KitoCheckoutPricing(
  vat: KitoCheckoutVat.kenya,
  freeDeliveryThreshold: 500000,
);

final _codes = KitoCheckoutPromoValidator([
  KitoCheckoutPromo.percent('KARIBU10', 10, cap: 50000),
  KitoCheckoutPromo.fixed('MASHUJAA', 30000, minimumSubtotal: 400000),
  KitoCheckoutPromo.freeDelivery('BODAFREE'),
]);

const _options = [
  KitoCheckoutDeliveryOption.standard(price: 20000),
  KitoCheckoutDeliveryOption.express(price: 35000, title: 'Boda express'),
  KitoCheckoutDeliveryOption.pickup(subtitle: 'Sarit Centre, Westlands'),
  KitoCheckoutDeliveryOption.scheduled(price: 15000),
];

const _addresses = [
  KitoCheckoutAddress(
    id: 'home',
    recipient: 'Wycliff N',
    phone: '0712 345 678',
    building: 'Mvuli Court, Block B',
    street: 'Argwings Kodhek Road',
    area: 'Kilimani',
    town: 'Nairobi',
    landmark: 'Yaya Centre',
  ),
  KitoCheckoutAddress(
    id: 'work',
    label: KitoCheckoutAddressLabel.work,
    recipient: 'Wycliff N',
    phone: '0712 345 678',
    building: 'Delta Towers, 9th floor',
    street: 'Chiromo Road',
    area: 'Westlands',
    town: 'Nairobi',
    instructions: 'Leave at reception',
  ),
  KitoCheckoutAddress(
    id: 'mum',
    label: KitoCheckoutAddressLabel.other,
    customLabel: 'Mum’s place',
    recipient: 'Grace Njenga',
    phone: '0722 000 111',
    street: 'Miotoni Road',
    area: 'Karen',
    town: 'Nairobi',
    landmark: 'the Hub Karen',
  ),
];

List<KitoCheckoutPaymentMethod> _methods() => [
      const KitoCheckoutPaymentMethod.mpesa('0712 345 678'),
      KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand.visa, '4242',
          expiry: '08/29'),
      KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand.mastercard, '5100',
          expiry: '01/24'),
      const KitoCheckoutPaymentMethod.applePay(),
      const KitoCheckoutPaymentMethod.googlePay(),
      const KitoCheckoutPaymentMethod.wallet(120000),
      const KitoCheckoutPaymentMethod.cash(limit: 500000),
    ];

Future<KitoCheckoutPromoResult> _check(String code, int subtotal) async {
  await Future<void>.delayed(const Duration(milliseconds: 650));
  return _codes.validate(code, subtotal: subtotal);
}

KitoCheckoutPlacedOrder _placed() {
  final totals = KitoCheckoutTotals(
    items: _items,
    deliveryFee: 35000,
    promo: KitoCheckoutPromo.percent('KARIBU10', 10, cap: 50000),
    pricing: _pricing,
  );
  final now = DateTime.now();
  return KitoCheckoutPlacedOrder.fromTotals(
    totals,
    number: KitoCheckoutOrderNumber.dated(42, date: now),
    placedAt: now,
    eta: const KitoCheckoutEta.minutes(30, 45).arrivalText,
    destination: _addresses.first.short,
    deliveryTitle: 'Boda express',
    paymentTitle: 'M-Pesa',
  );
}

/// The gallery for kito_ui_checkout.
final checkoutKit = KitEntry(
  title: 'Checkout',
  package: 'kito_ui_checkout',
  blurb: 'steps, summaries, promo codes, slots, M-Pesa tiles and receipts',
  icon: Icons.shopping_cart_checkout_rounded,
  category: KitCategory.commerce,
  isNew: true,
  sections: [
    KitSection('Flow', Icons.linear_scale_rounded, [
      KitSample(
        title: 'Full checkout',
        subtitle:
            'Cart, delivery, payment and review, then an M-Pesa order placed.',
        code: '''KitoCheckoutProgress(current: step, onStepTap: goTo);
// …each step's widgets…
KitoCheckoutTotalBar(
  total: totals.total,
  hint: missing,
  state: state,
  onPlaceOrder: next,
);''',
        builder: (_) =>
            PhoneStage(height: 600, builder: (_) => const _FullCheckout()),
      ),
      KitSample(
        title: 'Step progress',
        subtitle: 'Dots fill as you go; tap a finished step to go back.',
        code: '''KitoCheckoutProgress(
  current: step,
  onStepTap: (s) => setState(() => step = s),
)''',
        builder: (_) => const _Steps(style: KitoCheckoutProgressStyle.dots),
      ),
      KitSample(
        title: 'Segmented progress',
        subtitle: 'One bar per step with the step’s name and count.',
        code: '''KitoCheckoutProgress(
  current: step,
  style: KitoCheckoutProgressStyle.segmented,
  tint: const Color(0xFF21A86B),
)''',
        builder: (_) => const _Steps(
            style: KitoCheckoutProgressStyle.segmented,
            tint: Color(0xFF21A86B)),
      ),
      KitSample(
        title: 'Step 2 of 4',
        subtitle: 'A big title that slides in, with what comes next.',
        code: '''KitoCheckoutProgress(
  current: step,
  style: KitoCheckoutProgressStyle.text,
)''',
        builder: (_) => const _Steps(style: KitoCheckoutProgressStyle.text),
      ),
    ]),
    KitSection('Summary', Icons.receipt_long_rounded, [
      KitSample(
        title: 'Order summary',
        subtitle:
            'Items fold away; VAT included, a promo and free delivery progress.',
        code: '''KitoCheckoutSummary(
  totals: KitoCheckoutTotals(
    items: items,
    deliveryFee: 20000,
    promo: KitoCheckoutPromo.percent('KARIBU10', 10),
    pricing: const KitoCheckoutPricing(
      vat: KitoCheckoutVat.kenya,
      freeDeliveryThreshold: 500000,
    ),
  ),
)''',
        builder: (_) => KitoCheckoutSummary(
          totals: KitoCheckoutTotals(
            items: _items,
            deliveryFee: 20000,
            promo: KitoCheckoutPromo.percent('KARIBU10', 10, cap: 50000),
            pricing: _pricing,
          ),
        ),
      ),
      KitSample(
        title: 'Promo codes',
        subtitle: 'Try KARIBU10, MASHUJAA or BODAFREE; a wrong one shakes.',
        code: '''final codes = KitoCheckoutPromoValidator([
  KitoCheckoutPromo.percent('KARIBU10', 10, cap: 50000),
  KitoCheckoutPromo.fixed('MASHUJAA', 30000, minimumSubtotal: 400000),
  KitoCheckoutPromo.freeDelivery('BODAFREE'),
]);

KitoCheckoutPromoField(
  applied: promo,
  onChanged: (p) => setState(() => promo = p),
  validate: (code) async => codes.validate(code, subtotal: subtotal),
)''',
        builder: (_) => const _Promo(),
      ),
      KitSample(
        title: 'Tip the rider',
        subtitle: 'Each chip shows what it adds; the total rolls to match.',
        code: '''KitoCheckoutTipSelector(
  selected: tip,
  subtotal: totals.subtotal,
  onChanged: (t) => setState(() => tip = t),
)''',
        builder: (_) => const _Tips(),
      ),
    ]),
    KitSection('Delivery', Icons.local_shipping_rounded, [
      KitSample(
        title: 'Delivery options',
        subtitle: 'Prices, ETAs and badges; a busy option says why.',
        code: '''KitoCheckoutDeliveryOptions(
  options: const [
    KitoCheckoutDeliveryOption.standard(price: 20000),
    KitoCheckoutDeliveryOption.express(price: 35000, title: 'Boda express'),
    KitoCheckoutDeliveryOption.pickup(subtitle: 'Sarit Centre, Westlands'),
    KitoCheckoutDeliveryOption.scheduled(price: 15000),
  ],
  selected: option,
  onChanged: (o) => setState(() => option = o),
)''',
        builder: (_) => const _Options(),
      ),
      KitSample(
        title: 'Saved addresses',
        subtitle: 'Kenyan addresses with estates and landmarks for the rider.',
        code: '''KitoCheckoutAddressList(
  addresses: saved,
  selected: address,
  onChanged: (a) => setState(() => address = a),
  onAdd: openAddressForm,
)''',
        builder: (_) => const _Addresses(),
      ),
      KitSample(
        title: 'Delivery slots',
        subtitle: 'Two-hour windows, places left, closed on Sundays.',
        code: '''KitoCheckoutSlotPicker(
  schedule: KitoCheckoutSchedule(
    closedWeekdays: {DateTime.sunday},
    booked: bookings,
  ),
  selected: slot,
  onChanged: (s) => setState(() => slot = s),
)''',
        builder: (_) => const _Slots(),
      ),
    ]),
    KitSection('Payment', Icons.credit_card_rounded, [
      KitSample(
        title: 'Payment methods',
        subtitle:
            'M-Pesa, cards, Apple Pay and Google Pay; ones that can’t pay say why.',
        code: '''KitoCheckoutPaymentPicker(
  methods: [
    const KitoCheckoutPaymentMethod.mpesa('0712 345 678'),
    KitoCheckoutPaymentMethod.card(KitoCheckoutCardBrand.visa, '4242', expiry: '08/29'),
    const KitoCheckoutPaymentMethod.applePay(),
    const KitoCheckoutPaymentMethod.googlePay(),
    const KitoCheckoutPaymentMethod.wallet(120000),
  ],
  selected: method,
  onChanged: (m) => setState(() => method = m),
  total: totals.total,
)''',
        builder: (_) => const _Payment(style: KitoCheckoutPaymentStyle.list),
      ),
      KitSample(
        title: 'Payment tiles',
        subtitle: 'The same methods as a grid of brand tiles.',
        code: '''KitoCheckoutPaymentPicker(
  methods: methods,
  selected: method,
  onChanged: pick,
  total: totals.total,
  style: KitoCheckoutPaymentStyle.tiles,
)''',
        builder: (_) => const _Payment(style: KitoCheckoutPaymentStyle.tiles),
      ),
    ]),
    KitSection('Place order', Icons.lock_rounded, [
      KitSample(
        title: 'Place order button',
        subtitle:
            'Shrinks to a spinner, then a tick; every other try fails and shakes.',
        code: '''KitoCheckoutPlaceOrderButton(
  state: state,
  amount: totals.total,
  onPressed: () async {
    setState(() => state = KitoCheckoutOrderState.processing);
    final ok = await api.placeOrder();
    setState(() => state = ok
        ? KitoCheckoutOrderState.success
        : KitoCheckoutOrderState.failure);
  },
)''',
        builder: (_) => const _PlaceOrder(),
      ),
      KitSample(
        title: 'Total bar',
        subtitle: 'A hint keeps the button off until the slot is chosen.',
        code: '''KitoCheckoutTotalBar(
  total: totals.total,
  caption: 'Includes VAT · 4 items',
  hint: slot == null ? 'Choose a delivery slot' : null,
  onPlaceOrder: place,
)''',
        builder: (_) => const _TotalBar(),
      ),
    ]),
    KitSection('Receipt', Icons.verified_rounded, [
      KitSample(
        title: 'Receipt',
        subtitle: 'A torn-edge ticket; tap the order number to copy it.',
        code: '''KitoCheckoutReceipt(
  order: KitoCheckoutPlacedOrder.fromTotals(
    totals,
    number: KitoCheckoutOrderNumber.dated(42, date: DateTime.now()),
    placedAt: DateTime.now(),
    paymentTitle: 'M-Pesa',
  ),
  merchant: 'Kahawa House',
)''',
        builder: (_) =>
            KitoCheckoutReceipt(order: _placed(), merchant: 'Kahawa House'),
      ),
      KitSample(
        title: 'Order placed',
        subtitle: 'A burst and a drawn tick, then the receipt rises in.',
        code: '''KitoCheckoutSuccess(
  order: placed,
  merchant: 'Kahawa House',
  onTrackOrder: openTracking,
  onContinueShopping: () => Navigator.pop(context),
)''',
        builder: (_) => const _Success(),
      ),
    ]),
  ],
);

class _Steps extends StatefulWidget {
  const _Steps({required this.style, this.tint});

  final KitoCheckoutProgressStyle style;
  final Color? tint;

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  var _step = KitoCheckoutStep.delivery;

  void _move(int by) {
    final i = (KitoCheckoutStep.standard.indexOf(_step) + by)
        .clamp(0, KitoCheckoutStep.standard.length - 1);
    setState(() => _step = KitoCheckoutStep.standard[i]);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        KitoCheckoutProgress(
          current: _step,
          style: widget.style,
          tint: widget.tint,
          onStepTap: (s) => setState(() => _step = s),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: () => _move(-1), child: const Text('Back')),
          const SizedBox(width: 8),
          FilledButton(onPressed: () => _move(1), child: const Text('Next')),
        ]),
      ]);
}

class _Promo extends StatefulWidget {
  const _Promo();

  @override
  State<_Promo> createState() => _PromoState();
}

class _PromoState extends State<_Promo> {
  KitoCheckoutPromo? _promo;

  @override
  Widget build(BuildContext context) {
    final totals = KitoCheckoutTotals(
        items: _items, deliveryFee: 25000, promo: _promo, pricing: _pricing);
    return Column(children: [
      KitoCheckoutPromoField(
        applied: _promo,
        onChanged: (p) => setState(() => _promo = p),
        validate: (code) => _check(code, totals.subtotal),
      ),
      const SizedBox(height: 16),
      KitoCheckoutSummary(totals: totals, showsItems: false),
    ]);
  }
}

class _Tips extends StatefulWidget {
  const _Tips();

  @override
  State<_Tips> createState() => _TipsState();
}

class _TipsState extends State<_Tips> {
  var _tip = const KitoCheckoutTip.percentOf(10);

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final totals = KitoCheckoutTotals(
        items: _items, deliveryFee: 35000, tip: _tip, pricing: _pricing);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tip Otieno, your rider',
            style: theme.typography.headline
                .copyWith(color: theme.colors.onSurface)),
        const SizedBox(height: 12),
        KitoCheckoutTipSelector(
          selected: _tip,
          subtotal: totals.subtotal,
          onChanged: (t) => setState(() => _tip = t),
        ),
        const SizedBox(height: 16),
        KitoCheckoutSummary(totals: totals, showsItems: false),
      ],
    );
  }
}

class _Options extends StatefulWidget {
  const _Options();

  @override
  State<_Options> createState() => _OptionsState();
}

class _OptionsState extends State<_Options> {
  KitoCheckoutDeliveryOption? _option = _options.first;

  @override
  Widget build(BuildContext context) => KitoCheckoutDeliveryOptions(
        options: [
          ..._options,
          const KitoCheckoutDeliveryOption(
            id: 'drone',
            kind: KitoCheckoutDeliveryKind.express,
            title: 'Same-hour drone',
            price: 90000,
            eta: KitoCheckoutEta.minutes(15, 20),
            unavailableReason: 'Not flying today — long rains',
          ),
        ],
        selected: _option,
        onChanged: (o) => setState(() => _option = o),
      );
}

class _Addresses extends StatefulWidget {
  const _Addresses();

  @override
  State<_Addresses> createState() => _AddressesState();
}

class _AddressesState extends State<_Addresses> {
  KitoCheckoutAddress? _address = _addresses.first;

  @override
  Widget build(BuildContext context) => KitoCheckoutAddressList(
        addresses: _addresses,
        selected: _address,
        onChanged: (a) => setState(() => _address = a),
        onAdd: () {},
      );
}

KitoCheckoutSchedule _schedule() {
  final today = DateUtils.dateOnly(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));
  return KitoCheckoutSchedule(
    daysAhead: 6,
    closedWeekdays: const {DateTime.sunday},
    booked: {
      KitoCheckoutSchedule.slotId(
          tomorrow, const KitoCheckoutTimeWindow(8, 10)): 6,
      KitoCheckoutSchedule.slotId(
          tomorrow, const KitoCheckoutTimeWindow(10, 12)): 5,
      KitoCheckoutSchedule.slotId(
          tomorrow, const KitoCheckoutTimeWindow(18, 20)): 4,
    },
  );
}

class _Slots extends StatefulWidget {
  const _Slots();

  @override
  State<_Slots> createState() => _SlotsState();
}

class _SlotsState extends State<_Slots> {
  KitoCheckoutSlot? _slot;
  final _plan = _schedule();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitoCheckoutSlotPicker(
          schedule: _plan,
          selected: _slot,
          onChanged: (s) => setState(() => _slot = s),
        ),
        const SizedBox(height: 12),
        Text(
          _slot == null
              ? 'Pick a window'
              : 'Arriving ${KitoCheckoutSchedule.label(_slot!, now: DateTime.now())}',
          style: theme.typography.bodyEmphasized
              .copyWith(color: theme.colors.onSurface),
        ),
      ],
    );
  }
}

class _Payment extends StatefulWidget {
  const _Payment({required this.style});

  final KitoCheckoutPaymentStyle style;

  @override
  State<_Payment> createState() => _PaymentState();
}

class _PaymentState extends State<_Payment> {
  late final _all = _methods();
  late KitoCheckoutPaymentMethod? _method = _all.first;

  @override
  Widget build(BuildContext context) => KitoCheckoutPaymentPicker(
        methods: _all,
        selected: _method,
        onChanged: (m) => setState(() => _method = m),
        total: 245000,
        style: widget.style,
      );
}

class _PlaceOrder extends StatefulWidget {
  const _PlaceOrder();

  @override
  State<_PlaceOrder> createState() => _PlaceOrderState();
}

class _PlaceOrderState extends State<_PlaceOrder> {
  var _state = KitoCheckoutOrderState.idle;
  var _tries = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _place() {
    setState(() => _state = KitoCheckoutOrderState.processing);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final fails = _tries.isEven;
      _tries++;
      setState(() => _state = fails
          ? KitoCheckoutOrderState.failure
          : KitoCheckoutOrderState.success);
      if (_state == KitoCheckoutOrderState.success) {
        _timer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _state = KitoCheckoutOrderState.idle);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => KitoCheckoutPlaceOrderButton(
        state: _state,
        amount: 245000,
        onPressed: _place,
      );
}

class _TotalBar extends StatefulWidget {
  const _TotalBar();

  @override
  State<_TotalBar> createState() => _TotalBarState();
}

class _TotalBarState extends State<_TotalBar> {
  bool _slot = false;

  @override
  Widget build(BuildContext context) => Column(children: [
        SwitchListTile.adaptive(
          value: _slot,
          onChanged: (v) => setState(() => _slot = v),
          title: const Text('Slot chosen: Tomorrow, 2–4 PM'),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: KitoCheckoutTotalBar(
            total: 245000,
            caption: 'Includes VAT · 4 items',
            hint: _slot ? null : 'Choose a delivery slot',
            onPlaceOrder: () {},
          ),
        ),
      ]);
}

class _Success extends StatefulWidget {
  const _Success();

  @override
  State<_Success> createState() => _SuccessState();
}

class _SuccessState extends State<_Success> {
  var _run = 0;

  @override
  Widget build(BuildContext context) => Column(children: [
        KitoCheckoutSuccess(
          key: ValueKey(_run),
          order: _placed(),
          merchant: 'Kahawa House',
          onTrackOrder: () {},
          onContinueShopping: () {},
        ),
        TextButton.icon(
          onPressed: () => setState(() => _run++),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Replay'),
        ),
      ]);
}

/// A four-step checkout inside the phone frame.
class _FullCheckout extends StatefulWidget {
  const _FullCheckout();

  @override
  State<_FullCheckout> createState() => _FullCheckoutState();
}

class _FullCheckoutState extends State<_FullCheckout> {
  var _step = KitoCheckoutStep.cart;
  KitoCheckoutPromo? _promo;
  KitoCheckoutDeliveryOption _option = _options[1];
  KitoCheckoutAddress _address = _addresses.first;
  KitoCheckoutSlot? _slot;
  late final _all = _methods();
  late KitoCheckoutPaymentMethod _method = _all.first;
  var _state = KitoCheckoutOrderState.idle;
  KitoCheckoutPlacedOrder? _placedOrder;
  Timer? _timer;
  final _plan = _schedule();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  KitoCheckoutTotals get _totals => KitoCheckoutTotals(
        items: _items,
        deliveryFee: _option.price,
        promo: _promo,
        pricing: _pricing,
      );

  String? get _hint => switch (_step) {
        KitoCheckoutStep.delivery when _option.usesSlots && _slot == null =>
          'Choose a delivery slot',
        _ => null,
      };

  void _next() {
    final i = KitoCheckoutStep.standard.indexOf(_step);
    if (i < KitoCheckoutStep.standard.length - 1) {
      setState(() => _step = KitoCheckoutStep.standard[i + 1]);
      return;
    }
    setState(() => _state = KitoCheckoutOrderState.processing);
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _state = KitoCheckoutOrderState.success);
      _timer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        final now = DateTime.now();
        setState(() {
          _step = KitoCheckoutStep.done;
          _placedOrder = KitoCheckoutPlacedOrder.fromTotals(
            _totals,
            number: KitoCheckoutOrderNumber.dated(7, date: now),
            placedAt: now,
            eta: _slot != null
                ? 'Arriving ${KitoCheckoutSchedule.label(_slot!, now: now)}'
                : _option.eta.arrivalText,
            destination:
                _option.requiresAddress ? _address.short : _option.subtitle,
            deliveryTitle: _option.title,
            paymentTitle: _method.title,
          );
        });
      });
    });
  }

  void _restart() => setState(() {
        _step = KitoCheckoutStep.cart;
        _state = KitoCheckoutOrderState.idle;
        _placedOrder = null;
        _promo = null;
      });

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    if (_step == KitoCheckoutStep.done && _placedOrder != null) {
      return ColoredBox(
        color: theme.colors.background,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          KitoCheckoutSuccess(
            order: _placedOrder!,
            merchant: 'Kahawa House',
            onContinueShopping: _restart,
          ),
        ]),
      );
    }
    final totals = _totals;
    final body = switch (_step) {
      KitoCheckoutStep.cart => [
          KitoCheckoutSummary(totals: totals),
          const SizedBox(height: 12),
          KitoCheckoutPromoField(
            applied: _promo,
            onChanged: (p) => setState(() => _promo = p),
            validate: (code) => _check(code, totals.subtotal),
          ),
        ],
      KitoCheckoutStep.delivery => [
          KitoCheckoutDeliveryOptions(
            options: _options,
            selected: _option,
            onChanged: (o) => setState(() => _option = o),
          ),
          const SizedBox(height: 16),
          if (_option.usesSlots)
            KitoCheckoutSlotPicker(
              schedule: _plan,
              selected: _slot,
              onChanged: (s) => setState(() => _slot = s),
            )
          else if (_option.requiresAddress)
            KitoCheckoutAddressList(
              addresses: _addresses,
              selected: _address,
              onChanged: (a) => setState(() => _address = a),
            ),
        ],
      KitoCheckoutStep.payment => [
          KitoCheckoutPaymentPicker(
            methods: _all,
            selected: _method,
            onChanged: (m) => setState(() => _method = m),
            total: totals.total,
          ),
        ],
      _ => [
          KitoCheckoutSummary(totals: totals, initiallyExpanded: false),
          const SizedBox(height: 12),
          _ReviewRow(
              icon: _option.kind.icon,
              title: _option.title,
              detail: _slot != null && _option.usesSlots
                  ? KitoCheckoutSchedule.label(_slot!, now: DateTime.now())
                  : _option.eta.label),
          if (_option.requiresAddress)
            _ReviewRow(
                icon: Icons.place_rounded,
                title: _address.title,
                detail: _address.singleLine),
          _ReviewRow(
              icon: Icons.payments_rounded,
              title: _method.title,
              detail: _method.subtitle()),
        ],
    };
    return ColoredBox(
      color: theme.colors.background,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: KitoCheckoutProgress(
            current: _step,
            onStepTap: (s) => setState(() {
              _step = s;
              _state = KitoCheckoutOrderState.idle;
            }),
          ),
        ),
        Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: body),
        ),
        KitoCheckoutTotalBar(
          total: totals.total,
          caption: 'Includes VAT',
          hint: _hint,
          state: _state,
          buttonTitle:
              _step == KitoCheckoutStep.review ? 'Pay with M-Pesa' : 'Continue',
          onPlaceOrder: _next,
        ),
      ]),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(
      {required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KitoSurface(
        border: true,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: theme.colors.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.typography.label.copyWith(
                        color: theme.colors.onSurface,
                        fontWeight: FontWeight.w700)),
                Text(detail,
                    style: theme.typography.caption.copyWith(
                        color: theme.colors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
