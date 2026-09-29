// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_navigation/kito_ui_navigation.dart';

import 'helpers.dart';

class _Tabs extends StatefulWidget {
  const _Tabs(this.style, {this.count = 3});
  final KitoTopTabsStyle style;
  final int count;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          KitoTopTabs(
            tabs: [
              for (var i = 0; i < widget.count; i++)
                i == 1 ? 'Following' : 'Tab $i'
            ],
            selectedIndex: selected,
            onChanged: (i) => setState(() => selected = i),
            style: widget.style,
          ),
        ]),
      );
}

Finder _indicator() => find.descendant(
    of: find.byType(AnimatedPositioned), matching: find.byType(DecoratedBox));

void main() {
  group('KitoTopTabs', () {
    for (final style in KitoTopTabsStyle.values) {
      testWidgets('${style.name}: selects on tap', (tester) async {
        await tester.pumpWidget(testApp(_Tabs(style)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Following'));
        await tester.pumpAndSettle();
        final semantics = tester.ensureSemantics();
        expect(tester.getSemantics(find.bySemanticsLabel('Following')),
            isSemantics(label: 'Following', isSelected: true, isButton: true));
        semantics.dispose();
      });
    }

    testWidgets('the underline glides to the selected tab', (tester) async {
      await tester.pumpWidget(testApp(const _Tabs(KitoTopTabsStyle.underline)));
      await tester.pumpAndSettle();
      final tab0 = tester.getRect(find.text('Tab 0'));
      expect(
          tester.getRect(_indicator()).center.dx, closeTo(tab0.center.dx, 1));
      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      final tab1 = tester.getRect(find.text('Following'));
      final line = tester.getRect(_indicator());
      expect(line.center.dx, closeTo(tab1.center.dx, 1));
      expect(line.height, 3);
      expect(line.width, greaterThan(tab1.width), reason: 'spans the padding');
    });

    testWidgets('the pill starts on the right in RTL', (tester) async {
      await tester.pumpWidget(testApp(const _Tabs(KitoTopTabsStyle.pill),
          direction: TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(tester.getCenter(find.text('Tab 0')).dx,
          greaterThan(tester.getCenter(find.text('Following')).dx));
      expect(tester.getRect(_indicator()).center.dx,
          closeTo(tester.getCenter(find.text('Tab 0')).dx, 1));
    });

    testWidgets('scrolls the selected tab into view', (tester) async {
      await tester
          .pumpWidget(testApp(const _Tabs(KitoTopTabsStyle.chips, count: 14)));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(find.text('Tab 13'),
          find.byType(SingleChildScrollView), const Offset(-200, 0));
      await tester.tap(find.text('Tab 13'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.text('Tab 13'));
      expect(rect.right, lessThanOrEqualTo(800));
      expect(rect.left, greaterThanOrEqualTo(0));
    });
  });

  group('Drawer building blocks', () {
    testWidgets('header, items, sections, tiles and footer render and tap',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(testApp(Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            const KitoDrawerHeader(
              name: 'Wycliff N',
              detail: 'wycliff@example.com',
              avatar: KitoDrawerAvatar(initials: 'WN', showsRing: true),
            ),
            KitoDrawerTileGrid(children: [
              KitoDrawerTile(
                  title: 'Orders',
                  icon: Icons.inventory_2_rounded,
                  detail: '2 on the way',
                  onTap: () => tapped.add('orders')),
              KitoDrawerTile(
                  title: 'Wallet',
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => tapped.add('wallet')),
              KitoDrawerTile(
                  title: 'Offers', icon: Icons.sell_rounded, onTap: () {}),
            ]),
            KitoDrawerSection(title: 'Messages', children: [
              KitoDrawerItem(
                  title: 'Home',
                  icon: Icons.home_rounded,
                  isSelected: true,
                  onTap: () => tapped.add('home')),
              KitoDrawerItem(
                  title: 'My wallet',
                  icon: Icons.wallet_rounded,
                  badge: r'$10',
                  showsChevron: true,
                  onTap: () => tapped.add('my wallet')),
            ]),
            KitoSideMenuRow(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                badgeCount: 4,
                onTap: () => tapped.add('notifications')),
            KitoDrawerFooterButton(
                title: 'Sign out',
                isDestructive: true,
                onTap: () => tapped.add('sign out')),
          ]),
        ),
      )));
      expect(find.text('WN'), findsOneWidget);
      expect(find.text('MESSAGES'), findsOneWidget);
      expect(find.text(r'$10'), findsOneWidget);
      // Tiles share rows two by two.
      expect(tester.getTopLeft(find.text('Orders')).dy,
          tester.getTopLeft(find.text('Wallet')).dy);
      expect(tester.getTopLeft(find.text('Offers')).dy,
          greaterThan(tester.getTopLeft(find.text('Orders')).dy));
      for (final label in [
        'Orders',
        'Home',
        'My wallet',
        'Notifications',
        'Sign out'
      ]) {
        await tester.tap(find.text(label));
      }
      expect(
          tapped, ['orders', 'home', 'my wallet', 'notifications', 'sign out']);
    });

    testWidgets('items report selection and badges to screen readers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoDrawerItem(
            title: 'Inbox',
            icon: Icons.inbox_rounded,
            badge: '3',
            isSelected: true,
            onTap: () {}),
      )));
      expect(
          tester.getSemantics(find.byType(KitoDrawerItem)),
          isSemantics(
              label: 'Inbox',
              value: '3',
              isSelected: true,
              hasTapAction: true));
      semantics.dispose();
    });

    testWidgets('toggle flips on a row tap', (tester) async {
      var value = false;
      await tester.pumpWidget(testApp(StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: KitoDrawerToggle(
            title: 'Dark mode',
            icon: Icons.dark_mode_rounded,
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      )));
      await tester.tap(find.text('Dark mode'));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(value, isFalse);
    });

    testWidgets('callout action and dismiss', (tester) async {
      var acted = false, dismissed = false;
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoDrawerCallout(
          icon: Icons.mark_email_unread_rounded,
          title: 'Verify your email',
          message: 'Confirm it to keep your account secure.',
          actionTitle: 'Send link',
          onAction: () => acted = true,
          onDismiss: () => dismissed = true,
        ),
      )));
      await tester.tap(find.text('Send link'));
      await tester.tap(find.bySemanticsLabel('Dismiss'));
      expect(acted, isTrue);
      expect(dismissed, isTrue);
    });

    testWidgets('the rail highlight glides to the selection', (tester) async {
      const items = [
        KitoTabItem(id: 'a', title: 'Home', icon: Icons.home_rounded),
        KitoTabItem(
            id: 'b', title: 'Inbox', icon: Icons.inbox_rounded, badgeCount: 2),
        KitoTabItem(id: 'c', title: 'Settings', icon: Icons.settings_rounded),
      ];
      var selected = 'a';
      await tester.pumpWidget(testApp(StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: KitoSideRail(
            items: items,
            selectedId: selected,
            onSelected: (id) => setState(() => selected = id),
          ),
        ),
      )));
      final before = tester.getTopLeft(find.byType(AnimatedPositioned)).dy;
      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 'c');
      expect(
          tester.getTopLeft(find.byType(AnimatedPositioned)).dy, before + 120);
    });
  });
}
