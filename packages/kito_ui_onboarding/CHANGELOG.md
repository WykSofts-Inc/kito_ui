## 0.1.1

- `onPageChanged` reports each page once. A jump across several pages (`goTo(2)` from the
  first page) used to report the pages it passed through as well (2, 1, 2); it now reports
  only where it lands, and the controller's page no longer flickers during the jump.
- The text rise-in uses a timer cancelled on dispose, so removing a page mid rise-in leaves no
  pending timer behind.

## 0.1.0

- First release: `KitoOnboarding` with six layouts (centered, hero top, full bleed, card,
  text first, split), five indicators, six swipe-tracking transitions, four button placements
  including a progress ring, ambient artwork motion, skip / back / next / get started,
  permission-style steps, per-page colours that blend as you swipe, and
  `KitoOnboardingController`.
