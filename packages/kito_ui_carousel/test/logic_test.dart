// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_carousel/kito_ui_carousel.dart';

void main() {
  group('loop maths', () {
    test('wraps negatives and empty counts', () {
      expect(KitoCarouselLoopMath.wrap(7, 5), 2);
      expect(KitoCarouselLoopMath.wrap(-1, 5), 4);
      expect(KitoCarouselLoopMath.wrap(3, 0), 0);
    });

    test('takes the short way round', () {
      // From the last item to the first is one step forward.
      expect(KitoCarouselLoopMath.nearestVirtual(0, 5004, 5), 5005);
      expect(KitoCarouselLoopMath.nearestVirtual(4, 5000, 5), 4999);
      expect(KitoCarouselLoopMath.nearestVirtual(2, 5000, 5), 5002);
    });

    test('steps wrap or clamp', () {
      expect(KitoCarouselLoopMath.step(4, 1, 5, wraps: true), 0);
      expect(KitoCarouselLoopMath.step(4, 1, 5, wraps: false), 4);
      expect(KitoCarouselLoopMath.step(0, -1, 5, wraps: true), 4);
    });
  });

  group('auto-play clock', () {
    test('advances once per interval and restarts', () {
      final clock = KitoCarouselAutoPlayClock(const Duration(seconds: 4));
      expect(clock.tick(const Duration(seconds: 3)), isFalse);
      expect(clock.progress, closeTo(0.75, 1e-9));
      expect(clock.tick(const Duration(seconds: 1)), isTrue);
      expect(clock.elapsed, Duration.zero);
    });

    test('stacked pause reasons hold until all are released', () {
      final clock = KitoCarouselAutoPlayClock(const Duration(seconds: 1))
        ..pause(KitoCarouselPauseReason.touch)
        ..pause(KitoCarouselPauseReason.accessibility);
      expect(clock.tick(const Duration(seconds: 2)), isFalse);
      clock.resume(KitoCarouselPauseReason.touch);
      expect(clock.isPaused, isTrue);
      clock.resume(KitoCarouselPauseReason.accessibility);
      expect(clock.tick(const Duration(seconds: 2)), isTrue);
    });
  });

  test('the worm head races ahead, then the tail catches up', () {
    expect(KitoCarouselWormMath.span(2), const KitoCarouselWormSpan(2, 2));
    expect(KitoCarouselWormMath.span(2.25), const KitoCarouselWormSpan(2, 2.5));
    expect(KitoCarouselWormMath.span(2.5), const KitoCarouselWormSpan(2, 3));
    expect(KitoCarouselWormMath.span(2.75), const KitoCarouselWormSpan(2.5, 3));
    final (start, width) =
        KitoCarouselWormMath.frame(1.5, dotSize: 8, spacing: 8);
    expect(start, 16);
    expect(width, 24);
  });

  group('swipe decision', () {
    const decision = KitoSwipeDeckDecision();
    const size = Size(300, 500);

    test('distance or a flick throws; a flick back cancels', () {
      expect(decision.direction(const Offset(120, 0), Offset.zero, size),
          KitoSwipeDeckDirection.right);
      expect(decision.direction(const Offset(-120, 10), Offset.zero, size),
          KitoSwipeDeckDirection.left);
      expect(
          decision.direction(const Offset(40, 0), const Offset(900, 0), size),
          KitoSwipeDeckDirection.right);
      expect(
          decision.direction(const Offset(120, 0), const Offset(-900, 0), size),
          isNull);
      expect(
          decision.direction(const Offset(20, 0), Offset.zero, size), isNull);
    });

    test('up is a super like unless turned off', () {
      expect(decision.direction(const Offset(0, -200), Offset.zero, size),
          KitoSwipeDeckDirection.up);
      expect(
          const KitoSwipeDeckDecision(allowsUp: false)
              .direction(const Offset(0, -200), Offset.zero, size),
          isNull);
    });

    test('progress, tilt and exit follow the drag', () {
      final p = decision.progress(const Offset(48, 0), size);
      expect(p.right, closeTo(0.5, 1e-9));
      expect(p.dominant, KitoSwipeDeckDirection.right);
      expect(decision.progress(Offset.zero, size).dominant, isNull);
      expect(KitoSwipeDeckDecision.rotation(const Offset(150, 0), 300),
          greaterThan(0));
      expect(
          KitoSwipeDeckDecision.exitOffset(
                  KitoSwipeDeckDirection.left, Offset.zero, Offset.zero, size)
              .dx,
          lessThan(-300));
    });
  });

  group('story playback', () {
    test('plays through segments and people, skipping the empty', () {
      final p = KitoStoryPlayback([2, 0, 1]);
      expect(p.tick(const Duration(seconds: 2), const Duration(seconds: 5)),
          KitoStoryPlaybackEvent.none);
      expect(p.fill(0), closeTo(0.4, 1e-9));
      expect(p.next(), KitoStoryPlaybackEvent.advancedSegment);
      expect(p.fill(0), 1);
      expect(p.next(), KitoStoryPlaybackEvent.advancedUser);
      expect(p.user, 2);
      expect(p.next(), KitoStoryPlaybackEvent.finished);
      expect(p.isFinished, isTrue);
    });

    test('going back restarts, then returns to the previous person', () {
      final p = KitoStoryPlayback([2, 1], startingUser: 1);
      expect(p.previous(), KitoStoryPlaybackEvent.wentBackUser);
      expect((p.user, p.segment), (0, 1));
      p.previous();
      expect(p.previous(), KitoStoryPlaybackEvent.restartedSegment);
    });

    test('pausing holds the clock and jumping opens a person', () {
      final p = KitoStoryPlayback([1, 3])..pause();
      p.tick(const Duration(seconds: 3), const Duration(seconds: 5));
      expect(p.progress, 0);
      p.resume();
      expect(p.jumpToUser(1), KitoStoryPlaybackEvent.advancedUser);
      expect(p.segmentCount, 3);
      expect(p.jumpToUser(1), KitoStoryPlaybackEvent.none);
      expect(KitoStoryPlayback([0, 0]).isFinished, isTrue);
    });
  });
}
