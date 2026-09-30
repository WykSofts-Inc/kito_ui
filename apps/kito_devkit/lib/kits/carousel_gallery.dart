// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_carousel/kito_ui_carousel.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../app/toasts.dart';
import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';
import '../gallery/phone_frame.dart';

/// A place, drawn as a gradient scene with an icon: no network images needed.
class _Place {
  const _Place(this.name, this.detail, this.icon, this.colors, {this.price});
  final String name;
  final String detail;
  final IconData icon;
  final List<Color> colors;
  final String? price;
}

const _lodges = [
  _Place('Giraffe Manor', 'Lang’ata · breakfast with Rothschilds',
      Icons.park_rounded, [Color(0xFFF5A524), Color(0xFFD9480F)],
      price: 'KES 98,000'),
  _Place('Diani Reef', 'Diani Beach · 30 km of white sand',
      Icons.beach_access_rounded, [Color(0xFF00B8D4), Color(0xFF1565C0)],
      price: 'KES 24,500'),
  _Place('Mara Serena', 'Maasai Mara · the great migration',
      Icons.landscape_rounded, [Color(0xFFB08968), Color(0xFF6F4E37)],
      price: 'KES 61,000'),
  _Place('Lamu Old Town', 'Lamu · dhows and Swahili lanes',
      Icons.sailing_rounded, [Color(0xFF7C4DFF), Color(0xFF311B92)],
      price: 'KES 18,200'),
  _Place('Mount Kenya Lodge', 'Nanyuki · above the clouds',
      Icons.terrain_rounded, [Color(0xFF26A69A), Color(0xFF004D40)],
      price: 'KES 32,000'),
];

class _Scene extends StatelessWidget {
  const _Scene(this.place);

