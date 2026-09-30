// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'strings.dart';

// MARK: - Reactions and actions

/// The long-press layer: the bubble lifted above a blurred conversation, an emoji bar above it
/// and Reply / Copy / Delete below. Everything shifts to stay inside the view.
class KitoChatReactionOverlay extends StatefulWidget {
  /// Creates the overlay. [bubbleRect] is in the overlay's own coordinates.
  const KitoChatReactionOverlay({
    super.key,
    required this.bubbleRect,
    required this.bubble,
    required this.isOutgoing,
    required this.onReact,
    required this.onDismiss,
    this.onReply,
    this.onCopy,
    this.onDelete,
    this.selectedEmoji,
    this.tint,
    this.emoji = KitoChatReaction.quickPicks,
  });

  /// Where the bubble sits.
  final Rect bubbleRect;

  /// A copy of the bubble to lift.
  final Widget bubble;

  /// Whether it's your message (menus align to the trailing edge).
  final bool isOutgoing;

  /// Called with the chosen emoji.
  final ValueChanged<String> onReact;

  /// Called when the layer is dismissed without a choice.
  final VoidCallback onDismiss;

  /// Shows Reply.
  final VoidCallback? onReply;

  /// Shows Copy.
  final VoidCallback? onCopy;

  /// Shows Delete.
  final VoidCallback? onDelete;

  /// Your current reaction, ringed.
  final String? selectedEmoji;

  /// Overrides the primary colour.
  final Color? tint;

  /// The emoji offered.
  final List<String> emoji;

  /// Height of the emoji bar.
  static const barHeight = 52.0;

  /// Height of one menu row.
  static const rowHeight = 46.0;

  /// Width of the menu.
  static const menuWidth = 210.0;

  @override
  State<KitoChatReactionOverlay> createState() =>
      _KitoChatReactionOverlayState();
}

class _KitoChatReactionOverlayState extends State<KitoChatReactionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  final _focus = FocusNode();
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c.duration = context.reduceMotion
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 420);
    if (_c.status == AnimationStatus.dismissed && !_closing) _c.forward();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _close(VoidCallback then) async {
    if (_closing) return;
    _closing = true;
    await _c.animateBack(0,
        duration: KitoMotion.of(context, const Duration(milliseconds: 200)),
        curve: Curves.easeIn);
    then();
  }

  int get _menuRows => [widget.onReply, widget.onCopy, widget.onDelete]
      .where((a) => a != null)
      .length;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    final accent = kito.accent(widget.tint);
    const gap = 10.0, margin = 12.0;
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final rect = widget.bubbleRect;
      final menuHeight = KitoChatReactionOverlay.rowHeight * _menuRows;
      final top = rect.top - KitoChatReactionOverlay.barHeight - gap;
      final bottom = rect.bottom + gap + menuHeight;
      var shift = 0.0;
      if (bottom > size.height - margin) shift = size.height - margin - bottom;
      if (top + shift < margin) shift = margin - top;
      final rightAligned = widget.isOutgoing != context.isRtl;
      double leftFor(double width) {
        final preferred = rightAligned ? rect.right - width : rect.left;
        return preferred.clamp(8.0, math.max(8.0, size.width - width - 8));
      }

      final barWidth = widget.emoji.length * 42.0 + 14;
      return Focus(
        focusNode: _focus,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _close(widget.onDismiss);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final spring = reduce
                ? Curves.easeOut.transform(t)
                : kito.motion.spring.transform(t);
            final lifted = shift * spring;
            return Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: KitoChatStrings.of(context, 'close'),
                  onTap: () => _close(widget.onDismiss),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _close(widget.onDismiss),
                    child: BackdropFilter(
                      filter:
                          ui.ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
                      child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.14 * t)),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: rect.left,
                top: rect.top + lifted,
                width: rect.width,
                height: rect.height,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Transform.scale(
                      scale: reduce ? 1 : 1 + 0.04 * spring,
                      alignment: rightAligned
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.18 * t.clamp(0, 1)),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: OverflowBox(
                          alignment: rightAligned
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          maxWidth: rect.width,
                          maxHeight: double.infinity,
                          child: widget.bubble,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: leftFor(barWidth),
                top: top + lifted,
                width: barWidth,
                height: KitoChatReactionOverlay.barHeight,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * spring,
                    alignment: rightAligned
                        ? Alignment.bottomRight
                        : Alignment.bottomLeft,
                    child: _emojiBar(context, accent, t),
                  ),
                ),
              ),
              if (_menuRows > 0)
                Positioned(
                  left: leftFor(KitoChatReactionOverlay.menuWidth),
                  top: rect.bottom + lifted + gap,
                  width: KitoChatReactionOverlay.menuWidth,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.5 + 0.5 * spring,
                      alignment:
                          rightAligned ? Alignment.topRight : Alignment.topLeft,
                      child: _menu(context),
                    ),
                  ),
                ),
            ]);
          },
        ),
      );
    });
  }

  Widget _emojiBar(BuildContext context, Color accent, double t) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: kito.colors.surface,
        borderRadius: BorderRadius.circular(kito.radii.pill),
        border: Border.all(color: kito.colors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < widget.emoji.length; i++)
          Builder(builder: (context) {
            final e = widget.emoji[i];
            final start = (i * 0.06).clamp(0.0, 0.6);
            final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
            final s = reduce ? 1.0 : kito.motion.spring.transform(local);
            final selected = widget.selectedEmoji == e;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Transform.scale(
                scale: 0.2 + 0.8 * s,
                child: _EmojiButton(
                  emoji: e,
                  selected: selected,
                  ring: accent.withValues(alpha: 0.22),
                  label: KitoChatStrings.of(context, 'reactWith', {'emoji': e}),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _close(() => widget.onReact(e));
                  },
                ),
              ),
            );
          }),
      ]),
    );
  }

  Widget _menu(BuildContext context) {
    final kito = context.kito;
    final rows = <Widget>[];
    void add(String key, IconData icon, Color color, VoidCallback? action) {
      if (action == null) return;
      if (rows.isNotEmpty) {
        rows.add(
            Divider(height: 0.5, thickness: 0.5, color: kito.colors.border));
      }
      rows.add(_MenuRow(
        title: KitoChatStrings.of(context, key),
        icon: icon,
        color: color,
        onTap: () => _close(action),
      ));
    }

    add('reply', Icons.reply_rounded, kito.colors.onSurface, widget.onReply);
    add('copy', Icons.copy_rounded, kito.colors.onSurface, widget.onCopy);
    add('delete', Icons.delete_outline_rounded, kito.colors.danger,
        widget.onDelete);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kito.colors.surface,
        borderRadius: BorderRadius.circular(kito.radii.xl - 4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }
}

