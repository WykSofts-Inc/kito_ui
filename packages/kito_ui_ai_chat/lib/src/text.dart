// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/foundation.dart';

import 'markdown.dart';
import 'models.dart';

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int n) => n.toString().padLeft(2, '0');

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysBetween(DateTime from, DateTime to) =>
    (_day(to).difference(_day(from)).inHours / 24).round();

/// Makes a short conversation title from its first message.
///
/// ```dart
/// KitoAiTitle.make('Hey, can you help me plan a weekend in Diani?');  // "Plan a weekend in Diani"
/// ```
abstract final class KitoAiTitle {
  static const _fillers = [
    'i would like you to', "i'd like you to", 'i want you to', 'i need you to',
    'could you please', 'can you please', 'would you please', //
    'could you', 'can you', 'would you', 'will you', 'can u', //
    'help me to', 'help me', 'please', 'kindly', //
    'hey there', 'hello', 'hey', 'hi', 'habari', 'sasa', 'yo',
  ];

  static const _edge = ' ?!.,:;…-—';

  /// A title of at most [maxLength] characters from [text].
  static String make(String text, {int maxLength = 40}) {
    final firstLine = KitoAiMarkdown.plainText(text)
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    var title =
        firstLine.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
    title = _removingFillers(title);
    title = _trim(title, _edge);
    if (title.isEmpty) return 'New chat';
    title = title[0].toUpperCase() + title.substring(1);
    return _truncated(title, maxLength);
  }

  static String _trim(String text, String chars) {
    var start = 0;
    var end = text.length;
    while (start < end && chars.contains(text[start])) {
      start++;
    }
    while (end > start && chars.contains(text[end - 1])) {
      end--;
    }
    return text.substring(start, end);
  }

  static String _removingFillers(String text) {
    var result = text;
    var changed = true;
    while (changed) {
      changed = false;
      final lowered = result.toLowerCase();
      for (final filler in _fillers) {
        if (!lowered.startsWith(filler)) continue;
        final rest = result.substring(filler.length);
        if (rest.isNotEmpty && !' ,!'.contains(rest[0])) continue;
        result = _trim(rest, ' ,!');
        changed = true;
        break;
      }
    }
    return result.isEmpty ? text : result;
  }

  static String _truncated(String text, int maxLength) {
    if (text.length <= maxLength || maxLength <= 1) return text;
    final limit = text.substring(0, maxLength - 1);
    final space = limit.lastIndexOf(' ');
    final cut = space > 0 ? limit.substring(0, space) : limit;
    return '${_trim(cut, ' ,.;:-—')}…';
  }
}

/// Word, token and size helpers for prompts, replies and files.
abstract final class KitoAiTextStats {
  static final _word =
      RegExp(r"[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*", unicode: true);

  /// Words as a reader counts them — punctuation and markdown syntax don't count.
  static int wordCount(String text) => _word.allMatches(text).length;

  /// A provider-neutral estimate of model tokens: roughly four characters or three quarters of
  /// a word each, whichever is larger. Use your provider's tokenizer for exact numbers.
  static int estimatedTokens(String text) {
    if (text.trim().isEmpty) return 0;
    final byCharacters = (text.length / 4).ceil();
    final byWords = (wordCount(text) * 4 / 3).ceil();
    final best = byCharacters > byWords ? byCharacters : byWords;
    return best < 1 ? 1 : best;
  }

  /// How long [text] takes to read at [wordsPerMinute]; at least three seconds for any text.
  static Duration readingTime(String text, {double wordsPerMinute = 230}) {
    final words = wordCount(text);
    if (words == 0) return Duration.zero;
    final seconds = words / wordsPerMinute * 60;
    return Duration(milliseconds: ((seconds < 3 ? 3 : seconds) * 1000).round());
  }

  /// "820 bytes", "482 KB", "1.2 MB", "3.4 GB" (1 KB = 1,000 bytes, like file managers).
  static String fileSize(int bytes) {
    if (bytes < 1000) return bytes == 1 ? '1 byte' : '$bytes bytes';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1000;
    var unit = 0;
    while (value >= 1000 && unit < units.length - 1) {
      value /= 1000;
      unit++;
    }
    final text = unit == 0 || value >= 100
        ? value.round().toString()
        : value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '$text ${units[unit]}';
  }
}

