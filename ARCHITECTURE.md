# Kito UI for Flutter — architecture and conventions

Kito UI is the Flutter edition of the Kito SwiftUI kits. It is one repository (a pub workspace
managed with melos) holding many small packages:

- **`kito_ui`** — the umbrella. Depends on every pure-Dart kit and re-exports them, so
  `import 'package:kito_ui/kito_ui.dart';` gives you everything.
- **`kito_ui_<kit>`** — each kit on its own (`kito_ui_charts`, `kito_ui_buttons`, …) for apps that
  only want a few. Installing a kit pulls in `kito_ui_core` and nothing else it doesn't need.
- **Native kits are opt-in.** Kits that need platform plugins (camera, maps SDKs, in-app purchase,
  biometrics, notifications…) are *not* in the umbrella, so apps never inherit native code,
  permissions or Info.plist/AndroidManifest requirements they didn't ask for. Their READMEs list
  the platform setup.

```
packages/
  kito_ui/                 umbrella (pure-Dart kits only)
  kito_ui_core/            theme tokens, KitoTheme, gradients, backgrounds, glass, motion
  kito_ui_<kit>/           one folder per kit
apps/
  kito_devkit/             the showcase app (galleries + demo apps)
```

## Kits

Pure Dart / Flutter SDK only — **in the umbrella**:

| Package | Swift counterpart |
|---|---|
| `kito_ui_core` | KitoCore |
| `kito_ui_buttons` | KitoButtons |
| `kito_ui_fields` | KitoFields |
| `kito_ui_validation` | KitoValidation |
| `kito_ui_formatting` | KitoFormatting |
| `kito_ui_loaders` | KitoLoaders |
| `kito_ui_toasts` | KitoToasts |
| `kito_ui_modals` | KitoModals |
| `kito_ui_empty_states` | KitoEmptyStates |
| `kito_ui_haptics` | KitoHaptics (Flutter's `HapticFeedback`) |
| `kito_ui_navigation` | KitoNavigation (tab bars, side menus, top tabs, router helpers) |
| `kito_ui_onboarding` | KitoOnboarding |
| `kito_ui_tour` | KitoTour |
| `kito_ui_charts` | KitoCharts (2D + faux-3D) |
| `kito_ui_calendar` | KitoCalendar |
| `kito_ui_carousel` | KitoCarousel (carousels, stories, swipe deck) |
| `kito_ui_reviews` | KitoReviews |
| `kito_ui_search` | KitoSearch |
| `kito_ui_chat` | KitoChat (UI; voice recording is an optional adapter) |
| `kito_ui_ai_chat` | KitoAIChat |
| `kito_ui_feed` | KitoFeed |
| `kito_ui_cart` | KitoCart |
| `kito_ui_product` | KitoProduct |
| `kito_ui_checkout` | KitoCheckout |
| `kito_ui_order_tracking` | KitoOrderTracking (UI; live activities are native, not included) |
| `kito_ui_wallet_cards` | KitoWalletCards |
| `kito_ui_island` | KitoIslandBar (in-app Dynamic Island–style bar) |
| `kito_ui_settings` | KitoSettings + Control Center modules |
| `kito_ui_signature` | KitoSignature |
| `kito_ui_photo_editor` | KitoPhotoEditor (filters/crop/text on images, pure Dart) |

Native plugins — **opt-in, not in the umbrella**:

| Package | Plugin(s) |
|---|---|
| `kito_ui_permissions` | permission_handler |
| `kito_ui_biometrics` | local_auth |
| `kito_ui_secure_storage` | flutter_secure_storage (KitoKeychain) |
| `kito_ui_connectivity` | connectivity_plus |
| `kito_ui_image_loader` | cached_network_image |
| `kito_ui_media_picker` | image_picker, file_picker |
| `kito_ui_camera` | camera (capture screen for the photo editor) |
| `kito_ui_media_player` | video_player, just_audio |
| `kito_ui_maps` | flutter_map (OpenStreetMap / MapLibre-style tiles, no key) |
| `kito_ui_maps_google` | google_maps_flutter |
| `kito_ui_scanner` | mobile_scanner |
| `kito_ui_file_viewer` | pdfx, open_filex |
| `kito_ui_paywall` | in_app_purchase |
| `kito_ui_auth` | sign_in_with_apple, local_auth (screens themselves are pure) |
| `kito_ui_notifications` | flutter_local_notifications |
| `kito_ui_home_widgets` | home_widget |

## Conventions (every package follows these)

- **Layout:** `lib/kito_ui_<kit>.dart` exports the public API; implementation in `lib/src/`.
  Tests in `test/`. Each package has `README.md` (install, quick start, samples, platform setup
  for native kits), `CHANGELOG.md`, `LICENSE` (MIT, wyksoftsinc.com), `analysis_options.yaml`
  including the repo's lint rules, and an `example/` only if it adds something the DevKit doesn't.
- **pubspec:** `name`, `description` (60–180 chars, pub.dev scoring), `version` (start `0.1.0`),
  `homepage`/`repository: https://github.com/WykSofts-Inc/kito_ui`, `issue_tracker`,
  `topics` (≤5), `environment: sdk: ^3.6.0, flutter: ">=3.27.0"`, `resolution: workspace`.
  Depend on siblings with plain version constraints (the workspace resolves them locally).
- **Theming:** everything reads `KitoTheme.of(context)` from `kito_ui_core` — colours, spacing,
  radii, typography, motion — which is a `ThemeExtension` so it also works with `Theme.of`.
  Widgets take an optional `tint` that overrides the primary colour. Light and dark both work.
- **Naming:** public types start with `Kito` (`KitoButton`, `KitoToastHost`). A name must be
  unique across *all* kits so the umbrella can export everything without clashes; kit-specific
  names get the kit in them (`KitoChatTypingIndicator`, not `KitoTypingIndicator`). The
  umbrella's CI job compiles an import of every kit together to catch clashes.
- **Accessibility:** `Semantics` labels/values/actions on custom controls, text scales with the
  system, 44×44 minimum tap targets, respects `MediaQuery.disableAnimations` (reduce motion) and
  `MediaQuery.boldText`. RTL correct from the start: use `EdgeInsetsDirectional`,
  `AlignmentDirectional`, `start`/`end`, and flip directional icons and drag maths by
  `Directionality.of(context)`.
- **Quality:** `dart format`, `flutter analyze` with zero issues, widget + unit tests for logic,
  golden tests where they add value. No `print`. Public API documented with `///`.
- **Design bar:** match the SwiftUI kits — polished, animated (implicit animations, `AnimatedSwitcher`,
  `Hero`, spring curves), never flat.
- **Attribution:** authored by Wycliff Njenga / wyksoftsinc.com. No AI attribution anywhere.
