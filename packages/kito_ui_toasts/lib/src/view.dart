// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'appearance.dart';
import 'pieces.dart';
import 'toast.dart';

/// Draws one toast in its layout. [KitoToastHost] uses it; you can also put it anywhere
/// yourself, e.g. an inline preview in a settings screen.
class KitoToastView extends StatefulWidget {
  /// Creates a view of [toast].
  const KitoToastView({
    super.key,
    required this.toast,
    this.onDismiss,
    this.appearance = const KitoToastAppearance(),
    this.remaining,
    this.paused = false,
    this.topInset = 0,
    this.bottomInset = 0,
  });

  /// What to draw.
  final KitoToast toast;

  /// Called by actions that dismiss, and by the screen-reader dismiss action.
  final VoidCallback? onDismiss;

  /// Styling.
  final KitoToastAppearance appearance;

  /// Time left, for the countdown ring; the full duration when null.
  final Duration? remaining;

  /// Freezes the countdown ring.
  final bool paused;

  /// Extra top padding inside a banner, so it can run under the status bar.
  final double topInset;

  /// Extra bottom padding inside a banner, so it can run under the home indicator.
  final double bottomInset;

  @override
  State<KitoToastView> createState() => _KitoToastViewState();
}

class _KitoToastViewState extends State<KitoToastView> {
  @override
  void initState() {
    super.initState();
    _haptic();
  }

  @override
  void didUpdateWidget(KitoToastView old) {
    super.didUpdateWidget(old);
    final completed = old.toast.isLoading && !widget.toast.isLoading;
    if (completed || old.toast.style != widget.toast.style) _haptic();
  }

  void _haptic() {
    final toast = widget.toast;
    if (!widget.appearance.playsHaptics || toast.isLoading) return;
    switch (toast.style) {
      case KitoToastStyle.success:
        HapticFeedback.lightImpact();
      case KitoToastStyle.warning:
        HapticFeedback.mediumImpact();
      case KitoToastStyle.error:
        HapticFeedback.heavyImpact();
      case KitoToastStyle.info:
        break;
    }
  }

  KitoToast get toast => widget.toast;

  void _run(KitoToastAction action) {
    action.onPressed();
    if (action.dismisses) widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = kitoToastAccent(theme, toast);
    final Widget body = switch (toast.layout) {
      KitoToastLayout.card => _card(theme, accent),
      KitoToastLayout.pill => _pill(theme, accent),
      KitoToastLayout.banner => _banner(theme, accent),
      KitoToastLayout.glass => _glass(theme, accent),
      KitoToastLayout.island => _island(theme, accent),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: toast.accessibilityLabel,
      onDismiss: widget.onDismiss,
      child: DefaultTextStyle(
        style: theme.typography.body.copyWith(
            color: theme.colors.onSurface, decoration: TextDecoration.none),
        child: body,
      ),
    );
  }

  // MARK: Pieces

  Widget _texts(KitoTheme theme, Color foreground,
      {int? titleLines, int? messageLines}) {
    final a = widget.appearance;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (toast.title != null)
            Text(toast.title!,
                maxLines: titleLines ?? a.maxTitleLines,
                overflow: TextOverflow.ellipsis,
                style: a.resolveTitle(toast).copyWith(color: foreground)),
          if (toast.title != null) const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: KitoMotion.of(context, theme.motion.fast),
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topStart,
              children: [...previous, if (current != null) current],
            ),
            child: Text(
              toast.message,
              key: ValueKey(toast.message),
              maxLines: messageLines ?? a.maxMessageLines,
              overflow: TextOverflow.ellipsis,
              style: a.resolveMessage(toast).copyWith(
                  color: foreground.withValues(
                      alpha: toast.title == null ? 1 : 0.75)),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _countdown(Color color, {double size = 26}) {
    final duration = toast.duration;
    if (!toast.showsCountdown || duration == null) return null;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: KitoToastCountdownRing(
        duration: duration,
        remaining: widget.remaining ?? duration,
        paused: widget.paused,
        color: color,
        size: size,
      ),
    );
  }

  Widget? _progress(Color track, Color fill) {
    final p = toast.progress;
    if (p == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: KitoToastProgressBar(value: p, fill: fill, track: track),
    );
  }

