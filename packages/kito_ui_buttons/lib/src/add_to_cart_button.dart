// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'button_motion.dart';
import 'button_primitives.dart';
import 'button_strings.dart';
import 'button_theme.dart';
import 'button_types.dart';
import 'flight.dart';
import 'kito_button.dart';

/// Choreographed add-to-cart animations in the spirit of the popular Lottie buttons, drawn
/// natively from one timeline.
enum KitoAddToCartAnimation {
  /// The label slides away, a cart rolls in, the product drops into it, the cart rolls off and
  /// "Added ✓" appears.
  rollingCart('Rolling cart', 0.5, Duration(milliseconds: 1800)),

  /// The product falls into the cart icon, which squashes and bounces; a dot badge pops.
  dropIn('Drop in', 0.45, Duration(milliseconds: 1300)),

  /// The button squeezes into a circle with a spinner, a tick draws with a burst of particles,
  /// then it expands back.
  morphCircle('Morph to circle', 0.62, Duration(milliseconds: 1900)),

  /// The plus spins into a tick while particles fly outward.
  burst('Burst', 0.35, Duration(milliseconds: 1300)),

  /// The button flips over to reveal the added state.
  flip('Flip', 0.5, Duration(milliseconds: 1300)),

  /// The success colour sweeps across and a tick draws itself.
  fillSweep('Fill sweep', 0.5, Duration(milliseconds: 1300)),

  /// The cart jumps, a plus falls in, the cart wiggles and a "1" badge pops.
  bounceCart('Bounce cart', 0.45, Duration(milliseconds: 1300));

  const KitoAddToCartAnimation(
      this.title, this.landingPoint, this.defaultDuration);

  /// A human-readable name, for pickers and galleries.
  final String title;

  /// The fraction of the timeline at which the item lands (the badge bumps, flights launch).
  final double landingPoint;

  /// The tuned timeline length.
  final Duration defaultDuration;
}

/// An add-to-cart button with a built-in choreography.
///
/// The timeline is time-based like a Lottie file, so it plays the same whether [onPressed]
/// returns at once or after a second. If it throws, the button shakes and resets.
///
/// ```dart
/// KitoAddToCartButton(
///   animation: KitoAddToCartAnimation.rollingCart,
///   onPressed: () => cart.add(product),
///   onAdded: () => setState(() => count++),      // at the landing moment
///   flight: KitoFlightRequest(to: 'cart', builder: (_) => Image.asset(product.image)),
/// )
/// ```
class KitoAddToCartButton extends StatefulWidget {
  /// Creates an add-to-cart button.
  const KitoAddToCartButton({
    super.key,
    required this.onPressed,
    this.label,
    this.addedLabel,
    this.animation = KitoAddToCartAnimation.rollingCart,
    this.variant = KitoButtonVariant.primary,
    this.size = KitoButtonSize.medium,
    this.expand = false,
    this.tint,
    this.duration,
    this.hold = const Duration(seconds: 1),
    this.haptics = true,
    this.onAdded,
    this.flight,
    this.onError,
    this.semanticLabel,
  });

  /// Called on tap; may return a [Future]. Null disables the button.
  final KitoButtonAction? onPressed;

  /// The idle title; "Add to cart" (localised) when null.
  final String? label;

  /// The title once added; "Added" (localised) when null.
  final String? addedLabel;

  /// Which choreography plays.
  final KitoAddToCartAnimation animation;

  /// Colours: primary, tonal, outlined and ghost all work.
  final KitoButtonVariant variant;

  /// Metrics.
  final KitoButtonSize size;

  /// Fill the available width.
  final bool expand;

  /// Replaces the theme's brand colour.
  final Color? tint;

  /// The timeline length; each animation has a tuned default.
  final Duration? duration;

  /// How long the added state stays before fading back.
  final Duration hold;

  /// Tap, landing and error haptics.
  final bool haptics;

  /// Called at the landing moment — the natural place to bump a cart count.
  final VoidCallback? onAdded;

