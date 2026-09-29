# kito_ui_modals

Modals with polish for Flutter: a custom bottom sheet with detents and rubber-banding, alerts
that pop in (with confetti when there's something to celebrate), action menus, tooltips, hero
cards that expand into a story, blocking status dialogs and slide-to-confirm. Part of
[Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything follows `KitoTheme`, light and
dark, right-to-left layouts and Reduce Motion.

## Install

```yaml
dependencies:
  kito_ui_modals: ^0.1.0
```

```dart
import 'package:kito_ui_modals/kito_ui_modals.dart';
```

## Quick start

```dart
showKitoSheet<void>(
  context: context,
  builder: (context) => const FiltersForm(),
);
```

The sheet sizes itself to its content, drags down (or taps outside, or Escape) to close, and
springs with the finger's velocity.

## Bottom sheets

```dart
final colour = await showKitoSheet<Color>(
  context: context,
  configuration: const KitoSheetConfiguration(
    detents: [KitoSheetDetent.fit, KitoSheetDetent.fraction(0.6), KitoSheetDetent.large],
    style: KitoSheetStyle.floating,      // .attached, .glass
    blursBackdrop: true,
  ),
  builder: (context) => ColourGrid(
    onPicked: (c) => KitoSheetController.of(context).dismiss(c),
  ),
);
```

Drag between detents; past the tallest one the sheet rubber-bands. `KitoSheetController.of`
also has `snapTo(index)` and the current `detentIndex`.

**Long, scrolling content.** Return a scroll view — it picks up the sheet's scroll controller by
itself. The sheet drags from the grabber and header, when the list is pulled down at its top,
and when it's pushed up while the sheet isn't at its tallest:

```dart
showKitoSheet<void>(
  context: context,
  configuration: const KitoSheetConfiguration.scrollable(
    detents: [KitoSheetDetent.fraction(0.5), KitoSheetDetent.large],
  ),
  headerBuilder: (context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Comments'),
  ),
  builder: (context) => ListView.builder(
    itemCount: comments.length,
    itemBuilder: (context, i) => CommentTile(comments[i]),
  ),
);
```

## Alerts and confirmations

```dart
await showKitoAlert(context, KitoAlert(
  icon: Icons.delete_rounded,
  title: 'Delete account?',
  message: "This can't be undone.",
  actions: [
    const KitoAlertAction.cancel(),
    KitoAlertAction('Delete', role: KitoAlertRole.destructive, onPressed: deleteAccount),
  ],
));

showKitoAlert(context, const KitoAlert(
  icon: Icons.celebration_rounded,
  title: 'Order placed!',
  celebrates: true,                      // confetti (not with Reduce Motion)
));

if (await showKitoConfirmation(context,
    title: 'Sign out?', confirmTitle: 'Sign out', isDestructive: true)) {
  signOut();
}
```

Two short actions sit side by side (cancel first); otherwise they stack (cancel last). A tap
outside or Escape picks the cancel action when there is one.

## Action menus

```dart
showKitoActionMenu(context, title: 'Profile photo', actions: [
  KitoMenuAction('Take photo', icon: Icons.photo_camera_rounded, onPressed: takePhoto),
  KitoMenuAction('Choose from library', icon: Icons.photo_library_rounded, onPressed: pick),
  KitoMenuAction('Remove photo', icon: Icons.delete_rounded, isDestructive: true,
      onPressed: removePhoto),
]);
```

## Tooltips

```dart
KitoModalTooltip(
  visible: showTip,
  message: 'Create your first list',
  icon: Icons.auto_awesome_rounded,
  edge: KitoModalTooltipEdge.top,        // or .bottom
  onDismiss: () => setState(() => showTip = false),
  child: addButton,
)
```

The bubble floats in the overlay, so it never pushes your layout around.

## Status dialogs

```dart
final status = showKitoStatusDialog(context,
    state: const KitoStatusDialogState.pending('Processing payment…'));
try {
  await api.charge();
  status.update(const KitoStatusDialogState.success('Payment complete'));
} catch (_) {
  status.update(const KitoStatusDialogState.failure('Payment failed'));
}

// Or in one line:
await runWithKitoStatusDialog(context, api.charge,
    pendingMessage: 'Paying…', successMessage: 'Paid', failureMessage: 'Declined');
```

The tick and cross draw themselves in; success and failure close by themselves after
`autoDismissAfter` (1.6 s by default, null to keep them up).

## Slide to confirm

```dart
KitoSlideToConfirm(
  title: 'Slide to pay',
  icon: Icons.credit_card_rounded,
  tint: Colors.green,
  resetKey: attempt,                     // change it to start over
  onConfirm: () => checkout.pay(),       // throw to fail: cross, "Try again", slide back
)
```

Screen readers confirm with a double tap, keyboards with Enter or Space.

## Hero cards

```dart
ListView(children: [
  for (final story in stories)
    KitoModalHeroCard(
      tag: story.id,
      collapsed: (context) => StoryFace(story),   // fills the box it's given
      expanded: (context) => StoryBody(story),
    ),
]);
```

Tapping a card flies its face up into the story's header, App Store Today style.

## Accessibility and right-to-left

- Sheets, alerts and the hero story announce themselves as routes; the sheet backdrop is a
  "Dismiss" button, and the accessibility dismiss action closes them.
- Reduce Motion swaps slides, springs and the hero flight for fades, and turns off confetti and
  shimmer.
- `KitoSlideToConfirm` slides toward the end edge (right to left in Arabic or Hebrew) and the
  knob follows the finger there; the default chevron mirrors. Menu rows and dividers mirror
  too. The status dialog's tick stays unmirrored, like the system checkmark.

## License

MIT — see [LICENSE](LICENSE).
