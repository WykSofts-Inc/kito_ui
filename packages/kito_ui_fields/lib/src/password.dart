// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import 'resize.dart';
import 'text_field.dart';
import 'theme.dart';

/// How the strength meter is drawn.
enum KitoPasswordMeterStyle {
  /// Four segments that light up in turn.
  segments,

  /// One bar that fills and recolours.
  bar,

  /// Just the label.
  label,
}

/// The colour for a password score under [theme].
Color kitoPasswordScoreColor(KitoTheme theme, KitoPasswordScore score) =>
    switch (score) {
      KitoPasswordScore.veryWeak => theme.colors.danger,
      KitoPasswordScore.weak =>
        Color.lerp(theme.colors.danger, theme.colors.warning, 0.5)!,
      KitoPasswordScore.medium => theme.colors.warning,
      KitoPasswordScore.strong =>
        Color.lerp(theme.colors.warning, theme.colors.success, 0.6)!,
      KitoPasswordScore.veryStrong => theme.colors.success,
    };

/// A password strength meter: segments or a bar that fill and recolour, and the score's label.
class KitoPasswordStrengthMeter extends StatelessWidget {
  /// Shows [score].
  const KitoPasswordStrengthMeter({
    super.key,
    required this.score,
    this.style = KitoPasswordMeterStyle.segments,
    this.showsLabel = true,
    this.height = 4,
  });

  /// The score to show.
  final KitoPasswordScore score;

  /// Segments, bar or label only.
  final KitoPasswordMeterStyle style;

  /// Shows "Strong" and friends next to the meter.
  final bool showsLabel;

  /// Bar thickness.
  final double height;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final color = kitoPasswordScoreColor(kito, score);
    final medium = KitoMotion.of(context, kito.motion.medium);
    final track = kito.colors.surfaceMuted;
    final lit = score
        .index; // 0–4; segments light one per point, veryWeak lights one dimly.

