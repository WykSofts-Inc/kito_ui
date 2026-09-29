// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A full-screen sample shown inside a phone-sized frame, with its own [Navigator] (so sheets,
/// dialogs and pushed pages stay inside the frame) and an "Open full screen" button that pushes
/// the same screen as a real route.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.builder,
    this.width = 360,
    this.height = 620,
  });

  /// Builds the screen, usually a [Scaffold].
  final WidgetBuilder builder;

  /// The frame's logical size; it scales down to fit narrower previews.
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final available =
              constraints.maxWidth.isFinite ? constraints.maxWidth : width;
          final scale = (available / width).clamp(0.5, 1.0);
          final media = MediaQuery.of(context);
          return SizedBox(
            width: width * scale,
            height: height * scale,
            child: FittedBox(
              child: SizedBox(
                width: width,
                height: height,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: theme.colors.border, width: 6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: MediaQuery(
                      data: media.copyWith(
                        size: Size(width, height),
                        padding: const EdgeInsets.only(top: 12),
                        viewPadding: const EdgeInsets.only(top: 12),
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: HeroControllerScope.none(
                        child: Navigator(
                          onGenerateRoute: (_) =>
                              MaterialPageRoute<void>(builder: builder),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (context) => builder(context),
          )),
          icon: const Icon(Icons.open_in_full_rounded, size: 18),
          label: const Text('Open full screen'),
        ),
      ],
    );
  }
}
