// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';

/// Wraps [child] in an app with optional RTL, Reduce Motion, dark theme and locale.
Widget host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
  Locale? locale,
  bool center = true,
}) {
  return MaterialApp(
    home: Builder(builder: (context) {
      Widget body = Directionality(
        textDirection: direction,
        child: Scaffold(body: center ? Center(child: child) : child),
      );
      if (locale != null) {
        body = Localizations.override(
            context: context,
            locale: locale,
            delegates: const [_AnyMaterial(), _AnyWidgets()],
            child: body);
      }
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          platformBrightness: brightness,
        ),
        child: body,
      );
    }),
  );
}

class _AnyMaterial extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyMaterial();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(const Locale('en'));
  @override
  bool shouldReload(_AnyMaterial old) => false;
}

class _AnyWidgets extends LocalizationsDelegate<WidgetsLocalizations> {
  const _AnyWidgets();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(const Locale('en'));
  @override
  bool shouldReload(_AnyWidgets old) => false;
}
