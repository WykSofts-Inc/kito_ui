// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'button_theme.dart';
import 'button_types.dart';

/// Kito chrome for plain Material buttons, when you want the look without [KitoButton]:
///
/// ```dart
/// FilledButton(
///   style: KitoButtonStyles.material(context, variant: KitoButtonVariant.outlined),
///   onPressed: save,
///   child: const Text('Save'),
/// )
/// ```
abstract final class KitoButtonStyles {
  /// A Material [ButtonStyle] matching a [KitoButton] of [variant] and [size].
  static ButtonStyle material(
    BuildContext context, {
    KitoButtonVariant variant = KitoButtonVariant.primary,
    KitoButtonSize size = KitoButtonSize.medium,
    bool expand = false,
    Color? tint,
  }) {
    final kito = context.kito;
    final theme = KitoButtonTheme.of(context);
    final isLink = variant == KitoButtonVariant.link;
    final rest = theme.colorsFor(variant, kito, tintOverride: tint);
    final disabled = theme.colorsForState(variant, kito,
        enabled: false, phase: KitoButtonPhase.idle, tintOverride: tint);
    final fadesWhenDisabled =
        theme.disabledStyle == KitoButtonDisabledStyle.faded;

    Color fade(Color c) => fadesWhenDisabled
        ? c.withValues(alpha: c.a * theme.disabledOpacity)
        : c;

    return ButtonStyle(
      animationDuration: kito.motion.fast,
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      tapTargetSize: MaterialTapTargetSize.padded,
      minimumSize: WidgetStatePropertyAll(Size(
          expand && !isLink ? double.infinity : 0, isLink ? 0 : size.height)),
      padding: WidgetStatePropertyAll(EdgeInsetsDirectional.symmetric(
          horizontal: isLink ? 0 : size.horizontalPadding)),
      textStyle: WidgetStatePropertyAll(theme.textStyleFor(size).copyWith(
          decoration: isLink && theme.underlinesLink
              ? TextDecoration.underline
              : null)),
      iconSize: WidgetStatePropertyAll(size.iconSize),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: (theme.shape).radiusFor(size.height))),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return fade(disabled.background);
        }
        if (states.contains(WidgetState.pressed)) return rest.pressedBackground;
        return rest.background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return fade(disabled.foreground);
        }
        return rest.foreground;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return fade(disabled.foreground);
        }
        return rest.foreground;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final c = states.contains(WidgetState.disabled)
            ? fade(disabled.border)
            : rest.border;
        return c.a == 0
            ? BorderSide.none
            : BorderSide(color: c, width: theme.borderWidth);
      }),
    );
  }
}
