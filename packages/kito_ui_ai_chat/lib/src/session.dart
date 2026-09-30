// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'mock_stream.dart';
import 'models.dart';
import 'stream.dart';
import 'text.dart';

/// The state behind a chat: the conversation, the reply being generated, and the actions —
/// send, stop, regenerate, retry, edit-and-resend and feedback. [KitoAiChatView] is a pure
/// function of it, so you can drive it from your own UI or tests too.
///
/// ```dart
/// final session = KitoAiChatSession(stream: MyBackend());
///
/// KitoAiChatView(session: session);
/// session.send('Plan a weekend in Diani');
/// session.stop();
/// session.regenerate();
/// ```
///
/// Dispose it when you're done; that cancels a reply in progress.
class KitoAiChatSession extends ChangeNotifier {
  /// Creates a session; [stream] defaults to a [KitoAiMockStream].
  KitoAiChatSession({
    KitoAiConversation? conversation,
    KitoAiStream? stream,
    this.suggestions = KitoAiSuggestion.defaults,
    this.onReplyFinished,
    this.onFeedback,
  })  : _conversation = conversation ?? KitoAiConversation(),
        stream = stream ?? KitoAiMockStream();

  KitoAiConversation _conversation;
  List<KitoAiAttachment> _attachments = const [];
  String? _editingId;
  StreamSubscription<KitoAiStreamEvent>? _subscription;
  int _generation = 0;
  int _revision = 0;
  bool _disposed = false;

  /// Where replies come from. Swap it (for a different model) between replies.
  KitoAiStream stream;

  /// Starter prompts shown while the conversation is empty.
  List<KitoAiSuggestion> suggestions;

  /// Called with each finished (or failed, or stopped) reply — save the conversation here.
  ValueChanged<KitoAiMessage>? onReplyFinished;

  /// Called when a reply gets thumbs up or down (or the rating is cleared).
  void Function(KitoAiMessage message, KitoAiFeedback feedback)? onFeedback;

  /// The conversation so far.
  KitoAiConversation get conversation => _conversation;

  /// Its messages.
  List<KitoAiMessage> get messages => _conversation.messages;

  /// Files waiting in the composer; sent with the next message.
  List<KitoAiAttachment> get attachments => _attachments;
  set attachments(List<KitoAiAttachment> value) {
    _attachments = List.unmodifiable(value);
    _changed();
  }

  /// Adds a file to the next message.
  void attach(KitoAiAttachment attachment) =>
      attachments = [..._attachments, attachment];

  /// Removes a waiting file.
  void removeAttachment(String id) =>
      attachments = [..._attachments.where((a) => a.id != id)];

  /// The id of the user message being edited, if any.
  String? get editingMessageId => _editingId;

  /// Bumped on every visible change — handy for following streaming text.
  int get revision => _revision;

  /// True while a reply is streaming.
  bool get isGenerating => messages.isNotEmpty && messages.last.isStreaming;

  /// The latest reply's follow-ups, once it has finished without error.
  List<String> get followUps {
    if (messages.isEmpty) return const [];
    final last = messages.last;
    if (last.role != KitoAiRole.assistant ||
        last.isStreaming ||
        last.errorMessage != null) {
      return const [];
    }
    return last.followUps;
  }

  /// The last user message, which is the one that can be edited.
  String? get editableMessageId =>
      isGenerating ? null : _conversation.lastUserMessage?.id;

  // MARK: Actions

