// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds every frame with the seconds elapsed since it appeared — the engine behind the
/// continuous loaders, public so you can build your own.
///
/// ```dart
/// KitoLoaderTimeline(builder: (context, seconds, _) =>
///     Transform.rotate(angle: seconds * 2 * pi, child: logo))
/// ```
///
/// It stops ticking while [running] is false and when its [TickerMode] is off (a hidden tab).
class KitoLoaderTimeline extends StatefulWidget {
  /// Creates a timeline.
  const KitoLoaderTimeline(
      {super.key, required this.builder, this.child, this.running = true});

  /// Builds a frame at [seconds]; [child] is passed through untouched.
  final Widget Function(BuildContext context, double seconds, Widget? child)
      builder;

  /// A subtree that doesn't depend on time.
  final Widget? child;

  /// Pause without losing the elapsed time.
  final bool running;

  @override
  State<KitoLoaderTimeline> createState() => _KitoLoaderTimelineState();
}

class _KitoLoaderTimelineState extends State<KitoLoaderTimeline>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _offset = Duration.zero;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _elapsed = _offset + elapsed);
    });
    if (widget.running) _ticker.start();
  }

  @override
  void didUpdateWidget(KitoLoaderTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running && !_ticker.isActive) {
      _offset = _elapsed;
      _ticker.start();
    } else if (!widget.running && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context,
      _elapsed.inMicroseconds / Duration.microsecondsPerSecond, widget.child);
}
