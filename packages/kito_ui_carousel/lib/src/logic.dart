// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

/// Index maths for looping carousels.
abstract final class KitoCarouselLoopMath {
  /// [index] wrapped into `0..<count`, negatives included; 0 when [count] is 0.
  static int wrap(int index, int count) {
    if (count <= 0) return 0;
    final r = index % count;
    return r < 0 ? r + count : r;
  }

  /// The virtual position nearest [current] that shows [real], so a jump takes the shortest
  /// way round (from the last item to the first is one step forward).
  static int nearestVirtual(int real, int current, int count) {
    if (count <= 0) return current;
    var delta = wrap(real, count) - wrap(current, count);
    final half = count ~/ 2;
    if (delta > half) {
      delta -= count;
    } else if (delta < -half) {
      delta += count;
    }
    return current + delta;
  }

  /// [index] moved by [delta], wrapping when [wraps] and clamping otherwise.
  static int step(int index, int delta, int count, {required bool wraps}) {
    if (count <= 0) return 0;
    final target = index + delta;
    return wraps ? wrap(target, count) : target.clamp(0, count - 1);
  }
}

/// Why auto-play is holding.
enum KitoCarouselPauseReason {
  /// A finger is down or the carousel is moving.
  touch,

  /// The app asked it to hold (off screen, a sheet is up).
  external,

  /// A screen reader or switch control is in use.
  accessibility,
}

/// The auto-play clock: time spent on the current page, and the reasons it's holding.
class KitoCarouselAutoPlayClock {
  /// Creates a clock that advances every [interval].
  KitoCarouselAutoPlayClock(this.interval);

  /// How long each page stays.
  Duration interval;

  Duration _elapsed = Duration.zero;
  final Set<KitoCarouselPauseReason> _reasons = {};

  /// Time on the current page, while not paused.
  Duration get elapsed => _elapsed;

  /// Everything holding the clock.
  Set<KitoCarouselPauseReason> get pauseReasons => Set.unmodifiable(_reasons);

  /// True while anything holds it.
  bool get isPaused => _reasons.isNotEmpty;

  /// How far through the current page, 0–1; drives progress indicators.
  double get progress => interval <= Duration.zero
      ? 0
      : (_elapsed.inMicroseconds / interval.inMicroseconds).clamp(0.0, 1.0);

  /// Moves the clock on by [delta]. Returns true when it's time to advance, and starts the
  /// next page from zero.
  bool tick(Duration delta) {
    if (isPaused || interval <= Duration.zero || delta <= Duration.zero) {
      return false;
    }
    _elapsed += delta;
    if (_elapsed < interval) return false;
    _elapsed = Duration.zero;
    return true;
  }

  /// Holds the clock for [reason].
  void pause(
          [KitoCarouselPauseReason reason =
              KitoCarouselPauseReason.external]) =>
      _reasons.add(reason);

  /// Releases [reason]; the clock runs once nothing else holds it.
  void resume(
          [KitoCarouselPauseReason reason =
              KitoCarouselPauseReason.external]) =>
      _reasons.remove(reason);

  /// Starts the current page again, e.g. after a manual swipe.
  void restart() => _elapsed = Duration.zero;
}

/// The worm page indicator's extent, in page units.
@immutable
class KitoCarouselWormSpan {
  /// Creates a span.
  const KitoCarouselWormSpan(this.lower, this.upper);

  /// The trailing end, as a page position.
  final double lower;

  /// The leading end, as a page position.
  final double upper;

  /// How many pages it covers beyond one dot.
  double get length => upper - lower;

  @override
  bool operator ==(Object other) =>
      other is KitoCarouselWormSpan &&
      other.lower == lower &&
      other.upper == upper;

  @override
  int get hashCode => Object.hash(lower, upper);

  @override
  String toString() => 'KitoCarouselWormSpan($lower, $upper)';
}

/// The maths behind the worm indicator: the head races ahead to the next dot, then the tail
/// catches up.
abstract final class KitoCarouselWormMath {
  /// The span at a fractional page [position] (2.25 is a quarter of the way from 2 to 3).
  static KitoCarouselWormSpan span(double position) {
    final base = position.floorToDouble();
    final t = position - base;
    final head = base + math.min(1, t * 2);
    final tail = base + math.max(0, t * 2 - 1);
    return KitoCarouselWormSpan(math.min(head, tail), math.max(head, tail));
  }

  /// The worm's start and width in pixels, for dots [dotSize] wide set [spacing] apart.
  static (double, double) frame(double position,
      {required double dotSize, required double spacing}) {
    final step = dotSize + spacing;
    final s = span(position);
    return (s.lower * step, s.length * step + dotSize);
  }
}

/// Where a swipe-deck card went.
enum KitoSwipeDeckDirection {
  /// Pass ("nope").
  left,

