// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_navigation/kito_ui_navigation.dart';

import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';
import '../gallery/phone_frame.dart';

/// The gallery for kito_ui_navigation.
final navigationKit = KitEntry(
  title: 'Navigation',
  package: 'kito_ui_navigation',
  blurb: 'tab bars, side menus, drawer parts, top tabs and a typed router',
  icon: Icons.view_sidebar_rounded,
  category: KitCategory.navigation,
  isNew: true,
  sections: [
    KitSection('Tab bars', Icons.tab_rounded, [
      KitSample(
        title: 'Tab scaffold',
        subtitle:
            'Each tab keeps its own screen and state; the cart badge updates live.',
        code: '''final tabs = KitoTabBarController(items: const [
  KitoTabItem(id: 'home', title: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home_rounded),
  KitoTabItem(id: 'search', title: 'Search', icon: Icons.search_rounded),
  KitoTabItem(id: 'cart', title: 'Cart', icon: Icons.shopping_bag_outlined, badgeCount: 2),
  KitoTabItem(id: 'me', title: 'Profile', icon: Icons.person_outline_rounded),
]);

KitoTabScaffold(
  controller: tabs,
  style: KitoTabBarStyle.pill,
  builder: (context, id) => switch (id) {
    'home' => const HomeScreen(),
    'search' => const SearchScreen(),
    'cart' => const CartScreen(),
    _ => const ProfileScreen(),
  },
);''',
        builder: (_) => PhoneFrame(
            builder: (_) => const _TabApp(style: KitoTabBarStyle.pill)),
      ),
      KitSample(
        title: 'Nine styles',
        subtitle:
            'Classic, floating, pill, underline, bubble, glass, segmented, minimal, notched.',
        code: '''KitoTabScaffold(
  controller: tabs,
  style: KitoTabBarStyle.bubble,   // or any of the nine
  builder: buildTab,
);''',
        builder: (_) => PhoneFrame(builder: (_) => const _StylePicker()),
      ),
      KitSample(
        title: 'Notched with a centre action',
        subtitle: 'A raised button in a notch — send money, post, scan.',
        code: '''KitoTabScaffold(
  controller: tabs,
  style: KitoTabBarStyle.notched,
  tint: const Color(0xFF1FA84F),
  centerAction: KitoTabCenterAction(
    icon: Icons.qr_code_scanner_rounded,
    semanticLabel: 'Scan to pay',
    onPressed: openScanner,
  ),
  builder: buildTab,
);''',
        builder: (_) => PhoneFrame(
            builder: (_) => const _TabApp(
                style: KitoTabBarStyle.notched, tint: Color(0xFF1FA84F))),
      ),
      KitSample(
        title: 'Badges and reselect',
        subtitle:
            'Set a badge from anywhere; tapping the selected tab again is reported.',
        code: '''tabs.setBadge(5, 'inbox');
tabs.onReselect = (id) => scrollToTop(id);''',
        builder: (_) => const _BadgeBar(),
      ),
    ]),
    KitSection('Top tabs', Icons.view_week_rounded, [
      KitSample(
        title: 'Underline top tabs',
        subtitle: 'The line glides between tabs of any width.',
        code: '''KitoTopTabs(
  tabs: const ['For you', 'Following', 'Nairobi', 'Mombasa', 'Kisumu'],
  selectedIndex: feed,
  onChanged: (i) => setState(() => feed = i),
);''',
        builder: (_) => const _TopTabs(style: KitoTopTabsStyle.underline),
      ),
      KitSample(
        title: 'Pill top tabs',
        subtitle: 'A capsule sliding on a soft track.',
        code: '''KitoTopTabs(
  tabs: const ['Day', 'Week', 'Month', 'Year'],
  selectedIndex: range,
  onChanged: (i) => setState(() => range = i),
  style: KitoTopTabsStyle.pill,
);''',
        builder: (_) => const _TopTabs(
            style: KitoTopTabsStyle.pill,
            tabs: ['Day', 'Week', 'Month', 'Year']),
      ),
      KitSample(
        title: 'Chip top tabs',
        subtitle: 'Separate chips that scroll the selected one into view.',
        code: '''KitoTopTabs(
  tabs: const ['All', 'Nyama choma', 'Swahili', 'Ethiopian', 'Indian', 'Vegan', 'Coffee'],
  selectedIndex: cuisine,
  onChanged: (i) => setState(() => cuisine = i),
  style: KitoTopTabsStyle.chips,
);''',
        builder: (_) => const _TopTabs(style: KitoTopTabsStyle.chips, tabs: [
          'All',
          'Nyama choma',
          'Swahili',
          'Ethiopian',
          'Indian',
          'Vegan',
          'Coffee'
        ]),
      ),
    ]),
    KitSection('Side menus', Icons.menu_open_rounded, [
      KitSample(
        title: 'Scale drawer',
        subtitle:
            'The screen shrinks into a card over a gradient drawer. Drag or tap the menu.',
        code: '''final menu = KitoSideMenuController();

KitoSideMenu(
  controller: menu,
  style: KitoSideMenuStyle.scale,
  background: const KitoBackground.gradient(KitoGradient.ocean),
  foreground: Colors.white,
  menu: const DrawerContent(),
  child: HomeScreen(onMenu: menu.toggle),
);''',
        builder: (_) => PhoneFrame(
            builder: (_) => const _MenuApp(style: KitoSideMenuStyle.scale)),
      ),
      KitSample(
        title: 'Push drawer',
        subtitle: 'The drawer slides in and pushes the screen with it.',
        code:
            '''KitoSideMenu(controller: menu, style: KitoSideMenuStyle.push, menu: drawer, child: screen);''',
        builder: (_) => PhoneFrame(
            builder: (_) => const _MenuApp(style: KitoSideMenuStyle.push)),
      ),
      KitSample(
        title: 'From the end edge',
        subtitle: 'An overlay drawer on the other side, for filters or a cart.',
        code: '''KitoSideMenu(
  controller: filters,
  style: KitoSideMenuStyle.overlay,
  edge: KitoSideMenuEdge.end,
  menu: const FiltersPanel(),
  child: screen,
);''',
        builder: (_) => PhoneFrame(
            builder: (_) => const _MenuApp(
                style: KitoSideMenuStyle.overlay, edge: KitoSideMenuEdge.end)),
      ),
      KitSample(
        title: 'All six transitions',
        subtitle: 'Push, overlay, reveal, scale, 3D and floating.',
        code: '''KitoSideMenu(
  controller: menu,
  style: KitoSideMenuStyle.rotate3D,   // push, overlay, reveal, scale, floating
  menu: drawer,
  child: screen,
);''',
        builder: (_) => PhoneFrame(builder: (_) => const _MenuStylePicker()),
      ),
    ]),
    KitSection('Drawer parts', Icons.dashboard_customize_rounded, [
      KitSample(
        title: 'Header and avatar',
        subtitle: 'Stacked or inline, with a gradient ring.',
        code: '''const KitoDrawerHeader(
  name: 'Wycliff N',
  detail: 'wycliff@kito.co.ke',
  avatar: KitoDrawerAvatar(initials: 'WN', size: 60, showsRing: true),
);''',
        builder: (_) => const _Panel(children: [
          KitoDrawerHeader(
            name: 'Wycliff N',
            detail: 'wycliff@kito.co.ke',
            avatar: KitoDrawerAvatar(initials: 'WN', size: 60, showsRing: true),
          ),
          SizedBox(height: 20),
          KitoDrawerHeader(
            name: 'Amina K',
            detail: 'Premium · Mombasa',
            layout: KitoDrawerHeaderLayout.inline,
            avatar: KitoDrawerAvatar(
                initials: 'AK', colors: [Color(0xFF0EA5A4), Color(0xFF2563EB)]),
          ),
        ]),
      ),
      KitSample(
        title: 'Callout and tiles',
        subtitle: 'A prompt with an action, and a grid of shortcut tiles.',
        code: '''KitoDrawerCallout(
  icon: Icons.verified_user_rounded,
  title: 'Verify your ID',
  message: 'Upload your national ID to raise your M-Pesa limit.',
  actionTitle: 'Verify now',
  onAction: verify,
);
KitoDrawerTileGrid(children: [
  KitoDrawerTile(title: 'Orders', icon: Icons.inventory_2_rounded, detail: '2 on the way', onTap: openOrders),
  KitoDrawerTile(title: 'Wallet', icon: Icons.account_balance_wallet_rounded, detail: 'KES 24,580', tint: Colors.green, onTap: openWallet),
]);''',
        builder: (_) => _Panel(children: [
          KitoDrawerCallout(
            icon: Icons.verified_user_rounded,
            title: 'Verify your ID',
            message: 'Upload your national ID to raise your M-Pesa limit.',
            actionTitle: 'Verify now',
            onAction: () {},
            onDismiss: () {},
          ),
          const SizedBox(height: 16),
          KitoDrawerTileGrid(children: [
            KitoDrawerTile(
                title: 'Orders',
                icon: Icons.inventory_2_rounded,
                detail: '2 on the way',
                onTap: () {}),
            KitoDrawerTile(
                title: 'Wallet',
                icon: Icons.account_balance_wallet_rounded,
                detail: 'KES 24,580',
                tint: const Color(0xFF1FA84F),
                onTap: () {}),
            KitoDrawerTile(
                title: 'Trips',
                icon: Icons.directions_bus_rounded,
                detail: 'Nairobi → Nakuru',
                tint: const Color(0xFFE85D04),
                onTap: () {}),
            KitoDrawerTile(
                title: 'Chama',
                icon: Icons.groups_rounded,
                detail: 'Due Saturday',
                tint: const Color(0xFF8E4EC6),
                onTap: () {}),
          ]),
        ]),
      ),
      KitSample(
        title: 'Items, toggles and sign out',
        subtitle:
            'Sections of rows with badges and chevrons, a toggle and a footer button.',
        code: '''KitoDrawerSection(title: 'Menu', children: [
  KitoDrawerItem(title: 'Home', icon: Icons.home_rounded, isSelected: true, onTap: goHome),
  KitoDrawerItem(title: 'M-Pesa statements', icon: Icons.receipt_long_rounded, badge: 'New', onTap: open),
  KitoDrawerItem(title: 'Change PIN', icon: Icons.key_rounded, showsChevron: true, onTap: changePin),
]);
KitoDrawerToggle(title: 'Dark mode', icon: Icons.dark_mode_rounded, value: dark, onChanged: setDark);
KitoDrawerFooterButton(title: 'Sign out', isDestructive: true, onTap: signOut);''',
        builder: (_) => const _ItemsPanel(),
      ),
      KitSample(
        title: 'Rows and rail',
        subtitle:
            'The classic icon-title-count row, and a slim rail with a gliding highlight.',
        code:
            '''KitoSideMenuRow(icon: Icons.inbox_rounded, title: 'Inbox', badgeCount: 12, isSelected: true, onTap: open);

KitoSideRail(
  items: const [
    KitoTabItem(id: 'home', title: 'Home', icon: Icons.home_rounded),
    KitoTabItem(id: 'wallet', title: 'Wallet', icon: Icons.account_balance_wallet_rounded),
    KitoTabItem(id: 'chat', title: 'Chat', icon: Icons.chat_rounded, badgeCount: 3),
  ],
  selectedId: selected,
  onSelected: (id) => setState(() => selected = id),
);''',
        builder: (_) => const _RowsAndRail(),
      ),
    ]),
    KitSection('Router', Icons.alt_route_rounded, [
      KitSample(
        title: 'Typed router',
        subtitle:
            'Push, pop to a route, replace the stack and present full screen — all typed.',
        code: '''sealed class ShopRoute { const ShopRoute(); }
class ProductRoute extends ShopRoute { const ProductRoute(this.name); final String name; }
class CartRoute extends ShopRoute { const CartRoute(); }
class SignInRoute extends ShopRoute { const SignInRoute(); }

final router = KitoRouter<ShopRoute>();

KitoRouterView<ShopRoute>(
  router: router,
  root: (context) => const ShopHome(),
  destination: (context, route) => switch (route) {
    ProductRoute(:final name) => ProductScreen(name),
    CartRoute() => const CartScreen(),
    SignInRoute() => const SignInScreen(),
  },
);

router.push(const ProductRoute('Kiondo basket'));
router.popTo(const CartRoute());
router.presentFullScreen(const SignInRoute());''',
        builder: (_) => PhoneFrame(builder: (_) => const _RouterApp()),
      ),
    ]),
  ],
);

