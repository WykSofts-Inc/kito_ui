// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_toasts/kito_ui_toasts.dart';

Widget app(KitoToastCenter center,
        {bool reduceMotion = false,
        TextDirection direction = TextDirection.ltr,
        KitoToastAppearance appearance = const KitoToastAppearance(),
        Widget? home}) =>
    MaterialApp(
      theme: KitoTheme.light.toThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: direction,
          child: KitoToastHost(
              center: center, appearance: appearance, child: child!),
        ),
      ),
      home: home ?? const Scaffold(body: Center(child: Text('Home'))),
    );

void main() {
  testWidgets('shows a toast over a pushed page and a dialog', (tester) async {
    final center = KitoToastCenter();
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Details'))));
    await tester.pumpAndSettle();
    showDialog<void>(
        context: nav.context,
        builder: (_) => const AlertDialog(content: Text('Dialog')));
    await tester.pumpAndSettle();

    var opened = 0;
    center.show(KitoToast(
        message: 'Saved',
        title: 'Done',
        actions: [KitoToastAction(label: 'Open', onPressed: () => opened++)]));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(tester.getRect(find.byType(KitoToastView)).top, lessThan(100));

    // The tap reaches the toast, not the dialog's barrier, so the toast is on top.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(find.text('Dialog'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('touches outside the toast reach the app', (tester) async {
    final center = KitoToastCenter();
    addTearDown(center.dispose);
    var taps = 0;
    await tester.pumpWidget(app(center,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child:
                TextButton(onPressed: () => taps++, child: const Text('Tap')),
          ),
        )));
    center.showMessage('Hello', duration: null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap'));
    expect(taps, 1);
  });

  testWidgets('of() and context.kitoToasts find the center', (tester) async {
    late KitoToastCenter found;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => KitoToastHost(child: child!),
      home: Builder(builder: (context) {
        found = context.kitoToasts;
        return const SizedBox();
      }),
    ));
    expect(found, isA<KitoToastCenter>());
    expect(KitoToastHost.maybeOf(tester.element(find.byType(SizedBox))),
        same(found));
  });

  testWidgets('every layout renders, light and dark', (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final layout in KitoToastLayout.values) {
        final center = KitoToastCenter();
        await tester.pumpWidget(MaterialApp(
          theme: (brightness == Brightness.light
                  ? KitoTheme.light
                  : KitoTheme.dark)
              .toThemeData(),
          builder: (context, child) =>
              KitoToastHost(center: center, child: child!),
          home: const SizedBox(),
        ));
        center.show(KitoToast(
          message: 'Message for $layout',
          title: 'Title',
          layout: layout,
          progress: 0.4,
          avatar: layout == KitoToastLayout.glass
              ? const KitoToastAvatar(initials: 'WN')
              : null,
          actions: [KitoToastAction(label: 'Open', onPressed: () {})],
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$layout');
        expect(find.byType(KitoToastView), findsOneWidget);
        center.dismissAll();
        await tester.pumpAndSettle();
        center.dispose();
      }
    }
  });

  testWidgets('actions run and dismiss; non-dismissing actions keep it',
      (tester) async {
    final center = KitoToastCenter();
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    var opened = 0;
    center.show(KitoToast(message: 'New message', actions: [
      KitoToastAction(label: 'Later', onPressed: () {}, dismisses: false),
      KitoToastAction(label: 'Open', onPressed: () => opened++),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(center.current, isNotNull);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(center.current, isNull);
    expect(find.text('New message'), findsNothing);
  });

  testWidgets('swipe up dismisses, a short drag springs back', (tester) async {
    final center = KitoToastCenter();
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    center.showMessage('Swipe me', duration: null);
    await tester.pumpAndSettle();
    await tester.drag(find.text('Swipe me'), const Offset(0, -20));
    await tester.pumpAndSettle();
    expect(center.current, isNotNull);
    expect(center.isPaused, isFalse);
    await tester.drag(find.text('Swipe me'), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(center.current, isNull);
    expect(find.text('Swipe me'), findsNothing);
  });

  testWidgets('tapping a stack fans it out and pauses; tapping again folds',
      (tester) async {
    final center = KitoToastCenter(presentation: KitoToastPresentation.stacked);
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    center.info('First');
    center.info('Second');
    center.info('Third');
    await tester.pumpAndSettle();
    final collapsedGap = tester.getTopLeft(find.text('Second')).dy -
        tester.getTopLeft(find.text('Third')).dy;
    await tester.tap(find.text('Third'));
    await tester.pumpAndSettle();
    expect(center.isStackExpanded, isTrue);
    expect(center.isPaused, isTrue);
    final expandedGap = tester.getTopLeft(find.text('Second')).dy -
        tester.getTopLeft(find.text('Third')).dy;
    expect(expandedGap, greaterThan(collapsedGap + 30));
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(center.isStackExpanded, isFalse);
    center.dismissAll();
    await tester.pumpAndSettle();
  });

  testWidgets('bottom position sits above the bottom edge', (tester) async {
    final center = KitoToastCenter(position: KitoToastPosition.bottom);
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    center.showMessage('Bottom', duration: null);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(KitoToastView));
    expect(rect.bottom, greaterThan(500));
    expect(rect.bottom, lessThanOrEqualTo(600));
  });

  testWidgets('semantics: live region, label, dismiss and stack actions',
      (tester) async {
    final handle = tester.ensureSemantics();
    final center = KitoToastCenter(presentation: KitoToastPresentation.stacked);
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    center.showMessage('Saved', title: 'Done', duration: null);
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byType(KitoToastView));
    expect(node.label, 'Done. Saved');
    expect(
        node,
        // ignore: deprecated_member_use, containsSemantics works on every supported Flutter.
        containsSemantics(
            label: 'Done. Saved', isLiveRegion: true, hasDismissAction: true));

    center.showMessage('Another', duration: null);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Another')),
      findsOneWidget,
    );
    final front = tester.getSemantics(find.text('Another').first);
    final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
    expect(
      find.byWidgetPredicate((w) =>
          w is Semantics &&
          (w.properties.customSemanticsActions?.keys
                  .any((a) => a.label == 'Show all 2 notifications') ??
              false)),
      findsOneWidget,
    );
    owner.performAction(front.id, SemanticsAction.dismiss);
    await tester.pumpAndSettle();
    expect(center.visible, hasLength(1));
    center.dismissAll();
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('reduce motion: fades without sliding', (tester) async {
    final center = KitoToastCenter();
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center, reduceMotion: true));
    center.showMessage('Calm', duration: null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final translations = tester
        .widgetList<FractionalTranslation>(find.ancestor(
            of: find.text('Calm'),
            matching: find.byType(FractionalTranslation)))
        .toList();
    expect(translations, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Calm'), findsOneWidget);
  });

  testWidgets('RTL puts the accent bar and icon on the right', (tester) async {
    final center = KitoToastCenter();
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center, direction: TextDirection.rtl));
    center.success('تم الحفظ', title: 'تم');
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.byType(KitoToastView));
    final icon = tester.getCenter(find.byIcon(Icons.check_circle_rounded));
    expect(icon.dx, greaterThan(toast.center.dx));
    center.dismissAll();
    await tester.pumpAndSettle();
  });

  testWidgets('countdown ring counts down and loading shows a spinner',
      (tester) async {
    final center = KitoToastCenter();
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    center.undo('Archived', onUndo: () {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(KitoToastCountdownRing), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsNothing);

    center.show(KitoToast(message: 'Working', isLoading: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    center.complete(center.current!.id, style: KitoToastStyle.success);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    center.dismissAll();
    await tester.pumpAndSettle();
  });

  testWidgets('plays a haptic for success and when a loading toast completes',
      (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final center = KitoToastCenter(presentation: KitoToastPresentation.stacked);
    addTearDown(center.dispose);
    await tester.pumpWidget(app(center));
    center.info('Quiet');
    await tester.pump();
    expect(calls, isEmpty);
    center.error('Loud');
    await tester.pump();
    expect(calls, ['HapticFeedbackType.heavyImpact']);
    final id = center.show(KitoToast(message: 'Load', isLoading: true));
    await tester.pump();
    expect(calls, hasLength(1));
    center.complete(id, style: KitoToastStyle.success);
    await tester.pump();
    expect(calls.last, 'HapticFeedbackType.lightImpact');

    // Turned off in the appearance.
    calls.clear();
    await tester.pumpWidget(app(center,
        appearance: const KitoToastAppearance(playsHaptics: false)));
    center.dismissAll();
    await tester.pumpAndSettle();
    center.success('Silent');
    await tester.pump();
    expect(calls, isEmpty);
    center.dismissAll();
    await tester.pumpAndSettle();
  });

  testWidgets('an action button keeps its height in a tall parent',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: Row(children: [
            KitoToastActionButton(
              action: KitoToastAction(label: 'Undo', onPressed: () {}),
              color: Colors.red,
              onPressed: () {},
            ),
          ]),
        ),
      ),
    ));
    expect(tester.getSize(find.byType(KitoToastActionButton)).height, 44);
  });
}
