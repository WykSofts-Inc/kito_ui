// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_devkit/app/settings.dart';
import 'package:kito_devkit/catalog/catalog.dart';
import 'package:kito_devkit/gallery/gallery.dart';
import 'package:kito_devkit/main.dart';

/// Window sizes the app must lay out cleanly at: a small phone, a narrow
/// desktop window, a tablet and a wide desktop window.
const _sizes = [
  Size(320, 640),
  Size(360, 740),
  Size(768, 1024),
  Size(1440, 900)
];

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

String _errors(WidgetTester tester) {
  final messages = <String>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    messages.add(e.toString().split('\n').first);
  }
  return messages.join('; ');
}

void main() {
  testWidgets('home lays out at every window size', (tester) async {
    addTearDown(tester.view.reset);
    for (final size in _sizes) {
      _setSize(tester, size);
      await tester.pumpWidget(KitoDevKitApp(settings: AppSettings()));
      await tester.pump(const Duration(milliseconds: 100));
      // Scroll the whole page so every section is laid out.
      for (var i = 0; i < 12; i++) {
        await tester.drag(
            find.byType(CustomScrollView).first, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(_errors(tester), isEmpty, reason: '$size');
    }
  });

  testWidgets('galleries and samples lay out on a small phone', (tester) async {
    addTearDown(tester.view.reset);
    // 360 wide: a common small Android phone. (The test font draws every
    // glyph as a full square, so text runs much wider than on a device.)
    _setSize(tester, const Size(360, 740));
    final failures = <String>[];
    for (final kit in KitCatalog.kits) {
      await tester.pumpWidget(MaterialApp(home: KitGalleryPage(kit: kit)));
      await tester.pump(const Duration(milliseconds: 50));
      final g = _errors(tester);
      if (g.isNotEmpty) failures.add('${kit.title} gallery: $g');
      for (final section in kit.sections) {
        for (final sample in section.samples) {
          await tester.pumpWidget(
              MaterialApp(home: SampleDetailPage(kit: kit, sample: sample)));
          await tester.pump(const Duration(milliseconds: 50));
          final s = _errors(tester);
          if (s.isNotEmpty) failures.add('${kit.title} › ${sample.title}: $s');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
