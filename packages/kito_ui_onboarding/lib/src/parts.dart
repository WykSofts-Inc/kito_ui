// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'style.dart';

/// A colour that reads on [fill].
Color kitoOnboardingReadableOn(Color fill) =>
    ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0B0B0F);

/// One onboarding page on its own: background, artwork and text in the style's layout, with
/// room left at the top and bottom for the flow's floating controls. [KitoOnboarding] builds
/// these; use one directly for a preview or a single promotional screen.
class KitoOnboardingPageView extends StatelessWidget {
  /// Creates a page.
  const KitoOnboardingPageView({
    super.key,
    required this.page,
    this.style = const KitoOnboardingStyle(),
    this.isCurrent = true,
    this.topInset = 0,
    this.bottomInset = 0,
    this.motionEnabled = true,
    this.parallax = 0,
  });

  /// What to show.
  final KitoOnboardingPage page;

  /// The layout and motion to use.
  final KitoOnboardingStyle style;

  /// The text rises in when this turns true.
  final bool isCurrent;

  /// Room kept clear at the top.
  final double topInset;

  /// Room kept clear at the bottom.
  final double bottomInset;

  /// Allows ambient and entrance motion.
  final bool motionEnabled;

  /// How far the artwork lags (and the background leads), for the parallax transition.
  final double parallax;

  /// The text colour a page uses in [layout].
  static Color foregroundFor(KitoOnboardingPage page,
          KitoOnboardingLayout layout, KitoTheme theme) =>
      page.foreground ??
      (layout == KitoOnboardingLayout.fullBleed
          ? Colors.white
          : theme.colors.onBackground);

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final foreground = foregroundFor(page, style.layout, theme);
    final accent = page.accent ?? theme.colors.primary;
    final cardForeground = style.cardForeground ?? theme.colors.onSurface;
    final pad = theme.spacing.xl;

    Widget artwork({double? maxHeight}) => _ArtworkView(
          artwork: page.artwork,
          accent: accent,
          motion: style.artworkMotion,
          isCurrent: isCurrent,
          motionEnabled: motionEnabled,
          parallax: parallax,
          maxHeight: maxHeight,
        );

    Widget text(
            {required bool centered,
            required Color color,
            TextStyle? titleStyle}) =>
        _TextBlock(
          page: page,
          centered: centered,
          color: color,
          accent: style.layout == KitoOnboardingLayout.fullBleed
              ? color.withValues(alpha: 0.85)
              : accent,
          titleStyle: titleStyle,
          isCurrent: isCurrent,
          motionEnabled: motionEnabled,
        );

    final display = theme.typography.display;
    final title = theme.typography.display.copyWith(fontSize: 30);

