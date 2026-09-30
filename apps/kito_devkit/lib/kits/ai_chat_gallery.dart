// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kito_ui_ai_chat/kito_ui_ai_chat.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../catalog/catalog.dart';
import '../gallery/phone_frame.dart';

DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) => DateTime.now()
    .subtract(Duration(days: days, hours: hours, minutes: minutes));

const _mpesaSnippet = r'''final password = base64Encode(
  utf8.encode('$shortCode$passkey$timestamp'),
);

final response = await http.post(
  Uri.parse('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest'),
  headers: {'Authorization': 'Bearer $token'},
  body: jsonEncode({
    'BusinessShortCode': shortCode,
    'Password': password,
    'Timestamp': timestamp,
    'Amount': 1500, // KES
    'PhoneNumber': '2547XXXXXXXX',
  }),
);''';

const _richMarkdown = '''
## Nairobi to Naivasha 🚗

A **day trip** is easy: leave by 7am to beat the traffic on *Waiyaki Way*.

1. Breakfast at the viewpoint on the escarpment
2. Boat ride on Lake Naivasha — hippos are shy before 10am
3. Cycle through **Hell's Gate** (bring water!)

- [x] Book the boat
- [ ] Pack sunscreen

| Stop | Time | KES |
|:--|:-:|--:|
| Escarpment | 08:00 | 0 |
| Boat ride | 10:30 | 1,500 |
| Bike hire | 13:00 | 800 |

> Tip: fuel up in Limuru — stations thin out after Mai Mahiu.

Use `KitoAiMarkdownView` for any reply, or read more on [Magical Kenya](https://www.magicalkenya.com).''';

List<KitoAiConversation> _history() => [
      KitoAiConversation(
        id: 'mpesa',
        title: 'M-Pesa STK push callback',
        model: 'Pro',
        isPinned: true,
        messages: [
          KitoAiMessage.user('How do I handle the STK push callback?'),
          KitoAiMessage.assistant(
              'Expose an HTTPS endpoint and read `Body.stkCallback.ResultCode` — 0 means paid.'),
        ],
        updatedAt: _ago(days: 12),
      ),
      KitoAiConversation(
        id: 'diani',
        title: 'Weekend in Diani',
        model: 'Pro',
        messages: [
          KitoAiMessage.user('Plan a weekend in Diani'),
          KitoAiMessage.assistant(
              'Take the **SGR** on Friday morning, then the Likoni ferry.'),
        ],
        updatedAt: _ago(minutes: 25),
      ),
      KitoAiConversation(
        id: 'chapati',
        title: 'Soft layered chapati',
        messages: [
          KitoAiMessage.assistant(
              'Knead for 10 minutes and rest the dough for 30.'),
        ],
        updatedAt: _ago(days: 1, hours: 2),
      ),
      KitoAiConversation(
        id: 'swahili',
        title: 'Swahili for the safari',
        model: 'Fast',
        messages: [
          KitoAiMessage.assistant('**Pole pole** means slowly, slowly.'),
        ],
        updatedAt: _ago(days: 4),
      ),
      KitoAiConversation(
        id: 'landlord',
        title: 'Note to the landlord',
        messages: [
          KitoAiMessage.assistant(
              'Hi Mr. Otieno, the kitchen tap in B4 has been leaking since Monday…'),
        ],
        updatedAt: _ago(days: 18),
      ),
      KitoAiConversation(
        id: 'sgr',
        title: 'SGR vs matatu',
        messages: [
          KitoAiMessage.assistant('The SGR takes about six hours.'),
        ],
        updatedAt: _ago(days: 64),
      ),
    ];

KitoAiConversation _saved() {
  final start = _ago(minutes: 8);
  return KitoAiConversation(
    title: 'Madaraka Express fares',
    model: 'Kito Pro',
    messages: [
      KitoAiMessage.system('Switched to Kito Pro', date: start),
      KitoAiMessage.user('How much is the SGR to Mombasa this weekend?',
          date: start),
      KitoAiMessage(
        role: KitoAiRole.assistant,
        date: start.add(const Duration(seconds: 20)),
        feedback: KitoAiFeedback.positive,
        blocks: [
          KitoAiContentBlock.toolCall(KitoAiToolCall(
            id: 'fares',
            name: 'web_search',
            runningTitle: 'Checking fares…',
            doneTitle: 'Checked fares',
            detail: '2 sources',
            symbol: 'train',
            status: KitoAiToolStatus.done,
          )),
          const KitoAiContentBlock.markdown(
              'Economy is **KES 1,500** one way and First Class **KES 4,500**. '
              'Weekend trains fill up, so book a few days ahead and pay with M-Pesa.'),
          KitoAiContentBlock.citations([
            KitoAiCitation(
                id: 'krc', title: 'Madaraka Express', url: 'https://krc.co.ke'),
            KitoAiCitation(
                id: 'tickets',
                title: 'Booking',
                url: 'https://metickets.krc.co.ke'),
          ]),
        ],
        followUps: const ['Which train leaves earliest?', 'Is there Wi-Fi?'],
      ),
    ],
  );
}

