// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/foundation.dart';

/// One item of a markdown list.
@immutable
class KitoAiMarkdownListItem {
  /// Creates a list item.
  const KitoAiMarkdownListItem(this.text,
      {this.level = 0, this.number, this.isChecked});

  /// Inline markdown.
  final String text;

  /// 0 for top-level items; nested items count up by indentation.
  final int level;

  /// The number as written for ordered items; null for bullets.
  final int? number;

  /// `true`/`false` for task items (`- [x]` / `- [ ]`), null otherwise.
  final bool? isChecked;

  /// True for `1.` items.
  bool get isOrdered => number != null;

  KitoAiMarkdownListItem _appending(String more, String separator) =>
      KitoAiMarkdownListItem(text.isEmpty ? more : '$text$separator$more',
          level: level, number: number, isChecked: isChecked);

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownListItem &&
      other.text == text &&
      other.level == level &&
      other.number == number &&
      other.isChecked == isChecked;

  @override
  int get hashCode => Object.hash(text, level, number, isChecked);

  @override
  String toString() =>
      'KitoAiMarkdownListItem($text, level: $level, number: $number, checked: $isChecked)';
}

/// How a table column lines up. Start and end follow the reading direction.
enum KitoAiTableAlignment {
  /// `:--` or `---`.
  start,

  /// `:-:`.
  center,

  /// `--:`.
  end,
}

/// A block of markdown. Inline styles (bold, italic, `code`, links, ~~strike~~) stay in the text.
@immutable
sealed class KitoAiMarkdownBlock {
  const KitoAiMarkdownBlock();

  /// A short name for the kind of block — handy in tests and logs.
  String get kind;
}

/// `# Title` to `###### Title`.
final class KitoAiMarkdownHeading extends KitoAiMarkdownBlock {
  /// Creates a heading.
  const KitoAiMarkdownHeading(this.level, this.text);

  /// 1–6.
  final int level;

  /// Inline markdown.
  final String text;

  @override
  String get kind => 'heading';

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownHeading &&
      other.level == level &&
      other.text == text;

  @override
  int get hashCode => Object.hash(level, text);

  @override
  String toString() => 'heading($level, $text)';
}

/// Running text; single newlines inside it are kept.
final class KitoAiMarkdownParagraph extends KitoAiMarkdownBlock {
  /// Creates a paragraph.
  const KitoAiMarkdownParagraph(this.text);

  /// Inline markdown.
  final String text;

  @override
  String get kind => 'paragraph';

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownParagraph && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'paragraph($text)';
}

/// A bulleted, numbered or task list, with nesting in each item's level.
final class KitoAiMarkdownList extends KitoAiMarkdownBlock {
  /// Creates a list.
  const KitoAiMarkdownList(this.items);

  /// The items, in order.
  final List<KitoAiMarkdownListItem> items;

  @override
  String get kind => 'list';

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownList && listEquals(other.items, items);

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => 'list($items)';
}

/// `> quoted` lines.
final class KitoAiMarkdownQuote extends KitoAiMarkdownBlock {
  /// Creates a quote.
  const KitoAiMarkdownQuote(this.text);

  /// Inline markdown, lines joined with newlines.
  final String text;

  @override
  String get kind => 'quote';

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownQuote && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A fenced code block.
final class KitoAiMarkdownCode extends KitoAiMarkdownBlock {
  /// Creates a code block.
  const KitoAiMarkdownCode(this.code, {this.language, this.isClosed = true});

  /// The source, without the fences.
  final String code;

  /// The info string's first word, e.g. `dart`.
  final String? language;

  /// False while a streamed fence hasn't been closed yet.
  final bool isClosed;

  @override
  String get kind => 'code';

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownCode &&
      other.code == code &&
      other.language == language &&
      other.isClosed == isClosed;

  @override
  int get hashCode => Object.hash(code, language, isClosed);

  @override
  String toString() => 'code($language, closed: $isClosed)';
}

/// A GitHub-style table.
final class KitoAiMarkdownTable extends KitoAiMarkdownBlock {
  /// Creates a table.
  const KitoAiMarkdownTable(
      {required this.header, required this.alignments, required this.rows});

