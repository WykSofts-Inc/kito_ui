// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'button_motion.dart';
import 'button_primitives.dart';
import 'button_strings.dart';
import 'button_theme.dart';
import 'button_types.dart';
import 'flight.dart';

/// A tap handler. Return a [Future] and the button shows a spinner until it completes.
typedef KitoButtonAction = FutureOr<void> Function();

/// Drives or observes a [KitoButton]'s phase from outside — set `success` after a websocket
/// acknowledgement, say.
class KitoButtonController extends ValueNotifier<KitoButtonPhase> {
  /// Creates a controller, idle by default.
  KitoButtonController([super.value = KitoButtonPhase.idle]);
}

/// The Kito button: six variants, three sizes, icons, async loading → success / failure phases
/// with icon morphing, content slots and fly-to-target hooks.
///
/// ```dart
/// KitoButton(
///   label: 'Add to cart',
///   icon: const Icon(Icons.add_shopping_cart_rounded),
///   showSuccess: true,
///   showFailure: true,
///   successLabel: 'Added',
///   onPressed: () async => cart.add(product),   // spinner → tick, or shake + cross on error
/// )
/// ```
///
/// A null [onPressed] disables the button.
class KitoButton extends StatefulWidget {
  /// A button with a label and an optional icon.
  const KitoButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.iconPlacement = KitoButtonIconPlacement.leading,
    this.variant = KitoButtonVariant.primary,
    this.size = KitoButtonSize.medium,
    this.expand = false,
    this.tint,
    this.loading,
    this.controller,
    this.showSuccess = false,
    this.showFailure = false,
    this.successLabel,
    this.failureLabel,
    this.successIcon = Icons.check_rounded,
    this.failureIcon = Icons.close_rounded,
    this.haptics = true,
    this.semanticLabel,
    this.semanticHint,
    this.leading,
    this.trailing,
    this.subtitle,
    this.contentAlignment = KitoButtonContentAlignment.center,
    this.shape,
    this.minWidth,
    this.padding,
    this.disabledStyle,
    this.pressedStyle,
    this.flight,
    this.focusNode,
    this.autofocus = false,
    this.onError,
    this.onPhaseChanged,
  })  : child = null,
        _iconOnly = false;

  /// A square, icon-only button. [semanticLabel] is what screen readers announce.
  const KitoButton.icon({
    super.key,
    required Widget this.icon,
    required String this.semanticLabel,
    required this.onPressed,
    this.variant = KitoButtonVariant.primary,
    this.size = KitoButtonSize.medium,
    this.tint,
    this.loading,
    this.controller,
    this.showSuccess = false,
    this.showFailure = false,
    this.successIcon = Icons.check_rounded,
    this.failureIcon = Icons.close_rounded,
    this.haptics = true,
    this.semanticHint,
    this.shape,
    this.disabledStyle,
    this.pressedStyle,
    this.flight,
    this.focusNode,
    this.autofocus = false,
    this.onError,
    this.onPhaseChanged,
  })  : label = null,
        child = null,
        iconPlacement = KitoButtonIconPlacement.leading,
        expand = false,
        successLabel = null,
        failureLabel = null,
        leading = null,
        trailing = null,
        subtitle = null,
        contentAlignment = KitoButtonContentAlignment.center,
        minWidth = null,
        padding = null,
        _iconOnly = true;

  /// A button whose whole content is [child]. Phase chrome (spinner, shake, success/failure
  /// colours) still wraps around it. Screen readers read [child] unless [semanticLabel] is set.
  const KitoButton.custom({
    super.key,
    required Widget this.child,
    required this.onPressed,
    this.variant = KitoButtonVariant.primary,
    this.size = KitoButtonSize.medium,
    this.expand = false,
    this.tint,
    this.loading,
    this.controller,
    this.showSuccess = false,
    this.showFailure = false,
    this.haptics = true,
    this.semanticLabel,
    this.semanticHint,
    this.shape,
    this.minWidth,
    this.padding,
    this.disabledStyle,
    this.pressedStyle,
    this.flight,
    this.focusNode,
    this.autofocus = false,
    this.onError,
    this.onPhaseChanged,
  })  : label = null,
        icon = null,
        iconPlacement = KitoButtonIconPlacement.leading,
        successLabel = null,
        failureLabel = null,
        successIcon = Icons.check_rounded,
        failureIcon = Icons.close_rounded,
        leading = null,
        trailing = null,
        subtitle = null,
        contentAlignment = KitoButtonContentAlignment.center,
        _iconOnly = false;

  /// The title.
  final String? label;

  /// Called on tap. Return a [Future] to get the automatic loading phase. Null disables.
  final KitoButtonAction? onPressed;

  /// An icon, usually an [Icon]; it takes the variant's colour and the size's icon size.
  final Widget? icon;

  /// Which side of the label the icon sits on.
  final KitoButtonIconPlacement iconPlacement;

  /// Visual weight.
  final KitoButtonVariant variant;

  /// Metrics.
  final KitoButtonSize size;

  /// Fill the available width.
  final bool expand;

  /// Replaces the theme's brand colour for this button.
  final Color? tint;

  /// Forces the spinner on or off, overriding the automatic async phase.
  final bool? loading;

  /// Drives the phase from outside.
  final KitoButtonController? controller;

  /// After an async action succeeds, morph to a tick before returning to idle.
  final bool showSuccess;

  /// After an async action throws, shake and show a cross before returning to idle.
  final bool showFailure;

  /// Title during the success phase ("Added"); the normal label when null.
  final String? successLabel;

  /// Title during the failure phase; the normal label when null.
  final String? failureLabel;

  /// Glyph during the success phase.
  final IconData successIcon;

  /// Glyph during the failure phase.
  final IconData failureIcon;

  /// Tap and result haptics.
  final bool haptics;

  /// What screen readers announce; the label when null.
  final String? semanticLabel;

  /// A screen-reader hint, read after the label ("Double tap to pay").
  final String? semanticHint;

  /// Content before the label, replacing a leading icon (a flag, a composed view).
  final Widget? leading;

  /// Content after the label, replacing a trailing icon (a chevron, a price).
  final Widget? trailing;

  /// A second, smaller line under the label.
  final String? subtitle;

  /// Horizontal layout of the content.
  final KitoButtonContentAlignment contentAlignment;

  /// Replaces the theme's shape for this button.
  final KitoButtonShape? shape;

  /// A minimum width beyond the size's own metrics, to line up buttons in a row.
  final double? minWidth;

  /// Replaces the size's horizontal padding.
  final EdgeInsetsGeometry? padding;

  /// Replaces the theme's disabled look for this button.
  final KitoButtonDisabledStyle? disabledStyle;

  /// Replaces the theme's press feedback for this button.
  final KitoButtonPressedStyle? pressedStyle;

  /// On tap, fly something from this button to an anchor (see [KitoFlightController]).
  final KitoFlightRequest? flight;

  /// Keyboard focus.
  final FocusNode? focusNode;

  /// Focus on first build.
  final bool autofocus;

  /// Called when an async action throws. The error is otherwise swallowed (and shown as the
  /// failure phase when [showFailure] is on).
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Called whenever the phase changes.
  final ValueChanged<KitoButtonPhase>? onPhaseChanged;

  /// Custom content; see [KitoButton.custom].
  final Widget? child;

  final bool _iconOnly;

  @override
  State<KitoButton> createState() => _KitoButtonState();
}

