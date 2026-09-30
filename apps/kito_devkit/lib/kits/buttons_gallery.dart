// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_buttons/kito_ui_buttons.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';
import '../gallery/phone_frame.dart';

/// The gallery for kito_ui_buttons.
final buttonsKit = KitEntry(
  title: 'Buttons',
  package: 'kito_ui_buttons',
  blurb: 'variants, async phases, add-to-cart and fly-to-cart',
  icon: Icons.touch_app_rounded,
  category: KitCategory.components,
  isNew: true,
  sections: [
    KitSection('Basics', Icons.smart_button_rounded, [
      KitSample(
        title: 'Six variants',
        subtitle: 'Primary, tonal, outlined, ghost, destructive and link.',
        code: '''KitoButton(label: 'Pay now', onPressed: pay);
KitoButton(label: 'Save for later', variant: KitoButtonVariant.tonal, onPressed: save);
KitoButton(label: 'Share', variant: KitoButtonVariant.outlined, onPressed: share);
KitoButton(label: 'Skip', variant: KitoButtonVariant.ghost, onPressed: skip);
KitoButton(label: 'Remove item', variant: KitoButtonVariant.destructive, onPressed: remove);
KitoButton(label: 'Terms apply', variant: KitoButtonVariant.link, onPressed: openTerms);''',
        builder: (_) => const _Variants(),
      ),
      KitSample(
        title: 'Sizes',
        subtitle:
            'Small (with a 44-point tap target), medium, large and custom.',
        code:
            '''KitoButton(label: 'Small', size: KitoButtonSize.small, onPressed: go);
KitoButton(label: 'Medium', onPressed: go);
KitoButton(label: 'Large', size: KitoButtonSize.large, onPressed: go);
KitoButton(
  label: 'Custom 52',
  size: const KitoButtonSize.custom(height: 52, horizontalPadding: 28, iconSize: 18),
  onPressed: go,
);''',
        builder: (_) => const _Sizes(),
      ),
      KitSample(
        title: 'Icons and placement',
        subtitle: 'Leading or trailing; directional, so they mirror in RTL.',
        code: '''KitoButton(
  label: 'Continue',
  icon: const Icon(Icons.arrow_forward_rounded),
  iconPlacement: KitoButtonIconPlacement.trailing,
  onPressed: next,
);''',
        builder: (_) => const _Icons(),
      ),
      KitSample(
        title: 'Icon only',
        subtitle: 'Square buttons that read their label to screen readers.',
        code: '''KitoButton.icon(
  icon: const Icon(Icons.favorite_border_rounded),
  semanticLabel: 'Save to favourites',
  variant: KitoButtonVariant.tonal,
  onPressed: like,
);''',
        builder: (_) => const _IconOnly(),
      ),
      KitSample(
        title: 'Full width with a price',
        subtitle: 'A trailing slot and spaceBetween for checkout bars.',
        code: '''KitoButton(
  label: 'Pay with M-Pesa',
  subtitle: '0712 ••• 678',
  leading: const Icon(Icons.phone_android_rounded),
  trailing: const Text('KES 2,450'),
  contentAlignment: KitoButtonContentAlignment.spaceBetween,
  expand: true,
  onPressed: pay,
);''',
        builder: (_) => const _FullWidth(),
      ),
      KitSample(
        title: 'Disabled styles',
        subtitle: 'Faded (default), outlined or a flat fill.',
        code: '''KitoButton(label: 'Faded', onPressed: null);
KitoButton(label: 'Outlined', disabledStyle: KitoButtonDisabledStyle.outlined, onPressed: null);
KitoButton(
  label: 'Filled',
  disabledStyle: KitoButtonDisabledStyle.filled(background: Colors.grey.shade300, foreground: Colors.grey.shade600),
  onPressed: null,
);''',
        builder: (_) => const _Disabled(),
      ),
      KitSample(
        title: 'Press feedback',
        subtitle: 'Hold each one: scale, darken or none.',
        code: '''KitoButton(label: 'Scale', onPressed: go);
KitoButton(label: 'Darken', pressedStyle: KitoButtonPressedStyle.darken, onPressed: go);
KitoButton(label: 'None', pressedStyle: KitoButtonPressedStyle.none, onPressed: go);''',
        builder: (_) => const _Pressed(),
      ),
      KitSample(
        title: 'Tints and shapes',
        subtitle:
            'A per-button colour, and capsule, rounded or square corners.',
        code:
            '''KitoButton(label: 'Safaricom green', tint: const Color(0xFF1FA84F), onPressed: go);
KitoButton(label: 'Rounded', shape: KitoButtonShape.rounded, onPressed: go);
KitoButton(label: 'Square', shape: KitoButtonShape.rectangle, onPressed: go);''',
        builder: (_) => const _Tints(),
      ),
    ]),
    KitSection('Phases', Icons.hourglass_top_rounded, [
      KitSample(
        title: 'Async loading',
        subtitle: 'Return a Future and the spinner runs until it completes.',
        code: '''KitoButton(
  label: 'Save profile',
  onPressed: () async => api.saveProfile(wycliff),
);''',
        builder: (_) => const _AsyncLoading(),
      ),
      KitSample(
        title: 'Success tick',
        subtitle: 'The icon morphs to a tick and the label swaps.',
        code: '''KitoButton(
  label: 'Add to basket',
  icon: const Icon(Icons.add_shopping_cart_rounded),
  showSuccess: true,
  successLabel: 'Added',
  onPressed: () => basket.add(kikoi),
);''',
        builder: (_) => const _Success(),
      ),
      KitSample(
        title: 'Failure shake',
        subtitle: 'A thrown error shakes the button and shows a cross.',
        code: '''KitoButton(
  label: 'Send KES 5,000',
  icon: const Icon(Icons.send_rounded),
  showFailure: true,
  failureLabel: 'Insufficient balance',
  onError: (error, _) => log(error),
  onPressed: () => mpesa.send(to: '0712345678', amount: 5000),
);''',
        builder: (_) => const _Failure(),
      ),
      KitSample(
        title: 'Driven from outside',
        subtitle:
            'A controller sets the phase, e.g. when a payment callback arrives.',
        code: '''final pay = KitoButtonController();
KitoButton(label: 'Pay KES 1,200', controller: pay, showSuccess: true, onPressed: stkPush);
// When the M-Pesa callback lands:
pay.value = KitoButtonPhase.success;''',
        builder: (_) => const _Controlled(),
      ),
    ]),
    KitSection('Add to cart', Icons.shopping_cart_rounded, [
      KitSample(
        title: 'Seven choreographies',
        subtitle:
            'Tap each: rolling cart, drop in, morph, burst, flip, sweep, bounce.',
        code: '''KitoAddToCartButton(
  animation: KitoAddToCartAnimation.rollingCart,
  onPressed: () => cart.add(coffee),
  onAdded: () => setState(() => count++),
);''',
        builder: (_) => const _AllCartAnimations(),
      ),
      KitSample(
        title: 'Full-width add to cart',
        subtitle: 'Localised titles, a hold time and a landing callback.',
        code: '''KitoAddToCartButton(
  label: 'Ongeza kwenye kikapu',
  addedLabel: 'Imeongezwa',
  animation: KitoAddToCartAnimation.fillSweep,
  expand: true,
  hold: const Duration(milliseconds: 1200),
  onPressed: () => cart.add(sukuma),
);''',
        builder: (_) => const _WideCart(),
      ),
      KitSample(
        title: 'Scrub a timeline',
        subtitle:
            'Every frame of a choreography, drawn from one progress value.',
        code: '''KitoAddToCartChoreography(
  progress: progress,
  animation: KitoAddToCartAnimation.morphCircle,
  label: 'Add to cart',
  addedLabel: 'Added',
  colors: KitoButtonTheme.of(context).colorsFor(KitoButtonVariant.primary, context.kito),
  successColor: context.kito.colors.success,
);''',
        builder: (_) => const _Scrubber(),
      ),
    ]),
    KitSection('Fly to cart', Icons.flight_takeoff_rounded, [
      KitSample(
        title: 'Duka shop',
        subtitle:
            'Products arc into the cart badge, which bounces as they land.',
        code: '''final flights = KitoFlightController();

KitoFlightLayer(
  controller: flights,
  child: Scaffold(
    appBar: AppBar(actions: [
      KitoBadgeButton(
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag_rounded,
        count: cart.count,
        semanticLabel: 'Cart',
        flightAnchor: 'cart',
        onPressed: openCart,
      ),
    ]),
    body: ProductGrid(
      addButton: (p) => KitoAddToCartButton(
        animation: KitoAddToCartAnimation.burst,
        onPressed: () => cart.add(p),
        onAdded: () => setState(() => cart.count++),
        flight: KitoFlightRequest(to: 'cart', builder: (_) => ProductThumb(p)),
      ),
    ),
  ),
);''',
        builder: (_) => PhoneFrame(builder: (_) => const _ShopScreen()),
      ),
      KitSample(
        title: 'Badge button',
        subtitle: 'Counts in local digits, caps at 99+ and pops on change.',
        code: '''KitoBadgeButton(
  icon: Icons.notifications_none_rounded,
  activeIcon: Icons.notifications_rounded,
  count: unread,
  semanticLabel: 'Notifications',
  onPressed: openInbox,
);''',
        builder: (_) => const _Badges(),
      ),
    ]),
    KitSection('Theme and motion', Icons.tune_rounded, [
      KitSample(
        title: 'Theme scope',
        subtitle:
            'Rounded corners, lively motion and a brand tint for one subtree.',
        code: '''KitoButtonThemeScope(
  theme: const KitoButtonTheme(
    tint: Color(0xFF0E7C66),
    shape: KitoButtonShape.rounded,
    motion: KitoButtonMotion.lively,
    pressedStyle: KitoButtonPressedStyle.darken,
  ),
  child: checkoutForm,
);''',
        builder: (_) => const _ThemeScope(),
      ),
      KitSample(
        title: 'On Material buttons',
        subtitle: 'The Kito look on FilledButton and TextButton.',
        code: '''FilledButton(
  style: KitoButtonStyles.material(context, variant: KitoButtonVariant.outlined),
  onPressed: save,
  child: const Text('Save'),
);''',
        builder: (_) => const _MaterialStyle(),
      ),
      KitSample(
        title: 'Shake and bounce',
        subtitle: 'The same effects, around any widget.',
        code: '''KitoButtonShake(trigger: wrongPins, child: pinBoxes);
KitoButtonBounce(trigger: points, child: pointsChip);''',
        builder: (_) => const _Effects(),
      ),
    ]),
  ],
);

