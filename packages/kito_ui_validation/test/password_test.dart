// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

void main() {
  test('scores one point per requirement', () {
    expect(KitoPasswordScore.evaluate(''), KitoPasswordScore.veryWeak);
    expect(KitoPasswordScore.evaluate('abc'), KitoPasswordScore.veryWeak);
    expect(KitoPasswordScore.evaluate('abcdefgh'), KitoPasswordScore.weak);
    expect(KitoPasswordScore.evaluate('Abcdefgh'), KitoPasswordScore.medium);
    expect(KitoPasswordScore.evaluate('Abcdefg1'), KitoPasswordScore.strong);
    expect(
        KitoPasswordScore.evaluate('Abcdefg1!'), KitoPasswordScore.veryStrong);
    expect(KitoPasswordScore.evaluate('Abcdefghijk1!'),
        KitoPasswordScore.veryStrong);
  });

  test('common passwords are always very weak', () {
    expect(KitoPasswordScore.evaluate('P@ssw0rd'), KitoPasswordScore.veryWeak);
    expect(KitoPasswordScore.suggestions('password').first,
        'Avoid common passwords');
  });

  test('labels, fractions and comparisons', () {
    expect(KitoPasswordScore.medium.label, 'Medium');
    expect(KitoPasswordScore.veryWeak.fraction, closeTo(0.2, 1e-9));
    expect(KitoPasswordScore.veryStrong.fraction, 1);
    expect(KitoPasswordScore.strong > KitoPasswordScore.medium, isTrue);
    expect(KitoPasswordScore.strong >= KitoPasswordScore.strong, isTrue);
    expect(KitoPasswordScore.weak < KitoPasswordScore.medium, isTrue);
    expect(KitoPasswordScore.weak <= KitoPasswordScore.veryWeak, isFalse);
    expect(KitoPasswordScore.values.map((s) => s.label).toSet(), hasLength(5));
  });

  test('suggestions list what is missing, most useful first', () {
    expect(KitoPasswordScore.suggestions('abc'), [
      'Use at least 8 characters',
      'Add an uppercase letter',
      'Add a number',
      'Add a symbol like ! or #',
    ]);
    expect(KitoPasswordScore.suggestions('Abcdefgh1!'),
        ['Longer is stronger: try 12 or more']);
    expect(KitoPasswordScore.suggestions('Abcdefghijk1!'), isEmpty);
  });
}
