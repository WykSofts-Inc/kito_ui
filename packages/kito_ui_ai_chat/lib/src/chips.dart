// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'orb.dart';
import 'parts.dart';

/// A tool the assistant is using: "Searching the web…" with a spinner and a light sweep while
/// it runs, then "Searched the web · 4 sources" with a check.
///
/// ```dart
/// KitoAiToolChip(call: KitoAiToolCall.webSearch())
/// ```
class KitoAiToolChip extends StatelessWidget {
  /// Shows [call].
  const KitoAiToolChip({super.key, required this.call, this.tint});

  /// The call.
  final KitoAiToolCall call;

  /// The spinner and icon colour; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = aiAccent(theme, tint);
    final running = call.status == KitoAiToolStatus.running;
    final failed = call.status == KitoAiToolStatus.failed;
    final detail = call.detail;
    final label = [
      call.title,
      if (detail != null && detail.isNotEmpty && !running) detail,
    ].join(' · ');
    final Widget leading = running
        ? SizedBox.square(
            dimension: 14,
            child: context.reduceMotion
                ? Icon(call.icon, size: 14, color: accent)
                : CircularProgressIndicator(strokeWidth: 1.8, color: accent),
          )
        : Icon(
            failed ? Icons.error_outline_rounded : call.icon,
            size: 15,
            color: failed ? theme.colors.warning : aiMuted(theme, 0.6),
          );
    return Semantics(
      label: label,
      liveRegion: running,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: KitoMotion.of(context, theme.motion.medium),
        curve: theme.motion.standard,
        padding: EdgeInsetsDirectional.symmetric(
            horizontal: theme.spacing.md, vertical: theme.spacing.sm - 1),
        decoration: BoxDecoration(
          color:
              theme.colors.surfaceMuted.withValues(alpha: running ? 0.9 : 0.6),
          borderRadius: BorderRadius.circular(theme.radii.pill),
          border: Border.all(color: theme.colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: KitoMotion.of(context, theme.motion.fast),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: KeyedSubtree(key: ValueKey(call.status), child: leading),
            ),
            SizedBox(width: theme.spacing.sm),
            Flexible(
              child: KitoAiShimmer(
                isActive: running,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: call.title),
                    if (detail != null && detail.isNotEmpty && !running)
                      TextSpan(
                          text: ' · $detail',
                          style: TextStyle(color: aiMuted(theme, 0.5))),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.label
                      .copyWith(color: aiMuted(theme, 0.75), fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered source chips: "1 magicalkenya.com", "2 krc.co.ke"… in a row that scrolls sideways.
///
/// ```dart
/// KitoAiCitationChips(citations: message.citations, onSelect: (c) => launch(c.url))
/// ```
class KitoAiCitationChips extends StatelessWidget {
  /// Shows [citations].
  const KitoAiCitationChips(
      {super.key, required this.citations, this.onSelect, this.tint});

  /// The sources, in order.
  final List<KitoAiCitation> citations;

  /// Called when a chip is tapped.
  final ValueChanged<KitoAiCitation>? onSelect;

  /// The number badge colour; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return const SizedBox.shrink();
    final theme = context.kito;
    final accent = aiAccent(theme, tint);
    return Semantics(
      container: true,
      label: citations.length == 1 ? '1 source' : '${citations.length} sources',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < citations.length; i++) ...[
              if (i > 0) SizedBox(width: theme.spacing.xs + 2),
              AiEntrance(
                delay: Duration(milliseconds: 40 * i),
                child: AiTap(
                  onTap:
                      onSelect == null ? null : () => onSelect!(citations[i]),
                  label:
                      'Source ${i + 1}: ${citations[i].title}, ${citations[i].displaySource}',
                  minSize: 36,
                  child: Container(
                    padding: EdgeInsetsDirectional.only(
                        start: 4, end: theme.spacing.md, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: theme.colors.surface,
                      borderRadius: BorderRadius.circular(theme.radii.pill),
                      border: Border.all(color: theme.colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}',
                              style: theme.typography.caption.copyWith(
                                  color: accent, fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(width: theme.spacing.xs + 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            citations[i].displaySource.isEmpty
                                ? citations[i].title
                                : citations[i].displaySource,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.caption.copyWith(
                                color: aiMuted(theme, 0.75), fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Suggested next prompts after the latest reply, each with an arrow that follows the reading
/// direction.
///
/// ```dart
/// KitoAiFollowUpChips(suggestions: session.followUps, onSelect: session.send)
/// ```
class KitoAiFollowUpChips extends StatelessWidget {
  /// Shows [suggestions].
  const KitoAiFollowUpChips(
      {super.key,
      required this.suggestions,
      required this.onSelect,
      this.tint});

  /// The prompts.
  final List<String> suggestions;

  /// Called with the tapped prompt.
  final ValueChanged<String> onSelect;

  /// The arrow colour; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < suggestions.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : theme.spacing.xs + 2),
            child: AiEntrance(
              delay: Duration(milliseconds: 60 * i),
              child: AiTap(
                onTap: () => onSelect(suggestions[i]),
                label: 'Ask: ${suggestions[i]}',
                radius: theme.radii.pill,
                minSize: 40,
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: theme.spacing.md, vertical: theme.spacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(theme.radii.pill),
                    border: Border.all(color: theme.colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.flip(
                        flipX: context.isRtl,
                        child: Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 16, color: aiAccent(theme, tint)),
                      ),
                      SizedBox(width: theme.spacing.xs + 2),
                      Flexible(
                        child: Text(suggestions[i],
                            style: theme.typography.label
                                .copyWith(color: theme.colors.onSurface)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Starter prompt cards for an empty conversation, two to a row, rising in one after another.
///
/// ```dart
/// KitoAiSuggestedPrompts(onSelect: (s) => session.send(s.prompt))
/// ```
class KitoAiSuggestedPrompts extends StatelessWidget {
  /// Shows [suggestions].
  const KitoAiSuggestedPrompts({
    super.key,
    this.suggestions = KitoAiSuggestion.defaults,
    required this.onSelect,
    this.tint,
    this.columns = 2,
  });

  /// The cards.
  final List<KitoAiSuggestion> suggestions;

  /// Called with the tapped card.
  final ValueChanged<KitoAiSuggestion> onSelect;

  /// The icon colour; the theme's primary when null.
  final Color? tint;

  /// Cards per row.
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final gap = theme.spacing.sm + 2;
    final rows = <List<KitoAiSuggestion>>[
      for (var i = 0; i < suggestions.length; i += columns)
        suggestions.sublist(
            i,
            i + columns > suggestions.length
                ? suggestions.length
                : i + columns),
    ];
    var index = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) SizedBox(width: gap),
                    Expanded(
                      child: c < rows[r].length
                          ? AiEntrance(
                              delay: Duration(milliseconds: 70 * index++),
                              dy: 14,
                              child: _PromptCard(
                                  suggestion: rows[r][c],
                                  onTap: () => onSelect(rows[r][c]),
                                  tint: tint),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard(
      {required this.suggestion, required this.onTap, required this.tint});

  final KitoAiSuggestion suggestion;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return AiTap(
      onTap: onTap,
      label: '${suggestion.title} ${suggestion.subtitle}',
      radius: theme.radii.lg,
      scale: 0.97,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(theme.spacing.md),
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(theme.radii.lg),
          border: Border.all(color: theme.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(suggestion.icon, size: 18, color: aiAccent(theme, tint)),
            SizedBox(height: theme.spacing.sm),
            Text(suggestion.title,
                style: theme.typography.label.copyWith(
                    color: theme.colors.onSurface,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: theme.spacing.xxs),
            Text(suggestion.subtitle,
                style: theme.typography.caption
                    .copyWith(color: aiMuted(theme, 0.55))),
          ],
        ),
      ),
    );
  }
}

/// A file waiting in the composer or sent with a message, with an optional remove button.
///
/// ```dart
/// KitoAiAttachmentChip(attachment: file, onRemove: () => remove(file))
/// ```
class KitoAiAttachmentChip extends StatelessWidget {
  /// Shows [attachment].
  const KitoAiAttachmentChip(
      {super.key, required this.attachment, this.onRemove, this.tint});

  /// The file.
  final KitoAiAttachment attachment;

  /// Shows an × that calls this.
  final VoidCallback? onRemove;

  /// The icon tile colour; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = aiAccent(theme, tint);
    return Semantics(
      container: true,
      label: '${attachment.name}, ${attachment.subtitle}',
      child: Container(
        padding: EdgeInsetsDirectional.only(
            start: 6, top: 6, bottom: 6, end: onRemove == null ? 12 : 2),
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(theme.radii.md + 2),
          border: Border.all(color: theme.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(theme.radii.sm + 2),
              ),
              child: Icon(attachment.kind.icon, size: 18, color: accent),
            ),
            SizedBox(width: theme.spacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.label.copyWith(
                            color: theme.colors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    Text(attachment.subtitle,
                        maxLines: 1,
                        style: theme.typography.caption.copyWith(
                            color: aiMuted(theme, 0.55), fontSize: 11)),
                  ],
                ),
              ),
            ),
            if (onRemove != null)
              AiTap(
                onTap: onRemove,
                label: 'Remove ${attachment.name}',
                minSize: 36,
                child: Icon(Icons.close_rounded,
                    size: 16, color: aiMuted(theme, 0.5)),
              ),
          ],
        ),
      ),
    );
  }
}