// MARK: Helpers

Future<void> _wait([int ms = 1200]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

Widget _column(List<Widget> children, {double gap = 12}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    );

// MARK: Basics

class _Variants extends StatelessWidget {
  const _Variants();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          KitoButton(label: 'Pay now', onPressed: () {}),
          KitoButton(
              label: 'Save for later',
              variant: KitoButtonVariant.tonal,
              onPressed: () {}),
          KitoButton(
              label: 'Share',
              variant: KitoButtonVariant.outlined,
              onPressed: () {}),
          KitoButton(
              label: 'Skip',
              variant: KitoButtonVariant.ghost,
              onPressed: () {}),
          KitoButton(
              label: 'Remove item',
              variant: KitoButtonVariant.destructive,
              onPressed: () {}),
          KitoButton(
              label: 'Terms apply',
              variant: KitoButtonVariant.link,
              onPressed: () {}),
        ],
      );
}

class _Sizes extends StatelessWidget {
  const _Sizes();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          KitoButton(
              label: 'Small', size: KitoButtonSize.small, onPressed: () {}),
          KitoButton(label: 'Medium', onPressed: () {}),
          KitoButton(
              label: 'Large', size: KitoButtonSize.large, onPressed: () {}),
          KitoButton(
            label: 'Custom 52',
            size: const KitoButtonSize.custom(
                height: 52, horizontalPadding: 28, iconSize: 18),
            icon: const Icon(Icons.bolt_rounded),
            onPressed: () {},
          ),
        ],
      );
}

