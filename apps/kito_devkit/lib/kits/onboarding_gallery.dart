// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_onboarding/kito_ui_onboarding.dart';

import '../catalog/catalog.dart';
import '../gallery/phone_frame.dart';

/// The gallery for kito_ui_onboarding.
final onboardingKit = KitEntry(
  title: 'Onboarding',
  package: 'kito_ui_onboarding',
  blurb: 'paged onboarding with layouts, transitions and permission steps',
  icon: Icons.auto_awesome_rounded,
  category: KitCategory.navigation,
  isNew: true,
  sections: [
    KitSection('Flows', Icons.swipe_rounded, [
      KitSample(
        title: 'Quick start',
        subtitle: 'Three icon pages, capsule indicator, skip and get started.',
        code: '''KitoOnboarding(
  pages: const [
    KitoOnboardingPage(
      artwork: KitoOnboardingArtwork.icon(Icons.send_to_mobile_rounded),
      title: 'Send money in seconds',
      message: 'Pay anyone with M-Pesa, Airtel Money or a bank account.',
    ),
    KitoOnboardingPage(
      artwork: KitoOnboardingArtwork.icon(Icons.groups_rounded),
      title: 'Save with your chama',
      message: 'Track contributions and payouts together.',
    ),
    KitoOnboardingPage(
      artwork: KitoOnboardingArtwork.icon(Icons.shield_rounded),
      title: 'Safe by design',
      message: 'Your PIN never leaves your phone.',
    ),
  ],
  onFinish: () => prefs.setBool('seenOnboarding', true),
);''',
        builder: (_) => _frame(_walletPages),
      ),
      KitSample(
        title: 'Gradient pages',
        subtitle:
            'Each page brings its own gradient; controls blend as you swipe.',
        code: '''KitoOnboardingPage(
  artwork: const KitoOnboardingArtwork.icon(Icons.beach_access_rounded),
  eyebrow: 'Coast',
  title: 'Diani to Lamu',
  message: 'White sand, dhows at sunset and fresh madafu.',
  background: const KitoBackground.gradient(KitoGradient.sunset),
  foreground: Colors.white,
  accent: Colors.white,
  onAccent: Colors.black,
);''',
        builder: (_) => _frame(_safariPages,
            style: const KitoOnboardingStyle(
                artworkMotion: KitoOnboardingArtworkMotion.float)),
      ),
      KitSample(
        title: 'Solid colours and bullets',
        subtitle: 'Brand colours, an eyebrow and a short checklist per page.',
        code: '''KitoOnboardingPage(
  eyebrow: 'For shops',
  title: 'Run your duka',
  message: 'Everything you need behind the counter.',
  bullets: ['Accept M-Pesa and cards', 'Track stock', 'Send receipts by SMS'],
  background: const KitoBackground.color(Color(0xFF0E7C66)),
  foreground: Colors.white,
  accent: Colors.white,
  onAccent: Color(0xFF0E7C66),
);''',
        builder: (_) => _frame(_dukaPages),
      ),
      KitSample(
        title: 'Custom artwork',
        subtitle:
            'Draw anything as the page art — here, a little phone with a payment.',
        code: '''KitoOnboardingPage(
  artwork: KitoOnboardingArtwork.custom((context) => const PaymentIllustration()),
  title: 'Tap, confirm, done',
  message: 'Payments take one tap and your PIN.',
);''',
        builder: (_) => _frame(_customPages,
            style: const KitoOnboardingStyle(
                artworkMotion: KitoOnboardingArtworkMotion.bounce)),
      ),
      KitSample(
        title: 'Permission steps',
        subtitle:
            'Ask for location and notifications; “Not now” moves on without asking.',
        code: '''KitoOnboardingPage(
  artwork: const KitoOnboardingArtwork.icon(Icons.notifications_active_rounded),
  title: 'Know when your rider arrives',
  message: 'We only notify you about your orders.',
  permission: KitoOnboardingPermission(
    allowTitle: 'Allow notifications',
    onRequest: () => notifications.requestPermission(),   // Future<bool>
  ),
);''',
        builder: (_) => _frame(_permissionPages),
      ),
      KitSample(
        title: 'Swahili labels',
        subtitle:
            'Every button and the indicator label are yours to translate.',
        code: '''KitoOnboardingStyle(
  showsBackButton: true,
  labels: KitoOnboardingLabels(
    next: 'Endelea',
    getStarted: 'Anza sasa',
    skip: 'Ruka',
    back: 'Rudi',
    pageOf: (page, count) => 'Ukurasa \$page kati ya \$count',
  ),
);''',
        builder: (_) => _frame(_swahiliPages,
            style: KitoOnboardingStyle(
              showsBackButton: true,
              labels: KitoOnboardingLabels(
                next: 'Endelea',
                getStarted: 'Anza sasa',
                skip: 'Ruka',
                back: 'Rudi',
                pageOf: (page, count) => 'Ukurasa $page kati ya $count',
              ),
            )),
      ),
      KitSample(
        title: 'Driven from code',
        subtitle:
            'A controller moves pages; callbacks report skip, finish and page changes.',
        code: '''final onboarding = KitoOnboardingController();

KitoOnboarding(
  pages: pages,
  controller: onboarding,
  onPageChanged: (page) => analytics.log('onboarding_page_\$page'),
  onSkip: () => analytics.log('onboarding_skipped'),
  onFinish: finish,
);

onboarding.next();    // back(), goTo(2), skip()''',
        builder: (_) => PhoneFrame(builder: (_) => const _Driven()),
      ),
    ]),
    KitSection('Layouts', Icons.view_quilt_rounded, [
      KitSample(
        title: 'Split with a cube turn',
        subtitle:
            'Artwork on a colour block over the text; pages turn like a cube.',
        code: '''KitoOnboardingStyle(
  layout: KitoOnboardingLayout.split,
  pageTransition: KitoOnboardingPageTransition.cube,
  indicator: KitoOnboardingIndicator.progressBar,
);''',
        builder: (_) => _frame(_walletPages,
            style: const KitoOnboardingStyle(
              layout: KitoOnboardingLayout.split,
              pageTransition: KitoOnboardingPageTransition.cube,
              indicator: KitoOnboardingIndicator.progressBar,
            )),
      ),
      KitSample(
        title: 'Card with parallax',
        subtitle:
            'The content sits on a card; the art drifts slower than the text.',
        code: '''KitoOnboardingStyle(
  layout: KitoOnboardingLayout.card,
  pageTransition: KitoOnboardingPageTransition.parallax,
  indicator: KitoOnboardingIndicator.dots,
);''',
        builder: (_) => _frame(_safariPages,
            style: const KitoOnboardingStyle(
              layout: KitoOnboardingLayout.card,
              pageTransition: KitoOnboardingPageTransition.parallax,
              indicator: KitoOnboardingIndicator.dots,
            )),
      ),
      KitSample(
        title: 'Hero top with zoom',
        subtitle: 'Big artwork up top; pages zoom through.',
        code: '''KitoOnboardingStyle(
  layout: KitoOnboardingLayout.heroTop,
  pageTransition: KitoOnboardingPageTransition.zoom,
  artworkMotion: KitoOnboardingArtworkMotion.pulse,
);''',
        builder: (_) => _frame(_dukaPages,
            style: const KitoOnboardingStyle(
              layout: KitoOnboardingLayout.heroTop,
              pageTransition: KitoOnboardingPageTransition.zoom,
              artworkMotion: KitoOnboardingArtworkMotion.pulse,
            )),
      ),
      KitSample(
        title: 'Text first, fading',
        subtitle: 'Headline before the art, with a gentle crossfade.',
        code: '''KitoOnboardingStyle(
  layout: KitoOnboardingLayout.textFirst,
  pageTransition: KitoOnboardingPageTransition.fade,
);''',
        builder: (_) => _frame(_customPages,
            style: const KitoOnboardingStyle(
              layout: KitoOnboardingLayout.textFirst,
              pageTransition: KitoOnboardingPageTransition.fade,
            )),
      ),
      KitSample(
        title: 'Full bleed',
        subtitle: 'Edge-to-edge backgrounds with the text at the bottom.',
        code: '''KitoOnboardingStyle(
  layout: KitoOnboardingLayout.fullBleed,
  pageTransition: KitoOnboardingPageTransition.scaleFade,
);''',
        builder: (_) => _frame(_bleedPages,
            style: const KitoOnboardingStyle(
              layout: KitoOnboardingLayout.fullBleed,
              pageTransition: KitoOnboardingPageTransition.scaleFade,
            )),
      ),
    ]),
    KitSection('Controls', Icons.smart_button_rounded, [
      KitSample(
        title: 'Progress ring button',
        subtitle:
            'A ring that fills as you go, then stretches into “Get started”.',
        code: '''KitoOnboardingStyle(
  buttonPlacement: KitoOnboardingButtonPlacement.progressRing,
);''',
        builder: (_) => _frame(_walletPages,
            style: const KitoOnboardingStyle(
                buttonPlacement: KitoOnboardingButtonPlacement.progressRing)),
      ),
      KitSample(
        title: 'Compact buttons, numbered',
        subtitle:
            'A small Next at the top or bottom, with a numbered indicator.',
        code: '''KitoOnboardingStyle(
  buttonPlacement: KitoOnboardingButtonPlacement.bottomTrailingCompact,
  indicator: KitoOnboardingIndicator.numbered,
  showsBackButton: true,
);''',
        builder: (_) => _frame(_safariPages,
            style: const KitoOnboardingStyle(
              buttonPlacement:
                  KitoOnboardingButtonPlacement.bottomTrailingCompact,
              indicator: KitoOnboardingIndicator.numbered,
              showsBackButton: true,
            )),
      ),
      KitSample(
        title: 'Indicators',
        subtitle: 'Capsules, dots, numbered and a progress bar.',
        code: '''KitoOnboardingIndicatorView(
  style: KitoOnboardingIndicator.capsules,
  count: 4,
  current: page,
  accent: accent,
  foreground: foreground,
);''',
        builder: (_) => const _Indicators(),
      ),
      KitSample(
        title: 'A single page',
        subtitle:
            'KitoOnboardingPageView draws one page anywhere — a what’s-new card.',
        code: '''SizedBox(
  height: 440,
  child: KitoOnboardingPageView(
    page: const KitoOnboardingPage(
      artwork: KitoOnboardingArtwork.icon(Icons.new_releases_rounded),
      eyebrow: "What's new",
      title: 'Split the bill',
      message: 'Share a till payment with friends in two taps.',
    ),
  ),
);''',
        builder: (_) => const SizedBox(
          width: 340,
          height: 440,
          child: KitoOnboardingPageView(
            page: KitoOnboardingPage(
              artwork: KitoOnboardingArtwork.icon(Icons.new_releases_rounded),
              eyebrow: 'What’s new',
              title: 'Split the bill',
              message: 'Share a till payment with friends in two taps.',
            ),
          ),
        ),
      ),
    ]),
  ],
);

