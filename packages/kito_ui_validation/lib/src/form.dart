// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

import 'async_rule.dart';
import 'rule.dart';

/// When a field starts showing its errors.
enum KitoValidationTrigger {
  /// As the user types, from the first edit.
  live,

  /// Once the user leaves the field after editing it, then live from there on.
  onBlur,

  /// Only after the form is submitted, then live from there on.
  onSubmit,

  /// Never from rules; only errors you set yourself (a server response) are shown.
  never;

  /// The closest Flutter [AutovalidateMode], for a plain `TextFormField` or [Form].
  AutovalidateMode get autovalidateMode => switch (this) {
        live => AutovalidateMode.onUserInteraction,
        onBlur => AutovalidateMode.onUnfocus,
        onSubmit || never => AutovalidateMode.disabled,
      };
}

/// One field's value, rules and interaction state.
///
/// Get one from [KitoFormController.register], or create it on its own for a single field.
/// Hand [textController] and [focusNode] to any text field (a Kito field, `TextField` or
/// `TextFormField`) and read [error] to show what's wrong, at the moment [trigger] allows.
class KitoFormFieldController extends ChangeNotifier {
  /// Creates a field.
  KitoFormFieldController({
    required this.name,
    String initialValue = '',
    List<KitoValidationRule> rules = const [],
    this.asyncRule,
    this.trigger = KitoValidationTrigger.onBlur,
  })  : _value = initialValue,
        _initialValue = initialValue,
        _rules = rules {
    if (asyncRule != null) {
      _async = KitoAsyncValidator(asyncRule!)..addListener(notifyListeners);
    }
  }

  /// The key it's registered under.
  final String name;

  /// An optional server-side check, run once the sync rules pass.
  final KitoAsyncValidationRule? asyncRule;

  /// When errors become visible.
  final KitoValidationTrigger trigger;

  final String _initialValue;
  String _value;
  List<KitoValidationRule> _rules;
  KitoAsyncValidator? _async;
  TextEditingController? _text;
  FocusNode? _focus;
  String? _externalError;
  bool _edited = false;
  bool _blurred = false;
  bool _submitted = false;
  bool _syncing = false;

  /// The rules, run in order; the first failure wins.
  List<KitoValidationRule> get rules => _rules;
  set rules(List<KitoValidationRule> value) {
    _rules = value;
    notifyListeners();
  }

  /// The current value.
  String get value => _value;
  set value(String newValue) => _update(newValue, fromUser: false);

  /// Records a change the user made (typing, pasting, picking), which counts as an edit.
  void didChange(String newValue) => _update(newValue, fromUser: true);

  void _update(String newValue, {required bool fromUser}) {
    if (newValue == _value) return;
    _value = newValue;
    if (fromUser) {
      _edited = true;
      _externalError = null;
    }
    final text = _text;
    if (text != null && text.text != newValue) {
      _syncing = true;
      text.value = TextEditingValue(
          text: newValue,
          selection: TextSelection.collapsed(offset: newValue.length));
      _syncing = false;
    }
    if (_async != null && ruleError == null) _async!.validate(newValue);
    if (_async != null && ruleError != null) _async!.reset();
    notifyListeners();
  }

  /// A controller kept in sync with [value] both ways. Created on first use, owned (and
  /// disposed) by this field.
  TextEditingController get textController {
    return _text ??= TextEditingController(text: _value)
      ..addListener(() {
        if (!_syncing) didChange(_text!.text);
      });
  }

  /// A focus node that records when the user leaves the field. Created on first use, owned
  /// (and disposed) by this field.
  FocusNode get focusNode {
    return _focus ??= FocusNode(debugLabel: 'KitoFormField($name)')
      ..addListener(() {
        if (!_focus!.hasFocus) didBlur();
      });
  }

  /// Records that the user left the field. Call it yourself if you don't use [focusNode].
  void didBlur() {
    if (!_edited || _blurred) return;
    _blurred = true;
    notifyListeners();
  }

  /// Records a submit attempt, so errors show whatever the [trigger] (except
  /// [KitoValidationTrigger.never]).
  void didSubmit() {
    if (_submitted) return;
    _submitted = true;
    notifyListeners();
  }