  /// Header cells (inline markdown).
  final List<String> header;

  /// One per column.
  final List<KitoAiTableAlignment> alignments;

  /// Every row has exactly `header.length` cells.
  final List<List<String>> rows;

  @override
  String get kind => 'table';

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownTable &&
      listEquals(other.header, header) &&
      listEquals(other.alignments, alignments) &&
      other.rows.length == rows.length &&
      [for (var i = 0; i < rows.length; i++) listEquals(other.rows[i], rows[i])]
          .every((same) => same);

  @override
  int get hashCode => Object.hash(Object.hashAll(header),
      Object.hashAll(alignments), Object.hashAll(rows.map(Object.hashAll)));
}

/// `---`, `***` or `___`.
final class KitoAiMarkdownRule extends KitoAiMarkdownBlock {
  /// Creates a rule.
  const KitoAiMarkdownRule();

  @override
  String get kind => 'rule';

  @override
  bool operator ==(Object other) => other is KitoAiMarkdownRule;

  @override
  int get hashCode => 7;
}

/// Splits markdown into blocks: headings, paragraphs, lists (nested, ordered, task), block
/// quotes, fenced code, tables and rules. Pure and fast enough to run on every streamed token.
///
/// ```dart
/// KitoAiMarkdown.blocks('## Diani\n- SGR\n- Ferry');   // [heading, list]
/// KitoAiMarkdown.plainText('**Asante** sana');           // "Asante sana"
/// ```
abstract final class KitoAiMarkdown {
  /// The blocks in [markdown].
  static List<KitoAiMarkdownBlock> blocks(String markdown) =>
      _Parser(_normalizedLines(markdown)).run();

  /// The text with markdown syntax removed — for previews, titles and screen readers.
  static String plainText(String markdown) {
    final lines = [
      for (final block in blocks(markdown))
        switch (block) {
          KitoAiMarkdownHeading(:final text) => stripInline(text),
          KitoAiMarkdownParagraph(:final text) => stripInline(text),
          KitoAiMarkdownQuote(:final text) => stripInline(text),
          KitoAiMarkdownList(:final items) =>
            items.map((i) => stripInline(i.text)).join('\n'),
          KitoAiMarkdownCode(:final code) => code,
          KitoAiMarkdownTable(:final header, :final rows) => [header, ...rows]
              .map((r) => r.map(stripInline).join(', '))
              .join('\n'),
          KitoAiMarkdownRule() => '',
        },
    ];
    return lines.where((l) => l.isNotEmpty).join('\n');
  }

  /// Removes inline markers: `**`, `*`, `` ` ``, `~~`, and turns `[text](url)` into `text`.
  static String stripInline(String text) {
    var result = _replacingLinks(text);
    for (final marker in const ['**', '__', '~~', '`', '*']) {
      result = result.replaceAll(marker, '');
    }
    return result;
  }
}

// MARK: Line classification (shared with the stream assembler)

List<String> _normalizedLines(String text) =>
    text.replaceAll('\r\n', '\n').split('\n');

String _replacingLinks(String text) {
  final out = StringBuffer();
  var rest = text;
  while (true) {
    final open = rest.indexOf('[');
    if (open < 0) break;
    final close = rest.indexOf(']', open);
    if (close < 0 || close + 1 >= rest.length || rest[close + 1] != '(') break;
    final end = rest.indexOf(')', close);
    if (end < 0) break;
    var prefix = rest.substring(0, open);
    if (prefix.endsWith('!')) prefix = prefix.substring(0, prefix.length - 1);
    out
      ..write(prefix)
      ..write(rest.substring(open + 1, close));
    rest = rest.substring(end + 1);
  }
  out.write(rest);
  return out.toString();
}

/// The line without up to three spaces of indentation.
String _unindented(String line) {
  var i = 0;
  while (i < 3 && i < line.length && line[i] == ' ') {
    i++;
  }
  return line.substring(i);
}

int _indentation(String line) {
  var width = 0;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == ' ') {
      width += 1;
    } else if (c == '\t') {
      width += 4;
    } else {
      break;
    }
  }
  return width;
}