    final Widget content = switch (style.layout) {
      KitoOnboardingLayout.centered => Padding(
          padding: EdgeInsets.fromLTRB(pad, topInset, pad, bottomInset),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: artwork(maxHeight: 280)),
            SizedBox(height: pad),
            text(centered: true, color: foreground, titleStyle: title),
          ]),
        ),
      KitoOnboardingLayout.heroTop => Padding(
          padding: EdgeInsets.fromLTRB(pad, topInset, pad, bottomInset),
          child: Column(children: [
            Expanded(child: Center(child: artwork())),
            SizedBox(height: pad),
            text(centered: false, color: foreground, titleStyle: title),
          ]),
        ),
      KitoOnboardingLayout.fullBleed => Padding(
          padding: EdgeInsets.fromLTRB(pad, topInset, pad, bottomInset),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (page.artwork is! KitoOnboardingNoArtwork) ...[
                Flexible(
                  child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: artwork(maxHeight: 160)),
                ),
                SizedBox(height: theme.spacing.lg),
              ],
              text(centered: false, color: foreground, titleStyle: display),
            ],
          ),
        ),
      KitoOnboardingLayout.card => Column(children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, topInset, pad, pad),
              child: Center(child: artwork()),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: style.cardColor ?? theme.colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(36)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(pad, theme.spacing.md, pad, bottomInset),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: ShapeDecoration(
                      color: cardForeground.withValues(alpha: 0.15),
                      shape: const StadiumBorder()),
                ),
                SizedBox(height: theme.spacing.lg),
                text(centered: true, color: cardForeground, titleStyle: title),
              ]),
            ),
          ),
        ]),
      KitoOnboardingLayout.textFirst => Padding(
          padding: EdgeInsets.fromLTRB(
              pad, topInset + theme.spacing.md, pad, bottomInset),
          child: Column(children: [
            text(centered: false, color: foreground, titleStyle: display),
            SizedBox(height: pad),
            Expanded(child: Center(child: artwork())),
          ]),
        ),
      KitoOnboardingLayout.split => LayoutBuilder(
          builder: (context, box) => Column(children: [
            SizedBox(
              height: box.maxHeight * 0.55,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(36)),
                child: Stack(fit: StackFit.expand, children: [
                  if (page.background == null)
                    ColoredBox(color: accent.withValues(alpha: 0.12)),
                  if (page.background != null)
                    _Background(
                        background: page.background!, parallax: parallax),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, topInset, pad, pad),
                    child: Center(child: artwork()),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, bottomInset),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: text(
                        centered: false,
                        color: page.foreground ?? theme.colors.onBackground,
                        titleStyle: title),
                  ),
                ),
              ),
            ),
          ]),
        ),
    };

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ClipRect(
        child: Stack(fit: StackFit.expand, children: [
          if (page.background != null &&
              style.layout != KitoOnboardingLayout.split)
            _Background(background: page.background!, parallax: parallax),
          if (style.layout == KitoOnboardingLayout.fullBleed)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x59000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
          content,
        ]),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.background, required this.parallax});

  final KitoBackground background;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final surface = KitoSurface(
        background: background, radius: 0, child: const SizedBox.expand());
    if (parallax == 0) return surface;
    // Leads the page a little, scaled up so its edges never show.
    return Transform.translate(
      offset: Offset(-parallax * 160 / 110, 0),
      child: Transform.scale(scale: 1.3, child: surface),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.page,
    required this.centered,
    required this.color,
    required this.accent,
    required this.isCurrent,
    required this.motionEnabled,
    this.titleStyle,
  });

  final KitoOnboardingPage page;
  final bool centered;
  final Color color;
  final Color accent;
  final bool isCurrent;
  final bool motionEnabled;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final align = centered ? TextAlign.center : TextAlign.start;
    Widget rise(Widget child, double delay) => KitoOnboardingRiseIn(
        visible: isCurrent, delay: delay, enabled: motionEnabled, child: child);
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (page.eyebrow != null)
            rise(
                Padding(
                  padding: EdgeInsets.only(bottom: theme.spacing.sm),
                  child: Text(page.eyebrow!.toUpperCase(),
                      textAlign: align,
                      style: theme.typography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: accent)),
                ),
                0.02),
          rise(
              Semantics(
                header: true,
                child: Text(page.title,
                    textAlign: align,
                    style: (titleStyle ?? theme.typography.title)
                        .copyWith(color: color)),
              ),
              0.06),
          SizedBox(height: theme.spacing.sm),
          rise(
              Text(page.message,
                  textAlign: align,
                  style: theme.typography.body
                      .copyWith(color: color.withValues(alpha: 0.72))),
              0.12),
          if (page.bullets.isNotEmpty) ...[
            SizedBox(height: theme.spacing.md),
            for (var i = 0; i < page.bullets.length; i++)
              rise(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(Icons.check_circle_rounded,
                              size: 20, color: accent),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(page.bullets[i],
                              style:
                                  theme.typography.body.copyWith(color: color)),
                        ),
                      ],
                    ),
                  ),
                  0.18 + i * 0.06),
          ],
        ],
      ),
    );
  }
}

/// Fades and lifts [child] in, [delay] seconds after [visible] turns true.
///
/// Internal to the kit; not exported.
class KitoOnboardingRiseIn extends StatefulWidget {
  /// Creates the effect.
  const KitoOnboardingRiseIn({
    super.key,
    required this.visible,
    required this.child,
    this.delay = 0,
    this.enabled = true,
  });

