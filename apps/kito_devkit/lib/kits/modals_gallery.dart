// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_modals/kito_ui_modals.dart';

import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';
import '../gallery/phone_frame.dart';

/// The gallery for kito_ui_modals.
final modalsKit = KitEntry(
  title: 'Modals',
  package: 'kito_ui_modals',
  blurb: 'sheets, alerts, menus, tooltips, status dialogs and hero cards',
  icon: Icons.web_asset_rounded,
  category: KitCategory.feedback,
  isNew: true,
  sections: [
    KitSection('Sheets', Icons.vertical_align_top_rounded, [
      KitSample(
        title: 'Fitted sheet',
        subtitle:
            'Sizes itself to its content; drag down, tap outside or Escape to close.',
        code: '''showKitoSheet<void>(
  context: context,
  builder: (context) => const RestaurantFilters(),
);''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Nairobi eats',
            icon: Icons.restaurant_rounded,
            actions: [
              (
                'Filters',
                (context) async {
                  await showKitoSheet<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (context) => const _Filters(),
                  );
                  return null;
                }
              ),
            ],
          ),
        ),
      ),
      KitSample(
        title: 'Detents and a result',
        subtitle:
            'A floating sheet that rests at fit, 60% or full, and returns a choice.',
        code: '''final method = await showKitoSheet<String>(
  context: context,
  configuration: const KitoSheetConfiguration(
    detents: [KitoSheetDetent.fit, KitoSheetDetent.fraction(0.6), KitoSheetDetent.large],
    style: KitoSheetStyle.floating,
  ),
  builder: (context) => PaymentMethods(
    onPicked: (m) => KitoSheetController.of(context).dismiss(m),
  ),
);''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Checkout',
            icon: Icons.shopping_cart_checkout_rounded,
            actions: [
              (
                'Choose how to pay',
                (context) async {
                  final m = await showKitoSheet<String>(
                    context: context,
                    useRootNavigator: false,
                    configuration: const KitoSheetConfiguration(
                      detents: [
                        KitoSheetDetent.fit,
                        KitoSheetDetent.fraction(0.6),
                        KitoSheetDetent.large,
                      ],
                      style: KitoSheetStyle.floating,
                    ),
                    builder: (context) => const _PaymentMethods(),
                  );
                  return m == null ? null : 'Paying with $m';
                }
              ),
            ],
          ),
        ),
      ),
      KitSample(
        title: 'Glass sheet',
        subtitle: 'The glass style over a blurred backdrop.',
        code: '''showKitoSheet<void>(
  context: context,
  configuration: const KitoSheetConfiguration(
    style: KitoSheetStyle.glass,
    blursBackdrop: true,
  ),
  builder: (context) => const ShareSheet(),
);''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Maasai Mara trip',
            icon: Icons.landscape_rounded,
            gradient: KitoGradient.sunset,
            actions: [
              (
                'Share',
                (context) async {
                  await showKitoSheet<void>(
                    context: context,
                    useRootNavigator: false,
                    configuration: const KitoSheetConfiguration(
                      style: KitoSheetStyle.glass,
                      blursBackdrop: true,
                    ),
                    builder: (context) => const _Share(),
                  );
                  return null;
                }
              ),
            ],
          ),
        ),
      ),
      KitSample(
        title: 'Scrolling comments',
        subtitle:
            'A list inside the sheet, with a pinned header; half height or full.',
        code: '''showKitoSheet<void>(
  context: context,
  configuration: const KitoSheetConfiguration.scrollable(
    detents: [KitoSheetDetent.fraction(0.5), KitoSheetDetent.large],
  ),
  headerBuilder: (context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Comments'),
  ),
  builder: (context) => ListView.builder(
    itemCount: comments.length,
    itemBuilder: (context, i) => CommentTile(comments[i]),
  ),
);''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Wycliff N posted',
            icon: Icons.photo_rounded,
            actions: [
              (
                '24 comments',
                (context) async {
                  await showKitoSheet<void>(
                    context: context,
                    useRootNavigator: false,
                    configuration: const KitoSheetConfiguration.scrollable(
                      detents: [
                        KitoSheetDetent.fraction(0.5),
                        KitoSheetDetent.large
                      ],
                    ),
                    headerBuilder: (context) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text('Comments',
                          style: context.kito.typography.headline),
                    ),
                    builder: (context) => const _Comments(),
                  );
                  return null;
                }
              ),
            ],
          ),
        ),
      ),
      KitSample(
        title: 'Controlled from inside',
        subtitle: 'snapTo and dismiss from the sheet’s own buttons.',
        code: '''final sheet = KitoSheetController.of(context);
TextButton(onPressed: () => sheet.snapTo(1), child: const Text('Expand'));
TextButton(onPressed: sheet.dismiss, child: const Text('Done'));''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Trip to Mombasa',
            icon: Icons.train_rounded,
            actions: [
              (
                'Trip details',
                (context) async {
                  await showKitoSheet<void>(
                    context: context,
                    useRootNavigator: false,
                    configuration: const KitoSheetConfiguration(
                      detents: [
                        KitoSheetDetent.fraction(0.35),
                        KitoSheetDetent.large
                      ],
                    ),
                    builder: (context) => const _SnapControls(),
                  );
                  return null;
                }
              ),
            ],
          ),
        ),
      ),
    ]),
    KitSection('Alerts', Icons.error_outline_rounded, [
      KitSample(
        title: 'Alert card',
        subtitle:
            'The alert on its own: an icon badge, a message and two actions.',
        code: '''KitoAlertCard(
  alert: KitoAlert(
    icon: Icons.delete_rounded,
    title: 'Remove saved card?',
    message: 'Visa ending 4821 will be removed from your wallet.',
    actions: [
      const KitoAlertAction.cancel(),
      KitoAlertAction('Remove', role: KitoAlertRole.destructive, onPressed: remove),
    ],
  ),
  onAction: (action) => ...,
);''',
        builder: (_) => DemoWidth(
          width: 320,
          child: KitoAlertCard(
            alert: const KitoAlert(
              icon: Icons.delete_rounded,
              title: 'Remove saved card?',
              message: 'Visa ending 4821 will be removed from your wallet.',
              actions: [
                KitoAlertAction.cancel(),
                KitoAlertAction('Remove', role: KitoAlertRole.destructive),
              ],
            ),
            onAction: (_) {},
          ),
        ),
      ),
      KitSample(
        title: 'Stacked actions',
        subtitle: 'Three or longer actions stack, with cancel last.',
        code: '''KitoAlert(
  icon: Icons.wifi_off_rounded,
  title: 'You’re offline',
  message: 'We’ll send your order when you’re back online.',
  actions: [
    KitoAlertAction('Retry now'),
    KitoAlertAction('Send by SMS instead', role: KitoAlertRole.secondary),
    KitoAlertAction.cancel('Not now'),
  ],
);''',
        builder: (_) => DemoWidth(
          width: 320,
          child: KitoAlertCard(
            alert: const KitoAlert(
              icon: Icons.wifi_off_rounded,
              title: 'You’re offline',
              message: 'We’ll send your order when you’re back online.',
              actions: [
                KitoAlertAction('Retry now'),
                KitoAlertAction('Send by SMS instead',
                    role: KitoAlertRole.secondary),
                KitoAlertAction.cancel('Not now'),
              ],
            ),
            onAction: (_) {},
          ),
        ),
      ),
      KitSample(
        title: 'Alerts in a flow',
        subtitle:
            'Destructive, celebration with confetti, and a yes-or-no confirmation.',
        code: '''await showKitoAlert(context, const KitoAlert(
  icon: Icons.celebration_rounded,
  title: 'Order placed!',
  message: 'Your nyama choma arrives in 25 minutes.',
  celebrates: true,
));

if (await showKitoConfirmation(context,
    title: 'Sign out?', confirmTitle: 'Sign out', isDestructive: true)) {
  signOut();
}''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Account',
            icon: Icons.person_rounded,
            actions: [
              (
                'Delete account',
                (context) async {
                  final a = await showKitoAlert(
                    context,
                    const KitoAlert(
                      icon: Icons.delete_forever_rounded,
                      title: 'Delete account?',
                      message: 'Your M-Pesa history in the app goes too. This '
                          "can't be undone.",
                      actions: [
                        KitoAlertAction.cancel(),
                        KitoAlertAction('Delete',
                            role: KitoAlertRole.destructive),
                      ],
                    ),
                    useRootNavigator: false,
                  );
                  return a == null ? null : 'Picked “${a.title}”';
                }
              ),
              (
                'Place order',
                (context) async {
                  await showKitoAlert(
                    context,
                    const KitoAlert(
                      icon: Icons.celebration_rounded,
                      title: 'Order placed!',
                      message: 'Your nyama choma arrives in 25 minutes.',
                      celebrates: true,
                    ),
                    useRootNavigator: false,
                  );
                  return 'Asante!';
                }
              ),
              (
                'Sign out',
                (context) async {
                  final a = await showKitoAlert(
                    context,
                    const KitoAlert(
                      icon: Icons.logout_rounded,
                      title: 'Sign out?',
                      message: 'You’ll need your PIN to sign back in.',
                      actions: [
                        KitoAlertAction.cancel(),
                        KitoAlertAction('Sign out',
                            role: KitoAlertRole.destructive),
                      ],
                    ),
                    useRootNavigator: false,
                  );
                  return a?.role == KitoAlertRole.destructive
                      ? 'Signed out'
                      : 'Stayed signed in';
                }
              ),
            ],
          ),
        ),
      ),
    ]),
    KitSection('Menus and tips', Icons.more_horiz_rounded, [
      KitSample(
        title: 'Action menu',
        subtitle: 'A floating list of actions with a separate Cancel.',
        code: '''showKitoActionMenu(context, title: 'Profile photo', actions: [
  KitoMenuAction('Take photo', icon: Icons.photo_camera_rounded, onPressed: takePhoto),
  KitoMenuAction('Choose from library', icon: Icons.photo_library_rounded, onPressed: pick),
  KitoMenuAction('Remove photo', icon: Icons.delete_rounded, isDestructive: true, onPressed: remove),
]);''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Wycliff N',
            icon: Icons.account_circle_rounded,
            actions: [
              (
                'Change photo',
                (context) async {
                  final picked = await showKitoSheet<KitoMenuAction>(
                    context: context,
                    useRootNavigator: false,
                    configuration: const KitoSheetConfiguration(
                      style: KitoSheetStyle.floating,
                      showsGrabber: false,
                      background: Color(0x00000000),
                    ),
                    builder: (context) => KitoActionMenuContent(
                      title: 'Profile photo',
                      actions: _photoActions,
                      onPicked: (a) =>
                          KitoSheetController.of(context).dismiss(a),
                      onCancel: () => KitoSheetController.of(context).dismiss(),
                    ),
                  );
                  return picked?.title;
                }
              ),
            ],
          ),
        ),
      ),
      KitSample(
        title: 'Menu content',
        subtitle: 'The same rows, drawn inline.',
        code: '''KitoActionMenuContent(
  title: 'Order #KE-2041',
  message: 'Rider Otieno is 5 minutes away',
  actions: [
    KitoMenuAction('Call rider', icon: Icons.call_rounded),
    KitoMenuAction('Share live location', icon: Icons.share_location_rounded),
    KitoMenuAction('Cancel order', icon: Icons.cancel_rounded, isDestructive: true),
  ],
  onPicked: handle,
  onCancel: close,
);''',
        builder: (_) => DemoWidth(
          width: 330,
          child: KitoActionMenuContent(
            title: 'Order #KE-2041',
            message: 'Rider Otieno is 5 minutes away',
            actions: const [
              KitoMenuAction('Call rider', icon: Icons.call_rounded),
              KitoMenuAction('Share live location',
                  icon: Icons.share_location_rounded),
              KitoMenuAction('Cancel order',
                  icon: Icons.cancel_rounded, isDestructive: true),
            ],
            onPicked: (_) {},
            onCancel: () {},
          ),
        ),
      ),
      KitSample(
        title: 'Tooltip',
        subtitle:
            'A bubble that floats above or below without moving the layout.',
        code: '''KitoModalTooltip(
  visible: showTip,
  message: 'Save a till number for quick payments',
  icon: Icons.auto_awesome_rounded,
  edge: KitoModalTooltipEdge.bottom,
  onDismiss: () => setState(() => showTip = false),
  child: addTillButton,
);''',
        builder: (_) => const _Tooltips(),
      ),
    ]),
    KitSection('Status and confirm', Icons.task_alt_rounded, [
      KitSample(
        title: 'Status views',
        subtitle:
            'Pending, success and failure; the tick and cross draw themselves.',
        code:
            '''KitoStatusDialogView(state: const KitoStatusDialogState.pending('Sending…'));
KitoStatusDialogView(state: const KitoStatusDialogState.success('Sent'));
KitoStatusDialogView(state: const KitoStatusDialogState.failure('Failed'));''',
        builder: (_) => const Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            KitoStatusDialogView(
                state: KitoStatusDialogState.pending('Sending…')),
            KitoStatusDialogView(state: KitoStatusDialogState.success('Sent')),
            KitoStatusDialogView(
                state: KitoStatusDialogState.failure('Failed')),
          ],
        ),
      ),
      KitSample(
        title: 'Payment status',
        subtitle: 'A blocking dialog that updates as the payment goes through.',
        code: '''final status = showKitoStatusDialog(context,
    state: const KitoStatusDialogState.pending('Waiting for M-Pesa…'));
try {
  await mpesa.stkPush(amount: 1800);
  status.update(const KitoStatusDialogState.success('KES 1,800 paid'));
} catch (_) {
  status.update(const KitoStatusDialogState.failure('Payment cancelled'));
}''',
        builder: (_) => PhoneFrame(
          builder: (_) => _Launcher(
            title: 'Pay KES 1,800',
            icon: Icons.phone_android_rounded,
            actions: [
              ('Pay (succeeds)', (context) => _pay(context, succeed: true)),
              ('Pay (cancelled)', (context) => _pay(context, succeed: false)),
            ],
          ),
        ),
      ),
      KitSample(
        title: 'In one line',
        subtitle: 'runWithKitoStatusDialog wraps any Future.',
        code:
            '''await runWithKitoStatusDialog(context, () => api.saveProfile(wycliff),
    pendingMessage: 'Saving…', successMessage: 'Saved', failureMessage: 'Try again');''',
        builder: (_) => const _RunWith(),
      ),
      KitSample(
        title: 'Slide to pay',
        subtitle: 'Slide past 85% to confirm; Enter or a double tap work too.',
        code: '''KitoSlideToConfirm(
  title: 'Slide to pay KES 2,450',
  icon: Icons.chevron_right_rounded,
  tint: const Color(0xFF1FA84F),
  resetAfter: const Duration(seconds: 2),
  onConfirm: () => mpesa.pay(2450),
);''',
        builder: (_) => DemoWidth(
          width: 330,
          child: KitoSlideToConfirm(
            title: 'Slide to pay KES 2,450',
            tint: const Color(0xFF1FA84F),
            resetAfter: const Duration(seconds: 2),
            onConfirm: () =>
                Future<void>.delayed(const Duration(milliseconds: 1200)),
          ),
        ),
      ),
      KitSample(
        title: 'Slide that fails',
        subtitle:
            'Throw from onConfirm: a cross, “Try again”, and it slides back.',
        code: '''KitoSlideToConfirm(
  title: 'Slide to withdraw',
  failureTitle: 'Agent unavailable',
  onConfirm: () async => throw AgentUnavailable(),
);''',
        builder: (_) => DemoWidth(
          width: 330,
          child: KitoSlideToConfirm(
            title: 'Slide to withdraw',
            failureTitle: 'Agent unavailable',
            onConfirm: () async {
              await Future<void>.delayed(const Duration(milliseconds: 900));
              throw StateError('Agent unavailable');
            },
          ),
        ),
      ),
    ]),
    KitSection('Stories', Icons.auto_stories_rounded, [
      KitSample(
        title: 'Hero cards',
        subtitle: 'Tap a card and it flies up into its story.',
        code: '''ListView(children: [
  for (final story in stories)
    KitoModalHeroCard(
      tag: story.id,
      collapsed: (context) => StoryFace(story),
      expanded: (context) => StoryBody(story),
    ),
]);''',
        builder: (_) => PhoneFrame(builder: (_) => const _Stories()),
      ),
    ]),
  ],
);

// MARK: Shared

typedef _Action = Future<String?> Function(BuildContext context);

const _photoActions = [
  KitoMenuAction('Take photo', icon: Icons.photo_camera_rounded),
  KitoMenuAction('Choose from library', icon: Icons.photo_library_rounded),
  KitoMenuAction('Remove photo',
      icon: Icons.delete_rounded, isDestructive: true),
];

/// A small screen with buttons that open modals inside the phone frame.
class _Launcher extends StatefulWidget {
  const _Launcher(
      {required this.title,
      required this.icon,
      required this.actions,
      this.gradient = KitoGradient.ocean});

  final String title;
  final IconData icon;
  final List<(String, _Action)> actions;
  final KitoGradient gradient;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  String? _result;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: kito.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SizedBox(
            height: 180,
            child: KitoSurface(
              background: KitoBackground.gradient(widget.gradient),
              child: Center(
                  child: Icon(widget.icon, size: 64, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          for (final line in const [0.9, 0.7, 0.8])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: line,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                      color: kito.colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          for (final (label, action) in widget.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(
                builder: (context) => FilledButton(
                  onPressed: () async {
                    final r = await action(context);
                    if (mounted && r != null) setState(() => _result = r);
                  },
                  child: Text(label),
                ),
              ),
            ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_result!,
                  textAlign: TextAlign.center,
                  style: kito.typography.label.copyWith(
                      color: kito.colors.onBackground.withValues(alpha: 0.7))),
            ),
        ],
      ),
    );
  }
}

Future<String?> _pay(BuildContext context, {required bool succeed}) async {
  final status = showKitoStatusDialog(context,
      state: const KitoStatusDialogState.pending('Waiting for M-Pesa…'),
      useRootNavigator: false);
  await Future<void>.delayed(const Duration(milliseconds: 1600));
  status.update(succeed
      ? const KitoStatusDialogState.success('KES 1,800 paid')
      : const KitoStatusDialogState.failure('Payment cancelled'));
  await status.closed;
  return succeed ? 'Receipt QK7H2X9P sent by SMS' : 'Nothing was charged';
}

// MARK: Sheet contents

class _Filters extends StatefulWidget {
  const _Filters();

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final _picked = {'Swahili', 'Open now'};
  double _budget = 1500;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: kito.typography.title),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final f in [
              'Swahili',
              'Ethiopian',
              'Nyama choma',
              'Vegetarian',
              'Open now',
              'Delivers to Kilimani'
            ])
              FilterChip(
                label: Text(f),
                selected: _picked.contains(f),
                onSelected: (on) =>
                    setState(() => on ? _picked.add(f) : _picked.remove(f)),
              ),
          ]),
          const SizedBox(height: 16),
          Text('Budget per person: KES ${_budget.round()}',
              style: kito.typography.label),
          Slider(
              value: _budget,
              min: 300,
              max: 5000,
              onChanged: (v) => setState(() => _budget = v)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => KitoSheetController.of(context).dismiss(),
              child: const Text('Show 38 places'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    const methods = [
      ('M-Pesa', '0712 ••• 678', Icons.phone_android_rounded),
      ('Airtel Money', '0733 ••• 456', Icons.sim_card_rounded),
      ('Visa', '•••• 4821', Icons.credit_card_rounded),
      ('Cash on delivery', 'Pay the rider', Icons.payments_rounded),
    ];
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Pay with', style: kito.typography.title),
          const SizedBox(height: 8),
          for (final (name, detail, icon) in methods)
            ListTile(
              leading: Icon(icon),
              title: Text(name),
              subtitle: Text(detail),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => KitoSheetController.of(context).dismiss(name),
            ),
        ]),
      ),
    );
  }
}

class _Share extends StatelessWidget {
  const _Share();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    const targets = [
      ('WhatsApp', Icons.chat_rounded),
      ('Telegram', Icons.send_rounded),
      ('SMS', Icons.sms_rounded),
      ('Email', Icons.mail_rounded),
      ('Copy link', Icons.link_rounded),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Share trip photos', style: kito.typography.headline),
        const SizedBox(height: 16),
        Wrap(spacing: 18, runSpacing: 14, children: [
          for (final (name, icon) in targets)
            Column(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(radius: 24, child: Icon(icon)),
              const SizedBox(height: 6),
              Text(name, style: kito.typography.caption),
            ]),
        ]),
      ]),
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments();

  static const _names = [
    'Amina K',
    'Otieno M',
    'Wanjiku M',
    'Kiprono T',
    'Halima A',
    'Baraka J',
  ];
  static const _lines = [
    'Hii picha ni moto 🔥',
    'Where is this? Looks like Diani.',
    'Nimeipenda sana!',
    'The sunset colours 😍',
    'Take me with you next time',
    'Karibu Mombasa!',
  ];

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: ListView.builder(
          itemCount: 24,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(
                child: Text(_names[i % _names.length].substring(0, 1))),
            title: Text(_names[i % _names.length]),
            subtitle: Text(_lines[(i * 5) % _lines.length]),
          ),
        ),
      );
}

class _SnapControls extends StatelessWidget {
  const _SnapControls();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final sheet = KitoSheetController.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Madaraka Express', style: kito.typography.title),
          Text('Nairobi Terminus → Mombasa Terminus · 08:00',
              style: kito.typography.label),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonal(
                onPressed: () => sheet.snapTo(1), child: const Text('Expand')),
            OutlinedButton(
                onPressed: () => sheet.snapTo(0),
                child: const Text('Collapse')),
            TextButton(onPressed: sheet.dismiss, child: const Text('Done')),
          ]),
          const SizedBox(height: 16),
          for (final (stop, time) in const [
            ('Syokimau', '08:20'),
            ('Athi River', '08:40'),
            ('Emali', '09:40'),
            ('Mtito Andei', '11:00'),
            ('Voi', '12:30'),
            ('Miasenyi', '13:05'),
            ('Mariakani', '13:55'),
            ('Mombasa Terminus', '14:10'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                const Icon(Icons.circle, size: 10),
                const SizedBox(width: 12),
                Expanded(child: Text(stop)),
                Text(time, style: kito.typography.label),
              ]),
            ),
        ],
      ),
    );
  }
}

// MARK: Tips and status

class _Tooltips extends StatefulWidget {
  const _Tooltips();

  @override
  State<_Tooltips> createState() => _TooltipsState();
}

class _TooltipsState extends State<_Tooltips> {
  bool _top = true;
  bool _bottom = true;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 70),
        child: Wrap(spacing: 24, runSpacing: 24, children: [
          KitoModalTooltip(
            visible: _top,
            message: 'Save a till number for quick payments',
            icon: Icons.auto_awesome_rounded,
            onDismiss: () => setState(() => _top = false),
            child: FilledButton.icon(
              onPressed: () => setState(() => _top = !_top),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add till'),
            ),
          ),
          KitoModalTooltip(
            visible: _bottom,
            message: 'New: split bills with your chama',
            edge: KitoModalTooltipEdge.bottom,
            tint: const Color(0xFF0E7C66),
            onDismiss: () => setState(() => _bottom = false),
            child: OutlinedButton(
              onPressed: () => setState(() => _bottom = !_bottom),
              child: const Text('Split bill'),
            ),
          ),
        ]),
      );
}

class _RunWith extends StatelessWidget {
  const _RunWith();

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, children: [
        FilledButton(
          onPressed: () => runWithKitoStatusDialog(
            context,
            () => Future<void>.delayed(const Duration(milliseconds: 1200)),
            pendingMessage: 'Saving…',
            successMessage: 'Saved',
            failureMessage: 'Try again',
          ),
          child: const Text('Save profile'),
        ),
        OutlinedButton(
          onPressed: () async {
            try {
              await runWithKitoStatusDialog(
                context,
                () async {
                  await Future<void>.delayed(
                      const Duration(milliseconds: 1200));
                  throw StateError('No network');
                },
                pendingMessage: 'Uploading…',
                failureMessage: 'No network',
              );
            } catch (_) {
              // The dialog has shown the failure already.
            }
          },
          child: const Text('Upload (fails)'),
        ),
      ]);
}

// MARK: Stories

class _Stories extends StatelessWidget {
  const _Stories();

  static const _stories = [
    (
      'lamu',
      'Old Town, Lamu',
      'Dhows, donkeys and Swahili doors carved centuries ago.',
      KitoGradient.sunset,
      Icons.sailing_rounded
    ),
    (
      'mara',
      'The Great Migration',
      'Two million wildebeest cross the Mara River between July and October.',
      KitoGradient.lagoon,
      Icons.pets_rounded
    ),
    (
      'kenya',
      'Mount Kenya at dawn',
      'Point Lenana, 4,985 m, and a sunrise above the clouds.',
      KitoGradient.ocean,
      Icons.terrain_rounded
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      appBar: AppBar(
        title: const Text('Today'),
        backgroundColor: kito.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (id, title, blurb, gradient, icon) in _stories)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: KitoModalHeroCard(
                tag: id,
                height: 260,
                collapsed: (context) => KitoSurface(
                  radius: 0,
                  background: KitoBackground.gradient(gradient),
                  padding: const EdgeInsets.all(18),
                  child: Stack(children: [
                    Center(
                        child: Icon(icon,
                            size: 90,
                            color: Colors.white.withValues(alpha: 0.85))),
                    Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Text(title,
                          style: kito.typography.title
                              .copyWith(color: Colors.white)),
                    ),
                  ]),
                ),
                expanded: (context) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: kito.typography.title),
                      const SizedBox(height: 10),
                      Text(blurb, style: kito.typography.body),
                      const SizedBox(height: 10),
                      Text(
                          'Written by Wycliff N for Kito Travel. Best visited '
                          'between June and October, when the rains have passed.',
                          style: kito.typography.body),
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
