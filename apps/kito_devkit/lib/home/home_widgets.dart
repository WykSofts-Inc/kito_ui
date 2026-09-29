// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';

/// Greeting, the app name with a glow, and live stats.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.kitCount,
    required this.sampleCount,
    required this.onSurprise,
    required this.onSettings,
  });

  final int kitCount;
  final int sampleCount;
  final VoidCallback onSurprise;
  final VoidCallback onSettings;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final muted = theme.colors.onBackground.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  Color(0xFFFF9100),
                  Color(0xFFFF4081),
                  Color(0xFF7C4DFF)
                ]),
              ),
              child: const Text('WN',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting,
                      style: theme.typography.label.copyWith(color: muted)),
                  Text('Wycliff N',
                      style: theme.typography.headline
                          .copyWith(color: theme.colors.onBackground)),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Settings',
              child: KitoPressable(
                child: GestureDetector(
                  onTap: onSettings,
                  child: KitoSurface(
                    radius: 22,
                    border: true,
                    child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.settings_rounded,
                            color: theme.colors.primary)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        KitoGlow(
          radius: 26,
          intensity: 0.25,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [theme.colors.onBackground, theme.colors.primary],
            ).createShader(bounds),
            child: Text('Kito UI',
                style: theme.typography.display
                    .copyWith(fontSize: 40, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),
        Text('Every Flutter kit in the ecosystem, live and interactive.',
            style: theme.typography.body.copyWith(color: muted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatPill(
                value: '$kitCount', label: 'kits', icon: Icons.layers_rounded),
            _StatPill(
                value: '$sampleCount',
                label: 'samples',
                icon: Icons.auto_awesome_rounded),
            Semantics(
              button: true,
              hint: 'Opens a random kit',
              child: KitoPressable(
                child: GestureDetector(
                  onTap: onSurprise,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: theme.colors.primary,
                        borderRadius: BorderRadius.circular(theme.radii.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.casino_rounded,
                            size: 16, color: theme.colors.onPrimary),
                        const SizedBox(width: 6),
                        Text('Surprise me',
                            style: theme.typography.caption.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colors.onPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return KitoSurface(
      radius: theme.radii.pill,
      border: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colors.primary),
          const SizedBox(width: 5),
          Text(value,
              style: theme.typography.caption.copyWith(
                  fontWeight: FontWeight.w800, color: theme.colors.onSurface)),
          const SizedBox(width: 3),
          Text(label,
              style: theme.typography.caption.copyWith(
                  color: theme.colors.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// A section title with an icon and an optional trailing note.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader(
      {super.key, required this.title, required this.icon, this.trailing});

  final String title;
  final IconData icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: theme.typography.title
                  .copyWith(fontSize: 20, color: theme.colors.onBackground)),
          const SizedBox(width: 8),
          const Spacer(),
          if (trailing != null)
            Text(trailing!,
                style: theme.typography.caption.copyWith(
                    color: theme.colors.onBackground.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

/// A big art card for the Featured carousel.
class HomeFeatureCard extends StatelessWidget {
  const HomeFeatureCard({super.key, required this.kit, required this.colors});

  final KitEntry kit;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Semantics(
      button: true,
      label: '${kit.title}, ${kit.sampleCount} samples',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
              colors: colors,
              begin: AlignmentDirectional.topStart
                  .resolve(Directionality.of(context)),
              end: AlignmentDirectional.bottomEnd
                  .resolve(Directionality.of(context))),
          boxShadow: [
            BoxShadow(
                color: colors.first.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 12))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PositionedDirectional(
              top: 24,
              end: 20,
              child: Transform.rotate(
                angle: -0.18,
                child: Icon(kit.icon,
                    size: 104, color: Colors.white.withValues(alpha: 0.26)),
              ),
            ),
            PositionedDirectional(
              top: -60,
              end: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(kit.category.title.toUpperCase(),
                      style: theme.typography.caption.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(kit.title,
                      style: theme.typography.title
                          .copyWith(fontSize: 28, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(kit.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99)),
                          child: Text('${kit.sampleCount} samples',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.typography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explore',
                                style: theme.typography.label.copyWith(
                                    color: colors.first,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            Icon(
                                context.isRtl
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                                color: colors.first),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A kit in the grid: a tinted icon tile, its name and sample count.
class HomeKitTile extends StatelessWidget {
  const HomeKitTile({super.key, required this.kit});

  final KitEntry kit;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final tint = kit.category.color;
    return Semantics(
      button: true,
      label: '${kit.title}, ${kit.sampleCount} samples',
      child: KitoSurface(
        border: true,
        radius: 24,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -40,
              start: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    tint.withValues(alpha: 0.30),
                    tint.withValues(alpha: 0)
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                              colors: [tint, tint.withValues(alpha: 0.65)]),
                          boxShadow: [
                            BoxShadow(
                                color: tint.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Icon(kit.icon, color: Colors.white, size: 21),
                      ),
                      const Spacer(),
                      if (kit.isNew) const HomeNewBadge(),
                    ],
                  ),
                  const Spacer(),
                  Text(kit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.bodyEmphasized
                          .copyWith(color: theme.colors.onSurface)),
                  const SizedBox(height: 2),
                  Text('${kit.sampleCount} samples',
                      style: theme.typography.caption.copyWith(
                          color:
                              theme.colors.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dimmed tile for a kit that's on its way.
class HomeUpcomingTile extends StatelessWidget {
  const HomeUpcomingTile({super.key, required this.kit});

  final UpcomingKit kit;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Opacity(
      opacity: 0.55,
      child: KitoSurface(
        border: true,
        radius: 30,
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 16, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kit.category.color.withValues(alpha: 0.35)),
              child: Icon(kit.icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kit.title,
                    style: theme.typography.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colors.onSurface)),
                Text('Coming soon',
                    style: theme.typography.caption.copyWith(
                        color: theme.colors.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeNewBadge extends StatelessWidget {
  const HomeNewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: const LinearGradient(
            colors: [Color(0xFFFF4081), Color(0xFFFF9100)]),
      ),
      child: const Text('NEW',
          style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6)),
    );
  }
}

/// All + one chip per category; the selected chip fills.
class HomeCategoryChips extends StatelessWidget {
  const HomeCategoryChips(
      {super.key,
      required this.categories,
      required this.selected,
      required this.onSelected});

  final List<KitCategory> categories;
  final KitCategory? selected;
  final ValueChanged<KitCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, null, 'All', Icons.grid_view_rounded),
          for (final c in categories) _chip(context, c, c.title, c.icon),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, KitCategory? value, String label, IconData icon) {
    final theme = context.kito;
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Semantics(
        selected: isSelected,
        button: true,
        child: GestureDetector(
          onTap: () => onSelected(value),
          child: AnimatedContainer(
            duration: KitoMotion.of(context, theme.motion.medium),
            curve: theme.motion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colors.primary
                  : theme.colors.onBackground.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(theme.radii.pill),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: isSelected
                        ? theme.colors.onPrimary
                        : theme.colors.onBackground.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.typography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? theme.colors.onPrimary
                        : theme.colors.onBackground.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