// MARK: Tab apps

const _tabItems = [
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
      selectedIcon: Icons.shopping_bag_rounded,
      badgeCount: 2),
  KitoTabItem(
      id: 'me',
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded),
];

class _TabApp extends StatefulWidget {
  const _TabApp({super.key, required this.style, this.tint});

  final KitoTabBarStyle style;
  final Color? tint;

  @override
  State<_TabApp> createState() => _TabAppState();
}

class _TabAppState extends State<_TabApp> {
  late final _tabs = KitoTabBarController(items: _tabItems);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitoTabScaffold(
        controller: _tabs,
        style: widget.style,
        tint: widget.tint,
        centerAction: widget.style == KitoTabBarStyle.notched
            ? KitoTabCenterAction(
                icon: Icons.qr_code_scanner_rounded,
                semanticLabel: 'Scan to pay',
                onPressed: () {})
            : null,
        builder: (context, id) => _TabScreen(id: id, tabs: _tabs),
      );
}

class _TabScreen extends StatefulWidget {
  const _TabScreen({required this.id, required this.tabs});

  final String id;
  final KitoTabBarController tabs;

  @override
  State<_TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<_TabScreen> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final (title, icon, lines) = switch (widget.id) {
      'home' => (
          'Habari, Wycliff',
          Icons.wb_sunny_rounded,
          [
            'Deals near Westlands',
            'Your usual: Kenyan AA coffee',
            'Rider rated 4.9'
          ]
        ),
      'search' => (
          'Search',
          Icons.search_rounded,
          ['Kikoi', 'Sukuma wiki', 'Kiondo basket', 'Maasai shuka']
        ),
      'cart' => (
          'Cart',
          Icons.shopping_bag_rounded,
          ['Kenyan AA coffee · KES 1,250', 'Kikoi beach wrap · KES 1,800']
        ),
      _ => (
          'Wycliff N',
          Icons.person_rounded,
          ['0712 ••• 678', 'Nairobi, Kenya', 'Member since 2024']
        ),
    };
    return Scaffold(
      backgroundColor: kito.colors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kito.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 16 + MediaQuery.paddingOf(context).bottom),
        children: [
          SizedBox(
            height: 140,
            child: KitoSurface(
              background: const KitoBackground.gradient(KitoGradient.lagoon),
              child: Center(child: Icon(icon, size: 56, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          for (final l in lines)
            ListTile(contentPadding: EdgeInsets.zero, title: Text(l)),
          if (widget.id == 'cart')
            FilledButton(
              onPressed: () => widget.tabs
                  .setBadge(widget.tabs.badgeCount('cart') + 1, 'cart'),
              child: const Text('Add another item'),
            ),
          if (widget.id == 'home')
            OutlinedButton(
              onPressed: () => setState(() => _taps++),
              child: Text('Tapped $_taps times — switch tabs and come back'),
            ),
        ],
      ),
    );
  }
}

class _StylePicker extends StatefulWidget {
  const _StylePicker();

