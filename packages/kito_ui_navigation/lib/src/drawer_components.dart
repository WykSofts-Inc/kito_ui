// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'tab_item.dart';

// Building blocks for side menus. Text uses the surrounding text colour (a KitoSideMenu sets
// it from its `foreground`), with a quieter shade for secondary lines, so they read on light
// and dark drawers alike; `tint` colours selection and accents.

Color _secondary(BuildContext context) =>
    kitoNavForeground(context).withValues(alpha: 0.6);

/// A round avatar: an image, or initials on a gradient, with an optional gradient ring.
class KitoDrawerAvatar extends StatelessWidget {
  /// Creates an avatar.
  const KitoDrawerAvatar({
    super.key,
    required this.initials,
    this.image,
    this.colors = const [
      Color(0xFFFF8A3D),
      Color(0xFFFF3D77),
      Color(0xFF8E4EC6)
    ],
    this.size = 56,
    this.showsRing = false,
  });

  /// Shown when there's no [image].
  final String initials;

  /// A photo.
  final ImageProvider? image;

  /// The initials' gradient and the ring's colours.
  final List<Color> colors;

  /// The diameter.
  final double size;

  /// Draws a gradient ring around it.
  final bool showsRing;

  @override
  Widget build(BuildContext context) {
    final face = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: image != null
            ? Image(image: image!, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradient,
                    begin: AlignmentDirectional.topStart
                        .resolve(Directionality.of(context)),
                    end: AlignmentDirectional.bottomEnd
                        .resolve(Directionality.of(context)),
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                        fontSize: size * 0.36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
      ),
    );
    if (!showsRing) return ExcludeSemantics(child: face);
    final ring = math.max(size * 0.045, 2.0);
    return ExcludeSemantics(
      child: CustomPaint(
        foregroundPainter: _RingPainter(colors: _gradient, width: ring),
        child:
            Padding(padding: EdgeInsets.all(size * 0.06 + ring), child: face),
      ),
    );
  }

  List<Color> get _gradient {
    if (colors.length >= 2) return colors;
    final c = colors.isEmpty ? const Color(0xFF8E8E93) : colors.first;
    return [c, c];
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.colors, required this.width});

  final List<Color> colors;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawCircle(
      rect.center,
      size.shortestSide / 2 - width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader =
            SweepGradient(colors: [...colors, colors.first]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.width != width || oldDelegate.colors != colors;
}

/// How a [KitoDrawerHeader] is arranged.
enum KitoDrawerHeaderLayout {
  /// Avatar above the name.
  stacked,

  /// Avatar beside the name.
  inline,
}

/// The person at the top of a drawer: avatar, name and a detail line (an email, a plan).
class KitoDrawerHeader extends StatelessWidget {
  /// Creates a header.
  const KitoDrawerHeader({
    super.key,
    required this.name,
    required this.avatar,
    this.detail,
    this.layout = KitoDrawerHeaderLayout.stacked,
  });

  /// The name.
  final String name;

  /// The avatar.
  final Widget avatar;

  /// A line under the name.
  final String? detail;

  /// Stacked or inline.
  final KitoDrawerHeaderLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name,
            style: theme.typography.title
                .copyWith(fontSize: 20, color: kitoNavForeground(context))),
        if (detail != null) ...[
          const SizedBox(height: 3),
          Text(detail!,
              style: theme.typography.label.copyWith(
                  fontWeight: FontWeight.w400, color: _secondary(context))),
        ],
      ],
    );
    return MergeSemantics(
      child: switch (layout) {
        KitoDrawerHeaderLayout.stacked => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [avatar, const SizedBox(height: 12), text],
          ),
        KitoDrawerHeaderLayout.inline => Row(children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(child: text),
          ]),
      },
    );
  }
}

/// One destination in a drawer: an icon, a title, an optional badge ("\$10", "New", "3"), an
/// optional chevron, and a filled selected state.
class KitoDrawerItem extends StatelessWidget {
  /// Creates a row.
  const KitoDrawerItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.badge,
    this.isSelected = false,
    this.tint,
    this.badgeTint,
    this.showsChevron = false,
  });

  /// The title.
  final String title;

  /// The icon.
  final IconData icon;

  /// Called on tap.
  final VoidCallback? onTap;

  /// A short badge at the end.
  final String? badge;

  /// Fills the row with the accent.
  final bool isSelected;

  /// The accent; the theme's primary when null.
  final Color? tint;

  /// The badge colour when the row isn't selected; [tint] when null.
  final Color? badgeTint;

  /// A chevron at the end (it mirrors in RTL).
  final bool showsChevron;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    final onAccent = theme.onAccent(tint);
    final foreground = isSelected ? onAccent : kitoNavForeground(context);
    final badgeColor = badgeTint ?? accent;
    final duration = KitoMotion.of(context, theme.motion.medium);
    return KitoNavTapTarget(
      onTap: onTap,
      selected: isSelected,
      semanticValue: badge,
      pressScale: 0.97,
      focusRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent : accent.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          SizedBox(width: 26, child: Icon(icon, size: 20, color: foreground)),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: theme.typography.body.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: ShapeDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : badgeColor.withValues(alpha: 0.15),
                shape: const StadiumBorder(),
              ),
              child: ExcludeSemantics(
                  child: Text(badge!,
                      style: theme.typography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? onAccent : badgeColor))),
            ),
          ],
          if (showsChevron) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: isSelected
                    ? onAccent.withValues(alpha: 0.7)
                    : _secondary(context)),
          ],
        ]),
      ),
    );
  }
}

