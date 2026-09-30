// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'indicators.dart';
import 'models.dart';
import 'motion.dart';
import 'strings.dart';
import 'timeline.dart';
import 'waveform.dart';

/// One message in a conversation: avatar, bubble, time and receipts, with tap to show the
/// time, long-press for reactions and a swipe toward the trailing edge to reply.
class KitoChatMessageRow extends StatefulWidget {
  /// Creates a row around [bubble].
  const KitoChatMessageRow({
    super.key,
    required this.message,
    required this.bubble,
    required this.isOutgoing,
    this.position = KitoChatGroupPosition.single,
    this.showsAvatar = false,
    this.isTimeRevealed = false,
    this.isLifted = false,
    this.isHighlighted = false,
    this.tint,
    this.onTap,
    this.onLongPress,
    this.onReply,
    this.onRetry,
    this.onReact,
    this.onCopy,
    this.onDelete,
    this.avatarSize = 28,
  });

  /// The message.
  final KitoChatMessage message;

  /// The bubble to show.
  final Widget bubble;

  /// Whether it's yours.
  final bool isOutgoing;

  /// Its place in a run.
  final KitoChatGroupPosition position;

  /// Leave room for (and at the end of a run, draw) the author's avatar.
  final bool showsAvatar;

  /// Show the time under the bubble.
  final bool isTimeRevealed;

  /// Hide the bubble while a lifted copy is shown above everything.
  final bool isLifted;

  /// Flash a tinted wash — after jumping to a quoted message.
  final bool isHighlighted;

  /// Overrides the primary colour.
  final Color? tint;

  /// Called on tap.
  final VoidCallback? onTap;

  /// Called on long press with the bubble's rect on screen.
  final ValueChanged<Rect>? onLongPress;

  /// Called when swiped far enough, or from the screen-reader action.
  final VoidCallback? onReply;

  /// Called from the "Not delivered" footer.
  final VoidCallback? onRetry;

  /// Screen-reader "React with a heart".
  final VoidCallback? onReact;

  /// Screen-reader "Copy".
  final VoidCallback? onCopy;

  /// Screen-reader "Delete".
  final VoidCallback? onDelete;

  /// The avatar's diameter.
  final double avatarSize;

  @override
  State<KitoChatMessageRow> createState() => _KitoChatMessageRowState();
}