  @override
  State<_StylePicker> createState() => _StylePickerState();
}

class _StylePickerState extends State<_StylePicker> {
  KitoTabBarStyle _style = KitoTabBarStyle.bubble;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      body: Column(children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in KitoTabBarStyle.values)
                  ChoiceChip(
                    label: Text(s.name),
                    selected: s == _style,
                    onSelected: (_) => setState(() => _style = s),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _TabApp(key: ValueKey(_style), style: _style),
        ),
      ]),
    );
  }
}

class _BadgeBar extends StatefulWidget {
  const _BadgeBar();

  @override
  State<_BadgeBar> createState() => _BadgeBarState();
}

class _BadgeBarState extends State<_BadgeBar> {
  late final _tabs = KitoTabBarController(
    items: const [
      KitoTabItem(id: 'home', title: 'Home', icon: Icons.home_rounded),
      KitoTabItem(
          id: 'inbox',
          title: 'Inbox',
          icon: Icons.inbox_rounded,
          badgeCount: 3),
      KitoTabItem(id: 'wallet', title: 'Wallet', icon: Icons.wallet_rounded),
    ],
    onReselect: (id) => setState(() => _reselected = id),
  );
  String? _reselected;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          KitoTabBar(controller: _tabs, style: KitoTabBarStyle.classic),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            OutlinedButton(
              onPressed: () =>
                  _tabs.setBadge(_tabs.badgeCount('inbox') + 1, 'inbox'),
              child: const Text('New message'),
            ),
            OutlinedButton(
              onPressed: () => _tabs.setBadge(0, 'inbox'),
              child: const Text('Clear'),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            _reselected == null
                ? 'Tap the selected tab again'
                : 'Reselected “$_reselected” — scroll to top',
            style: context.kito.typography.caption,
          ),
        ]),
      );
}