/// The classic icon + title (+ count badge) side-menu row, with a soft selected background.
class KitoSideMenuRow extends StatelessWidget {
  /// Creates a row.
  const KitoSideMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.badgeCount = 0,
    this.isSelected = false,
    this.tint,
  });

  /// The icon.
  final IconData icon;

  /// The title.
  final String title;

  /// Called on tap.
  final VoidCallback? onTap;

  /// A red count badge; hidden at 0.
  final int badgeCount;

  /// Highlights the row.
  final bool isSelected;

  /// The accent; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    final foreground = kitoNavForeground(context);
    return KitoNavTapTarget(
      onTap: onTap,
      selected: isSelected,
      semanticValue: badgeCount > 0 ? '$badgeCount new' : null,
      pressEffect: false,
      focusRadius: BorderRadius.circular(theme.radii.md),
      child: AnimatedContainer(
        duration: KitoMotion.of(context, theme.motion.fast),
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md, vertical: theme.spacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.1)
              : accent.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(theme.radii.md),
        ),
        child: Row(children: [
          SizedBox(
            width: 24,
            child: Icon(icon,
                size: 20,
                color: isSelected ? accent : foreground.withValues(alpha: 0.7)),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Text(title,
                style: (isSelected
                        ? theme.typography.bodyEmphasized
                        : theme.typography.body)
                    .copyWith(color: isSelected ? accent : foreground)),
          ),
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: ShapeDecoration(
                  color: theme.colors.danger, shape: const StadiumBorder()),
              child: ExcludeSemantics(
                  child: Text(KitoTabItem.badgeText(badgeCount),
                      style: theme.typography.caption
                          .copyWith(color: Colors.white))),
            ),
        ]),
      ),
    );
  }
}

/// A switch in a drawer, e.g. dark mode or notifications.
class KitoDrawerToggle extends StatelessWidget {
  /// Creates a toggle row.
  const KitoDrawerToggle({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.tint,
  });

  /// The title.
  final String title;

  /// The icon.
  final IconData icon;

  /// On or off.
  final bool value;

  /// Called with the new value; null disables it.
  final ValueChanged<bool>? onChanged;

  /// The switch's on colour; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    final foreground = kitoNavForeground(context);
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            SizedBox(width: 26, child: Icon(icon, size: 20, color: foreground)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: theme.typography.body.copyWith(color: foreground)),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: accent,
              thumbColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? theme.onAccent(tint)
                      : null),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A titled group of drawer rows.
class KitoDrawerSection extends StatelessWidget {
  /// Creates a section.
  const KitoDrawerSection({super.key, this.title, required this.children});

  /// An uppercase heading.
  final String? title;

  /// The rows.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, bottom: 6),
            child: Semantics(
              header: true,
              child: Text(title!.toUpperCase(),
                  style: theme.typography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: _secondary(context))),
            ),
          ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          children[i],
        ],
      ],
    );
  }
}

/// A square shortcut for a grid at the top of a drawer.
class KitoDrawerTile extends StatelessWidget {
  /// Creates a tile.
  const KitoDrawerTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.detail,
    this.tint = const Color(0xFF3E63DD),
  });

  /// The title.
  final String title;

  /// The icon.
  final IconData icon;

  /// Called on tap.
  final VoidCallback? onTap;

  /// A line under the title.
  final String? detail;

  /// The icon's colour.
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final foreground = kitoNavForeground(context);
    return KitoNavTapTarget(
      onTap: onTap,
      pressScale: 0.97,
      focusRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: tint),
            ),
            const SizedBox(height: 10),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.label
                    .copyWith(fontWeight: FontWeight.w600, color: foreground)),
            if (detail != null)
              Text(detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption
                      .copyWith(color: _secondary(context))),
          ],
        ),
      ),
    );
  }
}

/// Lays tiles out in equal columns.
class KitoDrawerTileGrid extends StatelessWidget {
  /// Creates a grid.
  const KitoDrawerTileGrid(
      {super.key, required this.children, this.columns = 2, this.spacing = 10});

  /// The tiles.
  final List<Widget> children;

  /// How many columns; at least 1.
  final int columns;

  /// Space between tiles.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final n = math.max(columns, 1);
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += n) {
      if (start > 0) rows.add(SizedBox(height: spacing));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = start; i < start + n; i++) ...[
            if (i > start) SizedBox(width: spacing),
            Expanded(
                child: i < children.length ? children[i] : const SizedBox()),
          ],
        ]),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// A card that asks for something: verify your email, finish your profile, upgrade.
