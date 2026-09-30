// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_chat/kito_ui_chat.dart';

const me = KitoChatUser(id: 'wycliff', name: 'Wycliff N');
const amani = KitoChatUser(id: 'amani', name: 'Amani Wanjiru');
const baraka = KitoChatUser(id: 'baraka', name: 'Baraka');

KitoChatMessage text(String t, KitoChatUser who, DateTime at,
        {String? id,
        KitoChatMessageStatus status = KitoChatMessageStatus.sent}) =>
    KitoChatMessage.text(t, id: id, author: who, date: at, status: status);

void main() {
  final now = DateTime(2026, 9, 29, 14, 5);

  group('users', () {
    test('initials, first name and a stable palette index', () {
      expect(amani.initials, 'AW');
      expect(baraka.initials, 'B');
      expect(const KitoChatUser(id: 'x', name: '  ').initials, '?');
      expect(amani.firstName, 'Amani');
      expect(amani.paletteIndex(8), amani.paletteIndex(8));
      expect(amani.paletteIndex(8), inInclusiveRange(0, 7));
      expect(amani.paletteIndex(0), 0);
    });
  });

  group('status', () {
    test('only moves forward, except sending ⇄ failed', () {
      const s = KitoChatMessageStatus.values;
      expect(
          KitoChatMessageStatus.sending
              .canTransitionTo(KitoChatMessageStatus.read),
          isTrue);
      expect(
          KitoChatMessageStatus.read
              .canTransitionTo(KitoChatMessageStatus.sent),
          isFalse);
      expect(
          KitoChatMessageStatus.sending
              .canTransitionTo(KitoChatMessageStatus.failed),
          isTrue);
      expect(
          KitoChatMessageStatus.failed
              .canTransitionTo(KitoChatMessageStatus.sending),
          isTrue);
      expect(
          KitoChatMessageStatus.failed
              .canTransitionTo(KitoChatMessageStatus.sent),
          isFalse);
      expect(
          KitoChatMessageStatus.sent
              .canTransitionTo(KitoChatMessageStatus.failed),
          isFalse);
      expect(
          KitoChatMessageStatus.delivered
              .transitionedTo(KitoChatMessageStatus.sent),
          KitoChatMessageStatus.delivered);
      expect(s.map((x) => x.next), [
        KitoChatMessageStatus.sent,
        KitoChatMessageStatus.delivered,
        KitoChatMessageStatus.read,
        null,
        null,
      ]);
      expect(KitoChatMessageStatus.failed.label(), 'Not delivered');
      expect(KitoChatMessageStatus.read.label(const Locale('sw')), 'Imesomwa');
    });

    test('list updates respect transitions', () {
      final list = [
        text('Habari', me, now, id: 'a', status: KitoChatMessageStatus.read)
      ];
      expect(list.kitoUpdateStatus('a', KitoChatMessageStatus.sent), isFalse);
      expect(list.kitoUpdateStatus('missing', KitoChatMessageStatus.read),
          isFalse);
      final sending = [
        text('Habari', me, now, id: 'b', status: KitoChatMessageStatus.sending)
      ];
      expect(sending.kitoUpdateStatus('b', KitoChatMessageStatus.delivered),
          isTrue);
      expect(sending.first.status, KitoChatMessageStatus.delivered);
    });
  });

  group('messages', () {
    test('reactions: one per person, the same emoji again removes it', () {
      var m = text('Tuonane Java saa saba?', amani, now);
      m = m.toggledReaction('❤️', me.id);
      expect(m.reactions.single.userIds, [me.id]);
      m = m.toggledReaction('😂', me.id);
      expect(m.reactions.single.emoji, '😂');
      m = m.toggledReaction('😂', amani.id);
      expect(m.reactions.single.count, 2);
      m = m.toggledReaction('😂', me.id);
      expect(m.reactions.single.userIds, [amani.id]);
      expect(m.reactionOf(amani.id), '😂');
      expect(m.reactionOf(me.id), isNull);
    });

    test('jumbo emoji, previews, copy text and replies', () {
      expect(text('❤️', me, now).jumboEmojiCount, 1);
      expect(text(' 😂🙏 ', me, now).jumboEmojiCount, 2);
      expect(text('👍🏽', me, now).jumboEmojiCount, 1);
      expect(text('🇰🇪', me, now).jumboEmojiCount, 1);
      expect(text('😂😂😂😂', me, now).jumboEmojiCount, isNull);
      expect(text('Poa 😂', me, now).jumboEmojiCount, isNull);
      expect(text('1', me, now).jumboEmojiCount, isNull);

      final photo = KitoChatMessage(
          author: me,
          content: const KitoChatImageContent(
              KitoChatImage(AssetImage('x'), caption: 'Diani\nbeach')));
      expect(photo.previewText(), '📷 Diani beach');
      expect(photo.copyableText, 'Diani\nbeach');
      final voice = KitoChatMessage(
          author: amani,
          content: const KitoChatVoiceContent(duration: Duration(seconds: 12)));
      expect(voice.previewText(), '🎤 Voice message · 0:12');
      expect(
          voice.previewText(const Locale('sw')), '🎤 Ujumbe wa sauti · 0:12');
      expect(voice.copyableText, isNull);

      final reply = KitoChatReply.of(voice);
      expect(reply.authorName, 'Amani Wanjiru');
      expect(reply.preview, 'Voice message (0:12)');
      expect(reply.icon, isNotNull);
      expect(
          KitoChatReply.of(text('Two\nlines', me, now)).preview, 'Two lines');
    });

    test('equality and copyWith', () {
      final a = text('Sawa', me, now, id: 'x');
      expect(a, text('Sawa', me, now, id: 'x'));
      expect(a.copyWith(status: KitoChatMessageStatus.read), isNot(a));
      final r = a.copyWith(
          replyTo: const KitoChatReply(
              messageId: 'y', authorName: 'A', preview: 'p'));
      expect(r.copyWith(clearReply: true).replyTo, isNull);
    });

    test('conversations sort pinned first, then newest', () {
      final list = [
        KitoChatConversation(
            id: 'old',
            user: amani,
            lastMessage:
                text('a', amani, now.subtract(const Duration(days: 2)))),
        KitoChatConversation(
            id: 'new', user: baraka, lastMessage: text('b', baraka, now)),
        KitoChatConversation(
            id: 'pin',
            user: amani,
            isPinned: true,
            lastMessage:
                text('c', amani, now.subtract(const Duration(days: 9)))),
        const KitoChatConversation(id: 'empty', user: baraka),
      ];
      expect(KitoChatConversation.sorted(list).map((c) => c.id),
          ['pin', 'new', 'old', 'empty']);
      expect(list.first.copyWith(title: 'Wakili').displayName, 'Wakili');
    });
  });

  group('grouping and timeline', () {
    test('runs break on author, system notes, days and gaps', () {
      final m = [
        text('1', amani, now),
        text('2', amani, now.add(const Duration(minutes: 1))),
        text('3', amani, now.add(const Duration(minutes: 2))),
        text('4', me, now.add(const Duration(minutes: 3))),
        text('5', me, now.add(const Duration(minutes: 20))),
        KitoChatMessage(
            author: me, content: const KitoChatSystemContent('Baraka joined')),
        text('6', amani, now.add(const Duration(minutes: 21))),
      ];
      expect(KitoChatGrouping.positions(m), [
        KitoChatGroupPosition.first,
        KitoChatGroupPosition.middle,
        KitoChatGroupPosition.last,
        KitoChatGroupPosition.single,
        KitoChatGroupPosition.single,
        KitoChatGroupPosition.single,
        KitoChatGroupPosition.single,
      ]);
      expect(KitoChatGrouping.positions(m.sublist(0, 3), breaksBefore: {1}), [
        KitoChatGroupPosition.single,
        KitoChatGroupPosition.first,
        KitoChatGroupPosition.last,
      ]);
      expect(KitoChatGroupPosition.first.isGroupStart, isTrue);
      expect(KitoChatGroupPosition.middle.isGroupEnd, isFalse);
    });

    test('sections per day with titles and an unread divider', () {
      final yesterday = now.subtract(const Duration(days: 1));
      final m = [
        text('Habari ya jana', amani, yesterday, id: 'y1'),
        text('Poa', me, yesterday.add(const Duration(minutes: 1)), id: 'y2'),
        text('Uko?', amani, now, id: 't1'),
        text('Niko Westlands', amani, now.add(const Duration(minutes: 1)),
            id: 't2'),
      ];
      final t =
          KitoChatTimeline(m, currentUserId: me.id, unreadCount: 2, now: now);
      expect(t.sections.map((s) => s.title), ['Yesterday', 'Today']);
      final today = t.sections.last.rows;
      expect(today.first, isA<KitoChatTimelineUnreadDivider>());
      expect((today.first as KitoChatTimelineUnreadDivider).count, 2);
      expect(today[1].id, 't1');
      expect((today[1] as KitoChatTimelineMessage).position,
          KitoChatGroupPosition.first);

      final d = KitoChatTimeline.unreadDivider(m,
          currentUserId: me.id, unreadCount: 9);
      expect(d?.index, 0);
      expect(d?.count, 3);
      expect(
          KitoChatTimeline.unreadDivider(m,
              currentUserId: me.id, unreadCount: 0),
          isNull);
      expect(KitoChatTimeline.isGroupConversation(m, currentUserId: me.id),
          isFalse);
      expect(
          KitoChatTimeline.isGroupConversation(
              [...m, text('Mimi pia', baraka, now)],
              currentUserId: me.id),
          isTrue);
      final sw = KitoChatTimeline(m,
          currentUserId: me.id, now: now, locale: const Locale('sw'));
      expect(sw.sections.map((s) => s.title), ['Jana', 'Leo']);
    });
  });

  group('formatting', () {
    test('separators, list times, durations and typing', () {
      expect(KitoChatDateFormat.separatorTitle(now, now: now), 'Today');
      expect(KitoChatDateFormat.separatorTitle(DateTime(2026, 9, 27), now: now),
          'Sunday');
      expect(KitoChatDateFormat.separatorTitle(DateTime(2026, 9, 12), now: now),
          'Sat 12 Sep');
      expect(KitoChatDateFormat.separatorTitle(DateTime(2025, 9, 12), now: now),
          '12 Sep 2025');
      expect(
          KitoChatDateFormat.listTimestamp(DateTime(2026, 9, 28, 9), now: now),
          'Yesterday');
      expect(KitoChatDateFormat.listTimestamp(DateTime(2026, 9, 26), now: now),
          'Sat');
      expect(KitoChatDateFormat.listTimestamp(DateTime(2026, 9, 12), now: now),
          '12/09/26');
      expect(KitoChatDateFormat.listTimestamp(now, now: now), contains('2:05'));
      expect(KitoChatDateFormat.duration(const Duration(milliseconds: 6600)),
          '0:07');
      expect(KitoChatDateFormat.duration(const Duration(seconds: 3723)),
          '1:02:03');
      expect(KitoChatDateFormat.typingText([]), '');
      expect(KitoChatDateFormat.typingText(['Amani']), 'Amani is typing…');
      expect(KitoChatDateFormat.typingText(['Amani', 'Baraka']),
          'Amani and Baraka are typing…');
      expect(KitoChatDateFormat.typingText(['A', 'B', 'C']),
          'A, B and C are typing…');
      expect(KitoChatDateFormat.typingText(['A', 'B', 'C', 'D']),
          'A, B and 2 others are typing…');
      expect(
          KitoChatDateFormat.typingText(['Amani'], locale: const Locale('sw')),
          'Amani anaandika…');
    });

    test('strings fall back to English and honour a provider', () {
      expect(KitoChatStrings.lookup('send', const Locale('de')), 'Send');
      KitoChatStrings.provider =
          (key, locale) => key == 'send' ? 'Tuma sasa' : null;
      expect(KitoChatStrings.lookup('send', const Locale('en')), 'Tuma sasa');
      KitoChatStrings.provider = null;
      for (final lang in ['sw', 'fr']) {
        expect(KitoChatStrings.bundled[lang]!.keys.toSet(),
            KitoChatStrings.bundled['en']!.keys.toSet(),
            reason: lang);
      }
    });
  });

  group('markdown', () {
    test('bold, italic, strike, code and links', () {
      final s = KitoChatMarkdown.parse(
          '**Karibu** _sana_ ~~jana~~ `M-Pesa` www.kito.dev ok');
      expect(s[0], const KitoChatTextSegment('Karibu', bold: true));
      expect(s[2], const KitoChatTextSegment('sana', italic: true));
      expect(s[4], const KitoChatTextSegment('jana', strike: true));
      expect(s[6], const KitoChatTextSegment('M-Pesa', code: true));
      expect(s[8].link, Uri.parse('https://www.kito.dev'));
      expect(s.last.text, ' ok');
    });

    test('leaves unmatched markers and snake_case alone', () {
      expect(KitoChatMarkdown.parse('2 * 3 = 6').single.text, '2 * 3 = 6');
      expect(KitoChatMarkdown.parse('file_name_here').single.text,
          'file_name_here');
      expect(KitoChatMarkdown.parse(r'\*not\*').single.text, '*not*');
      final link = KitoChatMarkdown.parse('Soma https://kito.dev/docs.');
      expect(link[1].link.toString(), 'https://kito.dev/docs');
      expect(link.last.text, '.');
    });
  });

  group('waveform and swipe', () {
    test('downsample, normalise and decibels', () {
      expect(KitoChatWaveform.downsample([], 4), isEmpty);
      expect(KitoChatWaveform.downsample([0.1, 0.5, 0.2, 0.25], 2), [1.0, 0.5]);
      expect(KitoChatWaveform.downsample([0.5], 3), [1.0, 1.0, 1.0]);
      expect(KitoChatWaveform.normalized([0, 0]), [0.0, 0.0]);
      expect(KitoChatWaveform.normalized([double.nan, 2]), [0.0, 1.0]);
      expect(KitoChatWaveform.levelFromDecibels(0), 1);
      expect(KitoChatWaveform.levelFromDecibels(-25), 0.5);
      expect(KitoChatWaveform.levelFromDecibels(-80), 0);
      expect(KitoChatWaveform.levelFromDecibels(double.negativeInfinity), 0);
    });

    test('placeholders are stable and in range', () {
      final a = KitoChatWaveform.placeholder(count: 32, seed: 42);
      expect(a, KitoChatWaveform.placeholder(count: 32, seed: 42));
      expect(a, isNot(KitoChatWaveform.placeholder(count: 32, seed: 7)));
      expect(a.every((v) => v >= 0.08 && v <= 1), isTrue);
      expect(KitoChatWaveform.placeholder(count: 0), isEmpty);
      expect(KitoChatWaveform.seedFor('m1'), KitoChatWaveform.seedFor('m1'));
    });

    test('speeds cycle and the swipe rubber-bands', () {
      expect(KitoChatPlaybackSpeed.normal.next, KitoChatPlaybackSpeed.fast);
      expect(KitoChatPlaybackSpeed.fastest.next, KitoChatPlaybackSpeed.normal);
      expect(KitoChatPlaybackSpeed.fast.label, '1.5×');
      expect(KitoChatSwipeReply.offset(-20), 0);
      expect(KitoChatSwipeReply.offset(30), lessThan(30));
      expect(KitoChatSwipeReply.offset(10000),
          lessThanOrEqualTo(KitoChatSwipeReply.limit));
      expect(KitoChatSwipeReply.progress(KitoChatSwipeReply.threshold), 1);
    });
  });

  group('controller and playback', () {
    test('controller edits and notifies', () {
      final c = KitoChatController();
      var n = 0;
      c.addListener(() => n++);
      final m =
          text('Sasa', me, now, id: 'a', status: KitoChatMessageStatus.sending);
      c.add(m);
      expect(c.updateStatus('a', KitoChatMessageStatus.read), isTrue);
      expect(c.updateStatus('a', KitoChatMessageStatus.sent), isFalse);
      c.toggleReaction('a', '🙏', amani.id);
      expect(c.byId('a')!.reactions.single.emoji, '🙏');
      c.prepend([text('Old', amani, now, id: 'o')]);
      expect(c.messages.first.id, 'o');
      c.typingUsers = [amani];
      c.typingUsers = [amani];
      c.remove('a');
      c.remove('a');
      expect(c.messages.map((m) => m.id), ['o']);
      expect(n, 6);
      c.dispose();
    });

    test('simulated playback advances, finishes and cycles speed', () {
      final p = KitoChatVoicePlayback(duration: const Duration(seconds: 2));
      expect(p.isSimulated, isTrue);
      p.play();
      p.advance(const Duration(milliseconds: 500));
      expect(p.progress, closeTo(0.25, 1e-9));
      p.cycleSpeed();
      p.advance(const Duration(milliseconds: 500));
      expect(p.progress, closeTo(0.625, 1e-9));
      p.seek(2);
      expect(p.progress, 1);
      p.seek(0.9);
      p.advance(const Duration(seconds: 1));
      expect(p.isPlaying, isFalse);
      expect(p.progress, 0);
      p.dispose();
    });
  });
}
