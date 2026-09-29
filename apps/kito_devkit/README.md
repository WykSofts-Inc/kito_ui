# Kito UI DevKit

The showcase app for Kito UI: every Flutter kit, live, with the code behind each sample.

- **Home:** greeting, Featured carousel, New and Jump back in strips, category chips over a grid
  of kits, a Coming soon roadmap, and search across every sample.
- **Galleries:** each kit's samples in sections; tap one for a live preview and its code with a
  Copy button.
- **Settings:** Light, Dark, Neon or System theme, and a layout-direction switch to check every
  kit right to left.

## Run it

```sh
cd apps/kito_devkit
flutter run -d macos     # or -d chrome, or pick an iPhone/Android device
```

## Adding a kit's gallery

1. Add the kit package to `pubspec.yaml` (`kito_ui_<kit>: ^0.1.0`).
2. Create `lib/kits/<kit>_gallery.dart` with a `KitEntry` (sections of `KitSample`s: title,
   subtitle, code and a builder), following `core_gallery.dart`.
3. Add it to `KitCatalog.kits` in `lib/catalog/catalog.dart` and drop it from `upcoming`.

The test in `test/widget_test.dart` builds every sample left to right and right to left, so a
broken sample fails CI.
