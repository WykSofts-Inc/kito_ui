// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'parts.dart';
import 'text.dart';

/// One conversation in a list: title, the latest text, when, a pin and the model badge.
///
/// ```dart
/// KitoAiConversationRow(conversation: chat, isSelected: chat.id == openId, onTap: open)
/// ```
class KitoAiConversationRow extends StatelessWidget {
  /// Shows [conversation].
  const KitoAiConversationRow({
    super.key,
    required this.conversation,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.now,
    this.use24HourFormat = true,
    this.tint,
    this.customActions = const {},
  });

  /// The conversation.
  final KitoAiConversation conversation;

  /// Highlights the row.
  final bool isSelected;

  /// Called on tap.
  final VoidCallback? onTap;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// "Now" for the timestamp; handy in tests.
  final DateTime? now;

  /// "14:05" rather than "2:05 PM".
  final bool use24HourFormat;

  /// The selection and pin colour; the theme's primary when null.
  final Color? tint;

  /// Extra screen-reader actions, like Pin and Delete.
  final Map<CustomSemanticsAction, VoidCallback> customActions;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = aiAccent(theme, tint);
    final title = conversation.displayTitle;
    final snippet = conversation.snippet;
    final stamp = KitoAiDateFormat.rowTimestamp(conversation.updatedAt,
        now: now, use24HourFormat: use24HourFormat);
    return Semantics(
      button: true,
      selected: isSelected,
      label: [
        title,
        if (conversation.isPinned) 'Pinned',
        stamp,
        if (snippet.isNotEmpty) snippet,
      ].join(', '),
      excludeSemantics: true,
      customSemanticsActions: customActions,
      onTap: onTap,
      child: KitoPressable(
        scale: 0.98,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(theme.radii.md + 2),
            child: AnimatedContainer(
              duration: KitoMotion.of(context, theme.motion.fast),
              constraints: const BoxConstraints(minHeight: 56),
              alignment: AlignmentDirectional.centerStart,
              padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.md, vertical: theme.spacing.sm + 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(theme.radii.md + 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (conversation.isPinned) ...[
                        Icon(Icons.push_pin_rounded, size: 13, color: accent),
                        SizedBox(width: theme.spacing.xs),
                      ],
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.label.copyWith(
                                color: theme.colors.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 15)),
                      ),
                      SizedBox(width: theme.spacing.sm),
                      Text(stamp,
                          style: theme.typography.caption
                              .copyWith(color: aiMuted(theme, 0.45))),
                    ],
                  ),
                  if (snippet.isNotEmpty || conversation.model != null) ...[
                    SizedBox(height: theme.spacing.xxs + 1),
                    Row(
                      children: [
                        Expanded(
                          child: Text(snippet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.typography.caption.copyWith(
                                  color: aiMuted(theme, 0.55), fontSize: 13)),
                        ),
                        if (conversation.model case final model?) ...[
                          SizedBox(width: theme.spacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(theme.radii.pill),
                            ),
                            child: Text(model,
                                style: theme.typography.caption.copyWith(
                                    color: aiMuted(theme, 0.6),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A conversation sidebar: a New chat button, search over titles and the latest text, and
/// conversations grouped into Pinned, Today, Yesterday, Previous 7 days, Previous 30 days and
/// one section per month. Long-press a row (or use the screen-reader actions) to pin or delete.
///
/// ```dart
/// KitoAiConversationList(
///   conversations: history,
///   selectedId: openId,
///   onSelect: (c) => open(c),
///   onNewChat: startChat,
///   onTogglePin: pin,
///   onDelete: delete,
/// )
/// ```
///
/// It scrolls on its own, so give it a height (or put it in a drawer).
class KitoAiConversationList extends StatefulWidget {
  /// Creates a list.
  const KitoAiConversationList({
    super.key,
    required this.conversations,
    this.selectedId,
    this.onSelect,
    this.onNewChat,
    this.onTogglePin,
    this.onDelete,
    this.title = 'Chats',
    this.showsSearch = true,
    this.now,
    this.use24HourFormat = true,
    this.tint,
  });

  /// Every conversation, in any order.
  final List<KitoAiConversation> conversations;

  /// The open conversation.
  final String? selectedId;

  /// Called when a row is tapped.
  final ValueChanged<KitoAiConversation>? onSelect;

  /// Shows a New chat button.
  final VoidCallback? onNewChat;

  /// Offers Pin / Unpin.
  final ValueChanged<KitoAiConversation>? onTogglePin;

  /// Offers Delete.
  final ValueChanged<KitoAiConversation>? onDelete;

  /// The header.
  final String title;

  /// Shows the search field.
  final bool showsSearch;

  /// "Now" for grouping and timestamps; handy in tests.
  final DateTime? now;

  /// "14:05" rather than "2:05 PM".
  final bool use24HourFormat;

  /// Selection and accents; the theme's primary when null.
  final Color? tint;

  @override
  State<KitoAiConversationList> createState() => _KitoAiConversationListState();
}

class _KitoAiConversationListState extends State<KitoAiConversationList> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<CustomSemanticsAction, VoidCallback> _actions(KitoAiConversation c) => {
        if (widget.onTogglePin != null)
          CustomSemanticsAction(label: c.isPinned ? 'Unpin' : 'Pin'): () =>
              widget.onTogglePin!(c),
        if (widget.onDelete != null)
          const CustomSemanticsAction(label: 'Delete'): () =>
              widget.onDelete!(c),
      };

  Future<void> _menu(KitoAiConversation c) async {
    if (widget.onTogglePin == null && widget.onDelete == null) return;
    HapticFeedback.mediumImpact();
    final theme = context.kito;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              theme.spacing.lg, 0, theme.spacing.lg, theme.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(c.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.headline
                      .copyWith(color: theme.colors.onSurface)),
              SizedBox(height: theme.spacing.sm),
              if (widget.onTogglePin != null)
                _SheetAction(
                  icon: c.isPinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  label: c.isPinned ? 'Unpin' : 'Pin',
                  onTap: () => Navigator.of(context).pop('pin'),
                ),
              if (widget.onDelete != null)
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: theme.colors.danger,
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == 'pin') widget.onTogglePin?.call(c);
    if (action == 'delete') widget.onDelete?.call(c);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final query = _search.text;
    final visible =
        KitoAiConversationGrouping.filter(widget.conversations, query);
    final sections =
        KitoAiConversationGrouping.sections(visible, now: widget.now);

    final items = <Widget>[];
    for (final section in sections) {
      items.add(Padding(
        padding: EdgeInsetsDirectional.only(
            start: theme.spacing.md,
            top: items.isEmpty ? theme.spacing.xs : theme.spacing.lg,
            bottom: theme.spacing.xs),
        child: Semantics(
          header: true,
          child: Text(section.title,
              style: theme.typography.caption.copyWith(
                  color: aiMuted(theme, 0.5), fontWeight: FontWeight.w600)),
        ),
      ));
      for (final c in section.conversations) {
        items.add(KitoAiConversationRow(
          key: ValueKey(c.id),
          conversation: c,
          isSelected: c.id == widget.selectedId,
          onTap: widget.onSelect == null ? null : () => widget.onSelect!(c),
          onLongPress: () => _menu(c),
          now: widget.now,
          use24HourFormat: widget.use24HourFormat,
          tint: widget.tint,
          customActions: _actions(c),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
              start: theme.spacing.md, end: theme.spacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(widget.title,
                      style: theme.typography.title
                          .copyWith(color: theme.colors.onSurface)),
                ),
              ),
              if (widget.onNewChat != null)
                Tooltip(
                  message: 'New chat',
                  excludeFromSemantics: true,
                  child: AiTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onNewChat!();
                    },
                    label: 'New chat',
                    child: Icon(Icons.edit_square,
                        size: 22, color: theme.colors.onSurface),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showsSearch)
          Padding(
            padding: EdgeInsets.fromLTRB(theme.spacing.sm, theme.spacing.sm,
                theme.spacing.sm, theme.spacing.xs),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _search,
                style: theme.typography.label
                    .copyWith(color: theme.colors.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search chats',
                  hintStyle: theme.typography.label
                      .copyWith(color: aiMuted(theme, 0.4)),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: aiMuted(theme, 0.45)),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: Icon(Icons.cancel_rounded,
                              size: 18, color: aiMuted(theme, 0.4)),
                          onPressed: _search.clear,
                        ),
                  filled: true,
                  fillColor: theme.colors.surfaceMuted.withValues(alpha: 0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(theme.radii.md + 2),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: theme.spacing.sm),
                ),
              ),
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: KitoMotion.of(context, theme.motion.fast),
            child: items.isEmpty
                ? Center(
                    key: const ValueKey('empty'),
                    child: Padding(
                      padding: EdgeInsets.all(theme.spacing.xl),
                      child: Text(
                        query.trim().isEmpty
                            ? 'No chats yet'
                            : 'No chats match “${query.trim()}”',
                        textAlign: TextAlign.center,
                        style: theme.typography.label
                            .copyWith(color: aiMuted(theme, 0.5)),
                      ),
                    ),
                  )
                : ListView(
                    key: const ValueKey('list'),
                    padding: EdgeInsets.symmetric(
                        horizontal: theme.spacing.xs,
                        vertical: theme.spacing.xs),
                    children: items,
                  ),
          ),
        ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final c = color ?? theme.colors.onSurface;
    return AiTap(
      onTap: onTap,
      label: label,
      radius: theme.radii.md,
      scale: 0.98,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.xs, vertical: theme.spacing.sm + 2),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            SizedBox(width: theme.spacing.md),
            Expanded(
                child: Text(label,
                    style: theme.typography.body.copyWith(color: c))),
          ],
        ),
      ),
    );
  }
}
