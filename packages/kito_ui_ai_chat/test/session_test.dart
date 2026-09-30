// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_ai_chat/kito_ui_ai_chat.dart';

Future<void> _flush() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A stream the test drives by hand.
class _Manual implements KitoAiStream {
  StreamController<KitoAiStreamEvent>? controller;
  int cancelled = 0;
  int requests = 0;

  @override
  Stream<KitoAiStreamEvent> reply(KitoAiConversation conversation) {
    requests++;
    controller =
        StreamController<KitoAiStreamEvent>(onCancel: () => cancelled++);
    return controller!.stream;
  }
}

void main() {
  test('send streams a reply, titles the chat and reports when it finishes',
      () async {
    final finished = <KitoAiMessage>[];
    final session = KitoAiChatSession(
      stream: KitoAiMockStream(instant: true),
      onReplyFinished: finished.add,
    );
    var notifications = 0;
    session.addListener(() => notifications++);

    session.send('Hey, can you help me plan a weekend in Diani?');
    expect(session.isGenerating, isTrue);
    expect(session.messages.length, 2);
    expect(session.conversation.title, 'Plan a weekend in Diani');
    await _flush();

    expect(session.isGenerating, isFalse);
    final reply = session.messages.last;
    expect(reply.text, KitoAiMockStream.diani.text);
    expect(reply.toolCalls.single.status, KitoAiToolStatus.done);
    expect(reply.citations.length, 4);
    expect(session.followUps, KitoAiMockStream.diani.followUps);
    expect(finished.single.id, reply.id);
    expect(notifications, greaterThan(10));
    expect(session.revision, notifications);
    session.dispose();
  });

  test('blank sends are ignored; attachments alone can be sent', () {
    final session = KitoAiChatSession(stream: _Manual());
    session.send('   ');
    expect(session.messages, isEmpty);
    session.attach(
        KitoAiAttachment(name: 'Menu.pdf', kind: KitoAiAttachmentKind.pdf));
    session.send('');
    expect(session.messages.first.attachments.single.name, 'Menu.pdf');
    expect(session.attachments, isEmpty);
    session.dispose();
  });

  test('stop keeps what arrived, fails running tools and cancels the stream',
      () {
    final manual = _Manual();
    final session = KitoAiChatSession(stream: manual);
    session.send('Diani');
    manual.controller!
      ..add(KitoAiStreamEvent.toolCall(KitoAiToolCall.webSearch(id: 't')))
      ..add(const KitoAiStreamEvent.token('Half a '));
    return Future<void>(() async {
      await _flush();
      session.stop();
      final last = session.messages.last;
      expect(last.isStreaming, isFalse);
      expect(last.wasStopped, isTrue);
      expect(last.text, 'Half a ');
      expect(last.toolCalls.single.status, KitoAiToolStatus.failed);
      expect(manual.cancelled, 1);
      expect(session.editableMessageId, session.messages.first.id);
      session.dispose();
    });
  });

  test('errors show a message; retry replaces the reply', () async {
    final manual = _Manual();
    final session = KitoAiChatSession(stream: manual);
    session.send('SGR');
    manual.controller!
      ..add(const KitoAiStreamEvent.token('The SGR'))
      ..addError(KitoAiStreamError.networkLost);
    await _flush();
    expect(session.messages.last.errorMessage,
        KitoAiStreamError.networkLost.message);
    expect(session.followUps, isEmpty);

    manual.controller!.close();
    session.retry();
    expect(manual.requests, 2);
    expect(session.messages.length, 2);
    manual.controller!
      ..add(const KitoAiStreamEvent.token('Fine'))
      ..close();
    await _flush();
    expect(session.messages.last.text, 'Fine');
    expect(session.messages.last.errorMessage, isNull);

    manual.controller = null;
    final other = KitoAiChatSession(stream: _ThrowingStream());
    other.send('x');
    await _flush();
    expect(other.messages.last.errorMessage,
        'Something went wrong. Please try again.');
    other.dispose();
    session.dispose();
  });

  test('edit and resend replaces the message and what followed it', () async {
    final session = KitoAiChatSession(stream: KitoAiMockStream(instant: true));
    session.send('chapati recipe');
    await _flush();
    session.send('landlord email');
    await _flush();
    expect(session.messages.length, 4);

    expect(session.beginEditing(), 'landlord email');
    expect(session.editingMessageId, session.messages[2].id);
    session.send('Teach me Swahili phrases');
    expect(session.editingMessageId, isNull);
    await _flush();
    expect(session.messages.length, 4);
    expect(session.messages[2].text, 'Teach me Swahili phrases');
    expect(session.messages[3].text, KitoAiMockStream.swahili.text);

    session.beginEditing();
    session.cancelEditing();
    expect(session.editingMessageId, isNull);
    session.dispose();
  });

  test('feedback toggles and is reported', () async {
    final reports = <KitoAiFeedback>[];
    final session = KitoAiChatSession(
        stream: KitoAiMockStream(instant: true),
        onFeedback: (_, f) => reports.add(f));
    session.send('sgr');
    await _flush();
    final id = session.messages.last.id;
    session.setFeedback(KitoAiFeedback.positive, id);
    expect(session.messages.last.feedback, KitoAiFeedback.positive);
    session.setFeedback(KitoAiFeedback.positive, id);
    expect(session.messages.last.feedback, KitoAiFeedback.none);
    session.setFeedback(KitoAiFeedback.negative, id);
    expect(reports, [
      KitoAiFeedback.positive,
      KitoAiFeedback.none,
      KitoAiFeedback.negative
    ]);
    session.dispose();
  });

  test('regenerate asks again; reset and dispose cancel a reply in progress',
      () async {
    final manual = _Manual();
    final session = KitoAiChatSession(stream: manual);
    session.send('hi');
    manual.controller!.add(const KitoAiStreamEvent.token('One'));
    await _flush();
    session.regenerate();
    expect(manual.cancelled, 1);
    expect(manual.requests, 2);
    expect(session.messages.length, 2);
    expect(session.messages.last.isStreaming, isTrue);

    session.reset();
    expect(manual.cancelled, 2);
    expect(session.messages, isEmpty);

    session.send('again');
    session.setModel('Kito Pro');
    expect(session.conversation.model, 'Kito Pro');
    session.dispose();
    expect(manual.cancelled, 3);
  });

  testWidgets('the timed mock streams with fake time and leaves no timers',
      (tester) async {
    final session = KitoAiChatSession(stream: KitoAiMockStream(seed: 3));
    session.send('Swahili phrases please');
    await tester.pump(const Duration(milliseconds: 500));
    expect(session.messages.last.hasVisibleContent, isFalse);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(session.messages.last.text, isNotEmpty);
    expect(session.isGenerating, isTrue);
    session.stop();
    expect(session.messages.last.wasStopped, isTrue);

    session.send('SGR');
    await tester.pump(const Duration(seconds: 1));
    session.dispose();
  });

  testWidgets('a whole timed reply finishes', (tester) async {
    final session =
        KitoAiChatSession(stream: KitoAiMockStream(seed: 1, speed: 20));
    session.send('landlord');
    for (var i = 0; i < 200 && session.isGenerating; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(session.isGenerating, isFalse);
    expect(session.messages.last.text, KitoAiMockStream.landlord.text);
    session.dispose();
  });
}

class _ThrowingStream implements KitoAiStream {
  @override
  Stream<KitoAiStreamEvent> reply(KitoAiConversation conversation) =>
      Stream.error(StateError('boom'));
}
