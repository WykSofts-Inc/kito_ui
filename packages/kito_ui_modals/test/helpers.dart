// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A themed app around [child], optionally RTL or with reduced motion.
Widget testApp(Widget child,
    {TextDirection direction = TextDirection.ltr, bool reduceMotion = false}) {
  return MaterialApp(
    theme: KitoTheme.light.toThemeData(),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Directionality(textDirection: direction, child: app!),
    ),
    home: Scaffold(body: child),
  );
}

/// Pumps an app with a button that runs [onPressed] with a context under the navigator.
Future<void> pumpLauncher(
  WidgetTester tester,
  void Function(BuildContext context) onPressed, {
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(testApp(
    Builder(
      builder: (context) => Center(
        child: TextButton(
            onPressed: () => onPressed(context), child: const Text('Open')),
      ),
    ),
    direction: direction,
    reduceMotion: reduceMotion,
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