  final _Place place;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return ClipRRect(
      borderRadius: BorderRadius.circular(kito.radii.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: place.colors,
          ),
        ),
        child: Stack(children: [
          PositionedDirectional(
            end: -18,
            top: -10,
            child: Icon(place.icon,
                size: 150, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(place.name,
                    style: kito.typography.headline.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(place.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kito.typography.caption
                        .copyWith(color: Colors.white.withValues(alpha: 0.85))),
                if (place.price != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(kito.radii.pill),
                    ),
                    child: Text('${place.price} / night',
                        style: kito.typography.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// The gallery for kito_ui_carousel.
final carouselKit = KitEntry(
  title: 'Carousels',
  package: 'kito_ui_carousel',
  blurb: 'carousels, indicators, swipe decks, stories and paging',
  icon: Icons.view_carousel_rounded,
  category: KitCategory.components,
  isNew: true,
  sections: [
    KitSection('Carousels', Icons.view_carousel_rounded, [
      KitSample(
        title: 'Cover flow',
        subtitle:
            'Lodges swing round in 3D, loop forever and auto-play; the worm follows your finger.',
        code: '''final carousel = KitoCarouselController();

KitoCarousel(
  itemCount: lodges.length,
  itemBuilder: (context, i) => LodgeCard(lodges[i]),
  controller: carousel,
  effect: KitoCarouselEffect.coverFlow,
  peek: 40,
  loops: true,
  autoPlay: const Duration(seconds: 4),
)
KitoCarouselPageIndicator(
  count: lodges.length,
  controller: carousel,
  style: KitoCarouselIndicatorStyle.worm,
)''',
        builder: (_) => const _EffectDemo(
            effect: KitoCarouselEffect.coverFlow,
            indicator: KitoCarouselIndicatorStyle.worm,
            autoPlay: true),
      ),
      for (final (effect, title, subtitle, style) in const [
        (
          KitoCarouselEffect.scale,
          'Scale',
          'Neighbours shrink and dim a little.',
          KitoCarouselIndicatorStyle.capsule
        ),
        (
          KitoCarouselEffect.rotate,
          'Cards in a hand',
          'Neighbours tilt on their bottom edge and drop.',
          KitoCarouselIndicatorStyle.dots
        ),
        (
          KitoCarouselEffect.parallax,
          'Parallax',
          'Each scene drifts against the swipe, like a window onto a wider view.',
          KitoCarouselIndicatorStyle.capsule
        ),
        (
          KitoCarouselEffect.fade,
          'Fade',
          'Neighbours fade away as they leave.',
          KitoCarouselIndicatorStyle.numbers
        ),
        (
          KitoCarouselEffect.stack,
          'Stack',
          'Upcoming lodges wait stacked behind and slide out as you swipe.',
          KitoCarouselIndicatorStyle.worm
        ),
      ])
        KitSample(
          title: title,
          subtitle: subtitle,
          code: '''KitoCarousel(
  itemCount: lodges.length,
  itemBuilder: (context, i) => LodgeCard(lodges[i]),
  effect: KitoCarouselEffect.${effect.name},
)''',
          builder: (_) => _EffectDemo(effect: effect, indicator: style),
        ),
      KitSample(
        title: 'Deals banner',
        subtitle:
            'Full-width, looping banners; the current dot fills until the next one.',
        code: '''KitoBannerCarousel(
  itemCount: deals.length,
  itemBuilder: (context, i) => DealBanner(deals[i]),
  interval: const Duration(seconds: 5),
)''',
        builder: (_) => DemoWidth(
          width: 380,
          child: KitoBannerCarousel(
            itemCount: 3,
            height: 170,
            onPageChanged: (_) {},
            itemBuilder: (_, i) => const [
              _Banner(
                  'Mashujaa Day sale',
                  'Up to 40% off coast getaways',
                  Icons.local_offer_rounded,
                  [Color(0xFFFF5252), Color(0xFFB71C1C)]),
              _Banner(
                  'Pay with M-Pesa',
                  'KES 500 back on your first stay',
                  Icons.phone_android_rounded,
                  [Color(0xFF00C853), Color(0xFF1B5E20)]),
              _Banner('SGR weekend', 'Nairobi → Mombasa from KES 1,500',
                  Icons.train_rounded, [Color(0xFF2979FF), Color(0xFF0D47A1)]),
            ][i],
          ),
        ),
      ),
    ]),
    KitSection('Page indicators', Icons.more_horiz_rounded, [
      KitSample(
        title: 'Every style',
        subtitle:
            'Dots, capsule, worm, numbers and progress. Tap or scrub any row.',
        code: '''KitoCarouselPageIndicator(
  count: 6,
  current: page,
  onChanged: (i) => setState(() => page = i),
  style: KitoCarouselIndicatorStyle.capsule,
)''',
        builder: (_) => const _Indicators(),
      ),
    ]),
    KitSection('Cards', Icons.style_rounded, [
      KitSample(
        title: 'Swipe deck',
        subtitle:
            'Drag to tilt; LIKE / NOPE / SUPER stamps fade in; flick to throw; undo brings it back.',
        code: '''KitoSwipeDeck<Dish>(
  items: dishes,
  itemBuilder: (context, dish) => DishCard(dish),
  onSwipe: (dish, direction) {
    if (direction == KitoSwipeDeckDirection.right) save(dish);
  },
)''',
        builder: (_) => const _Deck(),
      ),
      KitSample(
        title: 'Your own buttons',
        subtitle:
            'Hide the built-in controls and drive the deck with a controller.',
        code: '''final deck = KitoSwipeDeckController();

KitoSwipeDeck(items: dishes, controller: deck,
    showsControls: false, itemBuilder: ...);
FilledButton(onPressed: () => deck.swipe(KitoSwipeDeckDirection.left),
    child: const Text('Pass'));
TextButton(onPressed: deck.canUndo ? deck.undo : null,
    child: const Text('Undo'));''',
        builder: (_) => const _Deck(controlled: true),
      ),
      KitSample(
        title: 'Wallet passes',
        subtitle:
            'Tap the pile to fan it out, tap a pass to bring it forward, tap again to go back.',
        code: '''KitoStackedCards(
  itemCount: passes.length,
  itemBuilder: (context, i) => PassCard(passes[i]),
  cardHeight: 190,
)''',
        builder: (_) => const _Passes(),
      ),
    ]),
    KitSection('Stories', Icons.amp_stories_rounded, [
      KitSample(
        title: 'Story tray',
        subtitle:
            'Tap a ring: it spins, then the viewer opens. Hold to pause, swipe for the cube, swipe down to close.',
        code: '''KitoStoryTray(
  itemCount: friends.length,
  titleBuilder: (i) => friends[i].name,
  isSeen: (i) => friends[i].seen,
  isLive: (i) => friends[i].live,
  avatarBuilder: (context, i) => Avatar(friends[i]),
  yourStory: KitoYourStory(initials: 'WN', onTap: compose),
  onSelect: (i) => Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    pageBuilder: (context, _, __) => KitoStoryViewer(
      userCount: friends.length,
      initialUser: i,
      segmentCount: (u) => friends[u].stories.length,
      titleBuilder: (u) => friends[u].name,
      storyBuilder: (context, u, s) => StoryPage(friends[u].stories[s]),
      onDismiss: () => Navigator.of(context).pop(),
    ),
  )),
)''',
        builder: (_) => PhoneFrame(builder: (_) => const _StoriesScreen()),
      ),
      KitSample(
        title: 'Story rings',
        subtitle: 'New, seen, live with a pulsing badge, and loading.',
        code: '''KitoStoryRing(isLive: true, child: avatar)
KitoStoryRing(isSeen: true, child: avatar)
KitoStoryRing(isLoading: true, child: avatar)''',
        builder: (_) => const _Rings(),
      ),
    ]),
    KitSection('Scroll containers', Icons.swipe_vertical_rounded, [
      KitSample(
        title: 'Parallax header',
        subtitle:
            'Pull to stretch; scroll and the hero drifts, blurs and hands over to a title bar.',
        code: '''KitoParallaxHeader(
  title: 'Zanzibar',
  subtitle: 'Stone Town · Nungwi · Paje',
  header: BeachScene(),
  pinnedHeader: CategoryChips(),
  child: GuideSections(),
)''',
        builder: (_) => PhoneFrame(builder: (_) => const _Guide()),
      ),
      KitSample(
        title: 'Reels-style paging',
        subtitle: 'One clip per screen; each learns when it is the active one.',
        code: '''KitoPagedList(
  itemCount: clips.length,
  itemBuilder: (context, i, isActive) =>
      ClipView(clips[i], playing: isActive),
)''',
        builder: (_) => PhoneFrame(builder: (_) => const _Reels()),
      ),
      KitSample(
        title: 'Snap grid',
        subtitle:
            'Three rows per column; a column snaps and the next one peeks in.',
        code: '''KitoSnapGrid(
  itemCount: menu.length,
  rows: 3,
  itemBuilder: (context, i) => MenuRow(menu[i]),
)''',
        builder: (_) => const DemoWidth(width: 380, child: _Menu()),
      ),
      KitSample(
        title: 'Marquee',
        subtitle: 'Towns drift by endlessly; press and hold to stop them.',
        code: '''KitoInfiniteMarquee(
  itemCount: towns.length,
  itemBuilder: (context, i) => TownChip(towns[i]),
  speed: 36,
  tint: Colors.grey,
)''',
        builder: (_) => const DemoWidth(width: 380, child: _Towns()),
      ),
    ]),
  ],
);

// MARK: - Carousels

class _EffectDemo extends StatefulWidget {
  const _EffectDemo(
      {required this.effect, required this.indicator, this.autoPlay = false});

  final KitoCarouselEffect effect;
  final KitoCarouselIndicatorStyle indicator;
  final bool autoPlay;

  @override
  State<_EffectDemo> createState() => _EffectDemoState();
}

class _EffectDemoState extends State<_EffectDemo> {
  final _controller = KitoCarouselController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoWidth(
      width: 400,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        KitoCarousel(
          itemCount: _lodges.length,
          controller: _controller,
          effect: widget.effect,
          peek: widget.effect == KitoCarouselEffect.stack ? 24 : 40,
          height: 230,
          loops: widget.autoPlay,
          autoPlay: widget.autoPlay ? const Duration(seconds: 4) : null,
          itemBuilder: (_, i) => _Scene(_lodges[i]),
        ),
        const SizedBox(height: 8),
        KitoCarouselPageIndicator(
          count: _lodges.length,
          controller: _controller,
          style: widget.indicator,
        ),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.title, this.detail, this.icon, this.colors);

  final String title;
  final String detail;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 16, 28),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kito.typography.headline.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kito.typography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.9)),
        ]),
      ),
    );
  }
}