// MARK: Frames and demos

Widget _frame(List<KitoOnboardingPage> pages,
        {KitoOnboardingStyle style = const KitoOnboardingStyle()}) =>
    PhoneFrame(builder: (_) => _Demo(pages: pages, style: style));

/// Runs a flow, then shows a welcome screen with Replay.
class _Demo extends StatefulWidget {
  const _Demo({required this.pages, required this.style});

  final List<KitoOnboardingPage> pages;
  final KitoOnboardingStyle style;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  bool _done = false;
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    if (_done) {
      return Scaffold(
        backgroundColor: kito.colors.background,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_rounded,
                size: 64, color: kito.colors.success),
            const SizedBox(height: 12),
            Text('Karibu, Wycliff!', style: kito.typography.title),
            const SizedBox(height: 4),
            Text('You’re all set.', style: kito.typography.body),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() {
                _done = false;
                _run++;
              }),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Replay'),
            ),
          ]),
        ),
      );
    }
    return Scaffold(
      backgroundColor: kito.colors.background,
      body: KitoOnboarding(
        key: ValueKey(_run),
        pages: widget.pages,
        style: widget.style,
        onFinish: () => setState(() => _done = true),
      ),
    );
  }
}

class _Driven extends StatefulWidget {
  const _Driven();

  @override
  State<_Driven> createState() => _DrivenState();
}

