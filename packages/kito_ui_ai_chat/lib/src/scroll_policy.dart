// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

/// Decides when a streaming conversation should follow new text and when it should leave the
/// reader alone.
///
/// It follows while the bottom is in view. When the distance from the bottom grows by more than
/// the content (or a shrinking viewport, like the keyboard) explains, the reader scrolled up —
/// so it pauses and offers "Jump to latest". Scrolling back near the bottom, jumping, or sending
/// a message resumes following.
///
/// ```dart
/// final policy = KitoAiAutoScrollPolicy();
/// policy.observe(distanceFromBottom: 420, contentHeight: 2000, viewportHeight: 700);
/// policy.isFollowing;         // false — the reader scrolled up
/// policy.showsJumpToLatest;   // true
/// ```
class KitoAiAutoScrollPolicy {
  /// Creates a policy; within [threshold] pixels of the bottom counts as "at the bottom".
  KitoAiAutoScrollPolicy({this.threshold = 56});

  /// Within this many pixels of the bottom counts as "at the bottom".
  final double threshold;

  bool _following = true;
  double _distance = 0;
  double _content = 0;
  double _viewport = 0;
  bool _observed = false;

  /// True when new content should scroll the conversation.
  bool get isFollowing => _following;

  /// The last distance from the bottom seen.
  double get distanceFromBottom => _distance;

  /// True when the "Jump to latest" pill should show.
  bool get showsJumpToLatest => !_following && _distance > threshold;

  /// Call whenever the scroll position, content height or viewport height changes.
  void observe({
    required double distanceFromBottom,
    required double contentHeight,
    required double viewportHeight,
  }) {
    if (distanceFromBottom <= threshold) {
      _following = true;
    } else if (_observed) {
      final growth = contentHeight - _content;
      final shrink = _viewport - viewportHeight;
      final explained = (growth > 0 ? growth : 0) + (shrink > 0 ? shrink : 0);
      final moved = distanceFromBottom - _distance;
      if (moved > explained + 1) _following = false;
    }
    _distance = distanceFromBottom;
    _content = contentHeight;
    _viewport = viewportHeight;
    _observed = true;
  }

  /// The reader tapped "Jump to latest".
  void jumpToLatest() => _following = true;

  /// The reader sent a message — always bring it into view.
  void didSendMessage() => _following = true;
}
