// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'text_field.dart';
import 'theme.dart';

/// Cleans typed or pasted amount text down to a plain number string with a `.` decimal point:
/// digits in any script become ASCII, grouping is recognised (`1,200.50`, `1.200,50`,
/// `1 200`), a lone separator followed by anything but three digits is read as the decimal
/// point ("20,5" is 20.5), and the fraction is cut to [decimals].
String kitoFieldNormalizeAmount(String raw,
    {String groupingSeparator = ',',
    int decimals = 2,
    bool allowNegative = false}) {
  var s = raw.kitoNormalizedDigits
      .replaceAll('٫', '.')
      .replaceAll('٬', '')
      .replaceAll(RegExp(r'[\s  ]'), '');
  final negative = allowNegative && s.trimLeft().startsWith('-');
  s = s.replaceAll(RegExp(r'[^0-9.,]'), '');
  final dots = '.'.allMatches(s).length;
  final commas = ','.allMatches(s).length;
  int? decimalAt;
  if (dots > 0 && commas > 0) {
    decimalAt = [s.lastIndexOf('.'), s.lastIndexOf(',')]
        .reduce((a, b) => a > b ? a : b);
  } else if (dots + commas == 1) {
    final at = s.indexOf(dots == 1 ? '.' : ',');
    final after = s.length - at - 1;
    final isGrouping = after == 3 && s[at] == groupingSeparator && at > 0;
    if (!isGrouping) decimalAt = at;
  }
  final intPart = StringBuffer();
  final fracPart = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == '.' || c == ',') continue;
    if (decimalAt != null && i > decimalAt) {
      fracPart.write(c);
    } else {
      intPart.write(c);
    }
  }
  var integer = intPart.toString().replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (integer.isEmpty && decimalAt != null) integer = '0';
  var fraction = fracPart.toString();
  if (fraction.length > decimals) fraction = fraction.substring(0, decimals);
  final hasPoint = decimalAt != null && decimals > 0;
  if (integer.isEmpty && !hasPoint) return negative ? '-' : '';
  return '${negative ? '-' : ''}$integer${hasPoint ? '.$fraction' : ''}';
}

/// Writes a normalised amount ("1200.5") for display ("1,200.5"), keeping a trailing decimal
/// point while the user is mid-typing.
String kitoFieldDisplayAmount(String normalized,
    {String groupingSeparator = ',', String decimalSeparator = '.'}) {
  if (normalized.isEmpty || normalized == '-') return normalized;
  final negative = normalized.startsWith('-');
  final unsigned = negative ? normalized.substring(1) : normalized;
  final point = unsigned.indexOf('.');
  final integer = point < 0 ? unsigned : unsigned.substring(0, point);
  final grouped = StringBuffer();
  for (var i = 0; i < integer.length; i++) {
    if (i > 0 && (integer.length - i) % 3 == 0) {
      grouped.write(groupingSeparator);
    }
    grouped.write(integer[i]);
  }
  final fraction =
      point < 0 ? '' : decimalSeparator + unsigned.substring(point + 1);
  return '${negative ? '-' : ''}$grouped$fraction';
}

/// Formats an amount as it's typed: groups thousands, keeps one decimal separator and caps the
/// fraction.
class KitoFieldAmountFormatter extends TextInputFormatter {
  /// Creates the formatter.
  KitoFieldAmountFormatter({
    this.decimals = 2,
    this.groupingSeparator = ',',
    this.decimalSeparator = '.',
    this.allowNegative = false,
  });

  /// Fraction digits allowed (0 for whole numbers).
  final int decimals;

  /// Thousands separator.
  final String groupingSeparator;

  /// Decimal separator.
  final String decimalSeparator;

