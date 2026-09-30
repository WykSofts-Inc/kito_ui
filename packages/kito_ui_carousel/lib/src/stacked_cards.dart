// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Wallet-style stacked cards. Collapsed, the cards sit in a tight pile with the edges of the
/// ones behind peeking out; tap to fan them out into a list, tap one to bring it forward with the
/// rest tucked beneath, tap it again to go back to the list.
///
/// ```dart
/// KitoStackedCards(
///   itemCount: passes.length,
///   itemBuilder: (context, i) => PassCard(passes[i]),
///   onSelectionChanged: (i) => setState(() => pass = i),
/// )
/// ```
///
/// Later cards sit in front, as in Wallet. [selected] and [expanded] set the state from outside;
/// taps change it and report through [onSelectionChanged] and [onExpandedChanged].
class KitoStackedCards extends StatefulWidget {
  /// Creates a stack.
  const KitoStackedCards({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.selected,
    this.expanded = false,
    this.onSelectionChanged,
    this.onExpandedChanged,
    this.cardHeight = 200,
    this.collapsedSpacing = 12,
    this.expandedSpacing = 72,
    this.maxCollapsedVisible = 4,
    this.tint,
    this.semanticLabelBuilder,
  });

  /// How many cards.
  final int itemCount;

  /// Builds card `index`; it's given the full width and [cardHeight].
  final IndexedWidgetBuilder itemBuilder;

  /// The card brought forward, or null.
  final int? selected;

  /// Whether the cards are fanned out.
  final bool expanded;

  /// Called when a tap brings a card forward (or sends it back, with null).
  final ValueChanged<int?>? onSelectionChanged;

  /// Called when a tap fans the cards out or gathers them.
  final ValueChanged<bool>? onExpandedChanged;

  /// One card's height.
  final double cardHeight;

  /// How much of each card behind peeks out when collapsed.
  final double collapsedSpacing;

  /// How much of each card shows when fanned out.
  final double expandedSpacing;

  /// Cards drawn in the collapsed pile.
  final int maxCollapsedVisible;

  /// The shadow colour; black when null.
  final Color? tint;

  /// What screen readers call card `index`; "Card 2 of 5" when null.
  final String Function(int index)? semanticLabelBuilder;

  @override
  State<KitoStackedCards> createState() => _KitoStackedCardsState();
}

/// Where one card sits.
@immutable
class _Placement {
  const _Placement(
      {this.y = 0,
      this.scale = 1,
      this.tilt = 0,
      this.opacity = 1,
      this.z = 0,
      this.front = false});
  final double y;
  final double scale;
  final double tilt;
  final double opacity;
  final double z;
  final bool front;
}

class _KitoStackedCardsState extends State<KitoStackedCards> {
  late int? _selected = widget.selected;
  late bool _expanded = widget.expanded;

