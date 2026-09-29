// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_onboarding/kito_ui_onboarding.dart';

const _pages = [
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.bolt_rounded),
    eyebrow: 'Step 1',
    title: 'Fast',
    message: 'Everything loads instantly.',
    accent: Color(0xFFFF3D77),
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.lock_rounded),
    title: 'Secure',
    message: 'Your data stays yours.',
    bullets: ['End-to-end encryption', 'No ads'],
    accent: Color(0xFF3E63DD),
  ),
  KitoOnboardingPage(
    background: KitoBackground.gradient(KitoGradient.ocean),
    title: 'Simple',
    message: 'No clutter, just what you need.',
  ),
];

Widget _app(Widget child,
        {TextDirection direction = TextDirection.ltr,
        bool reduceMotion = false}) =>
    MaterialApp(
      theme: KitoTheme.light.toThemeData(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Directionality(textDirection: direction, child: app!),
      ),
      home: Scaffold(body: child),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  _riseInLeavesNoTimers();
  group('KitoOnboardingMath', () {
    test('reduce motion swaps the big transitions for a fade', () {
      for (final t in [
        KitoOnboardingPageTransition.cube,
        KitoOnboardingPageTransition.zoom,
        KitoOnboardingPageTransition.parallax,
      ]) {
        expect(KitoOnboardingMath.effectiveTransition(t, reduceMotion: true),
            KitoOnboardingPageTransition.fade);
        expect(
            KitoOnboardingMath.effectiveTransition(t, reduceMotion: false), t);
      }
      expect(
          KitoOnboardingMath.effectiveTransition(
              KitoOnboardingPageTransition.scaleFade,
              reduceMotion: true),
          KitoOnboardingPageTransition.scaleFade);
    });

    test('opacity, scale, turn and parallax track the distance', () {
      const fade = KitoOnboardingPageTransition.fade;
      expect(KitoOnboardingMath.opacity(fade, 0), 1);
      expect(KitoOnboardingMath.opacity(fade, -1), 0.25);
      expect(KitoOnboardingMath.opacity(fade, 3), 0.25, reason: 'clamped');
      expect(KitoOnboardingMath.opacity(KitoOnboardingPageTransition.zoom, 0.5),
          0.5);
      expect(
          KitoOnboardingMath.scale(KitoOnboardingPageTransition.scaleFade, 1),
          0.86);
      expect(KitoOnboardingMath.scale(KitoOnboardingPageTransition.zoom, -1),
          1.35);
      expect(
          KitoOnboardingMath.scale(KitoOnboardingPageTransition.slide, 1), 1);
      expect(
          KitoOnboardingMath.cubeAngle(KitoOnboardingPageTransition.cube, -0.5),
          -37.5);
      expect(KitoOnboardingMath.cubeAngle(KitoOnboardingPageTransition.fade, 1),
          0);
      expect(
          KitoOnboardingMath.parallaxOffset(
              KitoOnboardingPageTransition.parallax, 1),
          110);
    });
  });

  group('KitoOnboardingController', () {
    testWidgets('next, back, goTo and progress', (tester) async {
      var finished = 0, skipped = 0;
      final c = KitoOnboardingController();
      await tester.pumpWidget(_app(KitoOnboarding(
        pages: _pages,
        controller: c,
        onFinish: () => finished++,
        onSkip: () => skipped++,
      )));
      expect(c.pageCount, 3);
      expect(c.isFirstPage, isTrue);
      expect(c.progress, closeTo(1 / 3, 1e-9));
      c.next();
      expect(c.page, 1);
      c.back();
      c.back();
      expect(c.page, 0);
      c.goTo(99);
      expect(c.page, 2);
      expect(c.isLastPage, isTrue);
      expect(c.progress, 1);
      c.next();
      expect(finished, 1);
      c.skip();
      expect(skipped, 1);
      await _settle(tester);
    });

    testWidgets('skip falls back to onFinish', (tester) async {
      var finished = 0;
      final c = KitoOnboardingController();
      await tester.pumpWidget(_app(KitoOnboarding(
          pages: _pages, controller: c, onFinish: () => finished++)));
      await tester.tap(find.text('Skip'));
      expect(finished, 1);
      await _settle(tester);
    });
  });

  group('KitoOnboarding', () {
    testWidgets('Next walks the pages; Get started finishes', (tester) async {
      var finished = false;
      final changes = <int>[];
      await tester.pumpWidget(_app(KitoOnboarding(
        pages: _pages,
        onFinish: () => finished = true,
        onPageChanged: changes.add,
      )));
      await _settle(tester);
      expect(find.text('Fast'), findsOneWidget);
      expect(find.text('STEP 1'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await _settle(tester);
      expect(find.text('Secure'), findsOneWidget);
      expect(find.text('No ads'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await _settle(tester);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Skip'), findsNothing,
          reason: 'no skip on the last page');
      await tester.tap(find.text('Get started'));
      expect(finished, isTrue);
      expect(changes, [1, 2]);
    });

    testWidgets('jumping several pages reports only where it lands',
        (tester) async {
      final c = KitoOnboardingController();
      final changes = <int>[];
      await tester.pumpWidget(_app(KitoOnboarding(
        pages: _pages,
        controller: c,
        onFinish: () {},
        onPageChanged: changes.add,
      )));
      await _settle(tester);
      c.goTo(2);
      await _settle(tester);
      expect(changes, [2]);
      expect(c.page, 2);
      c.goTo(0);
      await _settle(tester);
      expect(changes, [2, 0]);
      expect(c.page, 0);
    });

    testWidgets('swiping moves pages, and mirrors in RTL', (tester) async {
      for (final rtl in [false, true]) {
        final c = KitoOnboardingController();
        await tester.pumpWidget(_app(
            KitoOnboarding(pages: _pages, controller: c, onFinish: () {}),
            direction: rtl ? TextDirection.rtl : TextDirection.ltr));
        await _settle(tester);
        await tester.fling(
            find.text('Fast'), Offset(rtl ? 400 : -400, 0), 1500);
        await _settle(tester);
        expect(c.page, 1, reason: rtl ? 'RTL' : 'LTR');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the back button appears after the first page', (tester) async {
      final c = KitoOnboardingController(initialPage: 1);
      await tester.pumpWidget(_app(KitoOnboarding(
        pages: _pages,
        controller: c,
        onFinish: () {},
        style: const KitoOnboardingStyle(showsBackButton: true),
      )));
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await _settle(tester);
      expect(c.page, 0);
      expect(find.text('Fast'), findsOneWidget);
    });

    testWidgets('arrow keys move between pages', (tester) async {
      final c = KitoOnboardingController();
      await tester.pumpWidget(
          _app(KitoOnboarding(pages: _pages, controller: c, onFinish: () {})));
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settle(tester);
      expect(c.page, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await _settle(tester);
      expect(c.page, 0);
    });

    for (final layout in KitoOnboardingLayout.values) {
      testWidgets('layout ${layout.name} shows the page', (tester) async {
        await tester.pumpWidget(_app(KitoOnboarding(
          pages: [
            _pages[0],
            const KitoOnboardingPage(
                artwork: KitoOnboardingArtwork.none,
                background: KitoBackground.color(Color(0xFF123456)),
                title: 'Photo',
                message: 'Full bleed.'),
          ],
          onFinish: () {},
          style: KitoOnboardingStyle(layout: layout),
        )));
        await _settle(tester);
        expect(find.text('Fast'), findsOneWidget);
        expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Next'));
        await _settle(tester);
        expect(find.text('Photo'), findsOneWidget);
        if (layout == KitoOnboardingLayout.fullBleed) {
          final text = tester.widget<Text>(find.text('Photo'));
          expect(text.style?.color, Colors.white,
              reason: 'white over the photo');
        }
      });
    }

    for (final placement in KitoOnboardingButtonPlacement.values) {
      testWidgets('placement ${placement.name} gets to the end',
          (tester) async {
        var finished = false;
        await tester.pumpWidget(_app(KitoOnboarding(
          pages: _pages,
          onFinish: () => finished = true,
          style: KitoOnboardingStyle(buttonPlacement: placement),
        )));
        await _settle(tester);
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.bySemanticsLabel('Next'));
          await _settle(tester);
        }
        await tester.tap(find.bySemanticsLabel('Get started'));
        expect(finished, isTrue);
      });
    }

    for (final indicator in KitoOnboardingIndicator.values) {
      testWidgets('indicator ${indicator.name} reads the position',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final c = KitoOnboardingController(initialPage: 1);
        await tester.pumpWidget(_app(KitoOnboarding(
          pages: _pages,
          controller: c,
          onFinish: () {},
          style: KitoOnboardingStyle(indicator: indicator),
        )));
        await _settle(tester);
        if (indicator == KitoOnboardingIndicator.none) {
          expect(find.bySemanticsLabel('Page 2 of 3'), findsNothing);
        } else {
          expect(tester.getSemantics(find.bySemanticsLabel('Page 2 of 3')),
              isSemantics(label: 'Page 2 of 3', isLiveRegion: true));
        }
        if (indicator == KitoOnboardingIndicator.numbered) {
          expect(find.text('2'), findsOneWidget);
        }
        semantics.dispose();
      });
    }

    for (final transition in KitoOnboardingPageTransition.values) {
      testWidgets('transition ${transition.name} tracks a drag',
          (tester) async {
        final c = KitoOnboardingController();
        await tester.pumpWidget(_app(KitoOnboarding(
          pages: _pages,
          controller: c,
          onFinish: () {},
          style: KitoOnboardingStyle(
              pageTransition: transition,
              artworkMotion: KitoOnboardingArtworkMotion.bounce),
        )));
        await _settle(tester);
        final gesture = await tester.startGesture(const Offset(600, 300));
        await gesture.moveBy(const Offset(-200, 0));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await gesture.moveBy(const Offset(-200, 0));
        await gesture.up();
        await _settle(tester);
        expect(c.page, 1);
      });
    }

    testWidgets('the button takes on the next page accent as you swipe',
        (tester) async {
      await tester
          .pumpWidget(_app(KitoOnboarding(pages: _pages, onFinish: () {})));
      await _settle(tester);
      Color fill() {
        final box = tester.widget<AnimatedContainer>(find
            .ancestor(
                of: find.text('Next'), matching: find.byType(AnimatedContainer))
            .first);
        return (box.decoration! as ShapeDecoration).color!;
      }

      expect(fill(), const Color(0xFFFF3D77));
      final gesture = await tester.startGesture(const Offset(600, 300));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-380, 0));
      await tester.pump();
      final mid = fill();
      expect(mid, isNot(const Color(0xFFFF3D77)));
      expect(mid, isNot(const Color(0xFF3E63DD)));
      await gesture.up();
      await _settle(tester);
    });

    testWidgets('reduce motion shows text at once', (tester) async {
      await tester.pumpWidget(_app(
          KitoOnboarding(
            pages: _pages,
            onFinish: () {},
            style: const KitoOnboardingStyle(
                pageTransition: KitoOnboardingPageTransition.cube,
                artworkMotion: KitoOnboardingArtworkMotion.float),
          ),
          reduceMotion: true));
      await tester.pump();
      final opacity = tester.widget<Opacity>(find
          .ancestor(of: find.text('Fast'), matching: find.byType(Opacity))
          .first);
      expect(opacity.opacity, 1);
      // Float is off, so the flow settles.
      await tester.pumpAndSettle();
    });
  });

  group('Permission steps', () {
    KitoOnboardingPage permissionPage(Future<bool> Function() onRequest) =>
        KitoOnboardingPage(
          artwork:
              const KitoOnboardingArtwork.icon(Icons.notifications_rounded),
          title: 'Stay in the loop',
          message: 'We only notify you about orders.',
          permission: KitoOnboardingPermission(
              onRequest: onRequest, allowTitle: 'Allow notifications'),
        );

    testWidgets('Allow asks, shows progress, reports and moves on',
        (tester) async {
      final request = Completer<bool>();
      final results = <(int, bool)>[];
      final c = KitoOnboardingController();
      await tester.pumpWidget(_app(KitoOnboarding(
        pages: [permissionPage(() => request.future), _pages[2]],
        controller: c,
        onFinish: () {},
        onPermissionResult: (page, granted) => results.add((page, granted)),
      )));
      await _settle(tester);
      expect(find.text('Not now'), findsOneWidget);
      await tester.tap(find.text('Allow notifications'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      request.complete(true);
      await _settle(tester);
      expect(results, [(0, true)]);
      expect(c.page, 1);
      expect(find.text('Not now'), findsNothing);
    });

    testWidgets('Not now moves on without asking; errors count as denied',
        (tester) async {
      var asked = 0;
      final results = <bool>[];
      final c = KitoOnboardingController();
      await tester.pumpWidget(_app(KitoOnboarding(
        pages: [
          permissionPage(() async {
            asked++;
            return true;
          }),
          permissionPage(() async => throw StateError('denied')),
          _pages[2],
        ],
        controller: c,
        onFinish: () {},
        onPermissionResult: (_, granted) => results.add(granted),
      )));
      await _settle(tester);
      await tester.tap(find.text('Not now'));
      await _settle(tester);
      expect(asked, 0);
      expect(c.page, 1);
      await tester.tap(find.text('Allow notifications'));
      await _settle(tester);
      expect(results, [false]);
      expect(c.page, 2);
    });
  });

  group('Artwork', () {
    testWidgets('custom artwork is drawn and hidden from screen readers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(KitoOnboarding(
        pages: [
          KitoOnboardingPage(
            artwork:
                KitoOnboardingArtwork.custom((_) => const Text('Illustration')),
            title: 'Drawn',
            message: 'By hand.',
          ),
        ],
        onFinish: () {},
      )));
      await _settle(tester);
      expect(find.text('Illustration'), findsOneWidget);
      expect(find.bySemanticsLabel('Illustration'), findsNothing);
      expect(find.bySemanticsLabel('Drawn'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('page view works on its own', (tester) async {
      await tester.pumpWidget(_app(const KitoOnboardingPageView(
        page: KitoOnboardingPage(title: 'Solo', message: 'A single screen.'),
        style: KitoOnboardingStyle(layout: KitoOnboardingLayout.split),
      )));
      await _settle(tester);
      expect(find.text('Solo'), findsOneWidget);
    });
  });
}

void _riseInLeavesNoTimers() {
  testWidgets('a page removed mid rise-in leaves no timer behind',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: KitoOnboardingPageView(
          page: KitoOnboardingPage(title: 'Karibu', message: 'Hello'),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpWidget(const SizedBox());
  });
}