  /// Also fly something from this button to an anchor when the item lands.
  final KitoFlightRequest? flight;

  /// Called when [onPressed] throws.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// What screen readers announce; the label when null.
  final String? semanticLabel;

  @override
  State<KitoAddToCartButton> createState() => _KitoAddToCartButtonState();
}

class _KitoAddToCartButtonState extends State<KitoAddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline = AnimationController(vsync: this);
  bool _playing = false;
  bool _pressed = false;
  double _contentOpacity = 1;
  int _shakes = 0;
  Timer? _landingTimer;
  final Set<Timer> _waits = {};

  @override
  void dispose() {
    _landingTimer?.cancel();
    for (final t in _waits) {
      t.cancel();
    }
    _timeline.dispose();
    super.dispose();
  }

  /// A delay that is cancelled (and never completes) if the button goes away.
  Future<void> _wait(Duration d) {
    final done = Completer<void>();
    late final Timer timer;
    timer = Timer(d, () {
      _waits.remove(timer);
      done.complete();
    });
    _waits.add(timer);
    return done.future;
  }

  Future<void> _play() async {
    if (_playing || widget.onPressed == null) return;
    final reduce = context.reduceMotion;
    setState(() {
      _playing = true;
      _pressed = false;
    });
    if (widget.haptics) HapticFeedback.lightImpact();

    final total = reduce
        ? const Duration(milliseconds: 350)
        : widget.duration ?? widget.animation.defaultDuration;
    final Future<void> run;
    if (reduce) {
      // Reduce Motion: crossfade straight to the added state instead of playing the timeline.
      setState(() => _contentOpacity = 0);
      run = _wait(const Duration(milliseconds: 160)).then((_) async {
        if (!mounted) return;
        _timeline.value = 1;
        setState(() => _contentOpacity = 1);
        await _wait(total - const Duration(milliseconds: 160));
      });
    } else {
      _timeline.duration = total;
      run = _timeline.forward(from: 0).orCancel.catchError((Object _) {});
    }

    final landing = reduce
        ? const Duration(milliseconds: 200)
        : total * widget.animation.landingPoint;
    _landingTimer?.cancel();
    _landingTimer = Timer(landing, _land);

    try {
      await widget.onPressed!();
      await run;
      if (!mounted) return;
      await _wait(widget.hold);
    } catch (error, stack) {
      widget.onError?.call(error, stack);
      _landingTimer?.cancel();
      if (!mounted) return;
      _timeline.stop();
      setState(() => _shakes++);
      if (widget.haptics) HapticFeedback.heavyImpact();
    }
    await _reset();
  }

  void _land() {
    if (!mounted || !_playing) return;
    if (widget.haptics) HapticFeedback.mediumImpact();
    widget.flight?.launch(context);
    widget.onAdded?.call();
  }

  Future<void> _reset() async {
    if (!mounted) return;
    setState(() => _contentOpacity = 0);
    await _wait(const Duration(milliseconds: 160));
    if (!mounted) return;
    _timeline.value = 0;
    setState(() {
      _contentOpacity = 1;
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final theme = KitoButtonTheme.of(context);
    final motion = theme.motionFor(context);
    final reduce = context.reduceMotion;
    final enabled = widget.onPressed != null;
    final interactive = enabled && !_playing;
    final label =
        widget.label ?? KitoButtonStrings.of(context, 'cart.addToCart');
    final added =
        widget.addedLabel ?? KitoButtonStrings.of(context, 'cart.added');
    final colors =
        theme.colorsFor(widget.variant, kito, tintOverride: widget.tint);
    final palette = theme.resolve(kito);
    final material =
        Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);

    Widget body = AnimatedBuilder(
      animation: _timeline,
      builder: (context, _) => KitoAddToCartChoreography(
        progress: _timeline.value,
        animation: widget.animation,
        label: label,
        addedLabel: added,
        size: widget.size,
        textStyle: theme.textStyleFor(widget.size),
        colors: colors,
        successColor: palette.success,
        shape: theme.shape,
        borderWidth: theme.borderWidth,
        expand: widget.expand,
        badgeText: material?.formatDecimal(1) ?? '1',
      ),
    );

    body = AnimatedOpacity(
      opacity: _contentOpacity,
      duration: const Duration(milliseconds: 150),
      child: body,
    );

    body = AnimatedScale(
      scale: _pressed && interactive && !reduce ? theme.pressedScale : 1,
      duration: _pressed ? motion.pressDuration : motion.releaseDuration,
      curve: _pressed ? Curves.easeOut : motion.pressCurve,
      child: body,
    );

    body = AnimatedOpacity(
      opacity: enabled ? 1 : theme.disabledOpacity,
      duration: motion.pressDuration,
      child: body,
    );

    if (widget.size.isCompact) {
      body = ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Center(widthFactor: 1, heightFactor: 1, child: body),
      );
    }

    void setPressed(bool v) {
      if (_pressed != v) setState(() => _pressed = v);
    }

    body = FocusableActionDetector(
      enabled: interactive,
      mouseCursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      actions: {
        ActivateIntent:
            CallbackAction<ActivateIntent>(onInvoke: (_) => _play()),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: interactive ? (_) => setPressed(true) : null,
        onTapUp: interactive ? (_) => setPressed(false) : null,
        onTapCancel: () => setPressed(false),
        onTap: interactive ? _play : null,
        child: body,
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: interactive,
      label: widget.semanticLabel ?? label,
      value: _playing ? KitoButtonStrings.of(context, 'cart.adding') : null,
      liveRegion: _playing,
      onTap: interactive ? _play : null,
      child: KitoButtonShake(
        trigger: _shakes,
        duration: motion.shakeDuration,
        child: ExcludeSemantics(child: body),
      ),
    );
  }
}

