// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_modals/kito_ui_modals.dart';

import 'helpers.dart';

/// An app whose body holds a nested navigator with a button inside it.
Widget nestedApp(void Function(BuildContext context) onPressed) => testApp(
      SizedBox(
        width: 360,
        height: 600,
        child: Navigator(
          key: const Key('nested'),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                    onPressed: () => onPressed(context),
                    child: const Text('Open')),
              ),
            ),
          ),
        ),
      ),
    );

Finder insideNested(Finder f) =>
    find.descendant(of: find.byKey(const Key('nested')), matching: f);

void main() {
  group('pop-in timers', () {
    testWidgets('an alert card removed during its pop-in leaves no timer',
        (tester) async {
      await tester.pumpWidget(testApp(Center(
        child: KitoAlertCard(
            alert: const KitoAlert(title: 'Saved', icon: Icons.check),
            onAction: (_) {}),
      )));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a status view removed during its draw-in leaves no timer',
        (tester) async {
      await tester.pumpWidget(testApp(const Center(
          child: KitoStatusDialogView(
              state: KitoStatusDialogState.success('Paid')))));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the badge still pops in', (tester) async {
      await tester.pumpWidget(testApp(Center(
        child: KitoAlertCard(
            alert: const KitoAlert(title: 'Saved', icon: Icons.check),
            onAction: (_) {}),
      )));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('nested navigators', () {
    testWidgets('the action menu can open inside a nested navigator',
        (tester) async {
      KitoMenuAction? picked;
      await tester.pumpWidget(nestedApp((context) async {
        picked = await showKitoActionMenu(context,
            useRootNavigator: false,
            actions: const [KitoMenuAction('Take photo')]);
      }));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(insideNested(find.text('Take photo')), findsOneWidget);
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(picked?.title, 'Take photo');
    });

    testWidgets('by default the menu still opens on the root navigator',
        (tester) async {
      await tester.pumpWidget(nestedApp((context) => showKitoActionMenu(context,
          actions: const [KitoMenuAction('Take photo')])));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Take photo'), findsOneWidget);
      expect(insideNested(find.text('Take photo')), findsNothing);
    });

    testWidgets('runWithKitoStatusDialog can run inside a nested navigator',
        (tester) async {
      await tester.pumpWidget(nestedApp((context) => runWithKitoStatusDialog(
            context,
            () => Future<void>.delayed(const Duration(milliseconds: 300)),
            pendingMessage: 'Saving…',
            successMessage: 'Saved',
            useRootNavigator: false,
          )));
      await tester.tap(find.text('Open'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(insideNested(find.text('Saving…')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(insideNested(find.text('Saved')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });
  });
}
