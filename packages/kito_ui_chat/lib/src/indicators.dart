// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_loaders/kito_ui_loaders.dart';

import 'models.dart';
import 'motion.dart';
import 'strings.dart';
import 'style.dart';
import 'timeline.dart';

// MARK: - Typing indicator

/// Three hopping dots in an incoming bubble. Under Reduce Motion the dots fade in turn instead.
///
/// ```dart
/// if (isTyping) const KitoChatTypingIndicator(style: KitoChatBubbleStyle.imessage)
/// ```
class KitoChatTypingIndicator extends StatelessWidget {
  /// Creates a typing indicator.
  const KitoChatTypingIndicator({
    super.key,
    this.style = KitoChatBubbleStyle.modern,
    this.dotColor,
    this.semanticLabel,
  });

  /// The bubble style to match.
  final KitoChatBubbleStyle style;

  /// Dot colour; muted text colour when null.
  final Color? dotColor;

  /// What screen readers say; "Typing" when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final tail = style.tail != KitoChatBubbleTail.none;
    return Semantics(
      container: true,
      label: semanticLabel ?? KitoChatStrings.of(context, 'typing'),
      child: ExcludeSemantics(
        child: KitoChatBubbleBackground(
          style: style,
          isOutgoing: false,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: kito.spacing.md + 2 + (tail ? 3 : 0),
              end: kito.spacing.md + 2,
              top: kito.spacing.md,
              bottom: kito.spacing.md,
            ),
            child: KitoLoaderTypingIndicator(
              showBubble: false,
              dotColor: dotColor,
              dotSize: 8,
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Status ticks

/// A clock while sending, one tick when sent, two when delivered, two tinted when read, and a
/// red badge when it failed — each change animates.
class KitoChatStatusTicks extends StatelessWidget {
  /// Creates ticks for [status].
  const KitoChatStatusTicks(this.status, {super.key, this.tint, this.color});

  /// The status to show.
  final KitoChatMessageStatus status;

  /// The colour of read ticks; the primary colour when null.
  final Color? tint;

  /// The colour of the other states; faint text colour when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    final muted = color ?? kito.colors.onSurface.withValues(alpha: 0.45);
    final read = kito.accent(tint);
    final twoTicks = status == KitoChatMessageStatus.delivered ||
        status == KitoChatMessageStatus.read;
    final tickColor = status == KitoChatMessageStatus.read ? read : muted;
    final Widget glyph = switch (status) {
      KitoChatMessageStatus.sending => _Pulsing(
          key: const ValueKey('sending'),
          enabled: !reduce,
          child: Icon(Icons.schedule_rounded, size: 13, color: muted),
        ),
      KitoChatMessageStatus.failed => Icon(Icons.error_rounded,
          key: const ValueKey('failed'), size: 14, color: kito.colors.danger),
      _ => SizedBox(
          key: const ValueKey('ticks'),
          width: 19,
          height: 14,
          child: Stack(clipBehavior: Clip.none, children: [
            PositionedDirectional(
              start: 0,
              top: 0,
              child: _IconColor(
                color: tickColor,
                child: const Icon(Icons.check_rounded, size: 14),
              ),
            ),
            PositionedDirectional(
              start: 5,
              top: 0,
              child: AnimatedScale(
                scale: twoTicks ? 1 : 0.2,
                alignment: AlignmentDirectional.centerStart
                    .resolve(Directionality.of(context)),
                duration: KitoMotion.of(context, kito.motion.medium),
                curve: kito.motion.spring,
                child: AnimatedOpacity(
                  opacity: twoTicks ? 1 : 0,
                  duration: KitoMotion.of(context, kito.motion.fast),
                  child: _IconColor(
                    color: tickColor,
                    child: const Icon(Icons.check_rounded, size: 14),
                  ),
                ),
              ),
            ),
          ]),
        ),
    };
    return Semantics(
      container: true,
      label: status.label(KitoChatStrings.localeOf(context)),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 14,
          child: AnimatedSwitcher(
            duration: KitoMotion.of(context, kito.motion.medium),
            switchInCurve: reduce ? Curves.easeOut : kito.motion.spring,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: reduce
                  ? child
                  : ScaleTransition(
                      scale: Tween(begin: 0.5, end: 1.0).animate(animation),
                      child: child),
            ),
            child: glyph,
          ),
        ),
      ),
    );
  }
}

