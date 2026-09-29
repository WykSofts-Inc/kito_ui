// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'loader_strings.dart';
import 'shimmer.dart';

/// A ready-made placeholder layout for [KitoLoaderSkeletonView].
enum KitoLoaderSkeletonTemplate {
  /// Avatar, two lines and a trailing pill — contacts, transactions, settings.
  listRow,

  /// A cover image, a title, two lines and a footer.
  card,

  /// A big avatar, name, handle, three stats and a button.
  profile,

  /// A social post: header, text, a photo and an action row.
  feedPost,

  /// Chat bubbles, alternating sides.
  chat,

  /// A two-column grid of tiles with captions — a product catalogue.
  grid,

  /// A headline, byline, hero image and paragraphs.
  article;

  /// A stable 0.55–1 width for line [line] of row [row], so rows look hand-set rather than
  /// machine-stamped.
  static double lineFraction(int row, int line) {
    final seed = (row * 7919 + line * 104729) & 0xFFFF;
    return 0.55 + (seed % 1000) / 1000 * 0.45;
  }
}

/// Placeholder content in the shape of what's coming — a list, a card, a profile, a feed —
/// shimmering in one coherent sweep.
///
/// ```dart
/// KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.listRow, count: 6)
/// ```
class KitoLoaderSkeletonView extends StatelessWidget {
  /// Creates a skeleton layout; [count] is at least 1.
  const KitoLoaderSkeletonView(
    this.template, {
    super.key,
    this.count = 1,
    this.spacing = 20,
    this.animating = true,
  });

  /// Which layout.
  final KitoLoaderSkeletonTemplate template;

  /// How many items (rows of two for [KitoLoaderSkeletonTemplate.grid]).
  final int count;

  /// Space between items.
  final double spacing;

  /// Shimmer.
  final bool animating;

  @override
  Widget build(BuildContext context) {
    final fill = context.kito.colors.surfaceMuted;
    final b = _Blocks(fill);
    final n = count < 1 ? 1 : count;
    final items = [
      for (var row = 0; row < n; row++)
        switch (template) {
          KitoLoaderSkeletonTemplate.listRow => b.listRow(row),
          KitoLoaderSkeletonTemplate.card => b.card(row),
          KitoLoaderSkeletonTemplate.profile => b.profile(),
          KitoLoaderSkeletonTemplate.feedPost => b.feedPost(row),
          KitoLoaderSkeletonTemplate.chat => b.chat(row),
          KitoLoaderSkeletonTemplate.grid => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: b.gridTile(row * 2)),
                const SizedBox(width: 14),
                Expanded(child: b.gridTile(row * 2 + 1)),
              ],
            ),
          KitoLoaderSkeletonTemplate.article => b.article(row),
        },
    ];
    return Semantics(
      container: true,
      label: KitoLoaderStrings.of(context, 'loading'),
      child: ExcludeSemantics(
        child: KitoLoaderShimmer(
          enabled: animating,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                items[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Blocks {
  _Blocks(this.fill);
  final Color fill;

  Widget box({double? width, double? height, double radius = 6}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: fill, borderRadius: BorderRadius.circular(radius)),
      );

  Widget circle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      );

  Widget pill(double width, double height) =>
      box(width: width, height: height, radius: height / 2);

  Widget line(double fraction, double height) => FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: box(height: height, radius: height / 2),
      );

  Widget aspect(double ratio, {double radius = 18}) =>
      AspectRatio(aspectRatio: ratio, child: box(radius: radius));

  double f(int row, int line) =>
      KitoLoaderSkeletonTemplate.lineFraction(row, line);

  Widget listRow(int row) => Row(children: [
        circle(46),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            line(f(row, 0), 12),
            const SizedBox(height: 8),
            line(f(row, 1) * 0.6, 10),
          ]),
        ),
        const SizedBox(width: 14),
        pill(54, 22),
      ]);

  Widget card(int row) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: fill, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          aspect(16 / 9),
          const SizedBox(height: 12),
          line(0.7, 16),
          const SizedBox(height: 12),
          line(f(row, 1), 10),
          const SizedBox(height: 12),
          line(f(row, 2) * 0.8, 10),
          const SizedBox(height: 16),
          Row(children: [
            circle(26),
            const SizedBox(width: 10),
            Expanded(child: line(0.5, 10)),
            pill(70, 28),
          ]),
        ]),
      );

  Widget profile() => Column(children: [
        circle(88),
        const SizedBox(height: 14),
        box(width: 150, height: 16),
        const SizedBox(height: 14),
        box(width: 96, height: 11, radius: 5),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 28),
            Column(children: [
              box(width: 40, height: 16, radius: 5),
              const SizedBox(height: 6),
              box(width: 54, height: 9, radius: 4),
            ]),
          ],
        ]),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: box(height: 44, radius: 22),
        ),
      ]);

  Widget feedPost(int row) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          circle(38),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            box(width: 120, height: 11, radius: 5),
            const SizedBox(height: 6),
            box(width: 70, height: 9, radius: 4),
          ]),
          const Spacer(),
          pill(22, 8),
        ]),
        const SizedBox(height: 12),
        line(f(row, 0), 10),
        const SizedBox(height: 12),
        line(f(row, 1) * 0.75, 10),
        const SizedBox(height: 12),
        aspect(4 / 3, radius: 20),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            circle(24),
          ],
          const Spacer(),
          box(width: 60, height: 10, radius: 4),
        ]),
      ]);

  Widget chat(int row) {
    final fromMe = row.isOdd;
    final width = 0.45 + f(row, 3) * 0.35;
    final bubble = FractionallySizedBox(
      widthFactor: width,
      alignment: fromMe
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        height: row % 3 == 0 ? 56 : 38,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(18),
            topEnd: const Radius.circular(18),
            bottomStart: Radius.circular(fromMe ? 18 : 4),
            bottomEnd: Radius.circular(fromMe ? 4 : 18),
          ),
        ),
      ),
    );
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (!fromMe) ...[circle(28), const SizedBox(width: 8)],
      Expanded(child: bubble),
    ]);
  }

  Widget gridTile(int index) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        aspect(1),
        const SizedBox(height: 8),
        line(f(index, 0), 11),
        const SizedBox(height: 8),
        box(width: 48, height: 10, radius: 4),
      ]);

  Widget article(int row) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        line(0.95, 20),
        const SizedBox(height: 12),
        line(0.6, 20),
        const SizedBox(height: 12),
        Row(children: [
          circle(22),
          const SizedBox(width: 8),
          box(width: 110, height: 9, radius: 4),
        ]),
        const SizedBox(height: 12),
        box(height: 170, radius: 20),
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(height: 12),
          line(i == 3 ? 0.55 : f(row, i), 10),
        ],
      ]);
}
