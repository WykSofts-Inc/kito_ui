// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kito_ui_chat/kito_ui_chat.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../app/toasts.dart';
import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';
import '../gallery/phone_frame.dart';

const _me = KitoChatUser(id: 'wycliff', name: 'Wycliff N');
const _amani = KitoChatUser(id: 'amani', name: 'Amani Wanjiru', isOnline: true);
const _baraka = KitoChatUser(id: 'baraka', name: 'Baraka Otieno');
const _chebet = KitoChatUser(
    id: 'chebet', name: 'Chebet Kiprono', color: Color(0xFF21A86B));
const _njeri = KitoChatUser(id: 'njeri', name: 'Njeri Mwangi', isOnline: true);
const _safari = KitoChatUser(
    id: 'safari', name: 'Mara Safari Crew', color: Color(0xFFF5A524));

DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) => DateTime.now()
    .subtract(Duration(days: days, hours: hours, minutes: minutes));

List<KitoChatMessage> _direct() => [
      KitoChatMessage.text('Habari! Tuonane Java House saa saba?',
          id: 'd1', author: _amani, date: _ago(days: 1, minutes: 40)),
      KitoChatMessage.text('Sawa, nitafika **mapema** 🙏',
          id: 'd2',
          author: _me,
          date: _ago(days: 1, minutes: 38),
          status: KitoChatMessageStatus.read),
      KitoChatMessage.text('Leta ile kitabu ya _Ngũgĩ_ tafadhali',
          id: 'd3', author: _amani, date: _ago(days: 1, minutes: 37)),
      KitoChatMessage(
          id: 'd4',
          author: _amani,
          date: _ago(minutes: 14),
          content: const KitoChatVoiceContent(duration: Duration(seconds: 12))),
      KitoChatMessage.text('Traffic ya Waiyaki Way ni mbaya leo 😩',
          id: 'd5', author: _amani, date: _ago(minutes: 13)),
      KitoChatMessage.text('😂',
          id: 'd6',
          author: _me,
          date: _ago(minutes: 9),
          status: KitoChatMessageStatus.read,
          reactions: const [
            KitoChatReaction('❤️', userIds: ['amani'])
          ]),
      KitoChatMessage.text(
          'Niko Westlands, dakika kumi. Menu: www.javahouseafrica.com',
          id: 'd7',
          author: _me,
          date: _ago(minutes: 2),
          status: KitoChatMessageStatus.delivered,
          replyTo: const KitoChatReply(
              messageId: 'd1',
              authorName: 'Amani Wanjiru',
              preview: 'Habari! Tuonane Java House saa saba?')),
    ];

List<KitoChatMessage> _group() => [
      KitoChatMessage(
          id: 'g0',
          author: _me,
          date: _ago(hours: 3),
          content: const KitoChatSystemContent('Chebet added Njeri')),
      KitoChatMessage.text('Game drive inaanza saa kumi na mbili asubuhi 🦁',
          id: 'g1', author: _chebet, date: _ago(hours: 2, minutes: 50)),
      KitoChatMessage.text('Nani ameleta binoculars?',
          id: 'g2', author: _chebet, date: _ago(hours: 2, minutes: 49)),
      KitoChatMessage.text('Mimi! Na power bank pia',
          id: 'g3',
          author: _me,
          date: _ago(hours: 2, minutes: 40),
          status: KitoChatMessageStatus.read),
      KitoChatMessage.text('Tumeona cheetah karibu na Talek river 🐆',
          id: 'g4', author: _baraka, date: _ago(minutes: 20)),
      KitoChatMessage.text('Ati kweli?! Tuma picha',
          id: 'g5',
          author: _njeri,
          date: _ago(minutes: 18),
          reactions: const [
            KitoChatReaction('😂', userIds: ['baraka', 'wycliff'])
          ]),
      KitoChatMessage.text('Balloon ride ni **KES 45,000** kwa mtu',
          id: 'g6', author: _chebet, date: _ago(minutes: 5)),
    ];

