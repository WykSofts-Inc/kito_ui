// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_buttons/kito_ui_buttons.dart';

import 'host.dart';

void main() {
  testWidgets('renders the label and runs a sync action with a haptic',
      (tester) async {
    final haptics = recordHaptics(tester);
    var taps = 0;
    await tester.pumpWidget(
        host(KitoButton(label: 'Continue', onPressed: () => taps++)));
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.byType(KitoButton));
    await tester.pump();
    expect(taps, 1);
    expect(haptics, contains('HapticFeedbackType.lightImpact'));
    expect(find.byType(KitoButtonSpinner), findsNothing);
  });

  testWidgets('a null action disables it', (tester) async {
    final handle = tester.ensureSemantics();
    await tester
        .pumpWidget(host(const KitoButton(label: 'Pay', onPressed: null)));
    expect(
      tester.getSemantics(find.byType(KitoButton)),
      matchesSemantics(
          label: 'Pay',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false),
    );
    final opacity = tester.widget<AnimatedOpacity>(find
        .descendant(
            of: find.byType(KitoButton), matching: find.byType(AnimatedOpacity))
        .at(0));
    expect(opacity.opacity, KitoButtonTheme.standard.disabledOpacity);
    handle.dispose();
  });

  testWidgets('async actions show a spinner and ignore taps until done',
      (tester) async {
    final handle = tester.ensureSemantics();
    final done = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(host(KitoButton(
        label: 'Save',
        onPressed: () {
          calls++;
          return done.future;
        })));
    await tester.tap(find.byType(KitoButton));
    await tester.pump();
    expect(find.byType(KitoButtonSpinner), findsOneWidget);
    expect(tester.getSemantics(find.byType(KitoButton)).value, 'Loading');

    await tester.tap(find.byType(KitoButton), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    done.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(KitoButtonSpinner), findsNothing);
    handle.dispose();
  });

  testWidgets('success morphs the icon and label, then returns to idle',
      (tester) async {
    final phases = <KitoButtonPhase>[];
    await tester.pumpWidget(host(KitoButton(
      label: 'Add',
      icon: const Icon(Icons.add),
      showSuccess: true,
      successLabel: 'Added',
      onPhaseChanged: phases.add,
      onPressed: () async {},
    )));
    await tester.tap(find.byType(KitoButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Added'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Add'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(phases, [
      KitoButtonPhase.loading,
      KitoButtonPhase.success,
      KitoButtonPhase.idle,
    ]);
  });

  testWidgets('failure shakes, reports the error and shows a cross',
      (tester) async {
    final handle = tester.ensureSemantics();
    Object? reported;
    await tester.pumpWidget(host(KitoButton(
      label: 'Pay',
      icon: const Icon(Icons.credit_card),
      showFailure: true,
      failureLabel: 'Try again',
      onError: (e, _) => reported = e,
      onPressed: () async => throw StateError('declined'),
    )));
    await tester.tap(find.byType(KitoButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(reported, isA<StateError>());
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(tester.getSemantics(find.byType(KitoButton)).value, 'Failed');

    // Mid-shake, the button is off-centre.
    final shake = find.descendant(
        of: find.byType(KitoButtonShake), matching: find.byType(Transform));
    final t = tester.widget<Transform>(shake.first).transform;
    expect(t.getTranslation().x, isNot(0));
    await tester.pump(const Duration(seconds: 2));
    handle.dispose();
  });

  testWidgets('without showFailure an error just returns to idle',
      (tester) async {
    await tester.pumpWidget(host(KitoButton(
        label: 'Pay', onPressed: () async => throw Exception('nope'))));
    await tester.tap(find.byType(KitoButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pay'), findsOneWidget);
    expect(find.byType(KitoButtonSpinner), findsNothing);
  });

  testWidgets('a controller drives the phase', (tester) async {
    final controller = KitoButtonController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(
        KitoButton(label: 'Sync', controller: controller, onPressed: () {})));
    controller.value = KitoButtonPhase.loading;
    await tester.pump();
    expect(find.byType(KitoButtonSpinner), findsOneWidget);
    controller.value = KitoButtonPhase.idle;
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(KitoButtonSpinner), findsNothing);
  });

  testWidgets('loading: true forces the spinner', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
        KitoButton(label: 'Wait', loading: true, onPressed: () => taps++)));
    expect(find.byType(KitoButtonSpinner), findsOneWidget);
    await tester.tap(find.byType(KitoButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('small buttons get a 44×44 tap target', (tester) async {
    await tester.pumpWidget(host(KitoButton.icon(
        icon: const Icon(Icons.close),
        semanticLabel: 'Close',
        size: KitoButtonSize.small,
        onPressed: () {})));
    final size = tester.getSize(find.byType(KitoButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('icon-only buttons are square and read their label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(KitoButton.icon(
        icon: const Icon(Icons.favorite),
        semanticLabel: 'Like',
        semanticHint: 'Adds to favourites',
        onPressed: () {})));
    final chrome = find
        .descendant(
            of: find.byType(KitoButton),
            matching: find.byType(AnimatedContainer))
        .first;
    final size = tester.getSize(chrome);
    expect(size.width, size.height);
    expect(
      tester.getSemantics(find.byType(KitoButton)),
      matchesSemantics(
        label: 'Like',
        hint: 'Adds to favourites',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('leading icons sit on the right in RTL', (tester) async {
    for (final dir in TextDirection.values) {
      await tester.pumpWidget(host(
        KitoButton(
            label: 'Next',
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {}),
        direction: dir,
      ));
      final icon = tester.getCenter(find.byIcon(Icons.arrow_forward));
      final label = tester.getCenter(find.text('Next'));
      if (dir == TextDirection.ltr) {
        expect(icon.dx, lessThan(label.dx));
      } else {
        expect(icon.dx, greaterThan(label.dx));
      }
    }
  });

  testWidgets('trailing slots and spaceBetween push to the far edge',
      (tester) async {
    await tester.pumpWidget(host(SizedBox(
      width: 320,
      child: KitoButton(
        label: 'Pay',
        trailing: const Text('KES 1,500'),
        contentAlignment: KitoButtonContentAlignment.spaceBetween,
        expand: true,
        onPressed: () {},
      ),
    )));
    final button = tester.getRect(find.byType(KitoButton));
    final price = tester.getRect(find.text('KES 1,500'));
    final label = tester.getRect(find.text('Pay'));
    expect(button.width, 320);
    expect(button.right - price.right, lessThan(30));
    expect(label.left - button.left, lessThan(30));
  });

  testWidgets('press scales down, except under Reduce Motion', (tester) async {
    for (final reduce in [false, true]) {
      await tester.pumpWidget(host(KitoButton(label: 'Hold', onPressed: () {}),
          reduceMotion: reduce));
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(KitoButton)));
      await tester.pump();
      final scale = tester
          .widget<AnimatedScale>(find.descendant(
              of: find.byType(KitoButton),
              matching: find.byType(AnimatedScale)))
          .scale;
      expect(scale, reduce ? 1 : KitoButtonTheme.standard.pressedScale);
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('keyboard activation runs the action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
        KitoButton(label: 'Go', autofocus: true, onPressed: () => taps++)));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('screen-reader values follow the locale', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(
      const KitoButton(label: 'Hifadhi', loading: true, onPressed: null),
      locale: const Locale('sw'),
    ));
    expect(tester.getSemantics(find.byType(KitoButton)).value, 'Inapakia');
    handle.dispose();
  });

  testWidgets('large text wraps the title instead of shrinking it',
      (tester) async {
    await tester.pumpWidget(host(
        SizedBox(
            width: 200,
            child: KitoButton(
                label: 'Continue to secure checkout',
                expand: true,
                onPressed: () {})),
        textScale: 2));
    final text = tester.widget<Text>(find.text('Continue to secure checkout'));
    expect(text.maxLines, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every variant and size renders in light and dark',
      (tester) async {
    for (final brightness in Brightness.values) {
      for (final variant in KitoButtonVariant.values) {
        for (final size in [
          KitoButtonSize.small,
          KitoButtonSize.medium,
          KitoButtonSize.large
        ]) {
          await tester.pumpWidget(MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: host(KitoButton(
                label: variant.name,
                subtitle: 'sub',
                variant: variant,
                size: size,
                onPressed: () {})),
          ));
          expect(find.text(variant.name), findsOneWidget);
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scope theme reshapes buttons below it', (tester) async {
    await tester.pumpWidget(host(KitoButtonThemeScope(
      theme: const KitoButtonTheme(shape: KitoButtonShape.rectangle),
      child: KitoButton(label: 'Square', onPressed: () {}),
    )));
    final container = tester.widget<AnimatedContainer>(find
        .descendant(
            of: find.byType(KitoButton),
            matching: find.byType(AnimatedContainer))
        .first);
    final deco = container.decoration! as BoxDecoration;
    expect(deco.borderRadius, BorderRadius.circular(0));
  });

  testWidgets('Material buttons can wear Kito chrome', (tester) async {
    late ButtonStyle style;
    await tester.pumpWidget(host(Builder(builder: (context) {
      style = KitoButtonStyles.material(context,
          variant: KitoButtonVariant.outlined, size: KitoButtonSize.large);
      return FilledButton(
          style: style, onPressed: () {}, child: const Text('Save'));
    })));
    expect(find.text('Save'), findsOneWidget);
    expect(style.minimumSize!.resolve({})!.height, 56);
    expect(style.side!.resolve({}), isNot(BorderSide.none));
    final disabledBg = style.backgroundColor!.resolve({WidgetState.disabled})!;
    expect(disabledBg.a, lessThanOrEqualTo(1));
  });
}
