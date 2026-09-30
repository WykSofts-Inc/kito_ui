// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_chat/kito_ui_chat.dart';

import 'host.dart';

const me = KitoChatUser(id: 'wycliff', name: 'Wycliff N');
const amani = KitoChatUser(id: 'amani', name: 'Amani Wanjiru', isOnline: true);
const baraka = KitoChatUser(id: 'baraka', name: 'Baraka Otieno');

List<KitoChatMessage> history(DateTime now) => [
      KitoChatMessage.text('Habari! Tuonane Java saa saba?',
          id: 'm1', author: amani, date: now.subtract(const Duration(days: 1))),
      KitoChatMessage.text('Sawa, nitafika **mapema** 🙏',
          id: 'm2',
          author: me,
          date: now.subtract(const Duration(days: 1, minutes: -1)),
          status: KitoChatMessageStatus.read),
      KitoChatMessage(
          id: 'm3',
          author: amani,
          date: now.subtract(const Duration(minutes: 3)),
          content: const KitoChatVoiceContent(duration: Duration(seconds: 9))),
      KitoChatMessage.text('❤️',
          id: 'm4',
          author: amani,
          date: now.subtract(const Duration(minutes: 2)),
          reactions: const [
            KitoChatReaction('😂', userIds: ['wycliff'])
          ]),
      KitoChatMessage.text('Niko njiani',
          id: 'm5',
          author: me,
          date: now.subtract(const Duration(minutes: 1)),
          status: KitoChatMessageStatus.failed,
          replyTo: const KitoChatReply(
              messageId: 'm1',
              authorName: 'Amani Wanjiru',
              preview: 'Habari!')),
    ];