  @override
  void didUpdateWidget(KitoStackedCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) _selected = widget.selected;
    if (widget.expanded != oldWidget.expanded) _expanded = widget.expanded;
  }

  int? get _validSelection =>
      _selected != null && _selected! >= 0 && _selected! < widget.itemCount
          ? _selected
          : null;

  int get _visible => math.max(widget.maxCollapsedVisible, 1);

  _Placement _placement(int i, double gap) {
    final n = widget.itemCount;
    final sel = _validSelection;
    if (sel != null) {
      if (i == sel) return _Placement(z: n + 1.0, front: true);
      final position = i < sel ? i : i - 1;
      final others = n - 1;
      final depth = others - 1 - position;
      final visibleDepth = math.min(depth, _visible - 1);
      final tucked = math.min(others, _visible);
      return _Placement(
        y: widget.cardHeight +
            gap +
            (tucked - 1 - visibleDepth) * widget.collapsedSpacing * 0.7,
        scale: 0.92 - visibleDepth * 0.04,
        opacity: depth >= _visible ? 0 : 1,
        z: i.toDouble(),
      );
    }
    if (_expanded) {
      return _Placement(
        y: i * widget.expandedSpacing,
        tilt: i == n - 1 ? 0 : -4,
        z: i.toDouble(),
        front: i == n - 1,
      );
    }
    final depth = n - 1 - i;
    final visibleDepth = math.min(depth, _visible - 1);
    return _Placement(
      y: (_visible - 1 - visibleDepth) * widget.collapsedSpacing -
          math.max(0, _visible - n) * widget.collapsedSpacing,
      scale: 1 - visibleDepth * 0.05,
      opacity: depth >= _visible ? 0 : 1,
      z: i.toDouble(),
      front: depth == 0,
    );
  }

  double _height(double gap) {
    final n = widget.itemCount;
    if (n == 0) return 0;
    if (_validSelection != null) {
      if (n == 1) return widget.cardHeight;
      return widget.cardHeight * 1.92 +
          gap +
          (math.min(n - 1, _visible) - 1) * widget.collapsedSpacing * 0.7;
    }
    if (_expanded) return (n - 1) * widget.expandedSpacing + widget.cardHeight;
    return (math.min(n, _visible) - 1) * widget.collapsedSpacing +
        widget.cardHeight;
  }

  void _tap(int i) {
    HapticFeedback.lightImpact();
    final sel = _validSelection;
    setState(() {
      if (sel == null && !_expanded) {
        _expanded = true;
        widget.onExpandedChanged?.call(true);
      } else if (sel == null) {
        _selected = i;
        widget.onSelectionChanged?.call(i);
      } else {
        _selected = null;
        widget.onSelectionChanged?.call(null);
        if (sel != i && !_expanded) {
          _expanded = true;
          widget.onExpandedChanged?.call(true);
        }
      }
    });
  }

  String _hint() {
    if (_validSelection != null) return 'Goes back to all cards';
    return _expanded ? 'Brings this card forward' : 'Shows all cards';
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final gap = kito.spacing.xl;
    final n = widget.itemCount;
    final reduce = context.reduceMotion;
    final placements = [for (var i = 0; i < n; i++) _placement(i, gap)];
    final order = [for (var i = 0; i < n; i++) i]
      ..sort((a, b) => placements[a].z.compareTo(placements[b].z));
    final radius = BorderRadius.circular(kito.radii.xl);
    final shadow = widget.tint ?? Colors.black;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: _height(gap)),
      duration: KitoMotion.of(context, const Duration(milliseconds: 500)),
      curve: Curves.easeOutCubic,
      builder: (context, height, child) => SizedBox(
        height: height,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final i in order)
            _AnimatedCard(
              key: ValueKey(i),
              placement: placements[i],
              reduceMotion: reduce,
              delay: Duration(milliseconds: 25 * i),
              child: Semantics(
                container: true,
                button: true,
                selected: _validSelection == i,
                label: widget.semanticLabelBuilder?.call(i) ??
                    'Card ${i + 1} of $n',
                hint: _hint(),
                onTap: () => _tap(i),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tap(i),
                  child: Container(
                    height: widget.cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: shadow.withValues(
                              alpha: placements[i].front ? 0.22 : 0.12),
                          blurRadius: placements[i].front ? 36 : 16,
                          offset: Offset(0, placements[i].front ? 12 : 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: widget.itemBuilder(context, i),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Glides a card to its [placement], a little after the one before it.
class _AnimatedCard extends ImplicitlyAnimatedWidget {
  _AnimatedCard({
    super.key,
    required this.placement,
    required this.reduceMotion,
    required Duration delay,
    required this.child,
  }) : super(
          duration: reduceMotion
              ? const Duration(milliseconds: 200)
              : const Duration(milliseconds: 520) + delay,
          curve: reduceMotion
              ? Curves.easeInOut
              : Interval(delay.inMilliseconds / (520 + delay.inMilliseconds), 1,
                  curve: Curves.easeOutBack),
        );

  final _Placement placement;
  final bool reduceMotion;
  final Widget child;

  @override
  AnimatedWidgetBaseState<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends AnimatedWidgetBaseState<_AnimatedCard> {
  Tween<double>? _y, _scale, _tilt, _opacity;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    final p = widget.placement;
    _y = visitor(_y, p.y, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
    _scale = visitor(_scale, p.scale, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
    _tilt = visitor(_tilt, p.tilt, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
    _opacity =
        visitor(_opacity, p.opacity, (v) => Tween<double>(begin: v as double))
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final a = animation;
    final y = _y?.evaluate(a) ?? 0;
    final scale = _scale?.evaluate(a) ?? 1;
    final tilt = widget.reduceMotion ? 0.0 : (_tilt?.evaluate(a) ?? 0);
    final opacity = (_opacity?.evaluate(a) ?? 1).clamp(0.0, 1.0);
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(tilt * math.pi / 180)
      ..scaleByDouble(scale, scale, 1, 1);
    return Positioned(
      top: y,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: opacity < 0.05,
        child: ExcludeSemantics(
          excluding: widget.placement.opacity == 0,
          child: Opacity(
            opacity: opacity,
            child: Transform(
              alignment: Alignment.topCenter,
              transform: m,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
