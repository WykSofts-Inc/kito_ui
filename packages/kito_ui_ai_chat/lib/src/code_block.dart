// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'parts.dart';
import 'syntax.dart';

/// Colours for highlighted code.
@immutable
class KitoAiCodePalette {
  /// Creates a palette.
  const KitoAiCodePalette({
    required this.background,
    required this.header,
    required this.plain,
    required this.keyword,
    required this.string,
    required this.comment,
    required this.number,
    required this.type,
    required this.function,
  });

  /// Behind the code.
  final Color background;

  /// Behind the language label and Copy.
  final Color header;

  /// Ordinary code.
  final Color plain;

  /// Keywords.
  final Color keyword;

  /// Strings.
  final Color string;

  /// Comments.
  final Color comment;

  /// Numbers.
  final Color number;

  /// Type names.
  final Color type;

  /// Function names.
  final Color function;

  /// For light themes.
  static const light = KitoAiCodePalette(
    background: Color(0xFFF4F4F7),
    header: Color(0xFFEAEAF0),
    plain: Color(0xFF1F2330),
    keyword: Color(0xFFAD3DA4),
    string: Color(0xFFC4401D),
    comment: Color(0xFF7A8290),
    number: Color(0xFF2F57C9),
    type: Color(0xFF0E7C86),
    function: Color(0xFF4B45C6),
  );

  /// For dark themes.
  static const dark = KitoAiCodePalette(
    background: Color(0xFF14151C),
    header: Color(0xFF1D1F29),
    plain: Color(0xFFE6E7EE),
    keyword: Color(0xFFFF7AB2),
    string: Color(0xFFFF8170),
    comment: Color(0xFF7F8C98),
    number: Color(0xFFD9C97C),
    type: Color(0xFF6BDFFF),
    function: Color(0xFFB281EB),
  );

  /// The palette for [theme]'s brightness.
  static KitoAiCodePalette of(KitoTheme theme) =>
      theme.brightness == Brightness.dark ? dark : light;

  /// The colour for a token kind.
  Color colorFor(KitoAiSyntaxKind kind) => switch (kind) {
        KitoAiSyntaxKind.plain => plain,
        KitoAiSyntaxKind.keyword => keyword,
        KitoAiSyntaxKind.string => string,
        KitoAiSyntaxKind.comment => comment,
        KitoAiSyntaxKind.number => number,
        KitoAiSyntaxKind.type => type,
        KitoAiSyntaxKind.function => function,
      };
}

/// A code block with a language label, Copy, syntax colours and sideways scrolling. The code
/// stays left-to-right in RTL layouts; the header mirrors.
///
/// ```dart
/// KitoAiCodeBlock(code: snippet, language: 'dart')
/// ```
class KitoAiCodeBlock extends StatefulWidget {
  /// Creates a code block.
  const KitoAiCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.isStreaming = false,
    this.palette,
    this.onCopied,
  });

  /// The source.
  final String code;

  /// "dart", "swift", "json"… shown in the header and used for colours.
  final String? language;

  /// Hides Copy until the block is complete.
  final bool isStreaming;

  /// Overrides the colours.
  final KitoAiCodePalette? palette;

  /// Called after Copy puts the code on the clipboard.
  final VoidCallback? onCopied;

  @override
  State<KitoAiCodeBlock> createState() => _KitoAiCodeBlockState();
}

class _KitoAiCodeBlockState extends State<KitoAiCodeBlock> {
  bool _copied = false;
  Timer? _reset;
  List<KitoAiSyntaxToken>? _tokens;
  String? _tokensFor;

  List<KitoAiSyntaxToken> get _highlighted {
    final key = '${widget.language}\u0000${widget.code}';
    if (_tokensFor != key) {
      _tokens = KitoAiSyntaxHighlighter.tokens(widget.code,
          language: widget.language);
      _tokensFor = key;
    }
    return _tokens!;
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    widget.onCopied?.call();
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
    final theme = context.kito;
    final palette = widget.palette ?? KitoAiCodePalette.of(theme);
    final label = (widget.language?.isNotEmpty ?? false)
        ? widget.language!.toLowerCase()
        : 'code';
    final mono = theme.typography.label.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier New', 'Roboto Mono'],
      fontSize: 13,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    final radius = BorderRadius.circular(theme.radii.md + 2);
    return Semantics(
      container: true,
      label: '$label code block',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: radius,
          border: Border.all(color: theme.colors.border.withValues(alpha: 0.6)),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: palette.header,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: theme.spacing.md, end: theme.spacing.xs),
                  child: Row(
                    children: [
                      Icon(Icons.code_rounded,
                          size: 14, color: palette.comment),
                      SizedBox(width: theme.spacing.xs + 2),
                      Expanded(
                        child: Text(label,
                            style: theme.typography.caption
                                .copyWith(color: palette.comment)),
                      ),
                      AnimatedOpacity(
                        opacity: widget.isStreaming ? 0 : 1,
                        duration: KitoMotion.of(context, theme.motion.fast),
                        child: AiTap(
                          onTap: widget.isStreaming ? null : _copy,
                          label: _copied ? 'Copied' : 'Copy code',
                          minSize: 36,
                          radius: theme.radii.sm,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: theme.spacing.sm),
                            child: AnimatedSwitcher(
                              duration:
                                  KitoMotion.of(context, theme.motion.fast),
                              child: Row(
                                key: ValueKey(_copied),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      _copied
                                          ? Icons.check_rounded
                                          : Icons.copy_rounded,
                                      size: 14,
                                      color: _copied
                                          ? theme.colors.success
                                          : palette.comment),
                                  SizedBox(width: theme.spacing.xs),
                                  Text(_copied ? 'Copied' : 'Copy',
                                      style: theme.typography.caption.copyWith(
                                          color: _copied
                                              ? theme.colors.success
                                              : palette.comment)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.all(theme.spacing.md),
                  child: Text.rich(
                    TextSpan(
                      style: mono.copyWith(color: palette.plain),
                      children: [
                        for (final token in _highlighted)
                          TextSpan(
                            text: token.text,
                            style: token.kind == KitoAiSyntaxKind.plain
                                ? null
                                : TextStyle(
                                    color: palette.colorFor(token.kind),
                                    fontStyle:
                                        token.kind == KitoAiSyntaxKind.comment
                                            ? FontStyle.italic
                                            : null,
                                  ),
                          ),
                      ],
                    ),
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
