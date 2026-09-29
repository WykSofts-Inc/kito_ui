// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_buttons/kito_ui_buttons.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

void main() {
  const kito = KitoTheme.light;
  const theme = KitoButtonTheme.standard;

  group('colours', () {
    test('primary follows the Kito theme', () {
      final c = theme.colorsFor(KitoButtonVariant.primary, kito);
      expect(c.background, kito.colors.primary);
      expect(c.foreground, kito.colors.onPrimary);
      expect(c.pressedBackground, isNot(c.background));
    });

    test('a tint override recolours and picks a readable foreground', () {
      final c = theme.colorsFor(KitoButtonVariant.primary, kito,
          tintOverride: Colors.yellow);
      expect(c.background, Colors.yellow);
      expect(c.foreground, Colors.black);
    });

    test('tonal, outlined, ghost, link and destructive', () {
      final tonal = theme.colorsFor(KitoButtonVariant.tonal, kito);
      expect(tonal.background.a, closeTo(0.14, 0.01));
      expect(tonal.foreground, kito.colors.primary);

      final outlined = theme.colorsFor(KitoButtonVariant.outlined, kito);
      expect(outlined.hasBorder, isTrue);
      expect(outlined.background.a, 0);

      expect(theme.colorsFor(KitoButtonVariant.ghost, kito).hasBorder, isFalse);
      expect(
          theme.colorsFor(KitoButtonVariant.link, kito).pressedBackground.a, 0);
      expect(theme.colorsFor(KitoButtonVariant.destructive, kito).background,
          kito.colors.danger);
    });

    test('overrides win', () {
      final custom =
          KitoButtonColors(background: Colors.black, foreground: Colors.yellow);
      final t = KitoButtonTheme(overrides: {KitoButtonVariant.primary: custom});
      expect(t.colorsFor(KitoButtonVariant.primary, kito), custom);
    });

    test('explicit theme colours replace the Kito ones', () {
      const t = KitoButtonTheme(tint: Colors.indigo, destructive: Colors.pink);
      expect(t.colorsFor(KitoButtonVariant.primary, kito).background,
          Colors.indigo);
      expect(t.colorsFor(KitoButtonVariant.primary, kito).foreground,
          Colors.white);
      expect(t.colorsFor(KitoButtonVariant.destructive, kito).background,
          Colors.pink);
    });

    test('success and failure recolour each variant', () {
      final success = theme.colorsForState(KitoButtonVariant.primary, kito,
          enabled: true, phase: KitoButtonPhase.success);
      expect(success.background, kito.colors.success);

      final failure = theme.colorsForState(KitoButtonVariant.outlined, kito,
          enabled: true, phase: KitoButtonPhase.failure);
      expect(failure.border, kito.colors.danger);
      expect(failure.foreground, kito.colors.danger);

      final ghost = theme.colorsForState(KitoButtonVariant.ghost, kito,
          enabled: true, phase: KitoButtonPhase.success);
      expect(ghost.foreground, kito.colors.success);
    });

    test('disabled styles', () {
      final base = theme.colorsFor(KitoButtonVariant.primary, kito);
      expect(
          theme.colorsForState(KitoButtonVariant.primary, kito,
              enabled: false, phase: KitoButtonPhase.idle),
          base);
      final filled = theme.colorsForState(KitoButtonVariant.primary, kito,
          enabled: false,
          phase: KitoButtonPhase.idle,
          disabledStyle: const KitoButtonDisabledStyle.filled(
              background: Colors.grey, foreground: Colors.white));
      expect(filled.background, Colors.grey);
      final outlined = theme.colorsForState(KitoButtonVariant.primary, kito,
          enabled: false,
          phase: KitoButtonPhase.idle,
          disabledStyle: KitoButtonDisabledStyle.outlined);
      expect(outlined.background.a, 0);
      expect(outlined.hasBorder, isTrue);
      expect(outlined.foreground, isNot(kito.colors.onPrimary));
    });

    test('loading colours apply only when set', () {
      const t = KitoButtonTheme(
          loadingBackground: Colors.grey, loadingForeground: Colors.white);
      final c = t.colorsForState(KitoButtonVariant.primary, kito,
          enabled: true, phase: KitoButtonPhase.loading);
      expect(c.background, Colors.grey);
      expect(c.foreground, Colors.white);
      expect(
          theme.colorsForState(KitoButtonVariant.primary, kito,
              enabled: true, phase: KitoButtonPhase.loading),
          theme.colorsFor(KitoButtonVariant.primary, kito));
    });

    test('opacity for disabled and pressed states', () {
      expect(
          theme.opacityFor(
              enabled: false, phase: KitoButtonPhase.idle, pressed: false),
          theme.disabledOpacity);
      expect(
          theme.opacityFor(
              enabled: false,
              phase: KitoButtonPhase.idle,
              pressed: false,
              disabledStyle: KitoButtonDisabledStyle.outlined),
          1);
      expect(
          theme.opacityFor(
              enabled: true, phase: KitoButtonPhase.idle, pressed: true),
          theme.pressedOpacity);
      expect(
          theme.opacityFor(
              enabled: true,
              phase: KitoButtonPhase.idle,
              pressed: true,
              pressedStyle: KitoButtonPressedStyle.darken),
          1);
    });

    test('colour sets lerp', () {
      final a =
          KitoButtonColors(background: Colors.black, foreground: Colors.white);
      final b =
          KitoButtonColors(background: Colors.white, foreground: Colors.black);
      expect(KitoButtonColors.lerp(a, b, 0), a);
      expect(KitoButtonColors.lerp(a, b, 1).background, Colors.white);
    });
  });

  group('metrics', () {
    test('shapes resolve radii', () {
      expect(KitoButtonShape.capsule.cornerFor(48), 24);
      expect(KitoButtonShape.rectangle.cornerFor(48), 0);
      expect(KitoButtonShape.rounded.cornerFor(48), 12);
      expect(const KitoButtonShape.roundedRectangle(100).cornerFor(40), 20);
      expect(const KitoButtonShape.roundedRectangle(8),
          const KitoButtonShape.roundedRectangle(8));
    });

    test('sizes', () {
      expect(KitoButtonSize.small.isCompact, isTrue);
      expect(KitoButtonSize.medium.isCompact, isFalse);
      expect(KitoButtonSize.large.height, 56);
      expect(const KitoButtonSize.custom(height: 52),
          const KitoButtonSize.custom(height: 52));
      expect(const KitoButtonSize.custom(height: 52),
          isNot(const KitoButtonSize.custom(height: 50)));
      expect(KitoButtonSize.medium.toString(), 'KitoButtonSize.medium');
    });

    test('theme text style merges over the size style', () {
      const t = KitoButtonTheme(textStyle: TextStyle(fontFamily: 'Inter'));
      final s = t.textStyleFor(KitoButtonSize.large);
      expect(s.fontFamily, 'Inter');
      expect(s.fontSize, KitoButtonSize.large.textStyle.fontSize);
    });

    test('phase busy flag', () {
      expect(KitoButtonPhase.loading.isBusy, isTrue);
      expect(KitoButtonPhase.success.isBusy, isFalse);
    });

    test('motion copyWith and presets', () {
      final m = KitoButtonMotion.standard
          .copyWith(resultDuration: const Duration(seconds: 2));
      expect(m.resultDuration, const Duration(seconds: 2));
      expect(m.morphDuration, KitoButtonMotion.standard.morphDuration);
      expect(KitoButtonMotion.subtle.flightDuration,
          lessThan(KitoButtonMotion.standard.flightDuration));
    });

    test('theme copyWith and lerp', () {
      final t = theme.copyWith(borderWidth: 3, shape: KitoButtonShape.rounded);
      expect(t.borderWidth, 3);
      expect(t.shape, KitoButtonShape.rounded);
      expect(theme.lerp(t, 0.5).borderWidth, closeTo(2.25, 0.001));
      expect(theme.lerp(null, 0.5), theme);
    });
  });

  group('easing and effects', () {
    test('segments clamp', () {
      expect(KitoButtonEase.segment(0.1, 0.2, 0.4), 0);
      expect(KitoButtonEase.segment(0.3, 0.2, 0.4), closeTo(0.5, 1e-9));
      expect(KitoButtonEase.segment(0.9, 0.2, 0.4), 1);
      expect(KitoButtonEase.segment(0.5, 0.5, 0.5), 1);
    });

    test('curves start at 0 and end at 1', () {
      for (final f in <double Function(double)>[
        KitoButtonEase.outCubic,
        KitoButtonEase.inCubic,
        KitoButtonEase.inOutCubic,
        KitoButtonEase.outBack,
        KitoButtonEase.outBounce,
      ]) {
        expect(f(0), closeTo(0, 1e-9));
        expect(f(1), closeTo(1, 1e-9));
      }
      expect(KitoButtonEase.pulse(0.5), closeTo(1, 1e-9));
      expect(KitoButtonEase.lerp(10, 20, 0.5), 15);
    });

    test('shake and bounce rest at their origin', () {
      expect(KitoButtonShake.offsetAt(0, 8), 0);
      expect(KitoButtonShake.offsetAt(1, 8), closeTo(0, 1e-9));
      expect(KitoButtonShake.offsetAt(0.125, 8), greaterThan(0));
      expect(KitoButtonBounce.scaleAt(0, 1.3), 1);
      expect(KitoButtonBounce.scaleAt(1, 1.3), 1);
      expect(KitoButtonBounce.scaleAt(0.28, 1.3), closeTo(1.3, 0.001));
    });

    test('the flight arc starts, peaks above and lands', () {
      const a = Offset(0, 200), b = Offset(300, 100);
      expect(KitoFlightController.arcPoint(a, b, 120, 0), a);
      expect(KitoFlightController.arcPoint(a, b, 120, 1), b);
      final mid = KitoFlightController.arcPoint(a, b, 120, 0.5);
      expect(mid.dy, lessThan(100));
    });

    test('badge text caps at the max', () {
      expect(KitoBadgeButton.badgeText(7), '7');
      expect(KitoBadgeButton.badgeText(150), '99+');
      expect(KitoBadgeButton.badgeText(12, maxCount: 9), '9+');
      expect(KitoBadgeButton.badgeText(3, format: (n) => '<$n>'), '<3>');
    });

    test('every cart animation lands inside its timeline', () {
      for (final a in KitoAddToCartAnimation.values) {
        expect(a.landingPoint, inExclusiveRange(0, 1));
        expect(a.defaultDuration, greaterThan(Duration.zero));
        expect(a.title, isNotEmpty);
      }
    });
  });

  group('strings', () {
    tearDown(() => KitoButtonStrings.provider = null);

    test('bundled languages share the same keys', () {
      final en = KitoButtonStrings.bundled['en']!.keys.toSet();
      for (final lang in KitoButtonStrings.bundled.values) {
        expect(lang.keys.toSet(), en);
      }
    });

    test('lookup falls back to English and honours the provider', () {
      expect(KitoButtonStrings.lookup('phase.loading', const Locale('sw')),
          'Inapakia');
      expect(
          KitoButtonStrings.lookup('cart.added', const Locale('fr')), 'Ajouté');
      expect(
          KitoButtonStrings.lookup('cart.added', const Locale('de')), 'Added');
      KitoButtonStrings.provider =
          (key, locale) => key == 'cart.added' ? 'Imo' : null;
      expect(KitoButtonStrings.lookup('cart.added', const Locale('en')), 'Imo');
      expect(KitoButtonStrings.lookup('cart.adding', const Locale('en')),
          'Adding');
    });
  });
}