class _DrivenState extends State<_Driven> {
  final _controller = KitoOnboardingController();
  final _log = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String line) => setState(() {
        if (_log.isNotEmpty && _log.first == line) return;
        _log.insert(0, line);
        if (_log.length > 3) _log.removeLast();
      });

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      body: Column(children: [
        Expanded(
          child: KitoOnboarding(
            pages: _walletPages,
            controller: _controller,
            style: const KitoOnboardingStyle(showsSkip: false),
            onPageChanged: (p) => _add('onPageChanged($p)'),
            onSkip: () => _add('onSkip'),
            onFinish: () => _add('onFinish'),
          ),
        ),
        Material(
          color: kito.colors.surface,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Wrap(spacing: 6, children: [
                OutlinedButton(
                    onPressed: _controller.back, child: const Text('back()')),
                OutlinedButton(
                    onPressed: () => _controller.goTo(2),
                    child: const Text('goTo(2)')),
                OutlinedButton(
                    onPressed: _controller.next, child: const Text('next()')),
              ]),
              for (final l in _log) Text(l, style: kito.typography.caption),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Indicators extends StatefulWidget {
  const _Indicators();

  @override
  State<_Indicators> createState() => _IndicatorsState();
}

class _IndicatorsState extends State<_Indicators> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return SizedBox(
      width: 320,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final s in KitoOnboardingIndicator.values)
          if (s != KitoOnboardingIndicator.none)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                SizedBox(
                    width: 96,
                    child: Text(s.name, style: kito.typography.caption)),
                Expanded(
                  child: KitoOnboardingIndicatorView(
                    style: s,
                    count: 4,
                    current: _page,
                    accent: kito.colors.primary,
                    foreground: kito.colors.onBackground,
                  ),
                ),
              ]),
            ),
        Slider(
          value: _page.toDouble(),
          max: 3,
          divisions: 3,
          label: 'Page ${_page + 1}',
          onChanged: (v) => setState(() => _page = v.round()),
        ),
      ]),
    );
  }
}

