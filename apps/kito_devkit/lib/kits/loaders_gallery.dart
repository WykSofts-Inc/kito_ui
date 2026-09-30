// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_loaders/kito_ui_loaders.dart';

import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';
import '../gallery/phone_frame.dart';

/// The gallery for kito_ui_loaders.
final loadersKit = KitEntry(
  title: 'Loaders',
  package: 'kito_ui_loaders',
  blurb: 'spinners, progress, skeletons, overlays and pull to refresh',
  icon: Icons.autorenew_rounded,
  category: KitCategory.feedback,
  isNew: true,
  sections: [
    KitSection('Indicators', Icons.motion_photos_on_rounded, [
      KitSample(
        title: 'Spinner and gradient ring',
        subtitle: 'The everyday spinners, in any size and colour.',
        code: '''const KitoLoaderSpinner();
const KitoLoaderSpinner(size: 36, strokeWidth: 4, color: Color(0xFF1FA84F));
const KitoLoaderGradientRing(size: 40);''',
        builder: (_) => const _Spinners(),
      ),
      KitSample(
        title: 'Dots, pulse, bars and wave',
        subtitle: 'Low-key loaders for rows, chips and players.',
        code: '''const KitoLoaderDots();
const KitoLoaderPulse();
const KitoLoaderBars(barCount: 5);
const KitoLoaderWave();''',
        builder: (_) => const _Rhythm(),
      ),
      KitSample(
        title: 'Ripple and orbit',
        subtitle: 'Background activity: syncing, searching for a rider.',
        code: '''const KitoLoaderRipple(size: 56);
const KitoLoaderOrbit(size: 40, semanticLabel: 'Finding a rider near you');''',
        builder: (_) => const _RippleOrbit(),
      ),
      KitSample(
        title: 'Typing indicator',
        subtitle:
            'Dots hopping in a chat bubble; they fade instead under Reduce Motion.',
        code: '''Row(children: [
  const CircleAvatar(child: Text('AK')),
  const SizedBox(width: 12),
  const KitoLoaderTypingIndicator(),
]);''',
        builder: (_) => const _Typing(),
      ),
      KitSample(
        title: 'Heartbeat',
        subtitle:
            'An ECG trace with a beating heart — fitness and device pairing.',
        code:
            '''const KitoLoaderHeartbeat(showHeart: true, beatsPerMinute: 76);''',
        builder: (_) => const _Heartbeat(),
      ),
      KitSample(
        title: 'Morphing shape',
        subtitle:
            'Circle to triangle to square to star, with a turning gradient.',
        code: '''const KitoLoaderMorph(size: 56);''',
        builder: (_) => const Center(child: KitoLoaderMorph(size: 56)),
      ),
      KitSample(
        title: 'Loaders as configuration',
        subtitle: 'Pick any loader from one value.',
        code: '''KitoLoaderView(
  style: const KitoLoaderStyle(kind: KitoLoaderKind.orbit, size: 36),
);''',
        builder: (_) => const _Picker(),
      ),
    ]),
    KitSection('Progress', Icons.donut_large_rounded, [
      KitSample(
        title: 'Progress ring',
        subtitle: 'Animates to each new value and shows the percentage.',
        code:
            '''KitoLoaderProgressRing(value: upload.fraction, size: 72, strokeWidth: 7);''',
        builder: (_) => const _Ring(),
      ),
      KitSample(
        title: 'Upload bar',
        subtitle: 'Fills from the start edge with a travelling sheen.',
        code: '''KitoLoaderLinearProgress(
  value: 0.64,
  label: 'Uploading national ID',
  showPercentage: true,
);''',
        builder: (_) => const _UploadBar(),
      ),
      KitSample(
        title: 'Indeterminate bar',
        subtitle: 'Two segments chasing across the track.',
        code:
            '''const KitoLoaderLinearProgress(label: 'Syncing M-Pesa statements');''',
        builder: (_) => const DemoWidth(
            width: 300,
            child:
                KitoLoaderLinearProgress(label: 'Syncing M-Pesa statements')),
      ),
      KitSample(
        title: 'Checkout steps',
        subtitle: 'Numbered markers tick off as you go.',
        code: '''KitoLoaderStepProgress(
  steps: const ['Basket', 'Delivery', 'Payment', 'Done'],
  current: step,
);''',
        builder: (_) => const _Steps(),
      ),
      KitSample(
        title: 'Order on its way',
        subtitle: 'Segments like story progress, the current one part-filled.',
        code: '''KitoLoaderStepProgress(
  steps: const ['Placed', 'Packed', 'Rider Otieno is on the way', 'Delivered'],
  current: 2,
  stepFraction: 0.6,
  style: KitoLoaderStepStyle.segments,
);''',
        builder: (_) => const DemoWidth(
          width: 320,
          child: KitoLoaderStepProgress(
            steps: [
              'Placed',
              'Packed',
              'Rider Otieno is on the way',
              'Delivered'
            ],
            current: 2,
            stepFraction: 0.6,
            style: KitoLoaderStepStyle.segments,
          ),
        ),
      ),
    ]),
    KitSection('Skeletons', Icons.view_agenda_rounded, [
      KitSample(
        title: 'List rows',
        subtitle: 'Avatars, lines and a pill, shimmering in one sweep.',
        code:
            '''const KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.listRow, count: 4);''',
        builder: (_) => const DemoWidth(
            width: 330,
            child: KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.listRow,
                count: 4)),
      ),
      KitSample(
        title: 'Feed post and chat',
        subtitle: 'Placeholders in the shape of what is coming.',
        code:
            '''const KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.feedPost);
const KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.chat, count: 4);''',
        builder: (_) => const DemoWidth(
          width: 330,
          child: Column(children: [
            KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.feedPost),
            SizedBox(height: 24),
            KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.chat, count: 4),
          ]),
        ),
      ),
      KitSample(
        title: 'Product grid',
        subtitle: 'Two columns of tiles with captions.',
        code:
            '''const KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.grid, count: 2);''',
        builder: (_) => const DemoWidth(
            width: 330,
            child: KitoLoaderSkeletonView(KitoLoaderSkeletonTemplate.grid,
                count: 2)),
      ),
      KitSample(
        title: 'Skeleton swap',
        subtitle: 'Swaps a widget for a same-sized block, so nothing jumps.',
        code: '''KitoLoaderSkeletonSwap(
  loading: profile == null,
  radius: 22,
  child: ProfileChip(profile ?? Profile.placeholder),
);''',
        builder: (_) => const _Swap(),
      ),
      KitSample(
        title: 'Redacted card',
        subtitle: 'The real layout, redacted and shimmering while it loads.',
        code: '''KitoLoaderRedacted(
  loading: wallet == null,
  child: WalletCard(wallet ?? Wallet.sample),
);''',
        builder: (_) => const _Redacted(),
      ),
    ]),
    KitSection('Screens', Icons.smartphone_rounded, [
      KitSample(
        title: 'Loading overlay',
        subtitle:
            'Blurs, dims and blocks the screen while a payment goes through.',
        code: '''KitoLoaderOverlay(
  isPresented: paying,
  message: 'Confirming payment',
  detail: 'Check your phone for the M-Pesa prompt',
  child: checkoutScreen,
);''',
        builder: (_) => PhoneFrame(builder: (_) => const _OverlayScreen()),
      ),
      KitSample(
        title: 'Loading card',
        subtitle: 'The overlay card on its own, with a determinate ring.',
        code: '''const KitoLoaderCard(
  message: 'Uploading receipts',
  detail: '7 of 11',
  progress: 0.64,
);''',
        builder: (_) => const KitoLoaderCard(
            message: 'Uploading receipts', detail: '7 of 11', progress: 0.64),
      ),
      KitSample(
        title: 'Pull to refresh',
        subtitle:
            'A ring that draws as you pull, then spins while it refreshes.',
        code: '''KitoLoaderPullToRefresh(
  onRefresh: () => statements.reload(),
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [for (final t in transactions) TransactionRow(t)],
  ),
);''',
        builder: (_) => PhoneFrame(builder: (_) => const _RefreshScreen()),
      ),
    ]),
  ],
);

