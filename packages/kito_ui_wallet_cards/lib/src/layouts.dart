// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'card_view.dart';
import 'models.dart';

Duration _springTime(BuildContext context) => KitoMotion.of(
    context,
    context.reduceMotion
        ? const Duration(milliseconds: 250)
        : const Duration(milliseconds: 520));

Curve _springCurve(BuildContext context) => context.reduceMotion
    ? Curves.easeInOut
    : const KitoSpringCurve(damping: 0.8);

List<BoxShadow> _cardShadow([double strength = 1]) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2 * strength),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ];

// MARK: - Stack

/// A wallet-style stack: cards overlap so each one's top strip shows. Tap one and it slides to
/// the top while the rest tuck into a pile at the bottom, with [detailBuilder]'s content (say,
/// recent transactions) in between; tap it again, or drag it down, to put it back.
///
/// ```dart
/// KitoWalletCardStack(
///   cards: cards,
///   selectedId: selected,
///   onSelect: (id) => setState(() => selected = id),
///   height: 520,
///   detailBuilder: (card) => TransactionsList(card),
/// )
/// ```
class KitoWalletCardStack extends StatefulWidget {
  /// Creates a stack.
  const KitoWalletCardStack({
    super.key,
    required this.cards,
    required this.selectedId,
    required this.onSelect,
    this.peek,
    this.height,
    this.detailBuilder,
  });

  /// The cards, back to front.
  final List<KitoWalletCard> cards;

  /// The raised card, or null for the stack.
  final String? selectedId;

  /// Called with the tapped card's id, or null to put it back.
  final ValueChanged<String?> onSelect;

  /// How much of each card shows in the stack; about a quarter of the card's height when null,
  /// enough for its mark and name at any width.
  final double? peek;

  /// The widget's height; just enough for the stack when null.
  final double? height;

  /// Shown under the raised card.
  final Widget Function(KitoWalletCard card)? detailBuilder;

  /// The stacked top of card [index], or with a selection: the selected card at 0 and the
  /// others in a tight pile at the bottom of [containerHeight].
  static double offset({
    required int index,
    required int? selectedIndex,
    required int count,
    required double peek,
    required double cardHeight,
    required double containerHeight,
  }) {
    if (selectedIndex == null) return index * peek;
    if (index == selectedIndex) return 0;
    final pileIndex = index < selectedIndex ? index : index - 1;
    final pileTop =
        containerHeight - cardHeight * 0.32 - math.max(count - 2, 0) * 8;
    return pileTop + pileIndex * 8;
  }

  @override
  State<KitoWalletCardStack> createState() => _KitoWalletCardStackState();
}

class _KitoWalletCardStackState extends State<KitoWalletCardStack> {
  double _drag = 0;
  bool _dragging = false;

