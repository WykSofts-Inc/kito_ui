# kito_ui_ai_chat

An AI chat UI for Flutter that works with any model: streaming replies with markdown, code
blocks and tables, tool-use chips, sources, Stop, Regenerate, feedback, edit-and-resend, a
composer with suggestion chips and a model picker, a conversation list and a welcome screen.
Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything follows `KitoTheme`
(light, dark, neon), right-to-left layouts, text scaling and Reduce Motion.

It has no network code or SDK dependency of its own — you connect your provider by handing it a
stream of tokens — and no native plugins, so there's no platform setup.

## Install

```yaml
dependencies:
  kito_ui_ai_chat: ^0.1.0
```

```dart
import 'package:kito_ui_ai_chat/kito_ui_ai_chat.dart';
```

## A chat in one widget

```dart
final session = KitoAiChatSession(stream: KitoAiMockStream());

KitoAiChatView(session: session, userName: 'Wycliff N')

// dispose() the session with the screen
```

`KitoAiMockStream` types out canned replies with realistic jitter, runs a web search first when
it fits, and cites sources, so the whole UI works in demos before you connect a model. Ask it
about a weekend in Diani, M-Pesa STK push in Dart, Swahili phrases, the SGR or a matatu,
chapati, or a note to your landlord.

What you get:

- An empty conversation opens on an animated orb, "Good evening, Wycliff" and starter prompt
  cards.
- Replies stream in token by token with a cursor. Unfinished markdown is held back for a moment,
  so a lone `#`, `**bo` or a table header never flashes up as plain text first.
- "Thinking…" with a light sweep until the first token; tool chips go from "Searching the web…"
  to "Searched the web · 4 sources".
- Send morphs into Stop while a reply is generating. Stopped replies keep what arrived.
- Under each reply: Copy, 👍, 👎 and Regenerate. Under your last message: Copy and Edit — edit it
  and send, and the conversation continues from there.
- A failed reply shows what went wrong and a Retry button.
- Follow-up chips after the latest reply.
- The conversation follows new text as it streams, stops following the moment you scroll up, and
  offers a "Jump to latest" pill.

## Connect your model

Implement `KitoAiStream` and yield events as they arrive:

```dart
class MyBackend implements KitoAiStream {
  @override
  Stream<KitoAiStreamEvent> reply(KitoAiConversation conversation) async* {
    await for (final chunk in api.stream(conversation.messages)) {
      yield KitoAiStreamEvent.token(chunk.text);
    }
    yield const KitoAiStreamEvent.followUps(['Tell me more']);
  }
}

KitoAiChatSession(stream: MyBackend());
```

Events are `.token(String)`, `.toolCall(KitoAiToolCall)` (send the same `id` again with
`KitoAiToolStatus.done` to finish it), `.citations([...])`, `.image(KitoAiImage)` and
`.followUps([...])`. Stopping a reply cancels the subscription. Throw a `KitoAiStreamError` for a
friendly message in the error bubble.

Already have a `Stream<String>`? Wrap it:

```dart
final stream = KitoAiTokenStream((conversation) => client.streamText(conversation.messages));
```

## The session

`KitoAiChatSession` is a `ChangeNotifier` holding the state behind the view, so you can drive it
yourself and test it without widgets:

```dart
session.send('Plan a weekend in Diani');
session.stop();
session.regenerate();
session.retry();
session.beginEditing();                    // returns the last message's text
session.setFeedback(KitoAiFeedback.positive, messageId);
session.attach(KitoAiAttachment(name: 'Itinerary.pdf', kind: KitoAiAttachmentKind.pdf, byteCount: 482000));
session.onReplyFinished = (_) => save(session.conversation.toJson());
session.reset();                           // or reset(savedConversation)
```

