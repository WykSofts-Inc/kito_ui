// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// A phone-sized frame for samples that need their own screen, with a button to open it
/// full screen.
class PhoneStage extends StatelessWidget {
  const PhoneStage({super.key, required this.builder, this.height = 360});

  /// Builds the screen shown in the frame and full screen.
  final WidgetBuilder builder;

  /// The frame's height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 300,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: t.colors.border, width: 6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Builder(builder: builder),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Full screen')),
              body: Builder(builder: builder),
            ),
          )),
          icon: const Icon(Icons.open_in_full_rounded),
          label: const Text('Open full screen'),
        ),
      ],
    );
  }
}
