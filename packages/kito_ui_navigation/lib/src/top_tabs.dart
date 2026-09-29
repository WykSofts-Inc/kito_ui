// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';

/// The look of [KitoTopTabs].
enum KitoTopTabsStyle {
  /// Text with a line sliding under the selected tab.
  underline,

  /// A filled capsule sliding behind the selected tab, on a soft track.
  pill,

  /// Separate chips; the selected one fills.
  chips,
}

/// Scrollable tabs for the top of a screen. The indicator glides between tabs of any width,
/// and the selected tab is scrolled into view.
///
/// ```dart
/// KitoTopTabs(
///   tabs: const ['For you', 'Following', 'Nearby'],
///   selectedIndex: feed,
///   onChanged: (i) => setState(() => feed = i),
///   style: KitoTopTabsStyle.pill,
/// )
/// ```
class KitoTopTabs extends StatefulWidget {
  /// Creates top tabs.
  const KitoTopTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.style = KitoTopTabsStyle.underline,
    this.tint,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// The tab titles.
  final List<String> tabs;

  /// Which tab is selected.
  final int selectedIndex;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onChanged;

  /// Underline, pill or chips.
  final KitoTopTabsStyle style;

  /// Overrides the theme's primary colour.
  final Color? tint;

  /// Space around the row, inside the scroll view.
  final EdgeInsets padding;

  @override
  State<KitoTopTabs> createState() => _KitoTopTabsState();
}

class _KitoTopTabsState extends State<KitoTopTabs> {
  final _stackKey = GlobalKey();
  List<GlobalKey> _keys = [];
  List<Rect> _rects = const [];

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(KitoTopTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      if (oldWidget.selectedIndex != widget.selectedIndex) _reveal();
    });
  }

  void _syncKeys() {
    _keys = [for (var i = 0; i < widget.tabs.length; i++) GlobalKey()];
  }

  void _measure() {
    if (!mounted) return;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || !stack.hasSize) return;
    final rects = <Rect>[];
    for (final key in _keys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      rects.add(box.localToGlobal(Offset.zero, ancestor: stack) & box.size);
    }
    if (!_sameRects(rects, _rects)) setState(() => _rects = rects);
  }

  static bool _sameRects(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i].left - b[i].left).abs() > 0.5 ||
          (a[i].width - b[i].width).abs() > 0.5) {
        return false;
      }
    }
    return true;
  }

  void _reveal() {
    final i = widget.selectedIndex;
    if (i < 0 || i >= _keys.length) return;
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.5,
        duration: KitoMotion.of(context, const Duration(milliseconds: 320)),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(widget.tint);
    final onAccent = theme.onAccent(widget.tint);
    final style = widget.style;
    final selected = widget.selectedIndex;
    final duration = KitoMotion.of(context, const Duration(milliseconds: 380));
    final curve = context.reduceMotion
        ? Curves.easeInOut
        : const KitoSpringCurve(damping: 0.8);
    final hasRect = selected >= 0 && selected < _rects.length;
    final secondary = theme.colors.onBackground.withValues(alpha: 0.6);

    Widget tab(int i) {
      final isSelected = i == selected;
      final color = switch (style) {
        KitoTopTabsStyle.underline => isSelected ? accent : secondary,
        _ => isSelected ? onAccent : theme.colors.onBackground,
      };
      Widget label = AnimatedDefaultTextStyle(
        duration: KitoMotion.of(context, theme.motion.fast),
        style: theme.typography.label.copyWith(
          color: color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        child: Text(widget.tabs[i], maxLines: 1, softWrap: false),
      );
      label = AnimatedContainer(
        key: _keys[i],
        duration: duration,
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: style == KitoTopTabsStyle.underline ? 12 : 8),
        decoration: style == KitoTopTabsStyle.chips
            ? ShapeDecoration(
                color: isSelected
                    ? accent
                    : theme.colors.onBackground.withValues(alpha: 0.06),
                shape: const StadiumBorder())
            : null,
        child: label,
      );
      return KitoNavTapTarget(
        onTap: () => widget.onChanged(i),
        selected: isSelected,
        inGroup: true,
        semanticLabel: widget.tabs[i],
        pressEffect: style == KitoTopTabsStyle.chips,
        child: label,
      );
    }

    final row = Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < widget.tabs.length; i++) ...[
        if (i > 0) SizedBox(width: style == KitoTopTabsStyle.chips ? 8 : 2),
        tab(i),
      ],
    ]);

    Widget indicator = const SizedBox.shrink();
    if (hasRect && style != KitoTopTabsStyle.chips) {
      final r = _rects[selected];
      indicator = AnimatedPositioned(
        duration: duration,
        curve: curve,
        left: r.left,
        width: r.width,
        top: style == KitoTopTabsStyle.underline ? r.bottom - 3 : r.top,
        height: style == KitoTopTabsStyle.underline ? 3 : r.height,
        child: DecoratedBox(
          decoration:
              ShapeDecoration(color: accent, shape: const StadiumBorder()),
        ),
      );
    }

    Widget content = Stack(key: _stackKey, children: [
      if (style == KitoTopTabsStyle.pill)
        Positioned.fill(
          child: DecoratedBox(
            decoration: ShapeDecoration(
                color: theme.colors.onBackground.withValues(alpha: 0.06),
                shape: const StadiumBorder()),
          ),
        ),
      indicator,
      NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
          return true;
        },
        child: SizeChangedLayoutNotifier(child: row),
      ),
    ]);
    if (style == KitoTopTabsStyle.pill) {
      content = Padding(padding: const EdgeInsets.all(4), child: content);
    }

    Widget scroller = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: widget.padding.copyWith(
          top: widget.padding.top + (style == KitoTopTabsStyle.pill ? 4 : 0),
          bottom:
              widget.padding.bottom + (style == KitoTopTabsStyle.pill ? 4 : 0)),
      child: content,
    );
    if (style == KitoTopTabsStyle.underline) {
      scroller = DecoratedBox(
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colors.border))),
        child: scroller,
      );
    }
    return Semantics(
        container: true, explicitChildNodes: true, child: scroller);
  }
}
