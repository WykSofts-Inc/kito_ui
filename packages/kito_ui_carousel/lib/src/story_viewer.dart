// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'logic.dart';

/// A full-screen story viewer.
///
/// - Segmented progress bars along the top, one per story.
/// - Tap the trailing side for the next story, the leading side for the previous; hold anywhere
///   to pause.
/// - Swipe sideways to move between people, with a 3D cube turn. In right-to-left layouts the
///   next person comes in from the left and tapping the right side goes back.
/// - Swipe down to dismiss; the story shrinks away with your finger.
/// - A reply field and a like button with a heart burst.
///
/// ```dart
/// Navigator.of(context).push(PageRouteBuilder(
///   opaque: false,
///   pageBuilder: (context, _, __) => KitoStoryViewer(
///     userCount: friends.length,
///     initialUser: index,
///     segmentCount: (u) => friends[u].stories.length,
///     titleBuilder: (u) => friends[u].name,
///     storyBuilder: (context, u, s) => StoryPage(friends[u].stories[s]),
///     avatarBuilder: (context, u) => Avatar(friends[u]),
///     onDismiss: () => Navigator.of(context).pop(),
///   ),
/// ));
/// ```
///
/// Auto-advance pauses while a screen reader is running, while a finger is down and while you
/// type a reply; screen-reader users get Next story, Previous story, Like and Close actions.
/// With Reduce Motion on, people change with a slide instead of a cube.
class KitoStoryViewer extends StatefulWidget {
  /// Creates a viewer.
  const KitoStoryViewer({
    super.key,
    required this.userCount,
    required this.segmentCount,
    required this.titleBuilder,
    required this.storyBuilder,
    required this.onDismiss,
    this.avatarBuilder,
    this.subtitleBuilder,
    this.initialUser = 0,
    this.duration = const Duration(seconds: 5),
    this.showsReplyField = true,
    this.replyPlaceholder = 'Send message',
    this.tint,
    this.onSeen,
    this.onReply,
    this.onLike,
  });

  /// How many people's stories play, in order.
  final int userCount;

  /// How many stories person `user` has.
  final int Function(int user) segmentCount;

  /// The name in the header.
  final String Function(int user) titleBuilder;

  /// Builds story `segment` of person `user`; it fills the screen.
  final Widget Function(BuildContext context, int user, int segment)
      storyBuilder;

  /// Close the viewer: swipe down, the close button, or the last story ending.
  final VoidCallback onDismiss;

  /// The small picture in the header.
  final Widget Function(BuildContext context, int user)? avatarBuilder;

  /// A line under the name for a story, e.g. "2h".
  final String? Function(int user, int segment)? subtitleBuilder;

  /// The person to open on.
  final int initialUser;

  /// How long each story shows.
  final Duration duration;

  /// The reply field and like button along the bottom.
  final bool showsReplyField;

  /// The reply field's placeholder.
  final String replyPlaceholder;

  /// The like heart's colour; the theme's danger colour by default.
  final Color? tint;

  /// A story came on screen.
  final void Function(int user, int segment)? onSeen;

  /// A reply was sent.
  final void Function(int user, int segment, String text)? onReply;

  /// A story was liked (true) or unliked.
  final void Function(int user, int segment, bool liked)? onLike;

  @override
  State<KitoStoryViewer> createState() => _KitoStoryViewerState();
}

enum _Hold { press, typing, accessibility, closing }

enum _Axis { horizontal, vertical }