class _PayIllustration extends StatelessWidget {
  const _PayIllustration();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return SizedBox(
      width: 180,
      height: 200,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 110,
          height: 190,
          decoration: BoxDecoration(
            color: kito.colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kito.colors.primary, width: 3),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            const SizedBox(height: 16),
            Icon(Icons.check_circle_rounded,
                size: 40, color: kito.colors.success),
            const SizedBox(height: 8),
            Text('KES 1,500',
                style: kito.typography.label
                    .copyWith(fontWeight: FontWeight.w800)),
            Text('to Amina K', style: kito.typography.caption),
          ]),
        ),
        PositionedDirectional(
          end: 0,
          top: 20,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: kito.colors.warning,
            child: const Icon(Icons.bolt_rounded, color: Colors.black),
          ),
        ),
      ]),
    );
  }
}

// MARK: Content

const _walletPages = [
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.send_to_mobile_rounded),
    title: 'Send money in seconds',
    message: 'Pay anyone with M-Pesa, Airtel Money or a bank account.',
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.groups_rounded),
    title: 'Save with your chama',
    message: 'Track contributions and payouts together, every Saturday.',
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.shield_rounded),
    title: 'Safe by design',
    message: 'Your PIN never leaves your phone.',
  ),
];

const _safariPages = [
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.beach_access_rounded),
    eyebrow: 'Coast',
    title: 'Diani to Lamu',
    message: 'White sand, dhows at sunset and fresh madafu.',
    background: KitoBackground.gradient(KitoGradient.sunset),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Colors.black,
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.pets_rounded),
    eyebrow: 'Savannah',
    title: 'The Maasai Mara',
    message: 'Catch the Great Migration between July and October.',
    background: KitoBackground.gradient(KitoGradient.lagoon),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Colors.black,
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.terrain_rounded),
    eyebrow: 'Highlands',
    title: 'Mount Kenya',
    message: 'Guides from Naro Moru, porters and hot chai at the top.',
    background: KitoBackground.gradient(KitoGradient.ocean),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Colors.black,
  ),
];

