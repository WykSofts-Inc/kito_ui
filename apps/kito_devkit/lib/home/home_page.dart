// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../app/settings.dart';
import '../catalog/catalog.dart';
import '../gallery/gallery.dart';
import '../settings/settings_page.dart';
import 'home_widgets.dart';

/// The front page: header, featured kits, new and recent kits, and a grid to browse.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();
  final _featured = PageController(viewportFraction: 0.86);
  String _query = '';
  KitCategory? _category;
  double _page = 0;

  static const _featureColors = <String, List<Color>>{
    'Foundations': [Color(0xFF004D40), Color(0xFF00BFA5)],
  };

  @override
  void initState() {
    super.initState();
    _featured.addListener(() => setState(() => _page = _featured.page ?? 0));
  }

  @override
  void dispose() {
    _search.dispose();
    _featured.dispose();
    super.dispose();
  }

  void _open(KitEntry kit) {
    AppSettingsScope.of(context).remember(kit.title);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => KitGalleryPage(kit: kit)));
  }

  void _surprise() {
    final kits = KitCatalog.kits;
    if (kits.isEmpty) return;
    _open(kits[math.Random().nextInt(kits.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: HomeHeader(
                      kitCount: KitCatalog.kits.length,
                      sampleCount: KitCatalog.sampleCount,
                      onSurprise: _surprise,
                      onSettings: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: GallerySearchField(
                      controller: _search,
                      hint:
                          'Search ${KitCatalog.sampleCount} samples and every kit',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
                if (searching)
                  ..._searchResults(context)
                else
                  ..._home(context),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _home(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final recent =
        settings.recent.map(KitCatalog.byTitle).whereType<KitEntry>().toList();
    final newKits = KitCatalog.kits.where((k) => k.isNew).toList();
    final categories = KitCategory.values
        .where((c) => KitCatalog.kits.any((k) => k.category == c))
        .toList();
    final shown = _category == null ? categories : [_category!];

    return [
      _gap(20),
      _header('Featured', Icons.star_rounded),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _featured,
            itemCount: KitCatalog.kits.length,
            itemBuilder: (context, i) {
              final kit = KitCatalog.kits[i];
              final distance = (i - _page).abs().clamp(0.0, 1.0);
              return Transform.scale(
                scale: 1 - distance * 0.08,
                child: Opacity(
                  opacity: 1 - distance * 0.25,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: GestureDetector(
                      onTap: () => _open(kit),
                      child: HomeFeatureCard(
                        kit: kit,
                        colors: _featureColors[kit.category.title] ??
                            [
                              kit.category.color.withValues(alpha: 0.9),
                              const Color(0xFF311B92),
                            ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      if (newKits.isNotEmpty) ...[
        _gap(24),
        _header(
          'New',
          Icons.auto_awesome_rounded,
          trailing: '${newKits.length} kits',
        ),
        _strip([for (final k in newKits) _chipCard(k)]),
      ],
      if (recent.isNotEmpty) ...[
        _gap(24),
        _header('Jump back in', Icons.history_rounded),
        _strip([for (final k in recent) _chipCard(k)]),
      ],
      _gap(24),
      _header(
        'Browse',
        Icons.grid_view_rounded,
        trailing: '${KitCatalog.kits.length} kits',
      ),
      _gap(12),
      SliverToBoxAdapter(
        child: HomeCategoryChips(
          categories: categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
      ),
      for (final category in shown) ...[
        if (_category == null)
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(category.icon, size: 14, color: category.color),
                  const SizedBox(width: 6),
                  Text(
                    category.title.toUpperCase(),
                    style: context.kito.typography.caption.copyWith(
                      color: category.color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _gap(14),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final kit in KitCatalog.kits.where(
                (k) => k.category == category,
              ))
                KitoPressable(
                  child: GestureDetector(
                    onTap: () => _open(kit),
                    child: HomeKitTile(kit: kit),
                  ),
                ),
            ],
          ),
        ),
      ],
      if (KitCatalog.upcoming.isNotEmpty) ...[
        _gap(28),
        _header(
          'Coming soon',
          Icons.hourglass_top_rounded,
          trailing: '${KitCatalog.upcoming.length} kits',
        ),
        _strip([for (final k in KitCatalog.upcoming) HomeUpcomingTile(kit: k)]),
      ],
      _gap(32),
      const SliverToBoxAdapter(child: _Footer()),
    ];
  }

  List<Widget> _searchResults(BuildContext context) {
    final theme = context.kito;
    final kits = KitCatalog.searchKits(_query);
    final samples = KitCatalog.searchSamples(_query);
    if (kits.isEmpty && samples.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: GalleryNoResults(
            query: _query,
            hint:
                'Try a kit (“core”), a sample (“glass”) or a behaviour (“spring”).',
          ),
        ),
      ];
    }
    return [
      if (kits.isNotEmpty) ...[
        _gap(12),
        _header('Kits', Icons.layers_rounded),
        _gap(10),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final k in kits)
                GestureDetector(
                  onTap: () => _open(k),
                  child: HomeKitTile(kit: k),
                ),
            ],
          ),
        ),
      ],
      if (samples.isNotEmpty) ...[
        _gap(20),
        _header(
          '${samples.length} sample${samples.length == 1 ? '' : 's'}',
          Icons.auto_awesome_rounded,
        ),
        _gap(10),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: KitoSurface(
              border: true,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (final hit in samples)
                      ListTile(
                        leading: Icon(
                          hit.kit.icon,
                          color: hit.kit.category.color,
                        ),
                        title: Text(
                          hit.sample.title,
                          style: theme.typography.bodyEmphasized.copyWith(
                            color: theme.colors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${hit.kit.title} · ${hit.section.title}',
                          style: theme.typography.caption.copyWith(
                            color: theme.colors.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SampleDetailPage(
                              kit: hit.kit,
                              sample: hit.sample,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ];
  }

  Widget _chipCard(KitEntry kit) {
    final theme = context.kito;
    return KitoPressable(
      child: GestureDetector(
        onTap: () => _open(kit),
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
                  color: kit.category.color,
                ),
                child: Icon(kit.icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kit.title,
                    style: theme.typography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colors.onSurface,
                    ),
                  ),
                  Text(
                    '${kit.sampleCount} samples',
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _strip(List<Widget> children) => SliverToBoxAdapter(
        child: SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => children[i],
          ),
        ),
      );

  Widget _header(String title, IconData icon, {String? trailing}) =>
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: HomeSectionHeader(
            title: title,
            icon: icon,
            trailing: trailing,
          ),
        ),
      );

  Widget _gap(double height) =>
      SliverToBoxAdapter(child: SizedBox(height: height));
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return IgnorePointer(
      child: Stack(
        children: [
          PositionedDirectional(
            top: -180,
            start: -160,
            child: _blob(theme.colors.primary.withValues(alpha: 0.22), 420),
          ),
          PositionedDirectional(
            top: 260,
            end: -180,
            child: _blob(theme.colors.secondary.withValues(alpha: 0.18), 380),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final muted = theme.colors.onBackground.withValues(alpha: 0.5);
    return Column(
      children: [
        Icon(Icons.flutter_dash_rounded, color: theme.colors.primary, size: 28),
        const SizedBox(height: 6),
        Text(
          'Made in Nairobi with Flutter',
          style: theme.typography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.onBackground.withValues(alpha: 0.7),
          ),
        ),
        Text(
          'wyksoftsinc.com · v1.0.0',
          style: theme.typography.caption.copyWith(color: muted),
        ),
      ],
    );
  }
}
