// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:kito_ui_formatting/kito_ui_formatting.dart';

import 'models.dart';
import 'strings.dart';

// MARK: - Grouping

/// Where a message sits in a run of consecutive messages from the same person. Only the last
/// one (or a [single]) gets a tail.
enum KitoChatGroupPosition {
  /// Alone.
  single,

  /// Opens a run.
  first,

  /// Inside a run.
  middle,

  /// Closes a run.
  last;

  /// True for [single] and [first].
  bool get isGroupStart => this == single || this == first;

  /// True for [single] and [last].
  bool get isGroupEnd => this == single || this == last;
}

/// Groups consecutive messages from the same author.
abstract final class KitoChatGrouping {
  /// A run breaks on a new author, a system message, a new day, or a gap longer than
  /// [interval]. [breaksBefore] holds extra indices a run must break before (the unread divider,
  /// for instance).
  static List<KitoChatGroupPosition> positions(
    List<KitoChatMessage> messages, {
    Duration interval = const Duration(minutes: 5),
    Set<int> breaksBefore = const {},
  }) {
    final joins = [
      for (var i = 0; i < messages.length; i++)
        i > 0 &&
            !breaksBefore.contains(i) &&
            continues(messages[i - 1], messages[i], interval: interval),
    ];
    return [
      for (var i = 0; i < messages.length; i++)
        switch ((joins[i], i + 1 < messages.length && joins[i + 1])) {
          (false, false) => KitoChatGroupPosition.single,
          (false, true) => KitoChatGroupPosition.first,
          (true, true) => KitoChatGroupPosition.middle,
          (true, false) => KitoChatGroupPosition.last,
        },
    ];
  }

  /// Whether [message] continues the run [previous] is in.
  static bool continues(KitoChatMessage previous, KitoChatMessage message,
          {Duration interval = const Duration(minutes: 5)}) =>
      previous.author.id == message.author.id &&
      !previous.isSystem &&
      !message.isSystem &&
      KitoChatDateFormat.dayKey(previous.date) ==
          KitoChatDateFormat.dayKey(message.date) &&
      message.date.difference(previous.date).abs() <= interval;
}

// MARK: - Timeline

/// One row of a [KitoChatTimelineSection]: a message or the unread divider.
sealed class KitoChatTimelineRow {
  const KitoChatTimelineRow();

  /// A stable id for keys and scrolling.
  String get id;
}

/// A message and where it sits in its run.
final class KitoChatTimelineMessage extends KitoChatTimelineRow {
  /// Creates a message row.
  const KitoChatTimelineMessage(this.message, this.position);

  /// The message.
  final KitoChatMessage message;

  /// Its place in a run from the same author.
  final KitoChatGroupPosition position;

  @override
  String get id => message.id;

  @override
  bool operator ==(Object other) =>
      other is KitoChatTimelineMessage &&
      other.message == message &&
      other.position == position;

  @override
  int get hashCode => Object.hash(message, position);
}

/// The "N unread messages" divider.
final class KitoChatTimelineUnreadDivider extends KitoChatTimelineRow {
  /// Creates the divider.
  const KitoChatTimelineUnreadDivider(this.count);

  /// How many incoming messages follow it.
  final int count;

  @override
  String get id => KitoChatTimeline.unreadDividerId;

  @override
  bool operator ==(Object other) =>
      other is KitoChatTimelineUnreadDivider && other.count == count;

  @override
  int get hashCode => count.hashCode;
}

/// One day of messages with its separator title.
@immutable
class KitoChatTimelineSection {
  /// Creates a section.
  const KitoChatTimelineSection(
      {required this.id, required this.title, required this.rows});

  /// The day, as `yyyy-MM-dd`.
  final String id;

  /// "Today", "Yesterday", "Monday" or a date.
  final String title;

  /// Its messages (and perhaps the unread divider), oldest first.
  final List<KitoChatTimelineRow> rows;
}

