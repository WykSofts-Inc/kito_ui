// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'mask.dart';
import 'shell.dart';
import 'theme.dart';

/// Builds extra content under a field from its current text.
typedef KitoFieldFooterBuilder = Widget Function(
    BuildContext context, String value);

/// A polished text field: label (above or floating), leading and trailing accessories, a clear
/// button, validation that reveals itself at the right moment, a success tick, a counter and a
/// footer — in any [KitoFieldStyle].
///
/// Validate with [rules] (and an optional [asyncRule]), or hand it a [KitoFormFieldController]
/// as [field] to share state with a [KitoFormController]. Inside a Flutter [Form] it registers
/// itself, so `Form.validate()`, `save()` and `reset()` work as usual.
///
/// ```dart
/// KitoTextField(
///   label: 'Email',
///   placeholder: 'you@example.com',
///   leadingIcon: Icons.mail_outline_rounded,
///   keyboardType: TextInputType.emailAddress,
///   rules: [KitoValidationRule.required(), KitoValidationRule.email()],
/// )
/// ```
class KitoTextField extends StatefulWidget {
  /// Creates a field.
  const KitoTextField({
    super.key,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.field,
    this.initialValue,
    this.rules = const [],
    this.asyncRule,
    this.trigger = KitoValidationTrigger.onBlur,
    this.leading,
    this.leadingIcon,
    this.trailing,
    this.prefixText,
    this.suffixText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters = const [],
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.showsCounter = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.isRequired = false,
    this.showsClearButton = false,
    this.showsSuccess,
    this.forceLtr = false,
    this.normalizesDigits = true,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onSaved,
    this.footer,
    this.footerBuilder,
    this.style,
    this.tint,
    this.semanticLabel,
    this.textStyle,
  });

  /// The label.
  final String? label;

  /// Shown while empty.
  final String? placeholder;

  /// Quiet text under the field.
  final String? helper;

  /// An error you set (a server response, say). Always shown, over rule errors.
  final String? error;

  /// Your controller; one is made for you when null. Ignored when [field] is set.
  final TextEditingController? controller;

  /// Your focus node; one is made for you when null. Ignored when [field] is set.
  final FocusNode? focusNode;

  /// Shared state from a [KitoFormController]: its controller, focus node, rules and errors
  /// are used instead of this widget's.
  final KitoFormFieldController? field;

  /// The starting text when there's no [controller] or [field].
  final String? initialValue;

  /// Rules run in order; the first failure shows.
  final List<KitoValidationRule> rules;

  /// A server-side check run (debounced) once [rules] pass.
  final KitoAsyncValidationRule? asyncRule;

  /// When rule errors become visible.
  final KitoValidationTrigger trigger;

  /// Before the input.
  final Widget? leading;

  /// An icon before the input (when [leading] is null).
  final IconData? leadingIcon;

  /// After the input.
  final Widget? trailing;

  /// Fixed text before the value ("https://").
  final String? prefixText;

  /// Fixed text after the value ("kg").
  final String? suffixText;

  /// The keyboard.
  final TextInputType? keyboardType;

  /// The return key.
  final TextInputAction? textInputAction;

  /// Formatters, after digit normalisation.
  final List<TextInputFormatter> inputFormatters;

  /// Autofill hints (`AutofillHints.email`…).
  final Iterable<String>? autofillHints;

  /// Capitalisation.
  final TextCapitalization textCapitalization;

  /// Hides the text (passwords).
  final bool obscureText;

  /// Autocorrect.
  final bool autocorrect;

  /// Keyboard suggestions.
  final bool enableSuggestions;

  /// Minimum lines for multi-line fields.
  final int? minLines;

  /// Maximum lines; null grows without limit.
  final int? maxLines;

  /// The most characters allowed.
  final int? maxLength;

  /// Shows "12/280" when [maxLength] is set.
  final bool showsCounter;

  /// False dims the field and blocks input.
  final bool enabled;

  /// Shows the text without editing it.
  final bool readOnly;

  /// Focus on first build.
  final bool autofocus;

  /// Adds " *" to the label.
  final bool isRequired;

  /// A clear button while there's text.
  final bool showsClearButton;

  /// Shows the success state when valid; the theme's setting when null.
  final bool? showsSuccess;

  /// Keeps the text left to right even in RTL layouts — numbers, codes, card digits.
  final bool forceLtr;

