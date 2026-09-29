// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_toasts/kito_ui_toasts.dart';

import '../catalog/catalog.dart';
import '../gallery/phone_stage.dart';

/// Previews are still pictures, so they don't buzz when the gallery opens.
const _quiet = KitoToastAppearance(playsHaptics: false);

/// The gallery for kito_ui_toasts.
final toastsKit = KitEntry(
  title: 'Toasts',
  package: 'kito_ui_toasts',
  blurb: 'cards, pills, banners, glass and island toasts that stack',
  icon: Icons.chat_bubble_rounded,
  category: KitCategory.feedback,
  isNew: true,
  sections: [
    KitSection('Styles', Icons.palette_rounded, [
      _sample(
        title: 'Success',
        subtitle: 'A green accent, a tick and a light haptic.',
        code: '''context.kitoToasts.success('KSh 2,500 sent to Amina Otieno',
    title: 'Money sent');''',
        toast: () => KitoToast(
            title: 'Money sent',
            message: 'KSh 2,500 sent to Amina Otieno',
            style: KitoToastStyle.success),
      ),
      _sample(
        title: 'Error',
        subtitle: 'Red, with a firmer haptic.',
        code:
            '''context.kitoToasts.error('M-Pesa is taking a break. Try again in a minute.',
    title: 'Payment failed');''',
        toast: () => KitoToast(
            title: 'Payment failed',
            message: 'M-Pesa is taking a break. Try again in a minute.',
            style: KitoToastStyle.error),
      ),
      _sample(
        title: 'Warning',
        subtitle: 'Amber, for things that need attention.',
        code: '''context.kitoToasts.warning('Your balance is below KSh 200.',
    title: 'Low balance');''',
        toast: () => KitoToast(
            title: 'Low balance',
            message: 'Your balance is below KSh 200.',
            style: KitoToastStyle.warning),
      ),
      _sample(
        title: 'Info',
        subtitle: 'Neutral news in the primary colour.',
        code:
            '''context.kitoToasts.info('Your boda rider Baraka is 3 minutes away.');''',
        toast: () => KitoToast(
            message: 'Your boda rider Baraka is 3 minutes away.',
            icon: Icons.two_wheeler_rounded),
      ),
    ]),
    KitSection('Layouts', Icons.dashboard_customize_rounded, [
      _sample(
        title: 'Card',
        subtitle: 'An accent bar, icon, title, message and actions.',
        code: '''KitoToast(
  title: 'Order confirmed',
  message: 'Your Java House order will be ready at 1:15 pm.',
  style: KitoToastStyle.success,
)''',
        toast: () => KitoToast(
            title: 'Order confirmed',
            message: 'Your Java House order will be ready at 1:15 pm.',
            style: KitoToastStyle.success),
      ),
      _sample(
        title: 'Pill',
        subtitle: 'One line in a capsule, for quick confirmations.',
        code:
            '''KitoToast(message: 'Till number copied', layout: KitoToastLayout.pill,
    icon: Icons.content_copy_rounded)''',
        toast: () => KitoToast(
            message: 'Till number copied',
            layout: KitoToastLayout.pill,
            icon: Icons.content_copy_rounded),
      ),
      _sample(
        title: 'Banner',
        subtitle: 'Edge to edge in the accent colour, under the status bar.',
        code: '''KitoToast(
  title: 'You’re back online',
  message: 'Syncing your 3 saved drafts.',
  style: KitoToastStyle.success,
  layout: KitoToastLayout.banner,
)''',
        toast: () => KitoToast(
            title: 'You’re back online',
            message: 'Syncing your 3 saved drafts.',
            style: KitoToastStyle.success,
            layout: KitoToastLayout.banner),
      ),
      _sample(
        title: 'Glass',
        subtitle: 'Frosted, with a soft glow and an avatar.',
        code: '''KitoToast(
  title: 'Amina Otieno',
  message: 'Sent you a voice note · 0:42',
  layout: KitoToastLayout.glass,
  avatar: const KitoToastAvatar(initials: 'AO'),
  actions: [KitoToastAction(label: 'Play', icon: Icons.play_arrow_rounded, onPressed: play)],
)''',
        toast: () => KitoToast(
          title: 'Amina Otieno',
          message: 'Sent you a voice note · 0:42',
          layout: KitoToastLayout.glass,
          avatar: const KitoToastAvatar(initials: 'AO'),
          actions: [
            KitoToastAction(
                label: 'Play', icon: Icons.play_arrow_rounded, onPressed: () {})
          ],
        ),
      ),
      _sample(
        title: 'Island',
        subtitle: 'A black capsule that grows out of the top of the screen.',
        code: '''KitoToast(
  title: 'Recording',
  message: 'Team stand-up · 04:12',
  layout: KitoToastLayout.island,
  icon: Icons.mic_rounded,
  tint: Colors.redAccent,
)''',
        toast: () => KitoToast(
            title: 'Recording',
            message: 'Team stand-up · 04:12',
            layout: KitoToastLayout.island,
            icon: Icons.mic_rounded,
            tint: Colors.redAccent),
      ),
    ]),
    KitSection('Work in progress', Icons.hourglass_top_rounded, [
      KitSample(
        title: 'Promise',
        subtitle: 'A spinner while it runs, then success or error, same toast.',
        code: '''await context.kitoToasts.promise(
  api.placeOrder(cart),
  loading: 'Placing your order…',
  success: (order) => 'Order \${order.id} placed',
  error: (e) => 'Couldn’t place the order',
);''',
        builder: (_) => _Trigger(
          preview: KitoToast(message: 'Placing your order…', isLoading: true),
          label: 'Place order',
          onPressed: (toasts) => toasts.promise(
            Future<String>.delayed(
                const Duration(milliseconds: 1600), () => 'KE-4821'),
            loading: 'Placing your order…',
            success: (id) => 'Order $id placed. Asante!',
          ),
        ),
      ),
      KitSample(
        title: 'Upload progress',
        subtitle:
            'The bar fills in place, then the toast turns into a success.',
        code:
            '''final id = toasts.show(KitoToast(title: 'Uploading', message: 'kilifi-sunset.jpg', progress: 0));
upload.onProgress((p) => toasts.updateProgress(id, p));
toasts.complete(id, style: KitoToastStyle.success, message: 'Photo uploaded');''',
        builder: (_) => _Trigger(
          preview: KitoToast(
              title: 'Uploading', message: 'kilifi-sunset.jpg', progress: 0.6),
          label: 'Upload photo',
          onPressed: (toasts) {
            final id = toasts.show(KitoToast(
                title: 'Uploading',
                message: 'kilifi-sunset.jpg',
                progress: 0,
                icon: Icons.cloud_upload_rounded));
            var p = 0.0;
            Timer.periodic(const Duration(milliseconds: 160), (t) {
              p += 0.08;
              if (p >= 1) {
                t.cancel();
                toasts.complete(id,
                    style: KitoToastStyle.success,
                    title: 'Done',
                    message: 'Photo uploaded');
              } else {
                toasts.updateProgress(id, p);
              }
            });
          },
        ),
      ),
      KitSample(
        title: 'Undo',
        subtitle: 'A ring counts down; the delete commits if it runs out.',
        code: '''toasts.undo('Conversation with Baraka archived',
    onUndo: () => restore(chat),
    onExpire: () => api.archive(chat));''',
        builder: (_) => _Trigger(
          preview: KitoToast(
              message: 'Conversation with Baraka archived',
              showsCountdown: true,
              actions: [
                KitoToastAction(
                    label: 'Undo',
                    role: KitoToastActionRole.destructive,
                    onPressed: () {})
              ]),
          label: 'Archive chat',
          onPressed: (toasts) => toasts.undo(
            'Conversation with Baraka archived',
            onUndo: () => toasts.info('Restored'),
          ),
        ),
      ),
    ]),
    KitSection('Actions and people', Icons.people_alt_rounded, [
      _sample(
        title: 'Actions',
        subtitle: 'Primary, destructive and cancel roles.',
        code: '''KitoToast(
  title: 'Ride request',
  message: 'Wycliff N wants a ride to JKIA.',
  actions: [
    KitoToastAction(label: 'Accept', onPressed: accept),
    KitoToastAction(label: 'Decline', role: KitoToastActionRole.cancel, onPressed: decline),
  ],
)''',
        toast: () => KitoToast(
          title: 'Ride request',
          message: 'Wycliff N wants a ride to JKIA.',
          icon: Icons.local_taxi_rounded,
          actions: [
            KitoToastAction(label: 'Accept', onPressed: () {}),
            KitoToastAction(
                label: 'Decline',
                role: KitoToastActionRole.cancel,
                onPressed: () {}),
          ],
        ),
      ),
      _sample(
        title: 'Avatars',
        subtitle: 'Initials or an icon on a gradient in place of the icon.',
        code: '''KitoToast(
  title: 'Wanjiru K',
  message: 'Liked your photo from Hell’s Gate',
  avatar: const KitoToastAvatar(initials: 'WK',
      colors: [Color(0xFF00C853), Color(0xFF00B8D4)]),
)''',
        toast: () => KitoToast(
          title: 'Wanjiru K',
          message: 'Liked your photo from Hell’s Gate',
          avatar: const KitoToastAvatar(
              initials: 'WK', colors: [Color(0xFF00C853), Color(0xFF00B8D4)]),
        ),
      ),
      _sample(
        title: 'Celebrate',
        subtitle:
            'A gradient background and a large title for one special toast.',
        code: '''KitoToast(
  title: 'Achievement unlocked',
  message: '10 trips with Kito Ride. Karibu tena!',
  titleStyle: KitoToastTitleStyle.large,
  icon: Icons.emoji_events_rounded,
  tint: Colors.amber,
  background: const KitoBackground.gradient(KitoGradient.sunset),
)''',
        toast: () => KitoToast(
          title: 'Achievement unlocked',
          message: '10 trips with Kito Ride. Karibu tena!',
          titleStyle: KitoToastTitleStyle.large,
          icon: Icons.emoji_events_rounded,
          tint: Colors.amber,
          background: const KitoBackground.gradient(KitoGradient.sunset),
        ),
      ),
    ]),
    KitSection('Presentation', Icons.layers_rounded, [
      KitSample(
        title: 'Stack',
        subtitle: 'Older toasts peek out behind; tap the stack to fan it out.',
        code:
            '''final toasts = KitoToastCenter(presentation: KitoToastPresentation.stacked);
for (final m in messages) toasts.info(m);''',
        builder: (_) => _Trigger(
          label: 'Send three',
          onPressed: (toasts) {
            toasts.showMessage('Matatu 46 leaves Kencom in 5 min',
                style: KitoToastStyle.info,
                duration: const Duration(seconds: 6));
            toasts.showMessage('Rain expected in Nairobi at 4 pm',
                style: KitoToastStyle.warning,
                duration: const Duration(seconds: 6));
            toasts.showMessage('Electricity token 4821-2210-9934 received',
                style: KitoToastStyle.success,
                duration: const Duration(seconds: 6));
          },
        ),
      ),
      KitSample(
        title: 'Bottom, in its own stage',
        subtitle: 'A second host and center just for this frame.',
        code:
            '''final bottom = KitoToastCenter(position: KitoToastPosition.bottom);
KitoToastHost(center: bottom, child: screen);
bottom.success('Added to cart', layout: KitoToastLayout.pill);''',
        builder: (_) => const _BottomStage(),
      ),
      KitSample(
        title: 'Over dialogs',
        subtitle:
            'The host sits above the navigator, so dialogs don’t hide toasts.',
        code: '''MaterialApp(
  builder: (context, child) => KitoToastHost(center: toasts, child: child!),
);
showDialog(context: context, builder: (_) => const AlertDialog(...));
toasts.info('Still visible above the dialog');''',
        builder: (_) => const _OverDialog(),
      ),
      _sample(
        title: 'Swipe to dismiss',
        subtitle: 'Drag it up or down; a short drag springs back.',
        code: '''// Built in: a vertical drag past 50 points dismisses.
toasts.showMessage('Swipe me away', duration: null);''',
        toast: () => KitoToast(
            message: 'Swipe me away',
            icon: Icons.swipe_vertical_rounded,
            duration: null),
      ),
    ]),
  ],
);