  /// Sends a message (with the waiting attachments) and starts a reply. When editing, replaces
  /// the edited message and everything after it instead.
  void send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && _attachments.isEmpty) return;
    _stopQuietly();
    final editing = _editingId;
    final index = editing == null ? -1 : _conversation.indexOf(editing);
    if (index >= 0) {
      final list = [..._conversation.messages.sublist(0, index + 1)];
      list[index] = list[index].copyWith(
          blocks: [KitoAiMarkdownContent(trimmed)], date: DateTime.now());
      _conversation = _conversation.copyWith(messages: list);
      _editingId = null;
    } else {
      _conversation = _conversation.copyWith(messages: [
        ..._conversation.messages,
        KitoAiMessage.user(trimmed, attachments: _attachments),
      ]);
      _attachments = const [];
    }
    if (_conversation.title == null &&
        _conversation.messages.where((m) => m.role == KitoAiRole.user).length ==
            1) {
      _conversation = _conversation.copyWith(title: KitoAiTitle.make(trimmed));
    }
    _generate();
  }

  /// Stops the reply in progress, keeping what has arrived.
  void stop() {
    if (!isGenerating) return;
    _stopQuietly();
    _changed();
  }

  void _stopQuietly() {
    if (!isGenerating) return;
    _subscription?.cancel();
    _subscription = null;
    _generation++;
    _finishLast((m) => m.copyWith(wasStopped: true));
  }

  /// Replaces the latest reply with a new one.
  void regenerate() {
    _stopQuietly();
    if (messages.isEmpty || messages.last.role != KitoAiRole.assistant) {
      _changed();
      return;
    }
    _conversation = _conversation.copyWith(
        messages: messages.sublist(0, messages.length - 1));
    _generate();
  }

  /// Tries a failed reply again.
  void retry() => regenerate();

  /// Starts editing the last user message and returns its text for the composer.
  String? beginEditing() {
    final id = editableMessageId;
    if (id == null) return null;
    _editingId = id;
    _changed();
    return messages[_conversation.indexOf(id)].text;
  }

  /// Stops editing without changing anything.
  void cancelEditing() {
    if (_editingId == null) return;
    _editingId = null;
    _changed();
  }

  /// Thumbs up or down; the same again clears it.
  void setFeedback(KitoAiFeedback feedback, String messageId) {
    final index = _conversation.indexOf(messageId);
    if (index < 0) return;
    final current = messages[index].feedback;
    final next = current == feedback ? KitoAiFeedback.none : feedback;
    final list = [...messages];
    list[index] = list[index].copyWith(feedback: next);
    _conversation = _conversation.copyWith(messages: list);
    _changed();
    onFeedback?.call(list[index], next);
  }

  /// Starts a fresh conversation (or opens [conversation]).
  void reset([KitoAiConversation? conversation]) {
    _subscription?.cancel();
    _subscription = null;
    _generation++;
    _editingId = null;
    _attachments = const [];
    _conversation = conversation ?? KitoAiConversation();
    _changed();
  }

  /// Sets the conversation's model badge.
  void setModel(String? model) {
    _conversation = _conversation.copyWith(model: model);
    _changed();
  }

  // MARK: Streaming

  void _generate() {
    final current = ++_generation;
    final request = _conversation;
    _conversation = _conversation.copyWith(
      messages: [
        ..._conversation.messages,
        KitoAiMessage(role: KitoAiRole.assistant, isStreaming: true),
      ],
      updatedAt: DateTime.now(),
    );
    _changed();
    Stream<KitoAiStreamEvent> events;
    try {
      events = stream.reply(request);
    } catch (error) {
      _complete(current, error);
      return;
    }
    _subscription = events.listen(
      (event) {
        if (_generation != current) return;
        _applyToLast(event);
      },
      onError: (Object error) => _complete(current, error),
      onDone: () => _complete(current, null),
      cancelOnError: true,
    );
  }

  void _applyToLast(KitoAiStreamEvent event) {
    if (messages.isEmpty || !messages.last.isStreaming) return;
    final list = [...messages];
    list[list.length - 1] = list.last.applying(event);
    _conversation = _conversation.copyWith(messages: list);
    _changed();
  }

  void _complete(int generation, Object? error) {
    if (generation != _generation || _disposed) return;
    _subscription = null;
    _finishLast((m) => error == null
        ? m
        : m.copyWith(
            errorMessage: error is KitoAiStreamError
                ? error.message
                : 'Something went wrong. Please try again.'));
    _changed();
  }

  void _finishLast(KitoAiMessage Function(KitoAiMessage) update) {
    if (messages.isEmpty || !messages.last.isStreaming) return;
    final last = messages.last;
    final blocks = [
      for (final b in last.blocks)
        if (b is KitoAiToolCallContent &&
            b.call.status == KitoAiToolStatus.running)
          KitoAiToolCallContent(b.call.withStatus(KitoAiToolStatus.failed))
        else
          b,
    ];
    final finished = update(last.copyWith(isStreaming: false, blocks: blocks));
    _conversation = _conversation.copyWith(
      messages: [...messages.sublist(0, messages.length - 1), finished],
      updatedAt: DateTime.now(),
    );
    onReplyFinished?.call(finished);
  }

  void _changed() {
    if (_disposed) return;
    _revision++;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
