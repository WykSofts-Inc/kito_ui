// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_formatting/kito_ui_formatting.dart';

Widget host(Widget child,
        {TextDirection direction = TextDirection.ltr,
        bool reduceMotion = false,
        Locale? locale}) =>
    MaterialApp(
      home: Builder(builder: (context) {
        Widget body = Directionality(
            textDirection: direction,
            child: Scaffold(body: Center(child: child)));
        if (locale != null) {
          body = Localizations.override(
              context: context, locale: locale, child: body);
        }
        return MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: body,
        );
      }),
    );

void main() {
  group('rolling number', () {
    testWidgets('rolls only the characters that change', (tester) async {
      await tester.pumpWidget(host(const KitoFormattedNumberText(1250)));
      expect(find.text('1'), findsOneWidget);
      expect(find.text(','), findsOneWidget);
      await tester.pumpWidget(host(const KitoFormattedNumberText(1260)));
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-roll the old 5 and the new 6 are both on screen; the rest stayed put.
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('5'), findsNothing);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('reads as one number and formats it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(KitoFormattedNumberText(
        1250.5,
        format: (v) => KitoMoneyFormatting.string(v, KitoCurrency.kes),
      )));
      expect(find.bySemanticsLabel('KES 1,250.50'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('under Reduce Motion it is plain text', (tester) async {
      await tester.pumpWidget(
          host(const KitoFormattedNumberText(42), reduceMotion: true));
      expect(find.text('42'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsNothing);
    });

    testWidgets('growing a digit keeps the units in place', (tester) async {
      await tester.pumpWidget(host(const KitoFormattedNumberText(999)));
      await tester.pumpWidget(host(const KitoFormattedNumberText(1000)));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('counting number', () {
    testWidgets('counts in from zero, then between values', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const KitoFormattedCountingText(1000)));
      expect(find.text('0'), findsOneWidget);
      expect(find.bySemanticsLabel('1,000'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      final mid = tester.widget<Text>(find.byType(Text)).data!;
      final midValue = int.parse(mid.replaceAll(',', ''));
      expect(midValue, inExclusiveRange(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('1,000'), findsOneWidget);

      await tester.pumpWidget(host(const KitoFormattedCountingText(500)));
      await tester.pump(const Duration(milliseconds: 200));
      final down = int.parse(
          tester.widget<Text>(find.byType(Text)).data!.replaceAll(',', ''));
      expect(down, inExclusiveRange(500, 1000));
      await tester.pumpAndSettle();
      expect(find.text('500'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('can start at the value, and jumps under Reduce Motion',
        (tester) async {
      await tester.pumpWidget(
          host(const KitoFormattedCountingText(75, startFromZero: false)));
      expect(find.text('75'), findsOneWidget);
      await tester.pumpWidget(
          host(const KitoFormattedCountingText(1200), reduceMotion: true));
      await tester.pump();
      expect(find.text('1,200'), findsOneWidget);
    });
  });

  group('change badge', () {
    testWidgets('colours by trend and reads its direction', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const KitoFormattedChangeBadge(0.124)));
      expect(find.text('+12.4%'), findsOneWidget);
      expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('Up +12.4%'), findsOneWidget);
      final up = tester.widget<Icon>(find.byType(Icon)).color;
      expect(up, KitoColors.light.success);

      await tester.pumpWidget(host(const KitoFormattedChangeBadge(-0.031)));
      expect(find.text('−3.1%'), findsOneWidget);
      expect(tester.widget<Icon>(find.byType(Icon)).color,
          KitoColors.light.danger);

      await tester.pumpWidget(
          host(const KitoFormattedChangeBadge(-0.08, invertColors: true)));
      expect(tester.widget<Icon>(find.byType(Icon)).color,
          KitoColors.light.success);

      await tester.pumpWidget(host(const KitoFormattedChangeBadge(0)));
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.byIcon(Icons.east_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('Unchanged 0.0%'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('mirrors its arrow in RTL and localises', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const KitoFormattedChangeBadge(0.2),
          direction: TextDirection.rtl, locale: const Locale('sw')));
      final flip = tester.widget<Transform>(find
          .ancestor(of: find.byType(Icon), matching: find.byType(Transform))
          .first);
      expect(flip.transform.storage[0], -1);
      expect(find.bySemanticsLabel(RegExp('^Juu')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('every style renders', (tester) async {
      for (final style in KitoFormattedChangeBadgeStyle.values) {
        await tester
            .pumpWidget(host(KitoFormattedChangeBadge(0.05, style: style)));
        await tester.pumpAndSettle();
        expect(find.text('+5.0%'), findsOneWidget);
      }
      final solid = tester.widget<Icon>(find.byType(Icon));
      expect(solid.color, Colors.white);
    });
  });

  testWidgets('the phone formatter groups a TextField as you type',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        inputFormatters: [KitoKenyanPhoneInputFormatter()],
      ),
    )));
    await tester.enterText(find.byType(TextField), '0712345678');
    expect(controller.text, '0712 345 678');
    expect(KitoKenyanPhoneNumber.tryParse(controller.text)?.carrier,
        KitoKenyanCarrier.safaricom);
  });
}
