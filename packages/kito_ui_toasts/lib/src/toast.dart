// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// What a toast is about; picks the default icon, accent colour and haptic.
enum KitoToastStyle {
  /// Something worked.
  success,

  /// Something failed.
  error,

  /// Something needs attention.
  warning,

  /// Neutral news.
  info,
}

/// How a toast is drawn.
enum KitoToastLayout {
  /// A rounded card with an accent bar, icon, text and actions.
  card,

  /// A compact capsule: icon and one line.
  pill,

  /// Edge to edge, filled with the accent colour.
  banner,

  /// Frosted glass with a soft glow in the accent colour.
  glass,

  /// A black capsule that grows out of the top of the screen, like a Dynamic Island.
  island,
}

/// Where toasts appear.
enum KitoToastPosition {
  /// Under the status bar.
  top,

  /// Above the home indicator.
  bottom,
}

/// How big a toast's title is.
enum KitoToastTitleStyle {
  /// 20pt bold.
  large,

  /// 16pt semibold (the default).
  medium,

  /// 14pt medium.
  small,
}

/// What an action does, which sets its colour.
enum KitoToastActionRole {
  /// The main thing to do — the accent colour.
  primary,

  /// Deletes or undoes something — the danger colour.
  destructive,

  /// Backs out — a muted colour.
  cancel,
}

/// A button on a toast.
@immutable
class KitoToastAction {
  /// Creates an action. It dismisses the toast after [onPressed] unless [dismisses] is false.
  const KitoToastAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.role = KitoToastActionRole.primary,
    this.dismisses = true,
    this.showsLabel = true,
  });

  /// The title, also used as the accessibility label.
  final String label;

  /// An optional icon before the label (or instead of it with [showsLabel] false).
  final IconData? icon;

  /// Sets the colour.
  final KitoToastActionRole role;

  /// Runs when tapped.
  final VoidCallback onPressed;

  /// Whether tapping it also dismisses the toast.
  final bool dismisses;

  /// False shows only the [icon] (the label is still read by screen readers).
  final bool showsLabel;
}

/// A round avatar in place of the icon — for "Amina sent you a message".
@immutable
class KitoToastAvatar {
  /// Initials on a gradient.
  const KitoToastAvatar({
    this.initials = '',
    this.colors = const [Color(0xFFFF8A3D), Color(0xFFFF3D77)],
    this.icon,
    this.image,
  });

  /// One or two letters.
  final String initials;

  /// The gradient behind the initials or icon.
  final List<Color> colors;

  /// An icon instead of initials.
  final IconData? icon;

  /// A photo, which wins over initials and icon.
  final ImageProvider? image;
}

/// One toast. Immutable: the center updates it in place with [copyWith] as progress moves or
/// a promise settles, keeping its [id], so it animates rather than being replaced.
@immutable
class KitoToast {
  /// Creates a toast.
  ///
  /// [duration] is how long it stays; null keeps it until dismissed. Toasts with actions,
  /// progress or a spinner stay until dismissed or completed (so nothing with unfinished work
  /// disappears under the user's thumb), except countdown toasts, whose actions expire.
  KitoToast({
    Object? id,
    required this.message,
    this.title,
    this.style = KitoToastStyle.info,
    this.layout = KitoToastLayout.card,
    this.icon,
    this.showsIcon = true,
    this.titleStyle = KitoToastTitleStyle.medium,
    this.isBold = false,
    this.tint,
    this.background,
    this.actions = const [],
    double? progress,
    Duration? duration = const Duration(seconds: 3),
    this.avatar,
    this.isLoading = false,
    this.showsCountdown = false,
    this.onTap,
    this.semanticLabel,
  })  : id = id ?? _nextId(),
        progress = progress?.clamp(0.0, 1.0),
        duration = showsCountdown
            ? (duration ?? const Duration(seconds: 5))
            : (actions.isEmpty && progress == null && !isLoading)
                ? duration
                : null;

