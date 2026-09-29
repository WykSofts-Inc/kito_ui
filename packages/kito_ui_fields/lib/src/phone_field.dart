// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'country.dart';
import 'country_picker.dart';
import 'phone.dart';
import 'text_field.dart';
import 'theme.dart';

/// Formats national digits for a region as they're typed, keeping a typed trunk prefix
/// ("0712 345 678" in Kenya), and passes a leading "+" through so a pasted international number
/// can be recognised.
class KitoFieldPhoneFormatter extends TextInputFormatter {
  /// Formats for [country].
  KitoFieldPhoneFormatter(this.country);

  /// The region whose masks are used.
  final KitoFieldCountry country;

  /// [input] written for display.
  String format(String input) {
    final normalized = input.kitoNormalizedDigits.trim();
    if (normalized.startsWith('+')) {
      return '+${normalized.kitoAsciiDigits}';
    }
    var digits = normalized.kitoAsciiDigits;
    final trunk = country.trunkPrefix;
    if (trunk != null &&
        digits.startsWith(trunk) &&
        digits.length > trunk.length) {
      final rest = digits.substring(trunk.length);
      final capped = rest.length > country.maxLength
          ? rest.substring(0, country.maxLength)
          : rest;
      return trunk + country.formatNational(capped);
    }
    if (digits.length > country.maxLength + (trunk?.length ?? 0)) {
      digits = digits.substring(0, country.maxLength + (trunk?.length ?? 0));
    }
    if (trunk != null && digits == trunk) return digits;
    return country.formatNational(digits);
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = format(newValue.text);
    if (formatted == newValue.text) return newValue;
    // Keep the caret after the same number of digits.
    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitsBefore =
        newValue.text.substring(0, caret).kitoAsciiDigits.length;
    var seen = 0;
    var offset = formatted.length;
    for (var i = 0; i < formatted.length; i++) {
      final c = formatted.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) seen++;
      if (seen == digitsBefore) {
        offset = i + 1;
        break;
      }
    }
    if (digitsBefore == 0) offset = formatted.startsWith('+') ? 1 : 0;
    return TextEditingValue(
        text: formatted, selection: TextSelection.collapsed(offset: offset));
  }
}

/// A phone number field with a country picker: flag and dial code at the start, the number
/// formatted for the region as it's typed, and a pasted or autofilled international number
/// ("+254 712 345 678") switching the region by itself. Digits stay left to right in RTL.
///
/// ```dart
/// KitoPhoneField(
///   initialCountry: KitoFieldCountries.kenya,
///   favoriteCountries: const ['KE', 'UG', 'TZ', 'RW'],
///   onChanged: (phone) => form.phone = phone.e164,
/// )
/// ```
class KitoPhoneField extends StatefulWidget {
  /// Creates a phone field.
  const KitoPhoneField({
    super.key,
    this.label = 'Phone number',
    this.helper,
    this.error,
    this.initialCountry,
    this.initialValue,
    this.onChanged,
    this.onCountryChanged,
    this.countries,
    this.favoriteCountries = const [],
    this.isRequired = true,
    this.invalidMessage = 'Enter a valid phone number',
    this.rules = const [],
    this.trigger = KitoValidationTrigger.onBlur,
    this.enabled = true,
    this.canChangeCountry = true,
    this.textInputAction,
    this.onSaved,
    this.style,
    this.tint,
  });

  /// The label.
  final String? label;

  /// Quiet text under the field.
  final String? helper;

  /// An error you set.
  final String? error;

  /// The starting region; the device's region when null.
  final KitoFieldCountry? initialCountry;

  /// A starting number, national or international ("+254712345678").
  final String? initialValue;

  /// Every change, with the parsed number.
  final ValueChanged<KitoFieldPhoneNumber>? onChanged;

  /// When the region changes (picked or detected from a pasted number).
  final ValueChanged<KitoFieldCountry>? onCountryChanged;

  /// Limits the picker; every region when null.
  final List<KitoFieldCountry>? countries;

  /// ISO codes pinned at the top of the picker.
  final List<String> favoriteCountries;

  /// Fails validation when empty.
  final bool isRequired;

  /// The message when the length doesn't fit the region.
  final String invalidMessage;

  /// More rules, run on the formatted text after the built-in check.
  final List<KitoValidationRule> rules;

  /// When errors become visible.
  final KitoValidationTrigger trigger;

  /// False disables it.
  final bool enabled;