// MARK: Indicators

Widget _labelled(BuildContext context, String label, Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 64, child: Center(child: child)),
        const SizedBox(height: 6),
        Text(label, style: context.kito.typography.caption),
      ],
    );

class _Spinners extends StatelessWidget {
  const _Spinners();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 28,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _labelled(context, 'Spinner', const KitoLoaderSpinner()),
          _labelled(
              context,
              'Custom',
              const KitoLoaderSpinner(
                  size: 36, strokeWidth: 4, color: Color(0xFF1FA84F))),
          _labelled(
              context, 'Gradient ring', const KitoLoaderGradientRing(size: 40)),
          _labelled(
              context,
              'Sunset ring',
              const KitoLoaderGradientRing(
                  size: 40, colors: [Color(0x00FF3D77), Color(0xFFFF8A3D)])),
        ],
      );
}

class _Rhythm extends StatelessWidget {
  const _Rhythm();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 28,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _labelled(context, 'Dots', const KitoLoaderDots()),
          _labelled(context, 'Pulse', const KitoLoaderPulse()),
          _labelled(context, 'Bars', const KitoLoaderBars()),
          _labelled(context, 'Wave', const KitoLoaderWave()),
        ],
      );
}

class _RippleOrbit extends StatelessWidget {
  const _RippleOrbit();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        _labelled(context, 'Ripple', const KitoLoaderRipple(size: 56)),
        const SizedBox(width: 36),
        _labelled(
            context,
            'Orbit',
            const KitoLoaderOrbit(
                size: 40, semanticLabel: 'Finding a rider near you')),
      ]),
      const SizedBox(height: 12),
      Text('Finding a boda rider near Westlands…',
          style: kito.typography.label.copyWith(
              color: kito.colors.onBackground.withValues(alpha: 0.7))),
    ]);
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 18, child: Text('AK')),
          SizedBox(width: 14),
          KitoLoaderTypingIndicator(),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const KitoLoaderTypingIndicator(showBubble: false, dotSize: 6),
          const SizedBox(width: 8),
          Text('Amina is typing…', style: kito.typography.caption),
        ]),
      ],
    );
  }
}

