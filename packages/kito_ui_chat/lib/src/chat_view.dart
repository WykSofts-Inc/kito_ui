// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'bubble.dart';
import 'composer.dart';
import 'controller.dart';
import 'indicators.dart';
import 'message_row.dart';
import 'models.dart';
import 'motion.dart';
import 'overlays.dart';
import 'strings.dart';
import 'style.dart';
import 'timeline.dart';
import 'voice.dart';

/// A whole conversation: grouped bubbles with date separators and a floating day pill, an
/// "N unread" divider, read receipts, a typing indicator, a scroll-to-bottom button that counts
/// new messages, and the composer. Long-press a bubble to react, reply, copy or delete; swipe it
/// toward the trailing edge to reply; tap it to see its time; tap a photo to open it.
///
/// The view edits [controller] itself — sending appends a `sending` message, reactions and
/// deletes update it — and hands every new message to [onSend] so you can deliver it and move
/// its status on.
///
/// ```dart
/// final chat = KitoChatController(messages: history);
///
/// KitoChatView(
///   controller: chat,
///   currentUser: me,
///   style: KitoChatBubbleStyle.imessage,
///   onSend: (message) async {
///     await api.send(message);
///     chat.updateStatus(message.id, KitoChatMessageStatus.sent);
///   },
/// )
/// ```
class KitoChatView extends StatefulWidget {
  /// Creates a conversation.
  const KitoChatView({
    super.key,
    required this.controller,
    required this.currentUser,
    this.onSend,
    this.style = KitoChatBubbleStyle.modern,
    this.wallpaper = KitoChatWallpaper.plain,
    this.unreadCount = 0,
    this.showsComposer = true,
    this.placeholder,
    this.tint,
    this.onAttach,
    this.recorder,
    this.audioPlayer,
    this.onLinkTap,
    this.groupingInterval = const Duration(minutes: 5),
    this.padding,
  });

  /// The messages and typing users.
  final KitoChatController controller;

  /// You — your messages sit on the trailing side.
  final KitoChatUser currentUser;

  /// Called with every message you send (and every retry).
  final ValueChanged<KitoChatMessage>? onSend;

  /// How bubbles look.
  final KitoChatBubbleStyle style;

  /// What's behind the messages.
  final KitoChatWallpaper wallpaper;

  /// Puts an "N unread" divider before the last [unreadCount] incoming messages and scrolls to it.
  final int unreadCount;

  /// Show the composer.
  final bool showsComposer;

  /// The composer's placeholder.
  final String? placeholder;

  /// Overrides the primary colour.
  final Color? tint;

  /// Shows the composer's attach button.
  final VoidCallback? onAttach;

  /// Records voice notes; a simulated preview when null.
  final KitoChatVoiceRecorder? recorder;

  /// Makes a real audio player for voice notes with a URL.
  final KitoChatAudioPlayer Function()? audioPlayer;

  /// Called when a link in a message is tapped.
  final ValueChanged<Uri>? onLinkTap;

  /// Messages closer together than this group into one run.
  final Duration groupingInterval;

  /// Padding around the message list; 12 points on each side when null.
  final EdgeInsetsGeometry? padding;

  @override
  State<KitoChatView> createState() => _KitoChatViewState();
}

class _KitoChatViewState extends State<KitoChatView> {
  final _scroll = ScrollController();
  final _stackKey = GlobalKey();
  final _composerKey = GlobalKey();
  final _rowKeys = <String, GlobalKey>{};
  final _sectionKeys = <String, GlobalKey>{};
  final _fresh = <String>{};
  final _removing = <String>{};
  Set<String> _known = {};
  String? _lastId;

  KitoChatReply? _replyTo;
  String? _revealedId;
  String? _selectedId;
  Rect? _selectedRect;
  String? _highlightedId;
  ({KitoChatImage image, Rect? rect})? _viewer;