/// The gallery for kito_ui_chat.
final chatKit = KitEntry(
  title: 'Chat',
  package: 'kito_ui_chat',
  blurb: 'conversations, bubbles, voice notes, a composer and an inbox',
  icon: Icons.forum_rounded,
  category: KitCategory.communication,
  isNew: true,
  sections: [
    KitSection('Conversations', Icons.chat_rounded, [
      KitSample(
        title: 'Direct message',
        subtitle:
            'Send something: it goes sending → delivered → read, then Amani types back.',
        code: '''final chat = KitoChatController(messages: history);

Scaffold(
  appBar: PreferredSize(
    preferredSize: const Size.fromHeight(64),
    child: ListenableBuilder(
      listenable: chat,
      builder: (context, _) => KitoChatHeader(
          user: amani, typingUsers: chat.typingUsers),
    ),
  ),
  body: KitoChatView(
    controller: chat,
    currentUser: me,
    onSend: (m) async {
      await api.send(m);
      chat.updateStatus(m.id, KitoChatMessageStatus.delivered);
    },
  ),
)''',
        builder: (_) => PhoneFrame(builder: (_) => const _Conversation()),
      ),
      KitSample(
        title: 'iMessage style',
        subtitle: 'Curled tails, tight grouping and an unread divider.',
        code: '''KitoChatView(
  controller: chat,
  currentUser: me,
  style: KitoChatBubbleStyle.imessage,
  unreadCount: 2,
)''',
        builder: (_) => PhoneFrame(
          builder: (_) => const _Conversation(
              style: KitoChatBubbleStyle.imessage, unread: 2),
        ),
      ),
      KitSample(
        title: 'Glass on aurora',
        subtitle: 'Frosted bubbles over soft drifting colour.',
        code: '''KitoChatView(
  controller: chat,
  currentUser: me,
  style: KitoChatBubbleStyle.glass,
  wallpaper: KitoChatWallpaper.aurora,
  tint: const Color(0xFF7C4DFF),
)''',
        builder: (_) => PhoneFrame(
          builder: (_) => const _Conversation(
              style: KitoChatBubbleStyle.glass,
              wallpaper: KitoChatWallpaper.aurora,
              tint: Color(0xFF7C4DFF)),
        ),
      ),
      KitSample(
        title: 'Safari group',
        subtitle:
            'Names, avatars, a system line and reactions from several people.',
        code: '''KitoChatView(
  controller: KitoChatController(messages: groupHistory),
  currentUser: me,
  wallpaper: KitoChatWallpaper.dots,
)''',
        builder: (_) => PhoneFrame(
          builder: (_) => const _Conversation(
              group: true, wallpaper: KitoChatWallpaper.dots),
        ),
      ),
      KitSample(
        title: 'Minimal',
        subtitle: 'Outlined bubbles without tails, in the brand green.',
        code: '''KitoChatView(
  controller: chat,
  currentUser: me,
  style: KitoChatBubbleStyle.minimal,
  tint: const Color(0xFF21A86B),
)''',
        builder: (_) => PhoneFrame(
          builder: (_) => const _Conversation(
              style: KitoChatBubbleStyle.minimal, tint: Color(0xFF21A86B)),
        ),
      ),
    ]),
    KitSection('Pieces', Icons.widgets_rounded, [
      KitSample(
        title: 'Bubble styles',
        subtitle: 'Modern, minimal, glass and iMessage, both sides.',
        code: '''KitoChatBubble(
  message,
  isOutgoing: true,
  style: KitoChatBubbleStyle.imessage,
)''',
        builder: (_) => const _Bubbles(),
      ),
      KitSample(
        title: 'Read receipts',
        subtitle: 'Sending, sent, delivered, read and failed.',
        code: '''KitoChatStatusTicks(KitoChatMessageStatus.read)''',
        builder: (_) => const _Ticks(),
      ),
      KitSample(
        title: 'Typing',
        subtitle: 'Bouncing dots, and the header line that follows who types.',
        code: '''KitoChatTypingIndicator();

KitoChatHeader(
  user: amani,
  typingUsers: [amani],
  onBack: () => Navigator.pop(context),
  onCall: call,
)''',
        builder: (_) => const _Typing(),
      ),
      KitSample(
        title: 'Voice note',
        subtitle: 'Play, scrub along the waveform and cycle 1× / 1.5× / 2×.',
        code: '''KitoChatVoiceNote(
  voice: const KitoChatVoiceContent(duration: Duration(seconds: 23)),
)''',
        builder: (_) => const _Voice(),
      ),
      KitSample(
        title: 'Avatars',
        subtitle: 'Initials on a gradient, with an online dot.',
        code: '''KitoChatAvatar(amani, size: 48)''',
        builder: (_) => const Wrap(spacing: 12, runSpacing: 12, children: [
          KitoChatAvatar(_amani, size: 48),
          KitoChatAvatar(_baraka, size: 48),
          KitoChatAvatar(_chebet, size: 48),
          KitoChatAvatar(_njeri, size: 48),
          KitoChatAvatar(_safari, size: 48),
        ]),
      ),
    ]),
    KitSection('Composer', Icons.keyboard_rounded, [
      KitSample(
        title: 'Message bar',
        subtitle:
            'The mic morphs into send as you type; hold it to record, slide to cancel or up to lock.',
        code: '''KitoChatComposer(
  onSend: (content) => send(content),
  onAttach: pickPhoto,
)''',
        builder: (_) => const _Composer(),
      ),
      KitSample(
        title: 'Replying',
        subtitle: 'A quote of the message you answer, with a close button.',
        code: '''KitoChatComposer(
  replyTo: KitoChatReply.of(message),
  onCancelReply: () => setState(() => replyTo = null),
  onSend: send,
)''',
        builder: (_) => const _Composer(replying: true),
      ),
    ]),
    KitSection('Inbox', Icons.inbox_rounded, [
      KitSample(
        title: 'Conversations',
        subtitle:
            'Pinned first, unread badges, typing, muted; swipe a row for actions.',
        code: '''KitoChatList(
  conversations: conversations,
  currentUserId: me.id,
  onSelect: open,
  onChanged: (next) => setState(() => conversations = next),
)''',
        builder: (_) => PhoneFrame(builder: (_) => const _Inbox()),
      ),
    ]),
  ],
);

