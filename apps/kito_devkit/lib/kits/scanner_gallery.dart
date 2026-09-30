// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_scanner/kito_ui_scanner.dart';

import '../app/toasts.dart';
import '../catalog/catalog.dart';

const _wifi = r'WIFI:T:WPA;S:Java House Guest;P:karibu2026;;';
const _till =
    'kitopay://till?number=512349&amount=1450&name=Mama%20Mboga%20Greens';
const _contact =
    'MECARD:N:Wanjiru,Amina;TEL:0712345678;EMAIL:amina@kito.ke;ORG:Kito Studio;ADR:Kilimani, Nairobi;;';
const _product = '6161001234567';
const _link = 'https://kito.ke/menu?table=4';

Widget _stage(Widget child, {double height = 420}) => SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );

/// The gallery for kito_ui_scanner.
final scannerKit = KitEntry(
  title: 'Scanner',
  package: 'kito_ui_scanner',
  blurb: 'animated viewfinders, torch controls, smart results and a QR parser',
  icon: Icons.qr_code_scanner_rounded,
  category: KitCategory.device,
  isNew: true,
  sections: [
    KitSection('Viewfinder', Icons.center_focus_strong_rounded, [
      KitSample(
        title: 'Breathing corners',
        subtitle: 'Soft brackets over any child — here a stand-in preview.',
        code: '''KitoScanOverlay(
  hint: 'Point at the QR code on the till',
  child: cameraPreview,
)''',
        builder: (_) => _stage(const KitoScanOverlay(
          hint: 'Point at the QR code on the till',
          child: _FakePreview(),
        )),
      ),
      KitSample(
        title: 'Laser sweep',
        subtitle: 'Tap Found to lock on: the brackets snap in and turn green.',
        code: '''KitoScanOverlay(
  style: KitoScanOverlayStyle.laser,
  locked: found,
  child: cameraPreview,
)''',
        builder: (_) => const _Lock(style: KitoScanOverlayStyle.laser),
      ),
      KitSample(
        title: 'Framed window',
        subtitle: 'A heavier dim with a solid outline.',
        code: '''KitoScanOverlay(
  style: KitoScanOverlayStyle.frame,
  hint: 'Scan your boarding pass',
  child: cameraPreview,
)''',
        builder: (_) => _stage(const KitoScanOverlay(
          style: KitoScanOverlayStyle.frame,
          hint: 'Scan your boarding pass',
          child: _FakePreview(),
        )),
      ),
      KitSample(
        title: 'Minimal reticle',
        subtitle: 'Nothing dimmed, just a small ring in the middle.',
        code: '''KitoScanOverlay(
  style: KitoScanOverlayStyle.minimal,
  child: cameraPreview,
)''',
        builder: (_) => const _Lock(style: KitoScanOverlayStyle.minimal),
      ),
      KitSample(
        title: 'Barcode window',
        subtitle: 'A wide window for EAN and UPC codes on packets.',
        code: '''KitoScanOverlay(
  style: KitoScanOverlayStyle.laser,
  aspectRatio: 1.8,
  hint: 'Line up the barcode',
  tint: const Color(0xFFE5484D),
  child: cameraPreview,
)''',
        builder: (_) => _stage(const KitoScanOverlay(
          style: KitoScanOverlayStyle.laser,
          aspectRatio: 1.8,
          hint: 'Line up the barcode',
          tint: Color(0xFFE5484D),
          child: _FakePreview(barcode: true),
        )),
      ),
      KitSample(
        title: 'With controls',
        subtitle: 'Torch and camera switch in a frosted pill.',
        code: '''KitoScannerControlBar(
  torchOn: torch,
  onTorch: () => controller.toggleTorch(),
  onSwitchCamera: () => controller.switchCamera(),
  onClose: () => Navigator.pop(context),
)''',
        builder: (_) => const _WithControls(),
      ),
    ]),
    KitSection('Results', Icons.fact_check_rounded, [
      KitSample(
        title: 'Wi-Fi at Java House',
        subtitle: 'Network and security; the password hides until you ask.',
        code: '''KitoScanResultCard(
  code: KitoScannedCode('WIFI:T:WPA;S:Java House Guest;P:karibu2026;;'),
  onAction: handle,
)''',
        builder: (_) => _result(_wifi),
      ),
      KitSample(
        title: 'M-Pesa till',
        subtitle: 'A Buy Goods till with the amount and merchant.',
        code: '''KitoScanResultCard(
  code: KitoScannedCode(
      'kitopay://till?number=512349&amount=1450&name=Mama%20Mboga%20Greens'),
  onAction: (a) => startMpesa(a.value),
)''',
        builder: (_) => _result(_till),
      ),
      KitSample(
        title: 'Contact card',
        subtitle: 'MECARD and vCard: phones, email, company and address.',
        code:
            '''KitoScanResultCard(code: KitoScannedCode(mecard), onAction: handle)''',
        builder: (_) => _result(_contact),
      ),
      KitSample(
        title: 'Product barcode',
        subtitle: 'EAN-13 with its check digit and GS1 origin: 616 is Kenya.',
        code: '''KitoScanResultCard(
  code: KitoScannedCode('6161001234567', format: KitoScanFormat.ean13),
)''',
        builder: (_) => _result(_product, format: KitoScanFormat.ean13),
      ),
      KitSample(
        title: 'Link with scan again',
        subtitle: 'Open the menu, copy it, or go back to the camera.',
        code: '''KitoScanResultCard(
  code: KitoScannedCode('https://kito.ke/menu?table=4'),
  onAction: handle,
  onScanAgain: controller.start,
)''',
        builder: (_) => _result(_link, again: true),
      ),
      KitSample(
        title: 'Result sheet',
        subtitle: 'The same card in a bottom sheet, as the scanner shows it.',
        code: '''KitoScanResultSheet.show(context, code, onAction: handle)''',
        builder: (_) => const _SheetButtons(),
      ),
    ]),
    KitSection('Camera', Icons.photo_camera_rounded, [
      KitSample(
        title: 'Live scanner',
        subtitle: 'Opens the camera full screen; results slide up in a sheet.',
        code: '''KitoScannerView(
  hint: 'Scan any QR code or barcode',
  onDetect: (code) => KitoScanResultSheet.show(context, code),
  onClose: () => Navigator.pop(context),
)''',
        builder: (_) => const _OpenCamera(),
      ),
      KitSample(
        title: 'Parse anything',
        subtitle: 'Type or paste what a code holds and see what it means.',
        code: '''final payload = KitoScanParser.parse(text);
switch (payload) {
  KitoScanWifi(:final ssid) => …,
  KitoScanPayment(:final number, :final amount) => …,
  _ => …,
}''',
        builder: (_) => const _Parser(),
      ),
    ]),
  ],
);