  bool _atBottom = true;
  int _unseen = 0;
  String? _floatingTitle;
  bool _floatingVisible = false;
  Timer? _floatingTimer;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _known = {for (final m in widget.controller.messages) m.id};
    _lastId = widget.controller.messages.isEmpty
        ? null
        : widget.controller.messages.last.id;
    widget.controller.addListener(_changed);
    _scroll.addListener(_scrolled);
    if (widget.unreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToUnread());
    }
  }

  @override
  void didUpdateWidget(KitoChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _known = {for (final m in widget.controller.messages) m.id};
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _scroll.dispose();
    _floatingTimer?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }

  // MARK: Changes

  void _changed() {
    final messages = widget.controller.messages;
    final ids = {for (final m in messages) m.id};
    final added = ids.difference(_known);
    _fresh.addAll(added);
    _known = ids;
    final last = messages.isEmpty ? null : messages.last;
    if (last != null && last.id != _lastId && added.contains(last.id)) {
      if (last.author.id == widget.currentUser.id) {
        _scrollToBottom();
      } else if (!_atBottom && !last.isSystem) {
        _unseen++;
      }
    }
    _lastId = last?.id;
    if (_selectedId != null && !ids.contains(_selectedId)) _selectedId = null;
    setState(() {});
  }

  void _scrolled() {
    final pos = _scroll.position;
    final atBottom = pos.pixels <= 48;
    if (atBottom != _atBottom) {
      setState(() {
        _atBottom = atBottom;
        if (atBottom) _unseen = 0;
      });
    }
    _updateFloating();
  }

  void _updateFloating() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final top = pos.pixels + pos.viewportDimension - 8;
    String? title;
    for (final entry in _sectionKeys.entries) {
      final ro = entry.value.currentContext?.findRenderObject();
      if (ro is! RenderSliver || ro.geometry == null) continue;
      final start = ro.constraints.precedingScrollExtent;
      final end = start + ro.geometry!.scrollExtent;
      if (top >= start && top < end) {
        title = _sectionTitles[entry.key];
        break;
      }
    }
    final scrollable = pos.maxScrollExtent > 0;
    _floatingTimer?.cancel();
    _floatingTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _floatingVisible = false);
    });
    if (title != _floatingTitle || !_floatingVisible) {
      setState(() {
        _floatingTitle = title;
        _floatingVisible = scrollable && title != null;
      });
    }
  }

  Map<String, String> _sectionTitles = {};

  // MARK: Scrolling

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      if (context.reduceMotion) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic);
      }
    });
  }

  Future<bool> _reveal(String id, {double alignment = 0.5}) async {
    if (!_scroll.hasClients) return false;
    for (var i = 0; i < 40; i++) {
      final ctx = _rowKeys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(ctx,
            alignment: alignment,
            duration: KitoMotion.of(context, const Duration(milliseconds: 380)),
            curve: Curves.easeOutCubic);
        return true;
      }
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent) return false;
      _scroll.jumpTo((pos.pixels + pos.viewportDimension * 0.8)
          .clamp(0, pos.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
    }
    return false;
  }

  Future<void> _jumpToUnread() async {
    final divider = KitoChatTimeline.unreadDivider(widget.controller.messages,
        currentUserId: widget.currentUser.id, unreadCount: widget.unreadCount);
    if (divider == null || !mounted || !_scroll.hasClients) return;
    final ctx = _rowKeys[KitoChatTimeline.unreadDividerId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, alignment: 0.05);
    } else {
      await _reveal(KitoChatTimeline.unreadDividerId, alignment: 0.05);
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && !_atBottom) setState(() => _unseen = divider.count);
  }

  Future<void> _jumpTo(String id) async {
    if (widget.controller.byId(id) == null) return;
    final found = await _reveal(id);
    if (!found || !mounted) return;
    setState(() => _highlightedId = id);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  // MARK: Actions

  void _send(KitoChatContent content) {
    final message = KitoChatMessage(
      author: widget.currentUser,
      content: content,
      status: KitoChatMessageStatus.sending,
      replyTo: _replyTo,
    );
    setState(() => _replyTo = null);
    widget.controller.add(message);
    widget.onSend?.call(message);
  }

  void _retry(String id) {
    if (!widget.controller.updateStatus(id, KitoChatMessageStatus.sending)) {
      return;
    }
    final m = widget.controller.byId(id);
    if (m != null) widget.onSend?.call(m);
  }

  void _react(String id, String emoji) {
    widget.controller.toggleReaction(id, emoji, widget.currentUser.id);
    setState(() => _selectedId = null);
  }

  void _reply(KitoChatMessage m) {
    setState(() {
      _selectedId = null;
      _replyTo = KitoChatReply.of(m, locale: KitoChatStrings.localeOf(context));
    });
  }

  void _copy(KitoChatMessage m) {
    final text = m.copyableText;
    if (text != null) Clipboard.setData(ClipboardData(text: text));
    setState(() => _selectedId = null);
  }

  void _delete(String id) {
    setState(() {
      _selectedId = null;
      _removing.add(id);
      if (_replyTo?.messageId == id) _replyTo = null;
    });
    Timer(KitoMotion.of(context, const Duration(milliseconds: 240)), () {
      _removing.remove(id);
      widget.controller.remove(id);
    });
  }

  void _longPress(KitoChatMessage m, Rect global) {
    if (m.isSystem) return;
    final box = _stackKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final local = box.globalToLocal(global.topLeft) & global.size;
    setState(() {
      _selectedId = m.id;
      _selectedRect = local;
    });
  }

  void _openImage(KitoChatImage image, Rect? global) {
    final box = _stackKey.currentContext?.findRenderObject();
    Rect? local;
    if (global != null && box is RenderBox) {
      local = box.globalToLocal(global.topLeft) & global.size;
    }
    setState(() => _viewer = (image: image, rect: local));
  }

  // MARK: Build

  KitoChatBubble _bubble(KitoChatMessage m, KitoChatGroupPosition position,
      {required bool isGroup}) {
    final outgoing = m.author.id == widget.currentUser.id;
    return KitoChatBubble(
      m,
      isOutgoing: outgoing,
      position: position,
      style: widget.style,
      showsAuthorName: isGroup && !outgoing && position.isGroupStart,
      currentUserId: widget.currentUser.id,
      tint: widget.tint,
      onReactionTap: (e) => _react(m.id, e),
      onQuoteTap: _jumpTo,
      onImageTap: (_, image, rect) => _openImage(image, rect),
      onLinkTap: widget.onLinkTap,
      audioPlayer: widget.audioPlayer,
    );
  }

  Widget _row(KitoChatTimelineRow row, {required bool isGroup}) {
    final key = _rowKeys.putIfAbsent(row.id, GlobalKey.new);
    final Widget child = switch (row) {
      KitoChatTimelineUnreadDivider(:final count) =>
        KitoChatUnreadDivider(count: count, tint: widget.tint),
      KitoChatTimelineMessage(:final message, :final position) =>
        KitoChatMessageRow(
          message: message,
          bubble: _bubble(message, position, isGroup: isGroup),
          isOutgoing: message.author.id == widget.currentUser.id,
          position: position,
          showsAvatar: isGroup && message.author.id != widget.currentUser.id,
          isTimeRevealed: _revealedId == message.id,
          isLifted: _selectedId == message.id,
          isHighlighted: _highlightedId == message.id,
          tint: widget.tint,
          onTap: () => setState(() =>
              _revealedId = _revealedId == message.id ? null : message.id),
          onLongPress: (rect) => _longPress(message, rect),
          onReply: () => _reply(message),
          onRetry: () => _retry(message.id),
          onReact: () => _react(message.id, KitoChatReaction.quickPicks.first),
          onCopy: message.copyableText == null ? null : () => _copy(message),
          onDelete: () => _delete(message.id),
        ),
    };
    final fresh = _fresh.remove(row.id);
    final outgoing = row is KitoChatTimelineMessage &&
        row.message.author.id == widget.currentUser.id;
    return KeyedSubtree(
      key: key,
      child: _Entry(
        animate: fresh,
        removing: _removing.contains(row.id),
        fromEnd: outgoing,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final locale = KitoChatStrings.localeOf(context);
    final messages = widget.controller.messages;
    final typing = widget.controller.typingUsers;
    final isGroup = KitoChatTimeline.isGroupConversation(messages,
        currentUserId: widget.currentUser.id);
    final timeline = KitoChatTimeline(messages,
        currentUserId: widget.currentUser.id,
        unreadCount: widget.unreadCount,
        groupingInterval: widget.groupingInterval,
        locale: locale);
    _sectionTitles = {for (final s in timeline.sections) s.id: s.title};
    final padding =
        (widget.padding ?? EdgeInsets.symmetric(horizontal: kito.spacing.md))
            .resolve(Directionality.of(context));

    final slivers = <Widget>[
      SliverToBoxAdapter(child: SizedBox(height: kito.spacing.sm)),
      SliverPadding(
        padding: EdgeInsets.only(left: padding.left, right: padding.right),
        sliver: SliverToBoxAdapter(
          child: _TypingRow(
            users: typing,
            style: widget.style,
            isGroup: isGroup,
          ),
        ),
      ),
      for (final section in timeline.sections.reversed)
        SliverPadding(
          key: _sectionKeys.putIfAbsent(section.id, GlobalKey.new),
          padding: EdgeInsets.only(left: padding.left, right: padding.right),
          sliver: _SectionList(
            section: section,
            itemBuilder: (row) => _row(row, isGroup: isGroup),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: padding.top)),
    ];

    final selected =
        _selectedId == null ? null : widget.controller.byId(_selectedId!);
    final selectedPosition = selected == null
        ? null
        : _positionOf(selected.id, timeline) ?? KitoChatGroupPosition.single;

    return Stack(key: _stackKey, children: [
      Positioned.fill(
        child: KitoChatWallpaperView(
            wallpaper: widget.wallpaper, tint: widget.tint),
      ),
      Column(children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (_) {
                  if (_selectedId != null) setState(() => _selectedId = null);
                  return false;
                },
                child: CustomScrollView(
                  controller: _scroll,
                  reverse: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: slivers,
                ),
              ),
            ),
            PositionedDirectional(
              top: kito.spacing.sm,
              start: 0,
              end: 0,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedOpacity(
                    opacity: _floatingVisible ? 1 : 0,
                    duration: KitoMotion.of(context, kito.motion.medium),
                    child: Center(
                      child: _floatingTitle == null
                          ? const SizedBox.shrink()
                          : KitoChatDatePill(_floatingTitle!),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: kito.spacing.lg,
              bottom: kito.spacing.md,
              child: _ScrollButton(
                visible: !_atBottom,
                unseen: _unseen,
                tint: widget.tint,
                onTap: _scrollToBottom,
              ),
            ),
          ]),
        ),
        if (widget.showsComposer)
          KitoChatComposer(
            key: _composerKey,
            onSend: _send,
            replyTo: _replyTo,
            onCancelReply: () => setState(() => _replyTo = null),
            placeholder: widget.placeholder,
            tint: widget.tint,
            onAttach: widget.onAttach,
            recorder: widget.recorder,
          ),
      ]),
      if (selected != null && _selectedRect != null)
        Positioned.fill(
          child: KitoChatReactionOverlay(
            key: ValueKey(selected.id),
            bubbleRect: _selectedRect!,
            bubble: _bubble(selected, selectedPosition!, isGroup: isGroup),
            isOutgoing: selected.author.id == widget.currentUser.id,
            selectedEmoji: selected.reactionOf(widget.currentUser.id),
            tint: widget.tint,
            onReact: (e) => _react(selected.id, e),
            onReply: () => _reply(selected),
            onCopy:
                selected.copyableText == null ? null : () => _copy(selected),
            onDelete: () => _delete(selected.id),
            onDismiss: () => setState(() => _selectedId = null),
          ),
        ),
      if (_viewer != null)
        Positioned.fill(
          child: KitoChatImageViewer(
            image: _viewer!.image,
            sourceRect: _viewer!.rect,
            onClose: () => setState(() => _viewer = null),
          ),
        ),
    ]);
  }

  KitoChatGroupPosition? _positionOf(String id, KitoChatTimeline timeline) {
    for (final s in timeline.sections) {
      for (final r in s.rows) {
        if (r is KitoChatTimelineMessage && r.message.id == id) {
          return r.position;
        }
      }
    }
    return null;
  }
}

