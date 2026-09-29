# kito_ui_charts

Charts for Flutter, drawn with `CustomPainter` and no chart dependency: line and area charts in
many styles, sparklines, grouped, stacked and horizontal bars, pies and donuts, and faux-3D bars
and pies. Scrub a line to read values, tap a bar or slice to highlight it, and watch everything
animate in. Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui); every chart follows
`KitoTheme` (light, dark, neon), right-to-left layouts, text scaling and Reduce Motion.

## Install

```yaml
dependencies:
  kito_ui_charts: ^0.1.0
```

```dart
import 'package:kito_ui_charts/kito_ui_charts.dart';
```

## Quick start

```dart
KitoLineChart(
  series: [
    KitoChartSeries.values('M-Pesa', [120, 200, 150, 260, 240],
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']),
  ],
)
```

Data is a list of `KitoChartSeries` (a name, a colour and `KitoChartPoint`s). Series on one
chart are matched by position: the third point of every series shares the third label.

## Line and area charts

```dart
KitoLineChart(
  series: [
    KitoChartSeries.values('Nairobi', [22, 24, 25, 23, 21], labels: days),
    KitoChartSeries.values('Mombasa', [30, 31, 29, 32, 33], labels: days),
  ],
  style: const KitoLineChartStyle(
    interpolation: KitoLineInterpolation.catmullRom, // linear, smooth, stepped
    points: KitoLinePointStyle.hollow,               // filled, halo, lastPoint (pulsing)
    area: KitoLineAreaFill.gradient(opacity: 0.35),  // or KitoLineAreaFill.solid()
    showsLabels: true,                               // x labels, thinned when crowded
    referenceLines: [KitoChartReferenceLine('Hot', 30, color: Colors.red)],
  ),
  valueFormatter: (v) => '${v.round()}°',
  onSelectionChanged: (index) => debugPrint('scrubbed to $index'),
)
```

Also on the style: `lineWidth`, `dash`, `pointSize`, `strokeGradient`, `glows`,
`showsValueAxis`, `showsValues`, `includesZero` and `animatesIn`. Presets:
`KitoLineChartStyle.sparkline` and `KitoLineChartStyle.areaChart`.

**Scrubbing.** Drag across the chart and a guide follows your finger with a callout listing
every series' value at that point; lift to dismiss, or tap to pin it. Each new point gives a
selection click. Screen readers hear a summary and can swipe up and down to step through the
points.

**Data changes** morph: give the chart new values with the same shape and the lines glide to
them.

## Sparklines

```dart
ListTile(
  title: const Text('SCOM'),
  trailing: SizedBox(
    width: 80,
    child: KitoSparkline(const [27.1, 27.9, 27.4, 28.6, 29.2], trendColors: true),
  ),
)
```

`trendColors` makes it green when it ends at or above where it started and red when it ends
below.

## Bar charts

```dart
KitoBarChart(
  series: [
    KitoChartSeries.values('Tea', [42, 58, 35, 71], labels: ['Q1', 'Q2', 'Q3', 'Q4']),
    KitoChartSeries.values('Coffee', [20, 30, 25, 40], labels: ['Q1', 'Q2', 'Q3', 'Q4']),
  ],
  layout: KitoBarLayout.stacked,   // or grouped (the default)
  direction: Axis.horizontal,      // bars along the reading direction
  showsValues: true,
  referenceLines: const [KitoChartReferenceLine('Target', 90)],
)
```

Bars grow in one after another with a spring. Tap a category to highlight it; the others dim
and its values (or, when stacked, its total) appear. Each category is a button for screen
readers ("Q2, Tea 58, Coffee 30"). Give a single point its own `color` to call it out.

## Pies and donuts

```dart
KitoPieChart(
  points: const [
    KitoChartPoint('Rent', 45000),
    KitoChartPoint('Food', 18000),
    KitoChartPoint('Matatu', 6500, color: Color(0xFF7C4DFF)),
  ],
  holeFraction: 0.62,          // 0 is a pie
  gapDegrees: 2,
  center: const Text('KSh 69.5k'),
  valueFormatter: (v) => 'KSh ${KitoChartFormat.compact(v)}',
)
```

Slices sweep in from the top. Tap a slice or its legend entry to pull it out: the hole shows
its label, share and value instead of `center`. The slice, its legend swatch and the
selection all use the same colour: the point's own, or the palette by position.

## Faux-3D

```dart
KitoBar3DChart(points: const [
  KitoChartPoint('Nairobi', 420),
  KitoChartPoint('Mombasa', 260),
  KitoChartPoint('Kisumu', 180),
]);

KitoPie3DChart(
  points: const [
    KitoChartPoint('Safaricom', 64),
    KitoChartPoint('Airtel', 31),
    KitoChartPoint('Telkom', 5),
  ],
  holeFraction: 0.45,
  tilt: 0.5,
  depth: 22,
);
```

Lit blocks and a tilted disc with walls, all painted, so they're cheap enough for a card.
Drag the bars sideways to turn them; drag or flick the pie to spin it. Tap to select.

## Theming

Every chart reads `KitoChartTheme.of(context)`. Anything you leave out follows `KitoTheme`;
the neon theme gets `KitoChartTheme.neonPalette` automatically.

```dart
// For the whole app…
MaterialApp(
  theme: KitoTheme.light.toThemeData().copyWith(extensions: [
    KitoTheme.light,
    const KitoChartTheme(palette: [Colors.teal, Colors.amber, Colors.pink]),
  ]),
);

// …or one subtree.
KitoChartThemeScope(
  theme: const KitoChartTheme(showGridlines: false, animationDuration: Duration(milliseconds: 400)),
  child: Dashboard(),
);
```

`KitoChartLegend`, `KitoChartScale`, `KitoChartTicks` (1-2-5 axis steps), `KitoChartFormat`
and `KitoChartMath` (paths, label thinning, slice hit-testing) are public too, for building
your own chart on the same engine.

## Right-to-left

Line and bar charts mirror: the first point and the value axis sit on the right and time runs
right to left, while scrubbing still follows the finger. Horizontal bars grow from the right.
Pies run counter-clockwise, 3D blocks show their side toward the left, and labels, legends and
callouts lay out right to left. Pass a locale-aware `valueFormatter` for local digits and
currencies.

## Accessibility

Each chart has a spoken summary (override it with `semanticLabel`). Line charts are
adjustable, bar categories and legend entries are buttons with a selected state, and every tap
target is at least 44 points. Reduce Motion skips reveals, morphs and the live-point pulse.

## License

MIT — see [LICENSE](LICENSE).