`KitoAiConversation`, `KitoAiMessage` and every content block have `toJson` / `fromJson`, so
saving history is one `jsonEncode` away. The first message titles the conversation ("Hey, can you
help me plan a weekend in Diani?" becomes "Plan a weekend in Diani").

## Messages

```dart
KitoAiMessage.user('Compare the SGR and a matatu', attachments: [file]);
KitoAiMessage.assistant('## Weekend in Diani\nTake the **SGR** …');
KitoAiMessage(role: KitoAiRole.assistant, blocks: [
  KitoAiContentBlock.toolCall(KitoAiToolCall.webSearch().withStatus(KitoAiToolStatus.done, detail: '4 sources')),
  KitoAiContentBlock.markdown(text),
  KitoAiContentBlock.code(snippet, language: 'dart'),
  KitoAiContentBlock.citations([KitoAiCitation(title: 'Magical Kenya', url: 'https://www.magicalkenya.com')]),
]);
KitoAiMessage.system('Switched to Kito Pro');
```

Roles are `user`, `assistant`, `system` (a centred caption) and `tool` (a collapsed result).

## Rendering

```dart
KitoAiMarkdownView(reply)                              // headings, lists, tasks, quotes, tables, rules, code
KitoAiMarkdownView(partial, isStreaming: true)         // holds back unfinished syntax, shows a cursor
KitoAiStreamingMarkdown(stream: tokens)                // any Stream<String>, Thinking… until the first token
KitoAiCodeBlock(code: code, language: 'dart')          // language label, Copy, syntax colours, sideways scroll
KitoAiMessageView(message: m, onRegenerate: …, onFeedback: …)
```

## Pieces

```dart
KitoAiWelcome(name: 'Wycliff N')
KitoAiOrb(size: 64, isActive: true)
KitoAiThinkingIndicator()
KitoAiToolChip(call: KitoAiToolCall.webSearch())
KitoAiCitationChips(citations: message.citations, onSelect: open)
KitoAiSuggestedPrompts(onSelect: (s) => session.send(s.prompt))
KitoAiFollowUpChips(suggestions: session.followUps, onSelect: session.send)
KitoAiAttachmentChip(attachment: file, onRemove: () => remove(file))
KitoAiErrorBubble(message: 'The connection was lost.', onRetry: session.retry)
KitoAiStreamingCursor()
KitoAiShimmer(child: Text('Reading your file…'))
```

## Composer and model picker

```dart
KitoAiComposer(
  onSend: send,
  isGenerating: generating,
  onStop: stop,
  onAttach: pickFile,
  attachments: files,
  onRemoveAttachment: remove,
  suggestions: const ['Plan a weekend in Diani', 'Explain M-Pesa'],
  accessory: KitoAiModelPicker(
    models: KitoAiModelOption.defaults,
    selected: model,
    onChanged: (id) => setState(() => model = id),
  ),
)
```

The field grows to eight lines and shows a token estimate for long prompts. Enter sends from a
hardware keyboard and Shift+Enter adds a line. Suggestion chips show while the field is empty.

## Conversation list

```dart
KitoAiConversationList(
  conversations: history,
  selectedId: openId,
  onSelect: open,
  onNewChat: startChat,
  onTogglePin: pin,
  onDelete: delete,
)
```

Conversations are grouped into Pinned, Today, Yesterday, Previous 7 days, Previous 30 days and one
section per month, and the search field matches titles and the latest text. Long-press a row (or
use the screen-reader actions) to pin or delete.

## Logic without UI

```dart
KitoAiMarkdown.blocks(text);                                 // [heading, paragraph, list, code, table, …]
KitoAiMarkdown.plainText(text);                              // markdown stripped, for previews
KitoAiInlineMarkdown.runs('Take the **SGR**');               // styled runs
KitoAiStreamAssembler.displayTextFor(partial, isStreaming: true);
KitoAiTitle.make('Hey, can you help me plan a weekend in Diani?');   // "Plan a weekend in Diani"
KitoAiTextStats.estimatedTokens(text);                       // provider-neutral estimate
KitoAiGreeting.text(name: 'Wycliff N');                      // "Good evening, Wycliff"
KitoAiConversationGrouping.sections(history);
KitoAiDateFormat.rowTimestamp(date);                         // "14:05", "Yesterday", "Mon", "12 Sep"
KitoAiSyntaxHighlighter.tokens(code, language: 'dart');
KitoAiAutoScrollPolicy()..observe(distanceFromBottom: 420, contentHeight: 2000, viewportHeight: 700);
```

## Testing

`KitoAiMockStream(instant: true)` sends a whole reply through microtasks with no timers, and the
timed mock cancels its timers when the subscription is cancelled, so widget tests never leave
anything pending. `KitoAiMockStream(failures: 1)` makes the first reply fail part-way; `seed:`
repeats the same jitter.

## Right-to-left and accessibility

Everything mirrors with the text direction: bubbles, chips, the composer, the list, the orb's
drift and the shimmer sweep. Table columns map `:--` / `--:` to the start / end edge. Code blocks
keep their source left-to-right while the header mirrors. Replies, chips and code blocks have
screen-reader labels, messages offer Copy (and Edit) as actions, tap targets are at least 44
points, and the orb, shimmer, cursor and entrances hold still with Reduce Motion.

## License

MIT — see [LICENSE](LICENSE).