/// Draws one frame of a [KitoAddToCartAnimation] at [progress] (0–1). Public so you can scrub
/// it in a gallery or drive it from your own controller.
class KitoAddToCartChoreography extends StatelessWidget {
  /// Creates a frame.
  const KitoAddToCartChoreography({
    super.key,
    required this.progress,
    required this.animation,
    required this.label,
    required this.addedLabel,
    required this.colors,
    required this.successColor,
    this.size = KitoButtonSize.medium,
    this.textStyle,
    this.shape = KitoButtonShape.capsule,
    this.borderWidth = 1.5,
    this.expand = false,
    this.badgeText = '1',
  });

  /// 0–1 through the timeline.
  final double progress;

  /// Which choreography.
  final KitoAddToCartAnimation animation;

  /// The idle title.
  final String label;

  /// The added title.
  final String addedLabel;

  /// The variant's resting colours.
  final KitoButtonColors colors;

  /// The success accent.
  final Color successColor;

  /// Metrics.
  final KitoButtonSize size;

  /// Title style; the size's when null.
  final TextStyle? textStyle;

  /// Outline.
  final KitoButtonShape shape;

  /// Outline width.
  final double borderWidth;

  /// Fill the available width.
  final bool expand;

  /// The number on the bounce-cart badge.
  final String badgeText;

  double get _icon => size.iconSize + 2;

  static double _o(double v) => v.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final style =
        (textStyle ?? size.textStyle).copyWith(color: colors.foreground);
    final sizer = Container(
      constraints: BoxConstraints(minHeight: size.height),
      width: expand ? double.infinity : null,
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: size.horizontalPadding + 4),
      alignment: expand ? Alignment.center : null,
      child: Stack(alignment: Alignment.center, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox.square(dimension: _icon * 1.5),
          const SizedBox(width: 10),
          Flexible(child: Text(label, maxLines: 1, style: style)),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox.square(dimension: _icon * 1.5),
          const SizedBox(width: 10),
          Flexible(child: Text(addedLabel, maxLines: 1, style: style)),
        ]),
      ]),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: 0, child: ExcludeSemantics(child: sizer)),
        Positioned.fill(
          child: LayoutBuilder(builder: (context, c) {
            final frame = _Frame(this, c.maxWidth, c.maxHeight, dir, style);
            return switch (animation) {
              KitoAddToCartAnimation.rollingCart => frame.rollingCart(),
              KitoAddToCartAnimation.dropIn => frame.dropIn(),
              KitoAddToCartAnimation.morphCircle => frame.morphCircle(),
              KitoAddToCartAnimation.burst => frame.burst(),
              KitoAddToCartAnimation.flip => frame.flip(),
              KitoAddToCartAnimation.fillSweep => frame.fillSweep(),
              KitoAddToCartAnimation.bounceCart => frame.bounceCart(),
            };
          }),
        ),
      ],
    );
  }
}

