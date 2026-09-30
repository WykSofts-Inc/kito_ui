// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';

/// The gallery for kito_ui_core.
final coreKit = KitEntry(
  title: 'Core',
  package: 'kito_ui_core',
  blurb: 'theme tokens, presets, surfaces and motion',
  icon: Icons.layers_rounded,
  category: KitCategory.foundations,
  isNew: true,
  sections: [
    KitSection('Theme', Icons.palette_rounded, [
      KitSample(
        title: 'Colour roles',
        subtitle: 'The 13 roles every kit draws with.',
        code: '''final colors = context.kito.colors;
Container(color: colors.primary, child: Text('Hi', style: TextStyle(color: colors.onPrimary)));''',
        builder: (_) => const _ColourRoles(),
      ),
      KitSample(
        title: 'Presets',
        subtitle: 'Light, dark and neon, side by side.',
        code: '''MaterialApp(
  theme: KitoTheme.light.toThemeData(),
  darkTheme: KitoTheme.dark.toThemeData(),
);''',
        builder: (_) => const _Presets(),
      ),
      KitSample(
        title: 'Your brand',
        subtitle: 'Swap one token and every kit follows.',
        code: '''final brand = KitoTheme.light.copyWith(
  colors: KitoColors.light.copyWith(primary: const Color(0xFF0E7C66)),
);''',
        builder: (_) => const _Brand(),
      ),
      KitSample(
        title: 'Type scale',
        subtitle: 'Display to caption; scales with the system text size.',
        code:
            '''Text('Weekend picks', style: context.kito.typography.title);''',
        builder: (_) => const _TypeScale(),
      ),
      KitSample(
        title: 'Spacing and radii',
        subtitle: 'The steps kits use for padding and corners.',
        code: '''final s = context.kito.spacing;   // xxs 2 … xxl 32
final r = context.kito.radii;     // sm 6 … xl 24, pill''',
        builder: (_) => const _SpacingRadii(),
      ),
    ]),
    KitSection('Surfaces', Icons.gradient_rounded, [
      KitSample(
        title: 'Gradients',
        subtitle:
            'Sunset, ocean, lagoon and midnight; directional, so they mirror in RTL.',
        code: '''KitoSurface(
  background: const KitoBackground.gradient(KitoGradient.ocean),
  child: ...,
);''',
        builder: (_) => const _Gradients(),
      ),
      KitSample(
        title: 'Frosted glass',
        subtitle: 'Blurs and tints whatever is behind it.',
        code: '''KitoSurface(
  background: const KitoBackground.glass(blur: 18),
  child: Text('Glass'),
);''',
        builder: (_) => const _Glass(),
      ),
      KitSample(
        title: 'Glow',
        subtitle: 'A soft coloured halo.',
        code:
            '''KitoGlow(color: Colors.pinkAccent, radius: 24, child: icon);''',
        builder: (_) => const _Glow(),
      ),
      KitSample(
        title: 'Elevation',
        subtitle: 'Flat to floating.',
        code: '''KitoSurface(elevation: 8, child: ...);''',
        builder: (_) => const _Elevation(),
      ),
    ]),
    KitSection('Motion', Icons.animation_rounded, [
      KitSample(
        title: 'Press effect',
        subtitle: 'Shrinks while pressed and springs back.',
        code:
            '''KitoPressable(child: GestureDetector(onTap: open, child: card));''',
        builder: (_) => const _Press(),
      ),
      KitSample(
        title: 'Spring curve',
        subtitle: 'Tap to compare the Kito spring with an ease-out.',
        code: '''AnimatedAlign(
  duration: context.kito.motion.slow,
  curve: context.kito.motion.spring,
  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
  child: dot,
);''',
        builder: (_) => const _Spring(),
      ),
      KitSample(
        title: 'Reduce Motion',
        subtitle: 'Durations drop to zero when the user asks for less motion.',
        code: '''AnimatedOpacity(
  duration: KitoMotion.of(context, context.kito.motion.medium),
  opacity: visible ? 1 : 0,
  child: ...,
);''',
        builder: (_) => const _ReduceMotion(),
      ),
    ]),
    KitSection('Direction', Icons.swap_horiz_rounded, [
      KitSample(
        title: 'Right to left',
        subtitle: 'Directional gradients, padding and icons mirror together.',
        code: '''if (context.isRtl) { /* flip drag maths */ }
const EdgeInsetsDirectional.only(start: 16);''',
        builder: (_) => const _Rtl(),
      ),
    ]),
  ],
);

