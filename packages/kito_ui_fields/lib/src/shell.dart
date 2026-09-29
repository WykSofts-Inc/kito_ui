// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'resize.dart';
import 'theme.dart';

/// The chrome every Kito field shares: label, bordered (or filled, underlined…) row with
/// leading and trailing accessories, a floating label, focus glow, a shake when an error
/// appears, animated error and helper text, a counter and a footer.
///
/// The built-in fields use it; build your own composite field on it by passing any [input].
class KitoFieldShell extends StatefulWidget {
  /// Wraps [input] in field chrome.
  const KitoFieldShell({
    super.key,
    required this.input,
    this.label,
    this.leading,
    this.trailing,
    this.helper,
    this.error,
    this.counter,
    this.footer,
    this.isFocused = false,
    this.isEmpty = true,
    this.isEnabled = true,
    this.isSuccess = false,
    this.isRequired = false,
    this.tint,
    this.theme,
    this.onTap,
  });

  /// The editable part (usually a borderless `TextField`).
  final Widget input;

  /// The label; above the row, or inside it for [KitoFieldStyle.floatingLabel].
  final String? label;

  /// Before the input: an icon, a country picker, a currency symbol.
  final Widget? leading;

  /// After the input: a clear button, reveal toggle, spinner or badge.
  final Widget? trailing;

  /// Quiet text under the field, replaced by [error] when there is one.
  final String? helper;

  /// The error to show; null when valid (or not yet revealed).
  final String? error;

  /// Text at the end of the message line, e.g. "42/280".
  final Widget? counter;

  /// Extra content under the messages: a strength meter, a checklist.
  final Widget? footer;

  /// Draws the focused state.
  final bool isFocused;

  /// Whether the input is empty (keeps a floating label down).
  final bool isEmpty;

  /// Dims the field when false.
  final bool isEnabled;

  /// Draws the success state (border and tick) when the theme allows it.
  final bool isSuccess;

  /// Adds " *" to the label.
  final bool isRequired;

  /// Overrides the focus colour.
  final Color? tint;

  /// Overrides the scope's [KitoFieldTheme].
  final KitoFieldTheme? theme;

  /// Runs when the chrome around the input is tapped (focus the input here).
  final VoidCallback? onTap;

  @override
  State<KitoFieldShell> createState() => _KitoFieldShellState();
}

class _KitoFieldShellState extends State<KitoFieldShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(KitoFieldShell old) {
    super.didUpdateWidget(old);
    final fieldTheme = widget.theme ?? KitoFieldTheme.of(context);
    if (old.error == null &&
        widget.error != null &&
        fieldTheme.shakesOnError &&
        !context.reduceMotion) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final ft = widget.theme ?? KitoFieldTheme.of(context);
    final accent = kito.accent(widget.tint);
    final hasError = widget.error != null;
    final success = widget.isSuccess && ft.showsSuccess && !hasError;
    final floating = ft.style == KitoFieldStyle.floatingLabel;
    final fast = KitoMotion.of(context, kito.motion.fast);
    final medium = KitoMotion.of(context, kito.motion.medium);

    final borderColor = hasError
        ? kito.colors.danger
        : widget.isFocused
            ? accent
            : success
                ? kito.colors.success
                : kito.colors.border;
    final strong = widget.isFocused || hasError;
    final width = strong ? ft.focusedBorderWidth : ft.borderWidth;
    final radius = ft.radius ?? kito.radii.md;

    final Color fill = switch (ft.style) {
      KitoFieldStyle.outlined ||
      KitoFieldStyle.floatingLabel =>
        kito.colors.surface,
      KitoFieldStyle.filled => kito.colors.surfaceMuted,
      KitoFieldStyle.underlined || KitoFieldStyle.plain => Colors.transparent,
    };
    final Border? border = switch (ft.style) {
      KitoFieldStyle.outlined ||
      KitoFieldStyle.floatingLabel =>
        Border.all(color: borderColor, width: width),
      KitoFieldStyle.filled => Border.all(
          color: strong || success ? borderColor : Colors.transparent,
          width: width),
      KitoFieldStyle.underlined =>
        Border(bottom: BorderSide(color: borderColor, width: width)),
      KitoFieldStyle.plain => null,
    };
    final rounded = ft.style != KitoFieldStyle.underlined &&
        ft.style != KitoFieldStyle.plain;
    final glow = ft.showsFocusGlow && rounded && (widget.isFocused || hasError);
    final glowColor = hasError ? kito.colors.danger : accent;

    final labelColor = hasError
        ? kito.colors.danger
        : widget.isFocused
            ? accent
            : kito.colors.onSurface.withValues(alpha: 0.75);
    final labelText = widget.label == null
        ? null
        : widget.isRequired
            ? '${widget.label} *'
            : widget.label!;