/// Messages laid out for display: one section per day with its separator title, grouped
/// positions, and an "N unread" divider. Messages are expected oldest first.
@immutable
class KitoChatTimeline {
  /// Lays out [messages] as seen by [currentUserId].
  factory KitoChatTimeline(
    List<KitoChatMessage> messages, {
    required String currentUserId,
    int unreadCount = 0,
    DateTime? now,
    Duration groupingInterval = const Duration(minutes: 5),
    Locale locale = const Locale('en'),
  }) {
    final divider = unreadDivider(messages,
        currentUserId: currentUserId, unreadCount: unreadCount);
    final positions = KitoChatGrouping.positions(messages,
        interval: groupingInterval,
        breaksBefore: divider == null ? const {} : {divider.index});
    final sections = <KitoChatTimelineSection>[];
    final reference = now ?? DateTime.now();
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final key = KitoChatDateFormat.dayKey(message.date);
      if (sections.isEmpty || sections.last.id != key) {
        sections.add(KitoChatTimelineSection(
          id: key,
          title: KitoChatDateFormat.separatorTitle(message.date,
              now: reference, locale: locale),
          rows: [],
        ));
      }
      if (divider != null && divider.index == i) {
        sections.last.rows.add(KitoChatTimelineUnreadDivider(divider.count));
      }
      sections.last.rows.add(KitoChatTimelineMessage(message, positions[i]));
    }
    return KitoChatTimeline._(sections);
  }

  const KitoChatTimeline._(this.sections);

  /// The scroll id of the unread divider.
  static const unreadDividerId = 'kito.chat.unread';

  /// One section per day, oldest first.
  final List<KitoChatTimelineSection> sections;

  /// Where the "N unread" divider goes: before the [unreadCount]-th incoming message from the
  /// end (or the earliest incoming one, if there are fewer), and how many incoming messages
  /// follow it.
  static ({int index, int count})? unreadDivider(
    List<KitoChatMessage> messages, {
    required String currentUserId,
    required int unreadCount,
  }) {
    if (unreadCount <= 0) return null;
    var counted = 0;
    int? index;
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.author.id == currentUserId || m.isSystem) continue;
      counted++;
      index = i;
      if (counted == unreadCount) break;
    }
    return index == null ? null : (index: index, count: counted);
  }

  /// True when more than one other person has written — show names and avatars.
  static bool isGroupConversation(List<KitoChatMessage> messages,
          {required String currentUserId}) =>
      messages
          .where((m) => !m.isSystem && m.author.id != currentUserId)
          .map((m) => m.author.id)
          .toSet()
          .length >
      1;
}

// MARK: - Formatting

/// Dates, durations and typing text as a chat shows them.
abstract final class KitoChatDateFormat {
  /// "Today", "Yesterday", a weekday within the last week ("Monday"), "Sat 12 Sep" this year,
  /// otherwise "12 Sep 2025".
  static String separatorTitle(DateTime date,
      {DateTime? now, Locale locale = const Locale('en')}) {
    final ref = now ?? DateTime.now();
    final days = daysAgo(date, now: ref);
    final l = _locale(locale);
    if (days == 0) return KitoChatStrings.lookup('today', locale);
    if (days == 1) return KitoChatStrings.lookup('yesterday', locale);
    if (days > 1 && days < 7) return DateFormat.EEEE(l).format(date);
    return date.year == ref.year
        ? DateFormat('EEE d MMM', l).format(date)
        : DateFormat('d MMM yyyy', l).format(date);
  }

  /// The time in a chat list: "14:05" today, "Yesterday", "Mon" this week, otherwise a short
  /// date.
  static String listTimestamp(DateTime date,
      {DateTime? now, Locale locale = const Locale('en')}) {
    final days = daysAgo(date, now: now ?? DateTime.now());
    final l = _locale(locale);
    if (days <= 0) return time(date, locale: locale);
    if (days == 1) return KitoChatStrings.lookup('yesterday', locale);
    if (days < 7) return DateFormat.E(l).format(date);
    return DateFormat('dd/MM/yy', l).format(date);
  }

  /// The time of day: "2:05 PM" (or "14:05" where that's the custom).
  static String time(DateTime date, {Locale locale = const Locale('en')}) =>
      DateFormat.jm(intlLocale(locale)).format(date);

  /// "0:07", "1:23", "1:02:03".
  static String duration(Duration duration) =>
      KitoDurationFormatting.clock(Duration(
          seconds: (duration.inMilliseconds / 1000).round().clamp(0, 1 << 31)));

  /// "Amani is typing…", "Amani and Baraka are typing…", "Amani, Baraka and Chebet are
  /// typing…", "Amani, Baraka and 2 others are typing…".
  static String typingText(List<String> names,
      {Locale locale = const Locale('en')}) {
    return switch (names.length) {
      0 => '',
      1 => KitoChatStrings.lookup('typing1', locale, {'a': names[0]}),
      2 => KitoChatStrings.lookup(
          'typing2', locale, {'a': names[0], 'b': names[1]}),
      3 => KitoChatStrings.lookup(
          'typing3', locale, {'a': names[0], 'b': names[1], 'c': names[2]}),
      _ => KitoChatStrings.lookup('typingMany', locale,
          {'a': names[0], 'b': names[1], 'n': names.length - 2}),
    };
  }

  /// The day as `yyyy-MM-dd`.
  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Whole calendar days from [date] to [now]; negative for the future.
  static int daysAgo(DateTime date, {required DateTime now}) {
    final a = DateTime.utc(date.year, date.month, date.day);
    final b = DateTime.utc(now.year, now.month, now.day);
    return b.difference(a).inDays;
  }

  /// An intl locale name for [locale] that has date symbols loaded, or `en_US`.
  static String intlLocale(Locale locale) {
    try {
      return kitoDateLocale(locale.toLanguageTag().replaceAll('-', '_'));
    } on Object {
      return 'en_US';
    }
  }

  static String _locale(Locale locale) => intlLocale(locale);
}
