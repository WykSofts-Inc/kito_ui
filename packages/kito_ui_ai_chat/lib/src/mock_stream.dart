// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import 'models.dart';
import 'stream.dart';
import 'text.dart';

/// A canned reply for [KitoAiMockStream].
@immutable
class KitoAiMockReply {
  /// Creates a reply.
  const KitoAiMockReply({
    required this.keywords,
    required this.text,
    this.tools = const [],
    this.citations = const [],
    this.followUps = const [],
  });

  /// The reply is chosen when the prompt contains any of these (ignoring case).
  final List<String> keywords;

  /// The markdown that streams in.
  final String text;

  /// Run before the text, each shown as running and then done with its detail.
  final List<KitoAiToolCall> tools;

  /// Sent after the text.
  final List<KitoAiCitation> citations;

  /// Sent last.
  final List<String> followUps;
}

/// One streamed piece of text and the pause before it.
@immutable
class KitoAiMockChunk {
  /// Creates a chunk.
  const KitoAiMockChunk(this.text, this.delay);

  /// The text.
  final String text;

  /// The pause before it, at speed 1.
  final Duration delay;
}

/// A stand-in model for demos, galleries and tests. It picks a canned reply by keyword and types
/// it out token by token with realistic jitter — quick bursts, pauses after sentences, the odd
/// hesitation — optionally running a tool first and citing sources. No network, no plugins.
///
/// ```dart
/// KitoAiChatSession(stream: KitoAiMockStream());
/// KitoAiMockStream(failures: 1);     // the first reply fails, Retry works
/// KitoAiMockStream(instant: true);   // everything at once, without timers — for tests
/// ```
///
/// The pauses use timers that are cancelled with the subscription, so stopping a reply or
/// disposing the session leaves nothing pending.
class KitoAiMockStream implements KitoAiStream {
  /// Creates a mock.
  ///
  /// [failures] is how many replies fail part-way before replies start succeeding — use it to
  /// try the error bubble and Retry. [seed] fixes the jitter so runs repeat exactly.
  KitoAiMockStream({
    List<KitoAiMockReply>? replies,
    this.speed = 1,
    this.thinkingDelay = const Duration(milliseconds: 900),
    int failures = 0,
    this.seed,
    this.instant = false,
  })  : replies = replies ?? defaultReplies,
        _failures = failures < 0 ? 0 : failures;

  /// The canned replies, checked in order.
  final List<KitoAiMockReply> replies;

  /// Above 1 types faster, below 1 slower.
  final double speed;

  /// How long it "thinks" before the first token.
  final Duration thinkingDelay;

  /// Fixes the jitter; null varies it each time.
  final int? seed;

  /// Sends everything at once through microtasks, with no timers at all.
  final bool instant;

  int _failures;
  static final math.Random _seeds = math.Random();

  @override
  Stream<KitoAiStreamEvent> reply(KitoAiConversation conversation) {
    final prompt = conversation.lastUserMessage?.plainText ?? '';
    final canned = replyFor(prompt);
    final chunks =
        chunksFor(canned.text, seed: seed ?? _seeds.nextInt(1 << 30));
    final fail = _failures > 0;
    if (fail) _failures--;

    final pace = speed < 0.05 ? 0.05 : speed;
    Duration scaled(Duration d) => instant ? Duration.zero : d * (1 / pace);

    final steps = <_Step>[];
    var pending = scaled(thinkingDelay);
    for (final tool in canned.tools) {
      steps.add(_Step(
          pending,
          KitoAiToolCallEvent(KitoAiToolCall(
              id: tool.id,
              name: tool.name,
              runningTitle: tool.runningTitle,
              doneTitle: tool.doneTitle,
              symbol: tool.symbol))));
      steps.add(_Step(scaled(const Duration(milliseconds: 1400)),
          KitoAiToolCallEvent(tool.withStatus(KitoAiToolStatus.done))));
      pending = scaled(const Duration(milliseconds: 350));
    }
    final failAt = fail ? math.max(1, chunks.length * 2 ~/ 5) : -1;
    for (var i = 0; i < chunks.length; i++) {
      if (i == failAt) {
        steps.add(_Step(pending, null, KitoAiStreamError.networkLost));
        break;
      }
      steps.add(_Step(
          pending + scaled(chunks[i].delay), KitoAiTokenEvent(chunks[i].text)));
      pending = Duration.zero;
    }
    if (!fail) {
      if (canned.citations.isNotEmpty) {
        steps.add(_Step(Duration.zero, KitoAiCitationsEvent(canned.citations)));
      }
      if (canned.followUps.isNotEmpty) {
        steps.add(_Step(Duration.zero, KitoAiFollowUpsEvent(canned.followUps)));
      }
    }
    if (instant) return _instant(steps);
    return _timed(steps);
  }

