// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_empty_states/kito_ui_empty_states.dart';

Widget host(Widget child,
        {bool reduceMotion = false,
        TextDirection direction = TextDirection.ltr,
        KitoTheme theme = KitoTheme.light}) =>
    MaterialApp(
      theme: theme.toThemeData(),
      home: MediaQuery(
        data: MediaQueryData(
            disableAnimations: reduceMotion, size: const Size(400, 800)),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

void main() {
  group('poses', () {
    test('every motion starts near rest and stays small', () {
      for (final motion in KitoEmptyStateMotion.values) {
        for (var t = 0.0; t < 6; t += 0.05) {
          final p = KitoEmptyStatePose.at(t, motion);
          expect(p.x.abs(), lessThan(0.05), reason: '$motion x at $t');
          expect(p.y.abs(), lessThan(0.07), reason: '$motion y at $t');
          expect(p.rotation.abs(), lessThan(17), reason: '$motion r at $t');
          expect(p.scale, inInclusiveRange(1, 1.09));
          expect(p.squash, inInclusiveRange(0.9, 1));
        }
      }
    });

    test('each motion has its signature', () {
      // Beat pulses near the start of each 1.1 s loop.
      expect(KitoEmptyStatePose.at(0.13, KitoEmptyStateMotion.beat).scale,
          greaterThan(1.05));
      expect(KitoEmptyStatePose.at(0.8, KitoEmptyStateMotion.beat).scale,
          closeTo(1, 0.01));
      // Shake is still between bursts.
      expect(KitoEmptyStatePose.at(1.5, KitoEmptyStateMotion.shake),
          const KitoEmptyStatePose());
      // Bounce squashes on landing and lifts mid-air.
      expect(
          KitoEmptyStatePose.at(0.01, KitoEmptyStateMotion.bounce).squash, 0.9);
      expect(KitoEmptyStatePose.at(0.65, KitoEmptyStateMotion.bounce).y,
          lessThan(-0.05));
      // Swing rests in the second half of its loop.
      expect(
          KitoEmptyStatePose.at(2.0, KitoEmptyStateMotion.swing).rotation, 0);
    });

    test('satellites spread out and sparkles twinkle between 0 and 1', () {
      final spots = [
        for (var i = 0; i < 4; i++) KitoEmptyStatePose.satellite(i)
      ];
      expect(spots.toSet(), hasLength(4));
      for (final s in spots) {
        expect(s.distance, inInclusiveRange(0.39, 0.45));
      }
      for (var t = 0.0; t < 3; t += 0.1) {
        expect(KitoEmptyStatePose.twinkle(1, t), inInclusiveRange(0, 1));
        expect(KitoEmptyStatePose.bob(2, t).abs(), lessThanOrEqualTo(0.025));
      }
    });
  });

  group('illustrations', () {
    test('presets are complete and distinct', () {
      const presets = KitoEmptyStateIllustration.presets;
      expect(presets, hasLength(15));
      expect(presets.map((p) => p.name).toSet(), hasLength(15));
      for (final p in presets) {
        expect(p.colors, hasLength(2), reason: p.name);
        expect(p.satellites, hasLength(3), reason: p.name);
      }
      expect(KitoEmptyStateIllustration.offline.badge, isNotNull);
    });

    test('tinted and copyWith keep the rest', () {
      final red = KitoEmptyStateIllustration.cart.tinted([Colors.red]);
      expect(red.colors, [Colors.red]);
      expect(red.icon, KitoEmptyStateIllustration.cart.icon);
      expect(red, isNot(KitoEmptyStateIllustration.cart));
      expect(KitoEmptyStateIllustration.cart.copyWith(),
          KitoEmptyStateIllustration.cart);
      expect(KitoEmptyStateIllustration.cart.copyWith().hashCode,
          KitoEmptyStateIllustration.cart.hashCode);
    });

    testWidgets('animates, springs in and is one labelled image',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const KitoEmptyStateIllustrationView(
          KitoEmptyStateIllustration.notifications)));
      await tester.pump(const Duration(milliseconds: 16));
      final early = tester.widget<Opacity>(find
          .descendant(
              of: find.byType(KitoEmptyStateIllustrationView),
              matching: find.byType(Opacity))
          .first);
      expect(early.opacity, lessThan(1));
      await tester.pump(const Duration(seconds: 1));
      final tile = find.byIcon(Icons.notifications_rounded);
      final before = tester.getCenter(tile);
      await tester.pump(const Duration(milliseconds: 300));
      final after = tester.getCenter(tile);
      expect(before, isNot(after), reason: 'the bell swings');
      expect(find.bySemanticsLabel('No notifications'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('reduce motion draws it still', (tester) async {
      await tester.pumpWidget(host(
          const KitoEmptyStateIllustrationView(
              KitoEmptyStateIllustration.inbox),
          reduceMotion: true));
      await tester.pumpAndSettle(); // settles: nothing is ticking
      final tile = find.byIcon(Icons.inbox_rounded);
      final a = tester.getCenter(tile);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getCenter(tile), a);
    });

    testWidgets('every preset renders in light and dark', (tester) async {
      for (final theme in [KitoTheme.light, KitoTheme.dark]) {
        for (final p in KitoEmptyStateIllustration.presets) {
          await tester.pumpWidget(
              host(KitoEmptyStateIllustrationView(p, size: 120), theme: theme));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull, reason: p.name);
          expect(find.byIcon(p.icon), findsWidgets);
        }
      }
    });
  });

  group('KitoEmptyStateView', () {
    testWidgets('standard layout shows everything and runs actions',
        (tester) async {
      var retried = 0;
      await tester.pumpWidget(host(KitoEmptyStateView(
        media: const KitoEmptyStateMedia.illustration(
            KitoEmptyStateIllustration.cart),
        title: 'Your cart is empty',
        message: 'Everything you add shows up here.',
        actions: [
          KitoEmptyStateAction(label: 'Start shopping', onPressed: () {}),
          KitoEmptyStateAction(
              label: 'Retry',
              role: KitoEmptyStateActionRole.secondary,
              onPressed: () => retried++),
        ],
      )));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Everything you add shows up here.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
      // Vertical actions stack.
      expect(tester.getTopLeft(find.text('Retry')).dy,
          greaterThan(tester.getTopLeft(find.text('Start shopping')).dy));
      expect(tester.getSize(find.byType(KitoEmptyStateView)).height,
          greaterThan(300));
    });

    testWidgets('horizontal actions sit side by side', (tester) async {
      await tester.pumpWidget(host(KitoEmptyStateView(
        media: const KitoEmptyStateMedia.icon(Icons.inbox_rounded),
        title: 'Nothing',
        actionsAxis: Axis.horizontal,
        actions: [
          KitoEmptyStateAction(label: 'One', onPressed: () {}),
          KitoEmptyStateAction(label: 'Two', onPressed: () {}),
        ],
      )));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('One')).dy,
          tester.getTopLeft(find.text('Two')).dy);
    });

    testWidgets('entrance staggers media, text, then actions', (tester) async {
      await tester.pumpWidget(host(KitoEmptyStateView(
        media: const KitoEmptyStateMedia.icon(Icons.inbox_rounded),
        title: 'Title',
        actions: [KitoEmptyStateAction(label: 'Go', onPressed: () {})],
      )));
      await tester.pump(const Duration(milliseconds: 200));
      double opacityOf(Finder f) => tester
          .widget<Opacity>(
              find.ancestor(of: f, matching: find.byType(Opacity)).first)
          .opacity;
      expect(opacityOf(find.text('Title')),
          greaterThan(opacityOf(find.text('Go'))));
      await tester.pumpAndSettle();
      expect(opacityOf(find.text('Go')), 1);
    });

    testWidgets('compact puts media at the start, mirrored in RTL',
        (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(host(
            KitoEmptyStateView(
              media: const KitoEmptyStateMedia.icon(Icons.inbox_rounded),
              title: 'No mail',
              message: 'Inbox zero.',
              layout: KitoEmptyStateLayout.compact,
              actions: [
                KitoEmptyStateAction(label: 'Compose', onPressed: () {})
              ],
            ),
            direction: direction));
        await tester.pumpAndSettle();
        final icon = tester.getCenter(find.byIcon(Icons.inbox_rounded)).dx;
        final text = tester.getCenter(find.text('No mail')).dx;
        if (direction == TextDirection.ltr) {
          expect(icon, lessThan(text));
        } else {
          expect(icon, greaterThan(text));
        }
      }
    });

    testWidgets('inline is one row with a text action', (tester) async {
      var added = 0;
      await tester.pumpWidget(host(KitoEmptyStateView(
        media: const KitoEmptyStateMedia.illustration(
            KitoEmptyStateIllustration.wallet),
        title: 'No payment methods yet',
        layout: KitoEmptyStateLayout.inline,
        actions: [KitoEmptyStateAction(label: 'Add', onPressed: () => added++)],
      )));
      await tester.pumpAndSettle();
      expect(find.byType(KitoEmptyStateIllustrationView), findsNothing);
      expect(find.byIcon(Icons.credit_card_rounded), findsOneWidget);
      expect(
          tester.getSize(find.byType(KitoEmptyStateView)).height, lessThan(80));
      expect(tester.getSize(find.text('Add')).height, lessThan(44));
      await tester.tap(find.text('Add'));
      expect(added, 1);
    });

    testWidgets('full screen pins actions to the bottom', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: KitoTheme.light.toThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: KitoEmptyStateView.offline(
                onRetry: () {}, layout: KitoEmptyStateLayout.fullScreen),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text("You're offline"), findsOneWidget);
      expect(tester.getBottomLeft(find.text('Retry')).dy, greaterThan(500));
    });

    testWidgets('presets', (tester) async {
      await tester
          .pumpWidget(host(KitoEmptyStateView.noResults(query: 'kale')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No results for “kale”'), findsOneWidget);
      expect(find.byType(KitoEmptyStateIllustrationView), findsOneWidget);

      var retried = false;
      await tester.pumpWidget(host(KitoEmptyStateView.error(
          message: 'Server said no', onRetry: () => retried = true)));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);

      await tester.pumpWidget(host(KitoEmptyStateView.noData()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Nothing here yet'), findsOneWidget);

      await tester.pumpWidget(host(KitoEmptyStateView.offline()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('semantics: title is a header, actions are buttons',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(KitoEmptyStateView(
        media: const KitoEmptyStateMedia.illustration(
            KitoEmptyStateIllustration.photos),
        title: 'No photos',
        message: 'Take one to get started.',
        actions: [KitoEmptyStateAction(label: 'Open camera', onPressed: () {})],
      )));
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.getSemantics(find.text('No photos')),
        // ignore: deprecated_member_use, containsSemantics works on every supported Flutter.
        containsSemantics(label: 'No photos', isHeader: true),
      );
      expect(
        tester.getSemantics(find.text('Open camera')),
        // ignore: deprecated_member_use, containsSemantics works on every supported Flutter.
        containsSemantics(
            label: 'Open camera', isButton: true, hasTapAction: true),
      );
      // The illustration is a single image, labelled by its name.
      expect(find.bySemanticsLabel('No photos'), findsWidgets);
      handle.dispose();
    });

    testWidgets('image and widget media', (tester) async {
      await tester.pumpWidget(host(const KitoEmptyStateView(
        media: KitoEmptyStateMedia.widget(
            ColoredBox(key: ValueKey('custom'), color: Colors.teal)),
        title: 'Custom',
        mediaSize: 100,
      )));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('custom'))),
          const Size(100, 100));
    });
  });

  group('KitoEmptyStateSnapshotView', () {
    Widget build(AsyncSnapshot<List<int>> snapshot, {VoidCallback? onRetry}) =>
        host(SizedBox(
          height: 600,
          child: KitoEmptyStateSnapshotView<List<int>>(
            snapshot: snapshot,
            isEmpty: (d) => d.isEmpty,
            onRetry: onRetry,
            builder: (context, data) => Text('${data.length} items'),
          ),
        ));

    testWidgets('loading, data, empty and error', (tester) async {
      await tester.pumpWidget(build(const AsyncSnapshot.waiting()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(
          build(const AsyncSnapshot.withData(ConnectionState.done, [1, 2, 3])));
      await tester.pumpAndSettle();
      expect(find.text('3 items'), findsOneWidget);

      await tester.pumpWidget(
          build(const AsyncSnapshot.withData(ConnectionState.done, [])));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Nothing here yet'), findsOneWidget);

      var retried = 0;
      await tester.pumpWidget(build(
          AsyncSnapshot.withError(
              ConnectionState.done, TimeoutException('slow')),
          onRetry: () => retried++));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Something went wrong'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });
  });
}
