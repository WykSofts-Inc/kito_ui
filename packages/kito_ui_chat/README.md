# kito_ui_chat

Chat UI for Flutter: a conversation view with grouped bubbles in four styles, date separators
and a floating day pill, an "N unread" divider, read receipts, reactions, swipe to reply, voice
notes with a scrubbable waveform, photos that open full screen, a composer with hold-to-record,
typing indicators, a conversation header and an inbox with swipe actions. Part of
[Kito UI](https://github.com/WykSofts-Inc/kito_ui); everything follows `KitoTheme` (light, dark,
neon), right-to-left layouts, text scaling and Reduce Motion.

The kit is UI only. It ships no audio plugin: voice recording and playback go through two small
adapters you implement with the packages you already use. Without them the composer records a
clearly labelled simulated preview and voice notes play through a simulated timeline, so there
is no platform setup.

## Install

```yaml
dependencies:
  kito_ui_chat: ^0.1.0
```

```dart
import 'package:kito_ui_chat/kito_ui_chat.dart';
```

## Quick start

```dart
const me = KitoChatUser(id: 'wycliff', name: 'Wycliff N');
const amani = KitoChatUser(id: 'amani', name: 'Amani Wanjiru', isOnline: true);

final chat = KitoChatController(messages: [
  KitoChatMessage.text('Habari! Tuonane Java saa saba?', author: amani),
]);

KitoChatView(
  controller: chat,
  currentUser: me,
  onSend: (message) async {
    await api.send(message);
    chat.updateStatus(message.id, KitoChatMessageStatus.delivered);
  },
)
```

The view edits the controller itself: sending appends a `sending` message, reactions and
deletes update it, and a failed message offers **Tap to retry**. Every new message (and every
retry) is handed to `onSend` so you can deliver it and move its status on.

## Conversation view

```dart
KitoChatView(
  controller: chat,
  currentUser: me,
  style: KitoChatBubbleStyle.imessage,   // modern, minimal, glass, imessage
  wallpaper: KitoChatWallpaper.aurora,   // plain, aurora, dots
  unreadCount: 3,                        // divider before the last 3 incoming, opens there
  tint: Colors.teal,
  onAttach: pickPhoto,                   // shows the composer's attach button
  onLinkTap: launch,
)
```

- Messages from one person within `groupingInterval` (5 minutes) group into one run: tighter
  corners, one tail, one avatar. Group chats show names and avatars automatically.
- Days are separated ("Today", "Yesterday", "Monday", "Sat 12 Sep"), and a pill shows the day
  you're scrolling through.
- Long-press a bubble to lift it with a reaction bar and Reply / Copy / Delete; swipe it toward
  the trailing edge to reply; tap it to reveal its time; tap a quote to jump to the original.
- A scroll-to-latest button appears when you scroll up and counts messages that arrive.
- New messages slide in from their side; deleted ones collapse away.

Typing users come from the controller:

```dart
chat.typingUsers = [amani];     // bouncing dots in the list and "Amani is typing…" in the header
chat.typingUsers = [];
```

## Messages

```dart
KitoChatMessage.text('Sawa, nitafika **mapema** 🙏', author: me,
    status: KitoChatMessageStatus.read);

KitoChatMessage(
  id: 'p1',
  author: amani,
  content: KitoChatImageContent(KitoChatImage(
      NetworkImage(url), aspectRatio: 4 / 3, caption: 'Diani 🌅')),
);

KitoChatMessage(
  id: 'v1',
  author: amani,
  content: KitoChatVoiceContent(duration: Duration(seconds: 9), url: fileUri),
);

KitoChatMessage(id: 's1', author: me, content: KitoChatSystemContent('Amani joined'));
```

Text supports `**bold**`, `*italic*` / `_italic_`, `~~strike~~`, `` `code` `` and links, which
are detected automatically (`KitoChatMarkdown.parse`). A message of one to three emoji is shown
large without a bubble. Replies carry a `KitoChatReply` quote, reactions a list of
`KitoChatReaction('😂', userIds: [...])`.

