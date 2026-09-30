// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'logic.dart';

/// Drives a [KitoSwipeDeck] from outside: throw the top card from your own buttons, undo, and
/// read how many cards are left.
///
/// ```dart
/// final deck = KitoSwipeDeckController();
///
/// KitoSwipeDeck(items: dishes, controller: deck, showsControls: false, itemBuilder: ...);
/// FilledButton(onPressed: () => deck.swipe(KitoSwipeDeckDirection.left), child: Text('Pass'));
/// ```
class KitoSwipeDeckController extends ChangeNotifier {
  _KitoSwipeDeckState<dynamic>? _state;
  int _remaining = 0;
  bool _canUndo = false;

  /// Cards not yet swiped.
  int get remaining => _remaining;

  /// Whether there's a swipe to take back.
  bool get canUndo => _canUndo;

  /// Throws the top card [direction], as if it had been swiped.
  void swipe(KitoSwipeDeckDirection direction) => _state?._throwTop(direction);

  /// Brings the last swiped card back to the top.
  void undo() => _state?._undo();

  void _sync(int remaining, bool canUndo) {
    if (remaining == _remaining && canUndo == _canUndo) return;
    _remaining = remaining;
    _canUndo = canUndo;
    notifyListeners();
  }
}

/// A Tinder-style swipe deck: drag the top card and it tilts, LIKE / NOPE / SUPER stamps fade
/// in, and a quick flick or a long drag throws it off with momentum. Undo brings the last one
/// back.
///
/// ```dart
/// KitoSwipeDeck<Dish>(
///   items: dishes,
///   itemBuilder: (context, dish) => DishCard(dish),
///   onSwipe: (dish, direction) {
///     if (direction == KitoSwipeDeckDirection.right) save(dish);
///   },
/// )
/// ```
///
/// The deck fills the space it's given. Screen readers get Like, Nope, Super like and Undo as
/// actions on the top card.
///
/// Directions are physical in every layout direction: right (like) is always a swipe towards the
/// right edge of the screen, and the card, its tilt, the stamps and the button row stay that way
/// round in right-to-left layouts.
class KitoSwipeDeck<T> extends StatefulWidget {
  /// Creates a deck; the first item is on top.
  const KitoSwipeDeck({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.visibleCount = 3,
    this.allowsSuperLike = true,
    this.showsControls = true,
    this.likeLabel = 'LIKE',
    this.nopeLabel = 'NOPE',
    this.superLikeLabel = 'SUPER',
    this.emptyTitle = "You're all caught up",
    this.undoLabel = 'Undo',
    this.tint,
    this.onSwipe,
    this.onUndo,
    this.onEmpty,
  });

  /// The cards, first on top.
  final List<T> items;

  /// Builds one card; it fills the deck.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Swipe and undo from outside.
  final KitoSwipeDeckController? controller;

  /// Cards drawn in the pile.
  final int visibleCount;

  /// Whether throwing up counts (super like).
  final bool allowsSuperLike;

  /// The round Undo / Nope / Super like / Like buttons under the deck.
  final bool showsControls;

  /// The stamp shown when dragging right.
  final String likeLabel;

  /// The stamp shown when dragging left.
  final String nopeLabel;

  /// The stamp shown when dragging up.
  final String superLikeLabel;

  /// Shown once every card is gone.
  final String emptyTitle;

  /// What screen readers call the undo button and action.
  final String undoLabel;

  /// The super-like colour; the theme's primary when null.
  final Color? tint;

  /// A card left the deck.
  final void Function(T item, KitoSwipeDeckDirection direction)? onSwipe;

  /// A card came back.
  final ValueChanged<T>? onUndo;

  /// The last card left.
  final VoidCallback? onEmpty;

  @override
  State<KitoSwipeDeck<T>> createState() => _KitoSwipeDeckState<T>();
}

