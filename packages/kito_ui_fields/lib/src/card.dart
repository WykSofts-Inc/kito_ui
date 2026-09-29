// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'mask.dart';
import 'text_field.dart';
import 'theme.dart';

/// Payment card networks, detected from the first digits.
enum KitoFieldCardBrand {
  /// Visa (4…).
  visa('Visa', 'VISA', Color(0xFF1A1F71)),

  /// Mastercard (51–55, 2221–2720).
  mastercard('Mastercard', 'MC', Color(0xFFEB001B)),

  /// American Express (34, 37).
  amex('American Express', 'AMEX', Color(0xFF2E77BC)),

  /// Discover (6011, 644–649, 65).
  discover('Discover', 'DISC', Color(0xFFFF6000)),

  /// Diners Club (300–305, 36, 38, 39).
  dinersClub('Diners Club', 'DC', Color(0xFF0079BE)),

  /// JCB (3528–3589).
  jcb('JCB', 'JCB', Color(0xFF0B4EA2)),

  /// UnionPay (62).
  unionPay('UnionPay', 'UP', Color(0xFFD10429)),

  /// Not recognised (yet).
  unknown('Card', '', Color(0xFF8E8E93));

  const KitoFieldCardBrand(this.displayName, this.badge, this.color);

  /// "American Express".
  final String displayName;

  /// A short badge ("AMEX").
  final String badge;

  /// The badge colour.
  final Color color;

  /// How the digits are grouped.
  String get mask => switch (this) {
        amex => '#### ###### #####',
        dinersClub => '#### ###### ####',
        _ => '#### #### #### ####',
      };

  /// Digits in a full number.
  int get numberLength => switch (this) {
        amex => 15,
        dinersClub => 14,
        _ => 16,
      };

  /// Security code digits.
  int get cvvLength => this == amex ? 4 : 3;

  /// The brand for the digits typed so far.
  static KitoFieldCardBrand detect(String number) {
    final d = number.kitoAsciiDigits;
    if (d.isEmpty) return unknown;
    int? prefix(int n) => d.length >= n ? int.parse(d.substring(0, n)) : null;
    if (d.startsWith('4')) return visa;
    if (d.startsWith('34') || d.startsWith('37')) return amex;
    final two = prefix(2), three = prefix(3), four = prefix(4);
    if (two != null && two >= 51 && two <= 55) return mastercard;
    if (four != null && four >= 2221 && four <= 2720) return mastercard;
    if (d.startsWith('6011') ||
        d.startsWith('65') ||
        (three != null && three >= 644 && three <= 649)) {
      return discover;
    }
    if (four != null && four >= 3528 && four <= 3589) return jcb;
    if (d.startsWith('36') ||
        d.startsWith('38') ||
        d.startsWith('39') ||
        (three != null && three >= 300 && three <= 305)) {
      return dinersClub;
    }
    if (d.startsWith('62')) return unionPay;
    return unknown;
  }
}

/// A small badge for a card brand that flips in when the brand changes.
class KitoFieldCardBadge extends StatelessWidget {
  /// Shows [brand].
  const KitoFieldCardBadge({super.key, required this.brand});

  /// The brand.
  final KitoFieldCardBrand brand;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, kito.motion.medium),
      transitionBuilder: (child, a) => ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: kito.motion.spring),
          child: FadeTransition(opacity: a, child: child)),
      child: brand == KitoFieldCardBrand.unknown
          ? Icon(Icons.credit_card_rounded,
              key: const ValueKey('none'),
              size: 22,
              color: kito.colors.onSurface.withValues(alpha: 0.4))
          : Semantics(
              key: ValueKey(brand),
              label: brand.displayName,
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                    color: brand.color, borderRadius: BorderRadius.circular(5)),
                child: Text(brand.badge,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ),
    );
  }
}

/// A card number field: detects the brand as you type, groups the digits for it, shows a badge
/// and checks the Luhn checksum. Digits stay left to right in RTL.
class KitoCardNumberField extends StatefulWidget {
  /// Creates a card number field.
  const KitoCardNumberField({
    super.key,
    this.label = 'Card number',
    this.placeholder = '1234 5678 9012 3456',
    this.controller,
    this.onChanged,
    this.onBrandChanged,
    this.error,
    this.trigger = KitoValidationTrigger.onBlur,
    this.invalidMessage = 'Check the card number',
    this.enabled = true,
    this.style,
  });

  /// The label.
  final String? label;

  /// Shown while empty.
  final String? placeholder;

  /// Your controller.
  final TextEditingController? controller;

  /// Every change, with the digits only.
  final ValueChanged<String>? onChanged;

  /// When the detected brand changes (use it to size the CVV field).
  final ValueChanged<KitoFieldCardBrand>? onBrandChanged;

  /// An error you set.
  final String? error;

  /// When errors become visible.
  final KitoValidationTrigger trigger;

  /// Shown when the number fails its checksum or is too short.
  final String invalidMessage;

  /// False disables it.
  final bool enabled;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  @override
  State<KitoCardNumberField> createState() => _KitoCardNumberFieldState();
}

