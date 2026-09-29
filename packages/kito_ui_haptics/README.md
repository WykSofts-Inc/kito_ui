# kito_ui_haptics

Semantic haptic feedback for Flutter — call what you mean (`success`, `warning`, `error`), not
a platform feedback type. Plus timed haptic patterns with nine presets, and a visualizer that
draws a pattern so it reads even where it can't be felt. The Flutter edition of KitoHaptics.

Pure Flutter: it plays through `HapticFeedback`, so there's no plugin and no platform setup.

## Install

```yaml
dependencies:
  kito_ui_haptics: ^0.1.0
```

```dart
import 'package:kito_ui_haptics/kito_ui_haptics.dart';
```

## Semantic haptics

```dart
onPressed: () {
  save();
  KitoHaptics.success();
}

KitoHaptics.warning();                       // before a destructive action
KitoHaptics.error();                         // something failed
KitoHaptics.selection();                     // a picker moved
KitoHaptics.impact(KitoHapticImpactStyle.light);
```

Respect a user setting — every call checks it:

```dart
SwitchListTile(
  title: const Text('Haptic feedback'),
  value: KitoHaptics.isEnabled,
  onChanged: (on) => setState(() => KitoHaptics.isEnabled = on),
)
```

React to state instead of taps:

```dart
KitoHapticOnChange(
  value: form.hasError,
  when: (before, now) => now,            // only when an error appears
  haptic: KitoHaptics.error,
  child: form,
)
```

## Patterns

```dart
KitoHaptics.play(KitoHapticPattern.heartbeat);
KitoHaptics.play(KitoHapticPattern.successChime);
KitoHaptics.play(KitoHapticPattern.ticksOf(12, const Duration(milliseconds: 50)));
KitoHaptics.play(KitoHapticPattern.rumble.scaled(0.6));
KitoHaptics.stop();

final drumroll = KitoHapticPattern('Drumroll', [
  KitoHapticEvent.tap(Duration.zero, intensity: 0.6, sharpness: 0.8),
  KitoHapticEvent.tap(const Duration(milliseconds: 80), intensity: 0.7, sharpness: 0.8),
  KitoHapticEvent.hold(const Duration(milliseconds: 160),
      duration: const Duration(milliseconds: 500), intensity: 0.2, endIntensity: 1),
]);
await KitoHaptics.play(drumroll.repeated(2));

KitoHapticOnChange(
  value: order.isDelivered,
  pattern: KitoHapticPattern.successChime,
  child: OrderStatus(order),
)
```

Presets: `heartbeat`, `successChime`, `ticks`, `rumble`, `knock`, `rampUp`, `rampDown`,
`failure`, `nudge` (all in `KitoHapticPattern.presets`).

Flutter's haptics have no intensity control, so a pattern plays as a timed sequence of
platform taps (`pattern.impacts()`): strength picks light, medium or heavy, very crisp light
events become selection ticks, and buzzes become a tap every 60 ms.

## Visualizer

Height is intensity, colour is sharpness (warm for a thud, cool for a click). Set `playedAt`
when you play the pattern and a playhead sweeps across, lighting each beat.

```dart
DateTime? playedAt;

KitoHapticVisualizer(
  KitoHapticPattern.heartbeat,
  playedAt: playedAt,
  style: KitoHapticVisualizerStyle.waveform,
  height: 90,
);

FilledButton(
  onPressed: () {
    KitoHaptics.play(KitoHapticPattern.heartbeat);
    setState(() => playedAt = DateTime.now());
  },
  child: const Text('Play'),
);
```

Time runs from the start edge, so it mirrors in right-to-left layouts. Screen readers hear
"Heartbeat haptic pattern, 4 beats over 1.0 seconds".

## Platform notes

- **iOS:** taps use `UIImpactFeedbackGenerator` (iPhone 7 and later); nothing plays on iPads
  or the simulator.
- **Android:** taps use the view's haptic feedback, which follows the system "Touch feedback"
  setting. No permission is needed.
- In widget tests, a pattern schedules timers: pump past its duration or call
  `KitoHaptics.stop()` in `tearDown`.

## License

MIT — see [LICENSE](LICENSE).