const _dukaPages = [
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.storefront_rounded),
    eyebrow: 'For shops',
    title: 'Run your duka',
    message: 'Everything you need behind the counter.',
    bullets: ['Accept M-Pesa and cards', 'Track stock', 'Send receipts by SMS'],
    background: KitoBackground.color(Color(0xFF0E7C66)),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Color(0xFF0E7C66),
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.inventory_2_rounded),
    eyebrow: 'Stock',
    title: 'Never run out of unga',
    message: 'Low-stock alerts before the weekend rush.',
    bullets: ['Barcode scanning', 'Supplier reorders'],
    background: KitoBackground.color(Color(0xFFE85D04)),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Color(0xFFE85D04),
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.insights_rounded),
    eyebrow: 'Reports',
    title: 'Know your best day',
    message: 'Daily sales in shillings, in your pocket.',
    background: KitoBackground.color(Color(0xFF3E63DD)),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Color(0xFF3E63DD),
  ),
];

final _customPages = [
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.custom((_) => const _PayIllustration()),
    title: 'Tap, confirm, done',
    message: 'Payments take one tap and your PIN.',
  ),
  const KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.receipt_long_rounded),
    title: 'Receipts that add up',
    message: 'Every shilling, sorted by category.',
  ),
];

final _permissionPages = [
  KitoOnboardingPage(
    artwork: const KitoOnboardingArtwork.icon(Icons.location_on_rounded),
    title: 'Find riders near you',
    message: 'We use your location only while you’re ordering.',
    permission: KitoOnboardingPermission(
      allowTitle: 'Allow location',
      onRequest: () =>
          Future<bool>.delayed(const Duration(milliseconds: 800), () => true),
    ),
  ),
  KitoOnboardingPage(
    artwork:
        const KitoOnboardingArtwork.icon(Icons.notifications_active_rounded),
    title: 'Know when your rider arrives',
    message: 'We only notify you about your orders.',
    permission: KitoOnboardingPermission(
      allowTitle: 'Allow notifications',
      onRequest: () =>
          Future<bool>.delayed(const Duration(milliseconds: 800), () => false),
    ),
  ),
  const KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.delivery_dining_rounded),
    title: 'You’re ready',
    message: 'Your first delivery in Nairobi is on us.',
  ),
];

const _swahiliPages = [
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.waving_hand_rounded),
    title: 'Karibu Kito',
    message: 'Tuma pesa, lipa bili na uweke akiba — mahali pamoja.',
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.savings_rounded),
    title: 'Weka akiba',
    message: 'Weka lengo na uone maendeleo kila wiki.',
  ),
  KitoOnboardingPage(
    artwork: KitoOnboardingArtwork.icon(Icons.lock_rounded),
    title: 'Salama kabisa',
    message: 'PIN yako haiondoki kwenye simu yako.',
  ),
];

const _bleedPages = [
  KitoOnboardingPage(
    eyebrow: 'Nairobi',
    title: 'The city under the sun',
    message: 'Rooftop cafés, matatu art and the national park next door.',
    background: KitoBackground.gradient(KitoGradient.midnight),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Colors.black,
  ),
  KitoOnboardingPage(
    eyebrow: 'Zanzibar',
    title: 'Stone Town nights',
    message: 'Forodhani food market, spice tours and ocean breeze.',
    background: KitoBackground.gradient(KitoGradient.sunset),
    foreground: Colors.white,
    accent: Colors.white,
    onAccent: Colors.black,
  ),
];
