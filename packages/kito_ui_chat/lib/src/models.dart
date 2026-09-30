// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_formatting/kito_ui_formatting.dart';

import 'strings.dart';

// MARK: - User

/// Someone taking part in a conversation.
@immutable
class KitoChatUser {
  /// Creates a user.
  const KitoChatUser({
    required this.id,
    required this.name,
    this.avatar,
    this.color,
    this.isOnline = false,
  });

  /// A stable identifier.
  final String id;

  /// The display name.
  final String name;

  /// A photo; initials on a gradient are shown while it loads or when there's none.
  final ImageProvider? avatar;

  /// Overrides the avatar gradient and the author-name colour in group chats.
  final Color? color;

  /// Shows a green dot on the avatar.
  final bool isOnline;

  /// Up to two initials: "Amani Wanjiru" → "AW", "Baraka" → "B".
  String get initials {
    final letters = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  /// The first word of the name: "Amani Wanjiru" → "Amani".
  String get firstName {
    final words = name.trim().split(RegExp(r'\s+'));
    return words.isEmpty || words.first.isEmpty ? name : words.first;
  }

  /// A stable index into a palette of [count] colours, the same on every launch.
  int paletteIndex(int count) {
    if (count <= 0) return 0;
    var hash = 5381;
    for (final unit in id.codeUnits) {
      hash = ((hash * 33) + unit) & 0x7FFFFFFF;
    }
    return hash % count;
  }

  /// A copy with some fields replaced.
  KitoChatUser copyWith({
    String? name,
    ImageProvider? avatar,
    Color? color,
    bool? isOnline,
  }) =>
      KitoChatUser(
        id: id,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        color: color ?? this.color,
        isOnline: isOnline ?? this.isOnline,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoChatUser &&
      other.id == id &&
      other.name == name &&
      other.avatar == avatar &&
      other.color == color &&
      other.isOnline == isOnline;

  @override
  int get hashCode => Object.hash(id, name, avatar, color, isOnline);
}

// MARK: - Status

/// Where an outgoing message is on its way to the recipient.
///
/// Statuses only move forward — `sending → sent → delivered → read` — except that a
/// `sending` message can fail and a failed one can be retried (back to `sending`).
enum KitoChatMessageStatus {
  /// On its way to the server.
  sending,

  /// The server has it.
  sent,

  /// On the recipient's device.
  delivered,

  /// Seen.
  read,

  /// Couldn't be sent.
  failed;

  int get _rank => switch (this) {
        sending || failed => 0,
        sent => 1,
        delivered => 2,
        read => 3,
      };

  /// Whether moving from this status to [next] is allowed.
  bool canTransitionTo(KitoChatMessageStatus next) {
    if (this == sending && next == failed) return true;
    if (this == failed && next == sending) return true;
    if (this == failed || next == failed) return false;
    return next._rank > _rank;
  }

  /// [next] if the move is allowed, otherwise this status unchanged.
  KitoChatMessageStatus transitionedTo(KitoChatMessageStatus next) =>
      canTransitionTo(next) ? next : this;

  /// The following step on the happy path, or null once read (or failed).
  KitoChatMessageStatus? get next => switch (this) {
        sending => sent,
        sent => delivered,
        delivered => read,
        read || failed => null,
      };

  /// What screen readers say: "Sending", "Sent", "Delivered", "Read", "Not delivered".
  String label([Locale locale = const Locale('en')]) =>
      KitoChatStrings.lookup(name, locale);
}

// MARK: - Reactions and replies

/// One emoji and everyone who reacted with it.
@immutable
class KitoChatReaction {
  /// Creates a reaction.
  const KitoChatReaction(this.emoji, {this.userIds = const []});

  /// The emoji.
  final String emoji;

  /// Who reacted with it.
  final List<String> userIds;

  /// How many people reacted with it.
  int get count => userIds.length;

  /// Whether [userId] reacted with it.
  bool includes(String userId) => userIds.contains(userId);

  /// The six reactions offered when you long-press a message.
  static const quickPicks = ['❤️', '😂', '😮', '😢', '🙏', '👍'];

  @override
  bool operator ==(Object other) =>
      other is KitoChatReaction &&
      other.emoji == emoji &&
      _listEquals(other.userIds, userIds);

  @override
  int get hashCode => Object.hash(emoji, Object.hashAll(userIds));
}

/// A quoted message shown above a reply.
@immutable
class KitoChatReply {
  /// Creates a quote.
  const KitoChatReply({
    required this.messageId,
    required this.authorName,
    required this.preview,
    this.icon,
  });

  /// Quotes [message]: its author, a one-line preview and an icon for photos and voice notes.
  factory KitoChatReply.of(KitoChatMessage message,
      {Locale locale = const Locale('en')}) {
    final content = message.content;
    final (String preview, IconData? icon) = switch (content) {
      KitoChatTextContent(:final text) => (kitoChatSingleLine(text), null),
      KitoChatSystemContent(:final text) => (kitoChatSingleLine(text), null),
      KitoChatImageContent(:final image) => (
          image.caption == null || image.caption!.trim().isEmpty
              ? KitoChatStrings.lookup('photo', locale)
              : kitoChatSingleLine(image.caption!),
          Icons.photo_rounded,
        ),
      KitoChatVoiceContent(:final duration) => (
          KitoChatStrings.lookup('voiceMessageLength', locale,
              {'duration': KitoDurationFormatting.clock(duration)}),
          Icons.graphic_eq_rounded,
        ),
    };
    return KitoChatReply(
      messageId: message.id,
      authorName: message.author.name,
      preview: preview,
      icon: icon,
    );
  }

  /// The quoted message's id, for jumping to it.
  final String messageId;

  /// Who wrote the quoted message.
  final String authorName;

  /// A one-line preview of it.
  final String preview;

  /// An icon shown before the preview — a photo or a waveform.
  final IconData? icon;

  @override
  bool operator ==(Object other) =>
      other is KitoChatReply &&
      other.messageId == messageId &&
      other.authorName == authorName &&
      other.preview == preview &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(messageId, authorName, preview, icon);
}

// MARK: - Image

/// A photo in a message.
@immutable
class KitoChatImage {
  /// Creates a photo. [aspectRatio] (width ÷ height) sizes the bubble before it loads.
  const KitoChatImage(this.image, {double aspectRatio = 4 / 3, this.caption})
      : aspectRatio = aspectRatio > 0 ? aspectRatio : 1;

  /// The picture — `NetworkImage`, `AssetImage`, `MemoryImage`…
  final ImageProvider image;

  /// Width ÷ height.
  final double aspectRatio;

  /// Text under the photo.
  final String? caption;

  @override
  bool operator ==(Object other) =>
      other is KitoChatImage &&
      other.image == image &&
      other.aspectRatio == aspectRatio &&
      other.caption == caption;

  @override
  int get hashCode => Object.hash(image, aspectRatio, caption);
}

// MARK: - Content

/// What a message carries: text, a photo, a voice note or a system note.
sealed class KitoChatContent {
  const KitoChatContent();
}

/// Plain text, with inline `**bold**`, `*italic*`, `~~strike~~`, `` `code` `` and links.
final class KitoChatTextContent extends KitoChatContent {
  /// Creates text content.
  const KitoChatTextContent(this.text);

  /// The text.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is KitoChatTextContent && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A photo with an optional caption.
final class KitoChatImageContent extends KitoChatContent {
  /// Creates photo content.
  const KitoChatImageContent(this.image);

  /// The photo.
  final KitoChatImage image;

  @override
  bool operator ==(Object other) =>
      other is KitoChatImageContent && other.image == image;

  @override
  int get hashCode => image.hashCode;
}

/// A voice note: its length, loudness samples (0–1) for the waveform, and the recording if you
/// have it.
final class KitoChatVoiceContent extends KitoChatContent {
  /// Creates voice content.
  const KitoChatVoiceContent({
    required this.duration,
    this.waveform = const [],
    this.url,
  });

  /// How long it is.
  final Duration duration;

  /// Loudness samples, 0–1. Empty draws a placeholder shape.
  final List<double> waveform;

  /// Where the recording lives, for a player adapter to load.
  final Uri? url;

  @override
  bool operator ==(Object other) =>
      other is KitoChatVoiceContent &&
      other.duration == duration &&
      other.url == url &&
      _listEquals(other.waveform, waveform);

  @override
  int get hashCode => Object.hash(duration, url, Object.hashAll(waveform));
}

/// A centred note such as "Amani joined the group".
final class KitoChatSystemContent extends KitoChatContent {
  /// Creates a system note.
  const KitoChatSystemContent(this.text);

  /// The note.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is KitoChatSystemContent && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

// MARK: - Message

int _idCounter = 0;

/// A fresh, process-unique message id.
String kitoChatNewId() =>
    'm${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

/// One message in a conversation. Immutable — change it with [copyWith] or
/// [KitoChatController].
@immutable
class KitoChatMessage {
  /// Creates a message.
  KitoChatMessage({
    String? id,
    required this.author,
    DateTime? date,
    required this.content,
    this.status = KitoChatMessageStatus.sent,
    this.reactions = const [],
    this.replyTo,
  })  : id = id ?? kitoChatNewId(),
        date = date ?? DateTime.now();

  /// A text message.
  factory KitoChatMessage.text(
    String text, {
    String? id,
    required KitoChatUser author,
    DateTime? date,
    KitoChatMessageStatus status = KitoChatMessageStatus.sent,
    List<KitoChatReaction> reactions = const [],
    KitoChatReply? replyTo,
  }) =>
      KitoChatMessage(
        id: id,
        author: author,
        date: date,
        content: KitoChatTextContent(text),
        status: status,
        reactions: reactions,
        replyTo: replyTo,
      );

  /// A stable identifier.
  final String id;

  /// Who wrote it.
  final KitoChatUser author;

  /// When it was written.
  final DateTime date;

  /// What it carries.
  final KitoChatContent content;

  /// Delivery status, for outgoing messages.
  final KitoChatMessageStatus status;

  /// Emoji reactions.
  final List<KitoChatReaction> reactions;

  /// The message this one replies to.
  final KitoChatReply? replyTo;

  /// True for centred system notes.
  bool get isSystem => content is KitoChatSystemContent;

  /// The text you'd copy: the message text, the photo caption or the system note.
  String? get copyableText => switch (content) {
        KitoChatTextContent(:final text) => text,
        KitoChatSystemContent(:final text) => text,
        KitoChatImageContent(:final image) => image.caption,
        KitoChatVoiceContent() => null,
      };

  /// A one-line summary for chat lists and notifications: "📷 Photo", "🎤 Voice message · 0:12".
  String previewText([Locale locale = const Locale('en')]) {
    return switch (content) {
      KitoChatTextContent(:final text) => kitoChatSingleLine(text),
      KitoChatSystemContent(:final text) => kitoChatSingleLine(text),
      KitoChatImageContent(:final image) =>
        KitoChatStrings.lookup('photoPreview', locale, {
          'caption': image.caption == null || image.caption!.trim().isEmpty
              ? KitoChatStrings.lookup('photo', locale)
              : kitoChatSingleLine(image.caption!)
        }),
      KitoChatVoiceContent(:final duration) => KitoChatStrings.lookup(
          'voicePreview',
          locale,
          {'duration': KitoDurationFormatting.clock(duration)}),
    };
  }

  /// How many emoji a text message holds when it holds nothing else (1–3), so it can be shown
  /// large; null otherwise.
  int? get jumboEmojiCount {
    final c = content;
    if (c is! KitoChatTextContent) return null;
    final trimmed = c.text.trim();
    if (trimmed.isEmpty) return null;
    final count = trimmed.characters.length;
    if (count > 3) return null;
    return _emojiOnly.hasMatch(trimmed) ? count : null;
  }

  // The analyzer can't validate Unicode property escapes; the pattern is valid with
  // `unicode: true`.
  static final _emojiOnly = RegExp(
      // ignore: valid_regexps
      r'^(?:\p{Extended_Pictographic}|\p{Emoji_Presentation}|\p{Regional_Indicator}'
      r'|\p{Emoji_Modifier}|\u{200D}|\u{FE0F}|\u{20E3})+$', unicode: true);

  /// A copy where [emoji] from [userId] replaces that person's previous reaction; the same emoji
  /// again removes it.
  KitoChatMessage toggledReaction(String emoji, String userId) {
    final hadSame =
        reactions.any((r) => r.emoji == emoji && r.includes(userId));
    final next = <KitoChatReaction>[
      for (final r in reactions)
        KitoChatReaction(r.emoji, userIds: [
          for (final u in r.userIds)
            if (u != userId) u,
          if (!hadSame && r.emoji == emoji) userId,
        ]),
    ];
    if (!hadSame && !next.any((r) => r.emoji == emoji)) {
      next.add(KitoChatReaction(emoji, userIds: [userId]));
    }
    return copyWith(reactions: next.where((r) => r.count > 0).toList());
  }

  /// The emoji [userId] reacted with, if any.
  String? reactionOf(String userId) {
    for (final r in reactions) {
      if (r.includes(userId)) return r.emoji;
    }
    return null;
  }

  /// A copy with some fields replaced. Pass `clearReply: true` to drop [replyTo].
  KitoChatMessage copyWith({
    KitoChatUser? author,
    DateTime? date,
    KitoChatContent? content,
    KitoChatMessageStatus? status,
    List<KitoChatReaction>? reactions,
    KitoChatReply? replyTo,
    bool clearReply = false,
  }) =>
      KitoChatMessage(
        id: id,
        author: author ?? this.author,
        date: date ?? this.date,
        content: content ?? this.content,
        status: status ?? this.status,
        reactions: reactions ?? this.reactions,
        replyTo: clearReply ? null : (replyTo ?? this.replyTo),
      );

  @override
  bool operator ==(Object other) =>
      other is KitoChatMessage &&
      other.id == id &&
      other.author == author &&
      other.date == date &&
      other.content == content &&
      other.status == status &&
      other.replyTo == replyTo &&
      _listEquals(other.reactions, reactions);

  @override
  int get hashCode => Object.hash(
      id, author, date, content, status, replyTo, Object.hashAll(reactions));
}

/// [text] on one line: newlines become spaces, ends trimmed.
String kitoChatSingleLine(String text) =>
    text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).join(' ').trim();

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// MARK: - Lists of messages

/// Status updates on a list of messages.
extension KitoChatMessageList on List<KitoChatMessage> {
  /// Moves the message with [id] to [status], if that transition is allowed. Returns whether it
  /// changed.
  bool kitoUpdateStatus(String id, KitoChatMessageStatus status) {
    final index = indexWhere((m) => m.id == id);
    if (index < 0 || !this[index].status.canTransitionTo(status)) return false;
    this[index] = this[index].copyWith(status: status);
    return true;
  }
}

// MARK: - Conversation

/// One row of an inbox.
@immutable
class KitoChatConversation {
  /// Creates a conversation.
  const KitoChatConversation({
    required this.id,
    required this.user,
    this.title,
    this.lastMessage,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isTyping = false,
  });

  /// A stable identifier.
  final String id;

  /// The other person (or the group, with a group avatar colour).
  final KitoChatUser user;

  /// Shown instead of `user.name` — for groups.
  final String? title;

  /// The latest message, for the preview and time.
  final KitoChatMessage? lastMessage;

  /// How many messages are unread.
  final int unreadCount;

  /// Kept at the top.
  final bool isPinned;

  /// Notifications off; the unread badge turns grey.
  final bool isMuted;

  /// Shows "typing…" instead of the preview.
  final bool isTyping;

  /// [title], or the user's name.
  String get displayName => title ?? user.name;

  /// A copy with some fields replaced.
  KitoChatConversation copyWith({
    KitoChatUser? user,
    String? title,
    KitoChatMessage? lastMessage,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? isTyping,
  }) =>
      KitoChatConversation(
        id: id,
        user: user ?? this.user,
        title: title ?? this.title,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        isPinned: isPinned ?? this.isPinned,
        isMuted: isMuted ?? this.isMuted,
        isTyping: isTyping ?? this.isTyping,
      );

  /// Pinned first, then the most recent message first; ties keep their order.
  static List<KitoChatConversation> sorted(
      Iterable<KitoChatConversation> conversations) {
    final indexed = conversations.toList().asMap().entries.toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    indexed.sort((l, r) {
      if (l.value.isPinned != r.value.isPinned) {
        return l.value.isPinned ? -1 : 1;
      }
      final a = l.value.lastMessage?.date ?? epoch;
      final b = r.value.lastMessage?.date ?? epoch;
      final byDate = b.compareTo(a);
      return byDate != 0 ? byDate : l.key.compareTo(r.key);
    });
    return [for (final e in indexed) e.value];
  }

  @override
  bool operator ==(Object other) =>
      other is KitoChatConversation &&
      other.id == id &&
      other.user == user &&
      other.title == title &&
      other.lastMessage == lastMessage &&
      other.unreadCount == unreadCount &&
      other.isPinned == isPinned &&
      other.isMuted == isMuted &&
      other.isTyping == isTyping;

  @override
  int get hashCode => Object.hash(
      id, user, title, lastMessage, unreadCount, isPinned, isMuted, isTyping);
}