`KitoChatController` also offers `add`, `addAll`, `prepend` (older history), `replaceAll`,
`update`, `toggleReaction`, `remove` and `byId`.

## Composer

```dart
KitoChatComposer(
  replyTo: replyingTo,
  onCancelReply: () => setState(() => replyingTo = null),
  onSend: (content) => send(content),    // KitoChatTextContent or KitoChatVoiceContent
  onAttach: pickPhoto,
  recorder: myRecorder,                  // optional
)
```

The field grows with its text and the microphone morphs into a paper plane as you type. Hold
the microphone to record: slide toward the leading edge to cancel, slide up to lock and keep
recording hands-free, then send or delete. A quick tap explains how to record.

## Voice notes

Implement the two adapters with your audio packages (for example `record` and `just_audio`):

```dart
class MyRecorder implements KitoChatVoiceRecorder {
  @override
  Future<KitoChatRecordingStart> start() async { /* ask permission, start */ }
  @override
  Stream<double> get levels => /* loudness 0–1, ~20 times a second */;
  @override
  Future<Uri?> stop() async { /* return the file */ }
  @override
  Future<void> cancel() async {}
  @override
  bool get isSimulated => false;
}

KitoChatView(
  controller: chat,
  currentUser: me,
  recorder: MyRecorder(),
  audioPlayer: () => MyAudioPlayer(),  // implements KitoChatAudioPlayer
)
```

Without a recorder the composer uses `KitoChatSimulatedRecorder` and marks the recording
"Preview"; pass `simulatesRecordingWhenUnavailable: false` to explain that the microphone is off
instead. Voice notes play, pause, scrub along the waveform and cycle 1× / 1.5× / 2×; without a
player or URL they play through a simulated timeline.

## Pieces

Everything the view is made of can be used on its own:

```dart
KitoChatHeader(user: amani, typingUsers: typing, onBack: () => Navigator.pop(context));
KitoChatBubble(message, isOutgoing: true, style: KitoChatBubbleStyle.glass);
KitoChatStatusTicks(KitoChatMessageStatus.read);
KitoChatTypingIndicator();
KitoChatAvatar(amani, size: 40);
KitoChatVoiceNote(voice: voice);
KitoChatWaveformView(samples: levels, progress: 0.4);
KitoChatDateSeparator('Today');
KitoChatUnreadDivider(count: 2);
KitoChatWallpaperView(wallpaper: KitoChatWallpaper.dots);
```

`KitoChatTimeline` (grouping, day sections, the unread divider) and `KitoChatDateFormat` are
pure and covered by unit tests.

## Inbox

```dart
KitoChatList(
  conversations: conversations,
  currentUserId: me.id,
  onSelect: open,
  onChanged: (next) => setState(() => conversations = next),
)
```

Pinned conversations lead, unread counts show as badges, muted ones get a bell-slash, and a
row shows "typing…" while someone types. Swipe a row to reveal its actions: read / unread and
pin on the leading edge, mute and delete on the trailing edge. Turn actions off with
`allowsRead`, `allowsPin`, `allowsMute` and `allowsDelete`; without `onChanged` no swipe actions
show. `KitoChatSwipeActions` gives any row the same behaviour.

## Strings

English, Swahili and French are bundled and follow the app's `Locale`. Supply your own
translations (or override any string) with a provider:

```dart
KitoChatStrings.provider = (key, locale) => myTranslations[locale.languageCode]?[key];
```

## Right-to-left and accessibility

Everything mirrors in right-to-left layouts: your bubbles sit on the left with their tails,
swipe-to-reply and the inbox actions follow the reading direction, slide-to-cancel runs toward
the leading edge and waveforms fill from the right. Every bubble reads as one sentence
("Amani Wanjiru: Habari!, 10:24") with its status as the value, and offers Reply, React, Copy
and Delete as screen-reader actions. Buttons are 44 points or larger. Reduce Motion turns the
slides, lifts, bounces and aurora into plain changes.

## License

MIT — see [LICENSE](LICENSE).
