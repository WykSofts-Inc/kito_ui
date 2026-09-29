// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_modals/kito_ui_modals.dart';

import 'helpers.dart';

void main() {
  group('KitoAlert', () {
    test('two short actions sit side by side', () {
      expect(
          KitoAlert.laysOutHorizontally([
            const KitoAlertAction.cancel(),
            const KitoAlertAction('Delete', role: KitoAlertRole.destructive),
          ]),
          isTrue);
      expect(
          KitoAlert.laysOutHorizontally([
            const KitoAlertAction.cancel(),
            const KitoAlertAction('Delete my account forever'),
          ]),
          isFalse);
      expect(
          KitoAlert.laysOutHorizontally([
            const KitoAlertAction('A'),
            const KitoAlertAction('B'),
            const KitoAlertAction.cancel(),
          ]),
          isFalse);
    });

    test('cancel reads first side by side and last when stacked', () {
      const cancel = KitoAlertAction.cancel();
      const ok = KitoAlertAction('OK');
      const more = KitoAlertAction('Something longer here');
      expect(KitoAlert.orderedActions([ok, cancel]), [cancel, ok]);
      expect(KitoAlert.orderedActions([cancel, ok, more]), [ok, more, cancel]);
    });

    test('an alert always has an action', () {
      expect(const KitoAlert(title: 'Hi').actions.map((a) => a.title), ['OK']);
      expect(
          const KitoAlert(title: 'Delete?', actions: [
            KitoAlertAction('Delete', role: KitoAlertRole.destructive)
          ]).isDestructive,
          isTrue);
      expect(const KitoAlert(title: 'Hi').cancelAction, isNull);
    });
  });

  group('showKitoAlert', () {
    testWidgets('returns the tapped action after running it', (tester) async {
      var deleted = false;
      Future<KitoAlertAction?>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoAlert(
                context,
                KitoAlert(
                  icon: Icons.delete_rounded,
                  title: 'Delete account?',
                  message: "This can't be undone.",
                  actions: [
                    const KitoAlertAction.cancel(),
                    KitoAlertAction('Delete',
                        role: KitoAlertRole.destructive,
                        onPressed: () => deleted = true),
                  ],
                ),
              ));
      expect(find.text('Delete account?'), findsOneWidget);
      expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
      // Side by side: cancel sits before Delete.
      expect(tester.getCenter(find.text('Cancel')).dx,
          lessThan(tester.getCenter(find.text('Delete')).dx));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect((await result)?.title, 'Delete');
      expect(find.text('Delete account?'), findsNothing);
    });

    testWidgets('a tap outside picks cancel', (tester) async {
      var cancelled = false;
      Future<KitoAlertAction?>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoAlert(
              context,
              KitoAlert(title: 'Leave?', actions: [
                KitoAlertAction.cancel('Stay', () => cancelled = true),
                const KitoAlertAction('Leave'),
              ])));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
      expect((await result)?.role, KitoAlertRole.cancel);
    });

    testWidgets('without a cancel action, only the buttons close it',
        (tester) async {
      await pumpLauncher(tester,
          (context) => showKitoAlert(context, const KitoAlert(title: 'Saved')));
      await tester.tapAt(const Offset(10, 10));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('Escape picks cancel', (tester) async {
      Future<KitoAlertAction?>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoAlert(
              context,
              const KitoAlert(
                  title: 'Leave?', actions: [KitoAlertAction.cancel()])));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect((await result)?.role, KitoAlertRole.cancel);
    });

    testWidgets('stacks long actions with cancel last', (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoAlert(
              context,
              const KitoAlert(title: 'Plan', actions: [
                KitoAlertAction.cancel(),
                KitoAlertAction('Upgrade to the yearly plan'),
              ])));
      expect(
          tester.getCenter(find.text('Cancel')).dy,
          greaterThan(
              tester.getCenter(find.text('Upgrade to the yearly plan')).dy));
    });

    testWidgets('celebrating alerts burst confetti, unless motion is reduced',
        (tester) async {
      await pumpLauncher(
          tester,
          (context) => showKitoAlert(context,
              const KitoAlert(title: 'Order placed!', celebrates: true)));
      expect(find.byType(KitoModalConfetti), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await pumpLauncher(
          tester,
          (context) => showKitoAlert(context,
              const KitoAlert(title: 'Order placed!', celebrates: true)),
          reduceMotion: true);
      expect(
          find.descendant(
              of: find.byType(KitoModalConfetti),
              matching: find.byType(CustomPaint)),
          findsNothing);
    });

    testWidgets('names the route and exposes buttons to screen readers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpLauncher(
          tester,
          (context) => showKitoAlert(
              context,
              const KitoAlert(
                  title: 'Leave?', actions: [KitoAlertAction.cancel()])));
      expect(
          tester.getSemantics(find.text('Cancel')),
          matchesSemantics(
              label: 'Cancel',
              isButton: true,
              isEnabled: true,
              hasEnabledState: true,
              isFocusable: true,
              hasTapAction: true,
              hasFocusAction: true));
      expect(find.bySemanticsLabel('Leave?'), findsWidgets);
      semantics.dispose();
    });
  });

  group('showKitoConfirmation', () {
    testWidgets('true when confirmed, false when cancelled', (tester) async {
      Future<bool>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoConfirmation(context,
              title: 'Delete card?',
              confirmTitle: 'Delete',
              isDestructive: true));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });
}
