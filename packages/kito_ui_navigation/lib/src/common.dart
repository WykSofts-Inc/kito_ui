// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A tappable region for the kit's controls: keyboard focus and activation, a hand cursor,
/// merged button semantics and the Kito press shrink.
///
/// Internal to the kit; not exported.
class KitoNavTapTarget extends StatefulWidget {
  /// Creates a tap target.
  const KitoNavTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.semanticValue,
    this.selected,
    this.inGroup = false,
    this.pressScale = 0.96,
    this.pressEffect = true,
    this.focusRadius,
  });

  /// What's tappable.
  final Widget child;

  /// Called on tap, Enter or Space; null disables it.
  final VoidCallback? onTap;

  /// Replaces the label built from the child's text.
  final String? semanticLabel;

  /// Read after the label, e.g. a badge.
  final String? semanticValue;

  /// Selected state, for tabs.
  final bool? selected;

  /// Part of a set where one is selected (tabs).
  final bool inGroup;

  /// The pressed size, as a fraction.
  final double pressScale;

  /// Shrinks while pressed.
  final bool pressEffect;

  /// Draws a focus ring with this radius when focused from the keyboard.
  final BorderRadius? focusRadius;

  @override
  State<KitoNavTapTarget> createState() => _KitoNavTapTargetState();
}

class _KitoNavTapTargetState extends State<KitoNavTapTarget> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    Widget child = widget.child;
    if (widget.focusRadius != null) {
      child = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.focusRadius,
          border: _focused
              ? Border.all(color: context.kito.colors.primary, width: 2)
              : null,
        ),
        child: child,
      );
    }
    if (widget.pressEffect) {
      child = KitoPressable(
          enabled: enabled, scale: widget.pressScale, child: child);
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: widget.selected,
        inMutuallyExclusiveGroup: widget.inGroup ? true : null,
        enabled: enabled,
        label: widget.semanticLabel,
        value: widget.semanticValue,
        onTap: widget.onTap,
        excludeSemantics: widget.semanticLabel != null,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => widget.onTap?.call()),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The text colour a drawer part should use: the surrounding text colour, or the theme's
/// on-surface colour.
Color kitoNavForeground(BuildContext context) =>
    DefaultTextStyle.of(context).style.color ?? context.kito.colors.onSurface;

/// A colour that reads on [fill].
Color kitoNavReadableOn(Color fill) =>
    ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0B0B0F);
