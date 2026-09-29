// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'common.dart';
import 'sheet.dart';

/// One row of a Kito action menu.
@immutable
class KitoMenuAction {
  /// Creates a row.
  const KitoMenuAction(this.title,
      {this.icon, this.isDestructive = false, this.onPressed});

  /// The row text.
  final String title;

  /// An icon before the text.
  final IconData? icon;

  /// Draws the row in the danger colour.
  final bool isDestructive;

  /// Called after the menu has closed.
  final VoidCallback? onPressed;
}

/// Shows a floating action sheet: a card of icon rows with an optional [title] and
/// [message], and a separate Cancel card below it. Completes with the action picked (after
/// running its `onPressed`), or null when cancelled. Pass `useRootNavigator: false` to open it
/// inside a nested navigator (a tab, a phone-frame preview).
///
/// ```dart
/// showKitoActionMenu(context, title: 'Profile photo', actions: [
///   KitoMenuAction('Take photo', icon: Icons.photo_camera_rounded, onPressed: takePhoto),
///   KitoMenuAction('Remove photo', icon: Icons.delete_rounded, isDestructive: true,
///       onPressed: removePhoto),
/// ]);
/// ```
Future<KitoMenuAction?> showKitoActionMenu(
  BuildContext context, {
  required List<KitoMenuAction> actions,
  String? title,
  String? message,
  String cancelTitle = 'Cancel',
  bool useRootNavigator = true,
}) async {
  final picked = await showKitoSheet<KitoMenuAction>(
    context: context,
    useRootNavigator: useRootNavigator,
    configuration: KitoSheetConfiguration(
      style: KitoSheetStyle.floating,
      showsGrabber: false,
      background: const Color(0x00000000),
      semanticLabel: title ?? 'Actions',
    ),
    builder: (context) => KitoActionMenuContent(
      title: title,
      message: message,
      actions: actions,
      cancelTitle: cancelTitle,
      onPicked: (action) => KitoSheetController.of(context).dismiss(action),
      onCancel: () => KitoSheetController.of(context).dismiss(),
    ),
  );
  picked?.onPressed?.call();
  return picked;
}

/// The cards of an action menu, for placing one in your own sheet or layout.
class KitoActionMenuContent extends StatelessWidget {
  /// Creates the menu cards.
  const KitoActionMenuContent({
    super.key,
    required this.actions,
    required this.onPicked,
    required this.onCancel,
    this.title,
    this.message,
    this.cancelTitle = 'Cancel',
  });

  /// The rows.
  final List<KitoMenuAction> actions;

  /// Called with the tapped row.
  final ValueChanged<KitoMenuAction> onPicked;

  /// Called by the Cancel card.
  final VoidCallback onCancel;

  /// A heading above the rows.
  final String? title;

  /// A line under the heading.
  final String? message;

  /// The Cancel card's text.
  final String cancelTitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final card = BoxDecoration(
      color: theme.colors.surface,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8)),
      ],
    );
    final divider = theme.colors.onSurface.withValues(alpha: 0.1);
    final top = BorderRadius.vertical(
        top: (title == null && message == null)
            ? const Radius.circular(26)
            : Radius.zero);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      DecoratedBox(
        decoration: card,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (title != null || message != null) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(children: [
                  if (title != null)
                    Semantics(
                      header: true,
                      child: Text(title!,
                          textAlign: TextAlign.center,
                          style: theme.typography.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.onSurface)),
                    ),
                  if (message != null) ...[
                    const SizedBox(height: 4),
                    Text(message!,
                        textAlign: TextAlign.center,
                        style: theme.typography.caption.copyWith(
                            color:
                                theme.colors.onSurface.withValues(alpha: 0.6))),
                  ],
                ]),
              ),
              Divider(height: 1, thickness: 1, color: divider),
            ],
            for (var i = 0; i < actions.length; i++) ...[
              _MenuRow(
                action: actions[i],
                radius: i == 0 ? top : BorderRadius.zero,
                onTap: () => onPicked(actions[i]),
              ),
              if (i < actions.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: divider,
                  indent: actions[i].icon == null ? 20 : 60,
                ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 10),
      KitoModalTapTarget(
        onTap: onCancel,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: card,
          child: Text(cancelTitle,
              style: theme.typography.bodyEmphasized
                  .copyWith(color: theme.colors.onSurface)),
        ),
      ),
    ]);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(
      {required this.action, required this.onTap, required this.radius});

  final KitoMenuAction action;
  final VoidCallback onTap;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final color =
        action.isDestructive ? theme.colors.danger : theme.colors.onSurface;
    return KitoModalTapTarget(
      onTap: onTap,
      pressEffect: false,
      highlight: theme.colors.onSurface.withValues(alpha: 0.08),
      highlightRadius: radius,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          if (action.icon != null) ...[
            SizedBox(
                width: 26, child: Icon(action.icon, size: 22, color: color)),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Text(action.title,
                style: theme.typography.body
                    .copyWith(fontWeight: FontWeight.w500, color: color)),
          ),
        ]),
      ),
    );
  }
}