Widget _result(String raw,
        {KitoScanFormat format = KitoScanFormat.qr, bool again = false}) =>
    KitoScanResultCard(
      code: KitoScannedCode(raw, format: format),
      onAction: (a) => devKitToasts.info('${a.label}: ${a.value}'),
      onScanAgain: again ? () => devKitToasts.info('Back to the camera') : null,
    );

class _Lock extends StatefulWidget {
  const _Lock({required this.style});

  final KitoScanOverlayStyle style;

  @override
  State<_Lock> createState() => _LockState();
}

class _LockState extends State<_Lock> {
  bool _found = false;

  @override
  Widget build(BuildContext context) => Column(children: [
        _stage(KitoScanOverlay(
          style: widget.style,
          locked: _found,
          hint: _found ? 'Got it' : 'Hold steady',
          child: const _FakePreview(),
        )),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _found = !_found),
          icon: Icon(_found ? Icons.refresh_rounded : Icons.check_rounded),
          label: Text(_found ? 'Scan again' : 'Found'),
        ),
      ]);
}

class _WithControls extends StatefulWidget {
  const _WithControls();

  @override
  State<_WithControls> createState() => _WithControlsState();
}

class _WithControlsState extends State<_WithControls> {
  bool _torch = false;
  bool _front = false;

  @override
  Widget build(BuildContext context) => _stage(
        height: 480,
        Stack(fit: StackFit.expand, children: [
          KitoScanOverlay(
            style: KitoScanOverlayStyle.laser,
            hint: _front ? 'Front camera' : 'Scan a QR code',
            child: _FakePreview(bright: _torch),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: KitoScannerControlBar(
                torchOn: _torch,
                onTorch: () => setState(() => _torch = !_torch),
                onSwitchCamera: () => setState(() => _front = !_front),
                onPickImage: () => devKitToasts.info('Pick a photo to scan'),
                onClose: () => devKitToasts.info('Closed'),
              ),
            ),
          ),
        ]),
      );
}

class _SheetButtons extends StatelessWidget {
  const _SheetButtons();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final (label, raw) in const [
            ('Wi-Fi', _wifi),
            ('Till', _till),
            ('Contact', _contact),
            ('Location', 'geo:-1.2864,36.8172?q=KICC'),
          ])
            FilledButton.tonal(
              onPressed: () => KitoScanResultSheet.show(
                context,
                KitoScannedCode(raw),
                onAction: (a) => devKitToasts.info('${a.label}: ${a.value}'),
                onScanAgain: () {},
              ),
              child: Text(label),
            ),
        ],
      );
}