class _IconColor extends StatelessWidget {
  const _IconColor({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: KitoMotion.of(context, context.kito.motion.medium),
      builder: (context, c, child) =>
          IconTheme.merge(data: IconThemeData(color: c), child: child!),
      child: child,
    );
  }
}

class _Pulsing extends StatefulWidget {
  const _Pulsing({super.key, required this.enabled, required this.child});
  final bool enabled;
  final Widget child;

  @override
  State<_Pulsing> createState() => _PulsingState();
}

class _PulsingState extends State<_Pulsing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Pulsing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.enabled && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.enabled
      ? FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.35).animate(_c),
          child: widget.child)
      : widget.child;
}

// MARK: - Avatar

/// A round avatar — the photo if there is one, otherwise initials on a stable gradient — with
/// a pulsing green dot when the person is online.
class KitoChatAvatar extends StatelessWidget {
  /// Creates an avatar for [user].
  const KitoChatAvatar(this.user,
      {super.key, this.size = 40, this.showsOnlineStatus = true});

  /// Whose avatar.
  final KitoChatUser user;

  /// Its diameter.
  final double size;

  /// Show the online dot when [KitoChatUser.isOnline].
  final bool showsOnlineStatus;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final colors = KitoChatPalette.colorsFor(user);
    final online = showsOnlineStatus && user.isOnline;
    final dot = math.max(8.0, size * 0.28);
    return Semantics(
      container: true,
      image: true,
      label: online
          ? KitoChatStrings.of(context, 'nameOnline', {'name': user.name})
          : user.name,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(clipBehavior: Clip.none, children: [
            ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
                child: Stack(fit: StackFit.expand, children: [
                  Center(
                    child: Text(
                      user.initials,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.38,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                  if (user.avatar != null)
                    Image(
                      image: user.avatar!,
                      fit: BoxFit.cover,
                      frameBuilder: (context, child, frame, sync) =>
                          AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: sync
                            ? Duration.zero
                            : KitoMotion.of(context, kito.motion.medium),
                        child: child,
                      ),
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                ]),
              ),
            ),
            PositionedDirectional(
              end: -size * 0.02,
              bottom: -size * 0.02,
              child: AnimatedScale(
                scale: online ? 1 : 0,
                duration: KitoMotion.of(context, kito.motion.medium),
                curve: kito.motion.spring,
                child: _OnlineDot(
                  size: dot,
                  ring: kito.colors.background,
                  color: kito.colors.success,
                  pulse: online && !context.reduceMotion,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OnlineDot extends StatefulWidget {
  const _OnlineDot(
      {required this.size,
      required this.ring,
      required this.color,
      required this.pulse});
  final double size;
  final Color ring;
  final Color color;
  final bool pulse;

  @override
  State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat();
  }

  @override
  void didUpdateWidget(_OnlineDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_c.isAnimating) _c.repeat();
    if (!widget.pulse && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        border: Border.all(
            color: widget.ring, width: math.max(1.5, widget.size * 0.2)),
      ),
    );
    if (!widget.pulse) return core;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_c.value);
        return Stack(alignment: Alignment.center, children: [
          Transform.scale(
            scale: 1 + 0.9 * t,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.45 * (1 - t)),
              ),
            ),
          ),
          child!,
        ]);
      },
      child: core,
    );
  }
}

// MARK: - Header

/// The bar above a conversation: back, avatar, name and a subtitle that switches to
/// "Amani is typing…" while someone types.
///
/// ```dart
/// KitoChatHeader(user: amani, typingUsers: typing, onBack: () => Navigator.pop(context))
/// ```
class KitoChatHeader extends StatelessWidget {
  /// Creates a header.
  const KitoChatHeader({
    super.key,
    required this.user,
    this.title,
    this.typingUsers = const [],
    this.subtitle,
    this.tint,
    this.onBack,
    this.onCall,
    this.onVideo,
    this.onTap,
  });

  /// The other person (or the group).
  final KitoChatUser user;

  /// Shown instead of the user's name.
  final String? title;

  /// Who's typing now.
  final List<KitoChatUser> typingUsers;

  /// A line under the name — "last seen…"; "Online" is shown when the user is online.
  final String? subtitle;

  /// Overrides the primary colour.
  final Color? tint;

  /// Shows a back button.
  final VoidCallback? onBack;

  /// Shows a call button.
  final VoidCallback? onCall;

