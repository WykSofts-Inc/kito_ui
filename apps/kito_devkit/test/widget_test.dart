// Copyright © 2026 wyksoftsinc.com. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_devkit/app/settings.dart';
import 'package:kito_devkit/app/toasts.dart';
import 'package:kito_devkit/catalog/catalog.dart';
import 'package:kito_devkit/gallery/gallery.dart';
import 'package:kito_devkit/main.dart';
import 'package:kito_devkit/settings/settings_page.dart';
import 'package:kito_ui_maps/kito_ui_maps.dart';

void main() {
  // Maps in the galleries draw a plain backdrop instead of downloading tiles.
  setUpAll(() => KitoMap.debugTilesOverride = const KitoMapTiles.none());

  testWidgets('home shows the header, the kits and the roadmap',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KitoDevKitApp(settings: AppSettings()));
    await tester.pumpAndSettle();
    expect(find.text('Kito UI'), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
  });

  testWidgets('search finds samples', (tester) async {
    await tester.pumpWidget(KitoDevKitApp(settings: AppSettings()));
    await tester.enterText(find.byType(TextField), 'frosted');
    await tester.pumpAndSettle();
    expect(find.text('Frosted glass'), findsWidgets);
  });

  testWidgets('every sample builds without errors, in both directions',
      (tester) async {
    for (final direction in TextDirection.values) {
      for (final kit in KitCatalog.kits) {
        for (final section in kit.sections) {
          for (final sample in section.samples) {
            // Render inside the real detail page so container issues
            // (like ListTiles missing a Material) surface here.
            await tester.pumpWidget(MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: SampleDetailPage(kit: kit, sample: sample),
              ),
            ));
            await tester.pump(const Duration(milliseconds: 50));
            expect(tester.takeException(), isNull,
                reason: '${kit.title} › ${sample.title}');
          }
        }
      }
    }
  });

  testWidgets('settings opens cleanly in every theme', (tester) async {
    for (final choice in ThemeChoice.values) {
      final settings = AppSettings()..theme = choice;
      await tester.pumpWidget(KitoDevKitApp(settings: settings));
      await tester.pump();
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      expect(tester.takeException(), isNull, reason: choice.name);
    }
  });

  test('catalog search ranks title matches first', () {
    final hits = KitCatalog.searchSamples('spring');
    expect(hits.first.sample.title, 'Spring curve');
  });

  testWidgets('toasts show over the app from anywhere', (tester) async {
    await tester.pumpWidget(KitoDevKitApp(settings: AppSettings()));
    await tester.pump();
    devKitToasts.success('Karibu, Wycliff N');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Karibu, Wycliff N'), findsOneWidget);
    devKitToasts.dismissAll();
    await tester.pump(const Duration(seconds: 1));
  });
}
