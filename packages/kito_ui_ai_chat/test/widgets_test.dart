// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_ai_chat/kito_ui_ai_chat.dart';

import 'helpers.dart';

Widget _page(Widget child,
        {TextDirection direction = TextDirection.ltr,
        bool reduceMotion = false}) =>
    testApp(Scaffold(body: SafeArea(child: child)),
        direction: direction, reduceMotion: reduceMotion);

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        _clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  for (final direction in TextDirection.values) {
    testWidgets('a whole chat, ${direction.name}', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final session =
          KitoAiChatSession(stream: KitoAiMockStream(instant: true));
      addTearDown(session.dispose);
      await tester.pumpWidget(_page(
          KitoAiChatView(
            session: session,
            userName: 'Wycliff N',
            accessory: KitoAiModelPicker(selected: 'pro', onChanged: (_) {}),
            onAttach: () {},
          ),
          direction: direction));
      await _settle(tester);
      expect(find.textContaining('Wycliff'), findsOneWidget);
      expect(find.text('Plan a weekend'), findsOneWidget);
      expect(find.text('Kito Pro'), findsOneWidget);

      await tester.tap(find.text('Compare the SGR'));
      await tester.pump();
      expect(
          find.text('Compare the SGR and a matatu to Mombasa'), findsOneWidget);
      await _settle(tester, 20);
      expect(session.isGenerating, isFalse);
      expect(
          find.textContaining('My pick:', findRichText: true), findsOneWidget);
      expect(
          find.text('Checked schedules and fares · 2 sources',
              findRichText: true),
          findsOneWidget);
      expect(find.bySemanticsLabel('Regenerate'), findsOneWidget);
      expect(find.text('What about flying?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('send, stop and edit from the composer', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = KitoAiChatSession(stream: KitoAiMockStream(seed: 2));
    addTearDown(session.dispose);
    await tester.pumpWidget(_page(KitoAiChatView(session: session)));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'Chapati recipe please');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump();
    expect(session.isGenerating, isTrue);
    expect(find.text('Thinking…'), findsOneWidget);
    expect(find.bySemanticsLabel('Stop generating'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.bySemanticsLabel('Stop generating'));
    await tester.pump();
    expect(session.isGenerating, isFalse);
    expect(find.text('Stopped'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Edit message'));
    await _settle(tester);
    expect(find.text('Editing your message'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Chapati recipe please'),
        findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Cancel editing'));
    await _settle(tester);
    expect(find.text('Editing your message'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a failed reply shows Retry', (tester) async {
    final session =
        KitoAiChatSession(stream: KitoAiMockStream(instant: true, failures: 1));
    addTearDown(session.dispose);
    await tester.pumpWidget(_page(KitoAiChatView(session: session)));
    session.send('chapati');
    await _settle(tester);
    expect(find.text(KitoAiStreamError.networkLost.message), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Retry'));
    await _settle(tester);
    expect(find.text(KitoAiStreamError.networkLost.message), findsNothing);
    expect(find.textContaining('layered chapati', findRichText: true),
        findsOneWidget);
  });

  testWidgets('streaming markdown from a Stream<String>', (tester) async {
    final tokens = StreamController<String>();
    String? done;
    await tester.pumpWidget(_page(KitoAiStreamingMarkdown(
        stream: tokens.stream, onDone: (t) => done = t)));
    await tester.pump();
    expect(find.text('Thinking…'), findsOneWidget);
    tokens.add('## Karibu\nTake the **SG');
    await _settle(tester, 4);
    expect(find.text('Karibu', findRichText: true), findsOneWidget);
    expect(find.byType(KitoAiStreamingCursor), findsOneWidget);
    tokens.add('R**');
    await tokens.close();
    await _settle(tester, 4);
    expect(done, '## Karibu\nTake the **SGR**');
    expect(find.byType(KitoAiStreamingCursor), findsNothing);
  });

  testWidgets('markdown renders lists, quotes, tables and code with Copy',
      (tester) async {
    await tester.pumpWidget(_page(SingleChildScrollView(
      child: KitoAiMarkdownView(
          '${KitoAiMockStream.diani.text}\n\n```dart\nfinal fare = 1500;\n```\n\n- [x] Book SGR\n- [ ] Pack'),
    )));
    await tester.pump();
    expect(find.text('A relaxed weekend in Diani 🌴', findRichText: true),
        findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Estimate (KES)', findRichText: true), findsOneWidget);
    expect(find.byType(KitoAiCodeBlock), findsOneWidget);
    expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);

    await tester.ensureVisible(find.bySemanticsLabel('Copy code'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Copy code'));
    await tester.pump();
    expect(_clipboard, 'final fare = 1500;');
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('links call back', (tester) async {
    String? tapped;
    await tester.pumpWidget(_page(KitoAiMarkdownView(
        'Book at [Kenya Railways](https://metickets.krc.co.ke).',
        onLinkTap: (u) => tapped = u)));
    await tester.tapOnText(find.textRange.ofSubstring('Kenya Railways'));
    expect(tapped, 'https://metickets.krc.co.ke');
  });

  testWidgets('message views: user, assistant actions, system and tool',
      (tester) async {
    final feedback = <KitoAiFeedback>[];
    var regenerated = 0;
    await tester.pumpWidget(_page(ListView(children: [
      KitoAiMessageView(
          message: KitoAiMessage.user('Plan a weekend', attachments: [
            KitoAiAttachment(
                name: 'Budget.xlsx',
                kind: KitoAiAttachmentKind.spreadsheet,
                byteCount: 12000),
          ]),
          onEdit: () {}),
      KitoAiMessageView(
        message: KitoAiMessage.assistant('Karibu **Diani**'),
        onFeedback: feedback.add,
        onRegenerate: () => regenerated++,
      ),
      KitoAiMessageView(message: KitoAiMessage.system('Switched to Kito Pro')),
      KitoAiMessageView(
          message: KitoAiMessage.text(KitoAiRole.tool, '{"fare": 1500}')),
    ])));
    await _settle(tester);
    expect(find.text('Budget.xlsx'), findsOneWidget);
    expect(find.text('Spreadsheet · 12 KB'), findsOneWidget);
    expect(find.text('Switched to Kito Pro'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Good response'));
    await tester.tap(find.bySemanticsLabel('Regenerate'));
    expect(feedback, [KitoAiFeedback.positive]);
    expect(regenerated, 1);

    await tester.tap(find.bySemanticsLabel('Copy').last);
    await tester.pump();
    expect(_clipboard, 'Karibu **Diani**');

    await tester.tap(find.bySemanticsLabel('Show tool result'));
    await _settle(tester);
    expect(find.text('{"fare": 1500}', findRichText: true), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('composer chips, attachments and token estimate', (tester) async {
    final sent = <String>[];
    final removed = <String>[];
    final file =
        KitoAiAttachment(name: 'Itinerary.pdf', kind: KitoAiAttachmentKind.pdf);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_page(Align(
      alignment: Alignment.bottomCenter,
      child: KitoAiComposer(
        controller: controller,
        onSend: sent.add,
        suggestions: const ['Plan a weekend in Diani'],
        attachments: [file],
        onRemoveAttachment: (a) => removed.add(a.name),
        tokenEstimateThreshold: 20,
      ),
    )));
    await _settle(tester);
    await tester.tap(find.text('Plan a weekend in Diani'));
    expect(sent, ['Plan a weekend in Diani']);

    await tester.tap(find.bySemanticsLabel('Remove Itinerary.pdf'));
    expect(removed, ['Itinerary.pdf']);

    await tester.enterText(find.byType(TextField),
        'Please plan a long weekend in Diani for four people');
    await tester.pump();
    expect(find.textContaining('tokens'), findsOneWidget);
    expect(find.text('Plan a weekend in Diani'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Send'));
    expect(sent.last, 'Please plan a long weekend in Diani for four people');
    expect(controller.text, isEmpty);
  });

  testWidgets('model picker opens a sheet and reports the pick',
      (tester) async {
    String? picked;
    await tester.pumpWidget(_page(Center(
        child: KitoAiModelPicker(
            selected: 'fast', onChanged: (id) => picked = id))));
    expect(find.text('Kito Fast'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Model, Kito Fast'));
    await _settle(tester);
    expect(find.text('Runs on this device'), findsOneWidget);
    await tester.tap(find.text('Kito Local'));
    await _settle(tester);
    expect(picked, 'local');
  });

  testWidgets('conversation list groups, searches, pins and deletes',
      (tester) async {
    final now = DateTime(2026, 9, 30, 15);
    final chats = [
      KitoAiConversation(
          id: 'a',
          title: 'Diani weekend',
          model: 'Pro',
          messages: [KitoAiMessage.assistant('Take the SGR on Friday')],
          updatedAt: DateTime(2026, 9, 30, 9, 5)),
      KitoAiConversation(
          id: 'b', title: 'Chapati', updatedAt: DateTime(2026, 9, 29, 20)),
      KitoAiConversation(
          id: 'c',
          title: 'M-Pesa callback',
          isPinned: true,
          updatedAt: DateTime(2026, 8, 3)),
    ];
    KitoAiConversation? opened;
    final pinned = <String>[];
    final deleted = <String>[];
    var newChats = 0;
    await tester.pumpWidget(_page(KitoAiConversationList(
      conversations: chats,
      selectedId: 'a',
      now: now,
      onSelect: (c) => opened = c,
      onNewChat: () => newChats++,
      onTogglePin: (c) => pinned.add(c.id),
      onDelete: (c) => deleted.add(c.id),
    )));
    await tester.pump();
    expect(find.text('Pinned'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsNWidgets(2));
    expect(find.text('09:05'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);

    await tester.tap(find.text('Chapati'));
    expect(opened?.id, 'b');
    await tester.tap(find.bySemanticsLabel('New chat'));
    expect(newChats, 1);

    await tester.longPress(find.text('Diani weekend'));
    await _settle(tester);
    await tester.tap(find.text('Pin'));
    await _settle(tester);
    expect(pinned, ['a']);

    await tester.longPress(find.text('Chapati'));
    await _settle(tester);
    await tester.tap(find.text('Delete'));
    await _settle(tester);
    expect(deleted, ['b']);

    await tester.enterText(find.byType(TextField), 'sgr');
    await tester.pump();
    expect(find.text('Diani weekend'), findsOneWidget);
    expect(find.text('Chapati'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await _settle(tester);
    expect(find.text('No chats match “zzz”'), findsOneWidget);
  });

  testWidgets('pieces build in RTL with reduced motion', (tester) async {
    await tester.pumpWidget(_page(
      SingleChildScrollView(
        child: Column(children: [
          const KitoAiOrb(),
          const KitoAiThinkingIndicator(),
          const KitoAiWelcome(name: 'Amina Wanjiru'),
          KitoAiToolChip(call: KitoAiToolCall.webSearch()),
          KitoAiCitationChips(citations: [
            KitoAiCitation(title: 'KWS', url: 'https://www.kws.go.ke'),
          ]),
          KitoAiFollowUpChips(
              suggestions: const ['Pole pole'], onSelect: (_) {}),
          KitoAiSuggestedPrompts(onSelect: (_) {}),
          const KitoAiErrorBubble(message: 'Hakuna mtandao'),
        ]),
      ),
      direction: TextDirection.rtl,
      reduceMotion: true,
    ));
    await tester.pumpAndSettle();
    expect(find.text('kws.go.ke'), findsOneWidget);
    expect(
        find.text('Good ${KitoAiGreeting.period(DateTime.now()).name}, Amina'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String? _clipboard;
