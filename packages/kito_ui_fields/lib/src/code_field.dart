// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'resize.dart';

/// How code boxes are drawn.
enum KitoCodeBoxStyle {
  /// A bordered box per character.
  outlined,

  /// A soft filled box per character; a border appears on the active one.
  filled,

  /// A line under each character.
  underline,
}

/// Keeps only what a code accepts: digits (any script, converted to ASCII) or letters and
/// digits, uppercased, up to [length].
String kitoCodeSanitize(String input,
    {required int length, bool alphanumeric = false, bool uppercase = true}) {
  final normalized = input.kitoNormalizedDigits;
  final out = StringBuffer();
  for (final rune in normalized.runes) {
    if (out.length >= length) break;
    final c = String.fromCharCode(rune);
    final digit = rune >= 0x30 && rune <= 0x39;
    final letter =
        (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
    if (digit || (alphanumeric && letter)) {
      out.write(uppercase ? c.toUpperCase() : c);
    }
  }
  return out.toString();
}

/// The indexes after which a separator goes for group [sizes] ([3, 3] → {2}).
Set<int> kitoCodeGroupBoundaries(List<int>? sizes, int length) {
  if (sizes == null || sizes.length < 2) return const {};
  final out = <int>{};
  var index = -1;
  for (final size in sizes.take(sizes.length - 1)) {
    index += size;
    if (index >= 0 && index < length - 1) out.add(index);
  }
  return out;
}

/// One-time code entry drawn as boxes over a single hidden text field, so typing, paste and
/// SMS autofill all just work. Codes read left to right in every locale, so the boxes stay
/// left to right in RTL layouts too.
///
/// ```dart
/// KitoCodeField(
///   length: 6,
///   groups: const [3, 3],
///   onCompleted: (code) => verify(code),
/// )
/// ```
class KitoCodeField extends StatefulWidget {
  /// Creates a code field.
  const KitoCodeField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.obscureText = false,
    this.alphanumeric = false,
    this.error,
    this.groups,
    this.boxStyle = KitoCodeBoxStyle.outlined,
    this.boxSize = const Size(48, 56),
    this.minBoxWidth = 32,
    this.spacing = 10,
    this.autofocus = false,
    this.enabled = true,
    this.showsSuccess = false,
    this.semanticLabel = 'Verification code',
    this.tint,
  }) : assert(length > 0);

  /// How many characters.
  final int length;

  /// Your controller; one is made for you when null.
  final TextEditingController? controller;

  /// Your focus node.
  final FocusNode? focusNode;

  /// Every change.
  final ValueChanged<String>? onChanged;

  /// Once every box is filled.
  final ValueChanged<String>? onCompleted;

  /// Shows dots instead of characters.
  final bool obscureText;

  /// Accepts letters as well as digits (uppercased).
  final bool alphanumeric;

  /// An error to show under the boxes; they turn red and shake.
  final String? error;

  /// Group sizes with a dash between groups, e.g. `[3, 3]`.
  final List<int>? groups;

  /// Box look.
  final KitoCodeBoxStyle boxStyle;

  /// The largest box size; boxes shrink to fit narrow screens.
  final Size boxSize;

  /// The narrowest a box shrinks to.
  final double minBoxWidth;

  /// Gap between boxes.
  final double spacing;

  /// Focus on first build.
  final bool autofocus;

  /// False disables it.
  final bool enabled;

  /// Green boxes and a pulse, once the code is accepted.
  final bool showsSuccess;

  /// What screen readers call it.
  final String semanticLabel;

  /// Overrides the active-box colour.
  final Color? tint;

  @override
  State<KitoCodeField> createState() => _KitoCodeFieldState();
}

