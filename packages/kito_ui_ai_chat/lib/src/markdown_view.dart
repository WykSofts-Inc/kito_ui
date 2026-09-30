// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'code_block.dart';
import 'inline.dart';
import 'markdown.dart';
import 'orb.dart';
import 'parts.dart';

/// Renders markdown: headings, paragraphs, bulleted, numbered and task lists, quotes, tables,
/// rules and code blocks, with bold, italic, `code`, ~~strike~~ and links inline.
///
/// While [isStreaming], unfinished syntax is held back (see [KitoAiStreamAssembler]) and a
/// blinking cursor follows the text.
///
/// ```dart
/// KitoAiMarkdownView(reply)
/// KitoAiMarkdownView(partial, isStreaming: true, onLinkTap: launch)
/// ```
class KitoAiMarkdownView extends StatelessWidget {
  /// Renders [markdown].
  const KitoAiMarkdownView(
    this.markdown, {
    super.key,
    this.isStreaming = false,
    this.tint,
    this.onLinkTap,
    this.style,
  });

  /// The markdown.
  final String markdown;

  /// Holds back unfinished syntax and shows a cursor.
  final bool isStreaming;

  /// Links and quote bars; the theme's primary when null.
  final Color? tint;

  /// Called with a link's url when it's tapped.
  final ValueChanged<String>? onLinkTap;

  /// The body text style; the theme's body style when null.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final text = KitoAiStreamAssembler.displayTextFor(markdown,
        isStreaming: isStreaming);
    final blocks = KitoAiMarkdown.blocks(text);
    final body = (style ?? theme.typography.body)
        .copyWith(color: style?.color ?? theme.colors.onSurface);
    final ctx = _MdContext(
      theme: theme,
      body: body,
      accent: aiAccent(theme, tint),
      linkColor: tint ??
          (theme.brightness == Brightness.dark
              ? const Color(0xFF7CB7FF)
              : const Color(0xFF2563EB)),
      onLinkTap: onLinkTap,
    );
    final cursor = isStreaming
        ? WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 3),
              child: KitoAiStreamingCursor(
                  tint: tint, height: (body.fontSize ?? 16) * 0.95),
            ),
          )
        : null;
    if (blocks.isEmpty) {
      return cursor == null
          ? const SizedBox.shrink()
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text.rich(TextSpan(children: [cursor])));
    }
    final last = blocks.length - 1;
    final trailingInline = blocks.last is! KitoAiMarkdownCode &&
        blocks.last is! KitoAiMarkdownTable &&
        blocks.last is! KitoAiMarkdownRule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: _gapBefore(blocks[i], theme)),
          _block(ctx, blocks[i],
              trailing: i == last && trailingInline ? cursor : null,
              streamingCode: isStreaming && i == last),
        ],
        if (cursor != null && !trailingInline) ...[
          SizedBox(height: theme.spacing.sm),
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text.rich(TextSpan(children: [cursor]))),
        ],
      ],
    );
  }

  static double _gapBefore(KitoAiMarkdownBlock block, KitoTheme theme) =>
      block is KitoAiMarkdownHeading ? theme.spacing.lg : theme.spacing.md;

  Widget _block(_MdContext ctx, KitoAiMarkdownBlock block,
      {InlineSpan? trailing, required bool streamingCode}) {
    final theme = ctx.theme;
    switch (block) {
      case KitoAiMarkdownHeading(:final level, :final text):
        final style = switch (level) {
          1 => theme.typography.title,
          2 => theme.typography.title.copyWith(fontSize: 19),
          3 => theme.typography.headline,
          _ => theme.typography.bodyEmphasized,
        };
        return Semantics(
          header: true,
          child: _InlineText(text,
              ctx: ctx,
              style: style.copyWith(color: theme.colors.onSurface),
              trailing: trailing),
        );
      case KitoAiMarkdownParagraph(:final text):
        return _InlineText(text, ctx: ctx, style: ctx.body, trailing: trailing);
      case KitoAiMarkdownList(:final items):
        return _List(items: items, ctx: ctx, trailing: trailing);
      case KitoAiMarkdownQuote(:final text):
        return Container(
          padding: EdgeInsetsDirectional.only(
              start: theme.spacing.md,
              top: theme.spacing.xxs,
              bottom: theme.spacing.xxs),
          decoration: BoxDecoration(
            border: BorderDirectional(
                start: BorderSide(
                    color: ctx.accent.withValues(alpha: 0.35), width: 3)),
          ),
          child: _InlineText(text,
              ctx: ctx,
              style: ctx.body.copyWith(color: aiMuted(theme, 0.75)),
              trailing: trailing),
        );
      case KitoAiMarkdownCode(:final code, :final language, :final isClosed):
        return KitoAiCodeBlock(
            code: code,
            language: language,
            isStreaming: streamingCode && !isClosed);
      case KitoAiMarkdownTable():
        return _Table(table: block, ctx: ctx);
      case KitoAiMarkdownRule():
        return Divider(height: theme.spacing.md, color: theme.colors.border);
    }
  }
}