  /// Like.
  right,

  /// Super like.
  up,
}

/// How close a drag is to each swipe threshold, 0–1 per direction.
@immutable
class KitoSwipeDeckProgress {
  /// Creates progress.
  const KitoSwipeDeckProgress({this.left = 0, this.right = 0, this.up = 0});

  /// Towards a pass.
  final double left;

  /// Towards a like.
  final double right;

  /// Towards a super like.
  final double up;

  /// The strongest direction, or null at rest.
  KitoSwipeDeckDirection? get dominant {
    final best = math.max(left, math.max(right, up));
    if (best <= 0) return null;
    if (best == right) return KitoSwipeDeckDirection.right;
    if (best == left) return KitoSwipeDeckDirection.left;
    return KitoSwipeDeckDirection.up;
  }

  /// The strongest amount.
  double get amount => math.max(left, math.max(right, up));
}

/// Distance and velocity thresholds for throwing a swipe-deck card.
@immutable
class KitoSwipeDeckDecision {
  /// Creates thresholds.
  const KitoSwipeDeckDecision(
      {this.distanceThreshold = 0.32,
      this.velocityThreshold = 650,
      this.allowsUp = true});

  /// The fraction of the card's size a drag must cover, 0–1.
  final double distanceThreshold;

  /// Release speed, in logical pixels per second, that throws the card regardless of distance.
  final double velocityThreshold;

  /// Whether throwing up counts (super like).
  final bool allowsUp;

  /// Where a card released at [translation] with [velocity] goes, or null to spring back.
  /// Directions are physical: right is always like.
  KitoSwipeDeckDirection? direction(
      Offset translation, Offset velocity, Size size) {
    final width = math.max(size.width, 1.0),
        height = math.max(size.height, 1.0);
    final dx = translation.dx, dy = translation.dy;
    if (allowsUp && dy < 0 && -dy > dx.abs()) {
      final far = -dy > height * distanceThreshold;
      final flung = -velocity.dy > velocityThreshold;
      final flickedBack = velocity.dy > velocityThreshold;
      if ((far && !flickedBack) || flung) return KitoSwipeDeckDirection.up;
    }
    final horizontal =
        dx >= 0 ? KitoSwipeDeckDirection.right : KitoSwipeDeckDirection.left;
    final along = velocity.dx * (dx >= 0 ? 1 : -1);
    if (dx.abs() > width * distanceThreshold) {
      return along < -velocityThreshold ? null : horizontal;
    }
    if (dx.abs() > 16 && along > velocityThreshold) return horizontal;
    return null;
  }

  /// How close [translation] is to each threshold.
  KitoSwipeDeckProgress progress(Offset translation, Size size) {
    final w = math.max(size.width * distanceThreshold, 1.0);
    final h = math.max(size.height * distanceThreshold, 1.0);
    final horizontal = translation.dx.abs() >= -translation.dy;
    return KitoSwipeDeckProgress(
      left: horizontal ? (-translation.dx / w).clamp(0.0, 1.0) : 0,
      right: horizontal ? (translation.dx / w).clamp(0.0, 1.0) : 0,
      up: allowsUp && !horizontal ? (-translation.dy / h).clamp(0.0, 1.0) : 0,
    );
  }

  /// The tilt, in radians, for a card dragged [translation] across a card [width] wide.
  static double rotation(Offset translation, double width,
      {double maxDegrees = 14}) {
    if (width <= 0) return 0;
    final limit = maxDegrees * 1.6;
    final degrees = (translation.dx / width * limit).clamp(-limit, limit);
    return degrees * math.pi / 180;
  }

  /// Where a thrown card ends up, off screen, continuing the throw.
  static Offset exitOffset(KitoSwipeDeckDirection direction, Offset translation,
      Offset velocity, Size size) {
    final x = math.max(size.width, 1.0) * 1.6;
    final y = math.max(size.height, 1.0) * 1.5;
    return switch (direction) {
      KitoSwipeDeckDirection.left =>
        Offset(-x, translation.dy + velocity.dy * 0.12),
      KitoSwipeDeckDirection.right =>
        Offset(x, translation.dy + velocity.dy * 0.12),
      KitoSwipeDeckDirection.up =>
        Offset(translation.dx + velocity.dx * 0.12, -y),
    };
  }
}

/// What a [KitoStoryPlayback] call did, so a viewer can animate the right thing.
enum KitoStoryPlaybackEvent {
  /// Nothing changed.
  none,

  /// The same person's next story.
  advancedSegment,

  /// The next person's first story.
  advancedUser,

  /// The same person's previous story.
  wentBackSegment,

  /// The previous person.
  wentBackUser,

  /// The first story started over.
  restartedSegment,

  /// The last story finished.
  finished,
}