class _KitoStoryViewerState extends State<KitoStoryViewer>
    with TickerProviderStateMixin {
  late KitoStoryPlayback _playback = _makePlayback();
  final _holds = <_Hold>{};
  final _progress = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  // The cube: how far the faces have turned, in pages (layout direction; negative shows more
  // of the next person).
  late final AnimationController _cube =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _dismiss =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _fadeOut = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220));
  late final AnimationController _burst = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));

  final _reply = TextEditingController();
  final _replyFocus = FocusNode();
  final _liked = <(int, int)>{};
  bool _chromeHidden = false;
  bool _showsSent = false;
  bool _closing = false;
  Timer? _chromeTimer;
  Timer? _sentTimer;

  // Pointer tracking.
  int? _pointer;
  Offset _start = Offset.zero;
  Offset _translation = Offset.zero;
  Duration _downAt = Duration.zero;
  _Axis? _axis;
  VelocityTracker? _velocity;
  (int, int)? _lastSeen;

  KitoStoryPlayback _makePlayback() => KitoStoryPlayback(
        [for (var u = 0; u < widget.userCount; u++) widget.segmentCount(u)],
        startingUser: widget.initialUser,
      );

  @override
  void initState() {
    super.initState();
    _replyFocus.addListener(() => _hold(_Hold.typing, _replyFocus.hasFocus));
    _reply.addListener(() => setState(() {}));
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_playback.isFinished) {
        widget.onDismiss();
      } else {
        _reportSeen();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hold(_Hold.accessibility,
        MediaQuery.maybeAccessibleNavigationOf(context) ?? false);
  }

  @override
  void didUpdateWidget(KitoStoryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userCount != widget.userCount) {
      _playback = _makePlayback();
      _hold(_Hold.press, false);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cube.dispose();
    _dismiss.dispose();
    _fadeOut.dispose();
    _burst.dispose();
    _progress.dispose();
    _reply.dispose();
    _replyFocus.dispose();
    _chromeTimer?.cancel();
    _sentTimer?.cancel();
    super.dispose();
  }

  // MARK: Clock

  void _hold(_Hold reason, bool held) {
    if (held) {
      _holds.add(reason);
    } else {
      _holds.remove(reason);
    }
    if (_holds.isEmpty) {
      _playback.resume();
    } else {
      _playback.pause();
    }
    if (mounted) setState(() {});
  }

  void _tick(Duration elapsed) {
    final delta = elapsed - _last;
    _last = elapsed;
    if (_playback.isPaused || _playback.isFinished || _closing) return;
    final d = widget.duration;
    if (d <= Duration.zero ||
        _playback.progress + delta.inMicroseconds / d.inMicroseconds >= 1) {
      _advance();
    } else {
      _playback.tick(delta, d);
      _progress.value = _playback.progress;
    }
  }

  void _reportSeen() {
    final key = (_playback.user, _playback.segment);
    if (key == _lastSeen || _playback.isFinished) return;
    _lastSeen = key;
    widget.onSeen?.call(key.$1, key.$2);
  }

  void _after(KitoStoryPlaybackEvent event) {
    switch (event) {
      case KitoStoryPlaybackEvent.advancedUser:
        _turn(from: 1);
      case KitoStoryPlaybackEvent.wentBackUser:
        _turn(from: -1);
      case KitoStoryPlaybackEvent.finished:
        _close();
      default:
        break;
    }
    _progress.value = _playback.progress;
    _reportSeen();
    setState(() {});
  }

  /// The new person's face starts where it was ([from] pages away, plus any drag) and turns in.
  void _turn({required double from}) {
    final start = _cube.value + from;
    if (context.reduceMotion) {
      _cube.value = start;
      _cube.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    } else {
      _cube.value = start;
      _cube.animateTo(0,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic);
    }
  }

  void _advance() => _after(_playback.next());

  void _goBack() => _after(_playback.previous());

  void _toggleLike() {
    final key = (_playback.user, _playback.segment);
    final liked = !_liked.contains(key);
    setState(() {
      if (liked) {
        _liked.add(key);
      } else {
        _liked.remove(key);
      }
    });
    if (liked) {
      HapticFeedback.mediumImpact();
      _burst.forward(from: 0);
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onLike?.call(key.$1, key.$2, liked);
  }

  void _sendReply() {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    widget.onReply?.call(_playback.user, _playback.segment, text);
    _reply.clear();
    _replyFocus.unfocus();
    HapticFeedback.lightImpact();
    setState(() => _showsSent = true);
    _sentTimer?.cancel();
    _sentTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showsSent = false);
    });
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _hold(_Hold.closing, true);
    _dismiss.animateTo(math.max(_dismiss.value, 120),
        duration: const Duration(milliseconds: 220), curve: Curves.easeIn);
    _fadeOut.forward().whenComplete(() {
      if (mounted) widget.onDismiss();
    });
  }

  // MARK: Pointer

  bool get _rtl => context.isRtl;

  /// Physical distances in layout terms: negative is towards the leading edge (the next person).
  double _layout(double physical) => _rtl ? -physical : physical;

  void _down(PointerDownEvent e) {
    if (_pointer != null || _closing) return;
    _pointer = e.pointer;
    _start = e.position;
    _translation = Offset.zero;
    _downAt = e.timeStamp;
    _axis = null;
    _velocity = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.position);
    _cube.stop();
    _dismiss.stop();
    _replyFocus.unfocus();
    _hold(_Hold.press, true);
    _chromeTimer?.cancel();
    _chromeTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted && _pointer != null && _axis == null) {
        setState(() => _chromeHidden = true);
      }
    });
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    _velocity?.addPosition(e.timeStamp, e.position);
    _translation = e.position - _start;
    final t = _translation;
    if (_axis == null) {
      if (t.dx.abs() > 12 && t.dx.abs() > t.dy.abs()) {
        setState(() => _axis = _Axis.horizontal);
      } else if (t.dy > 12 && t.dy > t.dx.abs()) {
        setState(() => _axis = _Axis.vertical);
      }
    }
    final width = math.max(context.size?.width ?? 1, 1.0);
    switch (_axis) {
      case _Axis.horizontal:
        final dx = _layout(t.dx);
        final canMove =
            dx < 0 ? _playback.hasNextUser : _playback.hasPreviousUser;
        _cube.value = (canMove ? dx : dx * 0.22) / width;
      case _Axis.vertical:
        _dismiss.value = math.max(t.dy, 0);
      case null:
        break;
    }
  }

  void _up(PointerEvent e, {bool cancelled = false}) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _chromeTimer?.cancel();
    final held = e.timeStamp - _downAt;
    final axis = _axis;
    final velocity = _velocity?.getVelocity().pixelsPerSecond ?? Offset.zero;
    _axis = null;
    _hold(_Hold.press, false);
    if (_chromeHidden) setState(() => _chromeHidden = false);
    final size = context.size ?? const Size(390, 800);
    if (cancelled) {
      _settleCube();
      _settleDismiss();
      return;
    }
    switch (axis) {
      case null:
        if (held > const Duration(milliseconds: 300)) return;
        final box = context.findRenderObject() as RenderBox?;
        final local = box?.globalToLocal(e.position) ?? e.position;
        final x = _rtl ? size.width - local.dx : local.dx;
        if (x < size.width * 0.3) {
          _goBack();
        } else {
          _advance();
        }
      case _Axis.horizontal:
        final translation = _layout(_translation.dx);
        final v = _layout(velocity.dx);
        final threshold = size.width * 0.25;
        int? target;
        if (translation < -threshold || v < -700) {
          target = _playback.nextPlayableUser(_playback.user);
        } else if (translation > threshold || v > 700) {
          target = _playback.previousPlayableUser(_playback.user);
        }
        if (target != null) {
          final forward = target > _playback.user;
          _playback.jumpToUser(target);
          HapticFeedback.selectionClick();
          _turn(from: forward ? 1 : -1);
          _progress.value = 0;
          _reportSeen();
          setState(() {});
        } else {
          _settleCube();
        }
      case _Axis.vertical:
        if (_translation.dy > 130 || velocity.dy > 900) {
          _close();
        } else {
          _settleDismiss();
        }
    }
  }

  void _settleCube() => _cube.animateTo(0,
      duration: KitoMotion.of(context, const Duration(milliseconds: 380)),
      curve: Curves.easeOutCubic);

  void _settleDismiss() => _dismiss.animateTo(0,
      duration: KitoMotion.of(context, const Duration(milliseconds: 380)),
      curve: Curves.easeOutBack);

  // MARK: Build

  List<int> get _pageIndices => [
        if (_playback.previousPlayableUser(_playback.user) case final p?) p,
        _playback.user,
        if (_playback.nextPlayableUser(_playback.user) case final n?) n,
      ];

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final insets = MediaQuery.paddingOf(context);
    final heart = widget.tint ?? kito.colors.danger;
    final count = _playback.segmentCount;
    final hint = _rtl
        ? 'Tap the left side for the next story, the right for the previous. Hold to pause.'
        : 'Tap the right side for the next story, the left for the previous. Hold to pause.';

    final stage = LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final pages = _pageIndices;
      return Semantics(
        container: true,
        label:
            _playback.isFinished ? null : widget.titleBuilder(_playback.user),
        value: 'Story ${_playback.segment + 1} of $count',
        hint: hint,
        onTap: _advance,
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Next story'): _advance,
          const CustomSemanticsAction(label: 'Previous story'): _goBack,
          const CustomSemanticsAction(label: 'Like'): _toggleLike,
          const CustomSemanticsAction(label: 'Close'): _close,
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: (e) => _up(e, cancelled: true),
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _cube,
              builder: (context, _) => Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Faces further round paint first.
                  for (final u in pages.toList()
                    ..sort((a, b) => _faceProgress(b)
                        .abs()
                        .compareTo(_faceProgress(a).abs())))
                    Positioned.fill(
                      key: ValueKey('face-$u'),
                      child: _CubeFace(
                        progress: _faceProgress(u),
                        width: size.width,
                        rtl: _rtl,
                        cube: !context.reduceMotion,
                        child: _page(context, u, insets),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    final chromeVisible = !_chromeHidden && _axis != _Axis.horizontal;
    final body = Stack(children: [
      Positioned.fill(child: stage),
      Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: _HeartBurst(
                animation: _burst,
                color: heart,
                reduceMotion: context.reduceMotion),
          ),
        ),
      ),
      PositionedDirectional(
        top: insets.top + 14,
        end: kito.spacing.xs,
        child: AnimatedOpacity(
          opacity: chromeVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: _RoundIcon(
            icon: Icons.close_rounded,
            label: 'Close',
            onTap: _close,
          ),
        ),
      ),
      if (widget.showsReplyField)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedOpacity(
            opacity: chromeVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: _replyBar(context, insets.bottom, heart),
          ),
        ),
      Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: AnimatedScale(
              scale: _showsSent ? 1 : 0.8,
              duration: KitoMotion.of(context, kito.motion.medium),
              curve: kito.motion.spring,
              child: AnimatedOpacity(
                opacity: _showsSent ? 1 : 0,
                duration: KitoMotion.of(context, kito.motion.fast),
                child: Semantics(
                  liveRegion: true,
                  label: _showsSent ? 'Sent' : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: kito.spacing.lg, vertical: kito.spacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(kito.radii.pill),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.send_rounded,
                          size: 16, color: Colors.white),
                      SizedBox(width: kito.spacing.xs),
                      Text('Sent',
                          style: kito.typography.label
                              .copyWith(color: Colors.white)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([_dismiss, _fadeOut]),
        builder: (context, child) {
          final p = (_dismiss.value / 420).clamp(0.0, 1.0);
          final fade = 1 - _fadeOut.value;
          return Stack(children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black
                    .withValues(alpha: ((1 - p * 0.9) * fade).clamp(0.0, 1.0)),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(0, _dismiss.value),
                  child: Transform.scale(
                    scale: 1 - p * 0.22,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(kito.radii.lg + p * 28),
                      child: ColoredBox(color: Colors.black, child: child),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
        child: body,
      ),
    );
  }

  double _faceProgress(int user) {
    final rank = user < _playback.user ? -1 : (user > _playback.user ? 1 : 0);
    return rank + _cube.value;
  }

  Widget _page(BuildContext context, int user, EdgeInsets insets) {
    final kito = context.kito;
    final current = user == _playback.user;
    final count = math.max(widget.segmentCount(user), 0);
    final segment = current ? _playback.segment : 0;
    final shown = math.min(segment, math.max(count - 1, 0));
    final subtitle = widget.subtitleBuilder?.call(user, shown);
    return ColoredBox(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        AnimatedSwitcher(
          duration: KitoMotion.of(context, const Duration(milliseconds: 220)),
          child: KeyedSubtree(
            key: ValueKey((user, shown)),
            child: SizedBox.expand(
                child: widget.storyBuilder(context, user, shown)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: insets.top + 130,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x8C000000), Color(0x00000000)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: insets.bottom + 150,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x80000000)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: insets.top + kito.spacing.sm,
          child: AnimatedOpacity(
            opacity: _chromeHidden ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kito.spacing.md),
              child: Column(children: [
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, progress, _) => _StoryBars(
                    count: count,
                    fill: (i) {
                      if (user < _playback.user) return 1;
                      if (user > _playback.user) return 0;
                      return _playback.fill(i);
                    },
                  ),
                ),
                SizedBox(height: kito.spacing.md),
                Row(children: [
                  if (widget.avatarBuilder != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      child:
                          ClipOval(child: widget.avatarBuilder!(context, user)),
                    ),
                    SizedBox(width: kito.spacing.sm),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.titleBuilder(user),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kito.typography.label.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: kito.typography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.75)),
                          ),
                      ],
                    ),
                  ),
                  if (current && _playback.isPaused && _pointer != null) ...[
                    SizedBox(width: kito.spacing.sm),
                    Icon(Icons.pause_rounded,
                        size: 16, color: Colors.white.withValues(alpha: 0.85)),
                  ],
                  const SizedBox(width: 52),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _replyBar(BuildContext context, double bottomInset, Color heart) {
    final kito = context.kito;
    final liked = _liked.contains((_playback.user, _playback.segment));
    final empty = _reply.text.trim().isEmpty;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: kito.spacing.md,
        end: kito.spacing.md,
        top: kito.spacing.md,
        bottom: math.max(bottomInset, kito.spacing.md) + kito.spacing.xs,
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _reply,
            focusNode: _replyFocus,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendReply(),
            cursorColor: Colors.white,
            style: kito.typography.body.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.replyPlaceholder,
              hintStyle: kito.typography.body
                  .copyWith(color: Colors.white.withValues(alpha: 0.75)),
              filled: true,
              fillColor: Colors.white
                  .withValues(alpha: _replyFocus.hasFocus ? 0.12 : 0),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: kito.spacing.lg, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kito.radii.pill),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.55)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kito.radii.pill),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(width: kito.spacing.sm),
        AnimatedSwitcher(
          duration: KitoMotion.of(context, kito.motion.fast),
          transitionBuilder: (child, a) => ScaleTransition(
              scale: a, child: FadeTransition(opacity: a, child: child)),
          child: empty
              ? _RoundIcon(
                  key: ValueKey('like-$liked'),
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: liked ? heart : Colors.white,
                  size: 26,
                  label: liked ? 'Unlike' : 'Like',
                  onTap: _toggleLike,
                )
              : _RoundIcon(
                  key: const ValueKey('send'),
                  icon: Icons.send_rounded,
                  size: 22,
                  label: 'Send',
                  onTap: _sendReply,
                ),
        ),
      ]),
    );
  }
}