class _KitoCardNumberFieldState extends State<KitoCardNumberField> {
  KitoFieldCardBrand _brand = KitoFieldCardBrand.unknown;

  @override
  void initState() {
    super.initState();
    final text = widget.controller?.text;
    if (text != null) _brand = KitoFieldCardBrand.detect(text);
  }

  void _changed(String text) {
    final brand = KitoFieldCardBrand.detect(text);
    if (brand != _brand) {
      setState(() => _brand = brand);
      widget.onBrandChanged?.call(brand);
    }
    widget.onChanged?.call(text.kitoAsciiDigits);
  }

  @override
  Widget build(BuildContext context) {
    return KitoTextField(
      label: widget.label,
      placeholder: widget.placeholder,
      controller: widget.controller,
      error: widget.error,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.creditCardNumber],
      inputFormatters: [_BrandMaskFormatter()],
      forceLtr: true,
      enabled: widget.enabled,
      style: widget.style,
      trigger: widget.trigger,
      onChanged: _changed,
      trailing: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: KitoFieldCardBadge(brand: _brand),
      ),
      rules: [
        KitoValidationRule.required(),
        KitoValidationRule.custom(widget.invalidMessage, (v) {
          final digits = v.kitoAsciiDigits;
          final brand = KitoFieldCardBrand.detect(digits);
          final lengthOk = brand == KitoFieldCardBrand.unknown
              ? digits.length >= 12
              : digits.length >= brand.numberLength ||
                  (brand == KitoFieldCardBrand.dinersClub &&
                      digits.length == 16);
          return lengthOk && kitoPassesLuhn(digits);
        }),
      ],
    );
  }
}

/// Groups the digits with the mask of the brand they belong to.
class _BrandMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      KitoFieldMask(KitoFieldCardBrand.detect(newValue.text).mask)
          .formatter
          .formatEditUpdate(oldValue, newValue);
}

/// A card expiry field: types as MM/YY, the slash added for you, and rejects past dates.
class KitoCardExpiryField extends StatelessWidget {
  /// Creates an expiry field.
  const KitoCardExpiryField({
    super.key,
    this.label = 'Expiry',
    this.placeholder = 'MM/YY',
    this.controller,
    this.onChanged,
    this.error,
    this.trigger = KitoValidationTrigger.onBlur,
    this.enabled = true,
    this.style,
    this.now,
  });

  /// The label.
  final String? label;

  /// Shown while empty.
  final String? placeholder;

  /// Your controller.
  final TextEditingController? controller;

  /// Every change, as typed ("08/27").
  final ValueChanged<String>? onChanged;

  /// An error you set.
  final String? error;

  /// When errors become visible.
  final KitoValidationTrigger trigger;

  /// False disables it.
  final bool enabled;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  /// "Today", for tests.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) => KitoTextField(
        label: label,
        placeholder: placeholder,
        controller: controller,
        error: error,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.creditCardExpirationDate],
        inputFormatters: [const KitoFieldMask('##/##').formatter],
        forceLtr: true,
        enabled: enabled,
        style: style,
        trigger: trigger,
        onChanged: onChanged,
        rules: [
          KitoValidationRule.required(),
          KitoValidationRule.cardExpiry(now: now),
        ],
      );
}

/// A card security code field: 3 digits, or 4 for American Express; hidden as it's typed.
class KitoCardCvvField extends StatelessWidget {
  /// Creates a CVV field.
  const KitoCardCvvField({
    super.key,
    this.label = 'CVV',
    this.placeholder = '•••',
    this.brand = KitoFieldCardBrand.unknown,
    this.controller,
    this.onChanged,
    this.error,
    this.trigger = KitoValidationTrigger.onBlur,
    this.obscureText = true,
    this.enabled = true,
    this.style,
  });

  /// The label.
  final String? label;

  /// Shown while empty.
  final String? placeholder;

  /// Sets the length (4 for Amex).
  final KitoFieldCardBrand brand;

  /// Your controller.
  final TextEditingController? controller;

  /// Every change.
  final ValueChanged<String>? onChanged;

  /// An error you set.
  final String? error;

  /// When errors become visible.
  final KitoValidationTrigger trigger;

  /// Hides the digits.
  final bool obscureText;

  /// False disables it.
  final bool enabled;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  @override
  Widget build(BuildContext context) => KitoTextField(
        label: label,
        placeholder: brand.cvvLength == 4 ? '••••' : placeholder,
        controller: controller,
        error: error,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.creditCardSecurityCode],
        inputFormatters: [
          KitoFieldDigitsFormatter(digitsOnly: true, maxLength: brand.cvvLength)
        ],
        obscureText: obscureText,
        forceLtr: true,
        enabled: enabled,
        style: style,
        trigger: trigger,
        onChanged: onChanged,
        rules: [
          KitoValidationRule.required(),
          KitoValidationRule.exactLength(brand.cvvLength,
              message: 'Enter the ${brand.cvvLength}-digit code'),
        ],
      );
}
