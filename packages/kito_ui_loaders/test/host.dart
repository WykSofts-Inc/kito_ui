// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';

/// Wraps [child] in an app with optional RTL, Reduce Motion, dark theme and locale.
Widget host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
  Locale? locale,
}) {
  return MaterialApp(
    home: Builder(builder: (context) {
      Widget body = Directionality(
        textDirection: direction,
        child: Scaffold(body: Center(child: child)),
      );
      if (locale != null) {
        body = Localizations.override(
            context: context, locale: locale, child: body);
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
