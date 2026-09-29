// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A tappable region for the kit's custom controls: keyboard focus and activation, a hand
/// cursor, button semantics and, unless [pressEffect] is off, the Kito press shrink.
///
/// Internal to the kit; not exported.
class KitoModalTapTarget extends StatefulWidget {
  /// Creates a tap target.
  const KitoModalTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.pressEffect = true,
    this.pressScale = 0.96,
    this.highlight,
    this.highlightRadius,
  });

  /// What's tappable.
  final Widget child;

  /// Called on tap, Enter or Space; null disables the target.
  final VoidCallback? onTap;

  /// Overrides the label read by screen readers.
  final String? semanticLabel;

  /// What happens on activation, read after the label.
  final String? semanticHint;

  /// Shrinks the child while pressed.
  final bool pressEffect;

  /// The pressed size, as a fraction.
  final double pressScale;

  /// A fill shown behind the child while pressed or focused, for list rows.
  final Color? highlight;

  /// Corner radius of [highlight].
  final BorderRadius? highlightRadius;

  @override
  State<KitoModalTapTarget> createState() => _KitoModalTapTargetState();
}

class _KitoModalTapTargetState extends State<KitoModalTapTarget> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    Widget child = widget.child;
    final highlight = widget.highlight;
    if (highlight != null) {
      child = AnimatedContainer(
        duration: KitoMotion.of(context, context.kito.motion.fast),
        decoration: BoxDecoration(
          color:
              _pressed || _focused ? highlight : highlight.withValues(alpha: 0),
          borderRadius: widget.highlightRadius,
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
        enabled: enabled,
        label: widget.semanticLabel,
        hint: widget.semanticHint,
        onTap: widget.onTap,
        excludeSemantics: widget.semanticLabel != null,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => widget.onTap?.call()),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A colour that reads on [fill]: white on dark fills, near-black on light ones.
Color kitoModalReadableOn(Color fill) =>
    ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0B0B0F);
