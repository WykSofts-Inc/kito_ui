// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'chips.dart';
import 'code_block.dart';
import 'markdown_view.dart';
import 'models.dart';
import 'orb.dart';
import 'parts.dart';

/// One message. User messages sit in a bubble at the end; assistant replies run full width
/// beside a small orb, with tool chips, markdown, code, images and sources, then Copy, 👍, 👎
/// and Regenerate once they finish. A failed reply shows an error bubble with Retry.
///
/// ```dart
/// KitoAiMessageView(
///   message: message,
///   onRegenerate: session.regenerate,
///   onFeedback: (f) => session.setFeedback(f, message.id),
/// )
/// ```
class KitoAiMessageView extends StatefulWidget {
  /// Shows [message].
  const KitoAiMessageView({
    super.key,
    required this.message,
    this.showsAvatar = true,
    this.tint,
    this.onRegenerate,
    this.onFeedback,
    this.onRetry,
    this.onEdit,
    this.onCopy,
    this.onLinkTap,
    this.onCitationTap,
  });

  /// The message.
  final KitoAiMessage message;

  /// Shows the orb beside assistant replies.
  final bool showsAvatar;

  /// Links, the orb and chips; the theme's primary when null.
  final Color? tint;

  /// Shows Regenerate under a finished reply.
  final VoidCallback? onRegenerate;

  /// Shows thumbs up and down under a finished reply.
  final ValueChanged<KitoAiFeedback>? onFeedback;

  /// The error bubble's Retry; defaults to [onRegenerate].
  final VoidCallback? onRetry;

  /// Shows Edit under a user message.
  final VoidCallback? onEdit;

  /// Called after Copy, with the copied text.
  final ValueChanged<String>? onCopy;

  /// Called with a link's url when it's tapped.
  final ValueChanged<String>? onLinkTap;

  /// Called when a source chip is tapped.
  final ValueChanged<KitoAiCitation>? onCitationTap;

  @override
  State<KitoAiMessageView> createState() => _KitoAiMessageViewState();
}

class _KitoAiMessageViewState extends State<KitoAiMessageView> {
  bool _copied = false;
  Timer? _reset;
  bool _toolOpen = false;

  KitoAiMessage get _m => widget.message;

