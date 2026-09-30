// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_empty_states/kito_ui_empty_states.dart';

import '../catalog/catalog.dart';
import '../gallery/phone_stage.dart';

typedef _E = KitoEmptyStateIllustration;

/// A made-up illustration for a transport app.
const _matatu = KitoEmptyStateIllustration(
  name: 'No saved routes',
  icon: Icons.directions_bus_rounded,
  satellites: [
    Icons.route_rounded,
    Icons.schedule_rounded,
    Icons.place_rounded
  ],
  colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
  motion: KitoEmptyStateMotion.rock,
);

/// The gallery for kito_ui_empty_states.
final emptyStatesKit = KitEntry(
  title: 'Empty States',
  package: 'kito_ui_empty_states',
  blurb: 'empty, error and offline screens with animated illustrations',
  icon: Icons.inbox_rounded,
  category: KitCategory.feedback,
  isNew: true,
  sections: [
    KitSection('Illustrations', Icons.animation_rounded, [
      KitSample(
        title: 'Every preset',
        subtitle: 'Fifteen illustrations, all drawn in code — no image assets.',
        code: '''for (final illustration in KitoEmptyStateIllustration.presets)
  KitoEmptyStateIllustrationView(illustration, size: 96);''',
        builder: (_) => Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final i in _E.presets)
              KitoEmptyStateIllustrationView(i, size: 96),
          ],
        ),
      ),
      KitSample(
        title: 'Seven motions',
        subtitle: 'Float, swing, shake, bounce, beat, sweep and rock.',
        code:
            '''KitoEmptyStateIllustration.inbox.copyWith(motion: KitoEmptyStateMotion.beat)''',
        builder: (context) => Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in KitoEmptyStateMotion.values)
              Column(mainAxisSize: MainAxisSize.min, children: [
                KitoEmptyStateIllustrationView(
                    _E.favourites.copyWith(motion: m, name: m.name),
                    size: 96),
                Text(m.name, style: context.kito.typography.caption),
              ]),
          ],
        ),
      ),
      KitSample(
        title: 'Your own',
        subtitle: 'Pick an icon, satellites, colours and a motion.',
        code: '''const matatu = KitoEmptyStateIllustration(
  name: 'No saved routes',
  icon: Icons.directions_bus_rounded,
  satellites: [Icons.route_rounded, Icons.schedule_rounded, Icons.place_rounded],
  colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
  motion: KitoEmptyStateMotion.rock,
);
KitoEmptyStateIllustrationView(matatu, size: 200);''',
        builder: (_) =>
            const KitoEmptyStateIllustrationView(_matatu, size: 200),
      ),
      KitSample(
        title: 'Tinted',
        subtitle: 'Recolour any preset to match your brand.',
        code:
            '''KitoEmptyStateIllustration.cart.tinted(const [Color(0xFF00A650), Color(0xFF006B3F)])''',
        builder: (_) => Wrap(
          alignment: WrapAlignment.center,
          children: [
            const KitoEmptyStateIllustrationView(_E.cart, size: 140),
            KitoEmptyStateIllustrationView(
                _E.cart.tinted(const [Color(0xFF00A650), Color(0xFF006B3F)]),
                size: 140),
          ],
        ),
      ),
    ]),
    KitSection('Layouts', Icons.view_quilt_rounded, [
      KitSample(
        title: 'Standard',
        subtitle: 'Centred: illustration, title, message and actions.',
        code: '''KitoEmptyStateView(
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.cart),
  title: 'Your cart is empty',
  message: 'Fresh sukuma, mandazi and more are a tap away.',
  actions: [
    KitoEmptyStateAction(label: 'Start shopping', onPressed: openShop),
    KitoEmptyStateAction(label: 'View wishlist',
        role: KitoEmptyStateActionRole.secondary, onPressed: openWishlist),
  ],
)''',
        builder: (_) => KitoEmptyStateView(
          media: const KitoEmptyStateMedia.illustration(_E.cart),
          title: 'Your cart is empty',
          message: 'Fresh sukuma, mandazi and more are a tap away.',
          actions: [
            KitoEmptyStateAction(label: 'Start shopping', onPressed: () {}),
            KitoEmptyStateAction(
                label: 'View wishlist',
                role: KitoEmptyStateActionRole.secondary,
                onPressed: () {}),
          ],
        ),
      ),
      KitSample(
        title: 'Compact',
        subtitle: 'Beside the text, for a card or a list section.',
        code: '''KitoEmptyStateView(
  layout: KitoEmptyStateLayout.compact,
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.location),
  title: 'No saved addresses',
  message: 'Save home and work for faster deliveries.',
  actions: [KitoEmptyStateAction(label: 'Add address', onPressed: add)],
)''',
        builder: (_) => KitoSurface(
          border: true,
          child: KitoEmptyStateView(
            layout: KitoEmptyStateLayout.compact,
            media: const KitoEmptyStateMedia.illustration(_E.location),
            title: 'No saved addresses',
            message: 'Save home and work for faster deliveries.',
            actions: [
              KitoEmptyStateAction(label: 'Add address', onPressed: () {})
            ],
          ),
        ),
      ),
      KitSample(
        title: 'Inline',
        subtitle: 'One dashed row for an empty slot inside a form.',
        code: '''KitoEmptyStateView(
  layout: KitoEmptyStateLayout.inline,
  media: const KitoEmptyStateMedia.icon(Icons.phone_android_rounded),
  title: 'No payment methods yet',
  message: 'Add M-Pesa or a card',
  actions: [KitoEmptyStateAction(label: 'Add', onPressed: addPayment)],
)''',
        builder: (_) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: KitoEmptyStateView(
            layout: KitoEmptyStateLayout.inline,
            media: const KitoEmptyStateMedia.icon(Icons.phone_android_rounded),
            title: 'No payment methods yet',
            message: 'Add M-Pesa or a card',
            actions: [KitoEmptyStateAction(label: 'Add', onPressed: () {})],
          ),
        ),
      ),
      KitSample(
        title: 'Full screen',
        subtitle: 'A tinted backdrop with the actions at the bottom.',
        code: '''KitoEmptyStateView(
  layout: KitoEmptyStateLayout.fullScreen,
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.locked),
  title: 'Sign in to see your trips',
  message: 'Your bookings to Naivasha and Mombasa are waiting.',
  actions: [
    KitoEmptyStateAction(label: 'Sign in', onPressed: signIn),
    KitoEmptyStateAction(label: 'Create account',
        role: KitoEmptyStateActionRole.secondary, onPressed: signUp),
  ],
)''',
        builder: (_) => PhoneStage(
          height: 600,
          builder: (_) => KitoEmptyStateView(
            layout: KitoEmptyStateLayout.fullScreen,
            media: const KitoEmptyStateMedia.illustration(_E.locked),
            mediaSize: 120,
            title: 'Sign in to see your trips',
            message: 'Your bookings to Naivasha and Mombasa are waiting.',
            actions: [
              KitoEmptyStateAction(label: 'Sign in', onPressed: () {}),
              KitoEmptyStateAction(
                  label: 'Create account',
                  role: KitoEmptyStateActionRole.secondary,
                  onPressed: () {}),
            ],
          ),
        ),
      ),
    ]),
    KitSection('Presets', Icons.auto_awesome_rounded, [
      KitSample(
        title: 'No data',
        subtitle: 'A friendly default for an empty list.',
        code: '''KitoEmptyStateView.noData(
  title: 'No orders yet',
  message: 'Orders you place show up here.',
)''',
        builder: (_) => KitoEmptyStateView.noData(
            title: 'No orders yet', message: 'Orders you place show up here.'),
      ),
      KitSample(
        title: 'No results',
        subtitle: 'Echoes the search back.',
        code: '''KitoEmptyStateView.noResults(query: searchText)''',
        builder: (_) => KitoEmptyStateView.noResults(
          query: 'nyama choma in Kisumu',
          actions: [
            KitoEmptyStateAction(
                label: 'Clear filters',
                role: KitoEmptyStateActionRole.secondary,
                onPressed: () {})
          ],
        ),
      ),
      KitSample(
        title: 'Offline',
        subtitle: 'With a Retry button.',
        code: '''KitoEmptyStateView.offline(onRetry: reload)''',
        builder: (_) => KitoEmptyStateView.offline(onRetry: () {}),
      ),
      KitSample(
        title: 'Something went wrong',
        subtitle: 'Show the error and offer another go.',
        code: '''KitoEmptyStateView.error(
  message: 'We couldn’t load your statements. Your money is safe.',
  onRetry: reload,
)''',
        builder: (_) => KitoEmptyStateView.error(
          message: 'We couldn’t load your statements. Your money is safe.',
          onRetry: () {},
        ),
      ),
    ]),
    KitSection('Everyday screens', Icons.phone_iphone_rounded, [
      KitSample(
        title: 'Inbox',
        subtitle: 'Side-by-side actions.',
        code: '''KitoEmptyStateView(
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.messages),
  title: 'No messages yet',
  message: 'Say jambo to someone new.',
  actionsAxis: Axis.horizontal,
  actions: [...],
)''',
        builder: (_) => KitoEmptyStateView(
          media: const KitoEmptyStateMedia.illustration(_E.messages),
          title: 'No messages yet',
          message: 'Say jambo to someone new.',
          actionsAxis: Axis.horizontal,
          actions: [
            KitoEmptyStateAction(label: 'New chat', onPressed: () {}),
            KitoEmptyStateAction(
                label: 'Invite friends',
                role: KitoEmptyStateActionRole.secondary,
                onPressed: () {}),
          ],
        ),
      ),
      KitSample(
        title: 'All caught up',
        subtitle: 'Notifications, with a bell that swings.',
        code: '''KitoEmptyStateView(
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.notifications),
  title: 'You’re all caught up',
  message: 'We’ll let you know when your parcel leaves Nairobi.',
)''',
        builder: (_) => const KitoEmptyStateView(
          media: KitoEmptyStateMedia.illustration(_E.notifications),
          title: 'You’re all caught up',
          message: 'We’ll let you know when your parcel leaves Nairobi.',
        ),
      ),
      KitSample(
        title: 'Saved stays',
        subtitle: 'A heart that beats.',
        code: '''KitoEmptyStateView(
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.favourites),
  title: 'No saved stays',
  message: 'Tap the heart on a stay in Lamu or Diani to keep it here.',
  actions: [KitoEmptyStateAction(label: 'Explore stays', onPressed: explore)],
)''',
        builder: (_) => KitoEmptyStateView(
          media: const KitoEmptyStateMedia.illustration(_E.favourites),
          title: 'No saved stays',
          message: 'Tap the heart on a stay in Lamu or Diani to keep it here.',
          actions: [
            KitoEmptyStateAction(label: 'Explore stays', onPressed: () {})
          ],
        ),
      ),
      KitSample(
        title: 'Wallet',
        subtitle: 'A first-run state with one clear next step.',
        code: '''KitoEmptyStateView(
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.wallet),
  title: 'No transactions yet',
  message: 'Top up with M-Pesa to pay bills and buy airtime.',
  actions: [KitoEmptyStateAction(label: 'Top up', icon: Icons.add_rounded, onPressed: topUp)],
)''',
        builder: (_) => KitoEmptyStateView(
          media: const KitoEmptyStateMedia.illustration(_E.wallet),
          title: 'No transactions yet',
          message: 'Top up with M-Pesa to pay bills and buy airtime.',
          actions: [
            KitoEmptyStateAction(
                label: 'Top up', icon: Icons.add_rounded, onPressed: () {})
          ],
        ),
      ),
      KitSample(
        title: 'Payment complete',
        subtitle: 'Empty states can celebrate too.',
        code: '''KitoEmptyStateView(
  media: const KitoEmptyStateMedia.illustration(KitoEmptyStateIllustration.success),
  title: 'Asante, Wycliff N!',
  message: 'KSh 3,450 paid to Kenya Power. Receipt sent by SMS.',
  actions: [KitoEmptyStateAction(label: 'Done', onPressed: close)],
)''',
        builder: (_) => KitoEmptyStateView(
          media: const KitoEmptyStateMedia.illustration(_E.success),
          title: 'Asante, Wycliff N!',
          message: 'KSh 3,450 paid to Kenya Power. Receipt sent by SMS.',
          actions: [KitoEmptyStateAction(label: 'Done', onPressed: () {})],
        ),
      ),
      KitSample(
        title: 'Icon and custom media',
        subtitle: 'A simple icon, or any widget of your own.',
        code:
            '''KitoEmptyStateView(media: const KitoEmptyStateMedia.icon(Icons.download_rounded), ...);
KitoEmptyStateView(media: KitoEmptyStateMedia.widget(MyLottie()), ...);''',
        builder: (context) => Column(children: [
          const KitoEmptyStateView(
            layout: KitoEmptyStateLayout.compact,
            media: KitoEmptyStateMedia.icon(Icons.download_rounded),
            title: 'No downloads',
            message: 'Save episodes to listen offline on the SGR.',
          ),
          KitoEmptyStateView(
            layout: KitoEmptyStateLayout.compact,
            mediaSize: 120,
            media: KitoEmptyStateMedia.widget(Center(
              child: SizedBox.square(
                dimension: 44,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: context.kito.colors.secondary),
              ),
            )),
            title: 'Finding riders near you',
            message: 'Any widget can be the media.',
          ),
        ]),
      ),
    ]),
    KitSection('Loading and errors', Icons.sync_rounded, [
      KitSample(
        title: 'Snapshot view',
        subtitle: 'Loading, content, empty and error for a future or stream.',
        code: '''FutureBuilder(
  future: orders,
  builder: (context, snapshot) => KitoEmptyStateSnapshotView(
    snapshot: snapshot,
    isEmpty: (orders) => orders.isEmpty,
    empty: KitoEmptyStateView.noData(title: 'No orders yet'),
    onRetry: reload,
    builder: (context, orders) => OrderList(orders),
  ),
)''',
        builder: (_) => const _Snapshot(),
      ),
    ]),
  ],
);