  /// Accepts a leading minus.
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String normalized;
    if (newValue.text.length - oldValue.text.length <= 1) {
      normalized = _typed(oldValue, newValue);
    } else {
      // A paste: work out what its separators mean.
      final input = decimalSeparator == '.'
          ? newValue.text
          : newValue.text
              .replaceAll(groupingSeparator, '')
              .replaceAll(decimalSeparator, '.');
      normalized = kitoFieldNormalizeAmount(input,
          groupingSeparator: decimalSeparator == '.' ? groupingSeparator : ',',
          decimals: decimals,
          allowNegative: allowNegative);
    }
    final display = kitoFieldDisplayAmount(normalized,
        groupingSeparator: groupingSeparator,
        decimalSeparator: decimalSeparator);
    final fromEnd = newValue.text.length -
        newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final caret = (display.length - fromEnd).clamp(0, display.length);
    return TextEditingValue(
        text: display, selection: TextSelection.collapsed(offset: caret));
  }

  /// Typing: our own grouping is dropped, and a "." or "," just typed is the decimal point
  /// (unless there already is one).
  String _typed(TextEditingValue oldValue, TextEditingValue newValue) {
    const marker = '\u0000';
    var t = newValue.text.kitoNormalizedDigits.replaceAll('\u066B', marker);
    final at = newValue.selection.baseOffset - 1;
    if (newValue.text.length == oldValue.text.length + 1 &&
        at >= 0 &&
        at < t.length &&
        (t[at] == '.' || t[at] == ',')) {
      t = t.replaceRange(at, at + 1, marker);
    }
    t = t
        .replaceAll(groupingSeparator, '')
        .replaceAll(decimalSeparator, marker);
    final first = t.indexOf(marker);
    if (first >= 0) {
      t = t.substring(0, first + 1) +
          t.substring(first + 1).replaceAll(marker, '');
    }
    t = t.replaceAll(RegExp(r'[.,]'), '').replaceAll(marker, '.');
    return kitoFieldNormalizeAmount(t,
        groupingSeparator: ',',
        decimals: decimals,
        allowNegative: allowNegative);
  }
}

/// Parses amount text in any of the forms [kitoFieldNormalizeAmount] accepts.
double? kitoFieldParseAmount(String text,
    {String groupingSeparator = ',', String decimalSeparator = '.'}) {
  final input = decimalSeparator == '.'
      ? text
      : text
          .replaceAll(groupingSeparator, '')
          .replaceAll(decimalSeparator, '.');
  final normalized = kitoFieldNormalizeAmount(input,
      groupingSeparator: decimalSeparator == '.' ? groupingSeparator : ',',
      decimals: 12,
      allowNegative: true);
  return double.tryParse(normalized);
}

/// Where a currency symbol sits.
enum KitoCurrencySymbolPosition {
  /// Before the amount ("KSh 1,250.00").
  prefix,

  /// After the amount ("1 250,00 €").
  suffix,
}

/// An amount field with a currency symbol, thousands grouping as you type, a fixed number of
/// decimals and optional limits. Digits typed in Arabic or Persian are understood, and the
/// amount stays left to right in RTL.
///
/// ```dart
/// KitoCurrencyField(
///   currencySymbol: 'KSh',
///   max: 150000,
///   onChanged: (amount) => transfer.amount = amount,
/// )
/// ```
class KitoCurrencyField extends StatefulWidget {
  /// Creates an amount field.
  const KitoCurrencyField({
    super.key,
    this.label = 'Amount',
    this.placeholder,
    this.helper,
    this.error,
    this.initialValue,
    this.onChanged,
    this.currencySymbol = r'$',
    this.symbolPosition = KitoCurrencySymbolPosition.prefix,
    this.decimals = 2,
    this.groupingSeparator = ',',
    this.decimalSeparator = '.',
    this.min,
    this.max,
    this.isRequired = false,
    this.trailing,
    this.rules = const [],
    this.trigger = KitoValidationTrigger.onBlur,
    this.enabled = true,
    this.style,
    this.tint,
  });

  /// The label.
  final String? label;

  /// Shown while empty; "0.00" for two decimals.
  final String? placeholder;

  /// Quiet text under the field.
  final String? helper;

  /// An error you set.
  final String? error;

  /// The starting amount.
  final double? initialValue;

  /// Every change, with the parsed amount (null when empty).
  final ValueChanged<double?>? onChanged;

  /// "KSh", "$", "€".
  final String currencySymbol;

  /// Before or after the amount.
  final KitoCurrencySymbolPosition symbolPosition;

  /// Fraction digits (0 for whole amounts).
  final int decimals;

  /// Thousands separator.
  final String groupingSeparator;

  /// Decimal separator.
  final String decimalSeparator;