class _Heartbeat extends StatelessWidget {
  const _Heartbeat();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KitoLoaderHeartbeat(showHeart: true, beatsPerMinute: 76),
          const SizedBox(height: 10),
          Text('Connecting to your watch',
              style: context.kito.typography.label),
        ],
      );
}

class _Picker extends StatefulWidget {
  const _Picker();

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  KitoLoaderKind _kind = KitoLoaderKind.orbit;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 80,
            child: Center(
              child: KitoLoaderView(
                  style: KitoLoaderStyle(kind: _kind, size: 36, value: 0.7)),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final k in KitoLoaderKind.values)
                ChoiceChip(
                  label: Text(k.name),
                  selected: k == _kind,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
        ],
      );
}

// MARK: Progress

class _Ring extends StatefulWidget {
  const _Ring();

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> {
  double _v = 0.42;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KitoLoaderProgressRing(value: _v, size: 72, strokeWidth: 7),
          DemoWidth(
            width: 260,
            child: Slider(value: _v, onChanged: (v) => setState(() => _v = v)),
          ),
        ],
      );
}

class _UploadBar extends StatefulWidget {
  const _UploadBar();

  @override
  State<_UploadBar> createState() => _UploadBarState();
}

class _UploadBarState extends State<_UploadBar> {
  double _v = 0.64;

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KitoLoaderLinearProgress(
                value: _v,
                label: 'Uploading national ID',
                showPercentage: true),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                  onPressed: () => setState(() => _v = 0),
                  child: const Text('Reset')),
              TextButton(
                  onPressed: () =>
                      setState(() => _v = (_v + 0.18).clamp(0.0, 1.0)),
                  child: const Text('Add 18%')),
            ]),
          ],
        ),
      );
}

class _Steps extends StatefulWidget {
  const _Steps();

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  int _step = 1;
  static const _names = ['Basket', 'Delivery', 'Payment', 'Done'];

  @override
  Widget build(BuildContext context) => DemoWidth(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KitoLoaderStepProgress(steps: _names, current: _step),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                  onPressed: _step > 0 ? () => setState(() => _step--) : null,
                  child: const Text('Back')),
              FilledButton(
                  onPressed: _step < _names.length
                      ? () => setState(() => _step++)
                      : null,
                  child: const Text('Next')),
            ]),
          ],
        ),
      );
}