class _TopTabs extends StatefulWidget {
  const _TopTabs(
      {required this.style,
      this.tabs = const [
        'For you',
        'Following',
        'Nairobi',
        'Mombasa',
        'Kisumu'
      ]});

  final KitoTopTabsStyle style;
  final List<String> tabs;

  @override
  State<_TopTabs> createState() => _TopTabsState();
}

class _TopTabsState extends State<_TopTabs> {
  int _i = 0;

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          KitoTopTabs(
            tabs: widget.tabs,
            selectedIndex: _i,
            style: widget.style,
            onChanged: (i) => setState(() => _i = i),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: KitoMotion.of(context, context.kito.motion.medium),
            child: Text('Showing: ${widget.tabs[_i]}',
                key: ValueKey(_i), style: context.kito.typography.label),
          ),
        ]),
      );
}

// MARK: Side menus

class _Drawer extends StatelessWidget {
  const _Drawer({required this.menu});
  final KitoSideMenuController menu;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const KitoDrawerHeader(
              name: 'Wycliff N',
              detail: 'wycliff@kito.co.ke',
              avatar: KitoDrawerAvatar(initials: 'WN', showsRing: true),
            ),
            const SizedBox(height: 16),
            KitoDrawerSection(title: 'Menu', children: [
              KitoDrawerItem(
                  title: 'Home',
                  icon: Icons.home_rounded,
                  isSelected: true,
                  onTap: menu.close),
              KitoDrawerItem(
                  title: 'Wallet',
                  icon: Icons.account_balance_wallet_rounded,
                  badge: 'KES 24.5K',
                  onTap: menu.close),
              KitoDrawerItem(
                  title: 'Trips',
                  icon: Icons.directions_bus_rounded,
                  onTap: menu.close),
              KitoDrawerItem(
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  showsChevron: true,
                  onTap: menu.close),
            ]),
            const SizedBox(height: 12),
            KitoDrawerFooterButton(
                title: 'Sign out', isDestructive: true, onTap: menu.close),
          ],
        ),
      );
}

