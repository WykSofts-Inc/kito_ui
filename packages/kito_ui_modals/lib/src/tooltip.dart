// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// Which side of its target a [KitoModalTooltip] sits on.
enum KitoModalTooltipEdge {
  /// Above, arrow pointing down.
  top,

  /// Below, arrow pointing up.
  bottom,
}

/// A bubble with an arrow pointing at [child], above or below it, for coach marks and hints.
/// It floats in the overlay, so it never moves the layout around it; it springs in from the
/// arrow while [visible] and a tap on it calls [onDismiss].
///
/// ```dart
/// KitoModalTooltip(
///   visible: showTip,
///   message: 'Create your first list',
///   icon: Icons.auto_awesome_rounded,
///   onDismiss: () => setState(() => showTip = false),
///   child: addButton,
/// )
/// ```
class KitoModalTooltip extends StatefulWidget {
  /// Creates a tooltip around [child].
  const KitoModalTooltip({
    super.key,
    required this.visible,
    required this.message,
    required this.child,
    this.icon,
    this.edge = KitoModalTooltipEdge.top,
    this.onDismiss,
    this.tint,
    this.maxWidth = 260,
    this.gap = 6,
    this.dismissHint = 'Dismisses the tip',
  });

  /// Shows the bubble.
  final bool visible;

  /// The tip.
  final String message;

  /// What the bubble points at.
  final Widget child;

  /// An icon before the text.
  final IconData? icon;

  /// Above or below [child].
  final KitoModalTooltipEdge edge;

  /// Called when the bubble is tapped.
  final VoidCallback? onDismiss;

  /// The bubble colour; the theme's primary when null.
  final Color? tint;

  /// The widest the bubble gets before wrapping.
  final double maxWidth;

  /// Space between the arrow and [child].
  final double gap;

  /// Read by screen readers after the message.
  final String dismissHint;

  @override
  State<KitoModalTooltip> createState() => _KitoModalTooltipState();
}

class _KitoModalTooltipState extends State<KitoModalTooltip>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  late final AnimationController _show = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 160))
    ..addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _portal.isShowing) {
        _portal.hide();
      }
    });

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _portal.show();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.visible) _animate(true);
      });
    }
  }

  @override
  void didUpdateWidget(KitoModalTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      if (widget.visible) _portal.show();
      _animate(widget.visible);
    }
  }

  void _animate(bool show) {
    if (context.reduceMotion) {
      _show.value = show ? 1 : 0;
      if (!show && _portal.isShowing) _portal.hide();
      return;
    }
    show ? _show.forward() : _show.reverse();
  }

  @override
  void dispose() {
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _bubble,
      child: CompositedTransformTarget(link: _link, child: widget.child),
    );
  }

  Widget _bubble(BuildContext context) {
    final theme = context.kito;
    final fill = widget.tint ?? theme.colors.primary;
    final onFill = widget.tint == null
        ? theme.colors.onPrimary
        : (ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
            ? Colors.white
            : Colors.black);
    final top = widget.edge == KitoModalTooltipEdge.top;
    final arrow = CustomPaint(
      size: const Size(16, 8),
      painter: _ArrowPainter(color: fill, pointsDown: top),
    );
    final body = Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration:
          BoxDecoration(color: fill, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: onFill),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(widget.message,
              style: theme.typography.label
                  .copyWith(fontWeight: FontWeight.w600, color: onFill)),
        ),
      ]),
    );
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: top ? [body, arrow] : [arrow, body],
      ),
    );
    final curve = CurvedAnimation(
        parent: _show,
        curve: const KitoSpringCurve(damping: 0.62),
        reverseCurve: Curves.easeIn);
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: top ? Alignment.topCenter : Alignment.bottomCenter,
        followerAnchor: top ? Alignment.bottomCenter : Alignment.topCenter,
        offset: Offset(0, top ? -widget.gap : widget.gap),
        child: AnimatedBuilder(
          animation: _show,
          builder: (context, child) => Opacity(
            opacity: _show.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.6 + 0.4 * curve.value,
              alignment: top ? Alignment.bottomCenter : Alignment.topCenter,
              child: child,
            ),
          ),
          child: Semantics(
            button: widget.onDismiss != null,
            liveRegion: true,
            label: widget.message,
            hint: widget.onDismiss == null ? null : widget.dismissHint,
            excludeSemantics: true,
            onTap: widget.onDismiss,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: bubble,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.pointsDown});

  final Color color;
  final bool pointsDown;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pointsDown
        ? (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close())
        : (Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width / 2, 0)
          ..close());
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointsDown != pointsDown;
}