class _Icons extends StatelessWidget {
  const _Icons();

  @override
  Widget build(BuildContext context) => _column([
        KitoButton(
          label: 'Continue',
          icon: const Icon(Icons.arrow_forward_rounded),
          iconPlacement: KitoButtonIconPlacement.trailing,
          onPressed: () {},
        ),
        KitoButton(
          label: 'Book a boda',
          icon: const Icon(Icons.two_wheeler_rounded),
          variant: KitoButtonVariant.tonal,
          onPressed: () {},
        ),
        KitoButton(
          label: 'Directions to Sarit Centre',
          icon: const Icon(Icons.near_me_rounded),
          variant: KitoButtonVariant.outlined,
          onPressed: () {},
        ),
      ]);
}

class _IconOnly extends StatelessWidget {
  const _IconOnly();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        children: [
          KitoButton.icon(
              icon: const Icon(Icons.favorite_border_rounded),
              semanticLabel: 'Save to favourites',
              variant: KitoButtonVariant.tonal,
              onPressed: () {}),
          KitoButton.icon(
              icon: const Icon(Icons.share_rounded),
              semanticLabel: 'Share',
              variant: KitoButtonVariant.outlined,
              onPressed: () {}),
          KitoButton.icon(
              icon: const Icon(Icons.add_rounded),
              semanticLabel: 'Add',
              onPressed: () {}),
          KitoButton.icon(
              icon: const Icon(Icons.close_rounded),
              semanticLabel: 'Close',
              size: KitoButtonSize.small,
              variant: KitoButtonVariant.ghost,
              onPressed: () {}),
        ],
      );
}

