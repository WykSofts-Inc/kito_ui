// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'parts.dart';
import 'style.dart';

/// A paged onboarding flow. Pages fill the screen (backgrounds run under the status bar and
/// home indicator); Skip, Back, the indicator and the primary button float above them and
/// take on the current page's colours as you swipe.
///
/// ```dart
/// KitoOnboarding(
///   pages: const [
///     KitoOnboardingPage(
///       artwork: KitoOnboardingArtwork.icon(Icons.bolt_rounded),
///       title: 'Fast',
///       message: 'Everything loads instantly.',
///     ),
///     KitoOnboardingPage(
///       artwork: KitoOnboardingArtwork.icon(Icons.lock_rounded),
///       title: 'Secure',
///       message: 'Your data stays yours.',
///     ),
///   ],
///   onFinish: () => prefs.setBool('seenOnboarding', true),
/// )
/// ```
class KitoOnboarding extends StatefulWidget {
  /// Creates the flow. [pages] must not be empty.
  const KitoOnboarding({
    super.key,
    required this.pages,
    required this.onFinish,
    this.onSkip,
    this.controller,
    this.style = const KitoOnboardingStyle(),
    this.onPageChanged,
    this.onPermissionResult,
  }) : assert(pages.length > 0, 'KitoOnboarding needs at least one page');

  /// The pages, in order.
  final List<KitoOnboardingPage> pages;

  /// Called by "Get started" on the last page (and by Skip unless [onSkip] is set).
  final VoidCallback onFinish;

  /// Called by Skip; [onFinish] when null. Handy for telling skips from completions.
  final VoidCallback? onSkip;

  /// Moves the flow from code; one is made for you when null.
  final KitoOnboardingController? controller;

  /// How it looks and moves.
  final KitoOnboardingStyle style;

  /// Called with the new page index after each change.
  final ValueChanged<int>? onPageChanged;

  /// Called with a permission page's index and whether it was granted.
  final void Function(int page, bool granted)? onPermissionResult;

  @override
  State<KitoOnboarding> createState() => _KitoOnboardingState();
}

class _KitoOnboardingState extends State<KitoOnboarding> {
  KitoOnboardingController? _own;
  late KitoOnboardingController _controller;
  late PageController _pager;
  bool _busy = false;
  int _lastReported = -1;