// MARK: Samples

class _ColourRoles extends StatelessWidget {
  const _ColourRoles();

  @override
  Widget build(BuildContext context) {
    final c = context.kito.colors;
    final roles = <(String, Color, Color)>[
      ('primary', c.primary, c.onPrimary),
      ('secondary', c.secondary, c.onSecondary),
      ('background', c.background, c.onBackground),
      ('surface', c.surface, c.onSurface),
      ('muted', c.surfaceMuted, c.onSurface),
      ('danger', c.danger, Colors.white),
      ('success', c.success, Colors.white),
      ('warning', c.warning, Colors.black),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (name, fill, on) in roles)
          Container(
            width: 92,
            height: 64,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border)),
            child: Text(name,
                style: context.kito.typography.caption
                    .copyWith(color: on, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class _Presets extends StatelessWidget {
  const _Presets();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (name, theme) in [
          ('Light', KitoTheme.light),
          ('Dark', KitoTheme.dark),
          ('Neon', KitoTheme.neon)
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Theme(
                data: theme.toThemeData(),
                child: Builder(builder: (context) => _MiniScreen(title: name)),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return Container(
      height: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: t.colors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  t.typography.headline.copyWith(color: t.colors.onBackground)),
          const SizedBox(height: 8),
          Container(
              height: 34,
              decoration: BoxDecoration(
                  color: t.colors.surface,
                  borderRadius: BorderRadius.circular(10))),
          const Spacer(),
          Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: t.colors.primary,
                borderRadius: BorderRadius.circular(99)),
            child: Text('Continue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.typography.caption.copyWith(
                    color: t.colors.onPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatefulWidget {
  const _Brand();

  @override
  State<_Brand> createState() => _BrandState();
}

class _BrandState extends State<_Brand> {
  static const _choices = [
    Color(0xFF0B0B0F),
    Color(0xFF0E7C66),
    Color(0xFFE85D04),
    Color(0xFF5B5BD6),
    Color(0xFFD6336C)
  ];
  Color _primary = _choices[1];

  @override
  Widget build(BuildContext context) {
    final brand = KitoTheme.light
        .copyWith(colors: KitoColors.light.copyWith(primary: _primary));
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final c in _choices)
              Semantics(
                button: true,
                selected: c == _primary,
                label: 'Brand colour',
                child: GestureDetector(
                  onTap: () => setState(() => _primary = c),
                  child: AnimatedContainer(
                    duration: KitoMotion.of(context, context.kito.motion.fast),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: c == _primary ? 34 : 28,
                    height: c == _primary ? 34 : 28,
                    decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: c == _primary ? 3 : 0)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
            width: 200,
            child: Theme(
                data: brand.toThemeData(),
                child: const _MiniScreen(title: 'Your app'))),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    final color = t.colors.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in [
          ('Display', t.typography.display),
          ('Title', t.typography.title),
          ('Headline', t.typography.headline),
          ('Body', t.typography.body),
          ('Label', t.typography.label),
          ('Caption', t.typography.caption),
        ])
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(name, style: style.copyWith(color: color))),
      ],
    );
  }
}

class _SpacingRadii extends StatelessWidget {
  const _SpacingRadii();

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    final steps = [
      t.spacing.xs,
      t.spacing.sm,
      t.spacing.md,
      t.spacing.lg,
      t.spacing.xl,
      t.spacing.xxl
    ];
    final radii = [t.radii.sm, t.radii.md, t.radii.lg, t.radii.xl, 32.0];
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: WrapAlignment.center,
          children: [
            for (final s in steps)
              Container(width: s, height: s * 2, color: t.colors.primary),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final r in radii)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: t.colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(color: t.colors.primary, width: 1.5)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Gradients extends StatelessWidget {
  const _Gradients();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (name, g) in [
          ('Sunset', KitoGradient.sunset),
          ('Ocean', KitoGradient.ocean),
          ('Lagoon', KitoGradient.lagoon),
          ('Midnight', KitoGradient.midnight),
        ])
          SizedBox(
            width: 130,
            height: 90,
            child: KitoSurface(
              background: KitoBackground.gradient(g),
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient:
                      KitoGradient.sunset.resolve(Directionality.of(context))),
            ),
          ),
          const Positioned(
              left: 30,
              top: 30,
              child:
                  CircleAvatar(radius: 40, backgroundColor: Color(0xFF7C4DFF))),
          const Positioned(
              right: 30,
              bottom: 24,
              child:
                  CircleAvatar(radius: 34, backgroundColor: Color(0xFF00E5D4))),
          const SizedBox(
            width: 220,
            child: KitoSurface(
              background: KitoBackground.glass(),
              padding: EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('KES 248,500',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Total balance',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final c in const [
          Color(0xFF00E5D4),
          Color(0xFFFF4081),
          Color(0xFFFFC400)
        ])
          KitoGlow(
            color: c,
            radius: 26,
            intensity: 0.8,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child:
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
            ),
          ),
      ],
    );
  }
}