class _MenuApp extends StatefulWidget {
  const _MenuApp(
      {super.key, required this.style, this.edge = KitoSideMenuEdge.start});

  final KitoSideMenuStyle style;
  final KitoSideMenuEdge edge;

  @override
  State<_MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<_MenuApp> {
  final _menu = KitoSideMenuController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final behind = widget.style.drawerIsBehind;
    return KitoSideMenu(
      controller: _menu,
      style: widget.style,
      edge: widget.edge,
      width: 270,
      background:
          behind ? const KitoBackground.gradient(KitoGradient.ocean) : null,
      foreground: behind ? Colors.white : null,
      menu: _Drawer(menu: _menu),
      child: Scaffold(
        backgroundColor: kito.colors.background,
        appBar: AppBar(
          backgroundColor: kito.colors.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: widget.edge == KitoSideMenuEdge.start
              ? IconButton(
                  tooltip: 'Menu',
                  onPressed: _menu.toggle,
                  icon: const Icon(Icons.menu_rounded))
              : null,
          actions: [
            if (widget.edge == KitoSideMenuEdge.end)
              IconButton(
                  tooltip: 'Filters',
                  onPressed: _menu.toggle,
                  icon: const Icon(Icons.tune_rounded)),
          ],
          title: const Text('Kito Safari'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (place, detail, g) in const [
              ('Diani Beach', 'Kwale · 3 nights', KitoGradient.lagoon),
              ('Amboseli', 'Kajiado · Kilimanjaro views', KitoGradient.sunset),
              ('Lake Naivasha', 'Nakuru · boat safari', KitoGradient.ocean),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  height: 130,
                  child: KitoSurface(
                    background: KitoBackground.gradient(g),
                    padding: const EdgeInsets.all(14),
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place,
                              style: kito.typography.title
                                  .copyWith(color: Colors.white)),
                          Text(detail,
                              style: kito.typography.label
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuStylePicker extends StatefulWidget {
  const _MenuStylePicker();

  @override
  State<_MenuStylePicker> createState() => _MenuStylePickerState();
}

class _MenuStylePickerState extends State<_MenuStylePicker> {
  KitoSideMenuStyle _style = KitoSideMenuStyle.rotate3D;

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(child: _MenuApp(key: ValueKey(_style), style: _style)),
        Material(
          color: context.kito.colors.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final s in KitoSideMenuStyle.values)
                  ChoiceChip(
                    label: Text(s.name),
                    selected: s == _style,
                    onSelected: (_) => setState(() => _style = s),
                  ),
              ]),
            ),
          ),
        ),
      ]);
}

// MARK: Drawer parts

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 320,
        child: KitoSurface(
          border: true,
          padding: const EdgeInsets.all(18),
          child: Material(
            type: MaterialType.transparency,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      );
}

class _ItemsPanel extends StatefulWidget {
  const _ItemsPanel();