  /// Rises in when this turns true; hides again when false.
  final bool visible;

  /// What rises.
  final Widget child;

  /// Seconds to wait first.
  final double delay;

  /// Off shows the child as is.
  final bool enabled;

  @override
  State<KitoOnboardingRiseIn> createState() => _KitoOnboardingRiseInState();
}

class _KitoOnboardingRiseInState extends State<KitoOnboardingRiseIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 550));
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(KitoOnboardingRiseIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible ||
        oldWidget.enabled != widget.enabled) {
      _apply();
    }
  }

  void _apply() {
    // A timer, not Future.delayed, so a newer state or dispose can cancel it.
    _delay?.cancel();
    if (!widget.enabled) {
      _c.value = 1;
    } else if (!widget.visible) {
      _c.value = 0;
    } else {
      _delay = Timer(Duration(milliseconds: (widget.delay * 1000).round()),
          () => _c.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
        parent: _c, curve: const KitoSpringCurve(damping: 0.85));
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: _c.value,
        child: Transform.translate(
            offset: Offset(0, 18 * (1 - curve.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

class _ArtworkView extends StatefulWidget {
  const _ArtworkView({
    required this.artwork,
    required this.accent,
    required this.motion,
    required this.isCurrent,
    required this.motionEnabled,
    required this.parallax,
    this.maxHeight,
  });

  final KitoOnboardingArtwork artwork;
  final Color accent;
  final KitoOnboardingArtworkMotion motion;
  final bool isCurrent;
  final bool motionEnabled;
  final double parallax;
  final double? maxHeight;

  @override
  State<_ArtworkView> createState() => _ArtworkViewState();
}

class _ArtworkViewState extends State<_ArtworkView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_ArtworkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion ||
        oldWidget.motionEnabled != widget.motionEnabled) {
      _c.stop();
      _c.value = 0;
      _start();
    }
    if (widget.motion == KitoOnboardingArtworkMotion.bounce &&
        widget.motionEnabled &&
        widget.isCurrent &&
        !oldWidget.isCurrent) {
      _c.duration = const Duration(milliseconds: 680);
      _c.forward(from: 0);
    }
  }

  void _start() {
    if (!widget.motionEnabled) return;
    switch (widget.motion) {
      case KitoOnboardingArtworkMotion.float:
        _c.duration = const Duration(milliseconds: 2400);
        _c.repeat(reverse: true);
      case KitoOnboardingArtworkMotion.pulse:
        _c.duration = const Duration(milliseconds: 1600);
        _c.repeat(reverse: true);
      case KitoOnboardingArtworkMotion.bounce:
      case KitoOnboardingArtworkMotion.none:
        break;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _content(BuildContext context) {
    switch (widget.artwork) {
      case KitoOnboardingIconArtwork(:final icon):
        return LayoutBuilder(builder: (context, box) {
          final side = [
            box.maxWidth,
            box.maxHeight,
            widget.maxHeight ?? 220.0,
            220.0,
          ].reduce(math.min);
          return Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                widget.accent.withValues(alpha: 0.18),
                widget.accent.withValues(alpha: 0.04),
              ]),
            ),
            child: Icon(icon, size: side * 0.48, color: widget.accent),
          );
        });
      case KitoOnboardingImageArtwork(:final image, :final fit):
        return ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: widget.maxHeight ?? double.infinity),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image(
              image: image,
              fit: fit,
              frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
                opacity: sync || frame != null ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                child: child,
              ),
              errorBuilder: (context, error, stack) => Icon(
                  Icons.image_not_supported_rounded,
                  size: 48,
                  color: widget.accent.withValues(alpha: 0.5)),
            ),
          ),
        );
      case KitoOnboardingCustomArtwork(:final builder):
        return ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: widget.maxHeight ?? double.infinity),
          child: Builder(builder: builder),
        );
      case KitoOnboardingNoArtwork():
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Transform.translate(
        offset: Offset(widget.parallax, 0),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_c.value);
            return switch (widget.motion) {
              KitoOnboardingArtworkMotion.float =>
                Transform.translate(offset: Offset(0, -12 * t), child: child),
              KitoOnboardingArtworkMotion.pulse =>
                Transform.scale(scale: 1 + 0.06 * t, child: child),
              KitoOnboardingArtworkMotion.bounce =>
                Transform.scale(scale: _bounce(_c.value), child: child),
              KitoOnboardingArtworkMotion.none => child!,
            };
          },
          child: _content(context),
        ),
      ),
    );
  }

  /// Up to 1.14 quickly, then a springy settle back to 1.
  static double _bounce(double t) {
    if (t <= 0 || t >= 1) return 1;
    if (t < 0.26) return 1 + 0.14 * Curves.easeOut.transform(t / 0.26);
    final settle =
        const KitoSpringCurve(damping: 0.45).transform((t - 0.26) / 0.74);
    return 1 + 0.14 * (1 - settle);
  }
}

