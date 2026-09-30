// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/foundation.dart';

/// A run of inline text with one set of styles.
@immutable
class KitoAiInlineRun {
  /// Creates a run.
  const KitoAiInlineRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.strike = false,
    this.link,
  });

  /// The visible text, markers removed.
  final String text;

  /// `**bold**` or `__bold__`.
  final bool bold;

  /// `*italic*` or `_italic_`.
  final bool italic;

  /// `` `code` ``.
  final bool code;

  /// `~~strike~~`.
  final bool strike;

  /// The target of `[text](url)`.
  final String? link;

  bool _sameStyle(KitoAiInlineRun o) =>
      o.bold == bold &&
      o.italic == italic &&
      o.code == code &&
      o.strike == strike &&
      o.link == link;

  @override
  bool operator ==(Object other) =>
      other is KitoAiInlineRun && other.text == text && _sameStyle(other);

  @override
  int get hashCode => Object.hash(text, bold, italic, code, strike, link);

  @override
  String toString() {
    final flags = [
      if (bold) 'bold',
      if (italic) 'italic',
      if (code) 'code',
      if (strike) 'strike',
      if (link != null) 'link: $link',
    ];
    return flags.isEmpty ? '"$text"' : '"$text" (${flags.join(', ')})';
  }
}

/// Splits inline markdown — bold, italic, `code`, ~~strike~~ and links — into styled runs.
///
/// ```dart
/// KitoAiInlineMarkdown.runs('Take the **SGR** to `Mombasa`');
/// // ["Take the ", "SGR" (bold), " to ", "Mombasa" (code)]
/// ```
abstract final class KitoAiInlineMarkdown {
  /// The styled runs in [text]. Unmatched markers are kept as plain text.
  static List<KitoAiInlineRun> runs(String text) {
    final out = <KitoAiInlineRun>[];
    _parse(text, const _Style(), out);
    return _merged(out);
  }

  static void _parse(String text, _Style style, List<KitoAiInlineRun> out) {
    final buffer = StringBuffer();
    var bold = style.bold;
    var italic = style.italic;
    var strike = style.strike;
    var i = 0;

    void flush() {
      if (buffer.isEmpty) return;
      out.add(KitoAiInlineRun(buffer.toString(),
          bold: bold, italic: italic, strike: strike, link: style.link));
      buffer.clear();
    }

    bool isWordChar(int index) {
      if (index < 0 || index >= text.length) return false;
      return RegExp(r'[A-Za-z0-9]').hasMatch(text[index]);
    }

    while (i < text.length) {
      final c = text[i];
      if (c == r'\' && i + 1 < text.length) {
        buffer.write(text[i + 1]);
        i += 2;
        continue;
      }
      if (c == '`') {
        var run = 0;
        while (i + run < text.length && text[i + run] == '`') {
          run++;
        }
        final fence = '`' * run;
        final close = text.indexOf(fence, i + run);
        if (close > i + run) {
          flush();
          var code = text.substring(i + run, close);
          if (code.length > 2 && code.startsWith(' ') && code.endsWith(' ')) {
            code = code.substring(1, code.length - 1);
          }
          out.add(KitoAiInlineRun(code,
              bold: bold,
              italic: italic,
              strike: strike,
              code: true,
              link: style.link));
          i = close + run;
          continue;
        }
        buffer.write(fence);
        i += run;
        continue;
      }
      if (c == '[' && style.link == null) {
        final isImage = i > 0 && text[i - 1] == '!';
        final close = _matching(text, i);
        if (close > 0 && close + 1 < text.length && text[close + 1] == '(') {
          final end = text.indexOf(')', close + 2);
          if (end > 0) {
            if (isImage && buffer.isNotEmpty) {
              final kept = buffer.toString();
              buffer
                ..clear()
                ..write(kept.substring(0, kept.length - 1));
            }
            flush();
            final label = text.substring(i + 1, close);
            final url = text.substring(close + 2, end).trim().split(' ').first;
            _parse(
                label,
                _Style(bold: bold, italic: italic, strike: strike, link: url),
                out);
            i = end + 1;
            continue;
          }
        }
      }
      if ((c == '*' || c == '_') &&
          i + 1 < text.length &&
          text[i + 1] == c &&
          (c == '*' || !isWordChar(i - 1))) {
        final marker = c * 2;
        if (bold || text.indexOf(marker, i + 2) > i + 2) {
          flush();
          bold = !bold;
          i += 2;
          continue;
        }
      }
      if (c == '~' && i + 1 < text.length && text[i + 1] == '~') {
        if (strike || text.indexOf('~~', i + 2) > i + 2) {
          flush();
          strike = !strike;
          i += 2;
          continue;
        }
      }
      if (c == '*' || (c == '_' && (italic || !isWordChar(i - 1)))) {
        final next = i + 1 < text.length ? text[i + 1] : ' ';
        final opens = !italic && next != ' ' && _hasCloser(text, c, i + 1);
        final closes = italic && (c != '_' || !isWordChar(i + 1));
        if (opens || closes) {
          flush();
          italic = !italic;
          i += 1;
          continue;
        }
      }
      buffer.write(c);
      i++;
    }
    flush();
  }

  static bool _hasCloser(String text, String marker, int from) {
    for (var j = from; j < text.length; j++) {
      if (text[j] == marker &&
          text[j - 1] != ' ' &&
          (j + 1 >= text.length || text[j + 1] != marker)) {
        return true;
      }
    }
    return false;
  }

  static int _matching(String text, int open) {
    var depth = 0;
    for (var j = open; j < text.length; j++) {
      if (text[j] == '[') depth++;
      if (text[j] == ']') {
        depth--;
        if (depth == 0) return j;
      }
    }
    return -1;
  }

  static List<KitoAiInlineRun> _merged(List<KitoAiInlineRun> runs) {
    final out = <KitoAiInlineRun>[];
    for (final run in runs) {
      if (run.text.isEmpty) continue;
      if (out.isNotEmpty && out.last._sameStyle(run) && !run.code) {
        final last = out.removeLast();
        out.add(KitoAiInlineRun(last.text + run.text,
            bold: run.bold,
            italic: run.italic,
            strike: run.strike,
            code: run.code,
            link: run.link));
      } else {
        out.add(run);
      }
    }
    return out;
  }
}

class _Style {
  const _Style(
      {this.bold = false, this.italic = false, this.strike = false, this.link});

  final bool bold;
  final bool italic;
  final bool strike;
  final String? link;
}