  /// The smallest amount allowed.
  final double? min;

  /// The largest amount allowed.
  final double? max;

  /// Fails validation when empty.
  final bool isRequired;

  /// After the amount: a currency switcher, say.
  final Widget? trailing;

  /// More rules, run on the text.
  final List<KitoValidationRule> rules;

  /// When errors become visible.
  final KitoValidationTrigger trigger;

  /// False disables it.
  final bool enabled;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  /// Overrides the focus colour.
  final Color? tint;

  @override
  State<KitoCurrencyField> createState() => _KitoCurrencyFieldState();
}

class _KitoCurrencyFieldState extends State<KitoCurrencyField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue == null
        ? ''
        : kitoFieldDisplayAmount(
            widget.initialValue!.toStringAsFixed(widget.decimals),
            groupingSeparator: widget.groupingSeparator,
            decimalSeparator: widget.decimalSeparator),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _parse(String text) => kitoFieldParseAmount(text,
      groupingSeparator: widget.groupingSeparator,
      decimalSeparator: widget.decimalSeparator);

  String _fmt(double v) => kitoFieldDisplayAmount(
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : widget.decimals),
      groupingSeparator: widget.groupingSeparator,
      decimalSeparator: widget.decimalSeparator);

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final symbol = Directionality(
      textDirection: TextDirection.ltr,
      child: Text(widget.currencySymbol,
          style: kito.typography.bodyEmphasized
              .copyWith(color: kito.colors.onSurface.withValues(alpha: 0.7))),
    );
    final zero = widget.decimals == 0
        ? '0'
        : '0${widget.decimalSeparator}${'0' * widget.decimals}';
    return KitoTextField(
      label: widget.label,
      placeholder: widget.placeholder ?? zero,
      helper: widget.helper,
      error: widget.error,
      controller: _controller,
      leading: widget.symbolPosition == KitoCurrencySymbolPosition.prefix
          ? symbol
          : null,
      trailing: widget.symbolPosition == KitoCurrencySymbolPosition.suffix ||
              widget.trailing != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              if (widget.symbolPosition == KitoCurrencySymbolPosition.suffix)
                symbol,
              if (widget.trailing != null) widget.trailing!,
            ])
          : null,
      keyboardType: TextInputType.numberWithOptions(
          decimal: widget.decimals > 0, signed: false),
      inputFormatters: [
        KitoFieldAmountFormatter(
          decimals: widget.decimals,
          groupingSeparator: widget.groupingSeparator,
          decimalSeparator: widget.decimalSeparator,
        ),
      ],
      forceLtr: true,
      textStyle: kito.typography.bodyEmphasized.copyWith(
          fontSize: 18, fontFeatures: const [FontFeature.tabularFigures()]),
      trigger: widget.trigger,
      enabled: widget.enabled,
      style: widget.style,
      tint: widget.tint,
      onChanged: (t) => widget.onChanged?.call(_parse(t)),
      rules: [
        if (widget.isRequired) KitoValidationRule.required(),
        if (widget.min != null)
          KitoValidationRule.custom('The minimum is ${_fmt(widget.min!)}', (v) {
            final n = _parse(v);
            return n == null || n >= widget.min!;
          }),
        if (widget.max != null)
          KitoValidationRule.custom('The maximum is ${_fmt(widget.max!)}', (v) {
            final n = _parse(v);
            return n == null || n <= widget.max!;
          }),
        ...widget.rules,
      ],
    );
  }
}

/// A number stepper: − and + buttons around the value, which rolls up or down as it changes.
/// Hold a button to repeat, faster the longer it's held. Screen readers get increase and
/// decrease actions.
///
/// ```dart
/// KitoStepperField(label: 'Guests', value: guests, min: 1, max: 12,
///     onChanged: (v) => setState(() => guests = v.toInt()))
/// ```
class KitoStepperField extends StatefulWidget {
  /// Creates a stepper.
  const KitoStepperField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.decimals = 0,
    this.unit,
    this.enabled = true,
    this.tint,
  });

  /// The current value.
  final num value;

  /// Called with the new value.
  final ValueChanged<num> onChanged;

  /// A label before the control.
  final String? label;

  /// The smallest value.
  final num min;

  /// The largest value.
  final num max;

  /// How much each tap changes it.
  final num step;

  /// Fraction digits shown.
  final int decimals;

  /// A unit after the value ("kg", "nights").
  final String? unit;

  /// False disables it.
  final bool enabled;

  /// The buttons' colour.
  final Color? tint;

  @override
  State<KitoStepperField> createState() => _KitoStepperFieldState();
}