  @override
  State<_ItemsPanel> createState() => _ItemsPanelState();
}

class _ItemsPanelState extends State<_ItemsPanel> {
  String _selected = 'Home';
  bool _dark = false;

  @override
  Widget build(BuildContext context) => _Panel(children: [
        KitoDrawerSection(title: 'Menu', children: [
          for (final (t, i, badge, chevron) in const [
            ('Home', Icons.home_rounded, null, false),
            ('M-Pesa statements', Icons.receipt_long_rounded, 'New', false),
            ('Change PIN', Icons.key_rounded, null, true),
          ])
            KitoDrawerItem(
              title: t,
              icon: i,
              badge: badge,
              showsChevron: chevron,
              isSelected: _selected == t,
              onTap: () => setState(() => _selected = t),
            ),
        ]),
        const SizedBox(height: 8),
        KitoDrawerToggle(
          title: 'Dark mode',
          icon: Icons.dark_mode_rounded,
          value: _dark,
          onChanged: (v) => setState(() => _dark = v),
        ),
        const SizedBox(height: 12),
        KitoDrawerFooterButton(
            title: 'Sign out', isDestructive: true, onTap: () {}),
      ]);
}

class _RowsAndRail extends StatefulWidget {
  const _RowsAndRail();

  @override
  State<_RowsAndRail> createState() => _RowsAndRailState();
}

class _RowsAndRailState extends State<_RowsAndRail> {
  String _rail = 'home';
  String _row = 'Inbox';

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 340,
        child: KitoSurface(
          border: true,
          padding: const EdgeInsets.all(12),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  child: KitoSideRail(
                    items: const [
                      KitoTabItem(
                          id: 'home', title: 'Home', icon: Icons.home_rounded),
                      KitoTabItem(
                          id: 'wallet',
                          title: 'Wallet',
                          icon: Icons.account_balance_wallet_rounded),
                      KitoTabItem(
                          id: 'chat',
                          title: 'Chat',
                          icon: Icons.chat_rounded,
                          badgeCount: 3),
                    ],
                    selectedId: _rail,
                    onSelected: (id) => setState(() => _rail = id),
                    header: const KitoDrawerAvatar(initials: 'WN', size: 40),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(children: [
                    for (final (t, i, n) in const [
                      ('Inbox', Icons.inbox_rounded, 12),
                      ('Sent', Icons.send_rounded, 0),
                      ('Receipts', Icons.receipt_rounded, 4),
                      ('Archive', Icons.archive_rounded, 0),
                    ])
                      KitoSideMenuRow(
                        icon: i,
                        title: t,
                        badgeCount: n,
                        isSelected: _row == t,
                        onTap: () => setState(() => _row = t),
                      ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      );
}

// MARK: Router

sealed class _ShopRoute {
  const _ShopRoute();
}

class _ProductRoute extends _ShopRoute {
  const _ProductRoute(this.name, this.price);
  final String name;
  final String price;

  @override
  bool operator ==(Object other) =>
      other is _ProductRoute && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class _CartRoute extends _ShopRoute {
  const _CartRoute();

  @override
  bool operator ==(Object other) => other is _CartRoute;

  @override
  int get hashCode => 1;
}

class _SignInRoute extends _ShopRoute {
  const _SignInRoute();

  @override
  bool operator ==(Object other) => other is _SignInRoute;

  @override
  int get hashCode => 2;
}

class _RouterApp extends StatefulWidget {
  const _RouterApp();

  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  final _router = KitoRouter<_ShopRoute>();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitoRouterView<_ShopRoute>(
        router: _router,
        root: (context) => const _ShopHome(),
        destination: (context, route) => switch (route) {
          _ProductRoute() => _ProductPage(route),
          _CartRoute() => const _CartPage(),
          _SignInRoute() => const _SignInPage(),
        },
      );
}

Widget _page(BuildContext context, String title, List<Widget> children,
    {bool close = false}) {
  final kito = context.kito;
  return Scaffold(
    backgroundColor: kito.colors.background,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: kito.colors.background,
      surfaceTintColor: Colors.transparent,
      leading: close
          ? IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: () =>
                  KitoRouter.of<_ShopRoute>(context).dismissFullScreen())
          : null,
    ),
    body: ListView(padding: const EdgeInsets.all(16), children: children),
  );
}

class _ShopHome extends StatelessWidget {
  const _ShopHome();

  @override
  Widget build(BuildContext context) {
    final router = KitoRouter.of<_ShopRoute>(context);
    return _page(context, 'Duka', [
      for (final (name, price) in const [
        ('Kiondo basket', 'KES 2,300'),
        ('Kenyan AA coffee', 'KES 1,250'),
        ('Kikoi beach wrap', 'KES 1,800'),
      ])
        ListTile(
          title: Text(name),
          subtitle: Text(price),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => router.push(_ProductRoute(name, price)),
        ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => router.replaceStack(const [_CartRoute()]),
        child: const Text('Deep link: open cart'),
      ),
      TextButton(
        onPressed: () => router.presentFullScreen(const _SignInRoute()),
        child: const Text('Sign in'),
      ),
    ]);
  }
}

class _ProductPage extends StatelessWidget {
  const _ProductPage(this.route);
  final _ProductRoute route;

  @override
  Widget build(BuildContext context) {
    final router = KitoRouter.of<_ShopRoute>(context);
    return _page(context, route.name, [
      SizedBox(
        height: 160,
        child: KitoSurface(
          background: const KitoBackground.gradient(KitoGradient.sunset),
          child: Center(
              child: Text(route.price,
                  style: context.kito.typography.title
                      .copyWith(color: Colors.white))),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
          onPressed: () => router.push(const _CartRoute()),
          child: const Text('Add to cart')),
      TextButton(
          onPressed: () => router
              .push(const _ProductRoute('Maasai beaded bangle', 'KES 650')),
          child: const Text('You may also like: beaded bangle')),
      Text('Stack: ${router.path.length} deep',
          textAlign: TextAlign.center, style: context.kito.typography.caption),
    ]);
  }
}

class _CartPage extends StatelessWidget {
  const _CartPage();

  @override
  Widget build(BuildContext context) {
    final router = KitoRouter.of<_ShopRoute>(context);
    return _page(context, 'Cart', [
      const ListTile(title: Text('Kiondo basket'), trailing: Text('KES 2,300')),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: () => router.presentFullScreen(const _SignInRoute()),
        child: const Text('Checkout'),
      ),
      TextButton(
          onPressed: router.popToRoot, child: const Text('Back to the shop')),
    ]);
  }
}

class _SignInPage extends StatelessWidget {
  const _SignInPage();

  @override
  Widget build(BuildContext context) => _page(
        context,
        'Sign in',
        [
          const TextField(
              decoration: InputDecoration(
                  labelText: 'Phone number', hintText: '0712 345 678')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                KitoRouter.of<_ShopRoute>(context).dismissFullScreen(),
            child: const Text('Send code'),
          ),
        ],
        close: true,
      );
}