/// A white glyph with a 44-point target.
class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.size = 20,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: KitoPressable(
          scale: 0.85,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: size, color: color, shadows: const [
              Shadow(color: Color(0x55000000), blurRadius: 6),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The segmented bars along the top.
class _StoryBars extends StatelessWidget {
  const _StoryBars({required this.count, required this.fill});

  final int count;
  final double Function(int index) fill;

  @override
  Widget build(BuildContext context) {
    final n = math.max(count, 1);
    return Row(children: [
      for (var i = 0; i < n; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 2.5,
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(color: Colors.white.withValues(alpha: 0.32)),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: fill(i).clamp(0.0, 1.0),
                  child: const ColoredBox(color: Colors.white),
                ),
              ]),
            ),
          ),
        ),
      ],
    ]);
  }
}

/// One face of the cube: at 0 it faces you, at ±1 it has turned away round its shared edge.
class _CubeFace extends StatelessWidget {
  const _CubeFace({
    required this.progress,
    required this.width,
    required this.rtl,
    required this.cube,
    required this.child,
  });

  final double progress;
  final double width;
  final bool rtl;
  final bool cube;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress.abs() >= 0.999) {
      return Offstage(child: child);
    }
    final dir = rtl ? -1.0 : 1.0;
    final clamped = progress.clamp(-1.0, 1.0);
    final dx = progress * width * dir;
    if (!cube) {
      return Transform.translate(offset: Offset(dx, 0), child: child);
    }
    // A face to the trailing side hinges on its leading edge, and the other way round.
    final hingeOnLeft = (clamped > 0) == !rtl;
    final m = Matrix4.identity()
      ..translateByDouble(dx, 0, 0, 1)
      ..translateByDouble(hingeOnLeft ? 0.0 : width, 0, 0, 1)
      ..setEntry(3, 2, 0.0009)
      ..rotateY(-clamped * math.pi / 2 * dir)
      ..translateByDouble(hingeOnLeft ? 0.0 : -width, 0, 0, 1);
    return Transform(
      transform: m,
      child: Stack(fit: StackFit.expand, children: [
        child,
        IgnorePointer(
          child: ColoredBox(
              color: Colors.black.withValues(alpha: clamped.abs() * 0.45)),
        ),
      ]),
    );
  }
}