int _run(String text, String char, [int from = 0]) {
  var end = from;
  while (end < text.length && text[end] == char) {
    end++;
  }
  return end - from;
}

bool _isBlank(String s) => s.trim().isEmpty;

bool _isDigit(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

typedef _Fence = ({String char, int length, String info});

_Fence? _fenceOpening(String line) {
  final trimmed = _unindented(line);
  if (trimmed.isEmpty) return null;
  final first = trimmed[0];
  if (first != '`' && first != '~') return null;
  final run = _run(trimmed, first);
  if (run < 3) return null;
  final info = trimmed.substring(run).trim();
  if (first == '`' && info.contains('`')) return null;
  return (char: first, length: run, info: info);
}

bool _closesFence(String line, String char, int length) {
  final trimmed = _unindented(line);
  final run = _run(trimmed, char);
  if (run < length) return false;
  return _isBlank(trimmed.substring(run));
}

(int, String)? _heading(String line) {
  final trimmed = _unindented(line);
  final hashes = _run(trimmed, '#');
  if (hashes < 1 || hashes > 6) return null;
  final rest = trimmed.substring(hashes);
  if (rest.isNotEmpty && rest[0] != ' ' && rest[0] != '\t') return null;
  var text = rest.trim();
  while (text.endsWith('#')) {
    text = text.substring(0, text.length - 1);
  }
  return (hashes, text.trim());
}

bool _isRule(String line) {
  final compact = _unindented(line).replaceAll(RegExp(r'[ \t]'), '');
  if (compact.length < 3) return false;
  final first = compact[0];
  if (!'-*_'.contains(first)) return false;
  return compact.split('').every((c) => c == first);
}

KitoAiMarkdownListItem? _listItem(String line) {
  final indent = _indentation(line);
  final trimmed = line.trimLeft();
  if (trimmed.isEmpty) return null;
  int? number;
  String rest;
  if ('-*+'.contains(trimmed[0])) {
    rest = trimmed.substring(1);
  } else {
    var digits = 0;
    while (digits < trimmed.length && _isDigit(trimmed[digits])) {
      digits++;
    }
    if (digits < 1 || digits > 9) return null;
    if (digits >= trimmed.length) return null;
    final delimiter = trimmed[digits];
    if (delimiter != '.' && delimiter != ')') return null;
    number = int.parse(trimmed.substring(0, digits));
    rest = trimmed.substring(digits + 1);
  }
  if (rest.isNotEmpty && rest[0] != ' ' && rest[0] != '\t') return null;
  var text = rest.trim();
  bool? checked;
  final lower = text.toLowerCase();
  if (text.startsWith('[ ] ') || text == '[ ]') {
    checked = false;
    text = text.substring(3).trim();
  } else if (lower.startsWith('[x] ') || lower == '[x]') {
    checked = true;
    text = text.substring(3).trim();
  }
  return KitoAiMarkdownListItem(text,
      level: indent ~/ 2, number: number, isChecked: checked);
}

bool _isQuote(String line) => _unindented(line).startsWith('>');

String _quoteContent(String line) {
  var rest = _unindented(line).substring(1);
  if (rest.startsWith(' ')) rest = rest.substring(1);
  return rest;
}

bool _isTableRow(String line) => _unindented(line).startsWith('|');

List<String> _tableCells(String line) {
  var row = line.trim();
  if (row.startsWith('|')) row = row.substring(1);
  if (row.endsWith('|') && !row.endsWith(r'\|')) {
    row = row.substring(0, row.length - 1);
  }
  final cells = <String>[];
  final current = StringBuffer();
  String? previous;
  for (var i = 0; i < row.length; i++) {
    final c = row[i];
    if (c == '|' && previous != r'\') {
      cells.add(current.toString().trim());
      current.clear();
    } else {
      current.write(c);
    }
    previous = c;
  }
  cells.add(current.toString().trim());
  return [for (final c in cells) c.replaceAll(r'\|', '|')];
}

List<KitoAiTableAlignment>? _tableAlignments(String line) {
  if (!_isTableRow(line)) return null;
  final result = <KitoAiTableAlignment>[];
  for (final cell in _tableCells(line)) {
    final dashes = '-'.allMatches(cell).length;
    if (dashes < 1 || !RegExp(r'^[-:]+$').hasMatch(cell)) return null;
    final start = cell.startsWith(':');
    final end = cell.endsWith(':');
    result.add(start && end
        ? KitoAiTableAlignment.center
        : end
            ? KitoAiTableAlignment.end
            : KitoAiTableAlignment.start);
  }
  return result;
}

class _Parser {
  _Parser(this.lines);

  final List<String> lines;
  var index = 0;
  final blocks = <KitoAiMarkdownBlock>[];
  final paragraph = <String>[];
  final listItems = <KitoAiMarkdownListItem>[];
  var listIsOrdered = false;
  var sawBlankInList = false;

  List<KitoAiMarkdownBlock> run() {
    while (index < lines.length) {
      final line = lines[index];
      if (_isBlank(line)) {
        flushParagraph();
        if (listItems.isNotEmpty) sawBlankInList = true;
        index++;
        continue;
      }
      if (handleBlockStart(line)) continue;
      if (handleListLine(line)) continue;
      flushList();
      paragraph.add(line.trim());
      index++;
    }
    flushParagraph();
    flushList();
    return blocks;
  }

  bool handleBlockStart(String line) {
    final fence = _fenceOpening(line);
    if (fence != null) {
      flushAll();
      parseFence(fence, _indentation(line));
      return true;
    }
    final heading = _heading(line);
    if (heading != null) {
      flushAll();
      blocks.add(KitoAiMarkdownHeading(heading.$1, heading.$2));
      index++;
      return true;
    }
    if (_isRule(line)) {
      flushAll();
      blocks.add(const KitoAiMarkdownRule());
      index++;
      return true;
    }
    if (_isQuote(line)) {
      flushAll();
      final quoted = <String>[];
      while (index < lines.length && _isQuote(lines[index])) {
        quoted.add(_quoteContent(lines[index]));
        index++;
      }
      blocks.add(KitoAiMarkdownQuote(quoted.join('\n')));
      return true;
    }
    if (_isTableRow(line) && index + 1 < lines.length) {
      final alignments = _tableAlignments(lines[index + 1]);
      if (alignments != null) {
        flushAll();
        parseTable(_tableCells(line), alignments);
        return true;
      }
    }
    return false;
  }

  bool handleListLine(String line) {
    final item = _listItem(line);
    if (item != null) {
      flushParagraph();
      final startsNewList = listItems.isEmpty ||
          (item.level == 0 && item.isOrdered != listIsOrdered);
      if (startsNewList) {
        flushList();
        listIsOrdered = item.isOrdered;
      }
      listItems.add(item);
      sawBlankInList = false;
      index++;
      return true;
    }
    if (listItems.isNotEmpty && _indentation(line) >= 2 && paragraph.isEmpty) {
      final continuation = line.trim();
      final last = listItems.removeLast();
      listItems.add(last._appending(continuation, sawBlankInList ? '\n' : ' '));
      sawBlankInList = false;
      index++;
      return true;
    }
    return false;
  }

  void parseFence(_Fence fence, int indent) {
    index++;
    final code = <String>[];
    var closed = false;
    while (index < lines.length) {
      final line = lines[index];
      if (_closesFence(line, fence.char, fence.length)) {
        closed = true;
        index++;
        break;
      }
      code.add(_removingIndent(indent, line));
      index++;
    }
    final language = fence.info.split(' ').first;
    blocks.add(KitoAiMarkdownCode(code.join('\n'),
        language: language.isEmpty ? null : language, isClosed: closed));
  }

  void parseTable(List<String> header, List<KitoAiTableAlignment> alignments) {
    index += 2;
    final columns = header.length;
    final rows = <List<String>>[];
    while (index < lines.length && _isTableRow(lines[index])) {
      rows.add(_fitted(_tableCells(lines[index]), columns));
      index++;
    }
    final fitted = [
      for (var i = 0; i < columns; i++)
        i < alignments.length ? alignments[i] : KitoAiTableAlignment.start,
    ];
    blocks.add(
        KitoAiMarkdownTable(header: header, alignments: fitted, rows: rows));
  }

  static List<String> _fitted(List<String> cells, int count) {
    if (cells.length >= count) return cells.sublist(0, count);
    return [...cells, for (var i = cells.length; i < count; i++) ''];
  }

  static String _removingIndent(int indent, String line) {
    var removed = 0;
    while (removed < indent && removed < line.length && line[removed] == ' ') {
      removed++;
    }
    return line.substring(removed);
  }

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(KitoAiMarkdownParagraph(paragraph.join('\n')));
    paragraph.clear();
  }

  void flushList() {
    if (listItems.isEmpty) return;
    blocks.add(KitoAiMarkdownList(List.unmodifiable(listItems)));
    listItems.clear();
    sawBlankInList = false;
  }

  void flushAll() {
    flushParagraph();
    flushList();
  }
}