class _OpenCamera extends StatelessWidget {
  const _OpenCamera();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(children: [
      Icon(Icons.qr_code_scanner_rounded,
          size: 56, color: theme.colors.onSurface),
      const SizedBox(height: 12),
      Text('Uses the camera, so it asks for permission first.',
          textAlign: TextAlign.center,
          style: theme.typography.body
              .copyWith(color: theme.colors.onSurface.withValues(alpha: 0.7))),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            body: KitoScannerView(
              hint: 'Scan any QR code or barcode',
              style: KitoScanOverlayStyle.laser,
              onDetect: (code) => KitoScanResultSheet.show(context, code,
                  onAction: (a) => devKitToasts.info('${a.label}: ${a.value}')),
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        )),
        icon: const Icon(Icons.photo_camera_rounded),
        label: const Text('Open the scanner'),
      ),
    ]);
  }
}

class _Parser extends StatefulWidget {
  const _Parser();

  @override
  State<_Parser> createState() => _ParserState();
}

class _ParserState extends State<_Parser> {
  final _text = TextEditingController(text: _till);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final p = KitoScanParser.parse(_text.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _text,
          minLines: 1,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Code contents',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (label, raw) in const [
            ('Wi-Fi', _wifi),
            ('Till', _till),
            ('Paybill', 'kitopay://paybill/247247?account=ACC-9'),
            ('Contact', _contact),
            ('SMS', 'SMSTO:0712345678:Niko njiani'),
            ('EAN', _product),
          ])
            ActionChip(
              label: Text(label),
              onPressed: () => setState(() => _text.text = raw),
            ),
        ]),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: KitoMotion.of(context, theme.motion.medium),
          child: ListTile(
            key: ValueKey(p.kindTitle),
            leading: Icon(p.icon, color: theme.colors.onSurface),
            title: Text(p.kindTitle),
            subtitle:
                Text(p.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

/// A stand-in camera frame: a dim café counter with a QR sticker (or a barcode on a packet).
class _FakePreview extends StatelessWidget {
  const _FakePreview({this.barcode = false, this.bright = false});

  final bool barcode;
  final bool bright;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bright
                  ? const [Color(0xFF8A7560), Color(0xFF5E4A38)]
                  : const [Color(0xFF3B2F26), Color(0xFF1C1612)],
            ),
          ),
          child: CustomPaint(painter: _PreviewPainter(barcode: barcode)),
        ),
      );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({required this.barcode});

  final bool barcode;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(4);
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
        20 + r.nextDouble() * 50,
        Paint()
          ..color = const Color(0xFFFFD8A8)
              .withValues(alpha: 0.05 + r.nextDouble() * 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    final window = KitoScanWindow.rect(size, aspectRatio: barcode ? 1.8 : 1);
    canvas.save();
    canvas.translate(window.center.dx, window.center.dy);
    canvas.rotate(-0.05);
    final card = Rect.fromCenter(
        center: Offset.zero,
        width: window.width * 0.78,
        height: window.height * 0.78);
    canvas.drawRRect(
      RRect.fromRectAndRadius(card.inflate(6), const Radius.circular(10)),
      Paint()..color = const Color(0xFFF6F1E7),
    );
    final ink = Paint()..color = const Color(0xFF16161D);
    if (barcode) {
      var x = card.left + 6;
      var k = 0;
      while (x < card.right - 6) {
        final w = 1.5 + (k * 7 % 4);
        if (k.isEven) {
          canvas.drawRect(
              Rect.fromLTWH(x, card.top + 6, w, card.height - 22), ink);
        }
        x += w + 1;
        k++;
      }
    } else {
      const n = 21;
      final cell = card.width / n;
      bool finder(int i, int j) {
        bool inBox(int ox, int oy) =>
            i >= ox && i < ox + 7 && j >= oy && j < oy + 7;
        return inBox(0, 0) || inBox(n - 7, 0) || inBox(0, n - 7);
      }

      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          bool on;
          if (finder(i, j)) {
            final ox = i >= n - 7 ? n - 7 : 0;
            final oy = j >= n - 7 ? n - 7 : 0;
            final di = i - ox, dj = j - oy;
            on = di == 0 ||
                di == 6 ||
                dj == 0 ||
                dj == 6 ||
                (di >= 2 && di <= 4 && dj >= 2 && dj <= 4);
          } else {
            on = ((i * 31 + j * 17 + i * j) % 7) < 3;
          }
          if (on) {
            canvas.drawRect(
                Rect.fromLTWH(card.left + i * cell, card.top + j * cell,
                    cell + 0.3, cell + 0.3),
                ink);
          }
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.barcode != barcode;
}
