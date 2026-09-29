// Copyright © 2026 wyksoftsinc.com. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

void main() {
  test('the spring settles at 1 and overshoots on the way', () {
    const spring = KitoSpringCurve();
    expect(spring.transform(0), 0);
    expect(spring.transform(1), 1);
    final samples = [for (var i = 1; i < 100; i++) spring.transform(i / 100)];
    expect(samples.any((v) => v > 1), isTrue);
    expect(samples.last, closeTo(1, 0.02));
  });

  test('onAccent picks a readable colour for a tint', () {
    expect(KitoTheme.light.onAccent(Colors.black), Colors.white);
    expect(KitoTheme.light.onAccent(Colors.yellow), Colors.black);
    expect(KitoTheme.light.onAccent(null), KitoColors.light.onPrimary);
  });

  test('lerp blends colours', () {
    final mid = KitoTheme.light.lerp(KitoTheme.dark, 0.5);
    expect(mid.colors.primary,
        Color.lerp(KitoColors.light.primary, KitoColors.dark.primary, 0.5));
  });

  testWidgets('of() returns the installed theme, or the brightness default',
      (tester) async {
    late KitoTheme found;
    await tester.pumpWidget(MaterialApp(
      theme: KitoTheme.neon.toThemeData(),
      home: Builder(builder: (context) {
        found = context.kito;
        return const SizedBox();
      }),
    ));
    expect(found.colors.primary, KitoColors.neon.primary);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(platformBrightness: Brightness.dark),
      child: Builder(builder: (context) {
        found = KitoTheme.of(context);
        return const SizedBox();
      }),
    ));
    expect(found.brightness, Brightness.dark);
  });

  testWidgets('surfaces render every background kind', (tester) async {
    for (final background in [
      const KitoBackground.color(Colors.red),
      const KitoBackground.gradient(KitoGradient.sunset),
      const KitoBackground.glass(),
    ]) {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: KitoSurface(
            background: background,
            child: const SizedBox(width: 10, height: 10)),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