class _KitoChatMessageRowState extends State<KitoChatMessageRow>
    with SingleTickerProviderStateMixin {
  final _bubbleKey = GlobalKey();
  double _drag = 0;
  double _swipe = 0;
  bool _swiping = false;
  bool _passed = false;
  late final AnimationController _settle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350))
    ..addListener(() {
      setState(() => _swipe = _settleFrom * (1 - _settle.value));
    });
  double _settleFrom = 0;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _dragStart(DragStartDetails d) {
    _settle.stop();
    _drag = 0;
    _swiping = false;
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (widget.onReply == null) return;
    _drag += d.delta.dx * (context.isRtl ? -1 : 1);
    if (!_swiping) {
      if (_drag <= 0) return;
      _swiping = true;
    }
    final next = KitoChatSwipeReply.offset(_drag);
    final passed = next >= KitoChatSwipeReply.threshold;
    if (passed && !_passed) HapticFeedback.lightImpact();
    setState(() {
      _swipe = next;
      _passed = passed;
    });
  }

  void _dragEnd([DragEndDetails? d]) {
    if (_passed) widget.onReply?.call();
    _swiping = false;
    _passed = false;
    _settleFrom = _swipe;
    if (_swipe == 0) return;
    if (context.reduceMotion) {
      setState(() => _swipe = 0);
    } else {
      _settle
        ..duration = const Duration(milliseconds: 350)
        ..forward(from: 0);
    }
  }

  Rect _bubbleRect() {
    final box = _bubbleKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return Rect.zero;
  }

  String _label(BuildContext context) {
    final locale = KitoChatStrings.localeOf(context);
    final m = widget.message;
    final who = widget.isOutgoing
        ? KitoChatStrings.lookup('you', locale)
        : m.author.name;
    final time = KitoChatDateFormat.time(m.date, locale: locale);
    var label = '$who: ${m.previewText(locale)}, $time';
    if (m.replyTo != null) {
      label += ', ${KitoChatStrings.lookup('replyingToShort', locale, {
            'name': m.replyTo!.authorName
          })}';
    }
    if (m.reactions.isNotEmpty) {
      final list = m.reactions.map((r) => '${r.emoji} ${r.count}').join(', ');
      label +=
          ', ${KitoChatStrings.lookup('reactions', locale, {'list': list})}';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final m = widget.message;
    if (m.isSystem) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: kito.spacing.sm),
        child: MergeSemantics(child: widget.bubble),
      );
    }
    final rtl = context.isRtl;
    final showsFooter = widget.isTimeRevealed ||
        m.status == KitoChatMessageStatus.failed ||
        (widget.isOutgoing && widget.position.isGroupEnd);
    final progress = KitoChatSwipeReply.progress(_swipe);
    final accent = kito.accent(widget.tint);
    final keepsChildren =
        m.content is KitoChatVoiceContent || m.content is KitoChatImageContent;
    final locale = KitoChatStrings.localeOf(context);

    Widget bubble = KeyedSubtree(key: _bubbleKey, child: widget.bubble);
    bubble = Opacity(opacity: widget.isLifted ? 0 : 1, child: bubble);
    bubble = Semantics(
      container: true,
      label: _label(context),
      value: widget.isOutgoing ? m.status.label(locale) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () => widget.onLongPress!(_bubbleRect()),
      customSemanticsActions: {
        if (widget.onReply != null)
          CustomSemanticsAction(label: KitoChatStrings.lookup('reply', locale)):
              widget.onReply!,
        if (widget.onReact != null)
          CustomSemanticsAction(
                  label: KitoChatStrings.lookup('reactHeart', locale)):
              widget.onReact!,
        if (widget.onCopy != null)
          CustomSemanticsAction(label: KitoChatStrings.lookup('copy', locale)):
              widget.onCopy!,
        if (widget.onDelete != null)
          CustomSemanticsAction(
                  label: KitoChatStrings.lookup('delete', locale)):
              widget.onDelete!,
      },
      child: keepsChildren ? bubble : ExcludeSemantics(child: bubble),
    );
    bubble = GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!(_bubbleRect());
            },
      child: bubble,
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.isOutgoing) const SizedBox(width: 52),
        if (widget.showsAvatar) ...[
          SizedBox.square(
            dimension: widget.avatarSize,
            child: widget.position.isGroupEnd
                ? KitoChatAvatar(m.author,
                    size: widget.avatarSize, showsOnlineStatus: false)
                : null,
          ),
          SizedBox(width: kito.spacing.sm - 2),
        ],
        Expanded(
          child: Align(
            alignment: widget.isOutgoing
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: bubble,
          ),
        ),
        if (!widget.isOutgoing) const SizedBox(width: 52),
      ],
    );

    final swipeable = Stack(clipBehavior: Clip.none, children: [
      PositionedDirectional(
        start: 0,
        top: 0,
        bottom: 0,
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: Center(
              child: Transform.translate(
                offset: Offset(
                    (_swipe.clamp(0.0, KitoChatSwipeReply.threshold) / 2 - 18) *
                        (rtl ? -1 : 1),
                    0),
                child: Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * progress,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: kito.colors.surfaceMuted,
                          shape: BoxShape.circle),
                      child: AnimatedScale(
                        scale: _passed ? 1.2 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: kito.motion.spring,
                        child: Icon(Icons.reply_rounded,
                            size: 16,
                            color: _passed
                                ? accent
                                : kito.colors.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Transform.translate(
          offset: Offset(_swipe * (rtl ? -1 : 1), 0), child: row),
    ]);

    return AnimatedContainer(
      duration: KitoMotion.of(context, kito.motion.slow),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(
          top: widget.position.isGroupStart ? kito.spacing.sm : 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: widget.isHighlighted ? 0.14 : 0),
        borderRadius: BorderRadius.circular(kito.radii.lg),
      ),
      child: Column(
        crossAxisAlignment: widget.isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: widget.onReply == null ? null : _dragStart,
            onHorizontalDragUpdate: widget.onReply == null ? null : _dragUpdate,
            onHorizontalDragEnd: widget.onReply == null ? null : _dragEnd,
            onHorizontalDragCancel: widget.onReply == null ? null : _dragEnd,
            child: swipeable,
          ),
          AnimatedSize(
            duration: kitoChatSizeDuration(
                KitoMotion.of(context, kito.motion.medium)),
            curve: kito.motion.standard,
            alignment: AlignmentDirectional.topStart,
            child: showsFooter
                ? Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: (widget.showsAvatar
                              ? widget.avatarSize + kito.spacing.sm - 2
                              : 0) +
                          kito.spacing.xs,
                      end: kito.spacing.xs,
                      top: 3,
                    ),
                    child: _footer(context, accent),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, Color accent) {
    final kito = context.kito;
    final m = widget.message;
    final locale = KitoChatStrings.localeOf(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (widget.isTimeRevealed) ...[
        Text(
          KitoChatDateFormat.time(m.date, locale: locale),
          style: kito.typography.caption.copyWith(
            color: kito.colors.onSurface.withValues(alpha: 0.5),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(width: kito.spacing.xs),
      ],
      if (widget.isOutgoing) ...[
        if (m.status == KitoChatMessageStatus.failed && widget.onRetry != null)
          Flexible(
              child: Semantics(
            button: true,
            label: KitoChatStrings.lookup('retryLabel', locale),
            onTap: widget.onRetry,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onRetry,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text(
                        KitoChatStrings.lookup('retry', locale),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: kito.typography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: kito.colors.danger),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.refresh_rounded,
                        size: 14, color: kito.colors.danger),
                    SizedBox(width: kito.spacing.xs),
                  ]),
                ),
              ),
            ),
          )),
        KitoChatStatusTicks(m.status, tint: widget.tint),
      ],
    ]);
  }
}