// MARK: - Conversation

class _Conversation extends StatefulWidget {
  const _Conversation({
    this.style = KitoChatBubbleStyle.modern,
    this.wallpaper = KitoChatWallpaper.plain,
    this.tint,
    this.unread = 0,
    this.group = false,
  });

  final KitoChatBubbleStyle style;
  final KitoChatWallpaper wallpaper;
  final Color? tint;
  final int unread;
  final bool group;

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  late final _chat =
      KitoChatController(messages: widget.group ? _group() : _direct());
  final _timers = <Timer>[];
  var _replies = 0;

  static const _answers = [
    'Poa! Nimeona 👍',
    'Hakuna matata, tuonane huko',
    'Sawa sawa. Nitakuletea chai ☕️',
  ];

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _chat.dispose();
    super.dispose();
  }

  void _later(Duration d, VoidCallback f) =>
      _timers.add(Timer(d, () => mounted ? f() : null));

  void _send(KitoChatMessage m) {
    _later(const Duration(milliseconds: 700),
        () => _chat.updateStatus(m.id, KitoChatMessageStatus.delivered));
    if (widget.group) return;
    _later(const Duration(milliseconds: 1600), () {
      _chat.updateStatus(m.id, KitoChatMessageStatus.read);
      _chat.typingUsers = [_amani];
    });
    _later(const Duration(milliseconds: 3400), () {
      _chat.typingUsers = [];
      _chat.add(KitoChatMessage.text(_answers[_replies++ % _answers.length],
          author: _amani));
    });
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      body: Column(children: [
        ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => widget.group
              ? KitoChatHeader(
                  user: _safari,
                  title: 'Mara Safari Crew',
                  subtitle: 'Chebet, Baraka, Njeri, You',
                  typingUsers: _chat.typingUsers,
                  tint: widget.tint,
                  onBack: () => Navigator.maybePop(context),
                )
              : KitoChatHeader(
                  user: _amani,
                  typingUsers: _chat.typingUsers,
                  tint: widget.tint,
                  onBack: () => Navigator.maybePop(context),
                  onCall: () => devKitToasts.info('Calling Amani…'),
                  onVideo: () => devKitToasts.info('Video call'),
                ),
        ),
        Expanded(
          child: KitoChatView(
            controller: _chat,
            currentUser: _me,
            style: widget.style,
            wallpaper: widget.wallpaper,
            tint: widget.tint,
            unreadCount: widget.unread,
            onSend: _send,
            onAttach: () => devKitToasts.info('Pick a photo'),
            onLinkTap: (uri) => devKitToasts.info('Open ${uri.host}'),
          ),
        ),
      ]),
    );
  }
}

// MARK: - Pieces