class _FullWidth extends StatelessWidget {
  const _FullWidth();

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 340,
        child: _column([
          KitoButton(
            label: 'Pay with M-Pesa',
            subtitle: '0712 ••• 678',
            leading: const Icon(Icons.phone_android_rounded),
            trailing: const Text('KES 2,450'),
            contentAlignment: KitoButtonContentAlignment.spaceBetween,
            size: KitoButtonSize.large,
            tint: const Color(0xFF1FA84F),
            expand: true,
            onPressed: () async => _wait(),
          ),
          KitoButton(
            label: 'Checkout · 3 items',
            trailing: const Icon(Icons.chevron_right_rounded),
            contentAlignment: KitoButtonContentAlignment.spaceBetween,
            expand: true,
            onPressed: () {},
          ),
        ]),
      );
}

class _Disabled extends StatelessWidget {
  const _Disabled();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          const KitoButton(label: 'Faded', onPressed: null),
          const KitoButton(
              label: 'Outlined',
              disabledStyle: KitoButtonDisabledStyle.outlined,
              onPressed: null),
          KitoButton(
            label: 'Filled',
            disabledStyle: KitoButtonDisabledStyle.filled(
                background: Colors.grey.shade300,
                foreground: Colors.grey.shade600),
            onPressed: null,
          ),
        ],
      );
}

class _Pressed extends StatelessWidget {
  const _Pressed();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: [
          KitoButton(label: 'Scale', onPressed: () {}),
          KitoButton(
              label: 'Darken',
              pressedStyle: KitoButtonPressedStyle.darken,
              onPressed: () {}),
          KitoButton(
              label: 'None',
              pressedStyle: KitoButtonPressedStyle.none,
              onPressed: () {}),
        ],
      );
}

class _Tints extends StatelessWidget {
  const _Tints();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          KitoButton(
              label: 'Safaricom green',
              tint: const Color(0xFF1FA84F),
              onPressed: () {}),
          KitoButton(
              label: 'Sunset',
              tint: const Color(0xFFE85D04),
              variant: KitoButtonVariant.tonal,
              onPressed: () {}),
          KitoButton(
              label: 'Rounded',
              shape: KitoButtonShape.rounded,
              onPressed: () {}),
          KitoButton(
              label: 'Square',
              shape: KitoButtonShape.rectangle,
              variant: KitoButtonVariant.outlined,
              onPressed: () {}),
        ],
      );
}

// MARK: Phases

class _AsyncLoading extends StatelessWidget {
  const _AsyncLoading();

  @override
  Widget build(BuildContext context) => _column([
        KitoButton(label: 'Save profile', onPressed: () async => _wait(1500)),
        KitoButton(
            label: 'Refresh balance',
            icon: const Icon(Icons.refresh_rounded),
            variant: KitoButtonVariant.outlined,
            onPressed: () async => _wait()),
      ]);
}

class _Success extends StatelessWidget {
  const _Success();

  @override
  Widget build(BuildContext context) => KitoButton(
        label: 'Add to basket',
        icon: const Icon(Icons.add_shopping_cart_rounded),
        showSuccess: true,
        successLabel: 'Added',
        onPressed: () async => _wait(900),
      );
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) => KitoButton(
        label: 'Send KES 5,000',
        icon: const Icon(Icons.send_rounded),
        showFailure: true,
        failureLabel: 'Insufficient balance',
        onPressed: () async {
          await _wait(900);
          throw StateError('Insufficient balance');
        },
      );
}

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  final _pay = KitoButtonController();

  @override
  void dispose() {
    _pay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _column([
        KitoButton(
          label: 'Pay KES 1,200',
          icon: const Icon(Icons.lock_rounded),
          controller: _pay,
          showSuccess: true,
          showFailure: true,
          successLabel: 'Paid',
          failureLabel: 'Declined',
          onPressed: () => setState(() => _pay.value = KitoButtonPhase.loading),
        ),
        Wrap(spacing: 8, children: [
          for (final p in KitoButtonPhase.values)
            ChoiceChip(
              label: Text(p.name),
              selected: _pay.value == p,
              onSelected: (_) => setState(() => _pay.value = p),
            ),
        ]),
      ]);
}

