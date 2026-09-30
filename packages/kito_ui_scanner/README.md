# kito_ui_scanner

QR and barcode scanning for Flutter on [mobile_scanner](https://pub.dev/packages/mobile_scanner):
an animated viewfinder with breathing corners or a sweeping laser, torch and camera-switch
controls, a result card that knows what the code means (a link, Wi-Fi, a contact, an M-Pesa
till, a product) and offers the right actions, and a pure parser you can use on its own.
Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui); follows `KitoTheme`,
right-to-left layouts and Reduce Motion.

> **Opt-in native kit.** `kito_ui_scanner` is *not* part of the `kito_ui` umbrella, so apps
> that don't scan never inherit camera code or a camera permission. Add it on its own.

## Install

```yaml
dependencies:
  kito_ui_scanner: ^0.1.0
```

```dart
import 'package:kito_ui_scanner/kito_ui_scanner.dart';
```

mobile_scanner 7 needs Dart 3.7 / Flutter 3.29 or later.

## Platform setup

- **iOS** — `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Scan QR codes and barcodes.</string>
  ```
- **macOS** — the same `NSCameraUsageDescription` in `macos/Runner/Info.plist`, and
  `com.apple.security.device.camera` = `true` in both `DebugProfile.entitlements` and
  `Release.entitlements`.
- **Android** — `<uses-permission android:name="android.permission.CAMERA"/>` in
  `android/app/src/main/AndroidManifest.xml`; minSdk 21 or later.
- **Web** — served over HTTPS (or localhost); the browser asks for the camera.

## Scan

```dart
KitoScannerView(
  hint: 'Scan the QR code on the till',
  style: KitoScanOverlayStyle.laser,     // corners, laser, frame, minimal
  onDetect: (code) => KitoScanResultSheet.show(
    context,
    code,
    onAction: (action) => switch (action.kind) {
      KitoScanActionKind.open => launchUrl(Uri.parse(action.value)),
      KitoScanActionKind.pay => startMpesa(action.value),
      _ => null,
    },
  ),
  onClose: () => Navigator.pop(context),
)
```

Each code is reported once (the same code is ignored for `repeatDelay`), the viewfinder
snaps in and turns green, and only codes inside the window are read. Pass
`formats: [BarcodeFormat.qrCode]` to scan faster, `aspectRatio: 1.8` for a barcode-shaped
window, `pausesOnDetect: true` to stop after one, or your own `MobileScannerController`.
When the camera isn't allowed the view explains how to turn it on.

## The viewfinder on its own

`KitoScanOverlay` draws over any child, so you can use it for custom camera setups, for
screenshots, or over a placeholder in a design gallery:

```dart
KitoScanOverlay(
  style: KitoScanOverlayStyle.corners,
  locked: found,                     // snaps in and turns green
  hint: 'Hold steady',
  child: Image.asset('assets/counter.jpg', fit: BoxFit.cover),
)

KitoScanWindow.rect(size, aspectRatio: 1);   // the same rectangle the scanner reads
```

## Results

```dart
KitoScanResultCard(code: code, onAction: handle, onScanAgain: controller.start);
KitoScanAction.forCode(code);   // e.g. [Open link, Copy] or [Join network, Copy]
```

| Code | Card shows | Actions |
|---|---|---|
| `https://…`, `www.…` | host and address | Open link |
| `WIFI:S:…;T:WPA;P:…;;` | network, security, password (tap to reveal) | Join network, copy password |
| `MECARD:` / vCard | name, company, phones, emails, address | Add contact, Call |
| `tel:`, `mailto:`, `SMSTO:` | number / address / message | Call, Text, Write email |
| `geo:lat,lng?q=` | place and coordinates | Directions |
| `kitopay://till?number=…&amount=…&name=…` | M-Pesa till, paybill or phone, amount | Pay KES 1,500 |
| EAN-13, EAN-8, UPC | digits, check-digit validity, GS1 origin (616 is Kenya) | Look it up |

The card only reports actions; opening links, joining networks or starting payments is up to
your app (for example with url_launcher). Copy is done for you.

## Parsing without a camera

```dart
final payload = KitoScanParser.parse('WIFI:T:WPA;S:Java Guest;P:karibu2026;;');
if (payload case KitoScanWifi(:final ssid, :final password)) { ... }

KitoScanCheckDigits.isValidGtin('6161001234567');   // true
KitoScanCheckDigits.isValidLuhn('4242 4242 4242 4242');
```

## Testing

`KitoScannerView` opens the camera, so don't build it in widget tests. Build your screen's
overlay, result card and control bar instead — they're plain widgets.

## License

MIT — see [LICENSE](LICENSE).
