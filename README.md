# Kito UI for Flutter

Polished, animated Flutter widgets for real apps — buttons, fields, toasts, modals, charts,
navigation, onboarding, chat, commerce and more. The Flutter edition of the Kito SwiftUI kits.

## Install everything

```yaml
dependencies:
  kito_ui: ^0.1.0
```

```dart
import 'package:kito_ui/kito_ui.dart';
```

## Or just the kits you need

```yaml
dependencies:
  kito_ui_charts: ^0.1.0
  kito_ui_toasts: ^0.1.0
```

Unused kits cost nothing: install only what you use, or install `kito_ui` and let Flutter's tree
shaking drop what you don't call.

Kits that need native plugins (camera, maps, scanner, media player, in-app purchase, biometrics,
notifications, home-screen widgets…) are **not** part of `kito_ui`, so your app never inherits
permissions it doesn't need. Add them individually; each README lists its platform setup.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full list of kits and the conventions they follow.

## Developing

```sh
dart pub global activate melos
flutter pub get          # resolves the whole workspace
melos run analyze
melos run test
```

## License

MIT — see [LICENSE](LICENSE).