class KitoDrawerCallout extends StatelessWidget {
  /// Creates a callout.
  const KitoDrawerCallout({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionTitle,
    this.onAction,
    this.onDismiss,
    this.tint = const Color(0xFFF5A524),
    this.dismissLabel = 'Dismiss',
  });

  /// The icon on the coloured disc.
  final IconData icon;

  /// The title.
  final String title;

  /// The message.
  final String message;

  /// A text button under the message.
  final String? actionTitle;

  /// Called by the text button.
  final VoidCallback? onAction;

  /// Shows a close button that calls this.
  final VoidCallback? onDismiss;

  /// The card's colour.
  final Color tint;

  /// The close button's screen-reader label.
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final foreground = kitoNavForeground(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: kitoNavReadableOn(tint)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: theme.typography.label.copyWith(
                      fontWeight: FontWeight.w700, color: foreground)),
              const SizedBox(height: 4),
              Text(message,
                  style: theme.typography.caption
                      .copyWith(color: _secondary(context))),
              if (actionTitle != null)
                KitoNavTapTarget(
                  onTap: onAction,
                  pressEffect: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(actionTitle!,
                        style: theme.typography.caption.copyWith(
                            fontWeight: FontWeight.w700, color: tint)),
                  ),
                ),
            ],
          ),
        ),
        if (onDismiss != null)
          KitoNavTapTarget(
            onTap: onDismiss,
            semanticLabel: dismissLabel,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close_rounded,
                  size: 16, color: _secondary(context)),
            ),
          ),
      ]),
    );
  }
}

/// The button at the foot of a drawer, e.g. Sign out.
class KitoDrawerFooterButton extends StatelessWidget {
  /// Creates the button.
  const KitoDrawerFooterButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon = Icons.logout_rounded,
    this.isDestructive = false,
  });

  /// The title.
  final String title;

  /// Called on tap.
  final VoidCallback? onTap;

  /// The icon; the default mirrors in RTL.
  final IconData icon;

  /// Draws it in the danger colour.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final color =
        isDestructive ? theme.colors.danger : kitoNavForeground(context);
    return KitoNavTapTarget(
      onTap: onTap,
      pressScale: 0.97,
      focusRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: color.withValues(alpha: isDestructive ? 0.12 : 0.08),
          shape: const StadiumBorder(),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(title,
                style: theme.typography.label
                    .copyWith(fontWeight: FontWeight.w600, color: color)),
          ),
        ]),
      ),
    );
  }
}

/// A slim column of icons, for a compact sidebar or a tablet-style rail. The selected
/// highlight glides between items.
class KitoSideRail extends StatelessWidget {
  /// Creates a rail.
  const KitoSideRail({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.tint,
    this.header,
    this.footer,
    this.width = 76,
  });

  /// The destinations.
  final List<KitoTabItem> items;

  /// The selected item's id.
  final String selectedId;

  /// Called with a tapped item's id.
  final ValueChanged<String> onSelected;

  /// The highlight colour; the theme's primary when null.
  final Color? tint;

  /// Above the items (a logo, an avatar).
  final Widget? header;

  /// At the bottom (settings, sign out).
  final Widget? footer;

  /// The rail's width.
  final double width;

  static const double _item = 50;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = theme.accent(tint);
    final onAccent = theme.onAccent(tint);
    final muted = kitoNavForeground(context).withValues(alpha: 0.6);
    final index = items.indexWhere((i) => i.id == selectedId);
    final duration = KitoMotion.of(context, const Duration(milliseconds: 380));
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(children: [
          if (header != null) ...[header!, const SizedBox(height: 20)],
          SizedBox(
            height: items.isEmpty ? 0 : items.length * (_item + _gap) - _gap,
            width: _item,
            child: Stack(children: [
              if (index >= 0)
                AnimatedPositioned(
                  duration: duration,
                  curve: context.reduceMotion
                      ? Curves.easeInOut
                      : const KitoSpringCurve(damping: 0.78),
                  top: index * (_item + _gap),
                  left: 0,
                  width: _item,
                  height: _item,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: accent, borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              for (var i = 0; i < items.length; i++)
                Positioned(
                  top: i * (_item + _gap),
                  left: 0,
                  width: _item,
                  height: _item,
                  child: KitoNavTapTarget(
                    onTap: () => onSelected(items[i].id),
                    selected: i == index,
                    inGroup: true,
                    semanticLabel: items[i].title,
                    semanticValue: items[i].badgeCount > 0
                        ? '${items[i].badgeCount} new'
                        : null,
                    pressScale: 0.92,
                    child: Stack(children: [
                      Center(
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(end: i == index ? onAccent : muted),
                          duration: duration,
                          builder: (context, c, _) => Icon(
                              i == index
                                  ? (items[i].selectedIcon ?? items[i].icon)
                                  : items[i].icon,
                              size: 22,
                              color: c),
                        ),
                      ),
                      if (items[i].badgeCount > 0)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                                color: theme.colors.danger,
                                shape: BoxShape.circle),
                          ),
                        ),
                    ]),
                  ),
                ),
            ]),
          ),
          const Spacer(),
          if (footer != null) footer!,
        ]),
      ),
    );
  }
}