class _KitoStepperFieldState extends State<KitoStepperField> {
  Timer? _repeat;
  int _repeats = 0;
  bool _up = true;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  num _clamp(num v) =>
      v < widget.min ? widget.min : (v > widget.max ? widget.max : v);

  bool get _canDown => widget.enabled && widget.value > widget.min;
  bool get _canUp => widget.enabled && widget.value < widget.max;

  void _change(int direction) {
    if (direction > 0 ? !_canUp : !_canDown) {
      _stop();
      return;
    }
    final raw = widget.value + widget.step * direction;
    final rounded = widget.decimals == 0
        ? raw.round()
        : double.parse(raw.toStringAsFixed(widget.decimals));
    setState(() => _up = direction > 0);
    HapticFeedback.selectionClick();
    widget.onChanged(_clamp(rounded));
  }

  void _start(int direction) {
    _repeats = 0;
    _repeat?.cancel();
    _repeat = Timer.periodic(const Duration(milliseconds: 90), (t) {
      _repeats++;
      // Wait a moment, then speed up the longer it's held.
      if (_repeats < 4) return;
      final every = _repeats > 30 ? 1 : (_repeats > 14 ? 2 : 3);
      if (_repeats % every == 0) _change(direction);
    });
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  String get _text {
    final v = widget.value.toStringAsFixed(widget.decimals);
    return widget.unit == null ? v : '$v ${widget.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = kito.accent(widget.tint);
    final medium = KitoMotion.of(context, kito.motion.medium);

    Widget button(int direction) {
      final enabled = direction > 0 ? _canUp : _canDown;
      return ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _change(direction) : null,
          onLongPressStart: enabled ? (_) => _start(direction) : null,
          onLongPressEnd: (_) => _stop(),
          onLongPressCancel: _stop,
          child: KitoPressable(
            enabled: enabled,
            scale: 0.88,
            child: AnimatedContainer(
              duration: KitoMotion.of(context, kito.motion.fast),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled
                    ? accent.withValues(alpha: 0.1)
                    : kito.colors.surfaceMuted,
              ),
              child: Icon(
                  direction > 0 ? Icons.add_rounded : Icons.remove_rounded,
                  size: 20,
                  color: enabled
                      ? accent
                      : kito.colors.onSurface.withValues(alpha: 0.3)),
            ),
          ),
        ),
      );
    }

    final stepText = widget.step.toStringAsFixed(widget.decimals);
    final control = Semantics(
      label: widget.label,
      value: _text,
      increasedValue: _canUp
          ? _clamp(widget.value + widget.step).toStringAsFixed(widget.decimals)
          : null,
      decreasedValue: _canDown
          ? _clamp(widget.value - widget.step).toStringAsFixed(widget.decimals)
          : null,
      hint: 'Changes by $stepText',
      onIncrease: _canUp ? () => _change(1) : null,
      onDecrease: _canDown ? () => _change(-1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(-1),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: medium,
                switchInCurve: kito.motion.spring,
                transitionBuilder: (child, a) {
                  final incoming = child.key == ValueKey(_text);
                  final from = (_up ? 1.0 : -1.0) * (incoming ? 1 : -1);
                  return FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position:
                          Tween(begin: Offset(0, from * 0.6), end: Offset.zero)
                              .animate(a),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _text,
                  key: ValueKey(_text),
                  textAlign: TextAlign.center,
                  style: kito.typography.headline.copyWith(
                      color: kito.colors.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),
          button(1),
        ],
      ),
    );

    return AnimatedOpacity(
      opacity: widget.enabled ? 1 : 0.5,
      duration: KitoMotion.of(context, kito.motion.fast),
      child: widget.label == null
          ? control
          : Row(
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(widget.label!,
                        style: kito.typography.body
                            .copyWith(color: kito.colors.onSurface)),
                  ),
                ),
                control,
              ],
            ),
    );
  }
}