  KitoOnboardingStyle get _style => widget.style;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? (_own = KitoOnboardingController());
    _attach();
    _pager = PageController(initialPage: _controller.page);
    _lastReported = _controller.page;
    _controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(KitoOnboarding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onController);
      _own?.dispose();
      _own = null;
      _controller = widget.controller ?? (_own = KitoOnboardingController());
      _controller.addListener(_onController);
    }
    _attach();
  }

  void _attach() => _controller.attach(
        widget.pages.length,
        () => widget.onFinish(),
        () => (widget.onSkip ?? widget.onFinish)(),
      );

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _own?.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _onController() {
    final page = _controller.page;
    if (page != _lastReported) {
      _lastReported = page;
      widget.onPageChanged?.call(page);
    }
    setState(() {});
    if (!_pager.hasClients) return;
    final shown = _pager.page?.round() ?? page;
    if (shown == page) return;
    if (context.reduceMotion) {
      _pager.jumpToPage(page);
    } else {
      _pager.animateToPage(page,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic);
    }
  }

  // Colours

  Color _accentOf(KitoTheme theme, int i) =>
      widget.pages[i].accent ?? theme.colors.primary;

  Color _onAccentOf(KitoTheme theme, int i) =>
      widget.pages[i].onAccent ??
      (widget.pages[i].accent == null
          ? theme.colors.onPrimary
          : kitoOnboardingReadableOn(widget.pages[i].accent!));

  Color _foregroundOf(KitoTheme theme, int i) =>
      KitoOnboardingPageView.foregroundFor(
          widget.pages[i], _style.layout, theme);

  Color _footerForegroundOf(KitoTheme theme, int i) =>
      _style.layout == KitoOnboardingLayout.card
          ? (_style.cardForeground ?? theme.colors.onSurface)
          : _foregroundOf(theme, i);

  /// Blends a per-page colour at the pager's current position.
  Color _blend(double position, Color Function(int) of) {
    final last = widget.pages.length - 1;
    final p = position.clamp(0.0, last.toDouble());
    final a = p.floor();
    final b = math.min(a + 1, last);
    return Color.lerp(of(a), of(b), p - a)!;
  }

  double get _position {
    if (_pager.hasClients && _pager.position.haveDimensions) {
      return _pager.page ?? _controller.page.toDouble();
    }
    return _controller.page.toDouble();
  }

  // Actions

  Future<void> _primary() async {
    if (_busy) return;
    final index = _controller.page;
    final permission = widget.pages[index].permission;
    if (permission == null) {
      _controller.next();
      return;
    }
    setState(() => _busy = true);
    var granted = false;
    try {
      granted = await permission.onRequest();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onPermissionResult?.call(index, granted);
    _controller.next();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final media = MediaQuery.of(context);
    final rtl = context.isRtl;
    final transition = KitoOnboardingMath.effectiveTransition(
        _style.pageTransition,
        reduceMotion: context.reduceMotion);
    final hasPermission = widget.pages.any((p) => p.permission != null);
    final topInset = math.max(media.padding.top, theme.spacing.sm) +
        (_style.indicator == KitoOnboardingIndicator.progressBar ? 64 : 52);
    final bottomInset =
        math.max(media.padding.bottom, 24.0) + 120 + (hasPermission ? 44 : 0);

    final pager = PageView.builder(
      controller: _pager,
      itemCount: widget.pages.length,
      onPageChanged: _controller.settle,
      itemBuilder: (context, index) => AnimatedBuilder(
        animation: _pager,
        builder: (context, child) {
          // Distance from the centre, in pages: negative once the page has gone past.
          final v = index - _position;
          final page = KitoOnboardingPageView(
            page: widget.pages[index],
            isCurrent: index == _controller.page,
            style: _style,
            topInset: topInset,
            bottomInset: bottomInset,
            motionEnabled: !context.reduceMotion,
            parallax: KitoOnboardingMath.parallaxOffset(transition, v) *
                (rtl ? -1 : 1),
          );
          Widget out = Opacity(
            opacity: KitoOnboardingMath.opacity(transition, v).clamp(0.0, 1.0),
            child: Transform.scale(
                scale: KitoOnboardingMath.scale(transition, v), child: page),
          );
          final angle = KitoOnboardingMath.cubeAngle(transition, v);
          if (angle != 0) {
            out = Transform(
              alignment: v < 0
                  ? AlignmentDirectional.centerEnd
                      .resolve(Directionality.of(context))
                  : AlignmentDirectional.centerStart
                      .resolve(Directionality.of(context)),
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle * math.pi / 180 * (rtl ? -1 : 1)),
              child: out,
            );
          }
          return out;
        },
      ),
    );

    return CallbackShortcuts(
      bindings: {
        SingleActivator(rtl
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight): _controller.next,
        SingleActivator(rtl
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft): _controller.back,
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: theme.colors.background,
          child: Stack(children: [
            Positioned.fill(child: pager),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pager,
                builder: (context, _) => _header(context, media),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _pager,
                builder: (context, _) => _footer(context, media),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, MediaQueryData media) {
    final theme = context.kito;
    final pos = _position;
    final foreground = _blend(pos, (i) => _foregroundOf(theme, i));
    final accent = _blend(pos, (i) => _accentOf(theme, i));
    final onAccent = _blend(pos, (i) => _onAccentOf(theme, i));
    final c = _controller;
    final duration = KitoMotion.of(context, theme.motion.medium);
    final showBack = _style.showsBackButton && !c.isFirstPage;

    Widget trailing = const SizedBox(height: 44);
    if (!c.isLastPage) {
      if (_style.buttonPlacement ==
          KitoOnboardingButtonPlacement.topTrailingCompact) {
        trailing = KitoOnboardingTap(
          onTap: _busy ? null : _primary,
          semanticLabel: _style.labels.next,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Icon(Icons.arrow_forward_rounded, size: 20, color: onAccent),
          ),
        );
      } else if (_style.showsSkip) {
        trailing = KitoOnboardingTap(
          onTap: c.skip,
          pressEffect: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(_style.labels.skip,
                    style: theme.typography.label
                        .copyWith(color: foreground.withValues(alpha: 0.75))),
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding:
          EdgeInsets.only(top: math.max(media.padding.top, theme.spacing.sm)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_style.indicator == KitoOnboardingIndicator.progressBar)
          Padding(
            padding: EdgeInsets.fromLTRB(
                theme.spacing.lg, theme.spacing.xs, theme.spacing.lg, 0),
            child: KitoOnboardingIndicatorView(
              style: KitoOnboardingIndicator.progressBar,
              count: widget.pages.length,
              current: c.page,
              accent: accent,
              foreground: foreground,
              label: _style.labels.pageOf,
            ),
          ),
        SizedBox(
          height: 48,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
            child: Row(children: [
              AnimatedOpacity(
                opacity: showBack ? 1 : 0,
                duration: duration,
                child: IgnorePointer(
                  ignoring: !showBack,
                  child: ExcludeSemantics(
                    excluding: !showBack,
                    child: KitoOnboardingTap(
                      onTap: c.back,
                      semanticLabel: _style.labels.back,
                      child: KitoSurface(
                        background: const KitoBackground.glass(opacity: 0.22),
                        radius: 22,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.chevron_left_rounded,
                              size: 24, color: foreground),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                  duration: duration,
                  child: KeyedSubtree(
                      key: ValueKey(c.isLastPage), child: trailing)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _footer(BuildContext context, MediaQueryData media) {
    final theme = context.kito;
    final pos = _position;
    final c = _controller;
    final page = widget.pages[c.page];
    final foreground = _blend(pos, (i) => _footerForegroundOf(theme, i));
    final accent = _blend(pos, (i) => _accentOf(theme, i));
    final onAccent = _blend(pos, (i) => _onAccentOf(theme, i));
    final labels = _style.labels;
    final permission = page.permission;
    final primaryTitle = permission?.allowTitle ??
        (c.isLastPage ? labels.getStarted : labels.next);

    Widget indicator() => KitoOnboardingIndicatorView(
          style: _style.indicator == KitoOnboardingIndicator.progressBar
              ? KitoOnboardingIndicator.none
              : _style.indicator,
          count: widget.pages.length,
          current: c.page,
          accent: accent,
          foreground: foreground,
          label: labels.pageOf,
        );

    Widget primary({required bool fullWidth}) => KitoOnboardingPrimaryButton(
          title: primaryTitle,
          fullWidth: fullWidth,
          busy: _busy,
          accent: accent,
          onAccent: onAccent,
          onTap: _primary,
        );

    Widget skipLink() => KitoOnboardingTap(
          onTap: c.skip,
          pressEffect: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Center(
              child: Text(labels.skip,
                  style: theme.typography.label
                      .copyWith(color: foreground.withValues(alpha: 0.75))),
            ),
          ),
        );

    final isLast = c.isLastPage;
    final Widget main = switch (_style.buttonPlacement) {
      KitoOnboardingButtonPlacement.bottomFullWidth => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator(),
            SizedBox(height: theme.spacing.lg),
            primary(fullWidth: true)
          ],
        ),
      KitoOnboardingButtonPlacement.bottomTrailingCompact => Row(children: [
          if (!isLast && permission == null) ...[indicator(), const Spacer()],
          if (isLast || permission != null)
            Expanded(child: primary(fullWidth: true))
          else
            primary(fullWidth: false),
        ]),
      KitoOnboardingButtonPlacement.topTrailingCompact => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator(),
            SizedBox(height: theme.spacing.lg),
            if (isLast || permission != null)
              primary(fullWidth: true)
            else if (_style.showsSkip)
              skipLink()
            else
              const SizedBox(height: 52),
          ],
        ),
      KitoOnboardingButtonPlacement.progressRing => permission != null
          ? primary(fullWidth: true)
          : LayoutBuilder(
              builder: (context, box) => Row(children: [
                if (!isLast) ...[indicator(), const Spacer()],
                KitoOnboardingRingButton(
                  isLast: isLast,
                  progress: c.progress,
                  accent: accent,
                  onAccent: onAccent,
                  fullWidth: box.maxWidth,
                  labels: labels,
                  onTap: _primary,
                ),
              ]),
            ),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(theme.spacing.lg, 0, theme.spacing.lg,
          math.max(media.padding.bottom, theme.spacing.lg)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        main,
        AnimatedSize(
          duration: KitoMotion.of(context, theme.motion.medium),
          curve: Curves.easeOutCubic,
          child: permission == null
              ? const SizedBox(width: double.infinity)
              : KitoOnboardingTap(
                  onTap: _busy ? null : c.next,
                  pressEffect: false,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: 44, minWidth: double.infinity),
                    child: Center(
                      child: Text(permission.notNowTitle,
                          style: theme.typography.label.copyWith(
                              color: foreground.withValues(alpha: 0.75))),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}
