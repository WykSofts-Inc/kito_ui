// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A [SizedBox] for gallery samples that takes [width] when there's room and
/// shrinks to the space available otherwise, so samples fit small phones and
/// narrow desktop windows.
class DemoWidth extends StatelessWidget {
  const DemoWidth({super.key, required this.width, this.height, this.child});

  final double width;
  final double? height;
  final Widget? child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SizedBox(
          width: math.min(width, box.maxWidth),
          height: height,
          child: child,
        ),
      );
}
