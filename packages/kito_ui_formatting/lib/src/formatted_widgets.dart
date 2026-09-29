// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'formatting_strings.dart';
import 'number_formatting.dart';

/// Formats a number for display.
typedef KitoNumberFormatter = String Function(double value);

String _defaultFormat(double v) => KitoNumberFormatting.grouped(v);

/// A number whose digits roll to their new value whenever it changes — a balance, a cart total,
/// a live counter. Digits roll up when the number grows and down when it shrinks; only the
/// characters that changed move. Under Reduce Motion it simply updates.
///
/// ```dart
/// KitoFormattedNumberText(
///   balance,
///   format: (v) => KitoMoneyFormatting.string(v, KitoCurrency.kes),
///   style: Theme.of(context).textTheme.headlineMedium,
/// )
/// ```
class KitoFormattedNumberText extends StatefulWidget {
  /// Creates a rolling number.
  const KitoFormattedNumberText(
    this.value, {
    super.key,
    this.format = _defaultFormat,
    this.style,
    this.duration = const Duration(milliseconds: 350),
    this.textAlign,
  });

  /// The number.
  final double value;

  /// How it's written; grouped digits by default.
  final KitoNumberFormatter format;

  /// Text style; tabular figures are added so digits don't jiggle.
  final TextStyle? style;

  /// How long a roll takes.
  final Duration duration;

  /// Alignment inside a wider box.
  final TextAlign? textAlign;

  @override
  State<KitoFormattedNumberText> createState() =>
      _KitoFormattedNumberTextState();
}

class _KitoFormattedNumberTextState extends State<KitoFormattedNumberText> {
  bool _rising = true;

  @override
  void didUpdateWidget(KitoFormattedNumberText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _rising = widget.value > oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.format(widget.value);
    final style =
        DefaultTextStyle.of(context).style.merge(widget.style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (context.reduceMotion) {
      return Text(text, style: style, textAlign: widget.textAlign);
    }
    final chars = text.characters.toList();
    final rising = _rising;
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: DefaultTextStyle(
          style: style,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // Keyed from the right, so units stay units when the number gains a digit.
            textDirection: TextDirection.ltr,
            children: [
              for (var i = 0; i < chars.length; i++)
                ClipRect(
                  key: ValueKey(chars.length - i),
                  child: AnimatedSwitcher(
                    duration: widget.duration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final entering = child.key ==
                          ValueKey('${chars.length - i}:${chars[i]}');
                      final from = Offset(0, rising ? 1 : -1);
                      final to = Offset(0, rising ? -1 : 1);
                      final slide = entering
                          ? Tween(begin: from, end: Offset.zero)
                          : Tween(begin: to, end: Offset.zero);
                      return SlideTransition(
                        position: slide.animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.center,
                      children: [...previous, if (current != null) current],
                    ),
                    child: Text(chars[i],
                        key: ValueKey('${chars.length - i}:${chars[i]}')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Counts through every value between the old number and the new one, like a scoreboard —
/// counting in from zero when it first appears if [startFromZero]. Under Reduce Motion it
/// jumps straight to the value. Screen readers hear only the final value.
class KitoFormattedCountingText extends StatefulWidget {
  /// Creates a counting number.
  const KitoFormattedCountingText(
    this.value, {
    super.key,
    this.duration = const Duration(milliseconds: 1100),
    this.startFromZero = true,
    this.format = _defaultFormat,
    this.style,
    this.curve = Curves.easeOutCubic,
  });

  /// The number to land on.
  final double value;

  /// How long the count takes.
  final Duration duration;

  /// Count in from 0 on first appearance.
  final bool startFromZero;

  /// How it's written; grouped digits by default.
  final KitoNumberFormatter format;

  /// Text style; tabular figures are added.
  final TextStyle? style;

  /// The count's easing.
  final Curve curve;

  @override
  State<KitoFormattedCountingText> createState() =>
      _KitoFormattedCountingTextState();
}

class _KitoFormattedCountingTextState extends State<KitoFormattedCountingText> {
  late double _begin = widget.startFromZero ? 0 : widget.value;
  double _shown = 0;

  @override
  void didUpdateWidget(KitoFormattedCountingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _begin = _shown;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        const TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    return Semantics(
      label: widget.format(widget.value),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          // A fresh tween each time the target changes, starting where the count was.
          key: ValueKey(widget.value),
          tween: Tween(begin: _begin, end: widget.value),
          duration: KitoMotion.of(context, widget.duration),
          curve: widget.curve,
          builder: (context, v, _) {
            _shown = v;
            return Text(widget.format(v), style: style);
          },
        ),
      ),
    );
  }
}

/// How [KitoFormattedChangeBadge] is drawn.
enum KitoFormattedChangeBadgeStyle {
  /// A tinted capsule with an arrow — stat tiles and portfolio rows.
  pill,

  /// Coloured text and arrow, no background — inline in a sentence or table.
  plain,

  /// A solid capsule with white text — the loudest, for a hero number.
  solid,
}

/// "+12.4%" in green with an up arrow, "−3.1%" in red with a down arrow, grey when flat —
/// coloured from the theme's success and danger. Arrows point forward, so they mirror in RTL.
///
/// ```dart
/// KitoFormattedChangeBadge(0.124)
/// KitoFormattedChangeBadge(-0.08, invertColors: true)   // spending went down: good
/// ```
class KitoFormattedChangeBadge extends StatelessWidget {
  /// Creates a change badge for a fraction (0.124 = +12.4%).
  const KitoFormattedChangeBadge(
    this.fraction, {
    super.key,
    this.fractionDigits = 1,
    this.style = KitoFormattedChangeBadgeStyle.pill,
    this.invertColors = false,
  });

  /// The change as a fraction.
  final double fraction;

  /// Digits after the decimal point.
  final int fractionDigits;

  /// Pill, plain or solid.
  final KitoFormattedChangeBadgeStyle style;

  /// For numbers where down is good (spending, delivery time).
  final bool invertColors;

  /// The icon for [trend].
  static IconData iconFor(KitoFormattedTrend trend) => switch (trend) {
        KitoFormattedTrend.up => Icons.north_east_rounded,
        KitoFormattedTrend.down => Icons.south_east_rounded,
        KitoFormattedTrend.flat => Icons.east_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final trend = KitoFormattedTrend.of(fraction);
    final tint = switch (trend) {
      KitoFormattedTrend.flat =>
        kito.colors.onBackground.withValues(alpha: 0.55),
      KitoFormattedTrend.up =>
        invertColors ? kito.colors.danger : kito.colors.success,
      KitoFormattedTrend.down =>
        invertColors ? kito.colors.success : kito.colors.danger,
    };
    final text = KitoNumberFormatting.signedPercent(fraction,
        fractionDigits: fractionDigits, locale: locale);
    final fg =
        style == KitoFormattedChangeBadgeStyle.solid ? Colors.white : tint;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.flip(
          flipX: context.isRtl,
          child: Icon(iconFor(trend), size: 13, color: fg),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: kito.typography.caption.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    final Widget body = switch (style) {
      KitoFormattedChangeBadgeStyle.plain => row,
      KitoFormattedChangeBadgeStyle.pill => AnimatedContainer(
          duration: KitoMotion.of(context, kito.motion.medium),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: row,
        ),
      KitoFormattedChangeBadgeStyle.solid => AnimatedContainer(
          duration: KitoMotion.of(context, kito.motion.medium),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: row,
        ),
    };
    return Semantics(
      container: true,
      label:
          '${KitoFormattingStrings.lookup(trend.name, locale: locale)} $text',
      child: ExcludeSemantics(child: body),
    );
  }
}