// MARK: Add to cart

class _AllCartAnimations extends StatefulWidget {
  const _AllCartAnimations();

  @override
  State<_AllCartAnimations> createState() => _AllCartAnimationsState();
}

class _AllCartAnimationsState extends State<_AllCartAnimations> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => _column([
        Text('In cart: $_count', style: context.kito.typography.label),
        for (final a in KitoAddToCartAnimation.values)
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(a.title, style: context.kito.typography.caption),
            const SizedBox(height: 6),
            KitoAddToCartButton(
              animation: a,
              variant: a.index.isEven
                  ? KitoButtonVariant.primary
                  : KitoButtonVariant.outlined,
              onPressed: () async => _wait(300),
              onAdded: () => setState(() => _count++),
            ),
          ]),
      ], gap: 14);
}

class _WideCart extends StatelessWidget {
  const _WideCart();

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 340,
        child: _column([
          KitoAddToCartButton(
            label: 'Ongeza kwenye kikapu',
            addedLabel: 'Imeongezwa',
            animation: KitoAddToCartAnimation.fillSweep,
            expand: true,
            size: KitoButtonSize.large,
            hold: const Duration(milliseconds: 1200),
            onPressed: () {},
          ),
          KitoAddToCartButton(
            animation: KitoAddToCartAnimation.rollingCart,
            variant: KitoButtonVariant.tonal,
            expand: true,
            onPressed: () {},
          ),
        ]),
      );
}

