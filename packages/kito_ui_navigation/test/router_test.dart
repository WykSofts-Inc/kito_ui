// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_navigation/kito_ui_navigation.dart';

import 'helpers.dart';

enum _Route { details, cart, checkout, signIn }

Widget _view(KitoRouter<_Route> router) => testApp(KitoRouterView<_Route>(
      router: router,
      root: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () =>
                KitoRouter.of<_Route>(context).push(_Route.details),
            child: const Text('Home'),
          ),
        ),
      ),
      destination: (context, route) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Page ${route.name}')),
      ),
    ));

void main() {
  group('KitoRouter', () {
    test('push, pop and pop to root', () {
      final r = KitoRouter<_Route>();
      expect(r.canPop, isFalse);
      r
        ..push(_Route.details)
        ..push(_Route.cart);
      expect(r.path, [_Route.details, _Route.cart]);
      expect(r.top, _Route.cart);
      r.pop();
      expect(r.path, [_Route.details]);
      r.popToRoot();
      expect(r.path, isEmpty);
      r.pop();
      expect(r.path, isEmpty, reason: 'popping the root does nothing');
    });

    test('popTo keeps the route and drops what is above it', () {
      final r = KitoRouter<_Route>(
          initialPath: [_Route.details, _Route.cart, _Route.checkout]);
      r.popTo(_Route.cart);
      expect(r.path, [_Route.details, _Route.cart]);
      r.popTo(_Route.signIn);
      expect(r.path, [_Route.details, _Route.cart], reason: 'not in the stack');
    });

    test('replaceStack and the full-screen cover', () {
      var n = 0;
      final r = KitoRouter<_Route>()..addListener(() => n++);
      r.replaceStack([_Route.cart, _Route.checkout]);
      expect(r.path, [_Route.cart, _Route.checkout]);
      r.presentFullScreen(_Route.signIn);
      r.presentFullScreen(_Route.signIn);
      expect(r.fullScreenCover, _Route.signIn);
      r.dismissFullScreen();
      expect(r.fullScreenCover, isNull);
      expect(n, 3);
    });

    test('the path is read-only from outside', () {
      final r = KitoRouter<_Route>(initialPath: [_Route.cart]);
      expect(() => r.path.add(_Route.details), throwsUnsupportedError);
    });
  });

  group('KitoRouterView', () {
    testWidgets('pages follow the router, and back keeps it in step',
        (tester) async {
      final r = KitoRouter<_Route>();
      await tester.pumpWidget(_view(r));
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Page details'), findsOneWidget);
      expect(r.path, [_Route.details]);

      r.push(_Route.cart);
      await tester.pumpAndSettle();
      expect(find.text('Page cart'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Page details'), findsOneWidget);
      expect(r.path, [_Route.details]);

      r.popToRoot();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('replacing the stack is not undone by the old pages leaving',
        (tester) async {
      final r = KitoRouter<_Route>(initialPath: [_Route.details, _Route.cart]);
      await tester.pumpWidget(_view(r));
      await tester.pumpAndSettle();
      r.replaceStack([_Route.checkout]);
      await tester.pumpAndSettle();
      expect(r.path, [_Route.checkout]);
      expect(find.text('Page checkout'), findsOneWidget);
    });

    testWidgets('the cover shows over the stack and closes with back',
        (tester) async {
      final r = KitoRouter<_Route>(initialPath: [_Route.details]);
      await tester.pumpWidget(_view(r));
      await tester.pumpAndSettle();
      r.presentFullScreen(_Route.signIn);
      await tester.pumpAndSettle();
      expect(find.text('Page signIn'), findsOneWidget);
      expect(find.byType(CloseButton), findsOneWidget,
          reason: 'shown as a full-screen dialog');
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(r.fullScreenCover, isNull);
      expect(r.path, [_Route.details]);
      expect(find.text('Page details'), findsOneWidget);
    });
  });
}