/// The gallery for kito_ui_ai_chat.
final aiChatKit = KitEntry(
  title: 'AI Chat',
  package: 'kito_ui_ai_chat',
  blurb: 'streaming replies, markdown, code, tool chips and a composer',
  icon: Icons.auto_awesome_motion_rounded,
  category: KitCategory.communication,
  isNew: true,
  sections: [
    KitSection('Chat', Icons.forum_rounded, [
      KitSample(
        title: 'Assistant chat',
        subtitle:
            'Pick a starter: replies stream in with tools, sources, Stop and follow-ups.',
        code: '''final session = KitoAiChatSession(stream: KitoAiMockStream());

KitoAiChatView(
  session: session,
  userName: 'Wycliff N',
  onAttach: pickFile,
  accessory: KitoAiModelPicker(
    selected: model,
    onChanged: (id) => setState(() => model = id),
  ),
)''',
        builder: (_) => PhoneFrame(builder: (_) => const _ChatScreen()),
      ),
      KitSample(
        title: 'A failed reply',
        subtitle:
            'The first answer drops part-way; Retry asks again and it comes through.',
        code: '''final session = KitoAiChatSession(
  stream: KitoAiMockStream(failures: 1),
);
session.send('Soft chapati recipe');''',
        builder: (_) => PhoneFrame(
            builder: (_) => const _ChatScreen(
                failures: 1, autoSend: 'Soft chapati recipe', title: 'Retry')),
      ),
      KitSample(
        title: 'Saved history',
        subtitle:
            'A conversation restored from JSON: system note, tool chip, sources and a rating.',
        code: '''final conversation = KitoAiConversation.fromJson(saved);
final session = KitoAiChatSession(conversation: conversation);

KitoAiChatView(session: session)''',
        builder: (_) => PhoneFrame(
            builder: (_) => _ChatScreen(
                conversation: _saved(), title: 'Madaraka Express fares')),
      ),
    ]),
    KitSection('Streaming', Icons.stream_rounded, [
      KitSample(
        title: 'Any Stream<String>',
        subtitle:
            'Tokens from a local stream render as markdown with a cursor, then settle.',
        code: '''KitoAiStreamingMarkdown(
  stream: client.streamText(prompt),   // any Stream<String>
  onDone: (text) => save(text),
)''',
        builder: (_) => const _LocalStream(),
      ),
      KitSample(
        title: 'No flicker',
        subtitle:
            'Scrub through a reply: raw text on top, what the assembler shows below.',
        code:
            '''KitoAiStreamAssembler.displayTextFor(partial, isStreaming: true);
// "Take the **SG"  →  "Take the **SG**"
// "| Stop | KES |"  →  held until the |---| row arrives''',
        builder: (_) => const _Scrubber(),
      ),
      KitSample(
        title: 'Markdown',
        subtitle:
            'Headings, lists, tasks, a table, a quote, inline code and links.',
        code: '''KitoAiMarkdownView(reply, onLinkTap: launch)''',
        builder: (_) => KitoAiMarkdownView(_richMarkdown, onLinkTap: (_) {}),
      ),
      KitSample(
        title: 'Code block',
        subtitle: 'Syntax colours, sideways scrolling and Copy with a check.',
        code: '''KitoAiCodeBlock(code: snippet, language: 'dart')''',
        builder: (_) =>
            const KitoAiCodeBlock(code: _mpesaSnippet, language: 'dart'),
      ),
    ]),
    KitSection('Pieces', Icons.widgets_rounded, [
      KitSample(
        title: 'Orb and thinking',
        subtitle: 'The orb breathes while working and drifts when idle.',
        code: '''const KitoAiOrb(size: 72)
const KitoAiOrb(size: 40, isActive: false)
const KitoAiThinkingIndicator(label: 'Reading your M-Pesa statement')''',
        builder: (_) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                KitoAiOrb(size: 72),
                SizedBox(width: 24),
                KitoAiOrb(size: 40, isActive: false),
                SizedBox(width: 24),
                KitoAiOrb(size: 40, tint: Color(0xFFF58C29)),
              ],
            ),
            SizedBox(height: 24),
            KitoAiThinkingIndicator(label: 'Reading your M-Pesa statement'),
          ],
        ),
      ),
      KitSample(
        title: 'Tool chips',
        subtitle: 'Running with a sweep, done with a detail, or stopped.',
        code: '''KitoAiToolChip(call: KitoAiToolCall.webSearch())
KitoAiToolChip(call: call.withStatus(KitoAiToolStatus.done, detail: '4 sources'))''',
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KitoAiToolChip(call: KitoAiToolCall.webSearch(id: 'a')),
            const SizedBox(height: 10),
            KitoAiToolChip(
                call: KitoAiToolCall.webSearch(id: 'b')
                    .withStatus(KitoAiToolStatus.done, detail: '4 sources')),
            const SizedBox(height: 10),
            KitoAiToolChip(
                call: KitoAiToolCall(
                        id: 'c',
                        name: 'read_docs',
                        runningTitle: 'Reading the Daraja docs…',
                        doneTitle: 'Read the Daraja docs',
                        symbol: 'book')
                    .withStatus(KitoAiToolStatus.failed)),
          ],
        ),
      ),
      KitSample(
        title: 'Sources and follow-ups',
        subtitle: 'Numbered source chips and next-step prompts with arrows.',
        code:
            '''KitoAiCitationChips(citations: message.citations, onSelect: open)
KitoAiFollowUpChips(suggestions: session.followUps, onSelect: session.send)''',
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KitoAiCitationChips(citations: [
              KitoAiCitation(
                  id: '1',
                  title: 'Kisite-Mpunguti',
                  url: 'https://www.kws.go.ke'),
              KitoAiCitation(
                  id: '2',
                  title: 'Madaraka Express',
                  url: 'https://metickets.krc.co.ke'),
              KitoAiCitation(
                  id: '3',
                  title: 'Diani Beach',
                  url: 'https://www.magicalkenya.com'),
            ], onSelect: (_) {}),
            const SizedBox(height: 16),
            KitoAiFollowUpChips(suggestions: const [
              'Make it a budget trip under KES 15,000',
              'What should I pack?',
            ], onSelect: (_) {}),
          ],
        ),
      ),
      KitSample(
        title: 'Welcome and starters',
        subtitle: 'An empty chat greets by time of day with prompt cards.',
        code: '''KitoAiWelcome(name: 'Amina Wanjiru')
KitoAiSuggestedPrompts(onSelect: (s) => session.send(s.prompt))''',
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KitoAiWelcome(name: 'Amina Wanjiru'),
            const SizedBox(height: 20),
            KitoAiSuggestedPrompts(onSelect: (_) {}),
          ],
        ),
      ),
      KitSample(
        title: 'Reply with actions',
        subtitle:
            'Copy, thumbs and Regenerate under a reply; an error with Retry.',
        code: '''KitoAiMessageView(
  message: reply,
  onFeedback: (f) => session.setFeedback(f, reply.id),
  onRegenerate: session.regenerate,
)
KitoAiErrorBubble(message: 'The connection was lost…', onRetry: session.retry)''',
        builder: (_) => const _Actions(),
      ),
    ]),
    KitSection('Composer', Icons.edit_note_rounded, [
      KitSample(
        title: 'Prompt composer',
        subtitle:
            'Chips while empty, files, a model picker, and Send that morphs into Stop.',
        code: '''KitoAiComposer(
  onSend: send,
  isGenerating: generating,
  onStop: stop,
  onAttach: pickFile,
  attachments: files,
  onRemoveAttachment: remove,
  suggestions: const ['Plan a weekend in Diani', 'Explain M-Pesa'],
  accessory: KitoAiModelPicker(selected: model, onChanged: pick),
)''',
        builder: (_) => const _Composer(),
      ),
      KitSample(
        title: 'Model picker',
        subtitle: 'A capsule that opens a sheet of models.',
        code: '''KitoAiModelPicker(
  models: KitoAiModelOption.defaults,
  selected: model,
  onChanged: (id) => setState(() => model = id),
)''',
        builder: (_) => const _Models(),
      ),
    ]),
    KitSection('Conversations', Icons.history_rounded, [
      KitSample(
        title: 'Conversation list',
        subtitle:
            'Pinned, Today, Yesterday… with search; long-press to pin or delete.',
        code: '''KitoAiConversationList(
  conversations: history,
  selectedId: openId,
  onSelect: open,
  onNewChat: startChat,
  onTogglePin: pin,
  onDelete: delete,
)''',
        builder: (_) => const SizedBox(height: 520, child: _History()),
      ),
    ]),
  ],
);

