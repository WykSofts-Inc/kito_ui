// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'indicators.dart';
import 'models.dart';
import 'motion.dart';
import 'strings.dart';
import 'style.dart';
import 'timeline.dart';

// MARK: - Row

/// An inbox row: avatar with online dot, name, last-message preview (or "typing…"), time,
/// unread badge, and pinned / muted icons.
///
/// ```dart
/// KitoChatListRow(conversation, currentUserId: me.id, onTap: () => open(conversation))
/// ```
class KitoChatListRow extends StatelessWidget {
  /// Creates a row.
  const KitoChatListRow(
    this.conversation, {
    super.key,
    this.currentUserId,
    this.tint,
    this.onTap,
    this.now,
  });

  /// The conversation.
  final KitoChatConversation conversation;

  /// Shows "You:" and your ticks on your own last message.
  final String? currentUserId;

  /// Overrides the primary colour.
  final Color? tint;

  /// Called on tap.
  final VoidCallback? onTap;

  /// "Now", for the timestamp; the current time when null.
  final DateTime? now;

  bool get _fromMe {
    final last = conversation.lastMessage;
    return currentUserId != null &&
        last != null &&
        last.author.id == currentUserId;
  }

  String _label(BuildContext context) {
    final locale = KitoChatStrings.localeOf(context);
    final c = conversation;
    final parts = <String>[c.displayName];
    if (c.isPinned) parts.add(KitoChatStrings.lookup('pinned', locale));
    if (c.isMuted) parts.add(KitoChatStrings.lookup('muted', locale));
    if (c.unreadCount > 0) {
      parts.add(
          KitoChatStrings.lookup('unreadCount', locale, {'n': c.unreadCount}));
    }
    final last = c.lastMessage;
    if (c.isTyping) {
      parts.add(KitoChatStrings.lookup('typingInline', locale));
    } else if (last != null) {
      final preview = last.previewText(locale);
      parts.add(_fromMe
          ? KitoChatStrings.lookup('youPrefix', locale, {'text': preview})
          : preview);
      parts.add(KitoChatDateFormat.listTimestamp(last.date,
          now: now, locale: locale));
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final locale = KitoChatStrings.localeOf(context);
    final accent = KitoChatAccent.of(context, tint);
    final c = conversation;
    final unread = c.unreadCount > 0;
    final last = c.lastMessage;
    final dur = KitoMotion.of(context, kito.motion.medium);
    final muted = kito.colors.onSurface.withValues(alpha: 0.4);

    final preview = AnimatedSwitcher(
      duration: dur,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, if (current != null) current],
      ),
      child: c.isTyping
          ? Row(key: const ValueKey('typing'), children: [
              Text(KitoChatStrings.lookup('typingInline', locale),
                  style: kito.typography.label.copyWith(color: accent.tint)),
              const SizedBox(width: 4),
              KitoChatInlineTypingDots(color: accent.tint),
            ])
          : Row(
              key: ValueKey('last-${last?.id}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_fromMe && last != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: KitoChatStatusTicks(last.status, tint: accent.tint),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    last == null
                        ? ''
                        : (_fromMe
                            ? KitoChatStrings.lookup('youPrefix', locale,
                                {'text': last.previewText(locale)})
                            : last.previewText(locale)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: kito.typography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: kito.colors.onSurface
                          .withValues(alpha: unread ? 0.85 : 0.55),
                    ),
                  ),
                ),
              ],
            ),
    );

    final content = Padding(
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: kito.spacing.lg, vertical: kito.spacing.sm + 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        KitoChatAvatar(c.user, size: 54),
        SizedBox(width: kito.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    c.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kito.typography.bodyEmphasized.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      color: kito.colors.onSurface,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: c.isMuted ? 1 : 0,
                  duration: dur,
                  curve: kito.motion.spring,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Icon(Icons.notifications_off_rounded,
                        size: c.isMuted ? 13 : 0, color: muted),
                  ),
                ),
                SizedBox(width: kito.spacing.sm),
                const Spacer(),
                if (last != null)
                  Text(
                    KitoChatDateFormat.listTimestamp(last.date,
                        now: now, locale: locale),
                    style: kito.typography.caption.copyWith(
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      color: unread && !c.isMuted
                          ? accent.tint
                          : kito.colors.onSurface.withValues(alpha: 0.5),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ]),
              const SizedBox(height: 3),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: preview),
                SizedBox(width: kito.spacing.sm),
                AnimatedSize(
                  duration: kitoChatSizeDuration(dur),
                  curve: kito.motion.standard,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (c.isPinned)
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.only(end: 4, top: 2),
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: Icon(Icons.push_pin_rounded,
                              size: 14, color: muted),
                        ),
                      ),
                    if (unread)
                      _Badge(
                        count: c.unreadCount,
                        background:
                            c.isMuted ? kito.colors.surfaceMuted : accent.tint,
                        foreground:
                            c.isMuted ? kito.colors.onSurface : accent.onTint,
                      ),
                  ]),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label: _label(context),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.count,
      required this.background,
      required this.foreground});
  final int count;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return AnimatedContainer(
      duration: KitoMotion.of(context, kito.motion.fast),
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(11)),
      child: AnimatedSwitcher(
        duration: KitoMotion.of(context, kito.motion.fast),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Text(
          count > 99 ? '99+' : '$count',
          key: ValueKey(count),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

// MARK: - Swipe actions

/// One button revealed by swiping a row.
@immutable
class KitoChatSwipeAction {
  /// Creates an action.
  const KitoChatSwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.foreground = Colors.white,
  });

  /// Its title.
  final String label;

  /// Its glyph.
  final IconData icon;

  /// Its background.
  final Color color;

  /// Its text and glyph colour.
  final Color foreground;

  /// Called when chosen.
  final VoidCallback onPressed;
}

