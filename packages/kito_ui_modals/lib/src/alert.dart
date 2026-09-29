// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'confetti.dart';

/// What an alert action does, which sets its colour and where it sits.
enum KitoAlertRole {
  /// The main, filled action.
  primary,

  /// A quieter alternative.
  secondary,

  /// Deletes or discards something; drawn in the danger colour.
  destructive,

  /// Backs out. A tap outside the alert, or Escape, picks it.
  cancel,
}

/// One button on a Kito alert.
@immutable
class KitoAlertAction {
  /// Creates an action.
  const KitoAlertAction(this.title,
      {this.role = KitoAlertRole.primary, this.onPressed});

  /// A cancel action.
  const KitoAlertAction.cancel([this.title = 'Cancel', this.onPressed])
      : role = KitoAlertRole.cancel;

  /// The button text.
  final String title;

  /// Its role.
  final KitoAlertRole role;

  /// Called after the alert has closed.
  final VoidCallback? onPressed;
}

/// A custom alert: an icon that pops in on a tinted badge, a title, a message, and actions
/// that sit side by side when two short ones fit, stacked otherwise. [celebrates] adds a
/// confetti burst. Show it with [showKitoAlert].
@immutable
class KitoAlert {
  /// Creates an alert. With no actions it gets a single "OK".
  const KitoAlert({
    required this.title,
    this.message,
    this.icon,
    this.tint,
    List<KitoAlertAction> actions = const [],
    this.celebrates = false,
  }) : _actions = actions;

  /// The heading.
  final String title;

  /// Supporting text under the title.
  final String? message;

  /// The badge icon, if any.
  final IconData? icon;

  /// The badge colour; the theme's primary when null, or danger when an action is
  /// destructive.
  final Color? tint;

  final List<KitoAlertAction> _actions;

  /// The buttons; never empty.
  List<KitoAlertAction> get actions =>
      _actions.isEmpty ? const [KitoAlertAction('OK')] : _actions;

  /// Bursts confetti while it's showing (not with reduce motion).
  final bool celebrates;

  /// True when any action is destructive.
  bool get isDestructive =>
      actions.any((a) => a.role == KitoAlertRole.destructive);

  /// The cancel action, if there is one.
  KitoAlertAction? get cancelAction {
    for (final a in actions) {
      if (a.role == KitoAlertRole.cancel) return a;
    }
    return null;
  }

  /// Two actions whose titles are 12 characters or fewer sit side by side.
  static bool laysOutHorizontally(List<KitoAlertAction> actions) =>
      actions.length == 2 &&
      actions.every((a) => a.title.characters.length <= 12);

  /// The order buttons appear in: cancel first when side by side, last when stacked — the
  /// platform convention.
  static List<KitoAlertAction> orderedActions(List<KitoAlertAction> actions) {
    final cancels = actions.where((a) => a.role == KitoAlertRole.cancel);
    final others = actions.where((a) => a.role != KitoAlertRole.cancel);
    return laysOutHorizontally(actions)
        ? [...cancels, ...others]
        : [...others, ...cancels];
  }
}

/// Shows [alert] and completes with the action picked (after running its `onPressed`).
///
/// A tap outside, Escape or the accessibility dismiss gesture picks the cancel action when
/// there is one; without a cancel action the alert only closes through its buttons.
///
/// ```dart
/// await showKitoAlert(context, KitoAlert(
///   icon: Icons.delete_rounded,
///   title: 'Delete account?',
///   message: "This can't be undone.",
///   actions: [
///     const KitoAlertAction.cancel(),
///     KitoAlertAction('Delete', role: KitoAlertRole.destructive, onPressed: deleteAccount),
///   ],
/// ));
/// ```
Future<KitoAlertAction?> showKitoAlert(BuildContext context, KitoAlert alert,
    {bool useRootNavigator = true}) async {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final reduce = KitoMotion.reduced(context);
  final picked = await navigator.push<KitoAlertAction>(_KitoAlertRoute(
    alert: alert,
    reduceMotion: reduce,
    barrierLabel: alert.cancelAction?.title ?? 'Alert',
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
  ));
  final chosen = picked ?? alert.cancelAction;
  chosen?.onPressed?.call();
  return chosen;
}

/// Asks to confirm something, with a cancel and a confirm button. Completes with true when
/// confirmed.
///
/// ```dart
/// if (await showKitoConfirmation(context,
///     title: 'Delete card?', message: "This can't be undone.",
///     confirmTitle: 'Delete', isDestructive: true)) {
///   deleteCard();
/// }
/// ```
Future<bool> showKitoConfirmation(
  BuildContext context, {
  required String title,
  String? message,
  String confirmTitle = 'Confirm',
  String cancelTitle = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) async {
  final confirm = KitoAlertAction(confirmTitle,
      role: isDestructive ? KitoAlertRole.destructive : KitoAlertRole.primary);
  final picked = await showKitoAlert(
    context,
    KitoAlert(
      title: title,
      message: message,
      icon: icon,
      actions: [KitoAlertAction.cancel(cancelTitle), confirm],
    ),
  );
  return identical(picked, confirm);
}

class _KitoAlertRoute extends PopupRoute<KitoAlertAction> {
  _KitoAlertRoute({
    required this.alert,
    required this.reduceMotion,
    required this.barrierLabel,
    this.capturedThemes,
  });

  final KitoAlert alert;
  final bool reduceMotion;
  final CapturedThemes? capturedThemes;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.45);

  @override
  bool get barrierDismissible => alert.cancelAction != null;

  @override
  Duration get transitionDuration => reduceMotion
      ? const Duration(milliseconds: 180)
      : const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final page = _KitoAlertPage(alert: alert, route: this);
    return capturedThemes?.wrap(page) ?? page;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    if (reduceMotion || context.reduceMotion) {
      return FadeTransition(opacity: fade, child: child);
    }
    final scale = Tween<double>(begin: 0.86, end: 1).animate(CurvedAnimation(
      parent: animation,
      curve: const KitoSpringCurve(damping: 0.7),
      reverseCurve: Curves.easeIn,
    ));
    return FadeTransition(
        opacity: fade, child: ScaleTransition(scale: scale, child: child));
  }
}