class _ChatScreen extends StatefulWidget {
  const _ChatScreen(
      {this.failures = 0, this.autoSend, this.conversation, this.title});

  final int failures;
  final String? autoSend;
  final KitoAiConversation? conversation;
  final String? title;

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  late final KitoAiChatSession _session = KitoAiChatSession(
    conversation: widget.conversation,
    stream: KitoAiMockStream(failures: widget.failures),
  );
  String _model = 'pro';
  int _files = 0;

  static const _attachments = [
    ('Itinerary.pdf', KitoAiAttachmentKind.pdf, 482000),
    ('Budget.xlsx', KitoAiAttachmentKind.spreadsheet, 18400),
    ('Galu beach.jpg', KitoAiAttachmentKind.image, 1240000),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoSend case final prompt?) _session.send(prompt);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _attach() {
    final (name, kind, size) = _attachments[_files++ % _attachments.length];
    _session.attach(KitoAiAttachment(name: name, kind: kind, byteCount: size));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        surfaceTintColor: Colors.transparent,
        title: ListenableBuilder(
          listenable: _session,
          builder: (context, _) => Text(
            widget.title ??
                (_session.messages.isEmpty
                    ? 'Kito Assistant'
                    : _session.conversation.displayTitle),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.edit_square),
            onPressed: () => _session.reset(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: KitoAiChatView(
          session: _session,
          userName: 'Wycliff N',
          onAttach: _attach,
          accessory: KitoAiModelPicker(
            selected: _model,
            onChanged: (id) {
              setState(() => _model = id);
              final name =
                  KitoAiModelOption.defaults.firstWhere((m) => m.id == id).name;
              _session.setModel(name);
            },
          ),
        ),
      ),
    );
  }
}

