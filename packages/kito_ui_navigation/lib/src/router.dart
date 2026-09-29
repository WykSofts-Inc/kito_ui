// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';

/// A typed router for one navigation stack: push, pop, pop to a route, replace the stack,
/// and a full-screen cover slot for sign-in gates and onboarding. Pair it with
/// [KitoRouterView], which turns the stack into pages. Routes are your own type — usually an
/// enum or a sealed class with value equality.
///
/// ```dart
/// final router = KitoRouter<AppRoute>();
/// router.push(const ProductRoute('42'));
/// router.popTo(const CartRoute());
/// router.presentFullScreen(const SignInRoute());
/// ```
class KitoRouter<R extends Object> extends ChangeNotifier {
  /// Creates a router, optionally with a starting stack.
  KitoRouter({List<R> initialPath = const []}) : _path = List.of(initialPath);

  List<R> _path;
  R? _cover;

  /// The pushed routes above the root, bottom first.
  List<R> get path => List.unmodifiable(_path);

  /// The route shown as a full-screen cover, if any.
  R? get fullScreenCover => _cover;

  /// The top route, or null at the root.
  R? get top => _path.isEmpty ? null : _path.last;

  /// True when there's something to pop.
  bool get canPop => _path.isNotEmpty;

  /// Pushes [route].
  void push(R route) {
    _path.add(route);
    notifyListeners();
  }

  /// Pops the top route; nothing at the root.
  void pop() {
    if (_path.isEmpty) return;
    _path.removeLast();
    notifyListeners();
  }

  /// Back to the root.
  void popToRoot() {
    if (_path.isEmpty) return;
    _path.clear();
    notifyListeners();
  }

  /// Pops back to the first occurrence of [route], keeping it. Nothing happens when it isn't
  /// in the stack.
  void popTo(R route) {
    final index = _path.indexOf(route);
    if (index < 0 || index == _path.length - 1) return;
    _path = _path.sublist(0, index + 1);
    notifyListeners();
  }

  /// Replaces the whole stack, e.g. for a deep link.
  void replaceStack(List<R> routes) {
    _path = List.of(routes);
    notifyListeners();
  }

  /// Shows [route] as a full-screen cover above the stack.
  void presentFullScreen(R route) {
    if (_cover == route) return;
    _cover = route;
    notifyListeners();
  }

  /// Closes the full-screen cover.
  void dismissFullScreen() {
    if (_cover == null) return;
    _cover = null;
    notifyListeners();
  }

  /// Drops the page at [index] (and anything above it) when the user pops it with a back
  /// gesture, unless the stack has already moved on.
  void _didRemove(int index, R route) {
    if (index < _path.length && _path[index] == route) {
      _path = _path.sublist(0, index);
      notifyListeners();
    }
  }

  /// The router of the nearest [KitoRouterView] for route type [R].
  static KitoRouter<R> of<R extends Object>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_KitoRouterScope<R>>();
    assert(scope != null, 'No KitoRouterView<$R> above this context.');
    return scope!.notifier!;
  }

  /// Like [of], or null outside a matching [KitoRouterView].
  static KitoRouter<R>? maybeOf<R extends Object>(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_KitoRouterScope<R>>()
          ?.notifier;
}

class _KitoRouterScope<R extends Object>
    extends InheritedNotifier<KitoRouter<R>> {
  const _KitoRouterScope({required KitoRouter<R> router, required super.child})
      : super(notifier: router);
}

@immutable
class _CoverKey {
  const _CoverKey(this.route);
  final Object route;

  @override
  bool operator ==(Object other) => other is _CoverKey && other.route == route;

  @override
  int get hashCode => Object.hash(_CoverKey, route);
}

/// A `Navigator` driven by a [KitoRouter]: the root, then a page per pushed route, then the
/// full-screen cover when there is one. Back gestures and the back button keep the router in
/// step. Descendants reach the router with `KitoRouter.of<R>(context)`.
///
/// ```dart
/// KitoRouterView<AppRoute>(
///   router: router,
///   root: (context) => const HomeScreen(),
///   destination: (context, route) => switch (route) {
///     ProductRoute(:final id) => ProductScreen(id: id),
///     CartRoute() => const CartScreen(),
///     SignInRoute() => const SignInScreen(),
///   },
/// )
/// ```
class KitoRouterView<R extends Object> extends StatelessWidget {
  /// Creates the view.
  const KitoRouterView({
    super.key,
    required this.router,
    required this.root,
    required this.destination,
  });

  /// The stack to show.
  final KitoRouter<R> router;

  /// The bottom screen.
  final WidgetBuilder root;

  /// Builds the screen for a route.
  final Widget Function(BuildContext context, R route) destination;

  @override
  Widget build(BuildContext context) {
    return _KitoRouterScope<R>(
      router: router,
      child: ListenableBuilder(
        listenable: router,
        builder: (context, _) {
          final path = router._path;
          final cover = router._cover;
          return Navigator(
            pages: [
              MaterialPage<void>(
                  key: const ValueKey('kito-router-root'),
                  child: Builder(builder: root)),
              for (var i = 0; i < path.length; i++)
                MaterialPage<void>(
                  key: ValueKey((i, path[i])),
                  arguments: path[i],
                  child: Builder(
                      builder: (context) => destination(context, path[i])),
                ),
              if (cover != null)
                MaterialPage<void>(
                  key: ValueKey(_CoverKey(cover)),
                  fullscreenDialog: true,
                  child: Builder(
                      builder: (context) => destination(context, cover)),
                ),
            ],
            onDidRemovePage: (page) {
              final key = page.key;
              if (key is ValueKey<Object> && key.value is _CoverKey) {
                if ((key.value as _CoverKey).route == router._cover) {
                  router.dismissFullScreen();
                }
              } else if (key is ValueKey<Object> && key.value is (int, R)) {
                final (index, route) = key.value as (int, R);
                router._didRemove(index, route);
              }
            },
          );
        },
      ),
    );
  }
}
