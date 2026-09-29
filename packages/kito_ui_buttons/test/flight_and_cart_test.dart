// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_buttons/kito_ui_buttons.dart';

import 'host.dart';

Widget shop(KitoFlightController controller, {Widget? source, int count = 0}) =>
    KitoFlightLayer(
      controller: controller,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: KitoBadgeButton(
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart,
              count: count,
              semanticLabel: 'Cart',
              flightAnchor: 'cart',
              onPressed: () {},
            ),
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: source ??
                const KitoFlightAnchor(
                    id: 'product', child: SizedBox.square(dimension: 60)),
          ),
        ],
      ),
    );

void main() {
  group('flights', () {
    testWidgets('fly arcs an item to its target and counts the landing',
        (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(shop(controller)));
      var landed = false;
      final ok = controller.fly(
          from: 'product',
          to: 'cart',
          builder: (_) =>
              const ColoredBox(key: Key('flying'), color: Colors.orange),
          onLanded: () => landed = true);
      expect(ok, isTrue);
      await tester.pump();
      expect(find.byKey(const Key('flying')), findsOneWidget);
      expect(controller.flights, hasLength(1));

      await tester.pump(const Duration(milliseconds: 350));
      final mid = tester.getCenter(find.byKey(const Key('flying')));
      final start = controller.frameOf('product')!.center;
      expect(mid.dy, lessThan(start.dy));

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('flying')), findsNothing);
      expect(controller.landings('cart'), 1);
      expect(landed, isTrue);
    });

    testWidgets('unknown anchors or a missing layer refuse to fly',
        (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      expect(controller.isAttached, isFalse);
      expect(
          controller.flyFromPoint(Offset.zero,
              to: 'cart', builder: (_) => const SizedBox()),
          isFalse);
      await tester.pumpWidget(host(shop(controller)));
      expect(controller.isAttached, isTrue);
      expect(
          controller.fly(
              from: 'nowhere', to: 'cart', builder: (_) => const SizedBox()),
          isFalse);
      expect(controller.frameOf('nowhere'), isNull);
    });

    testWidgets('Reduce Motion lands instantly', (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(shop(controller), reduceMotion: true));
      controller.fly(
          from: 'product', to: 'cart', builder: (_) => const SizedBox());
      expect(controller.flights, isEmpty);
      expect(controller.landings('cart'), 1);
    });

    testWidgets('frames are physical in RTL, so flights still find the cart',
        (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester
          .pumpWidget(host(shop(controller), direction: TextDirection.rtl));
      final cart = controller.frameOf('cart')!;
      final product = controller.frameOf('product')!;
      // topEnd is the left in RTL, bottomStart the right.
      expect(cart.center.dx, lessThan(product.center.dx));
    });

    testWidgets('a button with a flight launches it on tap', (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(shop(controller,
          source: KitoButton(
            label: 'Add',
            onPressed: () {},
            flight: KitoFlightRequest(
                to: 'cart', builder: (_) => const Icon(Icons.star)),
          ))));
      await tester.tap(find.byType(KitoButton));
      await tester.pump();
      expect(controller.flights, hasLength(1));
      await tester.pumpAndSettle();
      expect(controller.landings('cart'), 1);
    });
  });

  group('badge button', () {
    testWidgets('shows the count and announces it', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(shop(controller, count: 3)));
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(KitoBadgeButton)),
        matchesSemantics(
            label: 'Cart, 3 items',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('caps big counts and hides at zero', (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(shop(controller, count: 250)));
      expect(find.text('99+'), findsOneWidget);
      await tester.pumpWidget(host(shop(controller)));
      await tester.pumpAndSettle();
      final scale = tester.widget<AnimatedScale>(find.descendant(
          of: find.byType(KitoBadgeButton),
          matching: find.byType(AnimatedScale)));
      expect(scale.scale, 0);
      expect(tester.getSize(find.byType(KitoBadgeButton)).width,
          greaterThanOrEqualTo(44));
    });

    testWidgets('bounces when a flight lands', (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(shop(controller, count: 1)));
      controller.fly(
          from: 'product', to: 'cart', builder: (_) => const SizedBox());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 720));
      await tester.pump(const Duration(milliseconds: 100));
      final bounce = find.descendant(
          of: find.byType(KitoButtonBounce), matching: find.byType(Transform));
      final scale =
          tester.widget<Transform>(bounce.first).transform.getMaxScaleOnAxis();
      expect(scale, greaterThan(1));
      await tester.pumpAndSettle();
    });
  });

  group('add to cart', () {
    testWidgets('every choreography draws its whole timeline, LTR and RTL',
        (tester) async {
      for (final animation in KitoAddToCartAnimation.values) {
        for (final dir in TextDirection.values) {
          for (final p in [0.0, 0.2, 0.45, 0.6, 0.8, 0.95, 1.0]) {
            await tester.pumpWidget(host(
              KitoAddToCartChoreography(
                progress: p,
                animation: animation,
                label: 'Add to cart',
                addedLabel: 'Added',
                colors: KitoButtonColors(
                    background: Colors.black, foreground: Colors.white),
                successColor: Colors.green,
              ),
              direction: dir,
            ));
          }
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the idle and added titles show at the ends of the timeline',
        (tester) async {
      Widget frame(double p) => host(KitoAddToCartChoreography(
            progress: p,
            animation: KitoAddToCartAnimation.fillSweep,
            label: 'Add to cart',
            addedLabel: 'Added',
            colors: KitoButtonColors(
                background: Colors.transparent, foreground: Colors.black),
            successColor: Colors.green,
          ));
      double opacityOf(String text) {
        final o = find.ancestor(
            of: find.text(text).last, matching: find.byType(Opacity));
        return tester.widget<Opacity>(o.first).opacity;
      }

      await tester.pumpWidget(frame(0));
      expect(opacityOf('Added'), 0);
      await tester.pumpWidget(frame(1));
      expect(opacityOf('Added'), 1);
    });

    testWidgets('plays, lands, then resets', (tester) async {
      final handle = tester.ensureSemantics();
      final haptics = recordHaptics(tester);
      var added = 0;
      await tester.pumpWidget(host(KitoAddToCartButton(
        animation: KitoAddToCartAnimation.burst,
        onPressed: () async {},
        onAdded: () => added++,
      )));
      expect(find.text('Add to cart'), findsWidgets);
      await tester.tap(find.byType(KitoAddToCartButton));
      await tester.pump();
      expect(tester.getSemantics(find.byType(KitoAddToCartButton)).value,
          'Adding');
      await tester.pump(const Duration(milliseconds: 500));
      expect(added, 1);
      expect(haptics, contains('HapticFeedbackType.mediumImpact'));

      // A second tap while playing does nothing.
      await tester.tap(find.byType(KitoAddToCartButton), warnIfMissed: false);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(added, 1);
      expect(tester.getSemantics(find.byType(KitoAddToCartButton)).value, '');
      handle.dispose();
    });

    testWidgets('a throwing action shakes and resets without landing',
        (tester) async {
      Object? error;
      var added = 0;
      await tester.pumpWidget(host(KitoAddToCartButton(
        onPressed: () async => throw StateError('out of stock'),
        onAdded: () => added++,
        onError: (e, _) => error = e,
      )));
      await tester.tap(find.byType(KitoAddToCartButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(error, isA<StateError>());
      await tester.pumpAndSettle();
      expect(added, 0);
    });

    testWidgets('Reduce Motion crossfades straight to added', (tester) async {
      var added = 0;
      await tester.pumpWidget(host(
          KitoAddToCartButton(
              addedLabel: 'Done', onPressed: () {}, onAdded: () => added++),
          reduceMotion: true));
      await tester.tap(find.byType(KitoAddToCartButton));
      await tester.pump(const Duration(milliseconds: 250));
      expect(added, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('disabled without an action and localised by default',
        (tester) async {
      await tester.pumpWidget(host(
        const KitoAddToCartButton(onPressed: null),
        locale: const Locale('fr'),
      ));
      expect(find.text('Ajouter au panier'), findsWidgets);
      await tester.tap(find.byType(KitoAddToCartButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(KitoAddToCartButton), findsOneWidget);
    });

    testWidgets('launches its flight at the landing moment', (tester) async {
      final controller = KitoFlightController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(shop(controller,
          source: KitoAddToCartButton(
            onPressed: () {},
            flight: KitoFlightRequest(
                to: 'cart', builder: (_) => const Icon(Icons.star)),
          ))));
      await tester.tap(find.byType(KitoAddToCartButton));
      await tester.pump();
      expect(controller.flights, isEmpty);
      await tester.pump(const Duration(milliseconds: 950));
      expect(controller.flights, hasLength(1));
      await tester.pumpAndSettle();
      expect(controller.landings('cart'), 1);
    });
  });
}
