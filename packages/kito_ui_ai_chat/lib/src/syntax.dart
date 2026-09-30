// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/foundation.dart';

/// What a piece of code is, for colouring.
enum KitoAiSyntaxKind {
  /// Everything else.
  plain,

  /// `final`, `if`, `return`…
  keyword,

  /// Quoted text.
  string,

  /// Comments.
  comment,

  /// Numeric literals.
  number,

  /// Capitalised names.
  type,

  /// A name followed by `(`.
  function,
}

/// A run of code of one kind.
@immutable
class KitoAiSyntaxToken {
  /// Creates a token.
  const KitoAiSyntaxToken(this.text, this.kind);

  /// The source text.
  final String text;

  /// How to colour it.
  final KitoAiSyntaxKind kind;

  @override
  bool operator ==(Object other) =>
      other is KitoAiSyntaxToken && other.text == text && other.kind == kind;

  @override
  int get hashCode => Object.hash(text, kind);

  @override
  String toString() => '${kind.name}("$text")';
}

enum _Family { cLike, hash, sql, json, markup }

/// A small, forgiving highlighter for the languages models write most: Dart, Swift, Kotlin,
/// JavaScript and TypeScript, Python, Go, Rust, Java, C-family, JSON, shell, SQL and YAML. It
/// never fails — unknown languages get strings, numbers and comments — and the tokens always
/// join back into the original code.
///
/// ```dart
/// KitoAiSyntaxHighlighter.tokens('final x = 42;', language: 'dart');
/// ```
abstract final class KitoAiSyntaxHighlighter {
  /// The tokens of [code].
  static List<KitoAiSyntaxToken> tokens(String code, {String? language}) =>
      _Scanner(code, _family(language)).run();

  static _Family _family(String? language) {
    switch (language?.toLowerCase() ?? '') {
      case 'python' ||
            'py' ||
            'ruby' ||
            'rb' ||
            'bash' ||
            'sh' ||
            'shell' ||
            'zsh' ||
            'console' ||
            'yaml' ||
            'yml' ||
            'toml' ||
            'r' ||
            'perl' ||
            'dockerfile' ||
            'makefile' ||
            'elixir':
        return _Family.hash;
      case 'sql' || 'postgres' || 'postgresql' || 'mysql' || 'sqlite':
        return _Family.sql;
      case 'json' || 'jsonc':
        return _Family.json;
      case 'html' ||
            'xml' ||
            'svg' ||
            'markdown' ||
            'md' ||
            'text' ||
            'txt' ||
            'plaintext':
        return _Family.markup;
      default:
        return _Family.cLike;
    }
  }

  static const _keywords = {
    // Dart, Swift, Kotlin, Java, C-family
    'abstract', 'actor', 'as', 'assert', 'async', 'await', 'base', 'break',
    'case', 'catch', 'class', 'const', 'continue', 'covariant', 'default',
    'defer', 'deferred', 'do', 'dynamic', 'else', 'enum', 'export', 'extends',
    'extension', 'external', 'factory', 'false', 'final', 'finally', 'for',
    'func', 'get', 'guard', 'hide', 'if', 'implements', 'import', 'in', 'init',
    'interface', 'is', 'late', 'let', 'library', 'mixin', 'new', 'nil', 'null',
    'on', 'operator', 'override', 'part', 'private', 'protocol', 'public',
    'required', 'rethrow', 'return', 'sealed', 'set', 'show', 'static',
    'struct', 'super', 'switch', 'sync', 'this', 'throw', 'throws', 'true',
    'try', 'typedef', 'var', 'void', 'when', 'where', 'while', 'with', 'yield',
    'fun', 'val', 'object', 'data', 'companion', 'self', 'Self', 'some', 'any',
    'int', 'double', 'bool', 'num', 'char', 'float', 'long', 'boolean',
    // JavaScript / TypeScript
    'function', 'from', 'of', 'typeof', 'instanceof', 'undefined', 'delete',
    'type', 'readonly', 'keyof', 'declare', 'namespace', 'constructor',
    // Python
    'def', 'elif', 'except', 'lambda', 'not', 'and', 'or', 'pass', 'raise',
    'None', 'True', 'False', 'global', 'nonlocal', 'del',
    // Go / Rust
    'go', 'chan', 'select', 'map', 'range', 'fn', 'impl', 'mod', 'pub', 'use',
    'crate', 'trait', 'match', 'loop', 'mut', 'ref', 'move', 'unsafe', 'dyn',
    // Shell
    'then', 'fi', 'esac', 'done', 'echo', 'local', 'source',
  };

  static const _sqlKeywords = {
    'select',
    'from',
    'where',
    'and',
    'or',
    'not',
    'insert',
    'into',
    'values',
    'update',
    'set',
    'delete',
    'create',
    'table',
    'index',
    'on',
    'join',
    'left',
    'right',
    'inner',
    'outer',
    'group',
    'by',
    'order',
    'limit',
    'as',
    'having',
    'distinct',
    'null',
    'is',
    'in',
    'primary',
    'key',
    'foreign',
    'references',
    'default',
    'count',
    'sum',
  };
}