/// One day's rows, newest at the bottom, its separator above them (the list is reversed).
class _SectionList extends StatelessWidget {
  const _SectionList({required this.section, required this.itemBuilder});
  final KitoChatTimelineSection section;
  final Widget Function(KitoChatTimelineRow row) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final rows = section.rows.reversed.toList();
    final count = rows.length + 1;
    final index = {for (var i = 0; i < rows.length; i++) rows[i].id: i};
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == rows.length) {
            return KitoChatDateSeparator(section.title,
                key: ValueKey('sep-${section.id}'));
          }
          return KeyedSubtree(
              key: ValueKey('row-${rows[i].id}'), child: itemBuilder(rows[i]));
        },
        childCount: count,
        findChildIndexCallback: (key) {
          if (key is ValueKey<String>) {
            final v = key.value;
            if (v == 'sep-${section.id}') return rows.length;
            if (v.startsWith('row-')) return index[v.substring(4)];
          }
          return null;
        },
      ),
    );
  }
}

/// Springs a new row in from its author's side; collapses a deleted one.
class _Entry extends StatefulWidget {
  const _Entry({
    required this.animate,
    required this.removing,
    required this.fromEnd,
    required this.child,
  });
  final bool animate;
  final bool removing;
  final bool fromEnd;
  final Widget child;

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 460), value: 1);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.value = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate && _c.value == 0 && !_c.isAnimating) {
      if (context.reduceMotion) {
        _c.duration = const Duration(milliseconds: 200);
      }
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    final spring = context.kito.motion.spring;
    final child = AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        if (t >= 1) return child!;
        final s = reduce ? 1.0 : spring.transform(t);
        final align = widget.fromEnd
            ? AlignmentDirectional.bottomEnd
            : AlignmentDirectional.bottomStart;
        return Opacity(
          opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
          child: Transform.translate(
            offset: Offset(0, reduce ? 0 : 24 * (1 - s)),
            child: Transform.scale(
              scale: reduce ? 1 : 0.6 + 0.4 * s,
              alignment: align.resolve(Directionality.of(context)),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
    return AnimatedSize(
      duration: kitoChatSizeDuration(
          KitoMotion.of(context, const Duration(milliseconds: 220))),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: widget.removing
          ? const SizedBox(width: double.infinity)
          : AnimatedOpacity(
              opacity: widget.removing ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: child,
            ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow(
      {required this.users, required this.style, required this.isGroup});
  final List<KitoChatUser> users;
  final KitoChatBubbleStyle style;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final locale = KitoChatStrings.localeOf(context);
    final dur = KitoMotion.of(context, kito.motion.medium);
    return AnimatedSize(
      duration: kitoChatSizeDuration(dur),
      curve: kito.motion.standard,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: dur,
        switchInCurve:
            context.reduceMotion ? Curves.easeOut : kito.motion.spring,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: context.reduceMotion
              ? child
              : ScaleTransition(
                  scale: Tween(begin: 0.6, end: 1.0).animate(a),
                  alignment: AlignmentDirectional.bottomStart
                      .resolve(Directionality.of(context)),
                  child: child),
        ),
        child: users.isEmpty
            ? const SizedBox(key: ValueKey('none'), width: double.infinity)
            : Padding(
                key: const ValueKey('typing'),
                padding: EdgeInsets.only(top: kito.spacing.sm),
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (isGroup) ...[
                    KitoChatAvatar(users.first,
                        size: 28, showsOnlineStatus: false),
                    SizedBox(width: kito.spacing.sm - 2),
                  ],
                  KitoChatTypingIndicator(
                    style: style,
                    semanticLabel: KitoChatDateFormat.typingText(
                        [for (final u in users) u.firstName],
                        locale: locale),
                  ),
                  const Spacer(),
                ]),
              ),
      ),
    );
  }
}

