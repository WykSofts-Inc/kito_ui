// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Holds a conversation's messages and who's typing. `KitoChatView` listens to it and edits it —
/// sending appends a `sending` message, reactions and deletes update it — and you move statuses
/// on as your backend confirms them.
///
/// ```dart
/// final chat = KitoChatController(messages: history);
/// chat.add(KitoChatMessage.text('Niko njiani 🚗', author: amani));
/// chat.updateStatus(id, KitoChatMessageStatus.read);
/// ```
class KitoChatController extends ChangeNotifier {
  /// Creates a controller, oldest message first.
  KitoChatController({
    List<KitoChatMessage> messages = const [],
    List<KitoChatUser> typingUsers = const [],
  })  : _messages = List.of(messages),
        _typing = List.of(typingUsers);

  final List<KitoChatMessage> _messages;
  List<KitoChatUser> _typing;

  /// The messages, oldest first.
  List<KitoChatMessage> get messages => List.unmodifiable(_messages);

  /// Who's typing now.
  List<KitoChatUser> get typingUsers => List.unmodifiable(_typing);

  set typingUsers(List<KitoChatUser> users) {
    if (listEquals(users, _typing)) return;
    _typing = List.of(users);
    notifyListeners();
  }

  /// The message with [id], if it's here.
  KitoChatMessage? byId(String id) {
    for (final m in _messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Appends [message].
  void add(KitoChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Appends [messages].
  void addAll(Iterable<KitoChatMessage> messages) {
    _messages.addAll(messages);
    notifyListeners();
  }

  /// Puts [messages] before the current ones — older history loaded on scroll.
  void prepend(Iterable<KitoChatMessage> messages) {
    _messages.insertAll(0, messages);
    notifyListeners();
  }

  /// Replaces everything.
  void replaceAll(Iterable<KitoChatMessage> messages) {
    _messages
      ..clear()
      ..addAll(messages);
    notifyListeners();
  }

  /// Moves the message with [id] to [status], if that transition is allowed. Returns whether it
  /// changed.
  bool updateStatus(String id, KitoChatMessageStatus status) {
    final changed = _messages.kitoUpdateStatus(id, status);
    if (changed) notifyListeners();
    return changed;
  }

  /// Replaces the message with [id] by `change(message)`.
  void update(String id, KitoChatMessage Function(KitoChatMessage) change) {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i < 0) return;
    _messages[i] = change(_messages[i]);
    notifyListeners();
  }

  /// [emoji] from [userId] on message [id]; the same emoji again removes it.
  void toggleReaction(String id, String emoji, String userId) =>
      update(id, (m) => m.toggledReaction(emoji, userId));

  /// Removes the message with [id].
  void remove(String id) {
    final before = _messages.length;
    _messages.removeWhere((m) => m.id == id);
    if (_messages.length != before) notifyListeners();
  }
}