class _KitoCodeFieldState extends State<KitoCodeField>
    with TickerProviderStateMixin {
  TextEditingController? _own;
  FocusNode? _ownFocus;
  late final AnimationController _caret = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 530));
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360));
  String _last = '';
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'KitoCode'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
    _last = _controller.text;
    _focused = _focus.hasFocus;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCaret();
  }

  @override
  void didUpdateWidget(KitoCodeField old) {
    super.didUpdateWidget(old);
    final motion = !context.reduceMotion;
    if (old.error == null && widget.error != null && motion) {
      _shake.forward(from: 0);
    }
    if (!old.showsSuccess && widget.showsSuccess && motion) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _focus.removeListener(_onFocus);
    _own?.dispose();
    _ownFocus?.dispose();
    _caret.dispose();
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _syncCaret() {
    final full = _controller.text.length >= widget.length;
    if (_focused && !full && !context.reduceMotion) {
      if (!_caret.isAnimating) _caret.repeat(reverse: true);
    } else {
      _caret
        ..stop()
        ..value = 1;
    }
  }

  void _onFocus() {
    if (_focus.hasFocus == _focused) return;
    setState(() => _focused = _focus.hasFocus);
    _syncCaret();
  }

  void _onText() {
    final text = _controller.text;
    if (text == _last) return;
    final wasComplete = _last.length == widget.length;
    _last = text;
    widget.onChanged?.call(text);
    if (text.length == widget.length && !wasComplete) {
      widget.onCompleted?.call(text);
    }
    setState(() {});
    _syncCaret();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final text = _controller.text;
    final boundaries = kitoCodeGroupBoundaries(widget.groups, widget.length);
    const separatorWidth = 14.0;

    final field = Positioned.fill(
      child: Opacity(
        opacity: 0,
        // The hidden field is what screen readers focus and type into.
        alwaysIncludeSemantics: true,
        child: Semantics(
          label: widget.semanticLabel,
          hint: widget.error,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            showCursor: false,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: widget.alphanumeric
                ? TextInputType.visiblePassword
                : TextInputType.number,
            textCapitalization: widget.alphanumeric
                ? TextCapitalization.characters
                : TextCapitalization.none,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              _KitoCodeFormatter(widget.length, widget.alphanumeric),
            ],
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
                border: InputBorder.none, isCollapsed: true),
          ),
        ),
      ),
    );

    final row = LayoutBuilder(builder: (context, constraints) {
      final seps = boundaries.length;
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : widget.boxSize.width * widget.length * 2;
      final perBox = (available -
              widget.spacing * (widget.length + seps - 1) -
              separatorWidth * seps) /
          widget.length;
      final width =
          math.max(widget.minBoxWidth, math.min(widget.boxSize.width, perBox));
      final height = widget.boxSize.height *
          (width / widget.boxSize.width).clamp(0.8, 1.0);
      // At the minimum box width a long code can still be wider than the
      // space available; scale it down rather than overflow.
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Directionality(
          // Codes read left to right everywhere.
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: widget.spacing),
                _box(kito, i, text, Size(width, height)),
                if (boundaries.contains(i)) ...[
                  SizedBox(width: widget.spacing),
                  SizedBox(
                    width: separatorWidth,
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 2,
                        decoration: BoxDecoration(
                            color: kito.colors.onSurface.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1)),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    });

    final boxes = AnimatedBuilder(
      animation: Listenable.merge([_shake, _pulse]),
      child: ExcludeSemantics(child: Center(child: row)),
      builder: (context, child) {
        final t = _shake.value;
        final dx =
            t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi * 6) * 8 * (1 - t);
        final p = _pulse.value;
        final scale = 1 + 0.05 * math.sin(p * math.pi);
        return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: scale, child: child));
      },
    );

    return AnimatedOpacity(
      opacity: widget.enabled ? 1 : 0.5,
      duration: KitoMotion.of(context, kito.motion.fast),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(children: [boxes, field]),
          FieldResize(
            duration: KitoMotion.of(context, kito.motion.medium),
            child: widget.error == null
                ? const SizedBox(width: double.infinity)
                : ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_rounded,
                              size: 14, color: kito.colors.danger),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(widget.error!,
                                textAlign: TextAlign.center,
                                style: kito.typography.caption
                                    .copyWith(color: kito.colors.danger)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _box(KitoTheme kito, int index, String text, Size size) {
    final accent = kito.accent(widget.tint);
    final filled = index < text.length;
    final full = text.length >= widget.length;
    final active = _focused &&
        (index == text.length || (full && index == widget.length - 1));
    final hasError = widget.error != null;
    final success = widget.showsSuccess && !hasError;
    final fast = KitoMotion.of(context, kito.motion.fast);

    final Color border = hasError
        ? kito.colors.danger
        : success
            ? kito.colors.success
            : active
                ? accent
                : filled
                    ? kito.colors.onSurface.withValues(alpha: 0.35)
                    : kito.colors.border;
    final width = active || hasError || success ? 1.8 : 1.2;
    final radius = BorderRadius.circular(kito.radii.md);
    final Color fill = switch (widget.boxStyle) {
      KitoCodeBoxStyle.outlined => kito.colors.surface,
      KitoCodeBoxStyle.filled =>
        active ? kito.colors.surface : kito.colors.surfaceMuted,
      KitoCodeBoxStyle.underline => Colors.transparent,
    };
    final underline = widget.boxStyle == KitoCodeBoxStyle.underline;
    final showBorder = widget.boxStyle != KitoCodeBoxStyle.filled ||
        active ||
        hasError ||
        success;

    final char = filled ? text[index] : null;
    return AnimatedContainer(
      key: ValueKey('${widget.boxStyle.name}-$index'),
      duration: fast,
      curve: kito.motion.standard,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: underline ? null : radius,
        boxShadow: active && !underline
            ? [
                BoxShadow(
                    color: accent.withValues(alpha: 0.14), spreadRadius: 3)
              ]
            : const [],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: underline ? null : radius,
        border: !showBorder
            ? null
            : underline
                ? Border(bottom: BorderSide(color: border, width: width + 0.4))
                : Border.all(color: border, width: width),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: KitoMotion.of(context, kito.motion.medium),
        switchInCurve: kito.motion.spring,
        transitionBuilder: (child, a) => ScaleTransition(
            scale: Tween(begin: 0.4, end: 1.0).animate(a),
            child: FadeTransition(opacity: a, child: child)),
        child: char != null
            ? Text(
                widget.obscureText ? '●' : char,
                key: ValueKey('c$index$char'),
                textScaler:
                    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                style: kito.typography.title.copyWith(
                    color: kito.colors.onSurface,
                    fontSize: widget.obscureText ? 14 : size.height * 0.42,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              )
            : active
                ? FadeTransition(
                    key: const ValueKey('caret'),
                    opacity: _caret,
                    child: Container(
                        width: 2, height: size.height * 0.42, color: accent),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}

class _KitoCodeFormatter extends TextInputFormatter {
  _KitoCodeFormatter(this.length, this.alphanumeric);
  final int length;
  final bool alphanumeric;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = kitoCodeSanitize(newValue.text,
        length: 1 << 20, alphanumeric: alphanumeric);
    // A paste or autofill into a full field replaces it rather than being cut off.
    if (text.length > length) {
      final added = kitoCodeSanitize(
          newValue.text.replaceFirst(oldValue.text, ''),
          length: 1 << 20,
          alphanumeric: alphanumeric);
      text = (added.length >= length ? added : text).substring(0, length);
    }
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// "Resend code" that locks for [cooldown] after each send, counting down in place
/// ("Resend in 0:29").
class KitoCodeResendButton extends StatefulWidget {
  /// Creates the button. It starts locked when [startsLocked] is true (a code was just sent).
  const KitoCodeResendButton({
    super.key,
    required this.onResend,
    this.cooldown = const Duration(seconds: 30),
    this.startsLocked = true,
    this.label = 'Resend code',
    this.waitingLabel,
  });

  /// Sends a new code.
  final VoidCallback onResend;

  /// How long to wait between sends.
  final Duration cooldown;

  /// Locked on first build.
  final bool startsLocked;

  /// The title when it can be tapped.
  final String label;

  /// The title while waiting, from the seconds left; "Resend in 0:29" by default.
  final String Function(int secondsLeft)? waitingLabel;

  @override
  State<KitoCodeResendButton> createState() => _KitoCodeResendButtonState();
}

class _KitoCodeResendButtonState extends State<KitoCodeResendButton> {
  Timer? _timer;
  int _left = 0;

  @override
  void initState() {
    super.initState();
    if (widget.startsLocked) _lock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _lock() {
    _timer?.cancel();
    _left = widget.cooldown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  void _tap() {
    widget.onResend();
    setState(_lock);
  }

  static String _clock(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final waiting = _left > 0;
    final title = waiting
        ? (widget.waitingLabel?.call(_left) ?? 'Resend in ${_clock(_left)}')
        : widget.label;
    return Semantics(
      button: true,
      enabled: !waiting,
      label: title,
      excludeSemantics: true,
      onTap: waiting ? null : _tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: waiting ? null : _tap,
        child: KitoPressable(
          enabled: !waiting,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: AnimatedDefaultTextStyle(
                duration: KitoMotion.of(context, kito.motion.fast),
                style: kito.typography.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: waiting
                      ? kito.colors.onSurface.withValues(alpha: 0.45)
                      : kito.colors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                child: Text(title),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