/// A big heart that pops, with a ring of small hearts flying out.
class _HeartBurst extends StatelessWidget {
  const _HeartBurst(
      {required this.animation,
      required this.color,
      required this.reduceMotion});

  final Animation<double> animation;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          if (t <= 0 || t >= 1) return const SizedBox.shrink();
          final opacity = t < 0.78 ? 1.0 : (1 - (t - 0.78) / 0.22);
          final pop = t < 0.3
              ? Curves.elasticOut.transform(t / 0.3) * 1.0
              : t < 0.78
                  ? 1.0
                  : 1 + 0.3 * ((t - 0.78) / 0.22);
          final spread = t < 0.08
              ? 0.0
              : Curves.easeOutCubic.transform(((t - 0.08) / 0.6).clamp(0, 1));
          return SizedBox.square(
            dimension: 320,
            child: Stack(alignment: Alignment.center, children: [
              if (!reduceMotion)
                for (var i = 0; i < 10; i++)
                  Transform.translate(
                    offset: Offset.fromDirection(i / 10 * 2 * math.pi,
                        (70 + 50 * spread + (i.isEven ? 16 : 0)) * spread),
                    child: Transform.scale(
                      scale: 1 - 0.5 * spread,
                      child: Opacity(
                        opacity: (opacity * (1 - spread * 0.7)).clamp(0.0, 1.0),
                        child: Icon(Icons.favorite_rounded,
                            size: i.isEven ? 18 : 12, color: color),
                      ),
                    ),
                  ),
              Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: reduceMotion ? 1 : math.max(pop, 0.3),
                  child: Icon(Icons.favorite_rounded,
                      size: 110,
                      color: color,
                      shadows: [
                        Shadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 24),
                      ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