/// A tappable region with button semantics, keyboard activation and the Kito press shrink.
///
/// Internal to the kit; not exported.
class KitoOnboardingTap extends StatelessWidget {
  /// Creates it.
  const KitoOnboardingTap({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.pressEffect = true,
  });

  /// What's tappable.
  final Widget child;

  /// Called on tap; null disables it.
  final VoidCallback? onTap;

  /// Replaces the label built from the child's text.
  final String? semanticLabel;

  /// Shrinks while pressed.
  final bool pressEffect;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    Widget body = child;
    if (pressEffect) body = KitoPressable(enabled: enabled, child: body);
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        onTap: onTap,
        excludeSemantics: semanticLabel != null,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          actions: {
            ActivateIntent:
                CallbackAction<ActivateIntent>(onInvoke: (_) => onTap?.call()),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: onTap,
            child: body,
          ),
        ),
      ),
    );
  }
}

/// The capsule primary button. Internal to the kit; not exported.
class KitoOnboardingPrimaryButton extends StatelessWidget {
  /// Creates it.
  const KitoOnboardingPrimaryButton({
    super.key,
    required this.title,
    required this.fullWidth,
    required this.busy,
    required this.accent,
    required this.onAccent,
    required this.onTap,
  });

  /// The text.
  final String title;

  /// Stretches across.
  final bool fullWidth;

  /// Shows a spinner instead of the text.
  final bool busy;

  /// The fill.
  final Color accent;

  /// The text colour.
  final Color onAccent;

  /// Called on tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final duration = KitoMotion.of(context, theme.motion.medium);
    return KitoOnboardingTap(
      onTap: busy ? null : onTap,
      semanticLabel: title,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: fullWidth ? double.infinity : null,
        constraints: const BoxConstraints(minHeight: 54),
        padding: EdgeInsets.symmetric(
            horizontal: fullWidth ? 16 : theme.spacing.xl, vertical: 14),
        alignment: fullWidth ? Alignment.center : null,
        decoration:
            ShapeDecoration(color: accent, shape: const StadiumBorder()),
        child: AnimatedSwitcher(
          duration: duration,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: busy
              ? SizedBox(
                  key: const ValueKey('busy'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: onAccent),
                )
              : Text(title,
                  key: ValueKey(title),
                  textAlign: TextAlign.center,
                  style: theme.typography.button.copyWith(color: onAccent)),
        ),
      ),
    );
  }
}

/// A round Next button whose ring fills with progress; on the last page it stretches into the
/// full-width "Get started" button. Internal to the kit; not exported.
class KitoOnboardingRingButton extends StatelessWidget {
  /// Creates it.
  const KitoOnboardingRingButton({
    super.key,
    required this.isLast,
    required this.progress,
    required this.accent,
    required this.onAccent,
    required this.fullWidth,
    required this.labels,
    required this.onTap,
  });

  /// On the last page.
  final bool isLast;

  /// How full the ring is, 0–1.
  final double progress;

  /// The fill.
  final Color accent;

  /// The icon and text colour.
  final Color onAccent;