class _Scrubber extends StatefulWidget {
  const _Scrubber();

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double _p = 0.4;
  KitoAddToCartAnimation _a = KitoAddToCartAnimation.morphCircle;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return _column([
      DemoWidth(
        width: 280,
        child: DropdownButton<KitoAddToCartAnimation>(
          value: _a,
          isExpanded: true,
          onChanged: (v) => setState(() => _a = v ?? _a),
          items: [
            for (final a in KitoAddToCartAnimation.values)
              DropdownMenuItem(
                  value: a,
                  child: Text(a.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      KitoAddToCartChoreography(
        progress: _p,
        animation: _a,
        label: 'Add to cart',
        addedLabel: 'Added',
        colors: KitoButtonTheme.of(context)
            .colorsFor(KitoButtonVariant.primary, kito),
        successColor: kito.colors.success,
      ),
      DemoWidth(
        width: 280,
        child: Slider(
            value: _p,
            label: '${(_p * 100).round()}%',
            onChanged: (v) => setState(() => _p = v)),
      ),
    ]);
  }
}

// MARK: Fly to cart

class _Product {
  const _Product(this.name, this.price, this.icon, this.color);
  final String name;
  final String price;
  final IconData icon;
  final Color color;
}

const _products = [
  _Product(
      'Kenyan AA coffee', 'KES 1,250', Icons.coffee_rounded, Color(0xFF6F4E37)),
  _Product('Kikoi beach wrap', 'KES 1,800', Icons.dry_cleaning_rounded,
      Color(0xFFE85D04)),
  _Product('Maasai beaded bangle', 'KES 650', Icons.circle_outlined,
      Color(0xFFD6336C)),
  _Product('Kiondo basket', 'KES 2,300', Icons.shopping_basket_rounded,
      Color(0xFF0E7C66)),
];

class _Thumb extends StatelessWidget {
  const _Thumb(this.product, {this.size = 44});
  final _Product product;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: product.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(size / 4),
        ),
        child: Icon(product.icon, color: product.color, size: size * 0.55),
      );
}

class _ShopScreen extends StatefulWidget {
  const _ShopScreen();

  @override
  State<_ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<_ShopScreen> {
  final _flights = KitoFlightController();
  int _count = 0;

  @override
  void dispose() {
    _flights.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return KitoFlightLayer(
      controller: _flights,
      child: Scaffold(
        backgroundColor: kito.colors.background,
        appBar: AppBar(
          backgroundColor: kito.colors.background,
          surfaceTintColor: Colors.transparent,
          title: const Text('Duka la Wycliff'),
          actions: [
            KitoBadgeButton(
              icon: Icons.shopping_bag_outlined,
              activeIcon: Icons.shopping_bag_rounded,
              count: _count,
              semanticLabel: 'Cart',
              flightAnchor: 'cart',
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = _products[i];
            return KitoSurface(
              border: true,
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                _Thumb(p, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: kito.typography.headline),
                      Text(p.price,
                          style: kito.typography.label.copyWith(
                              color: kito.colors.onSurface
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                KitoAddToCartButton(
                  label: 'Add',
                  animation: KitoAddToCartAnimation.burst,
                  size: KitoButtonSize.small,
                  onPressed: () async => _wait(250),
                  onAdded: () => setState(() => _count++),
                  flight:
                      KitoFlightRequest(to: 'cart', builder: (_) => _Thumb(p)),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _Badges extends StatefulWidget {
  const _Badges();

  @override
  State<_Badges> createState() => _BadgesState();
}

class _BadgesState extends State<_Badges> {
  int _unread = 3;

  @override
  Widget build(BuildContext context) => _column([
        Row(mainAxisSize: MainAxisSize.min, children: [
          KitoBadgeButton(
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            count: _unread,
            semanticLabel: 'Notifications',
            onPressed: () => setState(() => _unread = 0),
          ),
          const SizedBox(width: 20),
          KitoBadgeButton(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            count: 128,
            badgeColor: const Color(0xFF1FA84F),
            semanticLabel: 'Messages',
            onPressed: () {},
          ),
        ]),
        Wrap(spacing: 8, children: [
          KitoButton(
              label: 'New message',
              size: KitoButtonSize.small,
              variant: KitoButtonVariant.tonal,
              onPressed: () => setState(() => _unread++)),
          KitoButton(
              label: 'Mark read',
              size: KitoButtonSize.small,
              variant: KitoButtonVariant.ghost,
              onPressed: () => setState(() => _unread = 0)),
        ]),
      ]);
}

// MARK: Theme and motion

class _ThemeScope extends StatelessWidget {
  const _ThemeScope();

  @override
  Widget build(BuildContext context) => KitoButtonThemeScope(
        theme: const KitoButtonTheme(
          tint: Color(0xFF0E7C66),
          shape: KitoButtonShape.rounded,
          motion: KitoButtonMotion.lively,
          pressedStyle: KitoButtonPressedStyle.darken,
        ),
        child: _column([
          KitoButton(
              label: 'Book a matatu seat',
              icon: const Icon(Icons.directions_bus_rounded),
              onPressed: () async => _wait()),
          KitoButton(
              label: 'View route',
              variant: KitoButtonVariant.outlined,
              onPressed: () {}),
        ]),
      );
}

class _MaterialStyle extends StatelessWidget {
  const _MaterialStyle();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          FilledButton(
            style: KitoButtonStyles.material(context),
            onPressed: () {},
            child: const Text('FilledButton'),
          ),
          FilledButton(
            style: KitoButtonStyles.material(context,
                variant: KitoButtonVariant.outlined),
            onPressed: () {},
            child: const Text('Outlined'),
          ),
          TextButton(
            style: KitoButtonStyles.material(context,
                variant: KitoButtonVariant.link),
            onPressed: () {},
            child: const Text('Link style'),
          ),
          FilledButton(
            style: KitoButtonStyles.material(context),
            onPressed: null,
            child: const Text('Disabled'),
          ),
        ],
      );
}

class _Effects extends StatefulWidget {
  const _Effects();

  @override
  State<_Effects> createState() => _EffectsState();
}

class _EffectsState extends State<_Effects> {
  int _shakes = 0;
  int _points = 120;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return _column([
      KitoButtonShake(
        trigger: _shakes,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 44,
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                    color:
                        _shakes > 0 ? kito.colors.danger : kito.colors.border,
                    width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('•', style: TextStyle(fontSize: 24)),
            ),
        ]),
      ),
      KitoButtonBounce(
        trigger: _points,
        child: Chip(
          avatar: const Icon(Icons.stars_rounded, size: 18),
          label: Text('Bonga points: $_points'),
        ),
      ),
      Wrap(spacing: 8, children: [
        KitoButton(
            label: 'Wrong PIN',
            size: KitoButtonSize.small,
            variant: KitoButtonVariant.destructive,
            onPressed: () => setState(() => _shakes++)),
        KitoButton(
            label: 'Earn 10 points',
            size: KitoButtonSize.small,
            variant: KitoButtonVariant.tonal,
            onPressed: () => setState(() => _points += 10)),
      ]),
    ]);
  }
}
