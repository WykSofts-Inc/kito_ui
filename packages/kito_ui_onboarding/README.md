# kito_ui_onboarding

A paged onboarding flow for Flutter: photo, gradient, solid, card, split and illustrated pages,
animated indicators, transitions that track the finger, skip / back / next / get started, and
permission-style steps. Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything
follows `KitoTheme`, light and dark, right-to-left layouts and Reduce Motion.

## Install

```yaml
dependencies:
  kito_ui_onboarding: ^0.1.0
```

```dart
import 'package:kito_ui_onboarding/kito_ui_onboarding.dart';
```

## Quick start

```dart
KitoOnboarding(
  pages: const [
    KitoOnboardingPage(
      artwork: KitoOnboardingArtwork.icon(Icons.bolt_rounded),
      title: 'Fast',
      message: 'Everything loads instantly.',
    ),
    KitoOnboardingPage(
      artwork: KitoOnboardingArtwork.icon(Icons.lock_rounded),
      title: 'Secure',
      message: 'Your data stays yours.',
    ),
    KitoOnboardingPage(
      artwork: KitoOnboardingArtwork.icon(Icons.verified_rounded),
      title: 'Simple',
      message: 'No clutter, just what you need.',
    ),
  ],
  onFinish: () => prefs.setBool('seenOnboarding', true),
);
```

## Pages

Each page can carry an `eyebrow`, `bullets`, a `background`, and its own `foreground`,
`accent` and `onAccent`. Skip, Back, the indicator and the button blend into the next page's
colours as you swipe.

| Look | How |
|---|---|
| Photo | `background: KitoBackground.image(AssetImage('assets/beach.jpg'))` with `layout: fullBleed` |
| Gradient | `background: KitoBackground.gradient(KitoGradient.sunset)` |
| Solid | `background: KitoBackground.color(Color(0xFF0E7C66))` |
| Illustration | `artwork: KitoOnboardingArtwork.custom((context) => MyIllustration())` |
| Image | `artwork: KitoOnboardingArtwork.image(NetworkImage(url))` |

```dart
const KitoOnboardingPage(
  artwork: KitoOnboardingArtwork.none,
  eyebrow: 'Discover',
  title: 'See the world',
  message: 'Guides from locals, everywhere you go.',
  background: KitoBackground.image(AssetImage('assets/city.jpg'), overlay: Color(0x33000000)),
  accent: Colors.white,
  onAccent: Colors.black,
);
```

## Style

```dart
KitoOnboarding(
  pages: pages,
  onFinish: finish,
  style: const KitoOnboardingStyle(
    layout: KitoOnboardingLayout.split,                // centered, heroTop, fullBleed, card, textFirst
    pageTransition: KitoOnboardingPageTransition.cube, // slide, fade, scaleFade, parallax, zoom
    indicator: KitoOnboardingIndicator.progressBar,    // capsules, dots, numbered, none
    buttonPlacement: KitoOnboardingButtonPlacement.progressRing,
    artworkMotion: KitoOnboardingArtworkMotion.float,  // bounce, pulse
    labels: KitoOnboardingLabels(next: 'Continue', getStarted: "Let's go"),
    showsBackButton: true,
  ),
);
```

Every placement ends on a full-width "Get started". The progress ring fills as you go and
stretches into it on the last page.

## Permission steps

```dart
KitoOnboardingPage(
  artwork: const KitoOnboardingArtwork.icon(Icons.notifications_rounded),
  title: 'Stay in the loop',
  message: 'We only notify you about your orders.',
  permission: KitoOnboardingPermission(
    allowTitle: 'Allow notifications',
    onRequest: () => notifications.requestPermission(),   // Future<bool>
  ),
);
```

The primary button asks (with a spinner while it waits), "Not now" moves on without asking,
and either way the flow continues. `onPermissionResult` reports each answer. The kit doesn't
touch platform permissions itself — plug in whatever you use (for example
`kito_ui_permissions`).

## Driving it from code

```dart
final onboarding = KitoOnboardingController();

KitoOnboarding(
  pages: pages,
  controller: onboarding,
  onFinish: () => analytics.log('onboarding_completed'),
  onSkip: () => analytics.log('onboarding_skipped'),
  onPageChanged: (page) => analytics.log('onboarding_page_$page'),
);

onboarding.next();      // or back(), goTo(2), skip()
```

## Accessibility and right-to-left

- The indicator is read as "Page 2 of 4" and announces changes; titles are headings; artwork
  is hidden from screen readers. Buttons are 44pt+ and work with the keyboard, and the arrow
  keys move between pages.
- In Arabic or Hebrew the next page comes in from the left; swipes, parallax, the cube turn,
  the back chevron and the next arrows all mirror.
- Reduce Motion swaps cube, zoom and parallax for a fade, shows text without the rise-in, and
  turns off ambient artwork motion.

## License

MIT — see [LICENSE](LICENSE).
