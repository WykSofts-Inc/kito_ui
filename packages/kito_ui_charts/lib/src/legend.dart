// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'theme.dart';

/// One row of a [KitoChartLegend].
@immutable
class KitoChartLegendEntry {
  /// Creates an entry.
  const KitoChartLegendEntry(this.label, this.color, {this.value});

  /// The series or slice name.
  final String label;

  /// Its swatch.
  final Color color;

  /// An optional figure after the label, e.g. "42%".
  final String? value;
}

/// A wrapping legend: a swatch and a label per series or slice.
///
/// With [onTap] each entry becomes a button (44 points tall, announced as selected when
/// [highlighted]), which is also how screen-reader users pick a pie slice.
class KitoChartLegend extends StatelessWidget {
  /// Creates a legend.
  const KitoChartLegend({
    super.key,
    required this.entries,
    this.highlighted,
    this.onTap,
    this.alignment = WrapAlignment.start,
    this.spacing = 14,
  });

  /// The rows, in order.
  final List<KitoChartLegendEntry> entries;

  /// The entry to emphasise; the others dim. Null shows all at full strength.
  final int? highlighted;

  /// Called with an entry's index when it's tapped.
  final ValueChanged<int>? onTap;

  /// How rows line up.
  final WrapAlignment alignment;

  /// The gap between entries.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final chart = KitoChartTheme.of(context);
    final duration = KitoMotion.of(context, theme.motion.medium);
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: onTap == null ? 6 : 0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < entries.length; i++)
          _entry(context, i, chart, duration),
      ],
    );
  }

  Widget _entry(
      BuildContext context, int i, KitoChartTheme chart, Duration duration) {
    final entry = entries[i];
    final active = highlighted == null || highlighted == i;
    final style = chart.labelStyle!.copyWith(
        fontSize: 12,
        color: highlighted == i
            ? context.kito.colors.onSurface
            : chart.labelColor);
    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: duration,
          curve: context.kito.motion.spring,
          width: highlighted == i ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
              color: entry.color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(text: entry.label, children: [
              if (entry.value != null)
                TextSpan(
                    text: '  ${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    row = AnimatedOpacity(
        opacity: active ? 1 : 0.4, duration: duration, child: row);
    if (onTap == null) {
      return Semantics(
          label: entry.value == null
              ? entry.label
              : '${entry.label}, ${entry.value}',
          excludeSemantics: true,
          child: row);
    }
    return Semantics(
      button: true,
      selected: highlighted == i,
      label:
          entry.value == null ? entry.label : '${entry.label}, ${entry.value}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap!(i),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: KitoPressable(child: row)),
        ),
      ),
    );
  }
}
