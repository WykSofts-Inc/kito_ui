// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_scanner/kito_ui_scanner.dart';

import 'helpers.dart';

void main() {
  testWidgets('overlay draws over any child in every style', (tester) async {
    for (final style in KitoScanOverlayStyle.values) {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: KitoScanOverlay(
              style: style,
              hint: 'Scan the till QR',
              child: const ColoredBox(color: Colors.brown),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('Scan the till QR'), findsOneWidget);
    }
  });

  testWidgets('overlay locks and holds still with reduce motion', (
    tester,
  ) async {
    var locked = false;
    late StateSetter set;
    await tester.pumpWidget(
      testApp(
        StatefulBuilder(
          builder: (context, s) {
            set = s;
            return Scaffold(
              body: KitoScanOverlay(
                style: KitoScanOverlayStyle.laser,
                locked: locked,
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
        reduceMotion: true,
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    set(() => locked = true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('control bar reports taps and shows the torch state', (
    tester,
  ) async {
    var torch = 0, flips = 0, closed = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Center(
            child: KitoScannerControlBar(
              torchOn: true,
              onTorch: () => torch++,
              onSwitchCamera: () => flips++,
              onClose: () => closed++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Turn torch off'));
    await tester.tap(find.byTooltip('Switch camera'));
    await tester.tap(find.byTooltip('Close'));
    expect((torch, flips, closed), (1, 1, 1));
    expect(find.byTooltip('Scan a photo'), findsNothing);
  });

  testWidgets('result card shows Wi-Fi details, reveals and copies', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final actions = <KitoScanActionKind>[];
    var again = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: SingleChildScrollView(
            child: KitoScanResultCard(
              code: KitoScannedCode('WIFI:T:WPA;S:Java Guest;P:karibu2026;;'),
              onAction: (a) => actions.add(a.kind),
              onScanAgain: () => again++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('WI-FI NETWORK'), findsOneWidget);
    expect(find.text('Java Guest'), findsOneWidget);
    expect(find.text('karibu2026'), findsNothing);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.text('karibu2026'), findsOneWidget);
    await tester.tap(find.text('Join network'));
    await tester.tap(find.byTooltip('Copy'));
    await tester.pump();
    expect(copied, ['karibu2026']);
    expect(actions, [KitoScanActionKind.joinWifi, KitoScanActionKind.copy]);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Scan again'));
    expect(again, 1);
  });

  testWidgets('result cards build for every payload, RTL', (tester) async {
    const raws = [
      'https://kito.ke/menu',
      'MECARD:N:Wanjiru,Amina;TEL:0712345678;EMAIL:amina@kito.ke;;',
      'tel:+254712345678',
      'mailto:hello@kito.ke?subject=Hi',
      'SMSTO:0712345678:Niko njiani',
      'geo:-1.2864,36.8172?q=KICC',
      'kitopay://till?number=123456&amount=1500&name=Mama%20Mboga',
      '6161001234567',
      'Just some text',
    ];
    for (final raw in raws) {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: KitoScanResultCard(code: KitoScannedCode(raw)),
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: raw);
    }
    expect(find.text('Look it up'), findsNothing);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('result sheet opens from anywhere', (tester) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => KitoScanResultSheet.show(
                        context,
                        KitoScannedCode(
                          'kitopay://paybill/247247?account=ACC-9',
                        ),
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Paybill'), findsOneWidget);
    expect(find.text('ACC-9'), findsOneWidget);
  });
}