/// Everything one frame needs, with the drawing helpers.
class _Frame {
  _Frame(this.c, this.w, this.h, this.dir, this.style);
  final KitoAddToCartChoreography c;
  final double w;
  final double h;
  final double dir;
  final TextStyle style;

  double get p => c.progress;
  double get icon => c._icon;
  KitoButtonColors get colors => c.colors;
  BorderRadius get radius => c.shape.radiusFor(h);

  static double seg(double p, double a, double b) =>
      KitoButtonEase.segment(p, a, b);
  static double o(double v) => KitoAddToCartChoreography._o(v);

  Widget chrome({Color? fill, Color? border, BorderRadius? r}) {
    final b = border ?? colors.border;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill ?? colors.background,
        borderRadius: r ?? radius,
        border: b.a > 0 ? Border.all(color: b, width: c.borderWidth) : null,
      ),
    );
  }

  Widget label(String text, {Color? color}) => Text(text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: color == null ? style : style.copyWith(color: color));

  Widget symbol(IconData data, {Color? color, double scale = 1}) =>
      Icon(data, size: icon * scale, color: color ?? colors.foreground);

  Widget check(double t,
          {Color? color, double lineWidth = 2.5, double? side}) =>
      KitoButtonCheckmark(
          progress: t,
          color: color ?? colors.foreground,
          size: side ?? icon,
          strokeWidth: lineWidth);

  Widget get product => Container(
        width: icon * 0.55,
        height: icon * 0.55,
        decoration: BoxDecoration(
          color: colors.foreground,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
              color: colors.background.withValues(alpha: 0.6), width: 1),
        ),
      );

  Widget swapLabels(double swap, {double dy = 8, Color? from, Color? to}) =>
      Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Opacity(
              opacity: o(1 - swap),
              child: Transform.translate(
                  offset: Offset(0, -dy * swap),
                  child: label(c.label, color: from))),
          Opacity(
              opacity: o(swap),
              child: Transform.translate(
                  offset: Offset(0, dy * (1 - swap)),
                  child: label(c.addedLabel, color: to))),
        ],
      );

  Widget centred(Widget row) => Padding(
        padding: EdgeInsetsDirectional.symmetric(
            horizontal: c.size.horizontalPadding),
        child: Center(child: row),
      );

  Color variantAccent(Color accent) =>
      colors.background.a == 0 ? accent.withValues(alpha: 0.16) : accent;

  Color accentForeground(Color accent) =>
      colors.background.a == 0 ? accent : colors.foreground;

  Widget unbounded(Widget child) => OverflowBox(
      maxWidth: double.infinity, maxHeight: double.infinity, child: child);

  // 1. Rolling cart
  Widget rollingCart() {
    final labelOut = KitoButtonEase.outCubic(seg(p, 0, 0.15));
    final cartIn = KitoButtonEase.outCubic(seg(p, 0.08, 0.42));
    final cartOut = KitoButtonEase.inCubic(seg(p, 0.62, 0.85));
    final drop = KitoButtonEase.outBounce(seg(p, 0.34, 0.55));
    final added = KitoButtonEase.outBack(seg(p, 0.82, 1));
    final cartX = KitoButtonEase.lerp(-w / 2 - 30, 0, cartIn) +
        KitoButtonEase.lerp(0, w / 2 + 40, cartOut);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: chrome()),
        Opacity(
          opacity: o(1 - labelOut),
          child: Transform.translate(
            offset: Offset(0, -12 * labelOut),
            child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
              symbol(Icons.add_shopping_cart_rounded),
              const SizedBox(width: 8),
              Flexible(child: label(c.label)),
            ])),
          ),
        ),
        if (p > 0.05 && p < 0.9)
          Transform.translate(
            offset: Offset(cartX * dir, -1),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Transform.flip(
                    flipX: dir < 0,
                    child: symbol(Icons.shopping_cart_rounded, scale: 1.25)),
                if (p > 0.3 && p < 0.86)
                  Transform.translate(
                      offset: Offset(0, KitoButtonEase.lerp(-h * 0.9, 1, drop)),
                      child: product),
              ],
            ),
          ),
        Opacity(
          opacity: o(added),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - added)),
            child: Transform.scale(
              scale: 0.9 + 0.1 * added,
              child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
                check(seg(p, 0.84, 0.96)),
                const SizedBox(width: 8),
                Flexible(child: label(c.addedLabel)),
              ])),
            ),
          ),
        ),
      ]),
    );
  }

  // 2. Drop in
  Widget dropIn() {
    final fall = KitoButtonEase.inCubic(seg(p, 0.1, 0.42));
    final squash = KitoButtonEase.pulse(seg(p, 0.42, 0.6));
    final badge = KitoButtonEase.outBack(seg(p, 0.5, 0.75));
    final swap = KitoButtonEase.inOutCubic(seg(p, 0.55, 0.8));
    final hop = KitoButtonEase.pulse(seg(p, 0.55, 0.8));
    return ClipRRect(
      borderRadius: radius,
      child: Stack(children: [
        Positioned.fill(child: chrome()),
        Positioned.fill(
          child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox.square(
              dimension: icon * 1.4,
              child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -6 * hop),
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.diagonal3Values(
                            1 + 0.12 * squash, 1 - 0.18 * squash, 1),
                        child: symbol(Icons.shopping_cart_rounded, scale: 1.15),
                      ),
                    ),
                    if (p > 0.08 && p < 0.5)
                      Transform.translate(
                        offset: Offset(
                            0, KitoButtonEase.lerp(-h, -icon * 0.2, fall)),
                        child: Transform.scale(
                            scale: 1 - 0.35 * seg(p, 0.42, 0.5),
                            child: product),
                      ),
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Transform.scale(
                        scale: math.max(badge, 0),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: c.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: colors.background.a == 0
                                    ? const Color(0xFFFFFFFF)
                                    : colors.background,
                                width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(width: 10),
            Flexible(child: swapLabels(swap)),
          ])),
        ),
      ]),
    );
  }

  // 3. Morph to circle
  Widget morphCircle() {
    final collapse = KitoButtonEase.inOutCubic(seg(p, 0, 0.22));
    final expand = KitoButtonEase.outBack(seg(p, 0.84, 1), overshoot: 0.8);
    final spinnerOn = p > 0.18 && p < 0.62;
    final checkDraw = seg(p, 0.62, 0.78);
    final burstT = seg(p, 0.6, 0.9);
    final fillMix = seg(p, 0.6, 0.7);
    final width = KitoButtonEase.lerp(w, h, collapse) +
        KitoButtonEase.lerp(0, w - h, expand);
    final baseR = c.shape.cornerFor(h);
    final r = KitoButtonEase.lerp(baseR, h / 2, collapse) -
        KitoButtonEase.lerp(0, h / 2 - baseR, expand);
    final br = BorderRadius.circular(r.clamp(0, h / 2));
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: width.clamp(0, double.infinity),
          height: h,
          child: Stack(fit: StackFit.expand, children: [
            chrome(r: br),
            if (fillMix > 0)
              chrome(
                  r: br,
                  fill: variantAccent(c.successColor).withValues(
                      alpha: fillMix * variantAccent(c.successColor).a),
                  border: const Color(0x00000000)),
          ]),
        ),
        Opacity(
          opacity: o(1 - seg(p, 0, 0.12)),
          child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
            symbol(Icons.add_shopping_cart_rounded),
            const SizedBox(width: 8),
            Flexible(child: label(c.label)),
          ])),
        ),
        if (spinnerOn)
          Transform.rotate(
            angle: p * math.pi * 6 * dir,
            child: CustomPaint(
              size: Size.square(icon * 1.1),
              painter: _ProgressArcPainter(colors.foreground),
            ),
          ),
        unbounded(KitoButtonBurst(
            progress: burstT, color: c.successColor, radius: h * 0.9)),
        if (p > 0.62)
          Opacity(
            opacity: o(1 - expand),
            child: Transform.scale(
              scale: 1 + 0.15 * KitoButtonEase.pulse(seg(p, 0.75, 0.9)),
              child: check(checkDraw,
                  color: accentForeground(c.successColor),
                  lineWidth: 3,
                  side: icon * 1.2),
            ),
          ),
        Opacity(
          opacity: o(expand),
          child: Transform.scale(
            scale: 0.9 + 0.1 * expand,
            child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
              check(1, color: accentForeground(c.successColor), lineWidth: 3),
              const SizedBox(width: 8),
              Flexible(
                  child: label(c.addedLabel,
                      color: accentForeground(c.successColor))),
            ])),
          ),
        ),
      ],
    );
  }

  // 4. Burst
  Widget burst() {
    final spin = KitoButtonEase.outBack(seg(p, 0.15, 0.5));
    final burstT = seg(p, 0.3, 0.8);
    final swap = KitoButtonEase.inOutCubic(seg(p, 0.3, 0.6));
    final pulse = KitoButtonEase.pulse(seg(p, 0.25, 0.55));
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
          child: Transform.scale(scale: 1 + 0.04 * pulse, child: chrome())),
      Positioned.fill(
        child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox.square(
            dimension: icon * 1.3,
            child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: o(1 - seg(p, 0.3, 0.42)),
                    child: Transform.scale(
                      scale: 1 - 0.5 * seg(p, 0.3, 0.45),
                      child: Transform.rotate(
                          angle: math.pi / 2 * spin * dir,
                          child: symbol(Icons.add_rounded, scale: 1.1)),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8 + 0.2 * KitoButtonEase.outBack(seg(p, 0.4, 0.7)),
                    child: check(seg(p, 0.4, 0.62), lineWidth: 3),
                  ),
                  unbounded(KitoButtonBurst(
                      progress: burstT,
                      color: colors.foreground,
                      count: 12,
                      radius: icon * 1.9)),
                ]),
          ),
          const SizedBox(width: 10),
          Flexible(child: swapLabels(swap)),
        ])),
      ),
    ]);
  }

  // 5. Flip
  Widget flip() {
    final turn = KitoButtonEase.inOutCubic(seg(p, 0.05, 0.55));
    final angle = math.pi * turn;
    final showingBack = angle > math.pi / 2;
    final settle = KitoButtonEase.outBack(seg(p, 0.55, 0.8));
    final fg = accentForeground(c.successColor);
    final front = Stack(fit: StackFit.expand, children: [
      chrome(),
      centred(Row(mainAxisSize: MainAxisSize.min, children: [
        symbol(Icons.add_shopping_cart_rounded),
        const SizedBox(width: 8),
        Flexible(child: label(c.label)),
      ])),
    ]);
    final back = Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationX(math.pi),
      child: Stack(fit: StackFit.expand, children: [
        chrome(
            fill: variantAccent(c.successColor),
            border:
                colors.hasBorder ? c.successColor : const Color(0x00000000)),
        centred(Row(mainAxisSize: MainAxisSize.min, children: [
          Transform.scale(
              scale: 0.8 + 0.2 * settle,
              child: check(seg(p, 0.55, 0.75), color: fg, lineWidth: 3)),
          const SizedBox(width: 8),
          Flexible(child: label(c.addedLabel, color: fg)),
        ])),
      ]),
    );
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(angle),
      child: showingBack ? back : front,
    );
  }

  // 6. Fill sweep
  Widget fillSweep() {
    final sweep = KitoButtonEase.inOutCubic(seg(p, 0.05, 0.5));
    final checkDraw = seg(p, 0.5, 0.72);
    final swap = KitoButtonEase.inOutCubic(seg(p, 0.45, 0.7));
    final fg = accentForeground(c.successColor);
    final early = sweep > 0.5 ? fg : colors.foreground;
    return Stack(children: [
      Positioned.fill(child: chrome()),
      Positioned.fill(
        child: ClipRRect(
          borderRadius: radius,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
                width: w * sweep,
                height: h,
                child: ColoredBox(color: variantAccent(c.successColor))),
          ),
        ),
      ),
      Positioned.fill(
        child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox.square(
            dimension: icon * 1.2,
            child: Stack(alignment: Alignment.center, children: [
              Opacity(
                  opacity: o(1 - seg(p, 0.45, 0.55)),
                  child: symbol(Icons.add_shopping_cart_rounded, color: early)),
              check(checkDraw, color: fg, lineWidth: 3),
            ]),
          ),
          const SizedBox(width: 10),
          Flexible(
            child:
                Stack(alignment: AlignmentDirectional.centerStart, children: [
              Opacity(
                  opacity: o(1 - swap), child: label(c.label, color: early)),
              Opacity(
                opacity: o(swap),
                child: Transform.translate(
                    offset: Offset(6 * (1 - swap) * dir, 0),
                    child: label(c.addedLabel, color: fg)),
              ),
            ]),
          ),
        ])),
      ),
    ]);
  }

  // 7. Bounce cart
  Widget bounceCart() {
    final jump = KitoButtonEase.pulse(seg(p, 0.05, 0.4));
    final plusFall = KitoButtonEase.inCubic(seg(p, 0.15, 0.45));
    final ws = seg(p, 0.45, 0.8);
    final wiggle = math.sin(ws * math.pi * 3) * (1 - ws);
    final badge = KitoButtonEase.outBack(seg(p, 0.5, 0.75));
    final swap = KitoButtonEase.inOutCubic(seg(p, 0.55, 0.8));
    return Stack(children: [
      Positioned.fill(child: chrome()),
      Positioned.fill(
        child: centred(Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox.square(
            dimension: icon * 1.5,
            child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Transform.translate(
                    offset: Offset(0, -14 * jump),
                    child: Transform.rotate(
                      alignment: Alignment.bottomCenter,
                      angle: 10 * math.pi / 180 * wiggle,
                      child: symbol(Icons.shopping_cart_rounded, scale: 1.15),
                    ),
                  ),
                  if (p > 0.12 && p < 0.5)
                    Transform.translate(
                      offset: Offset(0,
                          KitoButtonEase.lerp(-h * 0.7, -icon * 0.2, plusFall)),
                      child: symbol(Icons.add_rounded, scale: 0.7),
                    ),
                  PositionedDirectional(
                    top: -4,
                    end: -6,
                    child: Transform.scale(
                      scale: math.max(badge, 0),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints:
                            const BoxConstraints(minWidth: 15, minHeight: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: c.successColor, shape: BoxShape.circle),
                        child: Text(c.badgeText,
                            style: const TextStyle(
                                fontSize: 9,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFFFFF))),
                      ),
                    ),
                  ),
                ]),
          ),
          const SizedBox(width: 10),
          Flexible(child: swapLabels(swap)),
        ])),
      ),
    ]);
  }
}

class _ProgressArcPainter extends CustomPainter {
  _ProgressArcPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      (Offset.zero & size).deflate(1.25),
      math.pi * 0.3,
      math.pi * 1.4,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter old) => old.color != color;
}