// MARK: Skeletons

class _Swap extends StatefulWidget {
  const _Swap();

  @override
  State<_Swap> createState() => _SwapState();
}

class _SwapState extends State<_Swap> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      KitoLoaderSkeletonSwap(
        loading: _loading,
        radius: 22,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
          decoration: BoxDecoration(
            color: kito.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(radius: 16, child: Text('WN')),
            const SizedBox(width: 10),
            Text('Wycliff N · Nairobi', style: kito.typography.label),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Switch(value: _loading, onChanged: (v) => setState(() => _loading = v)),
    ]);
  }
}

class _Redacted extends StatefulWidget {
  const _Redacted();

  @override
  State<_Redacted> createState() => _RedactedState();
}

class _RedactedState extends State<_Redacted> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DemoWidth(
        width: 320,
        child: KitoLoaderRedacted(
          loading: _loading,
          child: KitoSurface(
            background: const KitoBackground.gradient(KitoGradient.lagoon),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('M-Pesa balance',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                const Text('KES 24,580.00',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(children: [
                  const Icon(Icons.person_rounded, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Wycliff N',
                        overflow: TextOverflow.ellipsis,
                        style: kito.typography.label
                            .copyWith(color: Colors.white)),
                  ),
                  const Text('0712 ••• 678',
                      style: TextStyle(color: Colors.white70)),
                ]),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Switch(value: _loading, onChanged: (v) => setState(() => _loading = v)),
    ]);
  }
}

// MARK: Screens

class _OverlayScreen extends StatefulWidget {
  const _OverlayScreen();

  @override
  State<_OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<_OverlayScreen> {
  bool _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (mounted) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return KitoLoaderOverlay(
      isPresented: _paying,
      message: 'Confirming payment',
      detail: 'Check your phone for the M-Pesa prompt',
      child: Scaffold(
        backgroundColor: kito.colors.background,
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: kito.colors.background,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (item, price) in [
              ('Nyama choma platter', 'KES 1,450'),
              ('Chapati × 4', 'KES 200'),
              ('Delivery to Kilimani', 'KES 150'),
            ])
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
                  trailing: Text(price)),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Total', style: kito.typography.headline),
              trailing: Text('KES 1,800', style: kito.typography.headline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _paying ? null : _pay,
              icon: const Icon(Icons.phone_android_rounded),
              label: const Text('Pay with M-Pesa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshScreen extends StatefulWidget {
  const _RefreshScreen();

  @override
  State<_RefreshScreen> createState() => _RefreshScreenState();
}

class _RefreshScreenState extends State<_RefreshScreen> {
  final _rows = <(String, String, bool)>[
    ('Naivas Supermarket', 'KES 3,240', false),
    ('Received from Amina K', 'KES 5,000', true),
    ('KPLC tokens', 'KES 1,000', false),
    ('Java House, Kimathi St', 'KES 780', false),
    ('Received from Otieno M', 'KES 2,150', true),
    ('Safaricom airtime', 'KES 100', false),
    ('Uber · Kilimani to CBD', 'KES 420', false),
  ];

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(
        () => _rows.insert(0, ('Received from Wycliff N', 'KES 1,200', true)));
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      appBar: AppBar(
        title: const Text('Statements'),
        backgroundColor: kito.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: KitoLoaderPullToRefresh(
        onRefresh: _refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _rows.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, indent: 72, color: kito.colors.border),
          itemBuilder: (context, i) {
            final (name, amount, incoming) = _rows[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    (incoming ? kito.colors.success : kito.colors.onSurface)
                        .withValues(alpha: 0.12),
                child: Icon(
                    incoming
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color:
                        incoming ? kito.colors.success : kito.colors.onSurface),
              ),
              title: Text(name),
              subtitle: const Text('Today'),
              trailing: Text(incoming ? '+$amount' : '−$amount',
                  style: kito.typography.label.copyWith(
                      color: incoming ? kito.colors.success : null,
                      fontWeight: FontWeight.w600)),
            );
          },
        ),
      ),
    );
  }
}