class _Indicators extends StatefulWidget {
  const _Indicators();

  @override
  State<_Indicators> createState() => _IndicatorsState();
}

class _IndicatorsState extends State<_Indicators> {
  var _page = 2;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (final style in KitoCarouselIndicatorStyle.values) ...[
        Text(style.name,
            style: kito.typography.caption
                .copyWith(color: kito.colors.onSurface.withValues(alpha: 0.6))),
        KitoCarouselPageIndicator(
          count: 6,
          current: _page,
          style: style,
          progress: 0.6,
          onChanged: (i) => setState(() => _page = i),
        ),
        const SizedBox(height: 8),
      ],
    ]);
  }
}

// MARK: - Cards

class _Dish {
  const _Dish(this.name, this.place, this.price, this.icon, this.colors);
  final String name;
  final String place;
  final String price;
  final IconData icon;
  final List<Color> colors;
}

const _dishes = [
  _Dish('Nyama choma', 'Carnivore, Lang’ata', 'KES 1,800',
      Icons.outdoor_grill_rounded, [Color(0xFFD9480F), Color(0xFF7F1D1D)]),
  _Dish('Swahili pilau', 'Mama Oliech, Kilimani', 'KES 650',
      Icons.rice_bowl_rounded, [Color(0xFFF5A524), Color(0xFF92400E)]),
  _Dish('Githeri', 'Kenyatta Market', 'KES 250', Icons.soup_kitchen_rounded,
      [Color(0xFF65A30D), Color(0xFF365314)]),
  _Dish('Ugali na sukuma', 'Mama Rocks, CBD', 'KES 300', Icons.eco_rounded,
      [Color(0xFF16A34A), Color(0xFF14532D)]),
  _Dish('Mandazi', 'Mombasa Old Town', 'KES 50', Icons.bakery_dining_rounded,
      [Color(0xFFEAB308), Color(0xFF854D0E)]),
  _Dish('Chapati', 'Kibandaski, Ngara', 'KES 30', Icons.flatware_rounded,
      [Color(0xFFB45309), Color(0xFF451A03)]),
];