    Widget inputArea = widget.input;
    if (floating && labelText != null) {
      final up = widget.isFocused || !widget.isEmpty;
      inputArea = Stack(
        children: [
          Padding(padding: const EdgeInsets.only(top: 16), child: widget.input),
          PositionedDirectional(
            start: 0,
            end: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedAlign(
                  duration: medium,
                  curve: kito.motion.standard,
                  alignment: up
                      ? AlignmentDirectional.topStart
                      : AlignmentDirectional.centerStart,
                  child: AnimatedDefaultTextStyle(
                    duration: medium,
                    curve: kito.motion.standard,
                    style: (up ? kito.typography.caption : kito.typography.body)
                        .copyWith(
                            color: up
                                ? labelColor
                                : kito.colors.onSurface.withValues(alpha: 0.5)),
                    child: Padding(
                      padding: EdgeInsets.only(top: up ? 0 : 16),
                      child: Text(labelText,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final trailing = [
      if (widget.trailing != null) widget.trailing!,
      AnimatedSwitcher(
        duration: medium,
        transitionBuilder: (child, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: kito.motion.spring),
            child: child),
        child: success
            ? Padding(
                key: const ValueKey('tick'),
                padding: const EdgeInsetsDirectional.only(start: 6),
                child: Icon(Icons.check_circle_rounded,
                    size: 20, color: kito.colors.success),
              )
            : const SizedBox.shrink(key: ValueKey('none')),
      ),
    ];

    final chrome = AnimatedContainer(
      // A new container per style, so a rounded box never lerps into an underline.
      key: ValueKey(ft.style),
      duration: fast,
      curve: kito.motion.standard,
      constraints: BoxConstraints(
          minHeight: math.max(
              44, floating ? math.max(ft.minHeight, 58) : ft.minHeight)),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: rounded ? BorderRadius.circular(radius) : null,
        boxShadow: glow
            ? [
                BoxShadow(
                    color: glowColor.withValues(alpha: 0.14),
                    blurRadius: 0,
                    spreadRadius: 3.5),
              ]
            : const [],
      ),
      foregroundDecoration: BoxDecoration(
        border: border,
        borderRadius: rounded ? BorderRadius.circular(radius) : null,
      ),
      padding: ft.style == KitoFieldStyle.plain
          ? EdgeInsets.zero
          : ft.contentPadding,
      child: Row(
        children: [
          if (widget.leading != null) ...[
            IconTheme.merge(
              data: IconThemeData(
                  color: widget.isFocused
                      ? accent
                      : kito.colors.onSurface.withValues(alpha: 0.55),
                  size: 20),
              child: widget.leading!,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: inputArea),
          ...trailing,
        ],
      ),
    );

    final shaken = AnimatedBuilder(
      animation: _shake,
      child: chrome,
      builder: (context, child) {
        final t = _shake.value;
        final dx =
            t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi * 6) * 7 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );

    final message = widget.error ?? widget.helper;
    final messageRow = (message == null && widget.counter == null)
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, start: 2, end: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: medium,
                    switchInCurve: kito.motion.standard,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: AlignmentDirectional.topStart,
                      children: [...previous, if (current != null) current],
                    ),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, -0.35), end: Offset.zero)
                            .animate(a),
                        child: child,
                      ),
                    ),
                    child: message == null
                        ? const SizedBox.shrink(key: ValueKey('empty'))
                        : Row(
                            key: ValueKey('${hasError ? 'e' : 'h'}:$message'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasError && ft.showsErrorIcon) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(Icons.error_rounded,
                                      size: 14, color: kito.colors.danger),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  message,
                                  style: kito.typography.caption.copyWith(
                                      color: hasError
                                          ? kito.colors.danger
                                          : kito.colors.onSurface
                                              .withValues(alpha: 0.6)),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (widget.counter != null) ...[
                  const SizedBox(width: 8),
                  widget.counter!,
                ],
              ],
            ),
          );

    return AnimatedOpacity(
      opacity: widget.isEnabled ? 1 : ft.disabledOpacity,
      duration: fast,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (labelText != null && !floating)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 6, start: 2),
              child: ExcludeSemantics(
                child: AnimatedDefaultTextStyle(
                  duration: fast,
                  style: kito.typography.label.copyWith(color: labelColor),
                  child: Text(labelText),
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.isEnabled ? widget.onTap : null,
            child: shaken,
          ),
          FieldResize(
            duration: medium,
            curve: kito.motion.standard,
            alignment: AlignmentDirectional.topStart,
            // The field reads its error and helper as its hint, so they aren't read twice.
            child: ExcludeSemantics(child: messageRow),
          ),
          if (widget.footer != null)
            Padding(
                padding: const EdgeInsets.only(top: 8), child: widget.footer!),
        ],
      ),
    );
  }
}
