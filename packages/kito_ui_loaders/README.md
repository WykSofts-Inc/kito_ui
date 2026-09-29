# kito_ui_loaders

Animated loaders for Flutter — the Flutter edition of KitoLoaders. Spinners, rings, dots, bars,
waves, orbits, a typing indicator, an ECG heartbeat and a shape-morphing blob; determinate
rings, bars and steps; skeletons with a shimmer sweep, redaction and ready-made templates; a
frosted loading overlay; and pull to refresh.

- Colours follow your `KitoTheme`; every loader takes a `color`.
- One screen-reader node per loader ("Loading", "42 percent", "Step 2 of 3"), in English,
  Swahili and French.
- Reduce Motion aware: spinners hold still and breathe, dots fade instead of hopping, shimmer
  breathes in place, indeterminate bars pulse.
- RTL correct: bars fill from the start edge, shimmer sweeps from the start, steps and chat
  skeletons mirror, the orbit turns the other way.

## Install

```yaml
dependencies:
  kito_ui_loaders: ^0.1.0
```

```dart
import 'package:kito_ui_loaders/kito_ui_loaders.dart';
```

## Indicators

```dart
const KitoLoaderSpinner();
const KitoLoaderGradientRing(size: 32);
const KitoLoaderDots();
const KitoLoaderPulse();
const KitoLoaderBars(barCount: 5);
const KitoLoaderWave();
const KitoLoaderRipple();
const KitoLoaderOrbit(semanticLabel: 'Syncing contacts');
const KitoLoaderTypingIndicator();                 // chat bubble with hopping dots
const KitoLoaderHeartbeat(showHeart: true, beatsPerMinute: 80);
const KitoLoaderMorph(size: 48);                   // circle → triangle → square → star…
```

Pick one from configuration with `KitoLoaderView`:

```dart
KitoLoaderView(style: const KitoLoaderStyle(kind: KitoLoaderKind.orbit, size: 36));
```

## Progress

```dart
KitoLoaderProgressRing(value: upload.fraction);            // animates, shows "42%"

KitoLoaderLinearProgress(value: 0.6, label: 'Uploading', showPercentage: true);
const KitoLoaderLinearProgress();                           // indeterminate

KitoLoaderStepProgress(steps: const ['Cart', 'Delivery', 'Pay'], current: 1);
KitoLoaderStepProgress(
  steps: const ['Placed', 'Packed', 'On the way', 'Delivered'],
  current: 2,
  stepFraction: 0.4,
  style: KitoLoaderStepStyle.segments,
);
```

## Skeletons, shimmer and redaction

```dart
KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.listRow, count: 6);
// Also: card, profile, feedPost, chat, grid, article.

const KitoLoaderSkeleton(width: 120, height: 14);
const KitoLoaderSkeleton.circle(size: 44);

KitoLoaderSkeletonSwap(loading: user == null, child: Text(user?.name ?? 'Placeholder name'));

// Redact real layout into shimmering placeholders; taps and screen readers are blocked.
KitoLoaderRedacted(loading: profile == null, child: ProfileCard(profile ?? Profile.sample));

KitoLoaderShimmer(child: myOwnPlaceholder);
```

## Loading overlay

```dart
KitoLoaderOverlay(
  isPresented: saving,
  message: 'Saving',
  detail: 'This takes a few seconds',
  progress: uploadFraction,      // optional: a determinate ring instead of a spinner
  child: form,
);
```

The screen blurs and dims, taps are blocked, and screen readers only see the card.

## Pull to refresh

```dart
KitoLoaderPullToRefresh(
  onRefresh: () => feed.reload(),
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: posts,
  ),
);
```

Works with bouncing and clamping physics. `KitoLoaderRefreshIndicator` is public if you want to
drive it yourself.

## Build your own

`KitoLoaderTimeline` rebuilds every frame with the seconds elapsed, pausing with `running: false`
or when its `TickerMode` is off:

```dart
KitoLoaderTimeline(
  builder: (context, seconds, child) => Transform.rotate(angle: seconds * pi, child: child),
  child: const Icon(Icons.sync),
);
```

Continuous loaders never settle, so in widget tests use `tester.pump(duration)` rather than
`pumpAndSettle` while one is on screen.

## Localisation

```dart
KitoLoaderStrings.provider = (key, locale) => myStrings.lookup('kito.loaders.$key', locale);
```

## License

MIT — see [LICENSE](LICENSE).