/// A sample that previews [toast] and has a button to show it for real.
KitSample _sample({
  required String title,
  required String subtitle,
  required String code,
  required KitoToast Function() toast,
}) =>
    KitSample(
      title: title,
      subtitle: subtitle,
      code: code,
      builder: (_) => _Trigger(
        preview: toast(),
        label: 'Show it',
        onPressed: (toasts) => toasts.show(toast()),
      ),
    );

class _Trigger extends StatelessWidget {
  const _Trigger({this.preview, required this.label, required this.onPressed});

  final KitoToast? preview;
  final String label;
  final void Function(KitoToastCenter toasts) onPressed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview != null) ...[
              IgnorePointer(
                  child: KitoToastView(toast: preview!, appearance: _quiet)),
              const SizedBox(height: 20),
            ],
            FilledButton.icon(
              onPressed: () {
                final toasts = KitoToastHost.maybeOf(context);
                if (toasts != null) onPressed(toasts);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(label),
            ),
          ],
        ),
      );
}

class _BottomStage extends StatefulWidget {
  const _BottomStage();

  @override
  State<_BottomStage> createState() => _BottomStageState();
}

class _BottomStageState extends State<_BottomStage> {
  final _center = KitoToastCenter(position: KitoToastPosition.bottom);

  @override
  void dispose() {
    _center.dispose();
    super.dispose();
  }

