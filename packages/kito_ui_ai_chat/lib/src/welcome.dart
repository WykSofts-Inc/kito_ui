// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'orb.dart';
import 'parts.dart';
import 'text.dart';

/// The empty conversation: an animated orb, "Good evening, Wycliff" and a subtitle, rising in.
///
/// ```dart
/// const KitoAiWelcome(name: 'Wycliff N')
/// ```
class KitoAiWelcome extends StatelessWidget {
  /// Creates a welcome.
  const KitoAiWelcome({
    super.key,
    this.name,
    this.greeting,
    this.subtitle = 'How can I help you today?',
    this.date,
    this.orbSize = 72,
    this.tint,
  });

  /// The person's name; only the first word is used.
  final String? name;

  /// Replaces "Good evening, …".
  final String? greeting;

  /// The line under the greeting.
  final String subtitle;

  /// The time the greeting is for; now when null.
  final DateTime? date;

  /// The orb's diameter.
  final double orbSize;

  /// The orb colour; the theme's primary when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final title = greeting ?? KitoAiGreeting.text(date: date, name: name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AiEntrance(dy: 0, child: KitoAiOrb(size: orbSize, tint: tint)),
        SizedBox(height: theme.spacing.lg),
        AiEntrance(
          delay: const Duration(milliseconds: 80),
          child: Semantics(
            header: true,
            child: Text(title,
                textAlign: TextAlign.center,
                style: theme.typography.title
                    .copyWith(color: theme.colors.onSurface)),
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        AiEntrance(
          delay: const Duration(milliseconds: 160),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style:
                  theme.typography.body.copyWith(color: aiMuted(theme, 0.55))),
        ),
      ],
    );
  }
}
