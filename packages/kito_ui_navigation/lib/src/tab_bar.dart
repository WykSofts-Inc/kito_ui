// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'tab_bar_shape.dart';
import 'tab_item.dart';

/// How a [KitoTabBar] looks and moves.
enum KitoTabBarStyle {
  /// Edge to edge on the surface, a soft capsule sliding behind the selected icon.
  classic,

  /// A capsule floating above the content, with a dot under the selected icon.
  floating,

  /// The selected tab grows into a filled pill that shows its title.
  pill,

  /// A short line slides along the top edge to the selected tab.
  underline,

  /// The selected icon rises into a circle that sits in a curved dip gliding with it.
  bubble,

  /// A floating capsule of frosted glass with a sliding highlight.
  glass,

  /// A filled tile slides behind the selected icon and title.
  segmented,

  /// Icons only: the icon bounces and a dot stretches under it.
  minimal,

  /// A raised centre action button in a notch; pass a [KitoTabCenterAction].
  notched;

  /// Styles that float over the content rather than sitting flush with the bottom edge.
  bool get floats =>
      this == floating || this == pill || this == glass || this == segmented;
}

/// The raised button in the middle of a [KitoTabBarStyle.notched] tab bar.
@immutable
class KitoTabCenterAction {
  /// Creates the action.
  const KitoTabCenterAction({
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.semanticLabel = 'Create',
  });

  /// Called on tap.
  final VoidCallback onPressed;

  /// The button's icon.
  final IconData icon;

  /// What screen readers call it.
  final String semanticLabel;
}

/// A themed, custom bottom tab bar in nine styles — see [KitoTabBarStyle]. Its selection
/// indicator, icon colours and badges follow `KitoTheme`, and everything mirrors in
/// right-to-left layouts.
///
/// Use it on its own (as a `Scaffold.bottomNavigationBar`), or let [KitoTabScaffold] wire it
/// to the tabs' screens.
class KitoTabBar extends StatelessWidget {
  /// Creates a tab bar.
  const KitoTabBar({
    super.key,
    required this.controller,
    this.style = KitoTabBarStyle.classic,
    this.tint,
    this.centerAction,
  });

  /// Which tab is selected, and the tabs.
  final KitoTabBarController controller;

  /// The look.
  final KitoTabBarStyle style;

  /// Overrides the theme's primary colour for the selection.
  final Color? tint;

  /// The centre button of the notched style; without one, notched falls back to floating.
  final KitoTabCenterAction? centerAction;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bar = _Bar(
          items: controller.items,
          selected: controller.selectedIndex,
          onSelect: (i) => controller.select(controller.items[i].id),
          tint: tint,
        );
        return Semantics(
          container: true,
          explicitChildNodes: true,
          child: switch (style) {
            KitoTabBarStyle.classic => bar.classic(context),
            KitoTabBarStyle.floating => bar.floating(context),
            KitoTabBarStyle.pill => bar.pill(context),
            KitoTabBarStyle.underline => bar.underline(context),
            KitoTabBarStyle.bubble => bar.bubble(context),
            KitoTabBarStyle.glass => bar.glass(context),
            KitoTabBarStyle.segmented => bar.segmented(context),
            KitoTabBarStyle.minimal => bar.minimal(context),
            KitoTabBarStyle.notched => centerAction == null
                ? bar.floating(context)
                : bar.notched(context, centerAction!),
          },
        );
      },
    );
  }
}

/// Builds each style from the same parts.
class _Bar {
  const _Bar(
      {required this.items,
      required this.selected,
      required this.onSelect,
      required this.tint});

  final List<KitoTabItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final Color? tint;

  int get count => items.length;

  Duration _duration(BuildContext context) =>
      KitoMotion.of(context, const Duration(milliseconds: 420));

  Curve _curve(BuildContext context) => context.reduceMotion
      ? Curves.easeInOut
      : const KitoSpringCurve(damping: 0.76);

  Color _accent(BuildContext c) => c.kito.accent(tint);
  Color _onAccent(BuildContext c) => c.kito.onAccent(tint);
  Color _muted(BuildContext c) =>
      c.kito.colors.onBackground.withValues(alpha: 0.5);