class _Flight {
  _Flight(this.controller, this.from, this.to);
  final AnimationController controller;
  final Offset from;
  final Offset to;
  Offset get value => Offset.lerp(from, to, controller.value)!;
}

class _KitoSwipeDeckState<T> extends State<KitoSwipeDeck<T>>
    with TickerProviderStateMixin {
  int _top = 0;
  Offset _drag = Offset.zero;
  Size _size = const Size(320, 480);
  final _flights = <int, _Flight>{};
  final _returning = <int>{};
  final _history = <(int, KitoSwipeDeckDirection)>[];
  KitoSwipeDeckDirection? _armed;
  late final AnimationController _springBack =
      AnimationController.unbounded(vsync: this)..addListener(_onSpringBack);
  Offset _springFrom = Offset.zero;

  KitoSwipeDeckDecision get _decision =>
      KitoSwipeDeckDecision(allowsUp: widget.allowsSuperLike);

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
  }

  @override
  void didUpdateWidget(KitoSwipeDeck<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller!._state = null;
      }
      _attach(widget.controller);
    }
    if (widget.items.length != oldWidget.items.length) {
      _top = _top.clamp(0, widget.items.length);
      _history.removeWhere((h) => h.$1 >= widget.items.length);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
    }
  }

  void _attach(KitoSwipeDeckController? c) => c?._state = this;

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller!._state = null;
    _springBack.dispose();
    for (final f in _flights.values) {
      f.controller.dispose();
    }
    super.dispose();
  }

  void _syncController() {
    if (!mounted) return;
    widget.controller
        ?._sync(math.max(widget.items.length - _top, 0), _history.isNotEmpty);
  }

  void _onSpringBack() {
    setState(() => _drag = _springFrom * (1 - _springBack.value));
  }

  // MARK: Drag

  void _dragStart(DragStartDetails _) {
    _springBack.stop();
  }

  void _dragUpdate(DragUpdateDetails d) {
    setState(() => _drag += d.delta);
    final p = _decision.progress(_drag, _size);
    final armed = p.amount >= 1 ? p.dominant : null;
    if (armed != _armed) {
      _armed = armed;
      if (armed != null) HapticFeedback.selectionClick();
    }
  }

  void _dragEnd(DragEndDetails d) {
    _armed = null;
    final velocity = d.velocity.pixelsPerSecond;
    final direction = _decision.direction(_drag, velocity, _size);
    if (direction != null) {
      _throwTop(direction, from: _drag, velocity: velocity);
      return;
    }
    _springFrom = _drag;
    if (context.reduceMotion) {
      setState(() => _drag = Offset.zero);
      return;
    }
    _springBack.value = 0;
    _springBack.animateWith(SpringSimulation(
      SpringDescription.withDampingRatio(mass: 1, stiffness: 230, ratio: 0.62),
      0,
      1,
      0,
    ));
  }

  // MARK: Throw and undo

  void _throwTop(KitoSwipeDeckDirection direction,
      {Offset from = Offset.zero, Offset velocity = Offset.zero}) {
    if (!mounted || _top >= widget.items.length) return;
    if (direction == KitoSwipeDeckDirection.up && !widget.allowsSuperLike) {
      return;
    }
    final index = _top;
    final item = widget.items[index];
    final target =
        KitoSwipeDeckDecision.exitOffset(direction, from, velocity, _size);
    _springBack.stop();
    _flights.remove(index)?.controller.dispose();
    _returning.remove(index);
    final controller = AnimationController(vsync: this);
    final flight = _Flight(controller, from, target);
    _flights[index] = flight;
    controller.addListener(() => setState(() {}));
    final reduce = context.reduceMotion;
    final Future<void> done;
    if (reduce) {
      controller.duration = const Duration(milliseconds: 250);
      done = controller.animateTo(1, curve: Curves.easeIn);
    } else {
      final remaining = (target - from).distance;
      final speed = velocity.distance;
      final v = remaining > 0 ? math.min(speed / remaining, 10.0) : 0.0;
      done = controller.animateWith(SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 140, damping: 22),
        0,
        1,
        v,
        tolerance: const Tolerance(distance: 0.01, velocity: 0.05),
      ));
    }
    done.whenComplete(() {
      if (!mounted || _flights[index] != flight) return;
      setState(() => _flights.remove(index));
      controller.dispose();
    });
    setState(() {
      _drag = Offset.zero;
      _top = index + 1;
      _history.add((index, direction));
    });
    HapticFeedback.mediumImpact();
    _syncController();
    widget.onSwipe?.call(item, direction);
    if (index + 1 >= widget.items.length) widget.onEmpty?.call();
  }

  void _undo() {
    if (!mounted || _history.isEmpty) return;
    final (index, direction) = _history.removeLast();
    if (index >= widget.items.length) return;
    final from = _flights[index]?.value ??
        KitoSwipeDeckDecision.exitOffset(
            direction, Offset.zero, Offset.zero, _size);
    _flights.remove(index)?.controller.dispose();
    final controller = AnimationController(
        vsync: this,
        duration: KitoMotion.of(context, const Duration(milliseconds: 520)));
    final flight = _Flight(controller, from, Offset.zero);
    _flights[index] = flight;
    _returning.add(index);
    controller.addListener(() => setState(() {}));
    controller.animateTo(1, curve: Curves.easeOutBack).whenComplete(() {
      if (!mounted || _flights[index] != flight) return;
      setState(() {
        _flights.remove(index);
        _returning.remove(index);
      });
      controller.dispose();
    });
    setState(() {
      _drag = Offset.zero;
      _top = index;
    });
    HapticFeedback.lightImpact();
    _syncController();
    widget.onUndo?.call(widget.items[index]);
  }

  // MARK: Build

  Offset _offsetOf(int index) =>
      _flights[index]?.value ?? (index == _top ? _drag : Offset.zero);

  bool _isThrown(int index) =>
      _flights.containsKey(index) && !_returning.contains(index);

  List<int> get _rendered {
    final n = widget.items.length;
    final pile = [
      for (var i = _top; i < math.min(_top + widget.visibleCount + 1, n); i++) i
    ];
    final thrown = _flights.keys.where((i) => !pile.contains(i)).toList()
      ..sort();
    // Painted back to front: the far end of the pile first, thrown cards last.
    return [...pile.reversed, ...thrown];
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final deck = LayoutBuilder(builder: (context, constraints) {
      _size = Size(
        constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
        constraints.maxHeight.isFinite ? constraints.maxHeight : 480,
      );
      final empty = _top >= widget.items.length && _flights.isEmpty;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: KitoMotion.of(context, kito.motion.medium),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.0).animate(a),
                    child: child),
              ),
              child: empty
                  ? _EmptyDeck(
                      key: const ValueKey('empty'),
                      title: widget.emptyTitle,
                      undoLabel: widget.undoLabel,
                      color: kito.accent(widget.tint),
                      onUndo: _history.isEmpty ? null : _undo,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          for (final i in _rendered)
            Positioned.fill(
              key: ValueKey(i),
              child: _card(context, i),
            ),
        ],
      );
    });

    // Offsets, tilt and stamp corners are physical, so the deck needs no mirroring.
    if (!widget.showsControls) return deck;
    return Column(children: [
      Expanded(child: deck),
      SizedBox(height: kito.spacing.xl),
      _controls(context),
    ]);
  }

  Widget _card(BuildContext context, int index) {
    final kito = context.kito;
    final item = widget.items[index];
    final thrown = _isThrown(index);
    final isTop = index == _top && !thrown;
    final depth = thrown ? 0.0 : (index - _top).toDouble();
    final dragProgress = _size.width <= 0
        ? 0.0
        : math.min(_drag.distance / (_size.width * 0.5), 1.0);
    final lifted = math.max(depth - (depth > 0 ? dragProgress : 0), 0.0);
    final offset = _offsetOf(index);
    final swipe = _decision.progress(offset, _size);
    final hidden = depth >= widget.visibleCount;
    final rotation = context.reduceMotion
        ? 0.0
        : KitoSwipeDeckDecision.rotation(offset, _size.width);
    final radius = BorderRadius.circular(kito.radii.xl + 8);
    final superColor = kito.accent(widget.tint);

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: isTop || thrown ? 0.18 : 0.08),
            blurRadius: isTop ? 36 : 16,
            offset: Offset(0, isTop ? 12 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: kito.colors.surface,
          child: Stack(fit: StackFit.expand, children: [
            widget.itemBuilder(context, item),
            IgnorePointer(
              child: _EdgeGlow(
                  progress: swipe,
                  like: kito.colors.success,
                  nope: kito.colors.danger,
                  superLike: superColor),
            ),
            IgnorePointer(
              child: Padding(
                padding: EdgeInsets.all(kito.spacing.xl),
                child: Stack(children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: _Stamp(
                        text: widget.likeLabel,
                        color: kito.colors.success,
                        amount: swipe.right,
                        angle: -16),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: _Stamp(
                        text: widget.nopeLabel,
                        color: kito.colors.danger,
                        amount: swipe.left,
                        angle: 16),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.7),
                    child: _Stamp(
                        text: widget.superLikeLabel,
                        color: superColor,
                        amount: swipe.up,
                        angle: -6),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );

    final transform = Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy + lifted * 14, 0, 1);
    card = Transform(
      transform: transform,
      child: Transform.rotate(
        angle: rotation,
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scale: 1 - lifted * 0.05,
          alignment: Alignment.bottomCenter,
          child: card,
        ),
      ),
    );
    if (hidden) card = Opacity(opacity: 0, child: card);

    if (!isTop) return IgnorePointer(child: ExcludeSemantics(child: card));

    String cap(String s) =>
        s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
    return Semantics(
      container: true,
      hint: 'Swipe right to like, left to pass',
      customSemanticsActions: {
        CustomSemanticsAction(label: cap(widget.likeLabel)): () =>
            _throwTop(KitoSwipeDeckDirection.right),
        CustomSemanticsAction(label: cap(widget.nopeLabel)): () =>
            _throwTop(KitoSwipeDeckDirection.left),
        if (widget.allowsSuperLike)
          CustomSemanticsAction(label: cap(widget.superLikeLabel)): () =>
              _throwTop(KitoSwipeDeckDirection.up),
        if (_history.isNotEmpty)
          CustomSemanticsAction(label: widget.undoLabel): _undo,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _dragStart,
        onPanUpdate: _dragUpdate,
        onPanEnd: _dragEnd,
        child: card,
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final kito = context.kito;
    final swipe = _decision.progress(_drag, _size);
    final enabled = _top < widget.items.length;
    String cap(String s) =>
        s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
    final outer = Directionality.of(context);
    // Nope throws left and Like throws right, so the row keeps that order on screen.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Directionality(
            textDirection: outer,
            child: _DeckButton(
              icon: Icons.undo_rounded,
              label: widget.undoLabel,
              color: kito.colors.warning,
              size: 48,
              emphasis: 0,
              onPressed: _history.isEmpty ? null : _undo,
            ),
          ),
          SizedBox(width: kito.spacing.lg),
          _DeckButton(
            icon: Icons.close_rounded,
            label: cap(widget.nopeLabel),
            color: kito.colors.danger,
            size: 64,
            emphasis: swipe.left,
            onPressed:
                enabled ? () => _throwTop(KitoSwipeDeckDirection.left) : null,
          ),
          if (widget.allowsSuperLike) ...[
            SizedBox(width: kito.spacing.lg),
            _DeckButton(
              icon: Icons.star_rounded,
              label: cap(widget.superLikeLabel),
              color: kito.accent(widget.tint),
              size: 48,
              emphasis: swipe.up,
              onPressed:
                  enabled ? () => _throwTop(KitoSwipeDeckDirection.up) : null,
            ),
          ],
          SizedBox(width: kito.spacing.lg),
          _DeckButton(
            icon: Icons.favorite_rounded,
            label: cap(widget.likeLabel),
            color: kito.colors.success,
            size: 64,
            emphasis: swipe.right,
            onPressed:
                enabled ? () => _throwTop(KitoSwipeDeckDirection.right) : null,
          ),
        ],
      ),
    );
  }
}

