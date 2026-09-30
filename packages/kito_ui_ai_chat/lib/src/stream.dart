// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Something that happens while a reply streams in.
@immutable
sealed class KitoAiStreamEvent {
  const KitoAiStreamEvent();

  /// More text. Tokens are appended as they arrive; any size works, from a character to a
  /// paragraph.
  const factory KitoAiStreamEvent.token(String text) = KitoAiTokenEvent;

  /// A tool call started or changed. Send the same id again with [KitoAiToolStatus.done] to
  /// finish it.
  const factory KitoAiStreamEvent.toolCall(KitoAiToolCall call) =
      KitoAiToolCallEvent;

  /// Sources for the answer.
  const factory KitoAiStreamEvent.citations(List<KitoAiCitation> citations) =
      KitoAiCitationsEvent;

  /// A picture.
  const factory KitoAiStreamEvent.image(KitoAiImage image) = KitoAiImageEvent;

  /// Suggested next prompts, shown as chips once the reply finishes.
  const factory KitoAiStreamEvent.followUps(List<String> suggestions) =
      KitoAiFollowUpsEvent;
}

/// More reply text.
final class KitoAiTokenEvent extends KitoAiStreamEvent {
  /// Wraps [text].
  const KitoAiTokenEvent(this.text);

  /// The new text.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is KitoAiTokenEvent && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'token(${text.length} chars)';
}

/// A tool call started or changed.
final class KitoAiToolCallEvent extends KitoAiStreamEvent {
  /// Wraps [call].
  const KitoAiToolCallEvent(this.call);

  /// The call, identified by its id.
  final KitoAiToolCall call;

  @override
  bool operator ==(Object other) =>
      other is KitoAiToolCallEvent && other.call == call;

  @override
  int get hashCode => call.hashCode;
}

/// Sources for the answer.
final class KitoAiCitationsEvent extends KitoAiStreamEvent {
  /// Wraps [citations].
  const KitoAiCitationsEvent(this.citations);

  /// The new sources; ones already shown (by id) are skipped.
  final List<KitoAiCitation> citations;
}

/// A picture in the reply.
final class KitoAiImageEvent extends KitoAiStreamEvent {
  /// Wraps [image].
  const KitoAiImageEvent(this.image);

  /// The picture.
  final KitoAiImage image;
}

/// Suggested next prompts.
final class KitoAiFollowUpsEvent extends KitoAiStreamEvent {
  /// Wraps [suggestions].
  const KitoAiFollowUpsEvent(this.suggestions);

  /// The prompts.
  final List<String> suggestions;
}

/// Where replies come from. Wrap your provider's streaming API — the kit has no network code of
/// its own, so any model, any SDK and any transport works.
///
/// ```dart
/// class MyBackend implements KitoAiStream {
///   @override
///   Stream<KitoAiStreamEvent> reply(KitoAiConversation conversation) async* {
///     await for (final chunk in api.stream(conversation.messages)) {
///       yield KitoAiStreamEvent.token(chunk.text);
///     }
///     yield const KitoAiStreamEvent.followUps(['Tell me more']);
///   }
/// }
/// ```
///
/// Stopping a reply cancels the subscription, so stop work when the stream is cancelled. Errors
/// end the reply with an error bubble; throw a [KitoAiStreamError] for a friendly message.
abstract interface class KitoAiStream {
  /// Streams the reply to the last message of [conversation].
  Stream<KitoAiStreamEvent> reply(KitoAiConversation conversation);
}

/// Adapts any `Stream<String>` of text chunks into a [KitoAiStream].
///
/// ```dart
/// final stream = KitoAiTokenStream((conversation) => client.streamText(conversation.messages));
/// ```
class KitoAiTokenStream implements KitoAiStream {
  /// Wraps a function returning a stream of text chunks.
  const KitoAiTokenStream(this.tokens);

  /// Makes the text stream for a conversation.
  final Stream<String> Function(KitoAiConversation conversation) tokens;

  @override
  Stream<KitoAiStreamEvent> reply(KitoAiConversation conversation) =>
      tokens(conversation).map(KitoAiTokenEvent.new);
}

/// An error a stream can throw to show a friendly message in the error bubble.
@immutable
class KitoAiStreamError implements Exception {
  /// Creates an error with a message for people.
  const KitoAiStreamError(this.message);

  /// Shown in the error bubble.
  final String message;

  /// "The connection was lost before the reply finished."
  static const networkLost =
      KitoAiStreamError('The connection was lost before the reply finished.');

  @override
  bool operator ==(Object other) =>
      other is KitoAiStreamError && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => message;
}