class _Elevation extends StatelessWidget {
  const _Elevation();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final e in const [0.0, 2.0, 6.0, 12.0])
          SizedBox(
            width: 86,
            height: 70,
            child: KitoSurface(
              elevation: e,
              border: e == 0,
              child: Center(
                  child: Text('${e.toInt()}',
                      style: context.kito.typography.headline
                          .copyWith(color: context.kito.colors.onSurface))),
            ),
          ),
      ],
    );
  }
}

class _Press extends StatefulWidget {
  const _Press();

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return KitoPressable(
      child: GestureDetector(
        onTap: () => setState(() => _taps++),
        child: DemoWidth(
          width: 240,
          child: KitoSurface(
            background: const KitoBackground.gradient(KitoGradient.lagoon),
            padding: const EdgeInsets.all(20),
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Diani Beach stay',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tapped $_taps times',
                    style:
                        t.typography.caption.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Spring extends StatefulWidget {
  const _Spring();

  @override
  State<_Spring> createState() => _SpringState();
}

class _SpringState extends State<_Spring> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    Widget track(String label, Curve curve, Color color) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: t.typography.caption.copyWith(
                    color: t.colors.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 6),
            Container(
              height: 36,
              decoration: BoxDecoration(
                  color: t.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(99)),
              child: AnimatedAlign(
                duration: KitoMotion.of(context, t.motion.slow * 2),
                curve: curve,
                alignment: _on
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                    width: 36,
                    height: 36,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
              ),
            ),
          ],
        );
    return GestureDetector(
      onTap: () => setState(() => _on = !_on),
      behavior: HitTestBehavior.opaque,
      child: DemoWidth(
        width: 280,
        child: Column(
          children: [
            track('Kito spring', t.motion.spring, t.colors.primary),
            const SizedBox(height: 14),
            track('Ease out', Curves.easeOut, t.colors.secondary),
            const SizedBox(height: 12),
            Text('Tap to play',
                style: t.typography.caption.copyWith(
                    color: t.colors.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

class _ReduceMotion extends StatefulWidget {
  const _ReduceMotion();

  @override
  State<_ReduceMotion> createState() => _ReduceMotionState();
}

class _ReduceMotionState extends State<_ReduceMotion> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    final reduced = context.reduceMotion;
    return Column(
      children: [
        AnimatedOpacity(
          duration: KitoMotion.of(context, t.motion.slow),
          opacity: _visible ? 1 : 0,
          child: Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
                color: t.colors.primary,
                borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
            onPressed: () => setState(() => _visible = !_visible),
            child: Text(_visible ? 'Fade out' : 'Fade in')),
        Text(
          reduced
              ? 'Reduce Motion is on: changes are instant.'
              : 'Turn on Reduce Motion to see it switch instantly.',
          textAlign: TextAlign.center,
          style: t.typography.caption
              .copyWith(color: t.colors.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _Rtl extends StatelessWidget {
  const _Rtl();

  @override
  Widget build(BuildContext context) {
    Widget card(TextDirection direction, String label) => Directionality(
          textDirection: direction,
          child: Builder(
            builder: (context) => SizedBox(
              width: 150,
              child: KitoSurface(
                background: const KitoBackground.gradient(KitoGradient.ocean),
                padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700))),
                    Icon(
                        context.isRtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        card(TextDirection.ltr, 'Continue'),
        card(TextDirection.rtl, 'متابعة')
      ],
    );
  }
}