class _DishCard extends StatelessWidget {
  const _DishCard(this.dish);

  final _Dish dish;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dish.colors,
        ),
      ),
      child: Stack(children: [
        Center(
          child: Icon(dish.icon,
              size: 140, color: Colors.white.withValues(alpha: 0.25)),
        ),
        PositionedDirectional(
          start: 20,
          end: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dish.name,
                  style: kito.typography.title.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${dish.place} · ${dish.price}',
                  style: kito.typography.body
                      .copyWith(color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Deck extends StatefulWidget {
  const _Deck({this.controlled = false});

  final bool controlled;

  @override
  State<_Deck> createState() => _DeckState();
}

class _DeckState extends State<_Deck> {
  final _deck = KitoSwipeDeckController();
  var _saved = 0;
  var _round = 0;

  @override
  void dispose() {
    _deck.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final deck = KitoSwipeDeck<_Dish>(
      key: ValueKey(_round),
      items: _dishes,
      controller: _deck,
      showsControls: !widget.controlled,
      emptyTitle: 'Hakuna zaidi — you’ve seen every dish',
      itemBuilder: (_, dish) => _DishCard(dish),
      onSwipe: (dish, direction) {
        if (direction == KitoSwipeDeckDirection.left) return;
        setState(() => _saved++);
        devKitToasts.success(direction == KitoSwipeDeckDirection.up
            ? 'Super liked ${dish.name}'
            : 'Saved ${dish.name}');
      },
      onUndo: (dish) => devKitToasts.info('${dish.name} is back'),
    );
    if (!widget.controlled) {
      return DemoWidth(width: 340, height: 560, child: deck);
    }
    return DemoWidth(
      width: 340,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 440, child: deck),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: _deck,
          builder: (context, _) => Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _deck.remaining > 0
                    ? () => _deck.swipe(KitoSwipeDeckDirection.left)
                    : null,
                child: const Text('Pass'),
              ),
              FilledButton(
                onPressed: _deck.remaining > 0
                    ? () => _deck.swipe(KitoSwipeDeckDirection.right)
                    : null,
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: _deck.canUndo ? _deck.undo : null,
                child: const Text('Undo'),
              ),
              TextButton(
                onPressed: () => setState(() => _round++),
                child: const Text('Deal again'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: _deck,
          builder: (context, _) => Text(
            '${_deck.remaining} left · $_saved saved',
            style: kito.typography.caption
                .copyWith(color: kito.colors.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      ]),
    );
  }
}

class _Pass {
  const _Pass(this.title, this.line, this.detail, this.icon, this.colors);
  final String title;
  final String line;
  final String detail;
  final IconData icon;
  final List<Color> colors;
}

const _passes = [
  _Pass('Madaraka Express', 'Nairobi Terminus → Mombasa', 'Coach 4 · Seat 32',
      Icons.train_rounded, [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
  _Pass('Kenya Airways KQ 612', 'NBO → MBA · 07:40', 'Gate 14 · Seat 9A',
      Icons.flight_takeoff_rounded, [Color(0xFFB91C1C), Color(0xFFEF4444)]),
  _Pass('Maasai Mara entry', 'Sekenani Gate · 2 adults', 'Valid 3 days',
      Icons.landscape_rounded, [Color(0xFF92400E), Color(0xFFD97706)]),
  _Pass('Nairobi National Park', 'Main Gate · Safari walk', 'Valid today',
      Icons.pets_rounded, [Color(0xFF065F46), Color(0xFF10B981)]),
  _Pass('Chama loyalty card', 'Wycliff N · Gold', '2,450 points',
      Icons.loyalty_rounded, [Color(0xFF4C1D95), Color(0xFF8B5CF6)]),
];

class _Passes extends StatelessWidget {
  const _Passes();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return DemoWidth(
      width: 360,
      child: KitoStackedCards(
        itemCount: _passes.length,
        cardHeight: 190,
        semanticLabelBuilder: (i) => _passes[i].title,
        itemBuilder: (_, i) {
          final p = _passes[i];
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: p.colors),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(p.icon, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kito.typography.bodyEmphasized
                              .copyWith(color: Colors.white)),
                    ),
                  ]),
                  const Spacer(),
                  Text(p.line,
                      style: kito.typography.headline
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(p.detail,
                      style: kito.typography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// MARK: - Stories

class _Friend {
  const _Friend(this.name, this.initials, this.colors, this.stories,
      {this.seen = false, this.live = false});
  final String name;
  final String initials;
  final List<Color> colors;
  final List<(String, IconData, String)> stories;
  final bool seen;
  final bool live;
}

const _friends = [
  _Friend('Amani', 'AW', [
    Color(0xFFF472B6),
    Color(0xFFDB2777)
  ], [
    ('Sunrise at Diani', Icons.wb_twilight_rounded, '2h'),
    ('Coconut stand', Icons.local_drink_rounded, '1h'),
  ]),
  _Friend(
      'Baraka',
      'BO',
      [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
      [
        ('Safari Rally, Naivasha', Icons.directions_car_rounded, '45m'),
      ],
      live: true),
  _Friend('Chebet', 'CK', [
    Color(0xFF34D399),
    Color(0xFF047857)
  ], [
    ('Iten track session', Icons.directions_run_rounded, '5h'),
    ('Ugali victory lunch', Icons.restaurant_rounded, '4h'),
    ('Kerio Valley view', Icons.landscape_rounded, '3h'),
  ]),
  _Friend(
      'Njeri',
      'NM',
      [Color(0xFFFBBF24), Color(0xFFB45309)],
      [
        ('Nairobi skyline', Icons.location_city_rounded, '8h'),
      ],
      seen: true),
  _Friend(
      'Otieno',
      'OO',
      [Color(0xFFA78BFA), Color(0xFF6D28D9)],
      [
        ('Fish at Dunga Beach', Icons.set_meal_rounded, '12h'),
      ],
      seen: true),
];

class _Initials extends StatelessWidget {
  const _Initials(this.friend);

  final _Friend friend;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: friend.colors)),
        child: Center(
          child: Text(friend.initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
        ),
      );
}

class _StoriesScreen extends StatefulWidget {
  const _StoriesScreen();

  @override
  State<_StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<_StoriesScreen> {
  final _seen = <int>{};

  void _open(int index) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child),
      ),
      pageBuilder: (context, _, __) => KitoStoryViewer(
        userCount: _friends.length,
        initialUser: index,
        segmentCount: (u) => _friends[u].stories.length,
        titleBuilder: (u) => _friends[u].name,
        subtitleBuilder: (u, s) => _friends[u].stories[s].$3,
        avatarBuilder: (_, u) => _Initials(_friends[u]),
        onSeen: (u, _) => setState(() => _seen.add(u)),
        onReply: (u, _, text) =>
            devKitToasts.success('Sent to ${_friends[u].name}: $text'),
        onDismiss: () => Navigator.of(context).pop(),
        storyBuilder: (_, u, s) => _StoryPage(_friends[u], s),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      appBar: AppBar(
        title: const Text('Safari Moments'),
        backgroundColor: kito.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(children: [
        KitoStoryTray(
          itemCount: _friends.length,
          titleBuilder: (i) => _friends[i].name,
          isSeen: (i) => _friends[i].seen || _seen.contains(i),
          isLive: (i) => _friends[i].live,
          avatarBuilder: (_, i) => _Initials(_friends[i]),
          yourStory: KitoYourStory(
              initials: 'WN',
              onTap: () => devKitToasts.info('Add to your story')),
          onSelect: _open,
        ),
        const Divider(height: 24),
        for (final place in _lodges.take(3))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(height: 160, child: _Scene(place)),
          ),
      ]),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage(this.friend, this.segment);

  final _Friend friend;
  final int segment;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final (caption, icon, _) = friend.stories[segment];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            friend.colors.first,
            friend.colors.last,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 120, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 16),
          Text(caption,
              textAlign: TextAlign.center,
              style: kito.typography.title
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _Rings extends StatelessWidget {
  const _Rings();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    Widget ring(String label, KitoStoryRing child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 10),
            Text(label,
                style: kito.typography.caption.copyWith(
                    color: kito.colors.onSurface.withValues(alpha: 0.6))),
          ],
        );
    return Wrap(spacing: 20, runSpacing: 16, children: [
      ring('New', KitoStoryRing(child: _Initials(_friends[0]))),
      ring('Seen', KitoStoryRing(isSeen: true, child: _Initials(_friends[3]))),
      ring('Live', KitoStoryRing(isLive: true, child: _Initials(_friends[1]))),
      ring('Loading',
          KitoStoryRing(isLoading: true, child: _Initials(_friends[2]))),
      ring(
          'Tinted',
          KitoStoryRing(
              tint: const Color(0xFF00C853), child: _Initials(_friends[4]))),
    ]);
  }
}

// MARK: - Scroll containers

class _Guide extends StatefulWidget {
  const _Guide();

  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> {
  var _area = 0;
  static const _areas = ['Stone Town', 'Nungwi', 'Paje', 'Jambiani'];

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      body: KitoParallaxHeader(
        title: 'Zanzibar',
        subtitle: 'Stone Town · Nungwi · Paje',
        height: 300,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: kito.colors.onBackground,
          tooltip: 'Back',
        ),
        header: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9), Color(0xFFFDE68A)],
              stops: [0, 0.6, 1],
            ),
          ),
          child: Stack(children: [
            Positioned(
              right: 30,
              top: 60,
              child: Icon(Icons.wb_sunny_rounded,
                  size: 70, color: Color(0xFFFFF59D)),
            ),
            Positioned(
              left: 20,
              bottom: 40,
              child: Icon(Icons.sailing_rounded,
                  size: 90, color: Color(0xCCFFFFFF)),
            ),
          ]),
        ),
        pinnedHeader: SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _areas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(_areas[i]),
              selected: _area == i,
              onSelected: (_) => setState(() => _area = i),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (title, body) in const [
                (
                  'Forodhani Gardens',
                  'Zanzibar pizza and sugarcane juice as the sun goes down over the harbour.'
                ),
                (
                  'Spice farm tour',
                  'Cloves, vanilla and cinnamon straight from the tree, then a Swahili lunch.'
                ),
                (
                  'Prison Island',
                  'Giant Aldabra tortoises and snorkelling on the reef nearby.'
                ),
                (
                  'Nungwi dhow cruise',
                  'Sail out at golden hour with fresh fruit and taarab music.'
                ),
                (
                  'Jozani Forest',
                  'Red colobus monkeys found nowhere else on earth.'
                ),
                (
                  'Paje kite beach',
                  'Steady trade winds and shallow turquoise water for beginners.'
                ),
              ]) ...[
                Text(title,
                    style: kito.typography.headline
                        .copyWith(color: kito.colors.onBackground)),
                const SizedBox(height: 4),
                Text(body,
                    style: kito.typography.body.copyWith(
                        color:
                            kito.colors.onBackground.withValues(alpha: 0.7))),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Reels extends StatefulWidget {
  const _Reels();

  @override
  State<_Reels> createState() => _ReelsState();
}

class _ReelsState extends State<_Reels> {
  var _active = 0;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        KitoPagedList(
          itemCount: _lodges.length,
          onPageChanged: (i) => setState(() => _active = i),
          itemBuilder: (_, i, isActive) {
            final place = _lodges[i];
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [...place.colors, Colors.black],
                ),
              ),
              child: Stack(children: [
                Center(
                  child: AnimatedScale(
                    scale: isActive ? 1 : 0.7,
                    duration: KitoMotion.of(context, kito.motion.slow),
                    curve: kito.motion.spring,
                    child: Icon(
                        isActive ? place.icon : Icons.play_arrow_rounded,
                        size: 130,
                        color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
                PositionedDirectional(
                  start: 18,
                  end: 70,
                  bottom: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          style: kito.typography.title.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(place.detail,
                          style: kito.typography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
        PositionedDirectional(
          top: 24,
          end: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(kito.radii.pill),
            ),
            child: Text('${_active + 1} / ${_lodges.length}',
                style: kito.typography.caption.copyWith(color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu();

  static const _items = [
    ('Chips mayai', 'KES 250', Icons.egg_rounded),
    ('Mutura', 'KES 100', Icons.kebab_dining_rounded),
    ('Samosa', 'KES 50', Icons.bakery_dining_rounded),
    ('Bhajia', 'KES 200', Icons.lunch_dining_rounded),
    ('Pilau', 'KES 400', Icons.rice_bowl_rounded),
    ('Matoke', 'KES 350', Icons.eco_rounded),
    ('Kachumbari', 'KES 80', Icons.local_florist_rounded),
    ('Tilapia', 'KES 900', Icons.set_meal_rounded),
    ('Mahamri', 'KES 40', Icons.breakfast_dining_rounded),
    ('Chai', 'KES 60', Icons.coffee_rounded),
    ('Dawa', 'KES 300', Icons.local_bar_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return KitoSnapGrid(
      itemCount: _items.length,
      rows: 3,
      padding: 0,
      itemBuilder: (_, i) {
        final (name, price, icon) = _items[i];
        return Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kito.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kito.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: kito.typography.bodyEmphasized
                        .copyWith(color: kito.colors.onSurface)),
                Text(price,
                    style: kito.typography.caption.copyWith(
                        color: kito.colors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => devKitToasts.success('$name added'),
            child: const Text('Add'),
          ),
        ]);
      },
    );
  }
}

class _Towns extends StatelessWidget {
  const _Towns();

  static const _names = [
    'Nairobi',
    'Mombasa',
    'Kisumu',
    'Nakuru',
    'Eldoret',
    'Lamu',
    'Diani',
    'Naivasha',
    'Nanyuki',
    'Malindi',
  ];

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: 44,
        child: KitoInfiniteMarquee(
          itemCount: _names.length,
          speed: 36,
          tint: kito.colors.onSurface,
          itemBuilder: (_, i) => Text(_names[i],
              style: kito.typography.headline
                  .copyWith(color: kito.colors.onSurface)),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 40,
        child: KitoInfiniteMarquee(
          itemCount: _lodges.length,
          speed: 24,
          spacing: 10,
          direction: KitoMarqueeDirection.trailing,
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _lodges[i].colors),
              borderRadius: BorderRadius.circular(kito.radii.pill),
            ),
            child: Text(_lodges[i].name,
                style: kito.typography.label.copyWith(color: Colors.white)),
          ),
        ),
      ),
    ]);
  }
}