/// The capsule between days: "Today", "Yesterday", "Monday".
class KitoChatDateSeparator extends StatelessWidget {
  /// Creates a separator.
  const KitoChatDateSeparator(this.title, {super.key});

  /// The day.
  final String title;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: kito.spacing.sm),
        child: Center(child: KitoChatDatePill(title)),
      ),
    );
  }
}

/// The frosted capsule a day's title sits in.
class KitoChatDatePill extends StatelessWidget {
  /// Creates a pill.
  const KitoChatDatePill(this.title, {super.key});

  /// The text.
  final String title;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: kito.spacing.md, vertical: kito.spacing.xs + 1),
      decoration: BoxDecoration(
        color: kito.colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(kito.radii.pill),
        border: Border.all(
            color: kito.colors.border.withValues(alpha: 0.4), width: 0.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Text(
        title,
        style: kito.typography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: kito.colors.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// "3 unread messages" between two tinted hairlines.
class KitoChatUnreadDivider extends StatelessWidget {
  /// Creates the divider.
  const KitoChatUnreadDivider({super.key, required this.count, this.tint});

  /// How many unread messages follow.
  final int count;

  /// Overrides the primary colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = kito.accent(tint);
    final line = Expanded(
        child: Container(height: 1, color: accent.withValues(alpha: 0.35)));
    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: kito.spacing.md),
        child: Row(children: [
          line,
          SizedBox(width: kito.spacing.sm),
          Text(
            count == 1
                ? KitoChatStrings.of(context, 'unread1')
                : KitoChatStrings.of(context, 'unreadMany', {'n': count}),
            style: kito.typography.caption
                .copyWith(fontWeight: FontWeight.w600, color: accent),
          ),
          SizedBox(width: kito.spacing.sm),
          line,
        ]),
      ),
    );
  }
}