/// Swipe [child] toward the trailing edge to reveal [leading] actions, toward the leading edge
/// for [trailing] ones; swipe all the way to run the first. Mirrors in right-to-left layouts,
/// and every action is also a screen-reader action.
class KitoChatSwipeActions extends StatefulWidget {
  /// Wraps [child] in swipe actions.
  const KitoChatSwipeActions({
    super.key,
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.actionWidth = 78,
  });

  /// The row.
  final Widget child;

  /// Revealed at the leading edge.
  final List<KitoChatSwipeAction> leading;

  /// Revealed at the trailing edge.
  final List<KitoChatSwipeAction> trailing;

  /// The width of each button.
  final double actionWidth;

  @override
  State<KitoChatSwipeActions> createState() => _KitoChatSwipeActionsState();
}

class _KitoChatSwipeActionsState extends State<KitoChatSwipeActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController.unbounded(vsync: this)
        ..addListener(() => setState(() => _offset = _anim.value));
  double _offset = 0; // semantic: + reveals leading, − reveals trailing
  double _width = 0;
  bool _armed = false;

  double get _leadingExtent => widget.leading.length * widget.actionWidth;
  double get _trailingExtent => widget.trailing.length * widget.actionWidth;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    if (context.reduceMotion) {
      _anim.value = target;
      return;
    }
    _anim.animateTo(target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
  }

  void _update(DragUpdateDetails d) {
    _anim.stop();
    final dx = d.delta.dx * (context.isRtl ? -1 : 1);
    var next = _offset + dx;
    if (widget.leading.isEmpty) next = math.min(0, next);
    if (widget.trailing.isEmpty) next = math.max(0, next);
    final full = _width * 0.6;
    final armed = next.abs() >
        math.max(full, (next > 0 ? _leadingExtent : _trailingExtent) + 40);
    if (armed != _armed) {
      HapticFeedback.mediumImpact();
      _armed = armed;
    }
    _anim.value = next.clamp(-_width, _width);
  }

  void _end(DragEndDetails d) {
    final v = (d.primaryVelocity ?? 0) * (context.isRtl ? -1 : 1);
    if (_armed) {
      final action = _offset > 0 ? widget.leading.first : widget.trailing.first;
      _armed = false;
      _animateTo(0);
      action.onPressed();
      return;
    }
    if (_offset > 0) {
      _animateTo(_offset > _leadingExtent / 2 || v > 600 ? _leadingExtent : 0);
    } else if (_offset < 0) {
      _animateTo(
          _offset < -_trailingExtent / 2 || v < -600 ? -_trailingExtent : 0);
    }
  }

  void _run(KitoChatSwipeAction a) {
    _animateTo(0);
    a.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = context.isRtl;
    return Semantics(
      customSemanticsActions: {
        for (final a in [...widget.leading, ...widget.trailing])
          CustomSemanticsAction(label: a.label): a.onPressed,
      },
      child: LayoutBuilder(builder: (context, constraints) {
        _width = constraints.maxWidth;
        final physical = _offset * (rtl ? -1 : 1);
        return GestureDetector(
          onHorizontalDragUpdate: _update,
          onHorizontalDragEnd: _end,
          child: ClipRect(
            child: Stack(children: [
              if (_offset > 0)
                Positioned.fill(
                  child: _ActionStrip(
                    actions: widget.leading,
                    extent: _offset,
                    atStart: true,
                    armed: _armed,
                    actionWidth: widget.actionWidth,
                    onRun: _run,
                  ),
                ),
              if (_offset < 0)
                Positioned.fill(
                  child: _ActionStrip(
                    actions: widget.trailing,
                    extent: -_offset,
                    atStart: false,
                    armed: _armed,
                    actionWidth: widget.actionWidth,
                    onRun: _run,
                  ),
                ),
              Transform.translate(
                offset: Offset(physical, 0),
                child: ColoredBox(
                    color: context.kito.colors.background, child: widget.child),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.actions,
    required this.extent,
    required this.atStart,
    required this.armed,
    required this.actionWidth,
    required this.onRun,
  });
  final List<KitoChatSwipeAction> actions;
  final double extent;
  final bool atStart;
  final bool armed;
  final double actionWidth;
  final ValueChanged<KitoChatSwipeAction> onRun;

  @override
  Widget build(BuildContext context) {
    final each = extent / math.max(1, actions.length);
    final ordered = atStart ? actions : actions.reversed.toList();
    return Align(
      alignment: atStart
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: extent,
        child: ExcludeSemantics(
          child: Row(children: [
            if (armed)
              Expanded(child: _button(context, actions.first, extent))
            else
              for (final a in ordered)
                SizedBox(width: each, child: _button(context, a, each)),
          ]),
        ),
      ),
    );
  }

  Widget _button(BuildContext context, KitoChatSwipeAction a, double width) {
    return GestureDetector(
      onTap: () => onRun(a),
      child: ColoredBox(
        color: a.color,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: actionWidth,
            minWidth: actionWidth,
            child: Opacity(
              opacity: (width / actionWidth).clamp(0.0, 1.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a.icon, color: a.foreground, size: 20),
                    const SizedBox(height: 4),
                    Text(a.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                            color: a.foreground,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - List

/// A ready-made inbox: pinned conversations first, swipe to read, pin, mute or delete, and rows
/// that animate as conversations change. Leave a handler null to hide its action.
///
/// ```dart
/// KitoChatList(
///   conversations: conversations,
///   currentUserId: me.id,
///   onSelect: open,
///   onChanged: (next) => setState(() => conversations = next),
/// )
/// ```
class KitoChatList extends StatefulWidget {
  /// Creates an inbox.
  const KitoChatList({
    super.key,
    required this.conversations,
    this.currentUserId,
    this.tint,
    this.onSelect,
    this.onChanged,
    this.allowsRead = true,
    this.allowsPin = true,
    this.allowsMute = true,
    this.allowsDelete = true,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.now,
  });

  /// The conversations, in any order.
  final List<KitoChatConversation> conversations;

  /// Shows "You:" and your ticks on your own last messages.
  final String? currentUserId;

  /// Overrides the primary colour.
  final Color? tint;

  /// Called when a row is tapped.
  final ValueChanged<KitoChatConversation>? onSelect;

  /// Called with the updated list after a swipe action. Without it, no swipe actions show.
  final ValueChanged<List<KitoChatConversation>>? onChanged;

  /// Offer read / unread.
  final bool allowsRead;

  /// Offer pin / unpin.
  final bool allowsPin;

  /// Offer mute / unmute.
  final bool allowsMute;

  /// Offer delete.
  final bool allowsDelete;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Size to the rows instead of filling the space.
  final bool shrinkWrap;

  /// "Now", for timestamps.
  final DateTime? now;

  @override
  State<KitoChatList> createState() => _KitoChatListState();
}

class _KitoChatListState extends State<KitoChatList> {
  final _removing = <String>{};

  void _change(
      String id, KitoChatConversation Function(KitoChatConversation) f) {
    widget.onChanged?.call([
      for (final c in widget.conversations) c.id == id ? f(c) : c,
    ]);
  }

  void _delete(String id) {
    setState(() => _removing.add(id));
    Timer(KitoMotion.of(context, const Duration(milliseconds: 260)), () {
      if (!mounted) return;
      _removing.remove(id);
      widget.onChanged?.call([
        for (final c in widget.conversations)
          if (c.id != id) c
      ]);
    });
  }

  List<KitoChatSwipeAction> _leading(KitoChatConversation c) {
    final kito = context.kito;
    if (widget.onChanged == null) return const [];
    return [
      if (widget.allowsRead)
        KitoChatSwipeAction(
          label: KitoChatStrings.of(
              context, c.unreadCount > 0 ? 'markRead' : 'markUnread'),
          icon: c.unreadCount > 0
              ? Icons.mark_chat_read_rounded
              : Icons.mark_chat_unread_rounded,
          color: kito.accent(widget.tint),
          foreground: kito.onAccent(widget.tint),
          onPressed: () => _change(
              c.id, (x) => x.copyWith(unreadCount: x.unreadCount > 0 ? 0 : 1)),
        ),
      if (widget.allowsPin)
        KitoChatSwipeAction(
          label: KitoChatStrings.of(context, c.isPinned ? 'unpin' : 'pin'),
          icon: c.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          color: kito.colors.warning,
          onPressed: () =>
              _change(c.id, (x) => x.copyWith(isPinned: !x.isPinned)),
        ),
    ];
  }

  List<KitoChatSwipeAction> _trailing(KitoChatConversation c) {
    final kito = context.kito;
    if (widget.onChanged == null) return const [];
    return [
      if (widget.allowsDelete)
        KitoChatSwipeAction(
          label: KitoChatStrings.of(context, 'delete'),
          icon: Icons.delete_rounded,
          color: kito.colors.danger,
          onPressed: () => _delete(c.id),
        ),
      if (widget.allowsMute)
        KitoChatSwipeAction(
          label: KitoChatStrings.of(context, c.isMuted ? 'unmute' : 'mute'),
          icon: c.isMuted
              ? Icons.notifications_rounded
              : Icons.notifications_off_rounded,
          color: kito.colors.secondary,
          foreground: kito.colors.onSecondary,
          onPressed: () =>
              _change(c.id, (x) => x.copyWith(isMuted: !x.isMuted)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final sorted = KitoChatConversation.sorted(widget.conversations);
    return ColoredBox(
      color: kito.colors.background,
      child: ListView.separated(
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: sorted.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsetsDirectional.only(start: 82),
          child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: kito.colors.border.withValues(alpha: 0.6)),
        ),
        itemBuilder: (context, i) {
          final c = sorted[i];
          return AnimatedSize(
            key: ValueKey(c.id),
            duration: kitoChatSizeDuration(
                KitoMotion.of(context, const Duration(milliseconds: 240))),
            curve: Curves.easeOut,
            child: _removing.contains(c.id)
                ? const SizedBox(width: double.infinity)
                : KitoChatSwipeActions(
                    leading: _leading(c),
                    trailing: _trailing(c),
                    child: KitoChatListRow(
                      c,
                      currentUserId: widget.currentUserId,
                      tint: widget.tint,
                      now: widget.now,
                      onTap: widget.onSelect == null
                          ? null
                          : () => widget.onSelect!(c),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