  /// True once the user has changed the value.
  bool get isEdited => _edited;

  /// True once the user left the field after editing it.
  bool get isBlurred => _blurred;

  /// True once the form was submitted.
  bool get isSubmitted => _submitted;

  /// True when the value differs from the initial one.
  bool get isDirty => _value != _initialValue;

  /// The first failing sync rule, whether or not it's visible yet.
  String? get ruleError => kitoValidate(_value, _rules);

  /// The async rule's failure, if it has one for the current value.
  String? get asyncError =>
      _async?.checkedValue == _value ? _async?.error : null;

  /// An error you set, e.g. from a server response. Cleared when the user edits the field.
  String? get externalError => _externalError;
  set externalError(String? message) {
    if (message == _externalError) return;
    _externalError = message;
    notifyListeners();
  }

  /// The error the field has right now, visible or not: yours, then the rules', then async.
  String? get currentError => _externalError ?? ruleError ?? asyncError;

  /// Whether the [trigger] lets errors show at this point.
  bool get shouldShowErrors => switch (trigger) {
        KitoValidationTrigger.live => _edited || _submitted,
        KitoValidationTrigger.onBlur => _blurred || _submitted,
        KitoValidationTrigger.onSubmit => _submitted,
        KitoValidationTrigger.never => false,
      };

  /// The error to show under the field, or null. Errors you set are always shown.
  String? get error {
    if (_externalError != null) return _externalError;
    if (!shouldShowErrors) return null;
    return ruleError ?? asyncError;
  }

  /// Where validation stands for the current value.
  KitoValidationStatus get status {
    if (currentError != null) return KitoValidationStatus.invalid;
    if (_async?.isValidating ?? false) return KitoValidationStatus.validating;
    if (_value.isEmpty && _rules.isEmpty) return KitoValidationStatus.idle;
    if (_async != null && _async!.checkedValue != _value && _value.isNotEmpty) {
      return KitoValidationStatus.validating;
    }
    return KitoValidationStatus.valid;
  }

  /// True when the value passes every rule and no check is failing or pending.
  bool get isValid =>
      status == KitoValidationStatus.valid ||
      (status == KitoValidationStatus.idle && currentError == null);

  /// True while the async rule is running.
  bool get isValidating => status == KitoValidationStatus.validating;

  /// For `TextFormField(validator:)`: the rules' first failure, then your error, then async.
  String? Function(String?) get validator => (v) =>
      kitoValidate(v, _rules) ??
      _externalError ??
      (v == _value ? asyncError : null);

  /// Runs the async rule now (no debounce) and waits for it; resolves to [currentError].
  Future<String?> validateNow() async {
    if (ruleError == null && _async != null && _value.trim().isNotEmpty) {
      await _async!.validate(_value, immediate: true);
    }
    return currentError;
  }

  /// Back to the initial value with no interaction recorded.
  void reset() {
    _edited = false;
    _blurred = false;
    _submitted = false;
    _externalError = null;
    _async?.reset();
    _update(_initialValue, fromUser: false);
    notifyListeners();
  }

  @override
  void dispose() {
    _async?.dispose();
    _text?.dispose();
    _focus?.dispose();
    super.dispose();
  }
}

/// A whole form's fields: register each with its rules, then ask whether it's valid, which
/// field fails first, how many are complete, and submit.
///
/// ```dart
/// final form = KitoFormController()
///   ..register('email', rules: [KitoValidationRule.required(), KitoValidationRule.email()])
///   ..register('password', rules: KitoValidationRule.strongPassword());
///
/// if (form.submit()) api.signUp(form.values);
/// ```
class KitoFormController extends ChangeNotifier {
  /// Creates a form; [trigger] is the default for fields that don't set their own.
  KitoFormController({this.trigger = KitoValidationTrigger.onBlur});

  /// When fields show their errors, unless registered with their own trigger.
  final KitoValidationTrigger trigger;

  final Map<String, KitoFormFieldController> _fields = {};
  bool _submitted = false;