class _LocalStream extends StatefulWidget {
  const _LocalStream();

  @override
  State<_LocalStream> createState() => _LocalStreamState();
}

class _LocalStreamState extends State<_LocalStream> {
  static const _text = '''
### Matatu etiquette 🚐

- Say **"shukisha"** a stop early so the conductor can call it.
- Keep small notes: fares run *KES 50–100* across town.
- Pay with M-Pesa where you see a `Till` sticker.''';

  late Stream<String> _stream = _tokens();
  bool _done = false;

  Stream<String> _tokens() {
    final words =
        RegExp(r'\S+\s*').allMatches(_text).map((m) => m[0]!).toList();
    return Stream<String>.periodic(
        const Duration(milliseconds: 45), (i) => words[i]).take(words.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150),
          child: KitoAiStreamingMarkdown(
            stream: _stream,
            onDone: (_) => setState(() => _done = true),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: _done
                ? () => setState(() {
                      _done = false;
                      _stream = _tokens();
                    })
                : null,
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Replay'),
          ),
        ),
      ],
    );
  }
}

class _Scrubber extends StatefulWidget {
  const _Scrubber();

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  static const _text = '''Take the **SGR** to Mombasa, then the `Likoni` ferry.

| Stop | KES |
|:--|--:|
| Ferry | 0 |''';

  double _at = 21;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final partial = _text.substring(0, _at.round());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('RAW', style: theme.typography.caption),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 90),
          decoration: BoxDecoration(
            color: theme.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(theme.radii.md),
          ),
          child: Text(partial,
              style: theme.typography.label.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Menlo', 'Courier New'])),
        ),
        const SizedBox(height: 12),
        Text('WHAT READERS SEE', style: theme.typography.caption),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: KitoAiMarkdownView(partial, isStreaming: _at < _text.length),
        ),
        Slider(
          value: _at,
          min: 1,
          max: _text.length.toDouble(),
          label: '${_at.round()} characters',
          onChanged: (v) => setState(() => _at = v),
        ),
      ],
    );
  }
}

