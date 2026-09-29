// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in an app with optional RTL, Reduce Motion, text scale and locale.
Widget host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  double textScale = 1,
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
          textScaler: TextScaler.linear(textScale),
        ),
        child: body,
      );
    }),
  );
}

/// Records every haptic the widget under test asks for.
List<String> recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      calls.add(call.arguments as String? ?? 'vibrate');
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}