  Future<void> _copy() async {
    final text = _m.text;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    widget.onCopy?.call(text);
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_m.role) {
      KitoAiRole.user => _user(context),
      KitoAiRole.assistant => _assistant(context),
      KitoAiRole.system => _system(context),
      KitoAiRole.tool => _tool(context),
    };
  }

  // MARK: User

  Widget _user(BuildContext context) {
    final theme = context.kito;
    final text = _m.text;
    return Padding(
      padding: EdgeInsetsDirectional.only(
          start: theme.spacing.xxl + theme.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in _m.attachments)
            Padding(
              padding: EdgeInsets.only(bottom: theme.spacing.xs + 2),
              child: KitoAiAttachmentChip(attachment: a, tint: widget.tint),
            ),
          if (text.isNotEmpty)
            Semantics(
              label: 'You: ${_m.plainText}',
              excludeSemantics: true,
              customSemanticsActions: {
                const CustomSemanticsAction(label: 'Copy'): _copy,
                if (widget.onEdit != null)
                  const CustomSemanticsAction(label: 'Edit'): widget.onEdit!,
              },
              child: GestureDetector(
                onLongPress: _copy,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.md + 2,
                      vertical: theme.spacing.sm + 2),
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(theme.radii.xl),
                    border: Border.all(
                        color: theme.colors.border.withValues(alpha: 0.5),
                        width: 0.5),
                  ),
                  child: KitoAiMarkdownView(text, tint: widget.tint),
                ),
              ),
            ),
          if (widget.onEdit != null)
            Padding(
              padding: EdgeInsets.only(top: theme.spacing.xxs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AiIconAction(
                    icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                    label: _copied ? 'Copied' : 'Copy',
                    onTap: _copy,
                  ),
                  AiIconAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit message',
                    onTap: widget.onEdit,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // MARK: Assistant

  Widget _assistant(BuildContext context) {
    final theme = context.kito;
    final m = _m;
    final lastMarkdown =
        m.blocks.lastIndexWhere((b) => b is KitoAiMarkdownContent);
    final children = <Widget>[];
    void add(Widget w) {
      if (children.isNotEmpty) children.add(SizedBox(height: theme.spacing.md));
      children.add(w);
    }

    if (m.isStreaming && !m.hasVisibleContent) {
      add(const Padding(
        padding: EdgeInsets.only(top: 3),
        child: KitoAiThinkingIndicator(showsOrb: false),
      ));
    }
    for (var i = 0; i < m.blocks.length; i++) {
      final block = m.blocks[i];
      switch (block) {
        case KitoAiMarkdownContent(:final text):
          if (text.trim().isEmpty && !(m.isStreaming && i == lastMarkdown)) {
            continue;
          }
          add(KitoAiMarkdownView(text,
              isStreaming: m.isStreaming && i == lastMarkdown,
              tint: widget.tint,
              onLinkTap: widget.onLinkTap));
        case KitoAiCodeContent(:final code, :final language):
          add(KitoAiCodeBlock(code: code, language: language));
        case KitoAiImageContent(:final image):
          add(_ImageBlock(image: image));
        case KitoAiToolCallContent(:final call):
          add(Align(
            alignment: AlignmentDirectional.centerStart,
            child: AiEntrance(
                child: KitoAiToolChip(call: call, tint: widget.tint)),
          ));
        case KitoAiCitationsContent(:final citations):
          if (m.isStreaming) continue;
          add(AiEntrance(
            child: KitoAiCitationChips(
                citations: citations,
                onSelect: widget.onCitationTap,
                tint: widget.tint),
          ));
      }
    }
    if (m.wasStopped) {
      add(Text('Stopped',
          style:
              theme.typography.caption.copyWith(color: aiMuted(theme, 0.45))));
    }
    if (m.errorMessage case final error?) {
      add(KitoAiErrorBubble(
          message: error, onRetry: widget.onRetry ?? widget.onRegenerate));
    }
    final showsActions = !m.isStreaming &&
        m.errorMessage == null &&
        m.hasVisibleContent &&
        (widget.onRegenerate != null || widget.onFeedback != null);
    if (showsActions) {
      children.add(SizedBox(height: theme.spacing.xxs));
      children.add(AiEntrance(child: _actions(theme)));
    }

    return Semantics(
      container: true,
      label: m.isStreaming ? null : 'Assistant',
      customSemanticsActions: m.isStreaming
          ? null
          : {const CustomSemanticsAction(label: 'Copy'): _copy},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showsAvatar) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: KitoAiOrb(
                  size: 24,
                  isActive: m.isStreaming,
                  animatesWhenIdle: false,
                  tint: widget.tint),
            ),
            SizedBox(width: theme.spacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(KitoTheme theme) {
    final feedback = _m.feedback;
    final accent = aiAccent(theme, widget.tint);
    return Row(
      children: [
        AiIconAction(
          icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
          label: _copied ? 'Copied' : 'Copy',
          onTap: _copy,
          color: _copied ? theme.colors.success : null,
        ),
        if (widget.onFeedback != null) ...[
          AiIconAction(
            icon: feedback == KitoAiFeedback.positive
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            label: 'Good response',
            selected: feedback == KitoAiFeedback.positive,
            color: feedback == KitoAiFeedback.positive ? accent : null,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onFeedback!(KitoAiFeedback.positive);
            },
          ),
          AiIconAction(
            icon: feedback == KitoAiFeedback.negative
                ? Icons.thumb_down_rounded
                : Icons.thumb_down_outlined,
            label: 'Bad response',
            selected: feedback == KitoAiFeedback.negative,
            color: feedback == KitoAiFeedback.negative ? accent : null,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onFeedback!(KitoAiFeedback.negative);
            },
          ),
        ],
        if (widget.onRegenerate != null)
          AiIconAction(
            icon: Icons.refresh_rounded,
            label: 'Regenerate',
            onTap: widget.onRegenerate,
          ),
      ],
    );
  }

  // MARK: System and tool

  Widget _system(BuildContext context) {
    final theme = context.kito;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
        child: Text(_m.plainText,
            textAlign: TextAlign.center,
            style:
                theme.typography.caption.copyWith(color: aiMuted(theme, 0.5))),
      ),
    );
  }

  Widget _tool(BuildContext context) {
    final theme = context.kito;
    return Padding(
      padding: EdgeInsetsDirectional.only(
          start: widget.showsAvatar ? 24 + theme.spacing.md : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AiTap(
            onTap: () => setState(() => _toolOpen = !_toolOpen),
            label: _toolOpen ? 'Hide tool result' : 'Show tool result',
            radius: theme.radii.sm,
            minSize: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.terminal_rounded,
                    size: 15, color: aiMuted(theme, 0.5)),
                SizedBox(width: theme.spacing.xs + 2),
                Text('Tool result',
                    style: theme.typography.caption
                        .copyWith(color: aiMuted(theme, 0.6))),
                AnimatedRotation(
                  turns: _toolOpen ? 0.25 : 0,
                  duration: KitoMotion.of(context, theme.motion.fast),
                  child: Icon(
                      context.isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 16,
                      color: aiMuted(theme, 0.5)),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: KitoMotion.of(context, theme.motion.fast),
            alignment: AlignmentDirectional.topStart,
            child: _toolOpen
                ? KitoAiCodeBlock(code: _m.text, language: 'text')
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.image});

  final KitoAiImage image;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    Widget placeholder() => ColoredBox(
          color: theme.colors.surfaceMuted,
          child: Icon(Icons.image_outlined, color: aiMuted(theme, 0.35)),
        );
    final Widget picture;
    if (image.bytes case final bytes?) {
      picture = Image.memory(bytes,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder());
    } else if (image.url case final url?) {
      picture = Image.network(url,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder());
    } else {
      picture = placeholder();
    }
    return Semantics(
      image: true,
      label: image.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radii.lg),
        child: AspectRatio(
            aspectRatio: image.aspectRatio <= 0 ? 4 / 3 : image.aspectRatio,
            child: picture),
      ),
    );
  }
}

/// A failed reply: what went wrong and a Retry button.
///
/// ```dart
/// KitoAiErrorBubble(message: 'The connection was lost.', onRetry: session.retry)
/// ```
class KitoAiErrorBubble extends StatelessWidget {
  /// Shows [message].
  const KitoAiErrorBubble({super.key, required this.message, this.onRetry});

  /// What went wrong.
  final String message;

  /// Shows Retry.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final danger = theme.colors.danger;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.only(
            start: theme.spacing.md,
            end: theme.spacing.xs,
            top: theme.spacing.xs,
            bottom: theme.spacing.xs),
        decoration: BoxDecoration(
          color: danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(theme.radii.md + 2),
          border: Border.all(color: danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: danger),
            SizedBox(width: theme.spacing.sm),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
                child: Text(message,
                    style: theme.typography.label
                        .copyWith(color: theme.colors.onSurface)),
              ),
            ),
            if (onRetry != null)
              AiTap(
                onTap: onRetry,
                label: 'Retry',
                radius: theme.radii.pill,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: danger),
                      SizedBox(width: theme.spacing.xs),
                      Text('Retry',
                          style: theme.typography.label.copyWith(
                              color: danger, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
