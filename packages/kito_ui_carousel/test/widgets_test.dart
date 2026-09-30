// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_carousel/kito_ui_carousel.dart';

import 'helpers.dart';

const lodges = [
  'Giraffe Manor',
  'Hemingways',
  'Sarova Stanley',
  'Tribe',
  'Kempinski'
];

Widget card(int i) => ColoredBox(
      color: Colors.primaries[i % Colors.primaries.length],
      child: Center(child: Text(lodges[i % lodges.length])),
    );

Future<void> pumpFor(WidgetTester tester, Duration d) async {
  final steps = d.inMilliseconds ~/ 50;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('carousel', () {
    testWidgets('every effect renders LTR and RTL, with and without motion',
        (tester) async {
      for (final effect in KitoCarouselEffect.values) {
        for (final dir in TextDirection.values) {
          for (final reduce in [false, true]) {
            await tester.pumpWidget(testApp(
              Scaffold(
                body: KitoCarousel(
                  itemCount: 5,
                  effect: effect,
                  loops: true,
                  itemBuilder: (_, i) => card(i),
                ),
              ),
              direction: dir,
              reduceMotion: reduce,
            ));
            await tester.pump(const Duration(milliseconds: 100));
            expect(find.text('Giraffe Manor'), findsWidgets);
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('swiping snaps a page; RTL swipes the other way',
        (tester) async {
      for (final dir in TextDirection.values) {
        final pages = <int>[];
        await tester.pumpWidget(testApp(
          Scaffold(
            body: KitoCarousel(
              key: ValueKey(dir),
              itemCount: 5,
              itemBuilder: (_, i) => card(i),
              onPageChanged: pages.add,
            ),
          ),
          direction: dir,
        ));
        final towardNext = dir == TextDirection.ltr ? -300.0 : 300.0;
        await tester.fling(
            find.byType(KitoCarousel), Offset(towardNext, 0), 1000);
        await pumpFor(tester, const Duration(seconds: 1));
        expect(pages, [1], reason: '$dir');
      }
    });

    testWidgets('the controller moves it and the indicator follows',
        (tester) async {
      final controller = KitoCarouselController();
      final pages = <int>[];
      await tester.pumpWidget(testApp(Scaffold(
        body: Column(children: [
          KitoCarousel(
            itemCount: 5,
            controller: controller,
            loops: true,
            itemBuilder: (_, i) => card(i),
            onPageChanged: pages.add,
          ),
          KitoCarouselPageIndicator(
            count: 5,
            controller: controller,
            style: KitoCarouselIndicatorStyle.numbers,
          ),
        ]),
      )));
      controller.jumpToPage(4);
      await tester.pump();
      expect(controller.page, 4);
      expect(find.text('5'), findsOneWidget);
      controller.next();
      await pumpFor(tester, const Duration(seconds: 1));
      expect(controller.page, 0, reason: 'loops round');
      expect(pages, [4, 0]);
      controller.dispose();
    });

    testWidgets('auto-play advances, and holds while touched', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoCarousel(
          itemCount: 3,
          autoPlay: const Duration(seconds: 2),
          itemBuilder: (_, i) => card(i),
          onPageChanged: pages.add,
        ),
      )));
      await pumpFor(tester, const Duration(milliseconds: 2800));
      expect(pages, [1]);
      final g = await tester
          .startGesture(tester.getCenter(find.byType(KitoCarousel)));
      await pumpFor(tester, const Duration(seconds: 4));
      expect(pages, [1], reason: 'held by the finger');
      await g.up();
      await pumpFor(tester, const Duration(milliseconds: 2800));
      expect(pages, [1, 2]);
    });

    testWidgets('Reduce Motion stops auto-play', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(testApp(
        Scaffold(
          body: KitoCarousel(
            itemCount: 3,
            autoPlay: const Duration(seconds: 1),
            itemBuilder: (_, i) => card(i),
            onPageChanged: pages.add,
          ),
        ),
        reduceMotion: true,
      ));
      await pumpFor(tester, const Duration(seconds: 3));
      expect(pages, isEmpty);
    });

    testWidgets('screen readers hear the page and can change it',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoCarousel(itemCount: 4, itemBuilder: (_, i) => card(i)),
      )));
      final node =
          tester.getSemantics(find.bySemanticsLabel(RegExp('^Carousel')));
      expect(node.value, 'Page 1 of 4');
      node.owner!.performAction(node.id, SemanticsAction.increase);
      await pumpFor(tester, const Duration(seconds: 1));
      expect(
          tester.getSemantics(find.bySemanticsLabel(RegExp('^Carousel'))).value,
          'Page 2 of 4');
      handle.dispose();
    });
  });

  group('page indicator', () {
    testWidgets('every style draws; tapping a dot picks it', (tester) async {
      for (final style in KitoCarouselIndicatorStyle.values) {
        for (final dir in TextDirection.values) {
          await tester.pumpWidget(testApp(
            Scaffold(
              body: Center(
                child: KitoCarouselPageIndicator(
                    count: 6, current: 2, style: style, progress: 0.5),
              ),
            ),
            direction: dir,
          ));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        }
      }
      int? picked;
      await tester.pumpWidget(testApp(Scaffold(
        body: Center(
          child: KitoCarouselPageIndicator(
            count: 4,
            style: KitoCarouselIndicatorStyle.dots,
            onChanged: (i) => picked = i,
          ),
        ),
      )));
      final box = tester.getRect(find.byType(KitoCarouselPageIndicator));
      await tester.tapAt(Offset(box.right - 2, box.center.dy));
      expect(picked, 3);
    });

    testWidgets('banners render with their indicator', (tester) async {
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoBannerCarousel(itemCount: 3, itemBuilder: (_, i) => card(i)),
      )));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(KitoCarouselPageIndicator), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
    });
  });

  group('swipe deck', () {
    Widget deck(
      List<(String, KitoSwipeDeckDirection)> swipes, {
      KitoSwipeDeckController? controller,
      List<String>? undone,
      VoidCallback? onEmpty,
      bool showsControls = true,
    }) =>
        Scaffold(
          body: SizedBox(
            width: 360,
            height: 620,
            child: KitoSwipeDeck<String>(
              items: const ['Nyama choma', 'Pilau', 'Githeri'],
              controller: controller,
              showsControls: showsControls,
              itemBuilder: (_, s) => Center(child: Text(s)),
              onSwipe: (s, d) => swipes.add((s, d)),
              onUndo: (s) => undone?.add(s),
              onEmpty: onEmpty,
            ),
          ),
        );

    for (final dir in TextDirection.values) {
      testWidgets('dragging right likes, whatever the direction ($dir)',
          (tester) async {
        final swipes = <(String, KitoSwipeDeckDirection)>[];
        await tester.pumpWidget(testApp(deck(swipes), direction: dir));
        await tester.drag(find.text('Nyama choma'), const Offset(260, 0));
        await pumpFor(tester, const Duration(seconds: 1));
        expect(swipes, [('Nyama choma', KitoSwipeDeckDirection.right)]);
        await tester.drag(find.text('Pilau'), const Offset(-260, 0));
        await pumpFor(tester, const Duration(seconds: 1));
        expect(swipes.last, ('Pilau', KitoSwipeDeckDirection.left));
      });
    }

    testWidgets('a short drag springs back', (tester) async {
      final swipes = <(String, KitoSwipeDeckDirection)>[];
      await tester.pumpWidget(testApp(deck(swipes)));
      final before = tester.getCenter(find.text('Nyama choma'));
      await tester.timedDrag(find.text('Nyama choma'), const Offset(30, 0),
          const Duration(milliseconds: 600));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(swipes, isEmpty);
      expect(
          tester.getCenter(find.text('Nyama choma')).dx, closeTo(before.dx, 1));
    });

    testWidgets('buttons, undo and the empty state', (tester) async {
      final swipes = <(String, KitoSwipeDeckDirection)>[];
      final undone = <String>[];
      var empty = 0;
      await tester.pumpWidget(
          testApp(deck(swipes, undone: undone, onEmpty: () => empty++)));
      await tester.tap(find.bySemanticsLabel('Like'));
      await pumpFor(tester, const Duration(seconds: 1));
      await tester.tap(find.bySemanticsLabel('Super'));
      await pumpFor(tester, const Duration(seconds: 1));
      await tester.tap(find.bySemanticsLabel('Nope'));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(swipes.map((s) => s.$2), [
        KitoSwipeDeckDirection.right,
        KitoSwipeDeckDirection.up,
        KitoSwipeDeckDirection.left,
      ]);
      expect(empty, 1);
      expect(find.text("You're all caught up"), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Undo').first);
      await pumpFor(tester, const Duration(seconds: 1));
      expect(undone, ['Githeri']);
      expect(find.text('Githeri'), findsOneWidget);
    });

    testWidgets('the controller throws, undoes and reports', (tester) async {
      final swipes = <(String, KitoSwipeDeckDirection)>[];
      final controller = KitoSwipeDeckController();
      await tester.pumpWidget(
          testApp(deck(swipes, controller: controller, showsControls: false)));
      await tester.pump();
      expect(controller.remaining, 3);
      expect(controller.canUndo, isFalse);
      controller.swipe(KitoSwipeDeckDirection.left);
      await pumpFor(tester, const Duration(seconds: 1));
      expect(controller.remaining, 2);
      expect(controller.canUndo, isTrue);
      controller.undo();
      await pumpFor(tester, const Duration(seconds: 1));
      expect(controller.remaining, 3);
      expect(swipes.single.$2, KitoSwipeDeckDirection.left);
      controller.dispose();
    });

    testWidgets('screen-reader actions on the top card', (tester) async {
      final handle = tester.ensureSemantics();
      final swipes = <(String, KitoSwipeDeckDirection)>[];
      await tester.pumpWidget(testApp(deck(swipes, showsControls: false)));
      final node = tester.getSemantics(find.text('Nyama choma'));
      final actions = node.getSemanticsData().customSemanticsActionIds!;
      final like = actions.firstWhere(
          (id) => CustomSemanticsAction.getAction(id)!.label == 'Like');
      node.owner!.performAction(node.id, SemanticsAction.customAction, like);
      await pumpFor(tester, const Duration(seconds: 1));
      expect(swipes.single.$2, KitoSwipeDeckDirection.right);
      handle.dispose();
    });
  });

  group('stacked cards', () {
    testWidgets('tap fans out, tap picks, tap goes back', (tester) async {
      final selections = <int?>[];
      final expanded = <bool>[];
      await tester.pumpWidget(testApp(Scaffold(
        body: SingleChildScrollView(
          child: KitoStackedCards(
            itemCount: 4,
            cardHeight: 180,
            itemBuilder: (_, i) => card(i),
            onSelectionChanged: selections.add,
            onExpandedChanged: expanded.add,
          ),
        ),
      )));
      final collapsed = tester.getSize(find.byType(KitoStackedCards)).height;
      await tester.tap(find.text('Sarova Stanley'));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(expanded, [true]);
      final open = tester.getSize(find.byType(KitoStackedCards)).height;
      expect(open, greaterThan(collapsed));
      // Fanned out, only the top strip of each card behind shows.
      final top = tester.getTopLeft(find.byType(KitoStackedCards));
      await tester.tapAt(top + const Offset(40, 72 + 20));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(selections, [1]);
      await tester.tap(find.text('Hemingways'));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(selections, [1, null]);
    });

    testWidgets('renders RTL and with Reduce Motion', (tester) async {
      for (final dir in TextDirection.values) {
        await tester.pumpWidget(testApp(
          Scaffold(
            body: KitoStackedCards(
              itemCount: 6,
              expanded: true,
              selected: 2,
              itemBuilder: (_, i) => card(i),
            ),
          ),
          direction: dir,
          reduceMotion: true,
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('stories', () {
    testWidgets('rings show their state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp(const Scaffold(
        body: Row(children: [
          KitoStoryRing(child: Text('A')),
          KitoStoryRing(isSeen: true, child: Text('B')),
          KitoStoryRing(isLive: true, child: Text('C')),
          KitoStoryRing(isLoading: true, child: Text('D')),
        ]),
      )));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('LIVE'), findsOneWidget);
      expect(tester.getSemantics(find.text('B')).value, 'Seen');
      handle.dispose();
    });

    testWidgets('the tray spins a ring, then opens it', (tester) async {
      final opened = <int>[];
      var composed = 0;
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoStoryTray(
          itemCount: 3,
          titleBuilder: (i) => ['Amani', 'Baraka', 'Chebet'][i],
          avatarBuilder: (_, i) => card(i),
          isSeen: (i) => i == 2,
          yourStory: KitoYourStory(initials: 'WN', onTap: () => composed++),
          onSelect: opened.add,
        ),
      )));
      await tester.tap(find.text('Baraka'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opened, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));
      expect(opened, [1]);
      await tester.tap(find.text('Your story'));
      expect(composed, 1);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('story viewer', () {
    Widget viewer({
      required List<(int, int)> seen,
      VoidCallback? onDismiss,
      List<(int, int, bool)>? likes,
      List<String>? replies,
      TextDirection direction = TextDirection.ltr,
    }) =>
        testApp(
          Scaffold(
            body: KitoStoryViewer(
              userCount: 3,
              segmentCount: (u) => [2, 0, 1][u],
              titleBuilder: (u) => ['Amani', 'Empty', 'Chebet'][u],
              subtitleBuilder: (u, s) => '${s + 1}h',
              storyBuilder: (_, u, s) => ColoredBox(
                  color: Colors.teal,
                  child: Center(child: Text('story $u.$s'))),
              avatarBuilder: (_, u) => card(u),
              duration: const Duration(seconds: 2),
              onSeen: (u, s) => seen.add((u, s)),
              onLike: (u, s, l) => likes?.add((u, s, l)),
              onReply: (u, s, t) => replies?.add(t),
              onDismiss: onDismiss ?? () {},
            ),
          ),
          direction: direction,
        );

    testWidgets('plays through, skips people without stories, then closes',
        (tester) async {
      final seen = <(int, int)>[];
      var dismissed = 0;
      await tester.pumpWidget(viewer(seen: seen, onDismiss: () => dismissed++));
      await tester.pump();
      expect(find.text('story 0.0'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 2200));
      expect(find.text('story 0.1'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 2200));
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('story 2.0'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 2600));
      expect(seen, [(0, 0), (0, 1), (2, 0)]);
      expect(dismissed, 1);
    });

    for (final dir in TextDirection.values) {
      testWidgets('taps move forward and back ($dir)', (tester) async {
        final seen = <(int, int)>[];
        await tester.pumpWidget(viewer(seen: seen, direction: dir));
        await tester.pump();
        final size = tester.getSize(find.byType(KitoStoryViewer));
        final trailing = dir == TextDirection.ltr ? size.width - 40 : 40.0;
        final leading = dir == TextDirection.ltr ? 40.0 : size.width - 40;
        await tester.tapAt(Offset(trailing, size.height / 2));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('story 0.1'), findsOneWidget);
        await tester.tapAt(Offset(leading, size.height / 2));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('story 0.0'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('holding pauses; swiping sideways changes person',
        (tester) async {
      final seen = <(int, int)>[];
      await tester.pumpWidget(viewer(seen: seen));
      await tester.pump();
      final g = await tester.startGesture(const Offset(400, 300));
      await pumpFor(tester, const Duration(seconds: 3));
      expect(find.text('story 0.0'), findsOneWidget);
      await g.up();
      await tester.pump();
      await tester.fling(find.text('story 0.0'), const Offset(-400, 0), 1500);
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('story 2.0'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('liking bursts a heart and replying sends', (tester) async {
      final likes = <(int, int, bool)>[];
      final replies = <String>[];
      await tester.pumpWidget(viewer(seen: [], likes: likes, replies: replies));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Like'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(likes, [(0, 0, true)]);
      expect(find.bySemanticsLabel('Unlike'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Poa sana!');
      await pumpFor(tester, const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Send'));
      await pumpFor(tester, const Duration(milliseconds: 300));
      expect(replies, ['Poa sana!']);
      expect(find.text('Sent'), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('swiping down and the close button dismiss', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(viewer(seen: [], onDismiss: () => dismissed++));
      await tester.pump();
      await tester.drag(find.text('story 0.0'), const Offset(0, 300));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(dismissed, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(viewer(seen: [], onDismiss: () => dismissed++));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Close'));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(dismissed, 2);
    });
  });

  group('scroll containers', () {
    testWidgets('the parallax header collapses into a title bar',
        (tester) async {
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoParallaxHeader(
          title: 'Zanzibar',
          subtitle: 'Stone Town · Nungwi · Paje',
          header: const ColoredBox(color: Colors.orange),
          pinnedHeader: const SizedBox(height: 44, child: Text('Beaches')),
          child: Column(children: [
            for (var i = 0; i < 30; i++)
              SizedBox(height: 60, child: Text('Row $i')),
          ]),
        ),
      )));
      expect(find.text('Zanzibar'), findsNWidgets(2));
      await tester.drag(find.text('Row 2'), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Beaches'), findsOneWidget);
      final pinned = tester.getRect(find.text('Beaches'));
      expect(pinned.top, lessThan(120));
      await tester.drag(find.text('Row 12'), const Offset(0, 900));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the paged list reports the active page', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(testApp(Scaffold(
        body: KitoPagedList(
          itemCount: 4,
          onPageChanged: pages.add,
          itemBuilder: (_, i, active) =>
              Center(child: Text('Clip $i${active ? ' ▶' : ''}')),
        ),
      )));
      expect(find.text('Clip 0 ▶'), findsOneWidget);
      await tester.fling(find.text('Clip 0 ▶'), const Offset(0, -400), 1200);
      await tester.pumpAndSettle();
      expect(pages, [1]);
      expect(find.text('Clip 1 ▶'), findsOneWidget);
    });

    testWidgets('the snap grid pages by column, LTR and RTL', (tester) async {
      for (final dir in TextDirection.values) {
        await tester.pumpWidget(testApp(
          Scaffold(
            body: KitoSnapGrid(
              itemCount: 10,
              rows: 3,
              itemBuilder: (_, i) => Text('Dish $i'),
            ),
          ),
          direction: dir,
        ));
        expect(find.text('Dish 0'), findsOneWidget);
        final towardNext = dir == TextDirection.ltr ? -500.0 : 500.0;
        await tester.fling(find.text('Dish 0'), Offset(towardNext, 0), 1000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Dish 3'), findsOneWidget);
      }
    });

    testWidgets(
        'the marquee drifts, holds when pressed and stops for Reduce Motion',
        (tester) async {
      Widget marquee(
              {bool reduce = false, TextDirection dir = TextDirection.ltr}) =>
          testApp(
            Scaffold(
              body: KitoInfiniteMarquee(
                itemCount: 3,
                tint: Colors.grey,
                itemBuilder: (_, i) => Text('Partner $i'),
              ),
            ),
            reduceMotion: reduce,
            direction: dir,
          );
      await tester.pumpWidget(marquee());
      await tester.pump(const Duration(milliseconds: 50));
      final start = tester.getTopLeft(find.text('Partner 0').first).dx;
      await tester.pump(const Duration(seconds: 1));
      final later = tester.getTopLeft(find.text('Partner 0').first).dx;
      expect(later, lessThan(start));
      final g = await tester.startGesture(const Offset(200, 300));
      await tester.pump(const Duration(milliseconds: 16));
      final held = tester.getTopLeft(find.text('Partner 0').first).dx;
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getTopLeft(find.text('Partner 0').first).dx, held);
      await g.up();

      await tester.pumpWidget(marquee(dir: TextDirection.rtl));
      await tester.pump(const Duration(milliseconds: 50));
      final rtlStart = tester.getTopLeft(find.text('Partner 0').first).dx;
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getTopLeft(find.text('Partner 0').first).dx,
          greaterThan(rtlStart));

      await tester.pumpWidget(marquee(reduce: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