bool _isLetter(int c) =>
    (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || c > 0x7F;

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

class _Scanner {
  _Scanner(this.code, this.family);

  final String code;
  final _Family family;
  var index = 0;
  final tokens = <KitoAiSyntaxToken>[];

  List<KitoAiSyntaxToken> run() {
    if (family == _Family.markup) {
      return code.isEmpty
          ? const []
          : [KitoAiSyntaxToken(code, KitoAiSyntaxKind.plain)];
    }
    while (index < code.length) {
      if (scanComment() || scanString() || scanNumber() || scanWord()) continue;
      emit(code[index], KitoAiSyntaxKind.plain);
      index++;
    }
    return tokens;
  }

  String? peek([int offset = 0]) {
    final p = index + offset;
    return p < code.length ? code[p] : null;
  }

  void emit(String text, KitoAiSyntaxKind kind) {
    if (text.isEmpty) return;
    if (tokens.isNotEmpty &&
        tokens.last.kind == kind &&
        kind == KitoAiSyntaxKind.plain) {
      final last = tokens.removeLast();
      tokens.add(KitoAiSyntaxToken(last.text + text, kind));
    } else {
      tokens.add(KitoAiSyntaxToken(text, kind));
    }
  }

  bool scanComment() {
    final current = peek();
    final next = peek(1);
    final line = switch (family) {
      _Family.cLike => current == '/' && next == '/',
      _Family.hash => current == '#',
      _Family.sql => current == '-' && next == '-',
      _ => false,
    };
    if (line) {
      final start = index;
      while (index < code.length && code[index] != '\n') {
        index++;
      }
      emit(code.substring(start, index), KitoAiSyntaxKind.comment);
      return true;
    }
    if ((family == _Family.cLike || family == _Family.sql) &&
        current == '/' &&
        next == '*') {
      final start = index;
      index += 2;
      while (index < code.length && !(code[index] == '*' && peek(1) == '/')) {
        index++;
      }
      index = (index + 2).clamp(0, code.length);
      emit(code.substring(start, index), KitoAiSyntaxKind.comment);
      return true;
    }
    return false;
  }

  bool scanString() {
    final quote = peek();
    if (quote == null ||
        !(quote == '"' ||
            quote == "'" ||
            (quote == '`' && family == _Family.cLike))) {
      return false;
    }
    final start = index;
    index++;
    while (index < code.length) {
      final c = code[index];
      if (c == r'\') {
        index += 2;
        continue;
      }
      index++;
      if (c == quote) break;
      if (c == '\n' && quote != '`') break;
    }
    index = index.clamp(0, code.length);
    emit(code.substring(start, index), KitoAiSyntaxKind.string);
    return true;
  }

  bool scanNumber() {
    if (index >= code.length || !_isDigit(code.codeUnitAt(index))) {
      return false;
    }
    if (tokens.isNotEmpty) {
      final last = tokens.last.text;
      final prev = last.codeUnitAt(last.length - 1);
      if (_isLetter(prev) || prev == 0x5F) return false;
    }
    final start = index;
    while (index < code.length &&
        RegExp(r'[0-9a-fA-F._xob]').hasMatch(code[index])) {
      index++;
    }
    emit(code.substring(start, index), KitoAiSyntaxKind.number);
    return true;
  }

  bool scanWord() {
    final c = code.codeUnitAt(index);
    if (!(_isLetter(c) || c == 0x5F || c == 0x40 || c == 0x24)) return false;
    final start = index;
    index++;
    while (index < code.length) {
      final u = code.codeUnitAt(index);
      if (_isLetter(u) || _isDigit(u) || u == 0x5F) {
        index++;
      } else {
        break;
      }
    }
    final word = code.substring(start, index);
    emit(word, kindOf(word));
    return true;
  }

  KitoAiSyntaxKind kindOf(String word) {
    switch (family) {
      case _Family.sql:
        return KitoAiSyntaxHighlighter._sqlKeywords.contains(word.toLowerCase())
            ? KitoAiSyntaxKind.keyword
            : KitoAiSyntaxKind.plain;
      case _Family.json:
        return const {'true', 'false', 'null'}.contains(word)
            ? KitoAiSyntaxKind.keyword
            : KitoAiSyntaxKind.plain;
      default:
        if (word.startsWith('@')) return KitoAiSyntaxKind.keyword;
        if (KitoAiSyntaxHighlighter._keywords.contains(word)) {
          return KitoAiSyntaxKind.keyword;
        }
        if (peek() == '(') return KitoAiSyntaxKind.function;
        final first = word.codeUnitAt(0);
        if (first >= 0x41 && first <= 0x5A) return KitoAiSyntaxKind.type;
        return KitoAiSyntaxKind.plain;
    }
  }
}