/// The story viewer's state machine: whose story, which segment, how far through, paused or
/// finished. People with no stories are skipped.
class KitoStoryPlayback {
  /// Starts on [startingUser], or the next person with stories.
  KitoStoryPlayback(List<int> segmentCounts, {int startingUser = 0})
      : segmentCounts =
            List.unmodifiable(segmentCounts.map((c) => math.max(c, 0))) {
    final start = math.min(
        math.max(startingUser, 0), math.max(this.segmentCounts.length - 1, 0));
    final first = _firstPlayable(start);
    if (first == null) {
      _user = start;
      _finished = true;
    } else {
      _user = first;
    }
  }

  /// Stories per person.
  final List<int> segmentCounts;

  int _user = 0;
  int _segment = 0;
  double _progress = 0;
  bool _paused = false;
  bool _finished = false;

  /// The person showing.
  int get user => _user;

  /// Their story showing.
  int get segment => _segment;

  /// How far through it, 0–1.
  double get progress => _progress;

  /// Held (finger down, typing a reply).
  bool get isPaused => _paused;

  /// The last story has played out.
  bool get isFinished => _finished;

  /// Stories the current person has.
  int get segmentCount =>
      _user < segmentCounts.length ? segmentCounts[_user] : 0;

  /// Whether someone with stories comes next.
  bool get hasNextUser => nextPlayableUser(_user) != null;

  /// Whether someone with stories comes before.
  bool get hasPreviousUser => previousPlayableUser(_user) != null;

  /// How full segment [index]'s bar is: earlier ones full, the current one partly, later empty.
  double fill(int index) => index < _segment
      ? 1
      : index == _segment
          ? _progress
          : 0;

  /// Runs the timer; a story that runs out moves on as [next] would.
  KitoStoryPlaybackEvent tick(Duration delta, Duration duration) {
    if (_paused || _finished || delta <= Duration.zero) {
      return KitoStoryPlaybackEvent.none;
    }
    if (duration <= Duration.zero) return next();
    _progress += delta.inMicroseconds / duration.inMicroseconds;
    return _progress >= 1 ? next() : KitoStoryPlaybackEvent.none;
  }

  /// The next story, the next person's first, or finished.
  KitoStoryPlaybackEvent next() {
    if (_finished) return KitoStoryPlaybackEvent.none;
    if (_segment + 1 < segmentCount) {
      _segment++;
      _progress = 0;
      return KitoStoryPlaybackEvent.advancedSegment;
    }
    final n = nextPlayableUser(_user);
    if (n != null) {
      _user = n;
      _segment = 0;
      _progress = 0;
      return KitoStoryPlaybackEvent.advancedUser;
    }
    _progress = 1;
    _finished = true;
    return KitoStoryPlaybackEvent.finished;
  }

  /// The previous story, the previous person's last, or the first story again.
  KitoStoryPlaybackEvent previous() {
    if (_finished) return KitoStoryPlaybackEvent.none;
    if (_segment > 0) {
      _segment--;
      _progress = 0;
      return KitoStoryPlaybackEvent.wentBackSegment;
    }
    final p = previousPlayableUser(_user);
    if (p != null) {
      _user = p;
      _segment = math.max(segmentCounts[p] - 1, 0);
      _progress = 0;
      return KitoStoryPlaybackEvent.wentBackUser;
    }
    _progress = 0;
    return KitoStoryPlaybackEvent.restartedSegment;
  }

  /// Opens [index]'s first story, as a swipe between people does.
  KitoStoryPlaybackEvent jumpToUser(int index) {
    if (index < 0 ||
        index >= segmentCounts.length ||
        segmentCounts[index] <= 0 ||
        index == _user) {
      return KitoStoryPlaybackEvent.none;
    }
    final forward = index > _user;
    _user = index;
    _segment = 0;
    _progress = 0;
    _finished = false;
    return forward
        ? KitoStoryPlaybackEvent.advancedUser
        : KitoStoryPlaybackEvent.wentBackUser;
  }

  /// Holds the timer.
  void pause() => _paused = true;

  /// Releases the timer.
  void resume() => _paused = false;

  /// The next person with stories after [index].
  int? nextPlayableUser(int index) {
    for (var i = index + 1; i < segmentCounts.length; i++) {
      if (segmentCounts[i] > 0) return i;
    }
    return null;
  }

  /// The nearest person with stories before [index].
  int? previousPlayableUser(int index) {
    for (var i = math.min(index, segmentCounts.length) - 1; i >= 0; i--) {
      if (segmentCounts[i] > 0) return i;
    }
    return null;
  }

  int? _firstPlayable(int from) {
    for (var i = from; i < segmentCounts.length; i++) {
      if (segmentCounts[i] > 0) return i;
    }
    return null;
  }
}