/// Colour washing in from the edge the card leaves by.
class _EdgeGlow extends StatelessWidget {
  const _EdgeGlow(
      {required this.progress,
      required this.like,
      required this.nope,
      required this.superLike});

  final KitoSwipeDeckProgress progress;
  final Color like;
  final Color nope;
  final Color superLike;

  @override
  Widget build(BuildContext context) {
    Widget wash(Color c, double amount, Alignment from) => amount <= 0
        ? const SizedBox.shrink()
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: from,
                end: Alignment.center,
                colors: [
                  c.withValues(alpha: 0.45 * amount),
                  c.withValues(alpha: 0)
                ],
              ),
            ),
          );
    return Stack(fit: StackFit.expand, children: [
      wash(like, progress.right, Alignment.centerLeft),
      wash(nope, progress.left, Alignment.centerRight),
      wash(superLike, progress.up, Alignment.bottomCenter),
    ]);
  }
}

/// A rubber-stamp label that fades and settles in as the drag commits.
class _Stamp extends StatelessWidget {
  const _Stamp(
      {required this.text,
      required this.color,
      required this.amount,
      required this.angle});

  final String text;
  final Color color;
  final double amount;
  final double angle;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: amount.clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Transform.scale(
          scale: 1.35 - 0.35 * amount,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 4),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round deck control that swells as the matching drag builds.
class _DeckButton extends StatelessWidget {
  const _DeckButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.emphasis,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final double emphasis;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final full = emphasis > 0.95;
    final enabled = onPressed != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.4,
            duration: KitoMotion.of(context, kito.motion.fast),
            child: AnimatedScale(
              scale: 1 + 0.14 * emphasis,
              duration: KitoMotion.of(context, kito.motion.fast),
              curve: kito.motion.spring,
              child: KitoPressable(
                scale: 0.88,
                enabled: enabled,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.alphaBlend(
                        color.withValues(alpha: full ? 1 : emphasis * 0.18),
                        kito.colors.surface),
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25 + 0.3 * emphasis),
                        blurRadius: 20 + 16 * emphasis,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon,
                      size: size * 0.42,
                      color: full ? kito.colors.onPrimary : color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({
    super.key,
    required this.title,
    required this.undoLabel,
    required this.color,
    required this.onUndo,
  });

  final String title;
  final String undoLabel;
  final Color color;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kito.colors.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(kito.radii.xl + 8),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.7)],
            ).createShader(r),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 44, color: Colors.white),
          ),
          SizedBox(height: kito.spacing.md),
          Text(title,
              textAlign: TextAlign.center,
              style: kito.typography.bodyEmphasized
                  .copyWith(color: kito.colors.onBackground)),
          if (onUndo != null) ...[
            SizedBox(height: kito.spacing.md),
            Semantics(
              button: true,
              label: undoLabel,
              onTap: onUndo,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onUndo,
                child: KitoPressable(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: EdgeInsets.symmetric(horizontal: kito.spacing.lg),
                    decoration: BoxDecoration(
                      color: kito.colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(kito.radii.pill),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.undo_rounded,
                          size: 18, color: kito.colors.onSurface),
                      SizedBox(width: kito.spacing.xs),
                      Text(undoLabel,
                          style: kito.typography.label
                              .copyWith(color: kito.colors.onSurface)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
