# kito_ui_buttons

Polished, animated buttons for Flutter — the Flutter edition of KitoButtons. Six variants, three
sizes, icons and content slots, async actions that morph through loading → success / failure,
seven choreographed add-to-cart animations, fly-to-cart flights and a bouncing badge button.

- Black capsule by default (white in dark mode), following your `KitoTheme`.
- Screen-reader labels, values ("Loading", "Succeeded") and announcements; 44×44 minimum tap
  targets; keyboard activation and focus ring.
- Reduce Motion aware: no press scale, no shake or bounce, cart buttons crossfade, flights land
  instantly.
- RTL correct: icon placement, slots, alignment and choreographies all mirror.

## Install

```yaml
dependencies:
  kito_ui_buttons: ^0.1.0
```

```dart
import 'package:kito_ui_buttons/kito_ui_buttons.dart';
```

## Quick start

```dart
KitoButton(
  label: 'Continue',
  icon: const Icon(Icons.arrow_forward_rounded),
  iconPlacement: KitoButtonIconPlacement.trailing,
  size: KitoButtonSize.large,
  expand: true,
  onPressed: formIsValid ? () async => submit() : null, // spinner until the Future completes
)
```

Return a `Future` from `onPressed` and the button shows a spinner and ignores taps until it
completes. A `null` `onPressed` disables it.

## Variants, sizes and icons

```dart
KitoButton(label: 'Primary', onPressed: go);
KitoButton(label: 'Tonal', variant: KitoButtonVariant.tonal, onPressed: go);
KitoButton(label: 'Outlined', variant: KitoButtonVariant.outlined, onPressed: go);
KitoButton(label: 'Ghost', variant: KitoButtonVariant.ghost, onPressed: go);
KitoButton(label: 'Delete', variant: KitoButtonVariant.destructive, onPressed: go);
KitoButton(label: 'Learn more', variant: KitoButtonVariant.link, onPressed: go);

KitoButton(label: 'Small', size: KitoButtonSize.small, onPressed: go);
KitoButton(
  label: 'Custom',
  size: const KitoButtonSize.custom(height: 52, horizontalPadding: 20, iconSize: 16),
  onPressed: go,
);

KitoButton.icon(icon: const Icon(Icons.favorite_border), semanticLabel: 'Like', onPressed: like);
```

## Phases: loading → tick / shake

```dart
KitoButton(
  label: 'Add to cart',
  icon: const Icon(Icons.add_shopping_cart_rounded),
  showSuccess: true,        // morph to a tick
  showFailure: true,        // shake with a cross when it throws
  successLabel: 'Added',
  onError: (error, _) => log(error),
  onPressed: () => cart.add(product),
)
```

Drive the phase yourself with a controller:

```dart
final pay = KitoButtonController();
KitoButton(label: 'Pay', controller: pay, onPressed: startPayment);
// later, when the webhook arrives
pay.value = KitoButtonPhase.success;
```

## Slots and layout

```dart
KitoButton(
  label: 'Pay',
  subtitle: 'M-Pesa',
  leading: const Icon(Icons.phone_android),
  trailing: const Text('KES 1,500'),
  contentAlignment: KitoButtonContentAlignment.spaceBetween,
  expand: true,
  semanticHint: 'Double tap to pay',
  onPressed: pay,
)

KitoButton.custom(child: Row(children: [...]), semanticLabel: 'Share', onPressed: share);
```

Per-button overrides: `tint`, `shape`, `minWidth`, `padding`, `disabledStyle`
(`faded` / `outlined` / `.filled(background:, foreground:)`) and `pressedStyle`
(`scale` / `darken` / `none`).

## Add-to-cart animations

| Animation | What happens |
| --- | --- |
| `rollingCart` | The label slides away, a cart rolls in, the product drops in, the cart rolls off, "Added ✓" |
| `dropIn` | The product falls into the cart, which squashes and bounces; a dot badge pops |
| `morphCircle` | The button squeezes into a spinning circle, a tick draws with a burst, then it expands back |
| `burst` | The plus spins into a tick while particles fly outward |
| `flip` | The button flips over to reveal the added state |
| `fillSweep` | The success colour sweeps across and a tick draws itself |
| `bounceCart` | The cart jumps, a plus falls in, the cart wiggles and a "1" badge pops |

```dart
KitoAddToCartButton(
  animation: KitoAddToCartAnimation.rollingCart,
  addedLabel: 'Added',
  expand: true,
  duration: const Duration(milliseconds: 1600),
  hold: const Duration(seconds: 1),
  onPressed: () => cart.add(product),        // throwing = shake and reset
  onAdded: () => setState(() => count++),     // fires at the landing moment
  flight: KitoFlightRequest(to: 'cart', builder: (_) => Image.asset(product.image)),
)
```

The timeline is time-based, so it plays the same however long your call takes.
`KitoAddToCartChoreography` draws any frame (handy for galleries), and the building blocks are
public: `KitoButtonCheckmark`, `KitoButtonBurst`, `KitoButtonSpinner`, `KitoButtonEase`.

## Fly to cart

```dart
final flights = KitoFlightController();

KitoFlightLayer(
  controller: flights,
  child: Scaffold(
    appBar: AppBar(actions: [
      KitoBadgeButton(
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag,
        count: cart.count,
        semanticLabel: 'Shopping cart',
        flightAnchor: 'cart',             // target; bounces when something lands
        onPressed: openCart,
      ),
    ]),
    body: productGrid,
  ),
);

// Any widget can be a source or target:
KitoFlightAnchor(id: 'product-1', child: image);
flights.fly(from: 'product-1', to: 'cart', builder: (_) => image);
```

Frames are measured from the layer's physical top-left, so flights land correctly in RTL.

## Theme

`KitoButtonTheme` colours default to your `KitoTheme` (primary, danger, success). Install it
app-wide as a theme extension, or for one subtree:

```dart
KitoButtonThemeScope(
  theme: const KitoButtonTheme(
    shape: KitoButtonShape.rounded,
    textStyle: TextStyle(fontFamily: 'Inter'),
    motion: KitoButtonMotion.lively,
    pressedStyle: KitoButtonPressedStyle.darken,
  ),
  child: checkout,
)
```

Want the look on a plain Material button?

```dart
FilledButton(
  style: KitoButtonStyles.material(context, variant: KitoButtonVariant.outlined),
  onPressed: save,
  child: const Text('Save'),
)
```

Helpers: `KitoButtonBounce(trigger:)` pops any widget when a value changes, `KitoButtonShake(trigger:)`
shakes it.

## Localisation

Default cart titles and screen-reader values ship in English, Swahili and French and follow the
app's locale. Override or add languages:

```dart
KitoButtonStrings.provider = (key, locale) => myStrings.lookup('kito.$key', locale);
```

## License

MIT — see [LICENSE](LICENSE).