    final Widget meter = switch (style) {
      KitoPasswordMeterStyle.segments => Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: medium,
                  curve: kito.motion.standard,
                  height: height,
                  decoration: BoxDecoration(
                    color: i < lit || (i == 0 && lit == 0)
                        ? color.withValues(alpha: lit == 0 ? 0.6 : 1)
                        : track,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ],
        ),
      KitoPasswordMeterStyle.bar => Container(
          height: height,
          decoration: BoxDecoration(
              color: track, borderRadius: BorderRadius.circular(height)),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: score.fraction),
            duration: medium,
            curve: kito.motion.spring,
            builder: (context, v, _) => FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: v.clamp(0, 1),
              child: AnimatedContainer(
                duration: medium,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(height)),
              ),
            ),
          ),
        ),
      KitoPasswordMeterStyle.label => const SizedBox.shrink(),
    };

    return Semantics(
      label: 'Password strength',
      value: score.label,
      excludeSemantics: true,
      child: Row(
        children: [
          if (style != KitoPasswordMeterStyle.label) Expanded(child: meter),
          if (showsLabel) ...[
            if (style != KitoPasswordMeterStyle.label)
              const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: medium,
              transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                      position:
                          Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                              .animate(a),
                      child: c)),
              child: Text(
                score.label,
                key: ValueKey(score),
                style: kito.typography.caption
                    .copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A checklist of rules that tick off, with a spring, as the value meets them.
class KitoFieldRequirementsChecklist extends StatelessWidget {
  /// Shows each of [rules] against [value].
  const KitoFieldRequirementsChecklist({
    super.key,
    required this.value,
    required this.rules,
    this.showsOnlyUnmet = false,
    this.hidesWhenAllMet = false,
  });

  /// What's being checked.
  final String value;

  /// One line per rule, using its message.
  final List<KitoValidationRule> rules;

  /// Hides rules already met.
  final bool showsOnlyUnmet;

  /// Hides the whole list once everything passes.
  final bool hidesWhenAllMet;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final results = kitoEvaluate(value, rules);
    final allMet = results.every((r) => r.passed);
    final medium = KitoMotion.of(context, kito.motion.medium);
    final shown = [
      for (final r in results)
        if (!showsOnlyUnmet || !r.passed) r
    ];
    return FieldResize(
      duration: medium,
      curve: kito.motion.standard,
      alignment: AlignmentDirectional.topStart,
      child: hidesWhenAllMet && allMet
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Semantics(
                      label: r.message,
                      value: r.passed ? 'Met' : 'Not met',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: medium,
                            transitionBuilder: (c, a) => ScaleTransition(
                                scale: CurvedAnimation(
                                    parent: a, curve: kito.motion.spring),
                                child: c),
                            child: Icon(
                              r.passed
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              key: ValueKey(r.passed),
                              size: 16,
                              color: r.passed
                                  ? kito.colors.success
                                  : kito.colors.onSurface
                                      .withValues(alpha: 0.35),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: AnimatedDefaultTextStyle(
                              duration: medium,
                              style: kito.typography.caption.copyWith(
                                color: r.passed
                                    ? kito.colors.onSurface
                                        .withValues(alpha: 0.85)
                                    : kito.colors.onSurface
                                        .withValues(alpha: 0.55),
                              ),
                              child: Text(r.message),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// A password field with a show/hide toggle, an optional strength meter and an optional
/// requirements checklist that ticks off as the user types.
///
/// ```dart
/// KitoPasswordField(
///   showsStrength: true,
///   requirements: KitoValidationRule.strongPassword(),
///   isNewPassword: true,
/// )
/// ```
class KitoPasswordField extends StatefulWidget {
  /// Creates a password field.
  const KitoPasswordField({
    super.key,
    this.label = 'Password',
    this.placeholder,
    this.helper,
    this.error,
    this.controller,
    this.field,
    this.rules = const [],
    this.requirements = const [],
    this.showsStrength = false,
    this.meterStyle = KitoPasswordMeterStyle.segments,
    this.hidesChecklistWhenMet = false,
    this.isNewPassword = false,
    this.trigger = KitoValidationTrigger.onBlur,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.style,
    this.tint,
  });

  /// The label.
  final String? label;

  /// Shown while empty.
  final String? placeholder;

  /// Quiet text under the field.
  final String? helper;

  /// An error you set.
  final String? error;

  /// Your controller.
  final TextEditingController? controller;

  /// Shared form state.
  final KitoFormFieldController? field;

  /// Rules whose first failure shows as the error.
  final List<KitoValidationRule> rules;

  /// Rules shown as a live checklist under the field (and also validated).
  final List<KitoValidationRule> requirements;

  /// Shows a strength meter while there's text.
  final bool showsStrength;

  /// How the meter looks.
  final KitoPasswordMeterStyle meterStyle;

  /// Hides the checklist once every requirement passes.
  final bool hidesChecklistWhenMet;

  /// Tells autofill this is a new password (sign-up, reset) so it can suggest one.
  final bool isNewPassword;

  /// When errors become visible.
  final KitoValidationTrigger trigger;

  /// The return key.
  final TextInputAction? textInputAction;

  /// Every change.
  final ValueChanged<String>? onChanged;

  /// The return key.
  final ValueChanged<String>? onSubmitted;

  /// False disables it.
  final bool enabled;

  /// Overrides the theme's style.
  final KitoFieldStyle? style;

  /// Overrides the focus colour.
  final Color? tint;

  @override
  State<KitoPasswordField> createState() => _KitoPasswordFieldState();
}

class _KitoPasswordFieldState extends State<KitoPasswordField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return KitoTextField(
      label: widget.label,
      placeholder: widget.placeholder,
      helper: widget.helper,
      error: widget.error,
      controller: widget.controller,
      field: widget.field,
      rules: [...widget.rules, ...widget.requirements],
      trigger: widget.trigger,
      obscureText: !_revealed,
      leadingIcon: Icons.lock_outline_rounded,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: [
        widget.isNewPassword
            ? AutofillHints.newPassword
            : AutofillHints.password
      ],
      normalizesDigits: false,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      style: widget.style,
      tint: widget.tint,
      trailing: KitoFieldIconButton(
        icon:
            _revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        semanticLabel: _revealed ? 'Hide password' : 'Show password',
        toggled: _revealed,
        color: _revealed ? kito.accent(widget.tint) : null,
        onPressed: () => setState(() => _revealed = !_revealed),
      ),
      footerBuilder: (widget.showsStrength || widget.requirements.isNotEmpty)
          ? (context, value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showsStrength)
                    FieldResize(
                      duration: KitoMotion.of(context, kito.motion.medium),
                      child: value.isEmpty
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: KitoPasswordStrengthMeter(
                                score: KitoPasswordScore.evaluate(value),
                                style: widget.meterStyle,
                              ),
                            ),
                    ),
                  if (widget.requirements.isNotEmpty)
                    KitoFieldRequirementsChecklist(
                      value: value,
                      rules: widget.requirements,
                      hidesWhenAllMet: widget.hidesChecklistWhenMet,
                    ),
                ],
              )
          : null,
    );
  }
}