  static Stream<KitoAiStreamEvent> _instant(List<_Step> steps) async* {
    for (final step in steps) {
      if (step.error != null) throw step.error!;
      yield step.event!;
    }
  }

  static Stream<KitoAiStreamEvent> _timed(List<_Step> steps) {
    Timer? timer;
    var next = 0;
    late final StreamController<KitoAiStreamEvent> controller;

    void schedule() {
      if (next >= steps.length) {
        controller.close();
        return;
      }
      final step = steps[next];
      timer = Timer(step.delay, () {
        timer = null;
        next++;
        if (step.error != null) {
          controller
            ..addError(step.error!)
            ..close();
          return;
        }
        controller.add(step.event!);
        if (!controller.isPaused) schedule();
      });
    }

    controller = StreamController<KitoAiStreamEvent>(
      onListen: schedule,
      onPause: () {
        timer?.cancel();
        timer = null;
      },
      onResume: () {
        if (timer == null) schedule();
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  /// The canned reply for [prompt]: the first whose keywords match, else a general one.
  KitoAiMockReply replyFor(String prompt) {
    final lowered = prompt.toLowerCase();
    for (final reply in replies) {
      if (reply.keywords.any((k) => lowered.contains(k.toLowerCase()))) {
        return reply;
      }
    }
    return _fallback(prompt);
  }

  // MARK: Jitter

  /// Splits [text] into token-sized chunks with human-feeling delays. The chunks always join
  /// back into exactly [text], and the same seed always gives the same chunks.
  static List<KitoAiMockChunk> chunksFor(String text, {required int seed}) {
    final random = _ParkMiller(seed);
    final chunks = <KitoAiMockChunk>[];
    var fences = 0;
    var previous = '';
    for (final word in _words(text)) {
      final inCode = fences.isOdd;
      for (final piece in _split(word, random)) {
        chunks.add(KitoAiMockChunk(
            piece, _delay(previous, inCode: inCode, random: random)));
        previous = piece;
      }
      fences += '```'.allMatches(word).length;
    }
    return chunks;
  }

  static List<String> _words(String text) {
    final words = <String>[];
    final current = StringBuffer();
    var inWhitespace = false;
    for (final c in text.characters) {
      final isSpace = c.trim().isEmpty;
      if (!isSpace && inWhitespace && current.isNotEmpty) {
        words.add(current.toString());
        current.clear();
      }
      current.write(c);
      inWhitespace = isSpace;
    }
    if (current.isNotEmpty) words.add(current.toString());
    return words;
  }

  static List<String> _split(String word, _ParkMiller random) {
    final characters = word.characters.toList();
    if (characters.length <= 6 || random.unit() >= 0.7) return [word];
    final pieces = <String>[];
    var start = 0;
    while (characters.length - start > 5) {
      final size = 2 + (random.unit() * 4).floor();
      pieces.add(characters.sublist(start, start + size).join());
      start += size;
    }
    if (start < characters.length) pieces.add(characters.sublist(start).join());
    return pieces;
  }

  static Duration _delay(String piece,
      {required bool inCode, required _ParkMiller random}) {
    var seconds = 0.014 + random.unit() * 0.034;
    if (inCode) seconds *= 0.55;
    final trimmed = piece.trim();
    if (trimmed.isNotEmpty &&
        '.!?:'.contains(trimmed[trimmed.length - 1]) &&
        piece.isNotEmpty &&
        piece[piece.length - 1].trim().isEmpty) {
      seconds += 0.08 + random.unit() * 0.16;
    }
    if (piece.contains('\n\n')) seconds += 0.1 + random.unit() * 0.2;
    if (random.unit() < 0.035) seconds += 0.25 + random.unit() * 0.35;
    return Duration(microseconds: (seconds * 1e6).round());
  }

  // MARK: Canned replies

  static KitoAiMockReply _fallback(String prompt) {
    final topic = KitoAiTitle.make(prompt, maxLength: 60);
    return KitoAiMockReply(
      keywords: const [],
      text: '''
Good question. Here's a short take on **“$topic”**:

- **The short version:** this is a demo reply from `KitoAiMockStream`, streamed token by token with realistic pauses.
- **What it shows:** markdown, a streaming cursor, auto-scroll and the actions under each reply.
- **Try asking about:** a weekend in Diani, M-Pesa STK push in Dart, Swahili phrases, or the SGR vs a matatu.

Connect your own model by implementing `KitoAiStream` — any provider and any SDK works.''',
      followUps: const [
        'Plan a weekend in Diani',
        'Show me M-Pesa STK push in Dart',
      ],
    );
  }

  /// The built-in replies: a Diani weekend (with a web search and sources), M-Pesa STK push in
  /// Dart (code), Swahili phrases (a table), SGR vs matatu, a chapati recipe and a polite
  /// message to a landlord.
  static final List<KitoAiMockReply> defaultReplies = [
    diani,
    mpesa,
    swahili,
    sgr,
    chapati,
    landlord,
  ];

  /// A weekend in Diani, with a web search, a budget table and four sources.
  static final diani = KitoAiMockReply(
    keywords: const ['diani', 'weekend', 'beach', 'coast'],
    text: '''
## A relaxed weekend in Diani 🌴

Diani is about **30 km south of Mombasa**. The easiest way there from Nairobi is the SGR to Mombasa, then a transfer across the Likoni ferry.

### Friday
- Take the **Madaraka Express** from Nairobi Terminus in the morning.
- Check in, then catch the sunset on *Galu Beach*.

### Saturday
1. Snorkel at **Kisite-Mpunguti Marine Park** — dolphins are common before 10am.
2. Lunch on Wasini Island: coconut rice and fresh crab.
3. Dinner at a cave restaurant in Diani.

### Sunday
- Visit **Colobus Conservation**, then head back on the afternoon train.

| Item | Estimate (KES) |
|:-----|------:|
| SGR economy, return | 3,000 |
| Transfers and ferry | 2,500 |
| Guesthouse, 2 nights | 12,000 |
| Snorkelling trip | 4,500 |
| **Total** | **22,000** |

> Tip: book the SGR a week ahead — weekend trains sell out, especially in August and December.''',
    tools: [
      KitoAiToolCall(
          id: 'mock.search.diani',
          name: 'web_search',
          runningTitle: 'Searching the web…',
          doneTitle: 'Searched the web',
          detail: '4 sources',
          symbol: 'globe'),
    ],
    citations: [
      KitoAiCitation(
          id: 'c1', title: 'Diani Beach', url: 'https://www.magicalkenya.com'),
      KitoAiCitation(
          id: 'c2',
          title: 'Madaraka Express tickets',
          url: 'https://metickets.krc.co.ke'),
      KitoAiCitation(
          id: 'c3',
          title: 'Kisite-Mpunguti Marine Park',
          url: 'https://www.kws.go.ke'),
      KitoAiCitation(
          id: 'c4',
          title: 'Colobus Conservation',
          url: 'https://www.colobusconservation.org'),
    ],
    followUps: const [
      'Make it a budget trip under KES 15,000',
      'What should I pack?',
      'Add a day on Wasini Island',
    ],
  );

  /// M-Pesa STK push in Dart, with a docs lookup and a code block.
  static final mpesa = KitoAiMockReply(
    keywords: const ['m-pesa', 'mpesa', 'daraja', 'stk', 'dart', 'code'],
    text: r'''
Here's a minimal **STK Push** request against the Daraja sandbox, using `package:http` and `async`/`await`.

```dart
Future<Map<String, dynamic>> sendStkPush({
  required String token,
  required String phone, // 2547XXXXXXXX
  required int amount,
}) async {
  final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
  final password = base64Encode(utf8.encode('$shortCode$passkey$timestamp'));
  final response = await http.post(
    Uri.parse('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'BusinessShortCode': shortCode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount,
      'PartyA': phone,
      'PartyB': shortCode,
      'PhoneNumber': phone,
      'CallBackURL': 'https://example.co.ke/mpesa/callback',
      'AccountReference': 'Kito',
      'TransactionDesc': 'Order 1042',
    }),
  );
  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

A few things to get right:

- The `Password` is **Base64(Shortcode + Passkey + Timestamp)**, with the timestamp as `yyyyMMddHHmmss`.
- Fetch the OAuth token from `/oauth/v1/generate` first — it expires after an hour.
- Never ship your consumer secret in the app. Call Daraja from **your own backend** and let the app talk to that.

The customer sees the M-Pesa prompt on their phone, and Safaricom posts the result to your `CallBackURL`.''',
    tools: [
      KitoAiToolCall(
          id: 'mock.docs.daraja',
          name: 'read_docs',
          runningTitle: 'Reading the Daraja docs…',
          doneTitle: 'Read the Daraja docs',
          detail: 'STK Push',
          symbol: 'book'),
    ],
    citations: [
      KitoAiCitation(
          id: 'd1',
          title: 'Daraja API — M-Pesa Express',
          url: 'https://developer.safaricom.co.ke'),
    ],
    followUps: const [
      'How do I handle the callback?',
      'Show the password generation',
      'Write it with dio',
    ],
  );

  /// Swahili phrases for a safari, as a table and a list.
  static const swahili = KitoAiMockReply(
    keywords: ['swahili', 'kiswahili', 'phrase', 'translate'],
    text: '''
Here are **safari-ready Swahili phrases** — people will love that you tried. 😊

| English | Swahili | Say it like |
|:--|:--|:--|
| How are you? | Habari yako? | ha-BAH-ree YAH-koh |
| I'm fine | Nzuri | n-ZOO-ree |
| Thank you very much | Asante sana | ah-SAHN-teh SAH-nah |
| How much is this? | Hii ni bei gani? | hee nee BAY GAH-nee |
| Slowly, slowly | Pole pole | POH-leh POH-leh |
| Let's go! | Twende! | TWEN-deh |

A few more for the game drive:

- **Simba** — lion 🦁
- **Tembo** — elephant 🐘
- **Twiga** — giraffe 🦒
- **Kiboko** — hippo

> *Hakuna matata* is real Swahili, but in Kenya you'll hear **“hakuna shida”** far more often.''',
    followUps: [
      'Quiz me on these',
      'Phrases for bargaining at a market',
      'Teach me numbers 1–10',
    ],
  );

  /// The SGR against a matatu, as a comparison table.
  static final sgr = KitoAiMockReply(
    keywords: const ['sgr', 'matatu', 'madaraka', 'compare'],
    text: '''
Both get you from Nairobi to Mombasa — the right one depends on what you value.

| | SGR (Madaraka Express) | Bus or matatu |
|:--|:--:|:--:|
| Time | ~6 hours | 8–10 hours |
| One way | KES 1,500 economy | KES 1,200–2,000 |
| Comfort | Reserved seat, AC | Varies a lot |
| Departures | 2–3 a day | Every hour |
| Scenery | Tsavo from the window 🐘 | Mombasa Road traffic |

**My pick:** the **SGR**, if you can book a day or two ahead. Take a bus if you need to leave at an odd hour or want to stop at Mtito Andei on the way.

1. Book on the Kenya Railways portal and pay with M-Pesa.
2. Arrive **an hour early** — security checks at the terminus take time.
3. Carry your ID; it's checked against the ticket.''',
    tools: [
      KitoAiToolCall(
          id: 'mock.search.sgr',
          name: 'web_search',
          runningTitle: 'Checking schedules and fares…',
          doneTitle: 'Checked schedules and fares',
          detail: '2 sources',
          symbol: 'train'),
    ],
    citations: [
      KitoAiCitation(
          id: 's1',
          title: 'Madaraka Express schedule',
          url: 'https://krc.co.ke'),
      KitoAiCitation(
          id: 's2',
          title: 'Booking and fares',
          url: 'https://metickets.krc.co.ke'),
    ],
    followUps: const [
      'What about flying?',
      'Which side has the Tsavo views?',
    ],
  );

  /// A chapati recipe.
  static const chapati = KitoAiMockReply(
    keywords: ['chapati', 'recipe', 'cook', 'ugali', 'pilau'],
    text: '''
### Soft, layered chapati (makes 8)

**You'll need**
- 3 cups all-purpose flour
- 1 tsp salt and 1 tbsp sugar
- 1 cup warm water
- 4 tbsp vegetable oil, plus more for the pan

**Method**
1. Mix the flour, salt and sugar, add the water and 2 tbsp oil, and knead for **10 minutes** until smooth.
2. Cover and rest the dough for 30 minutes.
3. Roll each ball flat, brush with oil, roll it into a rope and coil it like a snail. *This is where the layers come from.*
4. Rest 10 more minutes, then roll out to about 20 cm.
5. Cook on a hot pan for about a minute a side, brushing with a little oil, until golden spots appear.

> Serve with ndengu or beef stew — and keep them stacked under a kitchen towel so they stay soft.''',
    followUps: ['How do I make ndengu?', 'Can I use whole wheat flour?'],
  );

  /// A polite note to a landlord.
  static const landlord = KitoAiMockReply(
    keywords: ['landlord', 'email', 'draft', 'letter'],
    text: '''
Here's a polite, firm draft you can adapt:

> **Subject:** Leaking kitchen tap — Apartment B4, Kilimani
>
> Hi Mr. Otieno,
>
> I hope you're well. The kitchen tap in B4 has been leaking since **Monday 21 September**, and it's getting worse — water now pools under the sink overnight.
>
> Could you arrange for a plumber this week? I'm home after 5pm on weekdays, or any time on Saturday.
>
> Thank you,
> Wycliff

Want it more formal, or shall I add a line asking for September's rent receipt?''',
    followUps: ['Make it more formal', 'Translate it to Swahili'],
  );
}

class _Step {
  const _Step(this.delay, this.event, [this.error]);

  final Duration delay;
  final KitoAiStreamEvent? event;
  final Object? error;
}

/// A small seedable generator that behaves the same on the web (no 64-bit maths).
class _ParkMiller {
  _ParkMiller(int seed) : _state = (seed.abs() % 2147483646) + 1;

  int _state;

  double unit() {
    _state = (_state * 48271) % 2147483647;
    return (_state - 1) / 2147483646;
  }
}