  /// Adds a field, or returns the one already registered under [name].
  KitoFormFieldController register(
    String name, {
    String initialValue = '',
    List<KitoValidationRule> rules = const [],
    KitoAsyncValidationRule? asyncRule,
    KitoValidationTrigger? trigger,
  }) {
    final existing = _fields[name];
    if (existing != null) return existing;
    final field = KitoFormFieldController(
      name: name,
      initialValue: initialValue,
      rules: rules,
      asyncRule: asyncRule,
      trigger: trigger ?? this.trigger,
    )..addListener(notifyListeners);
    _fields[name] = field;
    notifyListeners();
    return field;
  }

  /// The field registered under [name].
  KitoFormFieldController operator [](String name) {
    final field = _fields[name];
    if (field == null) {
      throw ArgumentError.value(name, 'name', 'No field registered');
    }
    return field;
  }

  /// Every field, in registration order.
  List<KitoFormFieldController> get fields => List.unmodifiable(_fields.values);

  /// Every value, keyed by field name.
  Map<String, String> get values =>
      {for (final f in _fields.values) f.name: f.value};

  /// The current error per failing field, visible or not.
  Map<String, String> get errors => {
        for (final f in _fields.values)
          if (f.currentError case final e?) f.name: e
      };

  /// The first field that isn't valid, in registration order — to scroll or focus to it.
  String? get firstInvalidField {
    for (final f in _fields.values) {
      if (!f.isValid) return f.name;
    }
    return null;
  }

  /// True when every field is valid.
  bool get isValid => _fields.values.every((f) => f.isValid);

  /// True while any async rule is running.
  bool get isValidating => _fields.values.any((f) => f.isValidating);

  /// How many fields are valid, for "3 of 5 complete".
  int get validCount => _fields.values.where((f) => f.isValid).length;

  /// 0–1 share of valid fields.
  double get progress => _fields.isEmpty ? 0 : validCount / _fields.length;

  /// True once [submit] or [submitAsync] was called.
  bool get isSubmitted => _submitted;

  /// True when any field differs from its initial value.
  bool get isDirty => _fields.values.any((f) => f.isDirty);

  /// Reveals every error and returns whether the form is valid. When [focusFirstInvalid] is
  /// true, the first failing field's [KitoFormFieldController.focusNode] gets focus.
  bool submit({bool focusFirstInvalid = true}) {
    _submitted = true;
    for (final f in _fields.values) {
      f.didSubmit();
    }
    notifyListeners();
    final valid = isValid;
    if (!valid && focusFirstInvalid) _focusFirstInvalid();
    return valid;
  }

  /// Like [submit], but runs every async rule first and waits for them.
  Future<bool> submitAsync({bool focusFirstInvalid = true}) async {
    await Future.wait([for (final f in _fields.values) f.validateNow()]);
    return submit(focusFirstInvalid: focusFirstInvalid);
  }

  /// Shows server-side errors by field name; fields not named keep theirs.
  void setErrors(Map<String, String> errors) {
    errors.forEach((name, message) => _fields[name]?.externalError = message);
  }

  /// Back to initial values with no interaction recorded.
  void reset() {
    _submitted = false;
    for (final f in _fields.values) {
      f.reset();
    }
    notifyListeners();
  }

  void _focusFirstInvalid() {
    final name = firstInvalidField;
    if (name == null) return;
    final field = _fields[name]!;
    // Only move focus when the app actually wired the field's node to a text field.
    if (field._focus?.context != null) field._focus!.requestFocus();
  }

  @override
  void dispose() {
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }
}

/// Makes a [KitoFormController] available below it, so fields can find it with
/// [KitoFormScope.of] and rebuild when it changes.
class KitoFormScope extends InheritedNotifier<KitoFormController> {
  /// Provides [controller] to [child].
  const KitoFormScope(
      {super.key, required KitoFormController controller, required super.child})
      : super(notifier: controller);

  /// The nearest controller, or null.
  static KitoFormController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitoFormScope>()?.notifier;

  /// The nearest controller; throws when there isn't one.
  static KitoFormController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No KitoFormScope above this widget');
    return controller!;
  }
}