class _KitoAlertPage extends StatelessWidget {
  const _KitoAlertPage({required this.alert, required this.route});

  final KitoAlert alert;
  final _KitoAlertRoute route;

  void _pick(BuildContext context, KitoAlertAction? action) {
    if (route.isCurrent) Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final cancel = alert.cancelAction;
    return Stack(children: [
      if (alert.celebrates) const Positioned.fill(child: KitoModalConfetti()),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: KitoAlertCard(
            alert: alert,
            onAction: (action) => _pick(context, action),
            onDismiss: cancel == null ? null : () => _pick(context, cancel),
          ),
        ),
      ),
    ]);
  }
}

/// The card a [KitoAlert] is drawn on, for placing an alert in your own layout (a preview,
/// an inline confirmation). [showKitoAlert] uses it.
class KitoAlertCard extends StatefulWidget {
  /// Creates the card.
  const KitoAlertCard(
      {super.key, required this.alert, required this.onAction, this.onDismiss});

  /// What to show.
  final KitoAlert alert;

  /// Called with the tapped action.
  final ValueChanged<KitoAlertAction> onAction;

  /// Called by the accessibility dismiss gesture.
  final VoidCallback? onDismiss;

  @override
  State<KitoAlertCard> createState() => _KitoAlertCardState();
}

class _KitoAlertCardState extends State<KitoAlertCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _badge = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _badge.value = 1;
    } else if (_badge.value == 0 && !_badge.isAnimating) {
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _badge.forward();
      });
    }
  }

  @override
  void dispose() {
    _badge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final alert = widget.alert;
    final tint = alert.tint ??
        (alert.isDestructive ? theme.colors.danger : theme.colors.primary);
    final ordered = KitoAlert.orderedActions(alert.actions);
    final buttons = [
      for (final action in ordered)
        _AlertButton(
            action: action, tint: tint, onTap: () => widget.onAction(action)),
    ];
    final horizontal = KitoAlert.laysOutHorizontally(alert.actions);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: alert.title,
      onDismiss: widget.onDismiss,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 14)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DefaultTextStyle(
              style:
                  theme.typography.body.copyWith(color: theme.colors.onSurface),
              textAlign: TextAlign.center,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (alert.icon != null) ...[
                      _Badge(icon: alert.icon!, tint: tint, progress: _badge),
                      const SizedBox(height: 14),
                    ],
                    Semantics(
                      header: true,
                      child: Text(alert.title,
                          style: theme.typography.title.copyWith(
                              fontSize: 20, color: theme.colors.onSurface)),
                    ),
                    if (alert.message != null) ...[
                      const SizedBox(height: 6),
                      Text(alert.message!,
                          style: theme.typography.label.copyWith(
                              fontWeight: FontWeight.w400,
                              color: theme.colors.onSurface
                                  .withValues(alpha: 0.65))),
                    ],
                    const SizedBox(height: 18),
                    if (horizontal)
                      Row(children: [
                        Expanded(child: buttons[0]),
                        const SizedBox(width: 10),
                        Expanded(child: buttons[1]),
                      ])
                    else
                      for (var i = 0; i < buttons.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: buttons[i]),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon, required this.tint, required this.progress});

  final IconData icon;
  final Color tint;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
        parent: progress, curve: const KitoSpringCurve(damping: 0.55));
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = progress.value;
          return SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1 + 0.35 * t,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: tint.withValues(alpha: 0.25), width: 6),
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.4 + 0.6 * pop.value,
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tint.withValues(alpha: 0.15)),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 30, color: tint),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton(
      {required this.action, required this.tint, required this.onTap});

  final KitoAlertAction action;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final (Color fill, Color text) = switch (action.role) {
      KitoAlertRole.primary => () {
          final f = tint == theme.colors.danger ? theme.colors.primary : tint;
          return (
            f,
            f == theme.colors.primary
                ? theme.colors.onPrimary
                : kitoModalReadableOn(f)
          );
        }(),
      KitoAlertRole.destructive => (theme.colors.danger, Colors.white),
      KitoAlertRole.secondary || KitoAlertRole.cancel => (
          theme.colors.onSurface.withValues(alpha: 0.08),
          theme.colors.onSurface
        ),
    };
    return KitoModalTapTarget(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        alignment: Alignment.center,
        decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
        child: Text(action.title,
            textAlign: TextAlign.center,
            style: theme.typography.button.copyWith(color: text)),
      ),
    );
  }
}