  Widget _screen(BuildContext context) {
    final t = context.kito;
    return ColoredBox(
      color: t.colors.background,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.local_grocery_store_rounded),
            title: const Text('Sukuma wiki, 1 bunch'),
            subtitle: const Text('KSh 40'),
            trailing: IconButton.filledTonal(
              tooltip: 'Add to cart',
              icon: const Icon(Icons.add_shopping_cart_rounded),
              onPressed: () => _center.show(KitoToast(
                  message: 'Sukuma wiki added to cart',
                  layout: KitoToastLayout.pill,
                  style: KitoToastStyle.success)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.egg_rounded),
            title: const Text('Kienyeji eggs, tray'),
            subtitle: const Text('KSh 520'),
            trailing: IconButton.filledTonal(
              tooltip: 'Add to cart',
              icon: const Icon(Icons.add_shopping_cart_rounded),
              onPressed: () => _center.show(KitoToast(
                  message: 'Eggs added to cart',
                  layout: KitoToastLayout.pill,
                  style: KitoToastStyle.success)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PhoneStage(
        builder: (context) =>
            KitoToastHost(center: _center, child: Builder(builder: _screen)),
      );
}

class _OverDialog extends StatelessWidget {
  const _OverDialog();

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open a dialog'),
        onPressed: () {
          final toasts = KitoToastHost.maybeOf(context);
          showDialog<void>(
            context: context,
            builder: (dialog) => AlertDialog(
              title: const Text('Confirm payment'),
              content: const Text('Pay KSh 1,200 to Naivas Westlands?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => toasts?.show(KitoToast(
                      title: 'Heads up',
                      message: 'This toast sits above the dialog.',
                      style: KitoToastStyle.warning)),
                  child: const Text('Toast now'),
                ),
              ],
            ),
          );
        },
      );
}