class _EmojiButton extends StatefulWidget {
  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.ring,
    required this.label,
    required this.onTap,
  });
  final String emoji;
  final bool selected;
  final Color ring;
  final String label;
  final VoidCallback onTap;

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedSlide(
            offset: Offset(0, _down && !reduce ? -0.15 : 0),
            duration: const Duration(milliseconds: 160),
            child: AnimatedScale(
              scale: _down && !reduce ? 1.35 : 1,
              duration: const Duration(milliseconds: 220),
              curve: context.kito.motion.spring,
              child: Container(
                width: 40,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected ? widget.ring : Colors.transparent,
                ),
                child: Text(widget.emoji,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(fontSize: 27)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(
      {required this.title,
      required this.icon,
      required this.color,
      required this.onTap});
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Semantics(
      button: true,
      label: title,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                minHeight: KitoChatReactionOverlay.rowHeight),
            child: Padding(
              padding:
                  EdgeInsetsDirectional.symmetric(horizontal: kito.spacing.lg),
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      style: kito.typography.body.copyWith(color: color)),
                ),
                Icon(icon, size: 18, color: color),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Image viewer

/// A photo full screen: it grows out of the bubble it was tapped in, pinch or double-tap to
/// zoom, drag down to close.
class KitoChatImageViewer extends StatefulWidget {
  /// Creates a viewer. [sourceRect] (in the viewer's coordinates) is where the photo grows from
  /// and shrinks back to.
  const KitoChatImageViewer({
    super.key,
    required this.image,
    required this.onClose,
    this.sourceRect,
  });

  /// The photo.
  final KitoChatImage image;

  /// Called once the close animation has finished.
  final VoidCallback onClose;

  /// Where the photo was on screen.
  final Rect? sourceRect;

  /// Pushes a viewer above the current route, growing from [globalRect].
  static Future<void> show(BuildContext context, KitoChatImage image,
      {Rect? globalRect}) {
    return Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (route, _, __) => KitoChatImageViewer(
        image: image,
        sourceRect: globalRect,
        onClose: () => Navigator.of(route).pop(),
      ),
    ));
  }

  @override
  State<KitoChatImageViewer> createState() => _KitoChatImageViewerState();
}

