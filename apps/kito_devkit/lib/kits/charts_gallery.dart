// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_charts/kito_ui_charts.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
const _quarters = ['Q1', 'Q2', 'Q3', 'Q4'];

String _ksh(double v) => 'KSh ${KitoChartFormat.compact(v)}';

/// The gallery for kito_ui_charts.
final chartsKit = KitEntry(
  title: 'Charts',
  package: 'kito_ui_charts',
  blurb: 'lines, sparklines, bars, pies, donuts and faux-3D, all painted',
  icon: Icons.show_chart_rounded,
  category: KitCategory.data,
  isNew: true,
  sections: [
    KitSection('Lines and areas', Icons.show_chart_rounded, [
      KitSample(
        title: 'Smooth area',
        subtitle: 'Wycliff N’s M-Pesa spend this week. Drag to scrub.',
        code: '''KitoLineChart(
  series: [
    KitoChartSeries.values('M-Pesa', [1200, 2450, 1800, 3100, 2750, 4200, 3600],
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']),
  ],
  style: const KitoLineChartStyle(
    area: KitoLineAreaFill.gradient(),
    points: KitoLinePointStyle.hollow,
    showsLabels: true,
  ),
  valueFormatter: (v) => 'KSh \${KitoChartFormat.compact(v)}',
)''',
        builder: (_) => KitoLineChart(
          series: [
            KitoChartSeries.values(
                'M-Pesa', const [1200, 2450, 1800, 3100, 2750, 4200, 3600],
                labels: _week),
          ],
          style: const KitoLineChartStyle(
            area: KitoLineAreaFill.gradient(),
            points: KitoLinePointStyle.hollow,
            showsLabels: true,
          ),
          valueFormatter: _ksh,
        ),
      ),
      KitSample(
        title: 'Two cities',
        subtitle: 'Several series share one callout and get a legend.',
        code: '''KitoLineChart(
  series: [
    KitoChartSeries.values('Nairobi', [24, 25, 26, 24, 23, 22, 24], labels: days),
    KitoChartSeries.values('Mombasa', [30, 31, 31, 32, 33, 32, 31], labels: days),
  ],
  style: const KitoLineChartStyle(
    points: KitoLinePointStyle.filled,
    showsLabels: true,
  ),
  valueFormatter: (v) => '\${v.round()}°',
)''',
        builder: (_) => KitoLineChart(
          series: [
            KitoChartSeries.values(
                'Nairobi', const [24, 25, 26, 24, 23, 22, 24],
                labels: _week),
            KitoChartSeries.values(
                'Mombasa', const [30, 31, 31, 32, 33, 32, 31],
                labels: _week),
          ],
          style: const KitoLineChartStyle(
            points: KitoLinePointStyle.filled,
            showsLabels: true,
          ),
          valueFormatter: (v) => '${v.round()}°',
        ),
      ),
      KitSample(
        title: 'Stepped fares',
        subtitle: 'Holds each value until it changes, like matatu fares.',
        code: '''KitoLineChart(
  series: [
    KitoChartSeries.values('CBD – Rongai', [100, 100, 150, 150, 200, 120, 100],
        labels: ['6am', '8am', '10am', '12pm', '5pm', '8pm', '10pm']),
  ],
  style: const KitoLineChartStyle(
    interpolation: KitoLineInterpolation.stepped,
    area: KitoLineAreaFill.solid(opacity: 0.12),
    showsLabels: true,
    includesZero: true,
  ),
)''',
        builder: (_) => KitoLineChart(
          series: [
            KitoChartSeries.values('CBD – Rongai', const [
              100,
              100,
              150,
              150,
              200,
              120,
              100
            ], labels: const [
              '6am',
              '8am',
              '10am',
              '12pm',
              '5pm',
              '8pm',
              '10pm'
            ]),
          ],
          style: const KitoLineChartStyle(
            interpolation: KitoLineInterpolation.stepped,
            area: KitoLineAreaFill.solid(opacity: 0.12),
            showsLabels: true,
            includesZero: true,
          ),
          valueFormatter: _ksh,
        ),
      ),
      KitSample(
        title: 'Goal line',
        subtitle: 'Catmull–Rom curve with halo points and a dashed target.',
        code: '''KitoLineChart(
  series: [KitoChartSeries.values('Steps', steps, labels: days)],
  style: const KitoLineChartStyle(
    interpolation: KitoLineInterpolation.catmullRom,
    points: KitoLinePointStyle.halo,
    showsLabels: true,
    referenceLines: [
      KitoChartReferenceLine('10k goal', 10000, color: Color(0xFF21A86B)),
    ],
  ),
)''',
        builder: (_) => KitoLineChart(
          series: [
            KitoChartSeries.values(
                'Steps', const [6400, 8200, 11800, 9100, 12500, 7300, 10400],
                labels: _week),
          ],
          style: const KitoLineChartStyle(
            interpolation: KitoLineInterpolation.catmullRom,
            points: KitoLinePointStyle.halo,
            showsLabels: true,
            referenceLines: [
              KitoChartReferenceLine('10k goal', 10000,
                  color: Color(0xFF21A86B)),
            ],
          ),
        ),
      ),
      KitSample(
        title: 'Neon glow',
        subtitle: 'A gradient stroke with a soft glow, for dark dashboards.',
        code: '''KitoLineChart(
  series: [KitoChartSeries.values('NSE 20', points)],
  style: const KitoLineChartStyle(
    lineWidth: 3,
    glows: true,
    strokeGradient: [Color(0xFF00E5D4), Color(0xFFA855F7)],
    area: KitoLineAreaFill.gradient(opacity: 0.25),
    showsValueAxis: false,
  ),
)''',
        builder: (_) => const _NeonCard(),
      ),
      KitSample(
        title: 'Live value',
        subtitle:
            'Only the latest point, with a pulse. Stops under Reduce Motion.',
        code: '''KitoLineChart(
  series: [KitoChartSeries.values('Boda rides', rides)],
  style: const KitoLineChartStyle(
    points: KitoLinePointStyle.lastPoint,
    area: KitoLineAreaFill.gradient(),
  ),
  height: 140,
)''',
        builder: (_) => KitoLineChart(
          series: [
            KitoChartSeries.values('Boda rides',
                const [12, 18, 15, 22, 28, 24, 31, 35, 30, 38, 42]),
          ],
          style: const KitoLineChartStyle(
            points: KitoLinePointStyle.lastPoint,
            area: KitoLineAreaFill.gradient(),
          ),
          height: 140,
          tint: const Color(0xFFF58C29),
        ),
      ),
      KitSample(
        title: 'Forecast',
        subtitle: 'A dashed line with values on every point.',
        code: '''KitoLineChart(
  series: [KitoChartSeries.values('Rain (mm)', rain, labels: months)],
  style: const KitoLineChartStyle(
    dash: [6, 4],
    points: KitoLinePointStyle.filled,
    showsValues: true,
    showsLabels: true,
    showsValueAxis: false,
  ),
)''',
        builder: (_) => KitoLineChart(
          series: [
            KitoChartSeries.values(
                'Rain (mm)', const [62, 55, 110, 210, 160, 45],
                labels: _months),
          ],
          style: const KitoLineChartStyle(
            dash: [6, 4],
            points: KitoLinePointStyle.filled,
            showsValues: true,
            showsLabels: true,
            showsValueAxis: false,
          ),
          tint: const Color(0xFF21A8C7),
        ),
      ),
      KitSample(
        title: 'Scrub readout',
        subtitle: 'onSelectionChanged drives your own UI above the chart.',
        code: '''KitoLineChart(
  series: [sales],
  onSelectionChanged: (i) => setState(() => picked = i),
)''',
        builder: (_) => const _ScrubReadout(),
      ),
    ]),
    KitSection('Sparklines', Icons.trending_up_rounded, [
      KitSample(
        title: 'Watchlist',
        subtitle: 'Green when up, red when down, sized to fit a row.',
        code: '''ListTile(
  title: const Text('SCOM'),
  trailing: SizedBox(
    width: 88,
    child: KitoSparkline(prices, trendColors: true),
  ),
)''',
        builder: (_) => const _Watchlist(),
      ),
      KitSample(
        title: 'Stat tile',
        subtitle: 'A figure with its recent trend.',
        code: '''KitoSurface(
  padding: const EdgeInsets.all(16),
  child: Column(children: [
    const Text('Chama savings'),
    const Text('KSh 48,200'),
    KitoSparkline(balances, height: 44, color: Color(0xFF8C5CF0)),
  ]),
)''',
        builder: (_) => const _StatTile(),
      ),
    ]),
    KitSection('Bars', Icons.bar_chart_rounded, [
      KitSample(
        title: 'Monthly sales',
        subtitle: 'Bars spring in one after another. Tap one to highlight it.',
        code: '''KitoBarChart(
  series: [
    KitoChartSeries.values('Sales', [42, 58, 35, 71, 64, 80], labels: months),
  ],
  showsValues: true,
  valueFormatter: (v) => '\${v.round()}k',
)''',
        builder: (_) => KitoBarChart(
          series: [
            KitoChartSeries.values('Sales', const [42, 58, 35, 71, 64, 80],
                labels: _months),
          ],
          showsValues: true,
          valueFormatter: (v) => '${v.round()}k',
        ),
      ),
      KitSample(
        title: 'Grouped',
        subtitle: 'Tea and coffee exports per quarter, side by side.',
        code: '''KitoBarChart(series: [
  KitoChartSeries.values('Tea', [42, 58, 35, 71], labels: quarters),
  KitoChartSeries.values('Coffee', [20, 30, 25, 40], labels: quarters),
])''',
        builder: (_) => KitoBarChart(series: [
          KitoChartSeries.values('Tea', const [42, 58, 35, 71],
              labels: _quarters),
          KitoChartSeries.values('Coffee', const [20, 30, 25, 40],
              labels: _quarters),
        ]),
      ),
      KitSample(
        title: 'Stacked',
        subtitle: 'Mobile money volume by provider; tap for the total.',
        code: '''KitoBarChart(
  layout: KitoBarLayout.stacked,
  series: [
    KitoChartSeries.values('M-Pesa', [320, 340, 360, 390], labels: quarters),
    KitoChartSeries.values('Airtel Money', [60, 72, 80, 85], labels: quarters),
    KitoChartSeries.values('T-Kash', [12, 14, 13, 16], labels: quarters),
  ],
  referenceLines: const [KitoChartReferenceLine('Target', 450)],
)''',
        builder: (_) => KitoBarChart(
          layout: KitoBarLayout.stacked,
          series: [
            KitoChartSeries.values('M-Pesa', const [320, 340, 360, 390],
                labels: _quarters),
            KitoChartSeries.values('Airtel Money', const [60, 72, 80, 85],
                labels: _quarters),
            KitoChartSeries.values('T-Kash', const [12, 14, 13, 16],
                labels: _quarters),
          ],
          referenceLines: const [KitoChartReferenceLine('Target', 450)],
        ),
      ),
      KitSample(
        title: 'Horizontal',
        subtitle: 'Long labels read better as rows; grows from the start edge.',
        code: '''KitoBarChart(
  direction: Axis.horizontal,
  showsValues: true,
  series: [
    KitoChartSeries.values('Riders', [420, 260, 180, 150, 90],
        labels: ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret']),
  ],
)''',
        builder: (_) => KitoBarChart(
          direction: Axis.horizontal,
          showsValues: true,
          tint: const Color(0xFF21A86B),
          series: [
            KitoChartSeries.values('Riders', const [
              420,
              260,
              180,
              150,
              90
            ], labels: const [
              'Nairobi',
              'Mombasa',
              'Kisumu',
              'Nakuru',
              'Eldoret'
            ]),
          ],
        ),
      ),
      KitSample(
        title: 'Profit and loss',
        subtitle:
            'Negative values hang below zero; call one out with its own colour.',
        code: '''KitoBarChart(
  showsValues: true,
  series: [
    KitoChartSeries(name: 'Net', points: [
      KitoChartPoint('Jan', 12),
      KitoChartPoint('Feb', -6, color: Color(0xFFE5484D)),
      KitoChartPoint('Mar', 18),
    ]),
  ],
)''',
        builder: (_) => const KitoBarChart(
          showsValues: true,
          series: [
            KitoChartSeries(name: 'Net', points: [
              KitoChartPoint('Jan', 12),
              KitoChartPoint('Feb', -6, color: Color(0xFFE5484D)),
              KitoChartPoint('Mar', 18),
              KitoChartPoint('Apr', 9),
              KitoChartPoint('May', -3, color: Color(0xFFE5484D)),
              KitoChartPoint('Jun', 22),
            ]),
          ],
        ),
      ),
      KitSample(
        title: 'Live data',
        subtitle: 'New values with the same shape morph instead of redrawing.',
        code: '''KitoBarChart(series: [
  KitoChartSeries.values('Orders', orders, labels: days),
])
// setState(() => orders = fresh); // bars glide to the new heights''',
        builder: (_) => const _LiveBars(),
      ),
    ]),
    KitSection('Pies and donuts', Icons.pie_chart_rounded, [
      KitSample(
        title: 'Donut with total',
        subtitle: 'Tap a slice or legend entry; the hole shows its share.',
        code: '''KitoPieChart(
  points: const [
    KitoChartPoint('Rent', 45000),
    KitoChartPoint('Food', 18000),
    KitoChartPoint('Matatu', 6500),
    KitoChartPoint('Airtime', 2500),
  ],
  holeFraction: 0.62,
  gapDegrees: 2,
  center: const Text('KSh 72k'),
  valueFormatter: (v) => 'KSh \${KitoChartFormat.compact(v)}',
)''',
        builder: (_) => const KitoPieChart(
          points: [
            KitoChartPoint('Rent', 45000),
            KitoChartPoint('Food', 18000),
            KitoChartPoint('Matatu', 6500),
            KitoChartPoint('Airtime', 2500),
          ],
          holeFraction: 0.62,
          gapDegrees: 2,
          center: Text('KSh 72k'),
          valueFormatter: _ksh,
        ),
      ),
      KitSample(
        title: 'Pie',
        subtitle: 'Each slice, its swatch and the selection share one colour.',
        code: '''KitoPieChart(points: const [
  KitoChartPoint('Maize', 38, color: Color(0xFFF5A524)),
  KitoChartPoint('Beans', 24, color: Color(0xFF8C5CF0)),
  KitoChartPoint('Sukuma', 22, color: Color(0xFF21A86B)),
  KitoChartPoint('Other', 16, color: Color(0xFF9CA3AF)),
])''',
        builder: (_) => const KitoPieChart(points: [
          KitoChartPoint('Maize', 38, color: Color(0xFFF5A524)),
          KitoChartPoint('Beans', 24, color: Color(0xFF8C5CF0)),
          KitoChartPoint('Sukuma', 22, color: Color(0xFF21A86B)),
          KitoChartPoint('Other', 16, color: Color(0xFF9CA3AF)),
        ]),
      ),
      KitSample(
        title: 'Preselected slice',
        subtitle:
            'Start with a slice pulled out, e.g. the category you came from.',
        code: '''KitoPieChart(
  points: shares,
  holeFraction: 0.5,
  selectedIndex: 1,
  onSelectionChanged: (i) => debugPrint('picked \$i'),
)''',
        builder: (_) => const KitoPieChart(
          points: [
            KitoChartPoint('Nairobi', 44),
            KitoChartPoint('Kampala', 28),
            KitoChartPoint('Kigali', 16),
            KitoChartPoint('Dar', 12),
          ],
          holeFraction: 0.5,
          selectedIndex: 1,
          size: 200,
        ),
      ),
    ]),
    KitSection('Faux 3D', Icons.view_in_ar_rounded, [
      KitSample(
        title: '3D bars',
        subtitle: 'Lit blocks you can turn with a sideways drag.',
        code: '''const KitoBar3DChart(points: [
  KitoChartPoint('Nairobi', 4.4),
  KitoChartPoint('Kiambu', 2.4),
  KitoChartPoint('Nakuru', 2.2),
  KitoChartPoint('Kakamega', 1.9),
])''',
        builder: (_) => const KitoBar3DChart(
          points: [
            KitoChartPoint('Nairobi', 4.4),
            KitoChartPoint('Kiambu', 2.4),
            KitoChartPoint('Nakuru', 2.2),
            KitoChartPoint('Kakamega', 1.9),
          ],
          valueFormatter: _millions,
        ),
      ),
      KitSample(
        title: '3D donut',
        subtitle:
            'A tilted disc with walls. Flick to spin, tap to lift a slice.',
        code: '''const KitoPie3DChart(
  points: [
    KitoChartPoint('Safaricom', 64),
    KitoChartPoint('Airtel', 31),
    KitoChartPoint('Telkom', 5),
  ],
  holeFraction: 0.45,
)''',
        builder: (_) => const KitoPie3DChart(
          points: [
            KitoChartPoint('Safaricom', 64, color: Color(0xFF21A86B)),
            KitoChartPoint('Airtel', 31, color: Color(0xFFE5484D)),
            KitoChartPoint('Telkom', 5, color: Color(0xFF1C6BF0)),
          ],
          holeFraction: 0.45,
        ),
      ),
    ]),
    KitSection('Theming', Icons.palette_rounded, [
      KitSample(
        title: 'Chart theme scope',
        subtitle: 'Retint every chart below with one palette; gridlines off.',
        code: '''KitoChartThemeScope(
  theme: const KitoChartTheme(
    palette: [Color(0xFF0E7C66), Color(0xFFF5A524)],
    showGridlines: false,
  ),
  child: KitoBarChart(series: [tea, coffee]),
)''',
        builder: (_) => KitoChartThemeScope(
          theme: const KitoChartTheme(
            palette: [Color(0xFF0E7C66), Color(0xFFF5A524)],
            showGridlines: false,
          ),
          child: KitoBarChart(series: [
            KitoChartSeries.values('Tea', const [42, 58, 35, 71],
                labels: _quarters),
            KitoChartSeries.values('Coffee', const [20, 30, 25, 40],
                labels: _quarters),
          ]),
        ),
      ),
    ]),
  ],
);