class _ScrollButton extends StatelessWidget {
  const _ScrollButton({
    required this.visible,
    required this.unseen,
    required this.onTap,
    this.tint,
  });
  final bool visible;
  final int unseen;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = KitoChatAccent.of(context, tint);
    final dur = KitoMotion.of(context, kito.motion.medium);
    final label = unseen > 0
        ? KitoChatStrings.of(context, 'scrollToLatestNew', {'n': unseen})
        : KitoChatStrings.of(context, 'scrollToLatest');
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: dur,
        child: AnimatedScale(
          scale: visible ? 1 : 0.5,
          duration: dur,
          curve: kito.motion.spring,
          child: visible
              ? Semantics(
                  button: true,
                  label: label,
                  onTap: onTap,
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      onTap: onTap,
                      child: KitoPressable(
                        scale: 0.9,
                        child: SizedBox(
                          width: 48,
                          height: 54,
                          child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: kito.colors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: kito.colors.border
                                            .withValues(alpha: 0.5),
                                        width: 0.5),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 26, color: kito.colors.onSurface),
                                ),
                                Positioned(
                                  top: 0,
                                  child: AnimatedScale(
                                    scale: unseen > 0 ? 1 : 0,
                                    duration: dur,
                                    curve: kito.motion.spring,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                          minWidth: 20, minHeight: 20),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: accent.tint,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unseen > 99 ? '99+' : '$unseen',
                                        textScaler: TextScaler.noScaling,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accent.onTint,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: 48, height: 54),
        ),
      ),
    );
  }
}
