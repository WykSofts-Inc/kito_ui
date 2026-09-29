// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'view.dart';

/// Switches between loading, error, empty and content for an [AsyncSnapshot] — the usual
/// `FutureBuilder` / `StreamBuilder` dance, with Kito empty states and a cross-fade.
///
/// ```dart
/// FutureBuilder(
///   future: orders,
///   builder: (context, snapshot) => KitoEmptyStateSnapshotView(
///     snapshot: snapshot,
///     isEmpty: (orders) => orders.isEmpty,
///     empty: KitoEmptyStateView.noData(title: 'No orders yet'),
///     onRetry: reload,
///     builder: (context, orders) => OrderList(orders),
///   ),
/// )
/// ```
class KitoEmptyStateSnapshotView<T> extends StatelessWidget {
  /// Creates a switcher for [snapshot].
  const KitoEmptyStateSnapshotView({
    super.key,
    required this.snapshot,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.error,
    this.onRetry,
  });

  /// The future or stream's state.
  final AsyncSnapshot<T> snapshot;

  /// Builds the content once there's data.
  final Widget Function(BuildContext context, T data) builder;

  /// True when the data counts as empty (an empty list, say).
  final bool Function(T data)? isEmpty;

  /// Shown when [isEmpty] says so; a "Nothing here yet" state by default.
  final Widget? empty;

  /// Shown while waiting; a small spinner by default.
  final Widget? loading;

  /// Builds the error state; an error empty state with a retry button by default.
  final Widget Function(BuildContext context, Object error)? error;

  /// Offered as "Try again" on the default error state.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final Widget child;
    final String key;
    if (snapshot.hasError) {
      key = 'error';
      child = error?.call(context, snapshot.error!) ??
          KitoEmptyStateView.error(
              message: snapshot.error.toString(), onRetry: onRetry);
    } else if (snapshot.hasData) {
      final data = snapshot.data as T;
      if (isEmpty?.call(data) ?? false) {
        key = 'empty';
        child = empty ?? KitoEmptyStateView.noData();
      } else {
        key = 'data';
        child = builder(context, data);
      }
    } else if (snapshot.connectionState == ConnectionState.done) {
      key = 'empty';
      child = empty ?? KitoEmptyStateView.noData();
    } else {
      key = 'loading';
      child = loading ??
          Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.6, color: theme.colors.primary),
            ),
          );
    }
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, theme.motion.medium),
      switchInCurve: theme.motion.standard,
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}
