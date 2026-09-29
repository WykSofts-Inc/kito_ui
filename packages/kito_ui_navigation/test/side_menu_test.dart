// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_navigation/kito_ui_navigation.dart';

import 'helpers.dart';

Widget _menu(KitoSideMenuController c,
        {KitoSideMenuStyle style = KitoSideMenuStyle.push,
        KitoSideMenuEdge edge = KitoSideMenuEdge.start,
        double? edgeDragWidth}) =>
    KitoSideMenu(
      controller: c,
      style: style,
      edge: edge,
      edgeDragWidth: edgeDragWidth,
      width: 280,
      background: const KitoBackground.gradient(KitoGradient.ocean),
      foreground: Colors.white,
      menu: const Column(children: [SizedBox(height: 40), Text('Drawer')]),
      child: const Scaffold(body: Center(child: Text('Screen'))),
    );

void main() {
  group('KitoSideMenuMath', () {
    test('progress follows the drag and clamps', () {
      expect(
          KitoSideMenuMath.progress(
              isOpen: false, translation: 140, width: 280),
          0.5);
      expect(
          KitoSideMenuMath.progress(isOpen: true, translation: -70, width: 280),
          0.75);
      expect(
          KitoSideMenuMath.progress(
              isOpen: false, translation: -50, width: 280),
          0);
      expect(
          KitoSideMenuMath.progress(isOpen: true, translation: 0, width: 0), 1);
    });

    test('settles open past halfway, counting a fling', () {
      expect(
          KitoSideMenuMath.settlesOpen(progress: 0.6, velocity: 0, width: 280),
          isTrue);
      expect(
          KitoSideMenuMath.settlesOpen(progress: 0.4, velocity: 0, width: 280),
          isFalse);
      expect(
          KitoSideMenuMath.settlesOpen(
              progress: 0.2, velocity: 900, width: 280),
          isTrue);
      expect(
          KitoSideMenuMath.settlesOpen(
              progress: 0.9, velocity: -900, width: 280),
          isFalse);
    });

    test('the start edge is on the left in LTR and the right in RTL', () {
      expect(
          KitoSideMenuMath.openingSign(
              KitoSideMenuEdge.start, TextDirection.ltr),
          1);
      expect(
          KitoSideMenuMath.openingSign(
              KitoSideMenuEdge.start, TextDirection.rtl),
          -1);
      expect(
          KitoSideMenuMath.openingSign(KitoSideMenuEdge.end, TextDirection.ltr),
          -1);
    });
  });

  group('KitoSideMenuController', () {
    test('open, close and toggle notify once per change', () {
      var n = 0;
      final c = KitoSideMenuController()..addListener(() => n++);
      c.open();
      c.open();
      expect(c.isOpen, isTrue);
      c.toggle();
      expect(c.isOpen, isFalse);
      c.close();
      expect(n, 2);
    });
  });

  group('KitoSideMenu', () {
    testWidgets('opens from the controller; a tap on the screen closes it',
        (tester) async {
      final c = KitoSideMenuController();
      await tester.pumpWidget(testApp(_menu(c)));
      expect(find.text('Drawer'), findsNothing);
      c.open();
      await tester.pumpAndSettle();
      expect(c.progress.value, 1);
      expect(
          tester.getTopLeft(find.text('Drawer')).dx, greaterThanOrEqualTo(0));
      // Push: the screen moved aside by the drawer's width.
      expect(tester.getCenter(find.text('Screen')).dx, closeTo(400 + 280, 1));
      await tester.tapAt(const Offset(700, 300));
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse);
      expect(c.progress.value, 0);
    });

    testWidgets('drags open toward the end edge, and closes back',
        (tester) async {
      final c = KitoSideMenuController();
      await tester.pumpWidget(testApp(_menu(c)));
      await tester.dragFrom(const Offset(20, 300), const Offset(220, 0));
      await tester.pumpAndSettle();
      expect(c.isOpen, isTrue);
      await tester.dragFrom(const Offset(600, 300), const Offset(-220, 0));
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse);
    });

    testWidgets('a short drag springs back closed', (tester) async {
      final c = KitoSideMenuController();
      await tester.pumpWidget(testApp(_menu(c)));
      await tester.timedDragFrom(const Offset(20, 300), const Offset(60, 0),
          const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse);
    });

    testWidgets('in RTL it opens from the right with a leftward drag',
        (tester) async {
      final c = KitoSideMenuController();
      await tester.pumpWidget(testApp(_menu(c), direction: TextDirection.rtl));
      await tester.dragFrom(const Offset(780, 300), const Offset(220, 0));
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse, reason: 'rightward drags close in RTL');
      await tester.dragFrom(const Offset(780, 300), const Offset(-220, 0));
      await tester.pumpAndSettle();
      expect(c.isOpen, isTrue);
      expect(tester.getTopRight(find.text('Drawer')).dx, greaterThan(520));
    });

    testWidgets('the end edge opens from the other side', (tester) async {
      final c = KitoSideMenuController(isOpen: true);
      await tester.pumpWidget(testApp(_menu(c, edge: KitoSideMenuEdge.end)));
      await tester.pumpAndSettle();
      expect(tester.getCenter(find.text('Drawer')).dx, greaterThan(520));
    });

    testWidgets('edgeDragWidth limits where a closed menu opens from',
        (tester) async {
      final c = KitoSideMenuController();
      await tester.pumpWidget(testApp(_menu(c, edgeDragWidth: 24)));
      await tester.dragFrom(const Offset(300, 300), const Offset(220, 0));
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse);
      await tester.dragFrom(const Offset(10, 300), const Offset(220, 0));
      await tester.pumpAndSettle();
      expect(c.isOpen, isTrue);
    });

    testWidgets('Escape closes an open menu', (tester) async {
      final c = KitoSideMenuController(isOpen: true);
      await tester.pumpWidget(testApp(_menu(c)));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse);
    });

    for (final style in KitoSideMenuStyle.values) {
      testWidgets('${style.name} opens and closes', (tester) async {
        final c = KitoSideMenuController();
        await tester.pumpWidget(testApp(_menu(c, style: style)));
        c.open();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(c.progress.value, inExclusiveRange(0, 1));
        await tester.pumpAndSettle();
        expect(find.text('Drawer'), findsOneWidget);
        expect(
            tester.getTopLeft(find.text('Drawer')).dx, greaterThanOrEqualTo(0));
        c.close();
        await tester.pumpAndSettle();
        expect(c.progress.value, 0);
      });
    }

    testWidgets('screen readers get the drawer only while open',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final c = KitoSideMenuController();
      await tester.pumpWidget(testApp(_menu(c)));
      expect(find.bySemanticsLabel('Drawer'), findsNothing);
      expect(find.bySemanticsLabel('Screen'), findsOneWidget);
      c.open();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Drawer'), findsOneWidget);
      expect(find.bySemanticsLabel('Screen'), findsNothing);
      expect(tester.getSemantics(find.bySemanticsLabel('Close menu')),
          isSemantics(label: 'Close menu', isButton: true, hasTapAction: true));
      semantics.dispose();
    });

    testWidgets('reduce motion eases without springing', (tester) async {
      final c = KitoSideMenuController();
      await tester.pumpWidget(testApp(
          _menu(c, style: KitoSideMenuStyle.rotate3D),
          reduceMotion: true));
      c.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 230));
      expect(c.progress.value, 1);
    });

    testWidgets('the drawer uses the foreground colour for its text',
        (tester) async {
      final c = KitoSideMenuController(isOpen: true);
      await tester.pumpWidget(testApp(_menu(c)));
      await tester.pumpAndSettle();
      final style =
          DefaultTextStyle.of(tester.element(find.text('Drawer'))).style;
      expect(style.color, Colors.white);
    });
  });
}
