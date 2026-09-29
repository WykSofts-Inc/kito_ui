// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_navigation/kito_ui_navigation.dart';

import 'helpers.dart';

const _items = [
  KitoTabItem(
      id: 'home',
      title: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded),
  KitoTabItem(id: 'search', title: 'Search', icon: Icons.search_rounded),
  KitoTabItem(
      id: 'cart',
      title: 'Cart',
      icon: Icons.shopping_bag_outlined,
      badgeCount: 3),
  KitoTabItem(id: 'me', title: 'Profile', icon: Icons.person_outline_rounded),
];

Widget _bar(KitoTabBarController c, KitoTabBarStyle style,
        {KitoTabCenterAction? center}) =>
    Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar:
          KitoTabBar(controller: c, style: style, centerAction: center),
    );

void main() {
  group('KitoTabBarController', () {
    test('selects the first tab unless told otherwise', () {
      expect(KitoTabBarController(items: _items).selectedId, 'home');
      expect(
          KitoTabBarController(items: _items, selectedId: 'cart').selectedIndex,
          2);
      expect(KitoTabBarController(items: _items, selectedId: 'nope').selectedId,
          'home');
    });

    test('select switches, a re-tap reports, unknown ids are ignored', () {
      final reselected = <String>[];
      var notified = 0;
      final c = KitoTabBarController(items: _items, onReselect: reselected.add)
        ..addListener(() => notified++);
      c.select('search');
      expect(c.selectedId, 'search');
      c.select('search');
      expect(reselected, ['search']);
      c.select('ghost');
      expect(c.selectedId, 'search');
      expect(notified, 1);
    });

    test('setBadge updates one tab and keeps the selection', () {
      final c = KitoTabBarController(items: _items, selectedId: 'me');
      c.setBadge(5, 'cart');
      expect(c.badgeCount('cart'), 5);
      c.setBadge(-2, 'cart');
      expect(c.badgeCount('cart'), 0);
      c.setBadge(4, 'ghost');
      expect(c.badgeCount('ghost'), 0);
      expect(c.selectedId, 'me');
    });

    test('changing the tabs keeps the selection, or falls back to the first',
        () {
      final c = KitoTabBarController(items: _items, selectedId: 'cart');
      c.items = _items.reversed.toList();
      expect(c.selectedId, 'cart');
      c.items = _items.take(2).toList();
      expect(c.selectedId, 'home');
    });

    test('badges read 99+ past 99', () {
      expect(KitoTabItem.badgeText(7), '7');
      expect(KitoTabItem.badgeText(120), '99+');
    });
  });

  group('KitoTabBarShape', () {
    test('the dip follows the centre, mirrored in RTL', () {
      const shape = KitoTabBarShape(notchCenter: 0.25, horizontalInset: 10);
      const rect = Rect.fromLTWH(0, 0, 420, 60);
      expect(shape.notchX(rect), 10 + 0.25 * 400);
      expect(shape.notchX(rect, TextDirection.rtl), 420 - (10 + 0.25 * 400));
      expect(const KitoTabBarShape(notchCenter: 3).notchX(rect), 420);
    });

    test('lerps the dip', () {
      final mid = KitoTabBarShape.lerp(const KitoTabBarShape(notchCenter: 0),
          const KitoTabBarShape(notchCenter: 1), 0.5);
      expect(mid.notchCenter, 0.5);
      expect(
          const KitoTabBarShape(notchCenter: 1)
              .lerpFrom(const KitoTabBarShape(notchCenter: 0), 0.25),
          const KitoTabBarShape(notchCenter: 0.25));
    });
  });

  group('KitoTabBar', () {
    for (final style in KitoTabBarStyle.values) {
      testWidgets('${style.name}: shows the tabs and switches on tap',
          (tester) async {
        final c = KitoTabBarController(items: _items);
        await tester.pumpWidget(testApp(_bar(c, style)));
        await tester.pumpAndSettle();
        for (final item in _items) {
          expect(find.bySemanticsLabel(item.title), findsOneWidget);
        }
        await tester.tap(find.bySemanticsLabel('Search'));
        await tester.pumpAndSettle();
        expect(c.selectedId, 'search');
        expect(find.text('3'), findsOneWidget, reason: 'the cart badge');
      });
    }

    testWidgets('tabs expose selection and badges to screen readers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final c = KitoTabBarController(items: _items);
      await tester.pumpWidget(testApp(_bar(c, KitoTabBarStyle.classic)));
      await tester.pumpAndSettle();
      expect(
          tester.getSemantics(find.bySemanticsLabel('Home')),
          isSemantics(
              label: 'Home',
              isSelected: true,
              isButton: true,
              hasTapAction: true));
      expect(tester.getSemantics(find.bySemanticsLabel('Cart')),
          isSemantics(label: 'Cart', value: '3 new', isSelected: false));
      semantics.dispose();
    });

    testWidgets('pill shows only the selected title', (tester) async {
      final c = KitoTabBarController(items: _items);
      await tester.pumpWidget(testApp(_bar(c, KitoTabBarStyle.pill)));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsNothing);
      c.select('search');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('the selected icon swaps to its filled variant',
        (tester) async {
      final c = KitoTabBarController(items: _items, selectedId: 'search');
      await tester.pumpWidget(testApp(_bar(c, KitoTabBarStyle.minimal)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      c.select('home');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('notched shows the centre action, or falls back to floating',
        (tester) async {
      var created = 0;
      final c = KitoTabBarController(items: _items);
      await tester.pumpWidget(testApp(_bar(c, KitoTabBarStyle.notched,
          center: KitoTabCenterAction(
              onPressed: () => created++, semanticLabel: 'New post'))));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('New post'));
      expect(created, 1);
      // Two tabs either side of the button.
      expect(tester.getCenter(find.bySemanticsLabel('Search')).dx,
          lessThan(tester.getCenter(find.bySemanticsLabel('New post')).dx));
      expect(tester.getCenter(find.bySemanticsLabel('Cart')).dx,
          greaterThan(tester.getCenter(find.bySemanticsLabel('New post')).dx));

      await tester.pumpWidget(testApp(_bar(c, KitoTabBarStyle.notched)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });

    testWidgets('mirrors in RTL', (tester) async {
      final c = KitoTabBarController(items: _items);
      await tester.pumpWidget(testApp(_bar(c, KitoTabBarStyle.underline),
          direction: TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(tester.getCenter(find.bySemanticsLabel('Home')).dx,
          greaterThan(tester.getCenter(find.bySemanticsLabel('Profile')).dx));
    });

    testWidgets('the bubble circle follows the selection, mirrored in RTL',
        (tester) async {
      Finder circle() => find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
          w.constraints?.maxWidth == 52);
      final c = KitoTabBarController(items: _items);
      await tester.pumpWidget(testApp(_bar(c, KitoTabBarStyle.bubble)));
      await tester.pumpAndSettle();
      final first = tester.getCenter(circle()).dx;
      c.select('me');
      await tester.pumpAndSettle();
      expect(tester.getCenter(circle()).dx, greaterThan(first + 300));

      final r = KitoTabBarController(items: _items);
      await tester.pumpWidget(testApp(_bar(r, KitoTabBarStyle.bubble),
          direction: TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(tester.getCenter(circle()).dx, greaterThan(600));
    });

    testWidgets('reduce motion jumps rather than glides', (tester) async {
      final c = KitoTabBarController(items: _items);
      await tester.pumpWidget(
          testApp(_bar(c, KitoTabBarStyle.segmented), reduceMotion: true));
      await tester.pumpAndSettle();
      c.select('me');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(align.duration, Duration.zero);
    });
  });

  group('KitoTabScaffold', () {
    testWidgets('builds tabs on first visit and keeps their state',
        (tester) async {
      final built = <String>[];
      final c = KitoTabBarController(items: _items);
      await tester.pumpWidget(testApp(KitoTabScaffold(
        controller: c,
        style: KitoTabBarStyle.floating,
        builder: (context, id) {
          built.add(id);
          return _Counter(id: id);
        },
      )));
      expect(built, ['home']);
      await tester.tap(find.text('home 0'));
      await tester.pump();
      expect(find.text('home 1'), findsOneWidget);

      c.select('cart');
      await tester.pumpAndSettle();
      expect(find.text('cart 0'), findsOneWidget);
      expect(find.text('home 1'), findsNothing);
      expect(built.contains('search'), isFalse);

      c.select('home');
      await tester.pumpAndSettle();
      expect(find.text('home 1'), findsOneWidget, reason: 'state kept');
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter({required this.id});
  final String id;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
            onPressed: () => setState(() => n++),
            child: Text('${widget.id} $n')),
      );
}