  double _bottomInset(BuildContext c) => MediaQuery.paddingOf(c).bottom;

  /// An indicator the width of one tab, gliding to the selected one.
  Widget _slider(BuildContext context, Widget child,
      {double y = 0, int? of, int? at}) {
    final n = of ?? count;
    final i = at ?? selected;
    final x = n <= 1 ? 0.0 : -1 + 2 * i / (n - 1);
    return AnimatedAlign(
      alignment: AlignmentDirectional(x, y),
      duration: _duration(context),
      curve: _curve(context),
      child: FractionallySizedBox(widthFactor: 1 / n, child: child),
    );
  }

  Widget _tab(BuildContext context, int index, Widget child,
          {bool expand = true}) =>
      KitoTabButton(
        item: items[index],
        selected: index == selected,
        onTap: () => onSelect(index),
        expand: expand,
        child: child,
      );

  Widget _icon(BuildContext context, int index, Color color,
      {double size = 22}) {
    final item = items[index];
    final isSelected = index == selected;
    return KitoTabIcon(
      icon: isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
      color: color,
      size: size,
      badgeCount: item.badgeCount,
      duration: _duration(context),
    );
  }

  Widget _title(BuildContext context, int index, Color color,
      {double size = 11, bool boldWhenSelected = true}) {
    final theme = context.kito;
    final isSelected = index == selected;
    return AnimatedDefaultTextStyle(
      duration: KitoMotion.of(context, theme.motion.fast),
      style: theme.typography.caption.copyWith(
        fontSize: size,
        color: color,
        fontWeight:
            isSelected && boldWhenSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      child: Text(items[index].title,
          maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
    );
  }

  Color _colorFor(BuildContext c, int i, {Color? on}) =>
      i == selected ? (on ?? _accent(c)) : _muted(c);

  Widget _flushBar(BuildContext context, Widget row) {
    final theme = context.kito;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: Border(top: BorderSide(color: theme.colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: _bottomInset(context)),
        child: row,
      ),
    );
  }

  Widget _floatingShell(BuildContext context, Widget child,
      {double horizontal = 24, Decoration? decoration, double radius = 999}) {
    final theme = context.kito;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontal, 0, horizontal, _bottomInset(context) + 8),
      child: DecoratedBox(
        decoration: decoration ??
            BoxDecoration(
              color: theme.colors.surface,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 10)),
              ],
            ),
        child: child,
      ),
    );
  }

  // Styles

  Widget classic(BuildContext context) {
    final accent = _accent(context);
    return _flushBar(
      context,
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Stack(children: [
          Positioned.fill(
            child: _slider(
              context,
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 52,
                  height: 30,
                  decoration: ShapeDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: const StadiumBorder()),
                ),
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < count; i++)
              _tab(
                context,
                i,
                Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      height: 30,
                      child: Center(
                          child: _icon(context, i, _colorFor(context, i)))),
                  const SizedBox(height: 3),
                  _title(context, i, _colorFor(context, i)),
                ]),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget floating(BuildContext context) {
    final accent = _accent(context);
    return _floatingShell(
      context,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          for (var i = 0; i < count; i++)
            _tab(
              context,
              i,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _icon(context, i, _colorFor(context, i), size: 23),
                  const SizedBox(height: 6),
                  AnimatedScale(
                    scale: i == selected ? 1 : 0.2,
                    duration: _duration(context),
                    curve: _curve(context),
                    child: AnimatedOpacity(
                      opacity: i == selected ? 1 : 0,
                      duration: _duration(context),
                      child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: accent, shape: BoxShape.circle)),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget pill(BuildContext context) {
    final theme = context.kito;
    final accent = _accent(context);
    final onAccent = _onAccent(context);
    return _floatingShell(
      context,
      horizontal: 20,
      Padding(
        padding: const EdgeInsets.all(7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < count; i++)
              _tab(
                context,
                i,
                expand: false,
                AnimatedContainer(
                  duration: _duration(context),
                  curve: _curve(context),
                  constraints:
                      const BoxConstraints(minHeight: 48, minWidth: 48),
                  padding:
                      EdgeInsets.symmetric(horizontal: i == selected ? 18 : 12),
                  decoration: ShapeDecoration(
                    color: i == selected ? accent : accent.withValues(alpha: 0),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _icon(
                        context, i, i == selected ? onAccent : _muted(context)),
                    AnimatedSize(
                      duration: _duration(context),
                      curve: _curve(context),
                      alignment: AlignmentDirectional.centerStart,
                      child: i == selected
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 8),
                              child: Text(items[i].title,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: theme.typography.label.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: onAccent)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget underline(BuildContext context) {
    final accent = _accent(context);
    return _flushBar(
      context,
      Stack(children: [
        Row(children: [
          for (var i = 0; i < count; i++)
            _tab(
              context,
              i,
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _icon(context, i, _colorFor(context, i)),
                  const SizedBox(height: 4),
                  _title(context, i, _colorFor(context, i)),
                ]),
              ),
            ),
        ]),
        Positioned.fill(
          child: IgnorePointer(
            child: _slider(
              context,
              y: -1,
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 30,
                  height: 3,
                  decoration: ShapeDecoration(
                      color: accent, shape: const StadiumBorder()),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget bubble(BuildContext context) {
    final theme = context.kito;
    final accent = _accent(context);
    final onAccent = _onAccent(context);
    const inset = 10.0;
    const height = 60.0;
    final target = count == 0 ? 0.5 : (selected + 0.5) / count;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: _duration(context),
      curve: _curve(context),
      builder: (context, center, _) {
        final direction = Directionality.of(context);
        return Padding(
          padding: EdgeInsets.zero,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: theme.colors.surface,
                  shape: KitoTabBarShape(
                      notchCenter: center,
                      horizontalInset: inset,
                      notchRadius: 36,
                      notchDepth: 34),
                  shadows: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -2)),
                  ],
                ),
              ),
            ),
            // The circle glides with the dip.
            Positioned.fill(
              child: LayoutBuilder(builder: (context, box) {
                final x =
                    KitoTabBarShape(notchCenter: center, horizontalInset: inset)
                        .notchX(Offset.zero & box.biggest, direction);
                return Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    left: x - 26,
                    top: 6 - 26,
                    child: IgnorePointer(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 6)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]);
              }),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: inset, right: inset, bottom: _bottomInset(context)),
              child: SizedBox(
                height: height,
                child: Row(children: [
                  for (var i = 0; i < count; i++)
                    _tab(
                      context,
                      i,
                      AnimatedSlide(
                        offset: Offset(0, i == selected ? -26 / 24 : 0),
                        duration: _duration(context),
                        curve: _curve(context),
                        child: _icon(context, i,
                            i == selected ? onAccent : _muted(context),
                            size: 22),
                      ),
                    ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget glass(BuildContext context) {
    final theme = context.kito;
    final accent = _accent(context);
    final foreground = theme.colors.onBackground.withValues(alpha: 0.7);
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, _bottomInset(context) + 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(children: [
                  Positioned.fill(
                    child: _slider(
                      context,
                      DecoratedBox(
                        decoration: ShapeDecoration(
                            color: accent.withValues(alpha: 0.16),
                            shape: const StadiumBorder()),
                      ),
                    ),
                  ),
                  Row(children: [
                    for (var i = 0; i < count; i++)
                      _tab(
                        context,
                        i,
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            _icon(
                                context, i, i == selected ? accent : foreground,
                                size: 20),
                            const SizedBox(height: 3),
                            _title(
                                context, i, i == selected ? accent : foreground,
                                size: 10),
                          ]),
                        ),
                      ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget segmented(BuildContext context) {
    final accent = _accent(context);
    final onAccent = _onAccent(context);
    return _floatingShell(
      context,
      horizontal: 16,
      radius: 24,
      Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(children: [
          Positioned.fill(
            child: _slider(
              context,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < count; i++)
              _tab(
                context,
                i,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _icon(context, i, _colorFor(context, i, on: onAccent),
                        size: 20),
                    const SizedBox(height: 4),
                    _title(context, i, _colorFor(context, i, on: onAccent),
                        size: 10, boldWhenSelected: false),
                  ]),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget minimal(BuildContext context) {
    final theme = context.kito;
    final accent = _accent(context);
    return ColoredBox(
      color: theme.colors.background,
      child: Padding(
        padding: EdgeInsets.only(bottom: _bottomInset(context)),
        child: Row(children: [
          for (var i = 0; i < count; i++)
            _tab(
              context,
              i,
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  KitoTabBounce(
                    active: i == selected,
                    child: _icon(context, i, _colorFor(context, i), size: 24),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: _duration(context),
                    curve: _curve(context),
                    width: i == selected ? 16 : 4,
                    height: 4,
                    decoration: ShapeDecoration(
                      color:
                          i == selected ? accent : accent.withValues(alpha: 0),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget notched(BuildContext context, KitoTabCenterAction center) {
    final theme = context.kito;
    final accent = _accent(context);
    final onAccent = _onAccent(context);
    final half = count ~/ 2;
    Widget tab(int i) => _tab(
          context,
          i,
          Column(mainAxisSize: MainAxisSize.min, children: [
            _icon(context, i, _colorFor(context, i)),
            const SizedBox(height: 4),
            _title(context, i, _colorFor(context, i)),
          ]),
        );
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: theme.colors.surface,
            shape: const KitoTabBarShape(
                notchCenter: 0.5, notchRadius: 42, notchDepth: 38),
            shadows: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -2)),
            ],
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(6, 10, 6, _bottomInset(context) + 6),
        child: Row(children: [
          for (var i = 0; i < half; i++) tab(i),
          const SizedBox(width: 84),
          for (var i = half; i < count; i++) tab(i),
        ]),
      ),
      Positioned(
        top: -30,
        left: 0,
        right: 0,
        child: Center(
          child: KitoNavTapTarget(
            onTap: center.onPressed,
            semanticLabel: center.semanticLabel,
            pressScale: 0.9,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Icon(center.icon, color: onAccent, size: 28),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// One tab: focusable, tappable, with tab semantics (selected state, badge as value).
///
/// Internal to the kit; not exported.
class KitoTabButton extends StatelessWidget {
  /// Creates a tab button.
  const KitoTabButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.child,
    this.expand = true,
  });

  /// The tab.
  final KitoTabItem item;

  /// Whether it's the selected tab.
  final bool selected;

  /// Called on tap.
  final VoidCallback onTap;

  /// What's drawn.
  final Widget child;

  /// Takes an equal share of the row.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = KitoNavTapTarget(
      onTap: onTap,
      semanticLabel: item.title,
      semanticValue: item.badgeCount > 0 ? '${item.badgeCount} new' : null,
      selected: selected,
      inGroup: true,
      pressScale: 0.92,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
    return expand ? Expanded(child: button) : button;
  }
}

/// A tab icon that cross-fades to its selected variant, with a badge at its top end.
///
/// Internal to the kit; not exported.
class KitoTabIcon extends StatelessWidget {
  /// Creates the icon.
  const KitoTabIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.badgeCount,
    required this.duration,
    this.size = 22,
  });

  /// The icon.
  final IconData icon;

  /// Its colour.
  final Color color;

  /// The badge count; hidden at 0.
  final int badgeCount;

  /// How long changes take.
  final Duration duration;

  /// Its size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Stack(clipBehavior: Clip.none, children: [
      TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: duration,
        builder: (context, c, _) => AnimatedSwitcher(
          duration: duration,
          child: Icon(icon, key: ValueKey(icon), size: size, color: c),
        ),
      ),
      PositionedDirectional(
        top: -4,
        end: -10,
        child: AnimatedScale(
          scale: badgeCount > 0 ? 1 : 0,
          duration: duration,
          curve: const KitoSpringCurve(damping: 0.6),
          child: badgeCount > 0
              ? Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: theme.colors.danger,
                    shape: StadiumBorder(
                        side: BorderSide(
                            color: theme.colors.surface, width: 1.5)),
                  ),
                  child: Text(
                    KitoTabItem.badgeText(badgeCount),
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2),
                  ),
                )
              : const SizedBox(width: 16, height: 16),
        ),
      ),
    ]);
  }
}

/// Bounces [child] each time [active] turns on (not with reduce motion).
///
/// Internal to the kit; not exported.
class KitoTabBounce extends StatefulWidget {
  /// Creates the bounce.
  const KitoTabBounce({super.key, required this.active, required this.child});

  /// Bounces when this turns true.
  final bool active;

  /// What bounces.
  final Widget child;

  @override
  State<KitoTabBounce> createState() => _KitoTabBounceState();
}

class _KitoTabBounceState extends State<KitoTabBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didUpdateWidget(KitoTabBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active && !context.reduceMotion) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          // Up to 1.2 quickly, then a damped settle back to 1.
          final scale = t == 0
              ? 1.0
              : t < 0.3
                  ? 1 + 0.2 * (t / 0.3)
                  : 1 +
                      0.2 *
                          (1 -
                              const KitoSpringCurve(damping: 0.5)
                                  .transform((t - 0.3) / 0.7));
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      );
}

/// A tab bar at the bottom and each tab's screen above it. Screens are built the first time
/// their tab is selected and then kept alive (with their own navigation state) while hidden.
/// With floating styles the content runs under the bar; `MediaQuery.padding.bottom` includes
/// the bar, so a `SafeArea` or a list's padding clears it.
///
/// ```dart
/// KitoTabScaffold(
///   controller: tabs,
///   style: KitoTabBarStyle.pill,
///   builder: (context, id) => switch (id) {
///     'home' => const HomeScreen(),
///     'cart' => const CartScreen(),
///     _ => const ProfileScreen(),
///   },
/// )
/// ```
class KitoTabScaffold extends StatefulWidget {
  /// Creates the scaffold.
  const KitoTabScaffold({
    super.key,
    required this.controller,
    required this.builder,
    this.style = KitoTabBarStyle.classic,
    this.tint,
    this.centerAction,
    this.backgroundColor,
  });

  /// Which tab is selected, and the tabs.
  final KitoTabBarController controller;

  /// Builds the screen for a tab id.
  final Widget Function(BuildContext context, String id) builder;

  /// The tab bar's look.
  final KitoTabBarStyle style;

  /// Overrides the theme's primary colour for the selection.
  final Color? tint;

  /// The notched style's centre button.
  final KitoTabCenterAction? centerAction;

  /// Behind the screens; the theme's background when null.
  final Color? backgroundColor;

  @override
  State<KitoTabScaffold> createState() => _KitoTabScaffoldState();
}

class _KitoTabScaffoldState extends State<KitoTabScaffold> {
  final Set<String> _visited = {};

  @override
  Widget build(BuildContext context) {
    final extend = widget.style.floats ||
        widget.style == KitoTabBarStyle.bubble ||
        widget.style == KitoTabBarStyle.notched;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = widget.controller.items;
        final selected = widget.controller.selectedId;
        _visited
          ..retainWhere((id) => items.any((i) => i.id == id))
          ..add(selected);
        return Scaffold(
          backgroundColor:
              widget.backgroundColor ?? context.kito.colors.background,
          extendBody: extend,
          body: Stack(fit: StackFit.expand, children: [
            for (final item in items)
              if (_visited.contains(item.id))
                KeyedSubtree(
                  key: ValueKey(item.id),
                  child: Offstage(
                    offstage: item.id != selected,
                    child: TickerMode(
                      enabled: item.id == selected,
                      child: ExcludeFocus(
                        excluding: item.id != selected,
                        child: Builder(
                            builder: (context) =>
                                widget.builder(context, item.id)),
                      ),
                    ),
                  ),
                ),
          ]),
          bottomNavigationBar: KitoTabBar(
            controller: widget.controller,
            style: widget.style,
            tint: widget.tint,
            centerAction: widget.centerAction,
          ),
        );
      },
    );
  }
}
