# kito_ui_empty_states

Empty, error and offline states that feel alive: a glossy tile with an icon, satellites that
float around it, sparkles that twinkle and a motion of its own — a bell that swings, a heart that
beats, a magnifier that scans. Everything is drawn in Flutter; there are no image assets to ship.

## Install

```yaml
dependencies:
  kito_ui_empty_states: ^0.1.0
```

## Quick start

```dart
KitoEmptyStateView(
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.cart),
  title: 'Your cart is empty',
  message: 'Everything you add shows up here.',
  actions: [
    KitoEmptyStateAction(label: 'Start shopping', onPressed: openShop),
    KitoEmptyStateAction(label: 'View wishlist', role: KitoEmptyStateActionRole.secondary,
        onPressed: openWishlist),
  ],
);
```

## Presets

```dart
KitoEmptyStateView.noData(title: 'No orders yet');
KitoEmptyStateView.noResults(query: searchText);
KitoEmptyStateView.offline(onRetry: reload);
KitoEmptyStateView.error(message: error.toString(), onRetry: reload);
```

Illustrations: `inbox`, `search`, `offline`, `cart`, `notifications`, `error`, `success`,
`location`, `photos`, `favourites`, `messages`, `calendar`, `wallet`, `downloads`, `locked`
(all in `KitoEmptyStateIllustration.presets`). Recolour one with `.tinted([...])`, or make your own:

```dart
const plants = KitoEmptyStateIllustration(
  name: 'No plants yet',
  icon: Icons.local_florist_rounded,
  satellites: [Icons.water_drop_rounded, Icons.wb_sunny_rounded, Icons.eco_rounded],
  colors: [Color(0xFF22C55E), Color(0xFF0EA5A4)],
  motion: KitoEmptyStateMotion.rock,
);
KitoEmptyStateIllustrationView(plants, size: 200);
```

Motions: `float`, `swing`, `shake`, `bounce`, `beat`, `sweep`, `rock`.

## Layouts

```dart
// Beside the text, for cards and list sections.
KitoEmptyStateView(layout: KitoEmptyStateLayout.compact, ...);

// One dashed row inside a form: "No payment methods yet · Add".
KitoEmptyStateView(
  layout: KitoEmptyStateLayout.inline,
  media: const KitoEmptyStateMedia.icon(Icons.credit_card_rounded),
  title: 'No payment methods yet',
  actions: [KitoEmptyStateAction(label: 'Add', onPressed: addCard)],
);

// The whole screen, tinted, with actions at the bottom.
KitoEmptyStateView.offline(onRetry: reload, layout: KitoEmptyStateLayout.fullScreen);
```

Media can also be `KitoEmptyStateMedia.icon`, `.image(AssetImage(...))` or `.widget(...)` for a
Lottie or Rive animation of your own.

## Futures and streams

```dart
FutureBuilder(
  future: orders,
  builder: (context, snapshot) => KitoEmptyStateSnapshotView(
    snapshot: snapshot,
    isEmpty: (orders) => orders.isEmpty,
    empty: KitoEmptyStateView.noData(title: 'No orders yet'),
    onRetry: reload,
    builder: (context, orders) => OrderList(orders),
  ),
);
```

## Accessibility and motion

Titles are headers, actions are buttons with 44-point targets, and each illustration is a single
image read by its name. With Reduce Motion on, illustrations are drawn still and the entrance is a
short fade. Illustrations stop ticking when their route is covered. Layouts use start/end, so
compact and inline states mirror in right-to-left languages.

In widget tests, an animated illustration never "settles"; pump a fixed duration, or set
`MediaQueryData(disableAnimations: true)` so `pumpAndSettle` works.

## License

MIT — see [LICENSE](LICENSE).