  void _tap(KitoWalletCard card) {
    HapticFeedback.selectionClick();
    widget.onSelect(card.id == widget.selectedId ? null : card.id);
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardHeight = width / KitoWalletCardGeometry.aspectRatio;
      final peek = widget.peek ?? cardHeight * 0.26;
      final stacked = cardHeight + math.max(cards.length - 1, 0) * peek;
      final height = math.max(widget.height ?? stacked, stacked);
      final selectedIndex = cards.indexWhere((c) => c.id == widget.selectedId);
      final selected = selectedIndex < 0 ? null : selectedIndex;
      final pileTop = KitoWalletCardStack.offset(
          index: selected == 0 ? 1 : 0,
          selectedIndex: selected,
          count: cards.length,
          peek: peek,
          cardHeight: cardHeight,
          containerHeight: height);
      final duration = _springTime(context);
      final curve = _springCurve(context);
      return SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (selected != null && widget.detailBuilder != null)
              Positioned(
                top: cardHeight + 16,
                left: 0,
                right: 0,
                height: math.max(0, pileTop - cardHeight - 28),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(widget.selectedId),
                  tween: Tween(begin: 0, end: 1),
                  duration: KitoMotion.of(context, context.kito.motion.medium),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                        offset: Offset(0, (1 - t) * 24), child: child),
                  ),
                  child: widget.detailBuilder!(cards[selected]),
                ),
              ),
            for (var i = 0; i < cards.length; i++)
              _positioned(
                context,
                card: cards[i],
                top: KitoWalletCardStack.offset(
                        index: i,
                        selectedIndex: selected,
                        count: cards.length,
                        peek: peek,
                        cardHeight: cardHeight,
                        containerHeight: height) +
                    (i == selected ? math.max(_drag, 0) : 0),
                width: width,
                isSelected: i == selected,
                dimmed: selected != null && i != selected,
                duration: _dragging && i == selected ? Duration.zero : duration,
                curve: curve,
              ),
          ],
        ),
      );
    });
  }

  Widget _positioned(
    BuildContext context, {
    required KitoWalletCard card,
    required double top,
    required double width,
    required bool isSelected,
    required bool dimmed,
    required Duration duration,
    required Curve curve,
  }) {
    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: duration,
      curve: curve,
      top: top,
      left: 0,
      width: width,
      child: AnimatedScale(
        scale: dimmed ? 0.94 : 1,
        alignment: Alignment.topCenter,
        duration: _springTime(context),
        curve: _springCurve(context),
        child: GestureDetector(
          onVerticalDragStart: isSelected
              ? (_) => setState(() {
                    _dragging = true;
                    _drag = 0;
                  })
              : null,
          onVerticalDragUpdate:
              isSelected ? (d) => setState(() => _drag += d.delta.dy) : null,
          onVerticalDragEnd: isSelected
              ? (_) {
                  final dismiss = _drag > 90;
                  setState(() {
                    _dragging = false;
                    _drag = 0;
                  });
                  if (dismiss) widget.onSelect(null);
                }
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(card.style.cornerRadius *
                  width /
                  KitoWalletCardGeometry.designWidth),
              boxShadow: _cardShadow(),
            ),
            child: KitoWalletCardView(
              card: card,
              showsBalance: isSelected,
              onTap: () => _tap(card),
              semanticHint: isSelected
                  ? 'Returns the card to the stack'
                  : 'Brings the card to the top',
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Carousel

/// Cards side by side; the centred one is full size, its neighbours turn away, shrink and fade
/// as they scroll off. Swipe or tap a neighbour to centre it.
///
/// ```dart
/// KitoWalletCardCarousel(
///   cards: cards,
///   onChanged: (card) => setState(() => current = card),
/// )
/// ```
class KitoWalletCardCarousel extends StatefulWidget {
  /// Creates a carousel.
  const KitoWalletCardCarousel({
    super.key,
    required this.cards,
    this.initialIndex = 0,
    this.onChanged,
    this.showsBalance = true,
    this.viewportFraction = 0.8,
    this.overlayBuilder,
  });

  /// The cards.
  final List<KitoWalletCard> cards;

  /// The card centred first.
  final int initialIndex;

  /// Called when a new card settles in the centre.
  final ValueChanged<KitoWalletCard>? onChanged;

  /// Shows each card's balance.
  final bool showsBalance;

  /// How much of the width each card takes.
  final double viewportFraction;

  /// Drawn over each card, clipped to it — a frosted "Frozen" layer or a "Default" tag.
  final Widget? Function(KitoWalletCard card)? overlayBuilder;

  @override
  State<KitoWalletCardCarousel> createState() => _KitoWalletCardCarouselState();
}

class _KitoWalletCardCarouselState extends State<KitoWalletCardCarousel> {
  late final PageController _pages = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: widget.initialIndex);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  double _page() {
    if (_pages.hasClients && _pages.position.haveDimensions) {
      return _pages.page ?? widget.initialIndex.toDouble();
    }
    return widget.initialIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = context.isRtl;
    final reduce = context.reduceMotion;
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = constraints.maxWidth * widget.viewportFraction;
      final cardHeight = cardWidth / KitoWalletCardGeometry.aspectRatio;
      return SizedBox(
        height: cardHeight + 32,
        child: Semantics(
          container: true,
          label: '${widget.cards.length} cards',
          child: PageView.builder(
            controller: _pages,
            itemCount: widget.cards.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              widget.onChanged?.call(widget.cards[i]);
            },
            itemBuilder: (context, i) {
              final card = widget.cards[i];
              final overlay = widget.overlayBuilder?.call(card);
              return AnimatedBuilder(
                animation: _pages,
                builder: (context, child) {
                  final delta = (i - _page()).clamp(-1.0, 1.0);
                  final amount = delta.abs();
                  final turn = (rtl ? 1 : -1) * delta * 22 * math.pi / 180;
                  return Center(
                    child: Opacity(
                      opacity: 1 - amount * 0.35,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(reduce ? 0 : turn),
                        child: Transform.scale(
                            scale: 1 - amount * 0.12, child: child),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          card.style.cornerRadius *
                              cardWidth /
                              KitoWalletCardGeometry.designWidth),
                      boxShadow: _cardShadow(1.1),
                    ),
                    child: Stack(
                      children: [
                        KitoWalletCardView(
                          card: card,
                          showsBalance: widget.showsBalance,
                          onTap: () => _pages.animateToPage(i,
                              duration: _springTime(context),
                              curve: Curves.easeOutCubic),
                        ),
                        if (overlay != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  card.style.cornerRadius *
                                      (cardWidth - 14) /
                                      KitoWalletCardGeometry.designWidth),
                              child: overlay,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

// MARK: - Fan

/// Cards fanned from a point below them, like a hand of cards. Tap one to lift it out.
///
/// ```dart
/// KitoWalletCardFan(cards: cards, selectedId: picked, onSelect: (id) => setState(() => picked = id))
/// ```
class KitoWalletCardFan extends StatelessWidget {
  /// Creates a fan.
  const KitoWalletCardFan({
    super.key,
    required this.cards,
    required this.selectedId,
    required this.onSelect,
    this.spread = 9,
  });

  /// The cards, back to front.
  final List<KitoWalletCard> cards;

  /// The lifted card.
  final String? selectedId;

  /// Called with the tapped card's id, or null to put it back.
  final ValueChanged<String?> onSelect;

  /// Degrees between neighbouring cards.
  final double spread;

  /// Centred on zero: five cards at 9° are −18, −9, 0, 9, 18.
  static double angle(
          {required int index, required int count, required double spread}) =>
      (index - (count - 1) / 2) * spread;

  @override
  Widget build(BuildContext context) {
    final direction = context.isRtl ? -1.0 : 1.0;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = width * 0.7;
      final cardHeight = cardWidth / KitoWalletCardGeometry.aspectRatio;
      final lift = cardWidth * 0.32;
      final height = cardHeight + lift + cardHeight * 0.55;
      final order = [
        for (var i = 0; i < cards.length; i++)
          if (cards[i].id != selectedId) i,
        for (var i = 0; i < cards.length; i++)
          if (cards[i].id == selectedId) i,
      ];
      return SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final i in order)
              _fanCard(context, i,
                  cardWidth: cardWidth,
                  top: lift + cardHeight * 0.2,
                  lift: lift,
                  direction: direction),
          ],
        ),
      );
    });
  }

  Widget _fanCard(BuildContext context, int i,
      {required double cardWidth,
      required double top,
      required double lift,
      required double direction}) {
    final card = cards[i];
    final selected = card.id == selectedId;
    final degrees = selected
        ? 0.0
        : angle(index: i, count: cards.length, spread: spread) * direction;
    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: _springTime(context),
      curve: _springCurve(context),
      top: selected ? top - lift : top,
      width: cardWidth,
      child: AnimatedRotation(
        turns: degrees / 360,
        alignment: const Alignment(0, 3.8),
        duration: _springTime(context),
        curve: _springCurve(context),
        child: AnimatedScale(
          scale: selected ? 1.06 : 1,
          duration: _springTime(context),
          curve: _springCurve(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(card.style.cornerRadius *
                  cardWidth /
                  KitoWalletCardGeometry.designWidth),
              boxShadow: _cardShadow(),
            ),
            child: KitoWalletCardView(
              card: card,
              showsBalance: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(selected ? null : card.id);
              },
              semanticHint:
                  selected ? 'Puts the card back' : 'Lifts the card out',
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - Deck

/// A deck to thumb through: swipe the top card away (either way) and it tucks in at the back.
/// Screen readers get a "Next card" action.
///
/// ```dart
/// KitoWalletCardDeck(cards: cards, onChanged: (top) => setState(() => current = top))
/// ```
class KitoWalletCardDeck extends StatefulWidget {
  /// Creates a deck.
  const KitoWalletCardDeck({super.key, required this.cards, this.onChanged});

  /// The cards, top first.
  final List<KitoWalletCard> cards;

  /// Called with the new top card.
  final ValueChanged<KitoWalletCard>? onChanged;

  @override
  State<KitoWalletCardDeck> createState() => _KitoWalletCardDeckState();
}

class _KitoWalletCardDeckState extends State<KitoWalletCardDeck>
    with SingleTickerProviderStateMixin {
  late List<KitoWalletCard> _order = [...widget.cards];
  Offset _drag = Offset.zero;
  late final AnimationController _fling = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 240));
  Offset _flingFrom = Offset.zero;
  Offset _flingTo = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fling.addListener(() {
      setState(() => _drag = Offset.lerp(
          _flingFrom, _flingTo, Curves.easeOutCubic.transform(_fling.value))!);
    });
    _fling.addStatusListener((status) {
      if (status == AnimationStatus.completed && _flingTo != Offset.zero) {
        setState(() {
          _drag = Offset.zero;
          _flingTo = Offset.zero;
        });
        _advance();
      }
    });
  }

  @override
  void didUpdateWidget(KitoWalletCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.cards.map((c) => c.id).toSet();
    if (ids.length != _order.length ||
        !_order.every((c) => ids.contains(c.id))) {
      _order = [...widget.cards];
    } else {
      final byId = {for (final c in widget.cards) c.id: c};
      _order = [for (final c in _order) byId[c.id]!];
    }
  }

  @override
  void dispose() {
    _fling.dispose();
    super.dispose();
  }

  void _advance() {
    if (_order.length < 2) return;
    HapticFeedback.selectionClick();
    setState(() => _order = [..._order.skip(1), _order.first]);
    widget.onChanged?.call(_order.first);
  }

  void _animate(Offset to) {
    _flingFrom = _drag;
    _flingTo = to;
    if (context.reduceMotion) {
      _fling.value = 1;
      if (to == Offset.zero) setState(() => _drag = Offset.zero);
      return;
    }
    _fling.forward(from: 0);
  }

  void _end(DragEndDetails details, double width) {
    final v = details.velocity.pixelsPerSecond.dx;
    if (_drag.dx.abs() > 100 || v.abs() > 900) {
      final sign = (_drag.dx == 0 ? v : _drag.dx).sign;
      _animate(Offset(sign * width * 1.3, _drag.dy));
    } else {
      _animate(Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = width * 0.86;
      final cardHeight = cardWidth / KitoWalletCardGeometry.aspectRatio;
      final visible = math.min(_order.length, 4);
      return Semantics(
        container: true,
        label: _order.isEmpty
            ? 'No cards'
            : '${_order.first.semanticLabel}, 1 of ${_order.length}',
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Next card'): _advance,
        },
        child: SizedBox(
          height: cardHeight + 60,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              for (var depth = visible - 1; depth >= 0; depth--)
                _deckCard(context, depth,
                    cardWidth: cardWidth, width: width, reduce: reduce),
            ],
          ),
        ),
      );
    });
  }

  Widget _deckCard(BuildContext context, int depth,
      {required double cardWidth,
      required double width,
      required bool reduce}) {
    final card = _order[depth];
    final top = depth == 0;
    final d = math.min(depth, 3);
    Widget face = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(card.style.cornerRadius *
            cardWidth /
            KitoWalletCardGeometry.designWidth),
        boxShadow: _cardShadow(),
      ),
      child: ExcludeSemantics(
          child: KitoWalletCardView(card: card, showsBalance: top)),
    );
    if (top) {
      face = GestureDetector(
        onPanStart: (_) => _fling.stop(),
        onPanUpdate: (u) => setState(() => _drag += u.delta),
        onPanEnd: (e) => _end(e, width),
        child: Transform.translate(
          offset: _drag,
          child: Transform.rotate(
            angle: reduce ? 0 : _drag.dx / 18 * math.pi / 180,
            child: face,
          ),
        ),
      );
    }
    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: _springTime(context),
      curve: _springCurve(context),
      bottom: d * 18.0,
      width: cardWidth,
      child: AnimatedScale(
        scale: 1 - d * 0.05,
        alignment: Alignment.topCenter,
        duration: _springTime(context),
        curve: _springCurve(context),
        child: face,
      ),
    );
  }
}
