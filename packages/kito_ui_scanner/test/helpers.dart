// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A themed app around [child], optionally RTL or with reduced motion.
Widget testApp(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: KitoTheme.light.toThemeData(),
    builder:
        (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: Directionality(textDirection: direction, child: app!),
        ),
    home: child,
  );
}