String _millions(double v) => '${v.toStringAsFixed(1)}M';

class _NeonCard extends StatelessWidget {
  const _NeonCard();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: KitoTheme.neon.toThemeData(),
      child: KitoSurface(
        background: const KitoBackground.color(Color(0xFF070B14)),
        padding: const EdgeInsets.all(16),
        child: KitoLineChart(
          series: [
            KitoChartSeries.values('NSE 20', const [
              1720,
              1745,
              1738,
              1790,
              1810,
              1795,
              1842,
              1868,
              1851,
              1890
            ]),
          ],
          style: const KitoLineChartStyle(
            lineWidth: 3,
            glows: true,
            strokeGradient: [Color(0xFF00E5D4), Color(0xFFA855F7)],
            area: KitoLineAreaFill.gradient(opacity: 0.25),
            showsValueAxis: false,
          ),
          height: 150,
          tint: const Color(0xFF00E5D4),
        ),
      ),
    );
  }
}

class _ScrubReadout extends StatefulWidget {
  const _ScrubReadout();

  @override
  State<_ScrubReadout> createState() => _ScrubReadoutState();
}

class _ScrubReadoutState extends State<_ScrubReadout> {
  static const _values = <double>[3200, 2800, 4100, 3900, 5200, 6100, 4800];
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final i = _picked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(i == null ? 'This week' : _week[i],
            style: theme.typography.caption.copyWith(
                color: theme.colors.onSurface.withValues(alpha: 0.6))),
        AnimatedSwitcher(
          duration: KitoMotion.of(context, theme.motion.fast),
          child: Text(
            i == null
                ? 'KSh 30.1k'
                : 'KSh ${_values[i].toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
            key: ValueKey(i),
            style: theme.typography.title,
          ),
        ),
        const SizedBox(height: 8),
        KitoLineChart(
          series: [
            KitoChartSeries.values('Sales', _values, labels: _week),
          ],
          style: const KitoLineChartStyle(
            area: KitoLineAreaFill.gradient(),
            showsLabels: true,
            showsValueAxis: false,
          ),
          height: 150,
          tint: const Color(0xFF8C5CF0),
          valueFormatter: _ksh,
          onSelectionChanged: (i) => setState(() => _picked = i),
        ),
      ],
    );
  }
}

