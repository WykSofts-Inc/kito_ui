# kito_ui_toasts

Toasts that feel native and look finished: card, pill, banner, glass and island layouts; a stack
that fans out when tapped; loading toasts that turn into success or error; progress bars that fill
in place; undo toasts with a countdown ring; avatars, actions, haptics and swipe to dismiss. They
draw in their own overlay layer above the navigator, so they stay visible over pushed pages,
dialogs and bottom sheets.

## Install

```yaml
dependencies:
  kito_ui_toasts: ^0.1.0
```

## Quick start

Create one center, host it in `MaterialApp.builder`, and show toasts from anywhere:

```dart
final toasts = KitoToastCenter();

MaterialApp(
  theme: KitoTheme.light.toThemeData(),
  builder: (context, child) => KitoToastHost(center: toasts, child: child!),
  home: const HomePage(),
);

toasts.success('Saved');
toasts.error('Couldn't reach the server', title: 'Offline');
```

No center to pass around? Leave it out and use `context.kitoToasts.success('Saved')` from any
widget below the host.

## Layouts

```dart
toasts.show(KitoToast(message: 'Copied', layout: KitoToastLayout.pill));
toasts.show(KitoToast(message: 'You're back online', style: KitoToastStyle.success,
    layout: KitoToastLayout.banner));
toasts.show(KitoToast(title: 'AirPods', message: 'Connected', layout: KitoToastLayout.island));
toasts.show(KitoToast(
  title: 'Amina Otieno',
  message: 'Sent you a voice note',
  layout: KitoToastLayout.glass,
  avatar: const KitoToastAvatar(initials: 'AO'),
  actions: [KitoToastAction(label: 'Play', onPressed: play)],
));
```

## Promise, progress and undo

```dart
// Spinner while it runs, then success or error — same toast, no flicker.
await toasts.promise(api.save(draft),
    loading: 'Saving…', success: (_) => 'Saved', error: (e) => 'Save failed');

// A bar that fills in place.
final id = toasts.show(KitoToast(title: 'Uploading', message: 'photo.jpg', progress: 0));
upload.onProgress((p) => toasts.updateProgress(id, p));
toasts.complete(id, style: KitoToastStyle.success, message: 'Uploaded');

// Undo with a ring counting down; commit when it runs out or is swiped away.
toasts.undo('Conversation archived',
    onUndo: () => restore(chat), onExpire: () => api.archive(chat));
```

## Stacks

```dart
final toasts = KitoToastCenter(presentation: KitoToastPresentation.stacked);
```

New toasts land on top and older ones peek out behind. Tap the stack to fan it out (timers pause
while it's open), tap again or outside to fold it. Screen readers get a "Show all notifications"
action. Hovering with a mouse, or holding a toast, also pauses it.

## Appearance

```dart
KitoToastHost(
  center: toasts,
  appearance: const KitoToastAppearance(
    radius: 20,
    showsAccentBar: false,
    maxWidth: 420,
    background: KitoBackground.gradient(KitoGradient.midnight),
    playsHaptics: true,
  ),
  child: child!,
);
```

Colours follow `KitoTheme` (success, danger, warning, primary); give any toast a `tint` or its own
`background`. Put `KitoToastCenter(position: KitoToastPosition.bottom)` for bottom toasts.

## Accessibility

Each toast is a live region read as "title. message", with a dismiss action. Action buttons have
44-point targets and their own labels. With Reduce Motion on, toasts fade instead of sliding and
springing. Layouts use start/end, so the accent bar and icon mirror in right-to-left languages.

## License

MIT — see [LICENSE](LICENSE).