/// Turns streamed tokens into markdown without flicker.
///
/// Rendering raw partial markdown makes blocks jump: a lone `#` shows as text and then becomes a
/// heading, `**bo` shows its asterisks until the closing pair arrives, and a table header shows
/// as a paragraph until its `|---|` row arrives. The assembler holds back the few characters
/// that could still change meaning and closes open inline markers, so every frame is a
/// plausible, stable rendering of what has arrived so far.
///
/// ```dart
/// final assembler = KitoAiStreamAssembler();
/// await for (final token in tokens) {
///   assembler.append(token);
///   render(assembler.blocks);
/// }
/// assembler.finish();
/// ```
class KitoAiStreamAssembler {
  /// Starts with [text] already received.
  KitoAiStreamAssembler({String text = '', bool isFinished = false})
      : _text = text,
        _finished = isFinished;

  String _text;
  bool _finished;

  /// Everything received so far.
  String get text => _text;

  /// True once [finish] was called.
  bool get isFinished => _finished;

  /// Adds a token.
  void append(String token) => _text += token;

  /// Marks the stream as complete; nothing is held back after this.
  void finish() => _finished = true;

  /// The text that is safe to render now.
  String get displayText => displayTextFor(_text, isStreaming: !_finished);

  /// The blocks to render now.
  List<KitoAiMarkdownBlock> get blocks => KitoAiMarkdown.blocks(displayText);