  Widget? _actions(KitoTheme theme, {Color? tint}) {
    if (toast.actions.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: theme.spacing.sm,
        children: [
          for (final action in toast.actions)
            KitoToastActionButton(
              action: action,
              color: tint ?? _roleColor(theme, action.role),
              onPressed: () => _run(action),
            ),
        ],
      ),
    );
  }

  Color _roleColor(KitoTheme theme, KitoToastActionRole role) => switch (role) {
        KitoToastActionRole.primary =>
          kitoToastAccent(theme, toast) == theme.colors.primary
              ? theme.colors.primary
              : kitoToastAccent(theme, toast),
        KitoToastActionRole.destructive => theme.colors.danger,
        KitoToastActionRole.cancel =>
          theme.colors.onBackground.withValues(alpha: 0.6),
      };

  BoxConstraints get _width =>
      BoxConstraints(maxWidth: widget.appearance.maxWidth ?? double.infinity);

  // MARK: Layouts

  Widget _card(KitoTheme theme, Color accent) {
    final a = widget.appearance;
    return Center(
      child: ConstrainedBox(
        constraints: _width,
        child: KitoSurface(
          background: toast.background ?? a.background,
          radius: a.radius,
          border: true,
          elevation: 8,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    a.showsAccentBar ? 10 + theme.spacing.xs : theme.spacing.md,
                    theme.spacing.md,
                    theme.spacing.md,
                    toast.actions.isEmpty
                        ? theme.spacing.md
                        : theme.spacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                              top: 1,
                              end: toast.showsIcon ||
                                      toast.avatar != null ||
                                      toast.isLoading
                                  ? theme.spacing.sm
                                  : 0),
                          child: KitoToastLeading(
                              toast: toast, color: accent, size: a.iconSize),
                        ),
                        Expanded(child: _texts(theme, theme.colors.onSurface)),
                        if (_countdown(accent) case final w?) w,
                      ],
                    ),
                    if (_progress(theme.colors.surfaceMuted, accent)
                        case final w?)
                      w,
                    if (_actions(theme) case final w?) w,
                  ],
                ),
              ),
              if (a.showsAccentBar)
                PositionedDirectional(
                  start: 6,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                        color: accent, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(KitoTheme theme, Color accent) {
    final a = widget.appearance;
    final line = toast.title == null
        ? toast.message
        : '${toast.title} · ${toast.message}';
    return Center(
      child: ConstrainedBox(
        constraints: _width,
        child: KitoSurface(
          background: toast.background ?? a.background,
          radius: 999,
          border: true,
          elevation: 7,
          padding: EdgeInsetsDirectional.fromSTEB(
              16,
              toast.actions.isEmpty ? 11 : 0,
              12,
              toast.actions.isEmpty ? 11 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KitoToastLeading(toast: toast, color: accent, size: 16),
              const SizedBox(width: 10),
              Flexible(
                child: ExcludeSemantics(
                  child: Text(line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colors.onSurface)),
                ),
              ),
              if (_countdown(accent, size: 20) case final w?) w,
              if (toast.actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: KitoToastActionButton(
                    action: toast.actions.first,
                    color: _roleColor(theme, toast.actions.first.role),
                    onPressed: () => _run(toast.actions.first),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner(KitoTheme theme, Color accent) {
    final background = toast.background;
    final content = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          20, 14 + widget.topInset, 20, 14 + widget.bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KitoToastLeading(toast: toast, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: _texts(theme, Colors.white)),
              if (_countdown(Colors.white) case final w?) w,
            ],
          ),
          if (_progress(Colors.white.withValues(alpha: 0.3), Colors.white)
              case final w?)
            w,
          if (_actions(theme, tint: Colors.white) case final w?) w,
        ],
      ),
    );
    if (background != null) {
      return KitoSurface(background: background, radius: 0, child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.82)],
          begin:
              AlignmentDirectional.topStart.resolve(Directionality.of(context)),
          end: AlignmentDirectional.bottomEnd
              .resolve(Directionality.of(context)),
        ),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: content,
    );
  }

  Widget _glass(KitoTheme theme, Color accent) {
    return Center(
      child: ConstrainedBox(
        constraints: _width,
        child: KitoGlow(
          color: accent,
          radius: 24,
          intensity: 0.4,
          child: KitoSurface(
            background: toast.background ??
                const KitoBackground.glass(blur: 22, opacity: 0.18),
            radius: 26,
            padding: const EdgeInsets.all(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: AlignmentDirectional.topStart
                      .resolve(Directionality.of(context)),
                  radius: 1.4,
                  colors: [accent.withValues(alpha: 0.10), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.18)),
                        child: KitoToastLeading(
                            toast: toast, color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _texts(theme, theme.colors.onSurface)),
                      if (_countdown(accent) case final w?) w,
                    ],
                  ),
                  if (_progress(
                          theme.colors.onSurface.withValues(alpha: 0.1), accent)
                      case final w?)
                    w,
                  if (_actions(theme) case final w?) w,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _island(KitoTheme theme, Color accent) {
    final action = toast.actions.isEmpty ? null : toast.actions.first;
    // The island is always dark, like the hardware it imitates.
    final onIsland = accent.computeLuminance() < 0.08 ? Colors.white : accent;
    return Center(
      child: ConstrainedBox(
        constraints: _width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                10, action == null ? 10 : 2, 14, action == null ? 10 : 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: onIsland.withValues(alpha: 0.22)),
                  child:
                      KitoToastLeading(toast: toast, color: onIsland, size: 18),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: _texts(theme, Colors.white,
                      titleLines: 1, messageLines: 2),
                ),
                if (_countdown(onIsland, size: 22) case final w?) w,
                if (action != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: KitoToastActionButton(
                      action: action,
                      color: accent.computeLuminance() < 0.08
                          ? Colors.white
                          : accent,
                      onFilled: accent.computeLuminance() < 0.08
                          ? Colors.black
                          : Colors.white,
                      filled: true,
                      onPressed: () => _run(action),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
