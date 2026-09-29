// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_modals/kito_ui_modals.dart';

import 'helpers.dart';

class _Tip extends StatefulWidget {
  const _Tip({this.edge = KitoModalTooltipEdge.top});
  final KitoModalTooltipEdge edge;

  @override
  State<_Tip> createState() => _TipState();
}

class _TipState extends State<_Tip> {
  bool visible = true;

  @override
  Widget build(BuildContext context) => Center(
        child: KitoModalTooltip(
          visible: visible,
          message: 'Create your first list',
          icon: Icons.auto_awesome_rounded,
          edge: widget.edge,
          onDismiss: () => setState(() => visible = false),
          child: const SizedBox(width: 60, height: 40, child: Text('Add')),
        ),
      );
}

void main() {
  group('KitoModalTooltip', () {
    testWidgets('floats above its target and dismisses on tap', (tester) async {
      await tester.pumpWidget(testApp(const _Tip()));
      await tester.pumpAndSettle();
      expect(find.text('Create your first list'), findsOneWidget);
      expect(tester.getBottomLeft(find.text('Create your first list')).dy,
          lessThan(tester.getTopLeft(find.text('Add')).dy));
      await tester.tap(find.text('Create your first list'));
      await tester.pumpAndSettle();
      expect(find.text('Create your first list'), findsNothing);
    });

    testWidgets('bottom edge sits below', (tester) async {
      await tester
          .pumpWidget(testApp(const _Tip(edge: KitoModalTooltipEdge.bottom)));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Create your first list')).dy,
          greaterThan(tester.getBottomLeft(find.text('Add')).dy));
    });

    testWidgets('appears at once with reduce motion, as a live button',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(testApp(const _Tip(), reduceMotion: true));
      await tester.pump();
      await tester.pump();
      final opacity = tester.widget<Opacity>(find
          .ancestor(
              of: find.text('Create your first list'),
              matching: find.byType(Opacity))
          .first);
      expect(opacity.opacity, 1);
      expect(
          tester.getSemantics(find.bySemanticsLabel('Create your first list')),
          matchesSemantics(
              label: 'Create your first list',
              hint: 'Dismisses the tip',
              isButton: true,
              isLiveRegion: true,
              hasTapAction: true));
      semantics.dispose();
    });
  });

  group('KitoModalHeroCard', () {
    testWidgets('opens into the story and closes again', (tester) async {
      await tester.pumpWidget(testApp(ListView(children: [
        KitoModalHeroCard(
          tag: 'story',
          height: 200,
          collapsed: (_) => const ColoredBox(
              color: Colors.orange, child: Center(child: Text('Face'))),
          expanded: (_) => const Padding(
              padding: EdgeInsets.all(20), child: Text('The whole story')),
        ),
      ])));
      expect(find.text('The whole story'), findsNothing);
      await tester.tap(find.text('Face'));
      await tester.pumpAndSettle();
      expect(find.text('The whole story'), findsOneWidget);
      // The face is now the full-width header.
      expect(tester.getSize(find.byType(ColoredBox).last).width, 800);

      final semantics = tester.ensureSemantics();
      expect(tester.getSemantics(find.bySemanticsLabel('Close')),
          isSemantics(label: 'Close', isButton: true, hasTapAction: true));
      semantics.dispose();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.text('The whole story'), findsNothing);
      expect(find.text('Face'), findsOneWidget);
    });

    testWidgets('reduce motion skips the flight', (tester) async {
      await tester.pumpWidget(testApp(
          KitoModalHeroCard(
            tag: 'story',
            height: 200,
            collapsed: (_) => const Text('Face'),
            expanded: (_) => const Text('Story'),
          ),
          reduceMotion: true));
      await tester.tap(find.text('Face'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final modes = tester.widgetList<HeroMode>(find.byType(HeroMode));
      expect(modes.every((m) => !m.enabled), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Story'), findsOneWidget);
    });
  });

  group('KitoSlideToConfirm', () {
    test('sliding past 85% confirms', () {
      expect(KitoSlideToConfirm.confirms(offset: 86, track: 100), isTrue);
      expect(KitoSlideToConfirm.confirms(offset: 80, track: 100), isFalse);
      expect(KitoSlideToConfirm.confirms(offset: 0, track: 0), isFalse);
    });

    Widget slider(Future<void> Function() onConfirm,
            {Object? resetKey, List<KitoSlidePhase>? phases}) =>
        Center(
          child: SizedBox(
            width: 300,
            child: KitoSlideToConfirm(
              title: 'Slide to pay',
              resetKey: resetKey,
              onConfirm: onConfirm,
              onPhaseChanged: phases?.add,
            ),
          ),
        );

    testWidgets('a full slide runs the work and ends on a tick',
        (tester) async {
      var paid = 0;
      await tester.pumpWidget(testApp(slider(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        paid++;
      })));
      await tester.drag(
          find.byIcon(Icons.chevron_right_rounded), const Offset(260, 0));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(paid, 1);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('a short slide springs back without confirming',
        (tester) async {
      var paid = 0;
      await tester.pumpWidget(testApp(slider(() async => paid++)));
      await tester.drag(
          find.byIcon(Icons.chevron_right_rounded), const Offset(100, 0));
      await tester.pump(const Duration(seconds: 1));
      expect(paid, 0);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('a failure shows the cross, then slides back to try again',
        (tester) async {
      final phases = <KitoSlidePhase>[];
      await tester.pumpWidget(testApp(
          slider(() async => throw Exception('declined'), phases: phases)));
      await tester.drag(
          find.byIcon(Icons.chevron_right_rounded), const Offset(260, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(phases, [
        KitoSlidePhase.working,
        KitoSlidePhase.failed,
        KitoSlidePhase.idle,
      ]);
      expect(find.text('Slide to pay'), findsOneWidget);
    });

    testWidgets('slides toward the start edge in RTL', (tester) async {
      var paid = 0;
      await tester.pumpWidget(
          testApp(slider(() async => paid++), direction: TextDirection.rtl));
      await tester.drag(
          find.byIcon(Icons.chevron_right_rounded), const Offset(260, 0));
      await tester.pump(const Duration(milliseconds: 500));
      expect(paid, 0, reason: 'dragging right goes backwards in RTL');
      await tester.drag(
          find.byIcon(Icons.chevron_right_rounded), const Offset(-260, 0));
      await tester.pump(const Duration(milliseconds: 500));
      expect(paid, 1);
    });

    testWidgets('screen readers confirm with a tap; resetKey starts over',
        (tester) async {
      final semantics = tester.ensureSemantics();
      var paid = 0;
      await tester.pumpWidget(testApp(slider(() async => paid++, resetKey: 1)));
      final node = tester.getSemantics(find.byType(KitoSlideToConfirm));
      expect(
          node,
          isSemantics(
              label: 'Slide to pay', isButton: true, hasTapAction: true));
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump(const Duration(milliseconds: 500));
      expect(paid, 1);
      expect(find.text('Done'), findsOneWidget);

      await tester.pumpWidget(testApp(slider(() async => paid++, resetKey: 2)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Slide to pay'), findsOneWidget);
      semantics.dispose();
    });
  });
}
