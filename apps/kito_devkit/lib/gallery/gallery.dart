// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';

/// A kit's gallery: its sections and samples, searchable.
class KitGalleryPage extends StatefulWidget {
  const KitGalleryPage({super.key, required this.kit});

  final KitEntry kit;

  @override
  State<KitGalleryPage> createState() => _KitGalleryPageState();
}

class _KitGalleryPageState extends State<KitGalleryPage> {
  String _query = '';

  bool _matches(KitSection section, KitSample sample) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return sample.title.toLowerCase().contains(q) ||
        sample.subtitle.toLowerCase().contains(q) ||
        section.title.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final kit = widget.kit;
    final sections = [
      for (final s in kit.sections)
        (s, s.samples.where((sample) => _matches(s, sample)).toList()),
    ].where((e) => e.$2.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        title: Text(kit.title),
        backgroundColor: theme.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 32),
        children: [
          Text(
            '${kit.sampleCount} samples · ${kit.blurb}',
            style: theme.typography.label.copyWith(
                color: theme.colors.onBackground.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          GallerySearchField(
            hint: 'Search ${kit.sampleCount} samples',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),
          if (sections.isEmpty) GalleryNoResults(query: _query),
          for (final (section, samples) in sections) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 4, top: 12, bottom: 8),
              child: Row(
                children: [
                  Icon(section.icon, size: 18, color: kit.category.color),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(section.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.headline
                            .copyWith(color: theme.colors.onBackground)),
                  ),
                ],
              ),
            ),
            KitoSurface(
              border: true,
              padding: EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (var i = 0; i < samples.length; i++) ...[
                      _SampleRow(kit: kit, sample: samples[i]),
                      if (i < samples.length - 1)
                        Divider(
                            height: 1, indent: 16, color: theme.colors.border),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SampleRow extends StatelessWidget {
  const _SampleRow({required this.kit, required this.sample});

  final KitEntry kit;
  final KitSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => SampleDetailPage(kit: kit, sample: sample)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sample.title,
                      style: theme.typography.bodyEmphasized
                          .copyWith(color: theme.colors.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    sample.subtitle,
                    style: theme.typography.caption.copyWith(
                        color: theme.colors.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colors.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

/// One sample on its own screen: the live preview, then its code with a copy button.
class SampleDetailPage extends StatelessWidget {
  const SampleDetailPage({super.key, required this.kit, required this.sample});

  final KitEntry kit;
  final KitSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        title: Text(sample.title),
        backgroundColor: theme.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 32),
        children: [
          Text(sample.subtitle,
              style: theme.typography.body.copyWith(
                  color: theme.colors.onBackground.withValues(alpha: 0.65))),
          const SizedBox(height: 16),
          KitoSurface(
            border: true,
            padding: const EdgeInsets.all(24),
            child: Material(
                type: MaterialType.transparency,
                child: Center(child: Builder(builder: sample.builder))),
          ),
          const SizedBox(height: 24),
          CodeBlock(
              code: sample.code,
              footnote:
                  'Requires `import \'package:${kit.package}/${kit.package}.dart\';`'),
        ],
      ),
    );
  }
}

/// Monospaced code with a Copy button that confirms in place.
class CodeBlock extends StatefulWidget {
  const CodeBlock({super.key, required this.code, this.footnote});

  final String code;
  final String? footnote;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Code',
                style: theme.typography.headline
                    .copyWith(color: theme.colors.onBackground)),
            const Spacer(),
            Semantics(
              button: true,
              label: _copied ? 'Code copied' : 'Copy code',
              child: KitoPressable(
                child: GestureDetector(
                  onTap: _copy,
                  child: AnimatedContainer(
                    duration: KitoMotion.of(context, theme.motion.fast),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _copied
                          ? theme.colors.primary
                          : theme.colors.onBackground.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(theme.radii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 16,
                          color: _copied
                              ? theme.colors.onPrimary
                              : theme.colors.onBackground,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: theme.typography.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _copied
                                ? theme.colors.onPrimary
                                : theme.colors.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Directionality(
          textDirection: TextDirection.ltr,
          child: KitoSurface(
            background: KitoBackground.color(theme.colors.surfaceMuted),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                widget.code,
                style: TextStyle(
                    fontFamily: 'Menlo',
                    fontFamilyFallback: const ['Courier', 'monospace'],
                    fontSize: 13,
                    height: 1.45,
                    color: theme.colors.onSurface),
              ),
            ),
          ),
        ),
        if (widget.footnote != null) ...[
          const SizedBox(height: 10),
          Text(widget.footnote!,
              style: theme.typography.caption.copyWith(
                  color: theme.colors.onBackground.withValues(alpha: 0.5))),
        ],
      ],
    );
  }
}

/// The rounded search field used on the home screen and in galleries.
class GallerySearchField extends StatelessWidget {
  const GallerySearchField(
      {super.key,
      required this.hint,
      required this.onChanged,
      this.controller});

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: theme.typography.body.copyWith(color: theme.colors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.typography.body
            .copyWith(color: theme.colors.onSurface.withValues(alpha: 0.45)),
        prefixIcon: Icon(Icons.search_rounded,
            color: theme.colors.onSurface.withValues(alpha: 0.55)),
        filled: true,
        fillColor: theme.colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.radii.pill),
            borderSide: BorderSide(color: theme.colors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.radii.pill),
            borderSide: BorderSide(color: theme.colors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.radii.pill),
            borderSide: BorderSide(color: theme.colors.primary, width: 1.5)),
      ),
    );
  }
}

/// Shown when a search finds nothing.
class GalleryNoResults extends StatelessWidget {
  const GalleryNoResults(
      {super.key,
      required this.query,
      this.hint = 'Try a component, a behaviour or a screen.'});

  final String query;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 40,
              color: theme.colors.onBackground.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Text('Nothing for “$query”',
              style: theme.typography.headline
                  .copyWith(color: theme.colors.onBackground)),
          const SizedBox(height: 4),
          Text(hint,
              textAlign: TextAlign.center,
              style: theme.typography.caption.copyWith(
                  color: theme.colors.onBackground.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