class _Bubbles extends StatelessWidget {
  const _Bubbles();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final incoming = KitoChatMessage.text('Uko wapi? 🙂',
        id: 'b-in', author: _amani, date: _ago(minutes: 3));
    final outgoing = KitoChatMessage.text('Niko njiani, nakuja!',
        id: 'b-out',
        author: _me,
        date: _ago(minutes: 2),
        status: KitoChatMessageStatus.read);
    return DemoWidth(
      width: 360,
      child: Column(children: [
        for (final style in KitoChatBubbleStyle.values) ...[
          Text(style.title,
              style: kito.typography.caption.copyWith(
                  color: kito.colors.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: KitoChatBubble(incoming, isOutgoing: false, style: style),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: KitoChatBubble(outgoing,
                isOutgoing: true, style: style, currentUserId: _me.id),
          ),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }
}

class _Ticks extends StatelessWidget {
  const _Ticks();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      children: [
        for (final s in KitoChatMessageStatus.values)
          Column(mainAxisSize: MainAxisSize.min, children: [
            KitoChatStatusTicks(s),
            const SizedBox(height: 6),
            Text(s.name,
                style: kito.typography.caption.copyWith(
                    color: kito.colors.onSurface.withValues(alpha: 0.6))),
          ]),
      ],
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return const DemoWidth(
      width: 360,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        KitoChatHeader(user: _amani, typingUsers: [_amani]),
        SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: KitoChatTypingIndicator(),
        ),
        SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: KitoChatTypingIndicator(style: KitoChatBubbleStyle.imessage),
        ),
      ]),
    );
  }
}

class _Voice extends StatelessWidget {
  const _Voice();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return DemoWidth(
      width: 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kito.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: KitoChatVoiceNote(
            seed: 'amani-voice',
            voice: KitoChatVoiceContent(duration: Duration(seconds: 23)),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({this.replying = false});

  final bool replying;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  late KitoChatReply? _reply = widget.replying
      ? const KitoChatReply(
          messageId: 'd5',
          authorName: 'Amani Wanjiru',
          preview: 'Traffic ya Waiyaki Way ni mbaya leo 😩')
      : null;

  @override
  Widget build(BuildContext context) {
    return DemoWidth(
      width: 380,
      child: KitoChatComposer(
        replyTo: _reply,
        onCancelReply: () => setState(() => _reply = null),
        onAttach: () => devKitToasts.info('Pick a photo'),
        onSend: (content) {
          final text = switch (content) {
            KitoChatTextContent(:final text) => 'Sent “$text”',
            KitoChatVoiceContent(:final duration) =>
              'Voice note, ${duration.inSeconds}s',
            _ => 'Sent',
          };
          devKitToasts.success(text);
          setState(() => _reply = null);
        },
      ),
    );
  }
}

// MARK: - Inbox

class _Inbox extends StatefulWidget {
  const _Inbox();

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  late var _conversations = [
    KitoChatConversation(
      id: 'amani',
      user: _amani,
      isPinned: true,
      unreadCount: 2,
      lastMessage: KitoChatMessage.text(
          'Traffic ya Waiyaki Way ni mbaya leo 😩',
          author: _amani,
          date: _ago(minutes: 13)),
    ),
    KitoChatConversation(
      id: 'safari',
      user: _safari,
      title: 'Mara Safari Crew',
      unreadCount: 14,
      isTyping: true,
      lastMessage: KitoChatMessage.text('Balloon ride ni KES 45,000 kwa mtu',
          author: _chebet, date: _ago(minutes: 5)),
    ),
    KitoChatConversation(
      id: 'baraka',
      user: _baraka,
      lastMessage: KitoChatMessage.text('Nitakutumia M-Pesa jioni',
          author: _me,
          date: _ago(hours: 3),
          status: KitoChatMessageStatus.read),
    ),
    KitoChatConversation(
      id: 'njeri',
      user: _njeri,
      isMuted: true,
      lastMessage: KitoChatMessage(
          author: _njeri,
          date: _ago(days: 1),
          content: const KitoChatVoiceContent(duration: Duration(seconds: 41))),
    ),
    KitoChatConversation(
      id: 'chebet',
      user: _chebet,
      lastMessage: KitoChatMessage.text('Asante kwa jana 🙏',
          author: _chebet, date: _ago(days: 4)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Scaffold(
      backgroundColor: kito.colors.background,
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: kito.colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: KitoChatList(
        conversations: _conversations,
        currentUserId: _me.id,
        onSelect: (c) => devKitToasts.info('Open ${c.displayName}'),
        onChanged: (next) => setState(() => _conversations = next),
      ),
    );
  }
}