/// A part of the day, for greetings.
enum KitoAiDayPeriod {
  /// 05:00–11:59.
  morning,

  /// 12:00–16:59.
  afternoon,

  /// 17:00–04:59.
  evening,
}

/// "Good morning", "Good afternoon" or "Good evening", with a first name.
abstract final class KitoAiGreeting {
  /// Morning from 5:00, afternoon from 12:00, evening from 17:00 until 5:00.
  static KitoAiDayPeriod period(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 12) return KitoAiDayPeriod.morning;
    if (hour >= 12 && hour < 17) return KitoAiDayPeriod.afternoon;
    return KitoAiDayPeriod.evening;
  }

  /// `"Good evening, Wycliff"` — the first word of [name] only.
  static String text({DateTime? date, String? name}) {
    final base = 'Good ${period(date ?? DateTime.now()).name}';
    final first = name?.trim().split(RegExp(r'\s+')).first ?? '';
    return first.isEmpty ? base : '$base, $first';
  }
}

/// Timestamps for conversation rows.
abstract final class KitoAiDateFormat {
  /// "14:05" today, "Yesterday", a weekday within the week, "12 Sep" this year, else
  /// "12/09/25".
  static String rowTimestamp(DateTime date,
      {DateTime? now, bool use24HourFormat = true}) {
    final today = now ?? DateTime.now();
    final days = _daysBetween(date, today);
    if (days == 0) return time(date, use24HourFormat: use24HourFormat);
    if (days == 1) return 'Yesterday';
    if (days > 1 && days < 7) return _weekdaysShort[date.weekday - 1];
    if (date.year == today.year) {
      return '${date.day} ${_monthsShort[date.month - 1]}';
    }
    return '${_two(date.day)}/${_two(date.month)}/${_two(date.year % 100)}';
  }

  /// "14:05", or "2:05 PM" when [use24HourFormat] is false.
  static String time(DateTime date, {bool use24HourFormat = true}) {
    if (use24HourFormat) return '${_two(date.hour)}:${_two(date.minute)}';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${_two(date.minute)} ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "September", or "September 2025" for another year.
  static String month(DateTime date, {DateTime? now}) {
    final sameYear = date.year == (now ?? DateTime.now()).year;
    final name = _monthsLong[date.month - 1];
    return sameYear ? name : '$name ${date.year}';
  }
}

/// A titled group of conversations in the list.
@immutable
class KitoAiConversationSection {
  /// Creates a section.
  const KitoAiConversationSection(this.title, this.conversations);

  /// "Pinned", "Today", "Previous 7 days", "August"…
  final String title;

  /// Newest first.
  final List<KitoAiConversation> conversations;
}

/// Buckets conversations the way chat apps do: Pinned, Today, Yesterday, Previous 7 days,
/// Previous 30 days, then one section per month.
abstract final class KitoAiConversationGrouping {
  /// The sections for [conversations], newest first.
  static List<KitoAiConversationSection> sections(
      List<KitoAiConversation> conversations,
      {DateTime? now}) {
    final today = now ?? DateTime.now();
    final sorted = [...conversations]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final titles = <String>[];
    final groups = <String, List<KitoAiConversation>>{};
    void add(String title, KitoAiConversation c) {
      if (!groups.containsKey(title)) titles.add(title);
      (groups[title] ??= []).add(c);
    }

    for (final c in sorted.where((c) => c.isPinned)) {
      add('Pinned', c);
    }
    for (final c in sorted.where((c) => !c.isPinned)) {
      add(bucket(c.updatedAt, now: today), c);
    }
    return [
      for (final t in titles)
        KitoAiConversationSection(t, List.unmodifiable(groups[t]!)),
    ];
  }

  /// The section title for [date].
  static String bucket(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = _daysBetween(date, today);
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return 'Previous 7 days';
    if (days < 30) return 'Previous 30 days';
    return KitoAiDateFormat.month(date, now: today);
  }

  /// Conversations whose title or latest text contains [query], ignoring case.
  static List<KitoAiConversation> filter(
      List<KitoAiConversation> conversations, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return [
      for (final c in conversations)
        if (c.displayTitle.toLowerCase().contains(q) ||
            c.snippet.toLowerCase().contains(q))
          c,
    ];
  }
}