  /// The width to stretch to on the last page.
  final double fullWidth;

  /// The words.
  final KitoOnboardingLabels labels;

  /// Called on tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final duration = KitoMotion.of(context, const Duration(milliseconds: 500));
    // No overshoot here: the button stretches to the full width.
    final curve = context.reduceMotion ? Curves.easeInOut : Curves.easeOutCubic;
    return KitoOnboardingTap(
      onTap: onTap,
      semanticLabel: isLast ? labels.getStarted : labels.next,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, p, _) => CustomPaint(
          painter: isLast ? null : _RingPainter(progress: p, color: accent),
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            width: isLast ? fullWidth : 70,
            height: isLast ? 56 : 70,
            padding: EdgeInsets.all(isLast ? 0 : 7),
            child: DecoratedBox(
              decoration:
                  ShapeDecoration(color: accent, shape: const StadiumBorder()),
              child: Center(
                child: AnimatedSwitcher(
                  duration: duration,
                  child: isLast
                      ? Text(labels.getStarted,
                          key: const ValueKey('last'),
                          maxLines: 1,
                          style:
                              theme.typography.button.copyWith(color: onAccent))
                      : Icon(Icons.arrow_forward_rounded,
                          key: const ValueKey('next'),
                          size: 22,
                          color: onAccent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = size.shortestSide / 2 - 1.5;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: 0.2);
    canvas.drawCircle(rect.center, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: rect.center, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      track
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// The position indicator in any [KitoOnboardingIndicator] style. It's read as "Page 2 of 4"
/// and announces changes.
class KitoOnboardingIndicatorView extends StatelessWidget {
  /// Creates an indicator.
  const KitoOnboardingIndicatorView({
    super.key,
    required this.style,
    required this.count,
    required this.current,
    required this.accent,
    required this.foreground,
    this.label = _defaultLabel,
  });

  static String _defaultLabel(int page, int count) => 'Page $page of $count';

  /// Capsules, dots, numbered, progress bar or none.
  final KitoOnboardingIndicator style;

  /// How many pages.
  final int count;

  /// The current page's index.
  final int current;

  /// The current page's colour.
  final Color accent;

  /// The base colour for the other pages.
  final Color foreground;

  /// How it's read, from a 1-based page and the count.
  final String Function(int page, int count) label;

  @override
  Widget build(BuildContext context) {
    if (style == KitoOnboardingIndicator.none || count <= 0) {
      return const SizedBox.shrink();
    }
    final theme = context.kito;
    final duration = KitoMotion.of(context, const Duration(milliseconds: 350));
    final curve = context.reduceMotion
        ? Curves.easeInOut
        : const KitoSpringCurve(damping: 0.8);
    final Widget body = switch (style) {
      KitoOnboardingIndicator.capsules => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: duration,
                curve: curve,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 22 : 7,
                height: 7,
                decoration: ShapeDecoration(
                  color: i == current
                      ? accent
                      : foreground.withValues(alpha: 0.25),
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
      KitoOnboardingIndicator.dots => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                child: AnimatedContainer(
                  duration: duration,
                  curve: curve,
                  width: i == current ? 10 : 7,
                  height: i == current ? 10 : 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == current
                        ? accent
                        : foreground.withValues(alpha: 0.25),
                  ),
                ),
              ),
          ],
        ),
      KitoOnboardingIndicator.numbered => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: duration,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.5), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              ),
              child: Text('${current + 1}',
                  key: ValueKey(current),
                  style: theme.typography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            Text(' / $count',
                style: theme.typography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground.withValues(alpha: 0.5),
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      KitoOnboardingIndicator.progressBar => Row(children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: duration,
                height: 3,
                decoration: ShapeDecoration(
                  color: i <= current
                      ? accent
                      : foreground.withValues(alpha: 0.22),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ]),
      KitoOnboardingIndicator.none => const SizedBox.shrink(),
    };
    return Semantics(
      liveRegion: true,
      label: label(current + 1, count),
      excludeSemantics: true,
      child: body,
    );
  }
}
