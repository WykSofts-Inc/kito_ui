# kito_ui_carousel

Carousels and paging for Flutter: a snapping carousel with seven effects, liquid page
indicators, auto-advancing banners, a swipe deck, Wallet-style stacked cards, story rings with a
full-screen story viewer and a 3D cube turn, a stretchy parallax header, Reels-style vertical
paging, an App Store–style snapping grid and an endless marquee. Part of
[Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything follows `KitoTheme` (light, dark,
neon), right-to-left layouts, text scaling and Reduce Motion.

Pure Flutter, no plugins and no platform setup.

## Install

```yaml
dependencies:
  kito_ui_carousel: ^0.1.0
```

```dart
import 'package:kito_ui_carousel/kito_ui_carousel.dart';
```

## Carousel

```dart
final carousel = KitoCarouselController();

KitoCarousel(
  itemCount: lodges.length,
  itemBuilder: (context, i) => LodgeCard(lodges[i]),
  controller: carousel,
  effect: KitoCarouselEffect.coverFlow,
  peek: 40,
  height: 240,
  loops: true,
  autoPlay: const Duration(seconds: 4),
  onPageChanged: (i) => setState(() => page = i),
);

KitoCarouselPageIndicator(
  count: lodges.length,
  controller: carousel,
  style: KitoCarouselIndicatorStyle.worm,
);
```

Effects: `none`, `scale`, `rotate`, `parallax`, `coverFlow` (3D), `fade` and `stack`. `peek` is
how much of each neighbour shows; `peek: 0` gives full-width pages. `loops` swipes past the end
back to the start forever. Swipes snap with a spring and a selection click; a flick moves one
page.

Auto-play pauses while a finger is down and while a screen reader is running, and stops under
Reduce Motion (which also turns effects off). `carousel.autoPlayProgress` drives your own
progress UI, and `carousel.holdAutoPlay(true)` holds it while the carousel is off screen. The
controller also offers `next`, `previous`, `animateToPage`, `jumpToPage` and a fractional
`position`.

## Page indicator

```dart
KitoCarouselPageIndicator(count: 8, current: page, onChanged: pick);
KitoCarouselPageIndicator(count: 5, controller: carousel, style: KitoCarouselIndicatorStyle.progress);
```

Styles: `dots`, `capsule` (the current dot stretches), `worm` (liquid, follows your finger),
`numbers` ("3 / 8" with chevrons) and `progress` (fills with auto-play). Tap a dot to jump or drag
along the row to scrub.

## Banners

```dart
KitoBannerCarousel(
  itemCount: deals.length,
  itemBuilder: (context, i) => DealBanner(deals[i]),
  interval: const Duration(seconds: 5),
  height: 180,
);
```

Full-width, looping, rounded, with a parallax drift and a progress indicator over a soft scrim.

## Swipe deck

```dart
KitoSwipeDeck<Dish>(
  items: dishes,
  itemBuilder: (context, dish) => DishCard(dish),
  onSwipe: (dish, direction) {
    if (direction == KitoSwipeDeckDirection.right) save(dish);
  },
);
```

Drag to tilt; LIKE / NOPE / SUPER stamps and an edge glow fade in; a long drag or a quick flick
throws the card with momentum, and a short one springs back. Built-in Undo / Nope / Super like /
Like buttons swell as the matching drag builds, or drive it yourself:

```dart
final deck = KitoSwipeDeckController();

KitoSwipeDeck(items: dishes, controller: deck, showsControls: false, itemBuilder: ...);
TextButton(onPressed: () => deck.swipe(KitoSwipeDeckDirection.left), child: const Text('Pass'));
TextButton(onPressed: deck.canUndo ? deck.undo : null, child: const Text('Undo'));
```

The deck stays physical in right-to-left layouts: right is always like. The distance and velocity
rules live in `KitoSwipeDeckDecision`.

## Stacked cards

```dart
KitoStackedCards(
  itemCount: passes.length,
  itemBuilder: (context, i) => PassCard(passes[i]),
  cardHeight: 200,
  onSelectionChanged: (i) => setState(() => pass = i),
);
```

Tap the pile to fan it out, tap a card to bring it forward with the rest tucked beneath, tap it
again to go back. Later cards sit in front, as in Wallet.

## Stories

```dart
KitoStoryTray(
  itemCount: friends.length,
  titleBuilder: (i) => friends[i].name,
  isSeen: (i) => friends[i].seen,
  isLive: (i) => friends[i].live,
  avatarBuilder: (context, i) => Avatar(friends[i]),
  yourStory: KitoYourStory(initials: 'WN', onTap: compose),
  onSelect: open,
);

void open(int index) => Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, _, __) => KitoStoryViewer(
        userCount: friends.length,
        initialUser: index,
        segmentCount: (u) => friends[u].stories.length,
        titleBuilder: (u) => friends[u].name,
        subtitleBuilder: (u, s) => friends[u].stories[s].age,
        storyBuilder: (context, u, s) => StoryPage(friends[u].stories[s]),
        avatarBuilder: (context, u) => Avatar(friends[u]),
        onReply: (u, s, text) => send(text),
        onDismiss: () => Navigator.of(context).pop(),
      ),
    ));
```

The viewer has segmented progress bars; tap the trailing side to go forward and the leading side
to go back, hold to pause, swipe sideways to change person with a 3D cube, swipe down to dismiss,
reply, and like with a heart burst. People with no stories are skipped. `KitoStoryRing` on its
own draws the gradient ring, the grey seen state, a pulsing LIVE badge and a spinning loading
ring. The timing lives in `KitoStoryPlayback`.

## Scroll containers

```dart
KitoParallaxHeader(
  title: 'Zanzibar',
  subtitle: 'Stone Town · Nungwi · Paje',
  header: Image.asset('assets/beach.jpg', fit: BoxFit.cover),
  pinnedHeader: CategoryTabs(),   // optional: sticks under the title bar
  child: GuideSections(),         // or slivers: [...]
);

KitoPagedList(
  itemCount: clips.length,
  itemBuilder: (context, i, isActive) => ClipView(clips[i], playing: isActive),
);

KitoSnapGrid(itemCount: menu.length, rows: 3, itemBuilder: (context, i) => MenuRow(menu[i]));

KitoInfiniteMarquee(
  itemCount: partners.length,
  itemBuilder: (context, i) => PartnerLogo(partners[i]),
  speed: 36,
);
```

- The parallax header stretches when pulled, drifts at half speed and blurs as it collapses,
  and hands over to a compact title bar.
- The paged list shows one page per screen with a haptic on each snap, and eases the leaving page
  back as the next slides in.
- The snap grid fills rows top to bottom, snaps a column to the leading edge and peeks the next.
- The marquee repeats its items to fill the strip, holds while pressed, fades its edges, and
  becomes a plain scroll under Reduce Motion.

## Logic without UI

`KitoCarouselLoopMath` (wrapping and shortest-way jumps), `KitoCarouselAutoPlayClock`
(auto-play with stacked pause reasons), `KitoCarouselWormMath` (the worm indicator),
`KitoSwipeDeckDecision` (swipe thresholds, tilt and exit) and `KitoStoryPlayback` (the story
state machine) are pure and covered by unit tests.

## Right-to-left and accessibility

Carousels, indicators, snap grids, story bars, the cube turn, tap zones and the marquee mirror
with the layout direction: in Arabic or Hebrew the next page sits to the left,
leading marquees drift right and the indicator scrubs from the right. The swipe deck deliberately
stays physical. Carousels and indicators read "Page 3 of 8" and change page with the screen
reader's increase and decrease gestures; the deck offers Like, Nope, Super like and Undo as
actions; the story viewer offers Next story, Previous story, Like and Close. Reduce Motion turns
effects, tilts, the cube and the marquee into plain changes.

## License

MIT — see [LICENSE](LICENSE).