  /// Converts digits typed in other scripts (Arabic-Indic, Persian…) to ASCII.
  final bool normalizesDigits;

  /// Every change.
  final ValueChanged<String>? onChanged;

  /// The return key.
  final ValueChanged<String>? onSubmitted;

  /// A tap on the input.
  final VoidCallback? onTap;

  /// Called by `Form.save()`.
  final ValueChanged<String>? onSaved;

  /// Extra content under the field.
  final Widget? footer;

  /// Builds extra content from the current text (a strength meter, a checklist).
  final KitoFieldFooterBuilder? footerBuilder;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  /// Overrides the focus colour.
  final Color? tint;

  /// What screen readers call the field; [label] (or [placeholder]) when null.
  final String? semanticLabel;

  /// Overrides the input's text style.
  final TextStyle? textStyle;

  @override
  State<KitoTextField> createState() => _KitoTextFieldState();
}

class _KitoTextFieldState extends State<KitoTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  KitoAsyncValidator? _async;
  bool _edited = false;
  bool _blurred = false;
  bool _submitted = false;
  bool _focused = false;
  String _lastText = '';

  TextEditingController get _controller =>
      widget.field?.textController ??
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.initialValue));

  FocusNode get _focus =>
      widget.field?.focusNode ??
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'KitoTextField'));

  @override
  void initState() {
    super.initState();
    _attach();
    _lastText = _controller.text;
    _focused = _focus.hasFocus;
    if (widget.asyncRule != null) {
      _async = KitoAsyncValidator(widget.asyncRule!)..addListener(_rebuild);
    }
  }

  void _attach() {
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
    widget.field?.addListener(_rebuild);
  }

  void _detach(KitoTextField old) {
    (old.field?.textController ?? old.controller ?? _ownController)
        ?.removeListener(_onText);
    (old.field?.focusNode ?? old.focusNode ?? _ownFocus)
        ?.removeListener(_onFocus);
    old.field?.removeListener(_rebuild);
  }

  @override
  void didUpdateWidget(KitoTextField old) {
    super.didUpdateWidget(old);
    if (old.field != widget.field ||
        old.controller != widget.controller ||
        old.focusNode != widget.focusNode) {
      _detach(old);
      _attach();
      _lastText = _controller.text;
    }
    if (old.asyncRule != widget.asyncRule) {
      _async?.dispose();
      _async = widget.asyncRule == null
          ? null
          : (KitoAsyncValidator(widget.asyncRule!)..addListener(_rebuild));
    }
  }

  @override
  void dispose() {
    _detach(widget);
    _ownController?.dispose();
    _ownFocus?.dispose();
    _async?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onText() {
    final text = _controller.text;
    if (text == _lastText) return;
    _lastText = text;
    _edited = true;
    if (_async != null) {
      if (kitoValidate(text, widget.rules) == null) {
        _async!.validate(text);
      } else {
        _async!.reset();
      }
    }
    widget.onChanged?.call(text);
    _rebuild();
  }

  void _onFocus() {
    final focused = _focus.hasFocus;
    if (focused == _focused) return;
    _focused = focused;
    if (!focused && _edited) _blurred = true;
    _rebuild();
  }

  bool get _shouldShow => switch (widget.trigger) {
        KitoValidationTrigger.live => _edited || _submitted,
        KitoValidationTrigger.onBlur => _blurred || _submitted,
        KitoValidationTrigger.onSubmit => _submitted,
        KitoValidationTrigger.never => false,
      };

  String? get _asyncError =>
      _async?.checkedValue == _controller.text ? _async?.error : null;

  /// The error, visible or not.
  String? get _currentError {
    if (widget.error != null) return widget.error;
    final field = widget.field;
    if (field != null) return field.currentError;
    return kitoValidate(_controller.text, widget.rules) ?? _asyncError;
  }

  /// The error to show now.
  String? get _visibleError {
    if (widget.error != null) return widget.error;
    final field = widget.field;
    if (field != null) return field.error;
    return _shouldShow ? _currentError : null;
  }

  bool get _validating =>
      widget.field?.isValidating ?? (_async?.isValidating ?? false);

  bool get _hasRules =>
      widget.rules.isNotEmpty ||
      widget.asyncRule != null ||
      (widget.field?.rules.isNotEmpty ?? false) ||
      widget.field?.asyncRule != null;

  bool get _isValid {
    if (_controller.text.isEmpty || !_hasRules || _validating) return false;
    if (_currentError != null) return false;
    if (_async != null && _async!.status != KitoValidationStatus.valid) {
      return false;
    }
    return true;
  }

  String? _validateForForm() {
    if (!_submitted) {
      _submitted = true;
      // Form.validate() runs from a handler, not a build, so the error can show right away;
      // an autovalidating Form calls it mid-build, so wait for the frame then.
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _rebuild());
      } else {
        _rebuild();
      }
    }
    widget.field?.didSubmit();
    return _currentError;
  }

  void _resetForForm() {
    _edited = false;
    _blurred = false;
    _submitted = false;
    _async?.reset();
    final initial = widget.field == null ? (widget.initialValue ?? '') : null;
    if (widget.field != null) {
      widget.field!.reset();
    } else if (widget.controller == null) {
      _controller.text = initial!;
    }
    _lastText = _controller.text;
    _rebuild();
  }

  Widget? _clearButton(KitoTheme kito) {
    if (!widget.showsClearButton || !widget.enabled || widget.readOnly) {
      return null;
    }
    final show = _controller.text.isNotEmpty;
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, kito.motion.fast),
      transitionBuilder: (child, a) => ScaleTransition(
          scale: a, child: FadeTransition(opacity: a, child: child)),
      child: !show
          ? const SizedBox.shrink(key: ValueKey('hidden'))
          : KitoFieldIconButton(
              key: const ValueKey('clear'),
              icon: Icons.cancel_rounded,
              semanticLabel: 'Clear',
              size: 18,
              onPressed: () {
                _controller.clear();
                _focus.requestFocus();
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final baseTheme = KitoFieldTheme.of(context);
    final ft = widget.style == null && widget.showsSuccess == null
        ? baseTheme
        : baseTheme.copyWith(
            style: widget.style, showsSuccess: widget.showsSuccess);
    final floating = ft.style == KitoFieldStyle.floatingLabel;
    final text = _controller.text;
    final error = _visibleError;

    final formatters = [
      if (widget.normalizesDigits) KitoFieldDigitsFormatter(),
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(widget.maxLength),
      ...widget.inputFormatters,
    ];

    final hint = floating && widget.label != null && !_focused
        ? null
        : widget.placeholder;
    final rtl = context.isRtl;
    final inputStyle = (widget.textStyle ?? kito.typography.body)
        .copyWith(color: kito.colors.onSurface);

    Widget input = TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect && !widget.obscureText,
      enableSuggestions: widget.enableSuggestions && !widget.obscureText,
      keyboardType: widget.keyboardType ??
          (widget.maxLines != 1 ? TextInputType.multiline : null),
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.enabled ? widget.autofillHints : null,
      inputFormatters: formatters,
      minLines: widget.minLines,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: inputStyle,
      cursorColor: kito.accent(widget.tint),
      textDirection: widget.forceLtr ? TextDirection.ltr : null,
      textAlign: widget.forceLtr
          ? (rtl ? TextAlign.right : TextAlign.left)
          : TextAlign.start,
      onTap: widget.onTap,
      onSubmitted: (v) {
        widget.onSubmitted?.call(v);
      },
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: inputStyle.copyWith(
            color: kito.colors.onSurface.withValues(alpha: 0.4)),
        prefixText: widget.prefixText,
        prefixStyle: inputStyle.copyWith(
            color: kito.colors.onSurface.withValues(alpha: 0.55)),
        suffixText: widget.suffixText,
        suffixStyle: inputStyle.copyWith(
            color: kito.colors.onSurface.withValues(alpha: 0.55)),
      ),
    );

    input = Semantics(
      label: widget.semanticLabel ?? widget.label ?? widget.placeholder,
      hint: error ?? widget.helper,
      child: input,
    );

    Widget? counter;
    if (widget.showsCounter && widget.maxLength != null) {
      final length = text.characters.length;
      final max = widget.maxLength!;
      final color = length >= max
          ? kito.colors.danger
          : length >= max * 0.9
              ? kito.colors.warning
              : kito.colors.onSurface.withValues(alpha: 0.5);
      counter = Semantics(
        label: '$length of $max characters',
        excludeSemantics: true,
        child: AnimatedDefaultTextStyle(
          duration: KitoMotion.of(context, kito.motion.fast),
          style: kito.typography.caption.copyWith(
              color: color, fontFeatures: const [FontFeature.tabularFigures()]),
          child: Text('$length/$max'),
        ),
      );
    }

    final trailing = [
      if (_validating)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6),
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: kito.accent(widget.tint)),
          ),
        ),
      if (_clearButton(kito) case final clear?) clear,
      if (widget.trailing != null) widget.trailing!,
    ];

    final leading = widget.leading ??
        (widget.leadingIcon == null ? null : Icon(widget.leadingIcon));

    final shell = KitoFieldShell(
      input: input,
      label: widget.label,
      leading: leading,
      trailing: trailing.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: trailing),
      helper: widget.helper,
      error: error,
      counter: counter,
      footer: widget.footerBuilder?.call(context, text) ?? widget.footer,
      isFocused: _focused,
      isEmpty: text.isEmpty,
      isEnabled: widget.enabled,
      isSuccess: _isValid,
      isRequired: widget.isRequired,
      tint: widget.tint,
      theme: ft,
      onTap: () => _focus.requestFocus(),
    );

    return _KitoFormField(
      validator: (_) => _validateForForm(),
      onSaved: (_) => widget.onSaved?.call(_controller.text),
      whenReset: _resetForForm,
      builder: (_) => shell,
    );
  }
}

