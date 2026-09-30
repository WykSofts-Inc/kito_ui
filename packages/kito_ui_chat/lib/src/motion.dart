// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

/// [duration], or one millisecond when it's zero (Reduce Motion) — `AnimatedSize` can't lay
/// out with a zero duration.
Duration kitoChatSizeDuration(Duration duration) =>
    duration == Duration.zero ? const Duration(milliseconds: 1) : duration;