  /// False locks the region (no picker).
  final bool canChangeCountry;

  /// The return key.
  final TextInputAction? textInputAction;

  /// Called by `Form.save()` with the parsed number.
  final ValueChanged<KitoFieldPhoneNumber>? onSaved;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  /// Overrides the focus colour.
  final Color? tint;

  @override
  State<KitoPhoneField> createState() => _KitoPhoneFieldState();
}

class _KitoPhoneFieldState extends State<KitoPhoneField> {
  late KitoFieldCountry _country;
  late final TextEditingController _controller;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry ?? KitoFieldCountries.current();
    var text = '';
    final initial = widget.initialValue;
    if (initial != null && initial.trim().isNotEmpty) {
      final parsed =
          KitoFieldPhoneNumber.parse(initial, defaultCountry: _country);
      if (parsed != null) {
        _country = parsed.country;
        text = _country.formatNational(parsed.nationalNumber);
      }
    }
    _controller = TextEditingController(text: text)..addListener(_onText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  KitoFieldPhoneNumber get _number =>
      KitoFieldPhoneNumber(country: _country, nationalNumber: _controller.text);

  void _onText() {
    if (_applying) return;
    final text = _controller.text;
    if (text.startsWith('+') || text.startsWith('00')) {
      final parsed = KitoFieldPhoneNumber.parse(text);
      final digits = text.kitoAsciiDigits;
      // Wait until there's enough to tell the dial code from the number.
      if (parsed != null && digits.length > parsed.country.dialCode.length) {
        _setCountry(parsed.country, notify: parsed.country != _country);
        _apply(parsed.country.formatNational(parsed.nationalNumber));
      }
    }
    widget.onChanged?.call(_number);
  }

  void _apply(String text) {
    _applying = true;
    _controller.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
    _applying = false;
  }

  void _setCountry(KitoFieldCountry country, {bool notify = true}) {
    if (country == _country) return;
    setState(() => _country = country);
    // Re-format what's there for the new region's mask.
    _apply(KitoFieldPhoneFormatter(country)
        .format(_controller.text.kitoAsciiDigits));
    if (notify) widget.onCountryChanged?.call(country);
  }

  Future<void> _pick() async {
    final picked = await KitoFieldCountryPicker.show(
      context,
      selected: _country,
      countries: widget.countries,
      favorites: widget.favoriteCountries,
    );
    if (picked != null && mounted) {
      _setCountry(picked);
      widget.onChanged?.call(_number);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final country = _country;
    final picker = Semantics(
      button: widget.canChangeCountry,
      label: 'Country: ${country.englishName}, ${country.formattedDialCode}',
      excludeSemantics: true,
      onTap: widget.canChangeCountry && widget.enabled ? _pick : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.canChangeCountry && widget.enabled ? _pick : null,
        child: KitoPressable(
          enabled: widget.canChangeCountry,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: KitoMotion.of(context, kito.motion.medium),
                  transitionBuilder: (c, a) => ScaleTransition(
                      scale:
                          CurvedAnimation(parent: a, curve: kito.motion.spring),
                      child: FadeTransition(opacity: a, child: c)),
                  child: Text(country.flag,
                      key: ValueKey(country.isoCode),
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(country.formattedDialCode,
                      style: kito.typography.body.copyWith(
                          color: kito.colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
                if (widget.canChangeCountry)
                  Icon(Icons.expand_more_rounded,
                      size: 18,
                      color: kito.colors.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Container(width: 1, height: 22, color: kito.colors.border),
              ],
            ),
          ),
        ),
      ),
    );

    return KitoTextField(
      label: widget.label,
      helper: widget.helper,
      error: widget.error,
      controller: _controller,
      placeholder: country.formattedExampleNumber,
      leading: picker,
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [KitoFieldPhoneFormatter(country)],
      forceLtr: true,
      trigger: widget.trigger,
      enabled: widget.enabled,
      style: widget.style,
      tint: widget.tint,
      semanticLabel: widget.label ?? 'Phone number',
      onSaved: (_) => widget.onSaved?.call(_number),
      rules: [
        if (widget.isRequired) KitoValidationRule.required(),
        KitoValidationRule.custom(widget.invalidMessage, (v) {
          if (v.trim().isEmpty) return true;
          return KitoFieldPhoneNumber(country: _country, nationalNumber: v)
              .isValid;
        }),
        ...widget.rules,
      ],
    );
  }
}
