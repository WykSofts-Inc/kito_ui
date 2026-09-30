// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_ai_chat/kito_ui_ai_chat.dart';

void main() {
  group('KitoAiMarkdown', () {
    test('splits headings, paragraphs, lists, quotes, code, tables and rules',
        () {
      const md = '''
## Diani
Take the **SGR**.
Then the ferry.

- one
  - nested
1. first
2. second
- [x] done
- [ ] todo

> Tip: book early
> really

```dart
final x = 1;
```

| Item | KES |
|:--|--:|
| Ferry | 100 |

---''';
      final blocks = KitoAiMarkdown.blocks(md);
      expect(blocks.map((b) => b.kind), [
        'heading',
        'paragraph',
        'list',
        'list',
        'list',
        'quote',
        'code',
        'table',
        'rule',
      ]);
      expect(blocks[0], const KitoAiMarkdownHeading(2, 'Diani'));
      expect(blocks[1],
          const KitoAiMarkdownParagraph('Take the **SGR**.\nThen the ferry.'));
      expect((blocks[2] as KitoAiMarkdownList).items, const [
        KitoAiMarkdownListItem('one'),
        KitoAiMarkdownListItem('nested', level: 1),
      ]);
      expect(
          (blocks[3] as KitoAiMarkdownList).items.map((i) => i.number), [1, 2]);
      expect((blocks[4] as KitoAiMarkdownList).items.map((i) => i.isChecked),
          [true, false]);
      expect(blocks[5], const KitoAiMarkdownQuote('Tip: book early\nreally'));
      expect(blocks[6],
          const KitoAiMarkdownCode('final x = 1;', language: 'dart'));
      final table = blocks[7] as KitoAiMarkdownTable;
      expect(table.header, ['Item', 'KES']);
      expect(table.alignments,
          [KitoAiTableAlignment.start, KitoAiTableAlignment.end]);
      expect(table.rows, [
        ['Ferry', '100']
      ]);
    });

    test('an unclosed fence is still code, marked open', () {
      final blocks = KitoAiMarkdown.blocks('```swift\nlet a = 1');
      expect(
          blocks.single,
          const KitoAiMarkdownCode('let a = 1',
              language: 'swift', isClosed: false));
    });

    test('table rows are padded or trimmed to the header', () {
      final table =
          KitoAiMarkdown.blocks('| a | b |\n|---|:-:|\n| 1 |\n| 1 | 2 | 3 |')
              .single as KitoAiMarkdownTable;
      expect(table.rows, [
        ['1', ''],
        ['1', '2'],
      ]);
      expect(table.alignments.last, KitoAiTableAlignment.center);
    });

    test('plain text drops the syntax', () {
      expect(
          KitoAiMarkdown.plainText(
              '# Hi\nSee **the** [docs](https://x.co) and `code`'),
          'Hi\nSee the docs and code');
      expect(KitoAiMarkdown.stripInline('~~old~~ *new*'), 'old new');
    });
  });

  group('KitoAiStreamAssembler', () {
    String shown(String text) =>
        KitoAiStreamAssembler.displayTextFor(text, isStreaming: true);

    test('holds back lines that could still change meaning', () {
      expect(shown('Hello\n#'), 'Hello');
      expect(shown('Hello\n##'), 'Hello');
      expect(shown('Hello\n-'), 'Hello');
      expect(shown('Hello\n12.'), 'Hello');
      expect(shown('Hello\n>'), 'Hello');
      expect(shown('Hello\n``'), 'Hello');
      expect(shown('Hello\n```da'), 'Hello');
    });

    test('closes open inline markers and hides bare ones', () {
      expect(shown('Take the **SG'), 'Take the **SG**');
      expect(shown('Take the **'), 'Take the ');
      expect(shown('Some `cod'), 'Some `cod`');
      expect(shown('- a *list ite'), '- a *list ite*');
      expect(shown('~~gone'), '~~gone~~');
    });

    test('shows an unfinished link as its label', () {
      expect(shown('See [the docs](https://exa'), 'See the docs');
      expect(shown('See [the do'), 'See the do');
      expect(
          shown('See [done](https://x.co) ok'), 'See [done](https://x.co) ok');
    });

    test('a table header waits for its separator row', () {
      expect(shown('Intro\n| a | b |\n'), 'Intro');
      expect(shown('Intro\n| a | b |\n|--'), 'Intro');
      expect(shown('| a | b |\n|---|---|\n| 1 | 2 |\n'),
          '| a | b |\n|---|---|\n| 1 | 2 |\n');
    });

    test('inside a fence nothing is held back or closed', () {
      expect(shown('```dart\nfinal a = **b'), '```dart\nfinal a = **b');
    });

    test('finishing shows everything', () {
      final assembler = KitoAiStreamAssembler()
        ..append('Hello **wor')
        ..append('ld');
      expect(assembler.displayText, 'Hello **world**');
      assembler
        ..append('**\n#')
        ..finish();
      expect(assembler.displayText, 'Hello **world**\n#');
      expect(assembler.blocks.first.kind, 'paragraph');
    });
  });

  group('KitoAiInlineMarkdown', () {
    test('bold, italic, code, strike and links', () {
      expect(KitoAiInlineMarkdown.runs('Take the **SGR** to `Mombasa`'), const [
        KitoAiInlineRun('Take the '),
        KitoAiInlineRun('SGR', bold: true),
        KitoAiInlineRun(' to '),
        KitoAiInlineRun('Mombasa', code: true),
      ]);
      expect(KitoAiInlineMarkdown.runs('*pole* ~~haraka~~'), const [
        KitoAiInlineRun('pole', italic: true),
        KitoAiInlineRun(' '),
        KitoAiInlineRun('haraka', strike: true),
      ]);
      expect(KitoAiInlineMarkdown.runs('see [KWS](https://kws.go.ke).'), const [
        KitoAiInlineRun('see '),
        KitoAiInlineRun('KWS', link: 'https://kws.go.ke'),
        KitoAiInlineRun('.'),
      ]);
    });

    test('unmatched markers and snake_case stay as text', () {
      expect(KitoAiInlineMarkdown.runs('2 * 3 and snake_case_name'),
          const [KitoAiInlineRun('2 * 3 and snake_case_name')]);
      expect(KitoAiInlineMarkdown.runs(r'\*not\*'),
          const [KitoAiInlineRun('*not*')]);
    });
  });

  group('KitoAiSyntaxHighlighter', () {
    test('tokens join back into the code', () {
      const code = '''
// Pay with M-Pesa
final amount = 1500; /* KES */
Future<void> pay(String phone) async => print("ok \$phone");''';
      final tokens = KitoAiSyntaxHighlighter.tokens(code, language: 'dart');
      expect(tokens.map((t) => t.text).join(), code);
      KitoAiSyntaxKind kindOf(String text) =>
          tokens.firstWhere((t) => t.text == text).kind;
      expect(kindOf('// Pay with M-Pesa'), KitoAiSyntaxKind.comment);
      expect(kindOf('final'), KitoAiSyntaxKind.keyword);
      expect(kindOf('1500'), KitoAiSyntaxKind.number);
      expect(kindOf('String'), KitoAiSyntaxKind.type);
      expect(kindOf('pay'), KitoAiSyntaxKind.function);
      expect(tokens.any((t) => t.kind == KitoAiSyntaxKind.string), isTrue);
    });

    test('families: hash comments, sql keywords, json literals, plain text',
        () {
      expect(
          KitoAiSyntaxHighlighter.tokens('# hi\necho', language: 'bash')
              .first
              .kind,
          KitoAiSyntaxKind.comment);
      expect(
          KitoAiSyntaxHighlighter.tokens('SELECT 1', language: 'sql')
              .first
              .kind,
          KitoAiSyntaxKind.keyword);
      expect(
          KitoAiSyntaxHighlighter.tokens('{"a": true}', language: 'json')
              .map((t) => t.kind),
          contains(KitoAiSyntaxKind.keyword));
      expect(KitoAiSyntaxHighlighter.tokens('<b>x</b>', language: 'html'),
          const [KitoAiSyntaxToken('<b>x</b>', KitoAiSyntaxKind.plain)]);
    });
  });

  group('text helpers', () {
    test('titles drop fillers and truncate on a word', () {
      expect(KitoAiTitle.make('Hey, can you help me plan a weekend in Diani?'),
          'Plan a weekend in Diani');
      expect(
          KitoAiTitle.make('habari! please translate this'), 'Translate this');
      expect(KitoAiTitle.make('   '), 'New chat');
      final long = KitoAiTitle.make(
          'compare the standard gauge railway with every matatu route to mombasa',
          maxLength: 30);
      expect(long.endsWith('…'), isTrue);
      expect(long.length, lessThanOrEqualTo(30));
    });

    test('word and token counts', () {
      expect(KitoAiTextStats.wordCount("Asante sana, it's **great**!"), 4);
      expect(KitoAiTextStats.estimatedTokens(''), 0);
      expect(KitoAiTextStats.estimatedTokens('Habari yako'), 3);
      expect(
          KitoAiTextStats.readingTime('one two'), const Duration(seconds: 3));
      expect(KitoAiTextStats.fileSize(482000), '482 KB');
      expect(KitoAiTextStats.fileSize(1200000), '1.2 MB');
      expect(KitoAiTextStats.fileSize(12), '12 bytes');
    });

    test('greetings follow the hour', () {
      expect(
          KitoAiGreeting.text(
              date: DateTime(2026, 9, 30, 8), name: 'Wycliff N'),
          'Good morning, Wycliff');
      expect(KitoAiGreeting.text(date: DateTime(2026, 9, 30, 13)),
          'Good afternoon');
      expect(KitoAiGreeting.period(DateTime(2026, 9, 30, 2)),
          KitoAiDayPeriod.evening);
    });

    test('row timestamps and grouping', () {
      final now = DateTime(2026, 9, 30, 15);
      expect(
          KitoAiDateFormat.rowTimestamp(DateTime(2026, 9, 30, 9, 5), now: now),
          '09:05');
      expect(
          KitoAiDateFormat.rowTimestamp(DateTime(2026, 9, 30, 21, 5),
              now: now, use24HourFormat: false),
          '9:05 PM');
      expect(KitoAiDateFormat.rowTimestamp(DateTime(2026, 9, 29), now: now),
          'Yesterday');
      expect(KitoAiDateFormat.rowTimestamp(DateTime(2026, 9, 27), now: now),
          'Sun');
      expect(KitoAiDateFormat.rowTimestamp(DateTime(2026, 3, 12), now: now),
          '12 Mar');
      expect(KitoAiDateFormat.rowTimestamp(DateTime(2025, 3, 2), now: now),
          '02/03/25');

      KitoAiConversation chat(String title, DateTime at,
              {bool pinned = false}) =>
          KitoAiConversation(title: title, updatedAt: at, isPinned: pinned);
      final sections = KitoAiConversationGrouping.sections([
        chat('Old', DateTime(2026, 7, 2)),
        chat('Today', DateTime(2026, 9, 30, 9)),
        chat('Pinned', DateTime(2026, 1, 1), pinned: true),
        chat('Yesterday', DateTime(2026, 9, 29)),
        chat('Week', DateTime(2026, 9, 26)),
        chat('Month', DateTime(2026, 9, 10)),
        chat('Last year', DateTime(2025, 12, 1)),
      ], now: now);
      expect(sections.map((s) => s.title), [
        'Pinned',
        'Today',
        'Yesterday',
        'Previous 7 days',
        'Previous 30 days',
        'July',
        'December 2025',
      ]);
      expect(
          KitoAiConversationGrouping.filter(
                  [chat('SGR fares', now), chat('Chapati', now)], 'sgr')
              .single
              .title,
          'SGR fares');
    });
  });

  group('KitoAiAutoScrollPolicy', () {
    test('follows at the bottom, pauses when the reader scrolls up', () {
      final policy = KitoAiAutoScrollPolicy();
      policy.observe(
          distanceFromBottom: 0, contentHeight: 1000, viewportHeight: 700);
      expect(policy.isFollowing, isTrue);
      // Content grew by 200 while following: explained, still following.
      policy.observe(
          distanceFromBottom: 200, contentHeight: 1200, viewportHeight: 700);
      expect(policy.isFollowing, isTrue);
      // The reader dragged up 300 with no new content.
      policy.observe(
          distanceFromBottom: 500, contentHeight: 1200, viewportHeight: 700);
      expect(policy.isFollowing, isFalse);
      expect(policy.showsJumpToLatest, isTrue);
      policy.jumpToLatest();
      expect(policy.isFollowing, isTrue);
      policy.observe(
          distanceFromBottom: 20, contentHeight: 1200, viewportHeight: 700);
      expect(policy.showsJumpToLatest, isFalse);
    });

    test('a shrinking viewport (keyboard) is explained', () {
      final policy = KitoAiAutoScrollPolicy()
        ..observe(
            distanceFromBottom: 0, contentHeight: 1000, viewportHeight: 700)
        ..observe(
            distanceFromBottom: 300, contentHeight: 1000, viewportHeight: 400);
      expect(policy.isFollowing, isTrue);
    });
  });

  group('models', () {
    test('streamed events build up a message', () {
      final call = KitoAiToolCall.webSearch(id: 't1');
      var m = KitoAiMessage(role: KitoAiRole.assistant, isStreaming: true);
      expect(m.hasVisibleContent, isFalse);
      m = m
          .applying(KitoAiStreamEvent.toolCall(call))
          .applying(const KitoAiStreamEvent.token('Hello '))
          .applying(const KitoAiStreamEvent.token('Nairobi'))
          .applying(KitoAiStreamEvent.toolCall(
              call.withStatus(KitoAiToolStatus.done, detail: '3 sources')))
          .applying(KitoAiStreamEvent.citations(
              [KitoAiCitation(id: 'a', title: 'A')]))
          .applying(KitoAiStreamEvent.citations([
            KitoAiCitation(id: 'a', title: 'A'),
            KitoAiCitation(id: 'b', title: 'B', url: 'https://www.kws.go.ke/x'),
          ]))
          .applying(const KitoAiStreamEvent.followUps(['More']));
      expect(m.blocks.length, 3);
      expect(m.toolCalls.single.title, 'Searched the web');
      expect(m.toolCalls.single.detail, '3 sources');
      expect(m.text, 'Hello Nairobi');
      expect(m.citations.map((c) => c.id), ['a', 'b']);
      expect(m.citations.last.displaySource, 'kws.go.ke');
      expect(m.followUps, ['More']);
      expect(call.withStatus(KitoAiToolStatus.failed).title,
          "Searching the web didn't finish");
    });

    test('conversations round-trip through JSON', () {
      final conversation = KitoAiConversation(
        model: 'Kito Pro',
        isPinned: true,
        messages: [
          KitoAiMessage.user('Hey, plan a weekend in Diani', attachments: [
            KitoAiAttachment(
                name: 'Itinerary.pdf',
                kind: KitoAiAttachmentKind.pdf,
                byteCount: 482000),
          ]),
          KitoAiMessage(
              role: KitoAiRole.assistant,
              blocks: [
                KitoAiContentBlock.toolCall(KitoAiToolCall.webSearch(id: 'w')),
                const KitoAiContentBlock.markdown('## Diani'),
                const KitoAiContentBlock.code('print(1)', language: 'dart'),
                KitoAiContentBlock.citations([KitoAiCitation(title: 'KWS')]),
              ],
              feedback: KitoAiFeedback.positive,
              followUps: const ['Pack?']),
        ],
      );
      final json =
          jsonDecode(jsonEncode(conversation.toJson())) as Map<String, Object?>;
      final back = KitoAiConversation.fromJson(json);
      expect(back.id, conversation.id);
      expect(back.displayTitle, 'Plan a weekend in Diani');
      expect(back.isPinned, isTrue);
      expect(back.model, 'Kito Pro');
      expect(back.messages.first.attachments.single.subtitle, 'PDF · 482 KB');
      expect(back.messages.last.blocks, conversation.messages.last.blocks);
      expect(back.messages.last.feedback, KitoAiFeedback.positive);
      expect(back.messages.last.text, '## Diani\n\n```dart\nprint(1)\n```');
      expect(back.snippet, 'Diani\nprint(1)'.replaceAll('\n', ' '));
    });

    test('removing messages after one', () {
      final a = KitoAiMessage.user('a');
      final b = KitoAiMessage.assistant('b');
      final c = KitoAiConversation(messages: [a, b]);
      expect(c.removingMessagesAfter(a.id).messages, [a]);
      expect(c.lastAssistantMessage, b);
      expect(KitoAiConversation().displayTitle, 'New chat');
    });
  });

  group('KitoAiMockStream', () {
    test('chunks join back into the text and repeat with a seed', () {
      final text = KitoAiMockStream.diani.text;
      final a = KitoAiMockStream.chunksFor(text, seed: 7);
      final b = KitoAiMockStream.chunksFor(text, seed: 7);
      expect(a.map((c) => c.text).join(), text);
      expect(a.map((c) => c.text), b.map((c) => c.text));
      expect(a.length, greaterThan(50));
    });

    test('picks replies by keyword, else a fallback', () {
      final mock = KitoAiMockStream();
      expect(
          mock.replyFor('Show me M-Pesa STK push').text, contains('STK Push'));
      expect(mock.replyFor('Something else entirely').text,
          contains('Something else entirely'));
    });

    test('instant replies stream tools, tokens, sources and follow-ups',
        () async {
      final mock = KitoAiMockStream(instant: true);
      final events = await mock
          .reply(KitoAiConversation(messages: [KitoAiMessage.user('diani')]))
          .toList();
      expect(events.first, isA<KitoAiToolCallEvent>());
      expect(events.whereType<KitoAiTokenEvent>().map((e) => e.text).join(),
          KitoAiMockStream.diani.text);
      expect(events[events.length - 2], isA<KitoAiCitationsEvent>());
      expect(events.last, isA<KitoAiFollowUpsEvent>());
    });

    test('failures throw part-way, then replies succeed', () async {
      final mock = KitoAiMockStream(instant: true, failures: 1);
      final conversation =
          KitoAiConversation(messages: [KitoAiMessage.user('chapati')]);
      await expectLater(mock.reply(conversation).toList(),
          throwsA(KitoAiStreamError.networkLost));
      expect(await mock.reply(conversation).toList(), isNotEmpty);
    });

    test('a token stream adapts Stream<String>', () async {
      final stream = KitoAiTokenStream(
          (_) => Stream.fromIterable(const ['Jambo', ' ', 'Kenya']));
      final events = await stream.reply(KitoAiConversation()).toList();
      expect(events, const [
        KitoAiTokenEvent('Jambo'),
        KitoAiTokenEvent(' '),
        KitoAiTokenEvent('Kenya'),
      ]);
    });
  });
}
