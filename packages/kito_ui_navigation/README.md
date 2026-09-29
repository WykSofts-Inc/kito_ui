# kito_ui_navigation

Navigation with polish for Flutter: a custom tab bar in nine animated styles, a swipeable side
menu with six transitions and a kit of drawer parts, scrollable top tabs, and a small typed
router. Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything follows
`KitoTheme`, light and dark, right-to-left layouts and Reduce Motion.

## Install

```yaml
dependencies:
  kito_ui_navigation: ^0.1.0
```

```dart
import 'package:kito_ui_navigation/kito_ui_navigation.dart';
```

## Quick start

```dart
final tabs = KitoTabBarController(items: const [
  KitoTabItem(id: 'home', title: 'Home', icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded),
  KitoTabItem(id: 'cart', title: 'Cart', icon: Icons.shopping_bag_outlined, badgeCount: 2),
  KitoTabItem(id: 'me', title: 'Profile', icon: Icons.person_outline_rounded),
]);

KitoTabScaffold(
  controller: tabs,
  style: KitoTabBarStyle.pill,
  builder: (context, id) => switch (id) {
    'home' => const HomeScreen(),
    'cart' => const CartScreen(),
    _ => const ProfileScreen(),
  },
);
```

Each tab's screen is built the first time it's opened and then kept alive, with its own
navigation state, while hidden. With floating styles the content runs under the bar and
`MediaQuery.padding.bottom` includes it.

## Tab bars

| Style | Look |
|---|---|
| `classic` | Edge to edge; a soft capsule slides behind the selected icon |
| `floating` | A capsule above the content; a dot under the selected icon |
| `pill` | The selected tab grows into a filled pill showing its title |
| `underline` | A line glides along the top edge |
| `bubble` | The selected icon rises into a circle sitting in a dip that glides with it |
| `glass` | Frosted glass floating over the content, with a sliding highlight |
| `segmented` | A filled tile slides behind the icon and title |
| `minimal` | Icons only; the icon bounces and a dot stretches |
| `notched` | A raised centre button in a notch — pass `centerAction` |

```dart
KitoTabBar(
  controller: tabs,
  style: KitoTabBarStyle.notched,
  tint: Colors.indigo,
  centerAction: KitoTabCenterAction(onPressed: compose, semanticLabel: 'New post'),
);
```

The controller's items are mutable, and re-tapping the selected tab is reported separately —
the conventional "scroll to top" gesture:

```dart
tabs.setBadge(5, 'cart');
tabs.onReselect = (id) { if (id == 'home') homeRouter.popToRoot(); };
```

`KitoTabBarShape` is the curved bar on its own, for a `ShapeDecoration` anywhere.

## Top tabs

```dart
KitoTopTabs(
  tabs: const ['For you', 'Following', 'Nearby'],
  selectedIndex: feed,
  onChanged: (i) => setState(() => feed = i),
  style: KitoTopTabsStyle.underline,     // .pill, .chips
);
```

The indicator glides between tabs of any width, and the selected tab scrolls into view.

## Side menu

```dart
final menu = KitoSideMenuController();

KitoSideMenu(
  controller: menu,
  style: KitoSideMenuStyle.scale,        // push, overlay, reveal, rotate3D, floating
  background: const KitoBackground.gradient(KitoGradient.ocean),
  foreground: Colors.white,
  menu: const DrawerContent(),
  child: HomeScreen(onMenu: menu.toggle),
);
```

Drag it open or closed (flings count), tap the screen, press Escape or use the accessibility
dismiss action to close it. It opens from the start edge, so from the right in Arabic or
Hebrew; pass `edge: KitoSideMenuEdge.end` for the other side, and `edgeDragWidth` to only
open from drags near the edge. `menu.progress` follows the drawer as it moves.

## Drawer building blocks

```dart
ListView(padding: const EdgeInsets.all(20), children: [
  const KitoDrawerHeader(
    name: 'Wycliff N',
    detail: 'wycliff@example.com',
    avatar: KitoDrawerAvatar(initials: 'WN', size: 60, showsRing: true),
  ),
  KitoDrawerCallout(
    icon: Icons.mark_email_unread_rounded,
    title: 'Verify your email',
    message: 'Confirm it to keep your account secure.',
    actionTitle: 'Send link',
    onAction: sendLink,
  ),
  KitoDrawerTileGrid(children: [
    KitoDrawerTile(title: 'Orders', icon: Icons.inventory_2_rounded, detail: '2 on the way',
        onTap: openOrders),
    KitoDrawerTile(title: 'Wallet', icon: Icons.account_balance_wallet_rounded,
        detail: r'$248.50', tint: Colors.green, onTap: openWallet),
  ]),
  KitoDrawerSection(title: 'Menu', children: [
    KitoDrawerItem(title: 'Home', icon: Icons.home_rounded, isSelected: true, onTap: goHome),
    KitoDrawerItem(title: 'My wallet', icon: Icons.wallet_rounded, badge: r'$10', onTap: w),
    KitoDrawerItem(title: 'Password', icon: Icons.key_rounded, showsChevron: true, onTap: p),
  ]),
  KitoDrawerToggle(title: 'Dark mode', icon: Icons.dark_mode_rounded,
      value: dark, onChanged: setDark),
  KitoDrawerFooterButton(title: 'Sign out', isDestructive: true, onTap: signOut),
]);
```

They take their text colour from the drawer's `foreground`, so they read on light and dark
drawers. `KitoSideMenuRow` is the classic icon + title + count row, and `KitoSideRail` a slim
column of icons with a gliding highlight.

## Router

```dart
sealed class AppRoute { const AppRoute(); }
class ProductRoute extends AppRoute { const ProductRoute(this.id); final String id; /* == */ }
class CartRoute extends AppRoute { const CartRoute(); }
class SignInRoute extends AppRoute { const SignInRoute(); }

final router = KitoRouter<AppRoute>();

KitoRouterView<AppRoute>(
  router: router,
  root: (context) => const HomeScreen(),
  destination: (context, route) => switch (route) {
    ProductRoute(:final id) => ProductScreen(id: id),
    CartRoute() => const CartScreen(),
    SignInRoute() => const SignInScreen(),
  },
);

router.push(const ProductRoute('42'));
router.popTo(const CartRoute());          // back to the cart, keeping it
router.replaceStack([const CartRoute()]); // deep links
router.presentFullScreen(const SignInRoute());
```

Back buttons and gestures keep the router in step. Inside the view,
`KitoRouter.of<AppRoute>(context)` finds it.

## Accessibility and right-to-left

- Tabs are buttons with a selected state; badges are read as "3 new". Every target is at
  least 44×44 and works with the keyboard.
- The side menu hides the drawer from screen readers while closed and the screen while
  open, offering a "Close menu" button; keyboard focus moves into the drawer when it opens.
- Indicators, the bubble's dip, the notched layout, drags and drawers all mirror in RTL;
  chevrons and the sign-out icon flip.
- Reduce Motion swaps springs and slides for short eases and turns off the icon bounce and the
  3D swing.

## License

MIT — see [LICENSE](LICENSE).
