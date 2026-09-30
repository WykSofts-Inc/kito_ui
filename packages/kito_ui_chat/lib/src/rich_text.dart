// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A run of message text with its inline formatting.
@immutable
class KitoChatTextSegment {
  /// Creates a segment.
  const KitoChatTextSegment(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
    this.link,
  });

  /// The characters.
  final String text;

  /// `**bold**`.
  final bool bold;

  /// `*italic*` or `_italic_`.
  final bool italic;

  /// `~~struck~~`.
  final bool strike;

  /// `` `code` ``.
  final bool code;

  /// Where a link goes.
  final Uri? link;

  @override
  bool operator ==(Object other) =>
      other is KitoChatTextSegment &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.strike == strike &&
      other.code == code &&
      other.link == link;

  @override
  int get hashCode => Object.hash(text, bold, italic, strike, code, link);

  @override
  String toString() =>
      'Segment("$text"${bold ? ' b' : ''}${italic ? ' i' : ''}${strike ? ' s' : ''}'
      '${code ? ' c' : ''}${link != null ? ' $link' : ''})';
}

/// Inline Markdown for chat text: `**bold**`, `*italic*`, `_italic_`, `~~strike~~`,
/// `` `code` `` and bare links (`https://…`, `www.…`).
abstract final class KitoChatMarkdown {
  static final _url = RegExp(
      r'((?:https?:\/\/|www\.)[^\s<>()]+[^\s<>().,!?;:"'
      "'"
      r'])',
      caseSensitive: false);

  /// Splits [text] into formatted segments.
  static List<KitoChatTextSegment> parse(String text) {
    final raw = <KitoChatTextSegment>[];
    _parse(text, raw, const KitoChatTextSegment(''));
    final out = <KitoChatTextSegment>[];
    for (final s in raw) {
      if (s.code) {
        out.add(s);
        continue;
      }
      var last = 0;
      for (final m in _url.allMatches(s.text)) {
        if (m.start > last) out.add(_with(s, s.text.substring(last, m.start)));
        final url = m.group(0)!;
        final uri = Uri.tryParse(
            url.toLowerCase().startsWith('www.') ? 'https://$url' : url);
        out.add(KitoChatTextSegment(url,
            bold: s.bold, italic: s.italic, strike: s.strike, link: uri));
        last = m.end;
      }
      if (last < s.text.length) out.add(_with(s, s.text.substring(last)));
    }
    return _merge(out);
  }

  static KitoChatTextSegment _with(KitoChatTextSegment s, String text) =>
      KitoChatTextSegment(text,
          bold: s.bold, italic: s.italic, strike: s.strike, code: s.code);

  static void _parse(
      String text, List<KitoChatTextSegment> out, KitoChatTextSegment style) {
    final plain = StringBuffer();
    void flush() {
      if (plain.isEmpty) return;
      out.add(_with(style, plain.toString()));
      plain.clear();
    }

    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == '\\' && i + 1 < text.length && '*_~`\\'.contains(text[i + 1])) {
        plain.write(text[i + 1]);
        i += 2;
        continue;
      }
      if (c == '`') {
        final end = text.indexOf('`', i + 1);
        if (end > i + 1) {
          flush();
          out.add(KitoChatTextSegment(text.substring(i + 1, end), code: true));
          i = end + 1;
          continue;
        }
      }
      String? marker;
      if (text.startsWith('**', i)) {
        marker = '**';
      } else if (text.startsWith('~~', i)) {
        marker = '~~';
      } else if (c == '*' || c == '_') {
        final before = i == 0 ? ' ' : text[i - 1];
        if (c == '*' || !_isWordChar(before)) marker = c;
      }
      if (marker != null) {
        final end = _closing(text, marker, i + marker.length);
        if (end > i + marker.length) {
          flush();
          final inner = text.substring(i + marker.length, end);
          _parse(
            inner,
            out,
            KitoChatTextSegment('',
                bold: style.bold || marker == '**',
                italic: style.italic || marker == '*' || marker == '_',
                strike: style.strike || marker == '~~'),
          );
          i = end + marker.length;
          continue;
        }
      }
      plain.write(c);
      i++;
    }
    flush();
  }

  static int _closing(String text, String marker, int from) {
    if (from >= text.length || text[from] == ' ') return -1;
    var j = from;
    while (true) {
      j = text.indexOf(marker, j);
      if (j < 0) return -1;
      final single = marker.length == 1;
      final doubled = single && j + 1 < text.length && text[j + 1] == marker;
      final spaced = text[j - 1] == ' ';
      final wordAfter =
          marker == '_' && j + 1 < text.length && _isWordChar(text[j + 1]);
      if (!doubled && !spaced && !wordAfter) return j;
      j += doubled ? 2 : 1;
    }
  }

  static bool _isWordChar(String c) =>
      RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(c);

  static List<KitoChatTextSegment> _merge(List<KitoChatTextSegment> segs) {
    final out = <KitoChatTextSegment>[];
    for (final s in segs) {
      if (s.text.isEmpty) continue;
      if (out.isNotEmpty) {
        final p = out.last;
        if (p.bold == s.bold &&
            p.italic == s.italic &&
            p.strike == s.strike &&
            p.code == s.code &&
            p.link == null &&
            s.link == null) {
          out[out.length - 1] = _with(p, p.text + s.text);
          continue;
        }
      }
      out.add(s);
    }
    return out;
  }
}

/// Message text with inline Markdown and tappable links.
class KitoChatText extends StatefulWidget {
  /// Creates formatted text.
  const KitoChatText(
    this.text, {
    super.key,
    this.style,
    this.linkColor,
    this.codeBackground,
    this.onLinkTap,
    this.textAlign,
  });

  /// The raw text.
  final String text;

  /// The base style.
  final TextStyle? style;

  /// Link colour; the base colour when null.
  final Color? linkColor;

  /// Behind `code`; a faint wash of the text colour when null.
  final Color? codeBackground;

  /// Called when a link is tapped.
  final ValueChanged<Uri>? onLinkTap;

  /// Alignment.
  final TextAlign? textAlign;

  @override
  State<KitoChatText> createState() => _KitoChatTextState();
}

class _KitoChatTextState extends State<KitoChatText> {
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
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    final color = base.color ?? Theme.of(context).colorScheme.onSurface;
    final spans = <InlineSpan>[];
    for (final s in KitoChatMarkdown.parse(widget.text)) {
      var style = TextStyle(
        fontWeight: s.bold ? FontWeight.w700 : null,
        fontStyle: s.italic ? FontStyle.italic : null,
        decoration: s.strike
            ? TextDecoration.lineThrough
            : (s.link != null ? TextDecoration.underline : null),
        decorationColor: s.link != null ? (widget.linkColor ?? color) : null,
        color: s.link != null ? (widget.linkColor ?? color) : null,
      );
      if (s.code) {
        style = style.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Courier'],
          backgroundColor:
              widget.codeBackground ?? color.withValues(alpha: 0.12),
        );
      }
      TapGestureRecognizer? recognizer;
      if (s.link != null && widget.onLinkTap != null) {
        final uri = s.link!;
        recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onLinkTap!(uri);
        _recognizers.add(recognizer);
      }
      spans.add(TextSpan(text: s.text, style: style, recognizer: recognizer));
    }
    return Text.rich(TextSpan(children: spans),
        style: widget.style, textAlign: widget.textAlign);
  }
}