class _KitoChatImageViewerState extends State<KitoChatImageViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  final _zoom = TransformationController();
  final _focus = FocusNode();
  Offset _drag = Offset.zero;
  bool _closing = false;
  TapDownDetails? _doubleTap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_open.status == AnimationStatus.dismissed && !_closing) {
      if (context.reduceMotion) {
        _open.duration = const Duration(milliseconds: 180);
      }
      _open.forward();
    }
  }

  @override
  void dispose() {
    _open.dispose();
    _zoom.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _zoomed => _zoom.value.getMaxScaleOnAxis() > 1.01;

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _open.animateBack(0,
        duration: KitoMotion.of(context, const Duration(milliseconds: 300)),
        curve: Curves.easeInCubic);
    widget.onClose();
  }

  void _toggleZoom() {
    if (_zoomed) {
      _zoom.value = Matrix4.identity();
    } else {
      final p = _doubleTap?.localPosition ?? Offset.zero;
      const s = 2.2;
      _zoom.value = Matrix4.diagonal3Values(s, s, 1)
        ..setTranslationRaw(-p.dx * (s - 1), -p.dy * (s - 1), 0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final caption = widget.image.caption;
    return Focus(
      focusNode: _focus,
      includeSemantics: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      // The photo and its close button are separate stops for a screen reader, and the chat
      // underneath is hidden from it while the viewer is open.
      child: BlockSemantics(
          child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          final ratio = widget.image.aspectRatio;
          var w = size.width, h = size.width / ratio;
          if (h > size.height) {
            h = size.height;
            w = h * ratio;
          }
          final target = Rect.fromCenter(
              center: size.center(Offset.zero), width: w, height: h);
          final source = widget.sourceRect ??
              Rect.fromCenter(
                  center: target.center, width: w * 0.85, height: h * 0.85);
          return AnimatedBuilder(
            animation: _open,
            builder: (context, _) {
              final t = context.reduceMotion
                  ? 1.0
                  : Curves.easeOutCubic.transform(_open.value);
              final fade = _open.value;
              final dismiss = (_drag.dy.abs() / 300).clamp(0.0, 1.0);
              final rect = Rect.lerp(source, target, t)!;
              final shrink = 1 - dismiss * 0.25;
              return Stack(children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(
                        alpha: (fade * (1 - dismiss * 0.8)).clamp(0, 1)),
                  ),
                ),
                Positioned.fromRect(
                  rect: rect.shift(_drag),
                  child: Transform.scale(
                    scale: shrink,
                    child: Semantics(
                      image: true,
                      label: caption == null || caption.trim().isEmpty
                          ? KitoChatStrings.of(context, 'photo')
                          : KitoChatStrings.of(
                              context, 'photoCaption', {'caption': caption}),
                      child: GestureDetector(
                        onDoubleTapDown: (d) => _doubleTap = d,
                        onDoubleTap: _toggleZoom,
                        onVerticalDragUpdate: (d) {
                          if (_zoomed) return;
                          setState(() => _drag += d.delta);
                        },
                        onVerticalDragEnd: (d) {
                          if (_zoomed) return;
                          if (_drag.dy.abs() > 120 ||
                              (d.primaryVelocity ?? 0).abs() > 900) {
                            _close();
                          } else {
                            setState(() => _drag = Offset.zero);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12 * (1 - t)),
                          child: InteractiveViewer(
                            transformationController: _zoom,
                            minScale: 1,
                            maxScale: 4,
                            onInteractionEnd: (_) => setState(() {}),
                            child: Image(
                                image: widget.image.image,
                                fit: BoxFit.cover,
                                width: rect.width,
                                height: rect.height,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Colors.black26)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  child: SafeArea(
                    child: Opacity(
                      opacity: (fade * (1 - dismiss)).clamp(0.0, 1.0),
                      child: Padding(
                        padding: EdgeInsets.all(kito.spacing.sm),
                        child: Semantics(
                          container: true,
                          button: true,
                          label: KitoChatStrings.of(context, 'closePhoto'),
                          onTap: _close,
                          child: ExcludeSemantics(
                            child: GestureDetector(
                              onTap: _close,
                              child: KitoPressable(
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (caption != null && caption.trim().isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: (fade * (1 - dismiss)).clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.all(kito.spacing.lg),
                            child: ExcludeSemantics(
                              child: Text(caption,
                                  textAlign: TextAlign.center,
                                  style: kito.typography.body
                                      .copyWith(color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]);
            },
          );
        }),
      )),
    );
  }
}