  const KitoToast._raw({
    required this.id,
    required this.message,
    required this.title,
    required this.style,
    required this.layout,
    required this.icon,
    required this.showsIcon,
    required this.titleStyle,
    required this.isBold,
    required this.tint,
    required this.background,
    required this.actions,
    required this.progress,
    required this.duration,
    required this.avatar,
    required this.isLoading,
    required this.showsCountdown,
    required this.onTap,
    required this.semanticLabel,
  });

  static int _counter = 0;
  static String _nextId() => 'kito-toast-${++_counter}';

  /// Identifies the toast for [KitoToastCenter.dismiss], `update` and `complete`.
  final Object id;

  /// The main text.
  final String message;

  /// An optional heading above [message].
  final String? title;

  /// Picks the default icon, accent colour and haptic.
  final KitoToastStyle style;

  /// How it's drawn.
  final KitoToastLayout layout;

  /// Replaces the style's icon.
  final IconData? icon;

  /// False hides the icon.
  final bool showsIcon;

  /// Title size.
  final KitoToastTitleStyle titleStyle;

  /// Bolder title and message.
  final bool isBold;

  /// Replaces the style's accent colour.
  final Color? tint;

  /// Replaces the layout's fill (a gradient for a celebratory toast, say).
  final KitoBackground? background;

  /// Buttons; pill and island layouts show the first one.
  final List<KitoToastAction> actions;

  /// 0–1 fills a progress bar; null hides it.
  final double? progress;

  /// How long it stays; null until dismissed.
  final Duration? duration;

  /// A round avatar in place of the icon.
  final KitoToastAvatar? avatar;

  /// Shows a spinner in place of the icon and holds the toast until completed.
  final bool isLoading;

  /// Shows a ring that empties over [duration], e.g. beside an Undo action.
  final bool showsCountdown;

  /// Runs when the toast body is tapped (when it's the only one on screen).
  final VoidCallback? onTap;

  /// What screen readers say; defaults to the title and message.
  final String? semanticLabel;

  /// A copy with some fields replaced. Pass `clearProgress` / `clearDuration` to set those to
  /// null.
  KitoToast copyWith({
    String? message,
    String? title,
    KitoToastStyle? style,
    KitoToastLayout? layout,
    IconData? icon,
    bool? showsIcon,
    KitoToastTitleStyle? titleStyle,
    bool? isBold,
    Color? tint,
    KitoBackground? background,
    List<KitoToastAction>? actions,
    double? progress,
    bool clearProgress = false,
    Duration? duration,
    bool clearDuration = false,
    KitoToastAvatar? avatar,
    bool? isLoading,
    bool? showsCountdown,
    VoidCallback? onTap,
    String? semanticLabel,
  }) =>
      KitoToast._raw(
        id: id,
        message: message ?? this.message,
        title: title ?? this.title,
        style: style ?? this.style,
        layout: layout ?? this.layout,
        icon: icon ?? this.icon,
        showsIcon: showsIcon ?? this.showsIcon,
        titleStyle: titleStyle ?? this.titleStyle,
        isBold: isBold ?? this.isBold,
        tint: tint ?? this.tint,
        background: background ?? this.background,
        actions: actions ?? this.actions,
        progress:
            clearProgress ? null : (progress?.clamp(0.0, 1.0) ?? this.progress),
        duration: clearDuration ? null : (duration ?? this.duration),
        avatar: avatar ?? this.avatar,
        isLoading: isLoading ?? this.isLoading,
        showsCountdown: showsCountdown ?? this.showsCountdown,
        onTap: onTap ?? this.onTap,
        semanticLabel: semanticLabel ?? this.semanticLabel,
      );

  /// What screen readers announce.
  String get accessibilityLabel =>
      semanticLabel ?? [if (title != null) title!, message].join('. ');

  @override
  String toString() => 'KitoToast($id, $style, "$message")';
}