Widget chat(KitoChatController c,
        {KitoChatBubbleStyle style = KitoChatBubbleStyle.modern,
        KitoChatWallpaper wallpaper = KitoChatWallpaper.plain,
        ValueChanged<KitoChatMessage>? onSend,
        int unread = 0}) =>
    SizedBox(
      width: 390,
      height: 700,
      child: KitoChatView(
        controller: c,
        currentUser: me,
        style: style,
        wallpaper: wallpaper,
        unreadCount: unread,
        onSend: onSend,
        onAttach: () {},
      ),
    );

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final now = DateTime.now();

  testWidgets(
      'every style and wallpaper renders LTR and RTL, with and without motion',
      (tester) async {
    for (final style in KitoChatBubbleStyle.values) {
      for (final dir in TextDirection.values) {
        for (final reduce in [false, true]) {
          final c =
              KitoChatController(messages: history(now), typingUsers: [amani]);
          await tester.pumpWidget(host(
            chat(c,
                style: style,
                wallpaper: KitoChatWallpaper.values[style.index % 3]),
            direction: dir,
            reduceMotion: reduce,
            brightness: reduce ? Brightness.dark : Brightness.light,
          ));
          await settle(tester);
          expect(find.text('Niko njiani'), findsOneWidget);
          c.dispose();
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('sending appends a sending message and hands it over',
      (tester) async {
    final c = KitoChatController(messages: history(now));
    final sent = <KitoChatMessage>[];
    await tester.pumpWidget(host(chat(c, onSend: sent.add)));
    await settle(tester);
    expect(find.bySemanticsLabel('Record voice message'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Niko Westlands  ');
    await tester.pump();
    expect(find.bySemanticsLabel('Send'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Send'));
    await settle(tester);
    expect(sent.single.content, const KitoChatTextContent('Niko Westlands'));
    expect(sent.single.status, KitoChatMessageStatus.sending);
    expect(c.messages.last.id, sent.single.id);
    expect(find.text('Niko Westlands'), findsOneWidget);
    c.dispose();
  });

  testWidgets('failed messages retry and statuses read aloud', (tester) async {
    final handle = tester.ensureSemantics();
    final c = KitoChatController(messages: history(now));
    final sent = <KitoChatMessage>[];
    await tester.pumpWidget(host(chat(c, onSend: sent.add)));
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp(r'^You: Niko njiani')), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Not delivered. Retry'));
    await settle(tester);
    expect(c.byId('m5')!.status, KitoChatMessageStatus.sending);
    expect(sent.single.id, 'm5');
    handle.dispose();
    c.dispose();
  });

  testWidgets(
      'long press lifts the bubble; reacting and deleting edit the controller',
      (tester) async {
    final c = KitoChatController(messages: history(now));
    await tester.pumpWidget(host(chat(c)));
    await settle(tester);
    await tester.longPress(find.text('Niko njiani'));
    await settle(tester);
    expect(find.byType(KitoChatReactionOverlay), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    await tester.tap(find.text('😮'));
    await settle(tester);
    expect(find.byType(KitoChatReactionOverlay), findsNothing);
    expect(c.byId('m5')!.reactionOf(me.id), '😮');

    await tester.longPress(find.text('Niko njiani'));
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(c.byId('m5'), isNull);
    c.dispose();
  });

  for (final dir in TextDirection.values) {
    testWidgets('swiping toward the trailing edge replies ($dir)',
        (tester) async {
      final c = KitoChatController(messages: history(now));
      await tester.pumpWidget(host(chat(c), direction: dir));
      await settle(tester);
      final sign = dir == TextDirection.rtl ? -1.0 : 1.0;
      // The wrong way does nothing.
      await tester.drag(find.text('Niko njiani'), Offset(-160 * sign, 0));
      await settle(tester);
      expect(find.textContaining('Replying to'), findsNothing);
      await tester.drag(find.text('Niko njiani'), Offset(220 * sign, 0));
      await settle(tester);
      expect(find.text('Replying to Wycliff N'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Cancel reply'));
      await settle(tester);
      expect(find.textContaining('Replying to'), findsNothing);
      c.dispose();
    });
  }

  testWidgets('screen-reader actions reply, react and copy', (tester) async {
    final handle = tester.ensureSemantics();
    final c = KitoChatController(messages: history(now));
    await tester.pumpWidget(host(chat(c)));
    await settle(tester);
    final node = tester
        .getSemantics(find.bySemanticsLabel(RegExp(r'^You: Niko njiani')));
    final data = node.getSemanticsData();
    final labels = data.customSemanticsActionIds!
        .map((id) => CustomSemanticsAction.getAction(id)!.label)
        .toList();
    expect(
        labels, containsAll(['Reply', 'React with a heart', 'Copy', 'Delete']));
    final react = data.customSemanticsActionIds!.firstWhere((id) =>
        CustomSemanticsAction.getAction(id)!.label == 'React with a heart');
    node.owner!.performAction(node.id, SemanticsAction.customAction, react);
    await settle(tester);
    expect(c.byId('m5')!.reactionOf(me.id), '❤️');
    handle.dispose();
    c.dispose();
  });

  testWidgets('tapping a bubble reveals its time; a quote jumps to its message',
      (tester) async {
    final c = KitoChatController(messages: history(now));
    await tester.pumpWidget(host(chat(c)));
    await settle(tester);
    final time = KitoChatDateFormat.time(c.byId('m4')!.date);
    expect(find.text(time), findsNothing);
    await tester.tap(find.text('❤️'));
    await settle(tester);
    expect(find.text(time), findsOneWidget);
    await tester.tap(find.byType(KitoChatQuotedReply));
    await settle(tester);
    expect(tester.takeException(), isNull);
    c.dispose();
  });

  testWidgets(
      'new incoming messages while scrolled up count on the scroll button',
      (tester) async {
    final msgs = [
      for (var i = 0; i < 40; i++)
        KitoChatMessage.text('Ujumbe $i',
            id: 'x$i',
            author: i.isEven ? amani : me,
            date: now.subtract(Duration(minutes: 60 - i))),
    ];
    final c = KitoChatController(messages: msgs);
    await tester.pumpWidget(host(chat(c)));
    await settle(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
    await settle(tester);
    expect(find.bySemanticsLabel('Scroll to latest'), findsOneWidget);
    c.add(KitoChatMessage.text('Uko wapi?', author: amani));
    await settle(tester);
    expect(find.bySemanticsLabel('Scroll to latest, 1 new'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Scroll to latest, 1 new'));
    await settle(tester);
    expect(find.text('Uko wapi?'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Scroll to latest')), findsNothing);
    c.dispose();
  });

  testWidgets('the unread divider shows and group chats show names',
      (tester) async {
    final msgs = [
      ...history(now),
      KitoChatMessage.text('Mimi niko Kilimani', author: baraka, date: now),
    ];
    final c = KitoChatController(messages: msgs);
    await tester.pumpWidget(host(chat(c, unread: 2)));
    await settle(tester);
    expect(find.text('2 unread messages'), findsOneWidget);
    // The view opens at the divider; the newest message sits below it.
    expect(find.text('Baraka Otieno', skipOffstage: false), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    c.dispose();
  });

  testWidgets('photos open full screen and close', (tester) async {
    final c = KitoChatController(messages: [
      KitoChatMessage(
        id: 'p',
        author: amani,
        content: KitoChatImageContent(KitoChatImage(
            MemoryImage(kTransparentImage),
            aspectRatio: 1,
            caption: 'Diani 🌅')),
      ),
    ]);
    await tester.pumpWidget(host(chat(c)));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Photo: Diani 🌅').first);
    await settle(tester);
    expect(find.byType(KitoChatImageViewer), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close photo'));
    await settle(tester);
    expect(find.byType(KitoChatImageViewer), findsNothing);
    c.dispose();
  });

  group('composer', () {
    testWidgets('mic morphs to send and hold-to-record sends a voice note',
        (tester) async {
      final sent = <KitoChatContent>[];
      await tester.pumpWidget(host(SizedBox(
          width: 390,
          child: KitoChatComposer(onSend: sent.add, onAttach: () {}))));
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Karibu');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 400));

      final mic =
          tester.getCenter(find.bySemanticsLabel('Record voice message'));
      final gesture = await tester.startGesture(mic);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Slide to cancel'), findsOneWidget);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 400));
      final voice = sent.single as KitoChatVoiceContent;
      expect(voice.duration, greaterThan(const Duration(milliseconds: 600)));
      expect(voice.waveform, hasLength(40));
      expect(voice.url, isNull);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a quick tap on the mic shows a hint; sliding cancels',
        (tester) async {
      final sent = <KitoChatContent>[];
      await tester.pumpWidget(host(
          SizedBox(width: 390, child: KitoChatComposer(onSend: sent.add))));
      await tester.tap(find.bySemanticsLabel('Record voice message'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hold to record, release to send'), findsOneWidget);

      final mic =
          tester.getCenter(find.bySemanticsLabel('Record voice message'));
      final gesture = await tester.startGesture(mic);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(seconds: 3));
      expect(sent, isEmpty);
      expect(find.text('Slide to cancel'), findsNothing);
    });

    testWidgets('sliding up locks, then send delivers the recording (RTL)',
        (tester) async {
      final sent = <KitoChatContent>[];
      final phases = <KitoChatRecordingPhase>[];
      await tester.pumpWidget(host(
        SizedBox(
            width: 390,
            child: KitoChatComposer(
                onSend: sent.add, onRecordingChanged: phases.add)),
        direction: TextDirection.rtl,
      ));
      final mic =
          tester.getCenter(find.bySemanticsLabel('Record voice message'));
      final gesture = await tester.startGesture(mic);
      await tester.pump(const Duration(milliseconds: 500));
      // In RTL the leading edge is on the right: moving left must not cancel.
      await gesture.moveBy(const Offset(-130, 0));
      await tester.pump();
      expect(phases.last, KitoChatRecordingPhase.recording);
      await gesture.moveBy(const Offset(130, -100));
      await tester.pump();
      expect(phases.last, KitoChatRecordingPhase.locked);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 800));
      expect(sent, isEmpty);
      expect(find.bySemanticsLabel('Delete recording'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Send'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(sent.single, isA<KitoChatVoiceContent>());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('without a recorder or simulation it explains', (tester) async {
      await tester.pumpWidget(host(SizedBox(
          width: 390,
          child: KitoChatComposer(
              onSend: (_) {}, simulatesRecordingWhenUnavailable: false))));
      final g = await tester.startGesture(
          tester.getCenter(find.bySemanticsLabel('Record voice message')));
      await tester.pump(const Duration(milliseconds: 100));
      await g.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Microphone access is off'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('reply previews show and are localised', (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 390,
          child: KitoChatComposer(
            onSend: (_) {},
            onCancelReply: () {},
            replyTo: const KitoChatReply(
                messageId: 'a', authorName: 'Amani', preview: 'Uko wapi?'),
          ),
        ),
        locale: const Locale('sw'),
      ));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Unamjibu Amani'), findsOneWidget);
      expect(find.text('Ujumbe'), findsOneWidget);
    });
  });

  group('pieces', () {
    testWidgets('voice notes play through, scrub and change speed',
        (tester) async {
      await tester.pumpWidget(host(const KitoChatVoiceNote(
          voice: KitoChatVoiceContent(duration: Duration(seconds: 2)))));
      expect(find.text('0:02'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Play voice message'));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.bySemanticsLabel('Pause voice message'), findsOneWidget);
      expect(find.text('0:01'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Playback speed 1×'));
      await tester.pump();
      expect(find.text('1.5×'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.bySemanticsLabel('Play voice message'), findsOneWidget);
      await tester.tap(find.byType(KitoChatWaveformView));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('0:01'), findsOneWidget);
    });

    testWidgets('a real audio adapter is driven when there is a URL',
        (tester) async {
      final player = _FakePlayer();
      await tester.pumpWidget(host(KitoChatVoiceNote(
        voice: KitoChatVoiceContent(
            duration: const Duration(seconds: 4),
            url: Uri.parse('file:///a.m4a')),
        audioPlayer: () => player,
      )));
      await tester.tap(find.bySemanticsLabel('Play voice message'));
      await tester.pump();
      expect(player.log, ['load file:///a.m4a', 'seek 0', 'speed 1.0', 'play']);
      await tester.tap(find.bySemanticsLabel('Pause voice message'));
      await tester.pump();
      expect(player.log.last, 'pause');
      await tester.pumpWidget(const SizedBox());
      expect(player.log.last, 'dispose');
    });

    testWidgets('ticks, avatars, typing and header announce themselves',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester
          .pumpWidget(host(Column(mainAxisSize: MainAxisSize.min, children: [
        const KitoChatStatusTicks(KitoChatMessageStatus.delivered),
        const KitoChatAvatar(amani),
        const KitoChatTypingIndicator(),
        SizedBox(
            width: 390,
            child: KitoChatHeader(
                user: amani,
                typingUsers: const [baraka],
                onBack: () {},
                onCall: () {})),
      ])));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Delivered'), findsOneWidget);
      expect(find.bySemanticsLabel('Amani Wanjiru, online'), findsWidgets);
      expect(find.bySemanticsLabel('Typing'), findsOneWidget);
      expect(find.text('Baraka is typing…'), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(tester.getSize(find.bySemanticsLabel('Call')).width,
          greaterThanOrEqualTo(44));
      handle.dispose();
    });

    testWidgets('bubble shapes put the tail on the trailing side',
        (tester) async {
      const shape = KitoChatBubbleShape(
          style: KitoChatBubbleStyle.imessage, isOutgoing: true);
      const rect = Rect.fromLTWH(0, 0, 120, 44);
      final ltr = shape
          .getOuterPath(rect, textDirection: TextDirection.ltr)
          .getBounds();
      final rtl = shape
          .getOuterPath(rect, textDirection: TextDirection.rtl)
          .getBounds();
      expect(ltr.right, greaterThan(rect.right));
      expect(rtl.left, lessThan(rect.left));
      const minimal = KitoChatBubbleShape(
          style: KitoChatBubbleStyle.minimal, isOutgoing: true);
      expect(minimal.getOuterPath(rect).getBounds(), rect);
    });
  });

  group('inbox', () {
    List<KitoChatConversation> inbox() => [
          KitoChatConversation(
              id: 'a',
              user: amani,
              unreadCount: 3,
              lastMessage:
                  KitoChatMessage.text('Uko wapi?', author: amani, date: now)),
          KitoChatConversation(
              id: 'b',
              user: baraka,
              isPinned: true,
              isMuted: true,
              lastMessage: KitoChatMessage.text('Nimefika',
                  author: me,
                  status: KitoChatMessageStatus.read,
                  date: now.subtract(const Duration(days: 3)))),
          const KitoChatConversation(
              id: 'c',
              user: KitoChatUser(id: 'g', name: 'Safari Crew'),
              title: 'Safari Crew 🦒',
              isTyping: true),
        ];

    testWidgets('rows read well and pinned rows lead', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(
          SizedBox(
              width: 390,
              height: 600,
              child:
                  KitoChatList(conversations: inbox(), currentUserId: me.id)),
          center: false));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
          find.bySemanticsLabel(
              RegExp(r'^Amani Wanjiru, 3 unread, Uko wapi\?')),
          findsOneWidget);
      expect(
          find.bySemanticsLabel(
              RegExp(r'^Baraka Otieno, pinned, muted, You: Nimefika')),
          findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Safari Crew 🦒, typing')),
          findsOneWidget);
      expect(tester.getTopLeft(find.text('Baraka Otieno')).dy,
          lessThan(tester.getTopLeft(find.text('Amani Wanjiru')).dy));
      handle.dispose();
    });

    for (final dir in TextDirection.values) {
      testWidgets('swipe actions reveal, run and mirror ($dir)',
          (tester) async {
        var list = inbox();
        await tester.pumpWidget(host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 390,
              height: 600,
              child: KitoChatList(
                conversations: list,
                currentUserId: me.id,
                onChanged: (next) => setState(() => list = next),
              ),
            ),
          ),
          direction: dir,
          center: false,
        ));
        final sign = dir == TextDirection.rtl ? -1.0 : 1.0;
        await tester.drag(find.text('Amani Wanjiru'), Offset(100 * sign, 0));
        await settle(tester);
        expect(find.text('Read'), findsOneWidget);
        await tester.tap(find.text('Read'));
        await settle(tester);
        expect(list.firstWhere((c) => c.id == 'a').unreadCount, 0);

        await tester.drag(find.text('Amani Wanjiru'), Offset(-100 * sign, 0));
        await settle(tester);
        await tester.tap(find.text('Mute'));
        await settle(tester);
        expect(list.firstWhere((c) => c.id == 'a').isMuted, isTrue);

        await tester.drag(find.text('Amani Wanjiru'), Offset(-380 * sign, 0));
        await settle(tester);
        expect(list.where((c) => c.id == 'a'), isEmpty);
      });
    }
  });
}

class _FakePlayer implements KitoChatAudioPlayer {
  final log = <String>[];
  @override
  Future<void> load(Uri url) async => log.add('load $url');
  @override
  Future<void> play() async => log.add('play');
  @override
  Future<void> pause() async => log.add('pause');
  @override
  Future<void> seek(Duration position) async =>
      log.add('seek ${position.inSeconds}');
  @override
  Future<void> setSpeed(double rate) async => log.add('speed $rate');
  @override
  Stream<Duration> get positions => const Stream.empty();
  @override
  Stream<void> get completions => const Stream.empty();
  @override
  Future<void> dispose() async => log.add('dispose');
}

/// A 1×1 transparent PNG.
final kTransparentImage = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, //
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);