class _Watchlist extends StatelessWidget {
  const _Watchlist();

  static const List<(String, String, String, List<double>)> _rows = [
    ('SCOM', 'Safaricom', 'KSh 29.20', [27.1, 27.9, 27.4, 28.6, 28.3, 29.2]),
    (
      'EQTY',
      'Equity Group',
      'KSh 44.05',
      [46.2, 45.8, 45.1, 45.4, 44.6, 44.05]
    ),
    ('KCB', 'KCB Group', 'KSh 38.60', [35.2, 36.0, 36.8, 36.1, 37.9, 38.6]),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      children: [
        for (final (ticker, name, price, values) in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticker, style: theme.typography.headline),
                    Text(name,
                        style: theme.typography.caption.copyWith(
                            color:
                                theme.colors.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              SizedBox(
                  width: 88,
                  child: KitoSparkline(values,
                      trendColors: true,
                      style: KitoLineChartStyle.sparkline
                          .copyWith(points: KitoLinePointStyle.none))),
              const SizedBox(width: 12),
              Text(price, style: theme.typography.label),
            ]),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return KitoSurface(
      border: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chama savings',
              style: theme.typography.caption.copyWith(
                  color: theme.colors.onSurface.withValues(alpha: 0.6))),
          Text('KSh 48,200', style: theme.typography.title),
          Text('+12% this quarter',
              style: theme.typography.caption
                  .copyWith(color: theme.colors.success)),
          const SizedBox(height: 8),
          const KitoSparkline(
            [31000, 33500, 36000, 35200, 39800, 43000, 48200],
            height: 44,
            color: Color(0xFF8C5CF0),
          ),
        ],
      ),
    );
  }
}

class _LiveBars extends StatefulWidget {
  const _LiveBars();

  @override
  State<_LiveBars> createState() => _LiveBarsState();
}

class _LiveBarsState extends State<_LiveBars> {
  static const List<List<double>> _sets = [
    [18.0, 24, 31, 22, 40, 52, 36],
    [26.0, 19, 28, 35, 33, 44, 48],
    [14.0, 30, 22, 27, 45, 38, 55],
  ];
  int _set = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KitoBarChart(
          series: [
            KitoChartSeries.values('Orders', _sets[_set], labels: _week),
          ],
          tint: const Color(0xFFF58C29),
          height: 200,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _set = (_set + 1) % _sets.length),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Next week'),
        ),
      ],
    );
  }
}
