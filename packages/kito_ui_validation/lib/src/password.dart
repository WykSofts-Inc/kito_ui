// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:characters/characters.dart';

/// A simple, explainable password strength score — enough to drive a strength meter. It isn't a
/// substitute for a breached-password check on your server.
///
/// One point each for: 8+ characters, 12+ characters, an uppercase letter, a digit and a
/// symbol, capped at [veryStrong]. Very common passwords always score [veryWeak].
enum KitoPasswordScore {
  /// 0 points.
  veryWeak,

  /// 1 point.
  weak,

  /// 2 points.
  medium,

  /// 3 points.
  strong,

  /// 4 or more points.
  veryStrong;

  /// "Very weak" … "Very strong".
  String get label => switch (this) {
        veryWeak => 'Very weak',
        weak => 'Weak',
        medium => 'Medium',
        strong => 'Strong',
        veryStrong => 'Very strong',
      };

  /// 0.2 … 1.0, for a meter.
  double get fraction => (index + 1) / 5;

  /// At least as strong as [other].
  bool operator >=(KitoPasswordScore other) => index >= other.index;

  /// Stronger than [other].
  bool operator >(KitoPasswordScore other) => index > other.index;

  /// At most as strong as [other].
  bool operator <=(KitoPasswordScore other) => index <= other.index;

  /// Weaker than [other].
  bool operator <(KitoPasswordScore other) => index < other.index;

  /// Scores [password].
  static KitoPasswordScore evaluate(String password) {
    if (password.isEmpty || _common.contains(password.toLowerCase())) {
      return veryWeak;
    }
    final length = password.characters.length;
    var score = 0;
    if (length >= 8) score++;
    if (length >= 12) score++;
    if (_upper.hasMatch(password)) score++;
    if (_digit.hasMatch(password)) score++;
    if (_symbol.hasMatch(password)) score++;
    return values[score.clamp(0, 4)];
  }

  /// What would make [password] stronger, most useful first. Empty once nothing is missing.
  static List<String> suggestions(String password) {
    final length = password.characters.length;
    return [
      if (_common.contains(password.toLowerCase()) && password.isNotEmpty)
        'Avoid common passwords',
      if (length < 8)
        'Use at least 8 characters'
      else if (length < 12)
        'Longer is stronger: try 12 or more',
      if (!_upper.hasMatch(password)) 'Add an uppercase letter',
      if (!_digit.hasMatch(password)) 'Add a number',
      if (!_symbol.hasMatch(password)) 'Add a symbol like ! or #',
    ];
  }

  static final _upper = RegExp(r'\p{Lu}', unicode: true);
  static final _digit = RegExp(r'\p{Nd}', unicode: true);
  static final _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static const _common = {
    'password',
    'password1',
    'password123',
    '123456',
    '12345678',
    '123456789',
    '1234567890',
    'qwerty',
    'qwerty123',
    'abc123',
    '111111',
    'letmein',
    'iloveyou',
    'admin',
    'welcome',
    'monkey',
    'football',
    'p@ssw0rd',
    'passw0rd',
  };
}