  /// The renderable part of [text]. When [isStreaming] is false the text is returned unchanged.
  static String displayTextFor(String text, {required bool isStreaming}) {
    if (!isStreaming || text.isEmpty) return text;
    final lines = _normalizedLines(text);
    final partial = lines.removeLast();
    final insideFence = _isInsideFence(lines);
    final shown = [...lines];
    var heldPartial = false;

    if (_isAmbiguous(partial, insideFence: insideFence)) {
      heldPartial = true;
    } else {
      shown.add(insideFence ? partial : closingOpenInlineMarkers(partial));
    }

    // A lone "| a | b |" line is a table header only if a "|---|" row follows it.
    final partialIsEmpty = heldPartial || partial.isEmpty;
    if (!insideFence &&
        partialIsEmpty &&
        lines.isNotEmpty &&
        _isTableRow(lines.last)) {
      final previous = lines.length >= 2 ? lines[lines.length - 2] : null;
      final isInTable = previous != null && _isTableRow(previous);
      if (!isInTable) {
        final drop = heldPartial ? 1 : 2;
        shown.removeRange(
            shown.length - (drop < shown.length ? drop : shown.length),
            shown.length);
      }
    }
    return shown.join('\n');
  }

  static bool _isInsideFence(List<String> lines) {
    (String, int)? open;
    for (final line in lines) {
      if (open != null) {
        if (_closesFence(line, open.$1, open.$2)) open = null;
      } else {
        final fence = _fenceOpening(line);
        if (fence != null) open = (fence.char, fence.length);
      }
    }
    return open != null;
  }

  static bool _isAmbiguous(String partial, {required bool insideFence}) {
    final trimmed = _unindented(partial);
    if (trimmed.isEmpty) return false;
    final first = trimmed[0];
    if (first == '`' || first == '~') {
      // A fence (or its closing line) until the line ends, so the language label doesn't
      // flicker.
      final run = _run(trimmed, first);
      return run == trimmed.length || run >= 3;
    }
    if (insideFence) return false;
    if (RegExp(r'^#+$').hasMatch(trimmed)) return true;
    if (RegExp(r'^[-*_+ ]+$').hasMatch(trimmed)) return true;
    if (trimmed == '>') return true;
    if (first == '|') return true;
    var digits = 0;
    while (digits < trimmed.length && _isDigit(trimmed[digits])) {
      digits++;
    }
    if (digits > 0 && digits <= 9) {
      final rest = trimmed.substring(digits);
      return rest.isEmpty || rest == '.' || rest == ')';
    }
    return false;
  }

