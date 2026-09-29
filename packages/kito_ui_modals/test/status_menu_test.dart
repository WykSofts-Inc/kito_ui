// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_modals/kito_ui_modals.dart';

import 'helpers.dart';

void main() {
  group('KitoStatusDialogState', () {
    test('keeps its message and compares by kind and message', () {
      expect(const KitoStatusDialogState.success('Paid').message, 'Paid');
      expect(const KitoStatusDialogState.pending().message, isNull);
      expect(const KitoStatusDialogState.success('x'),
          isNot(const KitoStatusDialogState.failure('x')));
      expect(const KitoStatusDialogState.success('x'),
          const KitoStatusDialogState.success('x'));
    });
  });

  group('showKitoStatusDialog', () {
    testWidgets('pending stays up; success closes by itself', (tester) async {
      late KitoStatusDialogController status;
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => TextButton(
          onPressed: () => status = showKitoStatusDialog(context,
              state: const KitoStatusDialogState.pending('Paying…')),
          child: const Text('Open'),
        ),
      )));
      await tester.tap(find.text('Open'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Paying…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Paying…'), findsOneWidget,
          reason: 'pending never auto-dismisses');
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Paying…'), findsOneWidget, reason: 'it blocks');

      status.update(const KitoStatusDialogState.success('Paid'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Paid'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.text('Paid'), findsNothing);
      expect(status.isClosed, isTrue);
    });

    testWidgets('announces its message as a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(testApp(const Center(
          child: KitoStatusDialogView(
              state: KitoStatusDialogState.failure('Payment failed')))));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byType(KitoStatusDialogView)),
          matchesSemantics(label: 'Payment failed', isLiveRegion: true));
      semantics.dispose();
    });

    testWidgets('runWithKitoStatusDialog reports success and failure',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(testApp(Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      })));
      final ok =
          runWithKitoStatusDialog(ctx, () async => 42, successMessage: 'Saved');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Saved'), findsOneWidget);
      expect(await ok, 42);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);

      Object? caught;
      runWithKitoStatusDialog<void>(ctx, () async => throw StateError('no'),
              failureMessage: 'Failed')
          .catchError((Object e) => caught = e);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Failed'), findsOneWidget);
      expect(caught, isA<StateError>());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('close shuts it early', (tester) async {
      late KitoStatusDialogController status;
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => TextButton(
          onPressed: () => status = showKitoStatusDialog(context,
              state: const KitoStatusDialogState.pending('Working'),
              dimsBackground: false),
          child: const Text('Open'),
        ),
      )));
      await tester.tap(find.text('Open'));
      await tester.pump(const Duration(milliseconds: 400));
      status.close();
      await tester.pumpAndSettle();
      expect(find.text('Working'), findsNothing);
    });
  });

  group('showKitoActionMenu', () {
    testWidgets('runs the picked action and closes', (tester) async {
      var took = false;
      Future<KitoMenuAction?>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoActionMenu(context,
                  title: 'Profile photo',
                  message: 'Choose a source',
                  actions: [
                    KitoMenuAction('Take photo',
                        icon: Icons.photo_camera_rounded,
                        onPressed: () => took = true),
                    const KitoMenuAction('Remove photo',
                        icon: Icons.delete_rounded, isDestructive: true),
                  ]));
      expect(find.text('Profile photo'), findsOneWidget);
      expect(find.text('Choose a source'), findsOneWidget);
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(took, isTrue);
      expect((await result)?.title, 'Take photo');
      expect(find.text('Profile photo'), findsNothing);
    });

    testWidgets('Cancel completes with null', (tester) async {
      Future<KitoMenuAction?>? result;
      await pumpLauncher(
          tester,
          (context) => result = showKitoActionMenu(context,
              actions: const [KitoMenuAction('Share')], cancelTitle: 'Close'));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(await result, isNull);
    });

    testWidgets('destructive rows use the danger colour; RTL mirrors icons',
        (tester) async {
      await pumpLauncher(
        tester,
        (context) => showKitoActionMenu(context, actions: const [
          KitoMenuAction('Remove',
              icon: Icons.delete_rounded, isDestructive: true),
        ]),
        direction: TextDirection.rtl,
      );
      final text = tester.widget<Text>(find.text('Remove'));
      expect(text.style?.color, const Color(0xFFE5484D));
      // In RTL the icon sits to the right of the title.
      expect(tester.getCenter(find.byIcon(Icons.delete_rounded)).dx,
          greaterThan(tester.getCenter(find.text('Remove')).dx));
    });
  });
}
