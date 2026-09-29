// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'country.dart';
import 'search.dart';

/// A searchable list of calling regions: flag, name and dial code, favourites pinned on top.
///
/// Show it as a sheet with [KitoFieldCountryPicker.show], or embed it.
class KitoFieldCountryPicker extends StatefulWidget {
  /// Creates a picker.
  const KitoFieldCountryPicker({
    super.key,
    this.selected,
    required this.onSelected,
    this.countries,
    this.favorites = const [],
    this.title = 'Country or region',
    this.searchPlaceholder = 'Search countries',
  });

  /// Shows a tick next to this one.
  final KitoFieldCountry? selected;

  /// Runs when a region is tapped.
  final ValueChanged<KitoFieldCountry> onSelected;

  /// Limits the list; every region when null.
  final List<KitoFieldCountry>? countries;

  /// ISO codes pinned at the top, in order (e.g. `['KE', 'UG', 'TZ']`).
  final List<String> favorites;

  /// The heading.
  final String title;

  /// The search placeholder.
  final String searchPlaceholder;

  /// Opens the picker in a bottom sheet and resolves to the chosen region (or null).
  static Future<KitoFieldCountry?> show(
    BuildContext context, {
    KitoFieldCountry? selected,
    List<KitoFieldCountry>? countries,
    List<String> favorites = const [],
    String title = 'Country or region',
  }) {
    final kito = context.kito;
    return showModalBottomSheet<KitoFieldCountry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kito.colors.surface,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(kito.radii.xl))),
      builder: (sheet) => FractionallySizedBox(
        heightFactor: 0.88,
        child: KitoFieldCountryPicker(
          selected: selected,
          countries: countries,
          favorites: favorites,
          title: title,
          onSelected: (c) => Navigator.of(sheet).pop(c),
        ),
      ),
    );
  }

  @override
  State<KitoFieldCountryPicker> createState() => _KitoFieldCountryPickerState();
}

class _KitoFieldCountryPickerState extends State<KitoFieldCountryPicker> {
  String _query = '';

  List<KitoFieldCountry> get _source =>
      widget.countries ?? KitoFieldCountries.all;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final source = _source;
    final matches = _query.isEmpty
        ? source
        : KitoFieldCountries.search(_query)
            .where((c) => widget.countries == null || source.contains(c))
            .toList();
    final favorites = _query.isEmpty
        ? [
            for (final iso in widget.favorites)
              if (KitoFieldCountries.byIsoCode(iso) case final c?)
                if (source.contains(c)) c
          ]
        : const <KitoFieldCountry>[];

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
              color: kito.colors.border,
              borderRadius: BorderRadius.circular(3)),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              header: true,
              child: Text(widget.title,
                  style: kito.typography.title
                      .copyWith(color: kito.colors.onSurface)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: KitoFieldSearchBar(
            placeholder: widget.searchPlaceholder,
            showsCancel: false,
            debounce: Duration.zero,
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: matches.isEmpty
              ? Center(
                  child: Text('No matches',
                      style: kito.typography.body.copyWith(
                          color: kito.colors.onSurface.withValues(alpha: 0.5))),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final c in favorites) _row(kito, c),
                    if (favorites.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        child: Divider(height: 1, color: kito.colors.border),
                      ),
                    for (final c in matches) _row(kito, c),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _row(KitoTheme kito, KitoFieldCountry c) {
    final selected = c == widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: '${c.englishName}, ${c.formattedDialCode}',
      excludeSemantics: true,
      onTap: () => widget.onSelected(c),
      child: InkWell(
        onTap: () => widget.onSelected(c),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(c.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(c.englishName,
                      style: kito.typography.body
                          .copyWith(color: kito.colors.onSurface)),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(c.formattedDialCode,
                      style: kito.typography.label.copyWith(
                          color: kito.colors.onSurface.withValues(alpha: 0.55),
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
                AnimatedSwitcher(
                  duration: KitoMotion.of(context, kito.motion.fast),
                  child: selected
                      ? Padding(
                          key: const ValueKey('on'),
                          padding: const EdgeInsetsDirectional.only(start: 10),
                          child: Icon(Icons.check_rounded,
                              size: 20, color: kito.colors.primary),
                        )
                      : const SizedBox(key: ValueKey('off'), width: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