class _KitoFormField extends FormField<String> {
  const _KitoFormField({
    required super.validator,
    required super.onSaved,
    required this.whenReset,
    required super.builder,
  });

  final VoidCallback whenReset;

  @override
  FormFieldState<String> createState() => _KitoFormFieldState();
}

class _KitoFormFieldState extends FormFieldState<String> {
  @override
  void reset() {
    super.reset();
    (widget as _KitoFormField).whenReset();
  }
}

/// A small round icon button for field accessories, with a 44-point tap target.
class KitoFieldIconButton extends StatelessWidget {
  /// Creates a button.
  const KitoFieldIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 20,
    this.color,
    this.toggled,
  });

  /// The icon.
  final IconData icon;

  /// Runs when tapped.
  final VoidCallback? onPressed;

  /// What screen readers say.
  final String semanticLabel;

  /// Icon size.
  final double size;

  /// Icon colour; a muted on-surface colour when null.
  final Color? color;

  /// For toggles (show/hide password): reported as a toggled state.
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Semantics(
      button: true,
      label: semanticLabel,
      toggled: toggled,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: KitoPressable(
          scale: 0.85,
          child: SizedBox(
            width: 36,
            height: 44,
            child: Center(
              child: Icon(icon,
                  size: size,
                  color:
                      color ?? kito.colors.onSurface.withValues(alpha: 0.45)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A multi-line field that grows from [minLines] to [maxLines], with a live character
/// counter that turns amber near [maxLength] and red at it.
class KitoTextArea extends StatelessWidget {
  /// Creates a text area.
  const KitoTextArea({
    super.key,
    this.label,
    this.placeholder,
    this.helper,
    this.controller,
    this.field,
    this.initialValue,
    this.rules = const [],
    this.minLines = 3,
    this.maxLines = 8,
    this.maxLength = 280,
    this.onChanged,
    this.enabled = true,
    this.style,
  });

  /// The label.
  final String? label;

  /// Shown while empty.
  final String? placeholder;

  /// Quiet text under the field.
  final String? helper;

  /// Your controller.
  final TextEditingController? controller;

  /// Shared form state.
  final KitoFormFieldController? field;

  /// The starting text.
  final String? initialValue;

  /// Validation rules.
  final List<KitoValidationRule> rules;

  /// Lines at rest.
  final int minLines;

  /// Lines before it scrolls.
  final int maxLines;

  /// The limit shown in the counter; null hides it.
  final int? maxLength;

  /// Every change.
  final ValueChanged<String>? onChanged;

  /// False disables it.
  final bool enabled;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  @override
  Widget build(BuildContext context) => KitoTextField(
        label: label,
        placeholder: placeholder,
        helper: helper,
        controller: controller,
        field: field,
        initialValue: initialValue,
        rules: rules,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLength,
        showsCounter: maxLength != null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: onChanged,
        enabled: enabled,
        style: style,
      );
}
