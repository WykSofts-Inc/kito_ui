# kito_ui_core

The foundation every Kito UI kit builds on: theme tokens (colours, spacing, radii, typography,
motion), light, dark and neon presets, gradients, backgrounds, frosted glass, glow and the Kito
press effect. You rarely add it yourself — every kit depends on it.

## Theme your app

```dart
MaterialApp(
  theme: KitoTheme.light.toThemeData(),
  darkTheme: KitoTheme.dark.toThemeData(),
);
```

Customise any token:

```dart
final brand = KitoTheme.light.copyWith(
  colors: KitoColors.light.copyWith(primary: const Color(0xFF0E7C66)),
);
```

Read it anywhere with `context.kito` (or `KitoTheme.of(context)`).

## Surfaces

```dart
KitoSurface(
  background: const KitoBackground.gradient(KitoGradient.ocean),
  radius: 24,
  padding: const EdgeInsets.all(20),
  child: Text('Weekend picks'),
);

KitoSurface(background: const KitoBackground.glass(), child: ...);
KitoGlow(child: icon);
KitoPressable(child: card);   // shrinks while pressed, springs back
```

Motion helpers respect Reduce Motion: `KitoMotion.of(context, duration)` returns zero when the
user asked for less motion, and `context.isRtl` tells you when to mirror drag maths.

## License

MIT — see [LICENSE](LICENSE).