class _MdContext {
  const _MdContext({
    required this.theme,
    required this.body,
    required this.accent,
    required this.linkColor,
    required this.onLinkTap,
  });

  final KitoTheme theme;
  final TextStyle body;
  final Color accent;
  final Color linkColor;
  final ValueChanged<String>? onLinkTap;
}

class _InlineText extends StatefulWidget {
  const _InlineText(this.text,
      {required this.ctx, required this.style, this.trailing, this.align});

  final String text;
  final _MdContext ctx;
  final TextStyle style;
  final InlineSpan? trailing;
  final TextAlign? align;

  @override
  State<_InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<_InlineText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final ctx = widget.ctx;
    final theme = ctx.theme;
    final spans = <InlineSpan>[];
    for (final run in KitoAiInlineMarkdown.runs(widget.text)) {
      var style = TextStyle(
        fontWeight: run.bold ? FontWeight.w700 : null,
        fontStyle: run.italic ? FontStyle.italic : null,
        decoration: run.strike
            ? TextDecoration.lineThrough
            : run.link != null
                ? TextDecoration.underline
                : null,
        decorationColor:
            run.link != null ? ctx.linkColor.withValues(alpha: 0.4) : null,
        color: run.link != null ? ctx.linkColor : null,
      );
      if (run.code) {
        style = style.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Courier New', 'Roboto Mono'],
          fontSize: (widget.style.fontSize ?? 16) * 0.88,
          backgroundColor: theme.colors.surfaceMuted,
        );
      }
      TapGestureRecognizer? recognizer;
      final link = run.link;
      if (link != null && ctx.onLinkTap != null) {
        recognizer = TapGestureRecognizer()..onTap = () => ctx.onLinkTap!(link);
        _recognizers.add(recognizer);
      }
      spans.add(TextSpan(
          text: run.code ? ' ${run.text} ' : run.text,
          style: style,
          recognizer: recognizer));
    }
    if (widget.trailing != null) spans.add(widget.trailing!);
    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      textAlign: widget.align,
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items, required this.ctx, this.trailing});

  final List<KitoAiMarkdownListItem> items;
  final _MdContext ctx;
  final InlineSpan? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ctx.theme;
    final last = items.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsetsDirectional.only(
                start: items[i].level * 18.0,
                top: i == 0 ? 0 : theme.spacing.xs + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: items[i].isOrdered ? 26 : 20,
                  child: _marker(items[i], theme),
                ),
                Expanded(
                  child: _InlineText(
                    items[i].text,
                    ctx: ctx,
                    style: items[i].isChecked == true
                        ? ctx.body.copyWith(
                            color: aiMuted(theme, 0.55),
                            decoration: TextDecoration.lineThrough)
                        : ctx.body,
                    trailing: i == last ? trailing : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _marker(KitoAiMarkdownListItem item, KitoTheme theme) {
    final muted = aiMuted(theme, 0.6);
    if (item.isChecked case final checked?) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Semantics(
          checked: checked,
          child: Icon(
            checked
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            size: 18,
            color: checked ? ctx.accent : muted,
          ),
        ),
      );
    }
    if (item.number case final n?) {
      return Text('$n.',
          style: ctx.body.copyWith(
              color: muted,
              fontFeatures: const [FontFeature.tabularFigures()]));
    }
    return Text(item.level == 0 ? '•' : '◦',
        style: ctx.body.copyWith(color: muted, fontWeight: FontWeight.w700));
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.table, required this.ctx});

  final KitoAiMarkdownTable table;
  final _MdContext ctx;

  TextAlign _align(int column) => switch (table.alignments[column]) {
        KitoAiTableAlignment.start => TextAlign.start,
        KitoAiTableAlignment.center => TextAlign.center,
        KitoAiTableAlignment.end => TextAlign.end,
      };

  @override
  Widget build(BuildContext context) {
    final theme = ctx.theme;
    final small = ctx.body.copyWith(fontSize: (ctx.body.fontSize ?? 16) - 1.5);
    final radius = BorderRadius.circular(theme.radii.md);
    Widget cell(String text, int column, {bool header = false}) => Padding(
          padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md, vertical: theme.spacing.sm),
          child: _InlineText(text,
              ctx: ctx,
              style:
                  header ? small.copyWith(fontWeight: FontWeight.w700) : small,
              align: _align(column)),
        );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.colors.border),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                horizontalInside: BorderSide(color: theme.colors.border),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: theme.colors.surfaceMuted),
                  children: [
                    for (var c = 0; c < table.header.length; c++)
                      cell(table.header[c], c, header: true),
                  ],
                ),
                for (final row in table.rows)
                  TableRow(children: [
                    for (var c = 0; c < row.length; c++) cell(row[c], c),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Streams markdown from any `Stream<String>` of tokens and renders it as it arrives: "Thinking…"
/// until the first token, then text that grows with a cursor, then the finished reply.
///
/// ```dart
/// KitoAiStreamingMarkdown(stream: client.streamText(prompt))
/// ```
///
/// For whole conversations, use [KitoAiChatSession] and [KitoAiChatView] instead.
class KitoAiStreamingMarkdown extends StatefulWidget {
  /// Listens to [stream].
  const KitoAiStreamingMarkdown({
    super.key,
    required this.stream,
    this.tint,
    this.showsThinking = true,
    this.onLinkTap,
    this.onDone,
    this.onError,
  });

  /// The tokens.
  final Stream<String> stream;

  /// Links, quote bars and the orb; the theme's primary when null.
  final Color? tint;

  /// Shows "Thinking…" until the first token.
  final bool showsThinking;

  /// Called with a link's url when it's tapped.
  final ValueChanged<String>? onLinkTap;

  /// Called with the whole text once the stream finishes.
  final ValueChanged<String>? onDone;

  /// Called if the stream fails; what arrived stays on screen.
  final ValueChanged<Object>? onError;

  @override
  State<KitoAiStreamingMarkdown> createState() =>
      _KitoAiStreamingMarkdownState();
}

class _KitoAiStreamingMarkdownState extends State<KitoAiStreamingMarkdown> {
  StreamSubscription<String>? _subscription;
  final _text = StringBuffer();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(KitoAiStreamingMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _subscription?.cancel();
      _text.clear();
      _done = false;
      _listen();
    }
  }

  void _listen() {
    _subscription = widget.stream.listen(
      (token) => setState(() => _text.write(token)),
      onError: (Object error) {
        setState(() => _done = true);
        widget.onError?.call(error);
      },
      onDone: () {
        setState(() => _done = true);
        widget.onDone?.call(_text.toString());
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _text.toString();
    final theme = context.kito;
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, theme.motion.fast),
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, if (current != null) current],
      ),
      child: !_done && text.trim().isEmpty && widget.showsThinking
          ? Align(
              key: const ValueKey('thinking'),
              alignment: AlignmentDirectional.centerStart,
              child: KitoAiThinkingIndicator(tint: widget.tint),
            )
          : KitoAiMarkdownView(
              text,
              key: const ValueKey('text'),
              isStreaming: !_done,
              tint: widget.tint,
              onLinkTap: widget.onLinkTap,
            ),
    );
  }
}