  /// Closes bold, italic, strikethrough and code spans left open at the end of a streamed line,
  /// and shows an unfinished link as its text. A marker with nothing after it yet is hidden.
  static String closingOpenInlineMarkers(String line) {
    final prefixLength = _blockPrefixLength(line);
    final prefix = line.substring(0, prefixLength);
    var body = _hidingUnfinishedLink(line.substring(prefixLength));
    final open = _openMarkers(body);
    for (final marker in open.reversed) {
      final end = marker.offset + marker.token.length;
      final after = end < body.length ? body.substring(end) : '';
      if (after.trim().isEmpty) {
        body = body.substring(0, marker.offset);
      } else {
        body = body.trimRight() + marker.token;
      }
    }
    return prefix + body;
  }

  static List<({String token, int offset})> _openMarkers(String text) {
    final stack = <({String token, int offset})>[];
    var index = 0;
    var codeTicks = 0;
    while (index < text.length) {
      final c = text[index];
      if (c == r'\') {
        index += 2;
        continue;
      }
      if (c == '`') {
        final run = _run(text, '`', index);
        if (codeTicks == 0) {
          codeTicks = run;
          stack.add((token: '`' * run, offset: index));
        } else if (run == codeTicks) {
          codeTicks = 0;
          stack.removeLast();
        }
        index += run;
        continue;
      }
      if (codeTicks > 0) {
        index++;
        continue;
      }
      final token = _emphasisToken(text, index);
      if (token != null) {
        if (stack.isNotEmpty && stack.last.token == token) {
          stack.removeLast();
        } else {
          stack.add((token: token, offset: index));
        }
        index += token.length;
        continue;
      }
      index++;
    }
    return stack;
  }

  static String? _emphasisToken(String text, int index) {
    final c = text[index];
    if (c == '*') return _run(text, '*', index) >= 2 ? '**' : '*';
    if (c == '~' && index + 1 < text.length && text[index + 1] == '~') {
      return '~~';
    }
    return null;
  }

  static int _blockPrefixLength(String line) {
    var index = 0;
    while (index < line.length && line[index] == ' ') {
      index++;
    }
    if (index >= line.length) return index;
    final first = line[index];
    if (first == '>' || first == '#') {
      while (index < line.length && line[index] == first) {
        index++;
      }
      while (index < line.length && line[index] == ' ') {
        index++;
      }
      return index;
    }
    if ('-*+'.contains(first) &&
        index + 1 < line.length &&
        line[index + 1] == ' ') {
      return index + 2;
    }
    var digitsEnd = index;
    while (digitsEnd < line.length && _isDigit(line[digitsEnd])) {
      digitsEnd++;
    }
    final hasDelimiter = digitsEnd > index &&
        digitsEnd + 1 < line.length &&
        (line[digitsEnd] == '.' || line[digitsEnd] == ')') &&
        line[digitsEnd + 1] == ' ';
    return hasDelimiter ? digitsEnd + 2 : index;
  }

  /// `"see [the docs](https://exa"` → `"see the docs"`, `"see [the do"` → `"see the do"`.
  static String _hidingUnfinishedLink(String text) {
    final open = text.lastIndexOf('[');
    if (open < 0) return text;
    final tail = text.substring(open + 1);
    final before = text.substring(0, open);
    final prefix =
        before.endsWith('!') ? before.substring(0, before.length - 1) : before;
    final close = tail.indexOf(']');
    if (close < 0) return prefix + tail;
    final label = tail.substring(0, close);
    final afterClose = tail.substring(close + 1);
    if (afterClose.isEmpty) return prefix + label;
    if (!afterClose.startsWith('(')) return text;
    if (afterClose.contains(')')) return text;
    return prefix + label;
  }
}