class _Actions extends StatefulWidget {
  const _Actions();

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  KitoAiFeedback _feedback = KitoAiFeedback.none;
  int _regenerated = 0;

  @override
  Widget build(BuildContext context) {
    final reply = KitoAiMessage(
      id: 'reply',
      role: KitoAiRole.assistant,
      feedback: _feedback,
      blocks: [
        KitoAiContentBlock.markdown(_regenerated == 0
            ? '**Pole pole** means *slowly, slowly* — you will hear it on every hike up Longonot.'
            : '**Pole pole** — "slowly, slowly". Guides say it so you pace yourself on the climb.'),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitoAiMessageView(
          message: KitoAiMessage.user('What does pole pole mean?'),
          onEdit: () {},
        ),
        const SizedBox(height: 20),
        KitoAiMessageView(
          message: reply,
          onFeedback: (f) => setState(
              () => _feedback = _feedback == f ? KitoAiFeedback.none : f),
          onRegenerate: () => setState(() => _regenerated++),
        ),
        const SizedBox(height: 20),
        KitoAiErrorBubble(
            message: KitoAiStreamError.networkLost.message, onRetry: () {}),
      ],
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  String _model = 'fast';
  bool _generating = false;
  String? _last;
  Timer? _timer;
  List<KitoAiAttachment> _files = [
    KitoAiAttachment(
        name: 'Nairobi rent receipt.pdf',
        kind: KitoAiAttachmentKind.pdf,
        byteCount: 212000),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _send(String text) {
    setState(() {
      _last = text;
      _generating = true;
      _files = [];
    });
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _generating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: theme.motion.fast,
          child: Text(
            _last == null
                ? 'Nothing sent yet'
                : _generating
                    ? 'Generating a reply to “$_last”…'
                    : 'Sent “$_last”',
            key: ValueKey('$_last$_generating'),
            style: theme.typography.caption
                .copyWith(color: theme.colors.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        const SizedBox(height: 12),
        KitoAiComposer(
          onSend: _send,
          isGenerating: _generating,
          onStop: () {
            _timer?.cancel();
            setState(() => _generating = false);
          },
          onAttach: () => setState(() => _files = [
                ..._files,
                KitoAiAttachment(
                    name: 'Safari photo ${_files.length + 1}.jpg',
                    kind: KitoAiAttachmentKind.image,
                    byteCount: 1800000),
              ]),
          attachments: _files,
          onRemoveAttachment: (a) =>
              setState(() => _files = [..._files.where((f) => f.id != a.id)]),
          suggestions: const [
            'Plan a weekend in Diani',
            'Explain M-Pesa STK push',
            'Swahili for the market',
          ],
          accessory: KitoAiModelPicker(
              selected: _model, onChanged: (id) => setState(() => _model = id)),
        ),
      ],
    );
  }
}

class _Models extends StatefulWidget {
  const _Models();

  @override
  State<_Models> createState() => _ModelsState();
}

class _ModelsState extends State<_Models> {
  String _model = 'pro';

  @override
  Widget build(BuildContext context) {
    final picked = KitoAiModelOption.defaults.firstWhere((m) => m.id == _model);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KitoAiModelPicker(
            selected: _model, onChanged: (id) => setState(() => _model = id)),
        const SizedBox(height: 12),
        Text(picked.detail, style: context.kito.typography.caption),
      ],
    );
  }
}

class _History extends StatefulWidget {
  const _History();

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  late List<KitoAiConversation> _chats = _history();
  String? _open = 'diani';
  int _new = 0;

  @override
  Widget build(BuildContext context) {
    return KitoAiConversationList(
      conversations: _chats,
      selectedId: _open,
      onSelect: (c) => setState(() => _open = c.id),
      onNewChat: () => setState(() {
        final chat = KitoAiConversation(
            id: 'new-${_new++}', title: 'New chat', updatedAt: DateTime.now());
        _chats = [chat, ..._chats];
        _open = chat.id;
      }),
      onTogglePin: (c) => setState(() => _chats = [
            for (final x in _chats)
              x.id == c.id ? x.copyWith(isPinned: !x.isPinned) : x,
          ]),
      onDelete: (c) =>
          setState(() => _chats = [..._chats.where((x) => x.id != c.id)]),
    );
  }
}