class _KitoButtonState extends State<KitoButton> {
  KitoButtonPhase _internalPhase = KitoButtonPhase.idle;
  int _shakes = 0;
  bool _pressed = false;
  bool _focused = false;
  Timer? _resultTimer;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_controllerChanged);
  }

  @override
  void didUpdateWidget(KitoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_controllerChanged);
      widget.controller?.addListener(_controllerChanged);
    }
    if (oldWidget.loading != true && widget.loading == true) _announceLoading();
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    widget.controller?.removeListener(_controllerChanged);
    super.dispose();
  }

  KitoButtonPhase _lastPhase = KitoButtonPhase.idle;

  void _controllerChanged() {
    if (!mounted) return;
    setState(() {});
    _phaseChanged();
  }

  KitoButtonPhase get _phase {
    if (widget.loading == true) return KitoButtonPhase.loading;
    return widget.controller?.value ?? _internalPhase;
  }

  void _setPhase(KitoButtonPhase phase) {
    if (!mounted) return;
    if (widget.controller != null) {
      widget.controller!.value = phase;
    } else {
      setState(() => _internalPhase = phase);
      _phaseChanged();
    }
  }

  void _phaseChanged() {
    final phase = _phase;
    if (phase == _lastPhase) return;
    _lastPhase = phase;
    if (phase == KitoButtonPhase.loading) _announceLoading();
    widget.onPhaseChanged?.call(phase);
  }

  void _announceLoading() {
    final message = KitoButtonStrings.of(context, 'phase.inProgress');
    // ignore: deprecated_member_use
    SemanticsService.announce(message, Directionality.of(context));
  }

  bool get _interactive =>
      widget.onPressed != null && _phase == KitoButtonPhase.idle;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  Future<void> _handleTap() async {
    if (!_interactive) return;
    if (widget.haptics) HapticFeedback.lightImpact();
    widget.flight?.launch(context);
    final FutureOr<void> result;
    try {
      result = widget.onPressed!();
    } catch (error, stack) {
      widget.onError?.call(error, stack);
      _finish(success: false);
      return;
    }
    if (result is! Future<void>) return;
    _resultTimer?.cancel();
    _setPhase(KitoButtonPhase.loading);
    try {
      await result;
      _finish(success: true);
    } catch (error, stack) {
      widget.onError?.call(error, stack);
      _finish(success: false);
    }
  }

  void _finish({required bool success}) {
    if (!mounted) return;
    final shows = success ? widget.showSuccess : widget.showFailure;
    if (!shows) {
      if (_phase == KitoButtonPhase.loading) _setPhase(KitoButtonPhase.idle);
      return;
    }
    _setPhase(success ? KitoButtonPhase.success : KitoButtonPhase.failure);
    if (widget.haptics) {
      success ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    }
    if (!success) setState(() => _shakes++);
    final motion = KitoButtonTheme.of(context).motionFor(context);
    _resultTimer?.cancel();
    _resultTimer = Timer(motion.resultDuration, () {
      if (mounted && _phase != KitoButtonPhase.loading) {
        _setPhase(KitoButtonPhase.idle);
      }
    });
  }

  String? get _displayedLabel => switch (_phase) {
        KitoButtonPhase.success => widget.successLabel ?? widget.label,
        KitoButtonPhase.failure => widget.failureLabel ?? widget.label,
        _ => widget.label,
      };

  String _semanticValue(BuildContext context) => switch (_phase) {
        KitoButtonPhase.idle => '',
        KitoButtonPhase.loading =>
          KitoButtonStrings.of(context, 'phase.loading'),
        KitoButtonPhase.success =>
          KitoButtonStrings.of(context, 'phase.succeeded'),
        KitoButtonPhase.failure =>
          KitoButtonStrings.of(context, 'phase.failed'),
      };

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final theme = KitoButtonTheme.of(context);
    final motion = theme.motionFor(context);
    final reduce = context.reduceMotion;
    final phase = _phase;
    final enabled = widget.onPressed != null;
    final isLink = widget.variant == KitoButtonVariant.link;
    final size = widget.size;
    final pressedStyle = widget.pressedStyle ?? theme.pressedStyle;
    final shape = widget.shape ?? theme.shape;
    final radius = shape.radiusFor(size.height);

    final colors = theme.colorsForState(widget.variant, kito,
        enabled: enabled,
        phase: phase,
        disabledStyle: widget.disabledStyle,
        tintOverride: widget.tint);
    final pressed = _pressed && _interactive;
    final fill = pressed && pressedStyle != KitoButtonPressedStyle.none
        ? colors.pressedBackground
        : colors.background;
    final spinnerColor = theme.loadingForeground ?? colors.foreground;

    final colourDuration = reduce
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 200);

    Widget content = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: colors.foreground),
      duration: colourDuration,
      builder: (context, fg, child) => IconTheme.merge(
        data: IconThemeData(color: fg, size: size.iconSize),
        child: DefaultTextStyle.merge(
          style: theme.textStyleFor(size).copyWith(
                color: fg,
                decoration: isLink && theme.underlinesLink
                    ? TextDecoration.underline
                    : null,
                decorationColor: fg,
              ),
          child: child!,
        ),
      ),
      child: _content(theme, motion),
    );

    content = Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: phase == KitoButtonPhase.loading ? 0 : 1,
          duration: motion.pressDuration,
          child: content,
        ),
        if (phase == KitoButtonPhase.loading)
          KitoButtonSpinner(
              color: spinnerColor,
              size: size.iconSize + 2,
              strokeWidth: size.isCompact ? 2 : 2.4),
      ],
    );

    final fillsRow = (widget.expand || widget.minWidth != null) &&
        widget.contentAlignment != KitoButtonContentAlignment.center;

    Widget chrome = AnimatedContainer(
      duration: colourDuration,
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        minHeight: isLink ? 0 : size.height,
        minWidth: widget.minWidth ?? (widget._iconOnly ? size.height : 0),
      ),
      padding: widget._iconOnly
          ? EdgeInsets.zero
          : widget.padding ??
              EdgeInsetsDirectional.symmetric(
                  horizontal: isLink ? 0 : size.horizontalPadding,
                  vertical: isLink ? 2 : 6),
      decoration: isLink
          ? const BoxDecoration()
          : BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: colors.hasBorder
                  ? Border.all(color: colors.border, width: theme.borderWidth)
                  : null,
              boxShadow: enabled ? theme.shadow : null,
            ),
      foregroundDecoration: _focused
          ? BoxDecoration(
              borderRadius: isLink ? BorderRadius.circular(4) : radius,
              border: Border.all(
                  color: (isLink ? colors.foreground : kito.accent(widget.tint))
                      .withValues(alpha: 0.55),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside),
            )
          : null,
      child: Align(
        alignment:
            fillsRow ? AlignmentDirectional.centerStart : Alignment.center,
        widthFactor: widget.expand && !isLink ? null : 1,
        heightFactor: 1,
        child: content,
      ),
    );

    if (widget.expand && !isLink) {
      chrome = SizedBox(width: double.infinity, child: chrome);
    }

    chrome = AnimatedScale(
      scale: pressed &&
              !isLink &&
              !reduce &&
              pressedStyle == KitoButtonPressedStyle.scale
          ? theme.pressedScale
          : 1,
      duration: pressed ? motion.pressDuration : motion.releaseDuration,
      curve: pressed ? Curves.easeOut : motion.pressCurve,
      child: chrome,
    );

    chrome = AnimatedOpacity(
      opacity: theme.opacityFor(
          enabled: enabled,
          phase: phase,
          pressed: pressed,
          disabledStyle: widget.disabledStyle,
          pressedStyle: pressedStyle),
      duration: motion.pressDuration,
      child: chrome,
    );

    // Compact buttons draw under 44×44; grow the tappable area without growing the chrome.
    if (size.isCompact || isLink) {
      chrome = ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Center(widthFactor: 1, heightFactor: 1, child: chrome),
      );
    }

    chrome = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: _interactive ? (_) => _setPressed(true) : null,
      onTapUp: _interactive ? (_) => _setPressed(false) : null,
      onTapCancel: () => _setPressed(false),
      onTap: _interactive ? _handleTap : null,
      child: chrome,
    );

    chrome = FocusableActionDetector(
      enabled: _interactive,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent:
            CallbackAction<ActivateIntent>(onInvoke: (_) => _handleTap()),
      },
      child: chrome,
    );

    final value = _semanticValue(context);
    final label = widget.semanticLabel ??
        (widget.child != null ? null : (_displayedLabel ?? ''));
    return Semantics(
      container: true,
      button: true,
      enabled: _interactive,
      label: label,
      value: value.isEmpty ? null : value,
      hint: widget.semanticHint,
      liveRegion: phase != KitoButtonPhase.idle,
      onTap: _interactive ? _handleTap : null,
      child: KitoButtonShake(
        trigger: _shakes,
        duration: motion.shakeDuration,
        child: ExcludeSemantics(excluding: label != null, child: chrome),
      ),
    );
  }

  Widget _content(KitoButtonTheme theme, KitoButtonMotion motion) {
    if (widget.child != null) return widget.child!;
    final spacing = theme.iconSpacing;
    final iconWidget = _icon(motion);
    if (widget._iconOnly) return iconWidget ?? const SizedBox.shrink();

    final leading = widget.leading ??
        (widget.iconPlacement == KitoButtonIconPlacement.leading
            ? iconWidget
            : null);
    final trailing = widget.trailing ??
        (widget.iconPlacement == KitoButtonIconPlacement.trailing
            ? iconWidget
            : null);

    final align = widget.contentAlignment;
    final crossAlign = switch (align) {
      KitoButtonContentAlignment.center => CrossAxisAlignment.center,
      KitoButtonContentAlignment.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
    final textAlign = switch (align) {
      KitoButtonContentAlignment.center => TextAlign.center,
      KitoButtonContentAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    };
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.3;
    final label = _displayedLabel;

    final title = label == null
        ? null
        : AnimatedSwitcher(
            duration: motion.morphDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                  scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                  child: child),
            ),
            layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.center,
                children: [...previous, if (current != null) current]),
            child: Column(
              key: ValueKey(label),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: crossAlign,
              children: [
                Text(label,
                    maxLines: largeText ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: textAlign),
                if (widget.subtitle != null)
                  Opacity(
                    opacity: 0.75,
                    child: Text(widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: textAlign,
                        style: context.kito.typography.caption
                            .copyWith(decoration: TextDecoration.none)),
                  ),
              ],
            ),
          );

    final fills = (widget.expand || widget.minWidth != null) &&
        align != KitoButtonContentAlignment.center;
    return Row(
      mainAxisSize: fills ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: switch (align) {
        KitoButtonContentAlignment.start => MainAxisAlignment.start,
        KitoButtonContentAlignment.center => MainAxisAlignment.center,
        KitoButtonContentAlignment.end => MainAxisAlignment.end,
        KitoButtonContentAlignment.spaceBetween =>
          MainAxisAlignment.spaceBetween,
      },
      children: [
        if (leading != null) leading,
        if (leading != null && title != null) SizedBox(width: spacing),
        if (title != null) Flexible(child: title),
        if (trailing != null && title != null) SizedBox(width: spacing),
        if (trailing != null) trailing,
      ],
    );
  }

  /// The icon, morphing between the idle glyph and the success/failure glyph.
  Widget? _icon(KitoButtonMotion motion) {
    if (widget.icon == null) return null;
    final phase = _phase;
    final Widget current = switch (phase) {
      KitoButtonPhase.success =>
        Icon(widget.successIcon, key: const ValueKey(KitoButtonPhase.success)),
      KitoButtonPhase.failure =>
        Icon(widget.failureIcon, key: const ValueKey(KitoButtonPhase.failure)),
      _ => KeyedSubtree(
          key: const ValueKey(KitoButtonPhase.idle), child: widget.icon!),
    };
    return SizedBox.square(
      dimension: widget.size.iconSize + 2,
      child: AnimatedSwitcher(
        duration: motion.morphDuration,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
              scale: CurvedAnimation(
                  parent: animation,
                  curve: motion.morphCurve,
                  reverseCurve: Curves.easeIn),
              child: child),
        ),
        child: current,
      ),
    );
  }
}