class _Snapshot extends StatefulWidget {
  const _Snapshot();

  @override
  State<_Snapshot> createState() => _SnapshotState();
}

enum _Outcome { orders, empty, error }

class _SnapshotState extends State<_Snapshot> {
  _Outcome _outcome = _Outcome.orders;
  // The first load is instant, so opening the sample doesn't leave a timer running.
  late Future<List<String>> _future = Future.value(const [
    'Order KE-4821 · Chapati x4',
    'Order KE-4822 · Pilau',
    'Order KE-4823 · Mandazi x6'
  ]);

  Future<List<String>> _load() => Future.delayed(
        const Duration(milliseconds: 900),
        () => switch (_outcome) {
          _Outcome.orders => const [
              'Order KE-4821 · Chapati x4',
              'Order KE-4822 · Pilau',
              'Order KE-4823 · Mandazi x6'
            ],
          _Outcome.empty => const <String>[],
          _Outcome.error => throw TimeoutException('The kitchen is busy'),
        },
      );

  void _run(_Outcome outcome) => setState(() {
        _outcome = outcome;
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<_Outcome>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Outcome.orders, label: Text('Orders')),
              ButtonSegment(value: _Outcome.empty, label: Text('Empty')),
              ButtonSegment(value: _Outcome.error, label: Text('Error')),
            ],
            selected: {_outcome},
            onSelectionChanged: (s) => _run(s.first),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 380,
            child: FutureBuilder<List<String>>(
              future: _future,
              builder: (context, snapshot) => KitoEmptyStateSnapshotView(
                snapshot: snapshot,
                isEmpty: (orders) => orders.isEmpty,
                empty: KitoEmptyStateView.noData(
                    title: 'No orders yet',
                    message: 'Your chapati is one tap away.'),
                onRetry: () => _run(_outcome),
                builder: (context, orders) => ListView(
                  children: [
                    for (final o in orders)
                      ListTile(
                        leading: Icon(Icons.receipt_long_rounded,
                            color: t.colors.primary),
                        title: Text(o),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