  /// Shows a video-call button.
  final VoidCallback? onVideo;

  /// Called when the avatar and name are tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final locale = KitoChatStrings.localeOf(context);
    final accent = kito.accent(tint);
    final typing = typingUsers.isNotEmpty;
    final String? line = typing
        ? KitoChatDateFormat.typingText(
            [for (final u in typingUsers) u.firstName], locale: locale)
        : (subtitle ??
            (user.isOnline ? KitoChatStrings.of(context, 'online') : null));
    Widget identity = Row(mainAxisSize: MainAxisSize.min, children: [
      KitoChatAvatar(user, size: 40),
      SizedBox(width: kito.spacing.sm + 2),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kito.typography.bodyEmphasized
                  .copyWith(color: kito.colors.onSurface),
            ),
            AnimatedSize(
              duration: kitoChatSizeDuration(
                  KitoMotion.of(context, kito.motion.medium)),
              curve: kito.motion.standard,
              alignment: AlignmentDirectional.topStart,
              child: AnimatedSwitcher(
                duration: KitoMotion.of(context, kito.motion.medium),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                            begin: context.reduceMotion
                                ? Offset.zero
                                : const Offset(0, 0.6),
                            end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: animation, curve: kito.motion.standard)),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.topStart,
                  children: [...previous, if (current != null) current],
                ),
                child: line == null
                    ? const SizedBox(key: ValueKey('none'), height: 0)
                    : Text(
                        line,
                        key: ValueKey(line),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kito.typography.caption.copyWith(
                          fontWeight:
                              typing ? FontWeight.w600 : FontWeight.w400,
                          color: typing
                              ? accent
                              : kito.colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ]);
    identity = MergeSemantics(child: identity);
    if (onTap != null) {
      identity = GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: identity);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kito.colors.surface.withValues(alpha: 0.94),
        border: Border(
            bottom: BorderSide(
                color: kito.colors.border.withValues(alpha: 0.6), width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
              horizontal: kito.spacing.sm, vertical: kito.spacing.xs),
          child: Row(children: [
            if (onBack != null)
              KitoChatIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: KitoChatStrings.of(context, 'back'),
                onPressed: onBack!,
                filled: false,
              ),
            if (onBack == null) SizedBox(width: kito.spacing.xs),
            Expanded(
              child: Align(
                  alignment: AlignmentDirectional.centerStart, child: identity),
            ),
            if (onVideo != null)
              KitoChatIconButton(
                icon: Icons.videocam_rounded,
                label: KitoChatStrings.of(context, 'video'),
                onPressed: onVideo!,
              ),
            if (onCall != null)
              KitoChatIconButton(
                icon: Icons.call_rounded,
                label: KitoChatStrings.of(context, 'call'),
                onPressed: onCall!,
              ),
          ]),
        ),
      ),
    );
  }
}

/// A 44-point round icon button with the Kito press feel, used across the chat kit.
class KitoChatIconButton extends StatelessWidget {
  /// Creates an icon button.
  const KitoChatIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.color,
    this.background,
    this.size = 38,
    this.iconSize = 18,
  });

  /// The glyph.
  final IconData icon;

  /// What screen readers say.
  final String label;

  /// Called on tap.
  final VoidCallback onPressed;

  /// Draw a muted circle behind the glyph.
  final bool filled;

  /// Glyph colour; the text colour when null.
  final Color? color;

  /// Circle colour; the muted surface when null.
  final Color? background;

  /// The visible circle's diameter (the tap target is at least 44).
  final double size;

  /// The glyph size.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: KitoPressable(
            scale: 0.9,
            child: SizedBox.square(
              dimension: math.max(44, size),
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: filled
                      ? BoxDecoration(
                          color: background ?? kito.colors.surfaceMuted,
                          shape: BoxShape.circle)
                      : null,
                  child: Icon(icon,
                      size: iconSize, color: color ?? kito.colors.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three small dots that hop in turn — the inline "typing" in a chat list row.
class KitoChatInlineTypingDots extends StatelessWidget {
  /// Creates inline dots.
  const KitoChatInlineTypingDots({super.key, this.color, this.size = 4});

  /// Dot colour; the primary colour when null.
  final Color? color;

  /// Each dot's diameter.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: KitoLoaderTypingIndicator(
          showBubble: false,
          dotSize: size,
          dotColor: color ?? context.kito.colors.primary,
        ),
      );
}
