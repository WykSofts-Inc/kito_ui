// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_loaders/kito_ui_loaders.dart';

import 'host.dart';

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => taps++),
        child: SizedBox(width: 200, height: 60, child: Text('taps $taps')),
      );
}

void main() {
  testWidgets('every loader kind animates in every direction, theme and motion',
      (tester) async {
    for (final kind in KitoLoaderKind.values) {
      for (final dir in TextDirection.values) {
        for (final reduce in [false, true]) {
          await tester.pumpWidget(host(
            KitoLoaderView(
                style: KitoLoaderStyle(kind: kind, size: 32, value: 0.4)),
            direction: dir,
            reduceMotion: reduce,
            brightness: reduce ? Brightness.dark : Brightness.light,
          ));
          await tester.pump(const Duration(milliseconds: 170));
          await tester.pump(const Duration(milliseconds: 530));
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('loaders announce themselves, localised', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const KitoLoaderSpinner()));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await tester.pumpWidget(
        host(const KitoLoaderSpinner(), locale: const Locale('sw')));
    expect(find.bySemanticsLabel('Inapakia'), findsOneWidget);
    await tester.pumpWidget(
        host(const KitoLoaderOrbit(semanticLabel: 'Syncing contacts')));
    expect(find.bySemanticsLabel('Syncing contacts'), findsOneWidget);
    await tester.pumpWidget(host(const KitoLoaderTypingIndicator()));
    expect(find.bySemanticsLabel('Typing'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('typing dots hop, but not under Reduce Motion', (tester) async {
    for (final reduce in [false, true]) {
      await tester.pumpWidget(
          host(const KitoLoaderTypingIndicator(), reduceMotion: reduce));
      await tester.pump(const Duration(milliseconds: 216));
      final lifts = tester
          .widgetList<Transform>(find.descendant(
              of: find.byType(KitoLoaderTypingIndicator),
              matching: find.byType(Transform)))
          .map((t) => t.transform.getTranslation().y)
          .toList();
      if (reduce) {
        expect(lifts.every((y) => y == 0), isTrue);
      } else {
        expect(lifts.any((y) => y < 0), isTrue);
      }
    }
  });

  testWidgets('the orbit turns the other way in RTL', (tester) async {
    final tops = <TextDirection, double>{};
    for (final dir in TextDirection.values) {
      await tester
          .pumpWidget(host(const KitoLoaderOrbit(size: 40), direction: dir));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 250));
      tops[dir] =
          tester.widgetList<Positioned>(find.byType(Positioned)).first.top!;
    }
    // The lead dot starts at 3 o'clock: clockwise dips below centre, anticlockwise rises.
    expect(tops[TextDirection.ltr]!, greaterThan(20));
    expect(tops[TextDirection.rtl]!, lessThan(20));
  });

  testWidgets('a paused timeline stops moving', (tester) async {
    var last = -1.0;
    Widget build(bool running) => host(KitoLoaderTimeline(
          running: running,
          builder: (context, t, _) {
            last = t;
            return const SizedBox();
          },
        ));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(last, greaterThan(0));
    await tester.pumpWidget(build(false));
    final frozen = last;
    await tester.pump(const Duration(milliseconds: 300));
    expect(last, frozen);
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    expect(last, greaterThan(frozen));
  });

  testWidgets('progress ring shows and announces its percentage',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const KitoLoaderProgressRing(value: 0.426)));
    await tester.pumpAndSettle();
    expect(find.text('42%'), findsOneWidget);
    expect(tester.getSemantics(find.byType(KitoLoaderProgressRing)),
        matchesSemantics(label: 'Progress', value: '42 percent'));
    handle.dispose();
  });

  testWidgets('determinate bars fill from the start edge, also in RTL',
      (tester) async {
    for (final dir in TextDirection.values) {
      await tester.pumpWidget(host(
        const SizedBox(
            width: 300,
            child: KitoLoaderLinearProgress(
                value: 0.5, label: 'Uploading', showPercentage: true)),
        direction: dir,
      ));
      await tester.pump(const Duration(seconds: 1));
      final track = tester.getRect(find.byType(ClipRRect).first);
      final fill = tester.getRect(find.byType(FractionallySizedBox));
      expect(fill.width, closeTo(150, 0.5));
      if (dir == TextDirection.ltr) {
        expect(fill.left, closeTo(track.left, 0.5));
      } else {
        expect(fill.right, closeTo(track.right, 0.5));
      }
      expect(find.text('50%'), findsOneWidget);
    }
  });

  testWidgets('indeterminate bars say they are in progress', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const SizedBox(
        width: 200, child: KitoLoaderLinearProgress(label: 'Syncing'))));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getSemantics(find.byType(KitoLoaderLinearProgress)),
        matchesSemantics(label: 'Syncing', value: 'In progress'));
    handle.dispose();
  });

  testWidgets('step progress ticks off finished steps', (tester) async {
    final handle = tester.ensureSemantics();
    const steps = ['Cart', 'Delivery', 'Pay'];
    await tester.pumpWidget(host(const SizedBox(
        width: 340, child: KitoLoaderStepProgress(steps: steps, current: 1))));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.getSemantics(find.byType(KitoLoaderStepProgress)),
        matchesSemantics(label: 'Step 2 of 3', value: 'Delivery'));

    await tester.pumpWidget(host(const SizedBox(
        width: 340, child: KitoLoaderStepProgress(steps: steps, current: 3))));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    expect(tester.getSemantics(find.byType(KitoLoaderStepProgress)),
        matchesSemantics(label: 'Step 3 of 3', value: 'Complete'));
    handle.dispose();
  });

  testWidgets('segment steps fill in turn, from the start edge in RTL',
      (tester) async {
    await tester.pumpWidget(host(
      const SizedBox(
        width: 300,
        child: KitoLoaderStepProgress(
            steps: ['One', 'Two', 'Three'],
            current: 1,
            stepFraction: 0.5,
            style: KitoLoaderStepStyle.segments),
      ),
      direction: TextDirection.rtl,
    ));
    await tester.pumpAndSettle();
    final fills = tester
        .widgetList<AnimatedFractionallySizedBox>(
            find.byType(AnimatedFractionallySizedBox))
        .map((w) => w.widthFactor)
        .toList();
    expect(fills, [1, 0.5, 0]);
    final segments = find.byType(AnimatedFractionallySizedBox);
    // In RTL the first (done) segment is the rightmost.
    expect(tester.getRect(segments.at(0)).left,
        greaterThan(tester.getRect(segments.at(2)).left));
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('every skeleton template lays out cleanly, LTR and RTL',
      (tester) async {
    for (final template in KitoLoaderSkeletonTemplate.values) {
      for (final dir in TextDirection.values) {
        await tester.pumpWidget(host(
          SingleChildScrollView(
            child: SizedBox(
                width: 360, child: KitoLoaderSkeletonView(template, count: 3)),
          ),
          direction: dir,
        ));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton swap hides the real child, then reveals it',
      (tester) async {
    final handle = tester.ensureSemantics();
    Widget build(bool loading) => host(KitoLoaderSkeletonSwap(
        loading: loading, child: const Text('Jane Wanjiru')));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.bySemanticsLabel('Jane Wanjiru'), findsNothing);
    expect(find.byType(KitoLoaderSkeleton), findsOneWidget);
    await tester.pumpWidget(build(false));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Jane Wanjiru'), findsOneWidget);
    expect(find.byType(KitoLoaderSkeleton), findsNothing);
    handle.dispose();
  });

  testWidgets('redaction blocks taps and keeps state', (tester) async {
    Widget build(bool loading) =>
        host(KitoLoaderRedacted(loading: loading, child: const _Counter()));
    await tester.pumpWidget(build(false));
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);

    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(_Counter), warnIfMissed: false);
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);

    await tester.pumpWidget(build(false));
    await tester.pumpAndSettle();
    expect(find.text('taps 1'), findsOneWidget, reason: 'state survived');
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('taps 2'), findsOneWidget);
  });

  testWidgets('the overlay blocks the screen and shows its card',
      (tester) async {
    final handle = tester.ensureSemantics();
    Widget build(bool on) => host(SizedBox(
          width: 400,
          height: 500,
          child: KitoLoaderOverlay(
            isPresented: on,
            message: 'Saving',
            detail: 'Hang tight',
            child: const Center(child: _Counter()),
          ),
        ));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Saving'), findsOneWidget);
    expect(find.text('Hang tight'), findsOneWidget);
    expect(find.bySemanticsLabel('taps 0'), findsNothing);
    await tester.tap(find.byType(_Counter), warnIfMissed: false);
    await tester.pump();
    expect(find.text('taps 0'), findsOneWidget);

    await tester.pumpWidget(build(false));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(KitoLoaderCard), findsNothing);
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a card with progress shows a ring', (tester) async {
    await tester.pumpWidget(
        host(const KitoLoaderCard(message: 'Uploading', progress: 0.3)));
    await tester.pumpAndSettle();
    expect(find.byType(KitoLoaderProgressRing), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
  });

  testWidgets('shimmer can be switched off without losing state',
      (tester) async {
    Widget build(bool on) =>
        host(KitoLoaderShimmer(enabled: on, child: const _Counter()));
    await tester.pumpWidget(build(false));
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.text('taps 1'), findsOneWidget);
    await tester.pumpWidget(build(false));
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.text('taps 1'), findsOneWidget);
  });

  group('pull to refresh', () {
    for (final physics in [
      const BouncingScrollPhysics(),
      const ClampingScrollPhysics()
    ]) {
      testWidgets(
          'pulling past the threshold refreshes (${physics.runtimeType})',
          (tester) async {
        final done = Completer<void>();
        var calls = 0;
        await tester.pumpWidget(host(SizedBox(
          width: 360,
          height: 600,
          child: KitoLoaderPullToRefresh(
            onRefresh: () {
              calls++;
              return done.future;
            },
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(parent: physics),
              children: [
                for (var i = 0; i < 30; i++)
                  SizedBox(height: 50, child: Text('Row $i'))
              ],
            ),
          ),
        )));
        await tester.drag(find.text('Row 1'), const Offset(0, 400));
        await tester.pump();
        expect(calls, 1);
        expect(
            tester
                .widget<KitoLoaderRefreshIndicator>(
                    find.byType(KitoLoaderRefreshIndicator))
                .isRefreshing,
            isTrue);
        await tester.pump(const Duration(milliseconds: 600));
        done.complete();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(
            tester
                .widget<KitoLoaderRefreshIndicator>(
                    find.byType(KitoLoaderRefreshIndicator))
                .isRefreshing,
            isFalse);
        expect(calls, 1);
      });
    }

    testWidgets('a short pull does nothing', (tester) async {
      var calls = 0;
      await tester.pumpWidget(host(SizedBox(
        height: 600,
        child: KitoLoaderPullToRefresh(
          onRefresh: () async => calls++,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            children: const [SizedBox(height: 50, child: Text('Only row'))],
          ),
        ),
      )));
      await tester.drag(find.text('Only row'), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(calls, 0);
    });

    testWidgets('the indicator reads its state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const KitoLoaderRefreshIndicator(
          pullProgress: 1, isRefreshing: false)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Pull to refresh'), findsOneWidget);
      final rotation =
          tester.widget<AnimatedRotation>(find.byType(AnimatedRotation));
      expect(rotation.turns, 0.5);
      await tester.pumpWidget(host(const KitoLoaderRefreshIndicator(
          pullProgress: 1, isRefreshing: true)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.bySemanticsLabel('Refreshing'), findsOneWidget);
      expect(find.byType(KitoLoaderGradientRing), findsOneWidget);
      handle.dispose();
    });
  });
}
