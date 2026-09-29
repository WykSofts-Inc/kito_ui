// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// The app's look.
enum ThemeChoice {
  system('System'),
  light('Light'),
  dark('Dark'),
  neon('Neon');

  const ThemeChoice(this.label);

  final String label;
}

/// Which way the app reads.
enum DirectionChoice {
  system('System'),
  leftToRight('Left to right'),
  rightToLeft('Right to left');

  const DirectionChoice(this.label);

  final String label;
}

/// App-wide settings: theme, layout direction and recently opened kits.
class AppSettings extends ChangeNotifier {
  ThemeChoice _theme = ThemeChoice.neon;
  DirectionChoice _direction = DirectionChoice.system;
  final List<String> _recent = [];

  ThemeChoice get theme => _theme;
  set theme(ThemeChoice value) {
    if (_theme == value) return;
    _theme = value;
    notifyListeners();
  }

  DirectionChoice get direction => _direction;
  set direction(DirectionChoice value) {
    if (_direction == value) return;
    _direction = value;
    notifyListeners();
  }

  /// Titles of the last kits opened, newest first.
  List<String> get recent => List.unmodifiable(_recent);

  void remember(String kitTitle) {
    _recent
      ..remove(kitTitle)
      ..insert(0, kitTitle);
    if (_recent.length > 6) _recent.removeLast();
    notifyListeners();
  }

  /// The Kito theme for light and dark system appearance.
  KitoTheme lightTheme() => switch (_theme) {
        ThemeChoice.dark => KitoTheme.dark,
        ThemeChoice.neon => KitoTheme.neon,
        _ => KitoTheme.light,
      };

  KitoTheme darkTheme() => switch (_theme) {
        ThemeChoice.light => KitoTheme.light,
        ThemeChoice.neon => KitoTheme.neon,
        _ => KitoTheme.dark,
      };

  ThemeMode get themeMode =>
      _theme == ThemeChoice.system ? ThemeMode.system : ThemeMode.light;

  /// Wraps [child] in the chosen direction, or leaves the locale's direction alone.
  Widget applyDirection(Widget child) => switch (_direction) {
        DirectionChoice.system => child,
        DirectionChoice.leftToRight =>
          Directionality(textDirection: TextDirection.ltr, child: child),
        DirectionChoice.rightToLeft =>
          Directionality(textDirection: TextDirection.rtl, child: child),
      };
}

/// Makes [AppSettings] available below it.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope(
      {super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()!.notifier!;
}
