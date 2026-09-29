## 0.1.1

- The alert card's badge pop-in and the status view's tick/cross draw-in now use timers
  cancelled on dispose, so removing them mid-animation leaves no pending timer (widget tests
  no longer fail with "A Timer is still pending").
- `showKitoActionMenu` and `runWithKitoStatusDialog` take `useRootNavigator` (default true,
  unchanged), so they can open inside a nested navigator like `showKitoSheet` and
  `showKitoStatusDialog`.

## 0.1.0

- First release: `showKitoSheet` (detents, rubber-banding, attached/floating/glass styles,
  fitted or scrollable content that drags from the header or at the scroll top),
  `showKitoAlert` with roles and confetti, `showKitoConfirmation`, `showKitoActionMenu`,
  `KitoModalTooltip`, `KitoModalHeroCard`, `showKitoStatusDialog` /
  `runWithKitoStatusDialog`, and `KitoSlideToConfirm` with async work, failure and reset.
