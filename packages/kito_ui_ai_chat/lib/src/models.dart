// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, IconData;

import 'markdown.dart';
import 'stream.dart';
import 'text.dart';

int _idCounter = 0;
final math.Random _idRandom = math.Random();

/// A new unique id for a message, conversation, tool call or attachment.
String kitoAiNewId() {
  _idCounter = (_idCounter + 1) % 0x7FFFFFFF;
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = _idRandom.nextInt(0x7FFFFFFF).toRadixString(36);
  return '$time-${_idCounter.toRadixString(36)}-$noise';
}

bool _listEquals<T>(List<T> a, List<T> b) => listEquals(a, b);

/// Who wrote a message.
enum KitoAiRole {
  /// The person using the app.
  user,

  /// The model.
  assistant,

  /// A notice from the app or the model ("Switched to Kito Pro"), shown as a centred caption.
  system,

  /// The output of a tool the assistant called. Shown collapsed.
  tool,
}

/// A picture inside a message: a remote [url], or encoded image [bytes] (PNG or JPEG).
@immutable
class KitoAiImage {
  /// Creates an image; [id] defaults to a new unique id.
  KitoAiImage({
    String? id,
    this.url,
    this.bytes,
    this.aspectRatio = 4 / 3,
    this.altText,
  }) : id = id ?? kitoAiNewId();

  /// Identifies the image.
  final String id;

  /// Where to load it from.
  final String? url;

  /// The encoded image, when it's local.
  final Uint8List? bytes;

  /// Width divided by height, used to size the image before it loads.
  final double aspectRatio;

  /// Read by screen readers.
  final String? altText;

  /// A JSON-friendly map.
  Map<String, Object?> toJson() => {
        'id': id,
        if (url != null) 'url': url,
        if (bytes != null) 'bytes': base64Encode(bytes!),
        'aspectRatio': aspectRatio,
        if (altText != null) 'altText': altText,
      };

  /// Reads [toJson]'s output.
  factory KitoAiImage.fromJson(Map<String, Object?> json) => KitoAiImage(
        id: json['id'] as String?,
        url: json['url'] as String?,
        bytes: json['bytes'] is String
            ? base64Decode(json['bytes']! as String)
            : null,
        aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 4 / 3,
        altText: json['altText'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoAiImage &&
      other.id == id &&
      other.url == url &&
      other.aspectRatio == aspectRatio &&
      other.altText == altText;

  @override
  int get hashCode => Object.hash(id, url, aspectRatio, altText);
}

/// Where a tool call has got to.
enum KitoAiToolStatus {
  /// Still working.
  running,

  /// Finished.
  done,

  /// Stopped or failed before finishing.
  failed,
}

/// A tool the assistant is using — shown as a chip that reads "Searching the web…" while it runs
/// and "Searched the web · 5 sources" once it's done.
@immutable
class KitoAiToolCall {
  /// Creates a tool call; [id] defaults to a new unique id.
  KitoAiToolCall({
    String? id,
    required this.name,
    required this.runningTitle,
    required this.doneTitle,
    this.detail,
    this.symbol = 'wrench',
    this.status = KitoAiToolStatus.running,
  }) : id = id ?? kitoAiNewId();

  /// A web search chip.
  factory KitoAiToolCall.webSearch({String? id, String? query}) =>
      KitoAiToolCall(
        id: id,
        name: 'web_search',
        runningTitle: 'Searching the web…',
        doneTitle: 'Searched the web',
        detail: query,
        symbol: 'globe',
      );

  /// Identifies the call; send the same id again to update it.
  final String id;

  /// Your tool's identifier, e.g. `"web_search"`.
  final String name;

  /// Shown while running, e.g. "Searching the web…".
  final String runningTitle;

  /// Shown when finished, e.g. "Searched the web".
  final String doneTitle;

  /// A short result summary shown after the title, e.g. "5 sources".
  final String? detail;

  /// The chip's icon: `globe`, `book`, `code`, `train`, `map`, `calculator`, `image`, `file`,
  /// `calendar`, `sparkles` or `wrench` (the default for anything else).
  final String symbol;

  /// Where the call has got to.
  final KitoAiToolStatus status;

  /// The title that matches [status].
  String get title => switch (status) {
        KitoAiToolStatus.running => runningTitle,
        KitoAiToolStatus.done => doneTitle,
        KitoAiToolStatus.failed =>
          "${runningTitle.replaceAll('…', '').trim()} didn't finish",
      };

  /// A copy with a new status (and optionally a detail).
  KitoAiToolCall withStatus(KitoAiToolStatus status, {String? detail}) =>
      KitoAiToolCall(
        id: id,
        name: name,
        runningTitle: runningTitle,
        doneTitle: doneTitle,
        detail: detail ?? this.detail,
        symbol: symbol,
        status: status,
      );

  /// The Material icon for [symbol].
  IconData get icon => switch (symbol) {
        'globe' => Icons.public_rounded,
        'book' => Icons.menu_book_rounded,
        'code' => Icons.code_rounded,
        'train' => Icons.train_rounded,
        'map' => Icons.map_rounded,
        'calculator' => Icons.calculate_rounded,
        'image' => Icons.image_rounded,
        'file' => Icons.description_rounded,
        'calendar' => Icons.event_rounded,
        'sparkles' => Icons.auto_awesome_rounded,
        _ => Icons.build_rounded,
      };

  /// A JSON-friendly map.
  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'runningTitle': runningTitle,
        'doneTitle': doneTitle,
        if (detail != null) 'detail': detail,
        'symbol': symbol,
        'status': status.name,
      };

  /// Reads [toJson]'s output.
  factory KitoAiToolCall.fromJson(Map<String, Object?> json) => KitoAiToolCall(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        runningTitle: json['runningTitle'] as String? ?? '',
        doneTitle: json['doneTitle'] as String? ?? '',
        detail: json['detail'] as String?,
        symbol: json['symbol'] as String? ?? 'wrench',
        status: KitoAiToolStatus.values.asNameMap()[json['status']] ??
            KitoAiToolStatus.done,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoAiToolCall &&
      other.id == id &&
      other.name == name &&
      other.runningTitle == runningTitle &&
      other.doneTitle == doneTitle &&
      other.detail == detail &&
      other.symbol == symbol &&
      other.status == status;

  @override
  int get hashCode =>
      Object.hash(id, name, runningTitle, doneTitle, detail, symbol, status);
}

/// A source the answer draws on, shown as a numbered chip.
@immutable
class KitoAiCitation {
  /// Creates a citation; [id] defaults to a new unique id.
  KitoAiCitation({String? id, required this.title, this.url, this.source})
      : id = id ?? kitoAiNewId();

  /// Identifies the source; citations with the same id are merged.
  final String id;

  /// The page or document title.
  final String title;

  /// Where it lives.
  final String? url;

  /// Usually the site's domain; derived from [url] when null.
  final String? source;

  /// [source], or the url's host without "www.".
  String get displaySource {
    if (source case final s? when s.isNotEmpty) return s;
    final host = Uri.tryParse(url ?? '')?.host ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  /// A JSON-friendly map.
  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        if (url != null) 'url': url,
        if (source != null) 'source': source,
      };

  /// Reads [toJson]'s output.
  factory KitoAiCitation.fromJson(Map<String, Object?> json) => KitoAiCitation(
        id: json['id'] as String?,
        title: json['title'] as String? ?? '',
        url: json['url'] as String?,
        source: json['source'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoAiCitation &&
      other.id == id &&
      other.title == title &&
      other.url == url &&
      other.source == source;

  @override
  int get hashCode => Object.hash(id, title, url, source);
}

/// One piece of a message. Assistant replies are usually a single markdown block that streams in,
/// with tool calls, images and citations around it.
@immutable
sealed class KitoAiContentBlock {
  const KitoAiContentBlock();

  /// Markdown text — headings, lists, tables, fenced code and inline styles are all rendered.
  const factory KitoAiContentBlock.markdown(String text) =
      KitoAiMarkdownContent;

  /// A code block supplied separately from the text.
  const factory KitoAiContentBlock.code(String code, {String? language}) =
      KitoAiCodeContent;

  /// A picture.
  const factory KitoAiContentBlock.image(KitoAiImage image) =
      KitoAiImageContent;

  /// A tool chip.
  const factory KitoAiContentBlock.toolCall(KitoAiToolCall call) =
      KitoAiToolCallContent;

  /// A row of source chips.
  const factory KitoAiContentBlock.citations(List<KitoAiCitation> citations) =
      KitoAiCitationsContent;

  /// A JSON-friendly map.
  Map<String, Object?> toJson();

  /// Reads [toJson]'s output.
  static KitoAiContentBlock fromJson(Map<String, Object?> json) {
    final data = (json['data'] as Map?)?.cast<String, Object?>() ?? const {};
    switch (json['type']) {
      case 'code':
        return KitoAiCodeContent(data['code'] as String? ?? '',
            language: data['language'] as String?);
      case 'image':
        return KitoAiImageContent(KitoAiImage.fromJson(data));
      case 'toolCall':
        return KitoAiToolCallContent(KitoAiToolCall.fromJson(data));
      case 'citations':
        final list = (data['items'] as List?) ?? const [];
        return KitoAiCitationsContent([
          for (final item in list)
            KitoAiCitation.fromJson((item as Map).cast<String, Object?>()),
        ]);
      default:
        return KitoAiMarkdownContent(data['text'] as String? ?? '');
    }
  }
}

/// A markdown block.
final class KitoAiMarkdownContent extends KitoAiContentBlock {
  /// Wraps [text].
  const KitoAiMarkdownContent(this.text);

  /// The markdown.
  final String text;

  @override
  Map<String, Object?> toJson() => {
        'type': 'markdown',
        'data': {'text': text},
      };

  @override
  bool operator ==(Object other) =>
      other is KitoAiMarkdownContent && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A code block supplied separately from the text.
final class KitoAiCodeContent extends KitoAiContentBlock {
  /// Wraps [code].
  const KitoAiCodeContent(this.code, {this.language});

  /// The source.
  final String code;

  /// "dart", "swift", "json"…
  final String? language;

  @override
  Map<String, Object?> toJson() => {
        'type': 'code',
        'data': {'code': code, if (language != null) 'language': language},
      };

  @override
  bool operator ==(Object other) =>
      other is KitoAiCodeContent &&
      other.code == code &&
      other.language == language;

  @override
  int get hashCode => Object.hash(code, language);
}

/// A picture block.
final class KitoAiImageContent extends KitoAiContentBlock {
  /// Wraps [image].
  const KitoAiImageContent(this.image);

  /// The picture.
  final KitoAiImage image;

  @override
  Map<String, Object?> toJson() => {'type': 'image', 'data': image.toJson()};

  @override
  bool operator ==(Object other) =>
      other is KitoAiImageContent && other.image == image;

  @override
  int get hashCode => image.hashCode;
}

/// A tool chip block.
final class KitoAiToolCallContent extends KitoAiContentBlock {
  /// Wraps [call].
  const KitoAiToolCallContent(this.call);

  /// The call.
  final KitoAiToolCall call;

  @override
  Map<String, Object?> toJson() => {'type': 'toolCall', 'data': call.toJson()};

  @override
  bool operator ==(Object other) =>
      other is KitoAiToolCallContent && other.call == call;

  @override
  int get hashCode => call.hashCode;
}

/// A row of sources.
final class KitoAiCitationsContent extends KitoAiContentBlock {
  /// Wraps [citations].
  const KitoAiCitationsContent(this.citations);

  /// The sources, in order.
  final List<KitoAiCitation> citations;

  @override
  Map<String, Object?> toJson() => {
        'type': 'citations',
        'data': {
          'items': [for (final c in citations) c.toJson()],
        },
      };

  @override
  bool operator ==(Object other) =>
      other is KitoAiCitationsContent &&
      _listEquals(other.citations, citations);

  @override
  int get hashCode => Object.hashAll(citations);
}

/// Thumbs up or down on an assistant reply.
enum KitoAiFeedback {
  /// No rating.
  none,

  /// Thumbs up.
  positive,

  /// Thumbs down.
  negative,
}

/// What kind of file an attachment is.
enum KitoAiAttachmentKind {
  /// A photo or picture.
  image('Image', Icons.image_outlined),

  /// A text document.
  document('Document', Icons.description_outlined),

  /// A PDF.
  pdf('PDF', Icons.picture_as_pdf_outlined),

  /// Source code.
  code('Code', Icons.code_rounded),

  /// A spreadsheet.
  spreadsheet('Spreadsheet', Icons.table_chart_outlined),

  /// A recording.
  audio('Audio', Icons.graphic_eq_rounded);

  const KitoAiAttachmentKind(this.label, this.icon);

  /// "PDF", "Image"…
  final String label;

  /// The icon shown on the chip.
  final IconData icon;
}

/// A file attached to a user message (or waiting in the composer).
@immutable
class KitoAiAttachment {
  /// Creates an attachment; [id] defaults to a new unique id.
  KitoAiAttachment({
    String? id,
    required this.name,
    required this.kind,
    this.byteCount,
    this.thumbnail,
  }) : id = id ?? kitoAiNewId();

  /// Identifies the file.
  final String id;

  /// The file name.
  final String name;

  /// What kind of file it is.
  final KitoAiAttachmentKind kind;

  /// Its size, when known.
  final int? byteCount;

  /// A preview for images.
  final KitoAiImage? thumbnail;

  /// "PDF · 1.2 MB", "Image", …
  String get subtitle {
    final size = byteCount;
    if (size == null) return kind.label;
    return '${kind.label} · ${KitoAiTextStats.fileSize(size)}';
  }

  /// A JSON-friendly map.
  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        if (byteCount != null) 'byteCount': byteCount,
        if (thumbnail != null) 'thumbnail': thumbnail!.toJson(),
      };

  /// Reads [toJson]'s output.
  factory KitoAiAttachment.fromJson(Map<String, Object?> json) =>
      KitoAiAttachment(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        kind: KitoAiAttachmentKind.values.asNameMap()[json['kind']] ??
            KitoAiAttachmentKind.document,
        byteCount: (json['byteCount'] as num?)?.toInt(),
        thumbnail: json['thumbnail'] is Map
            ? KitoAiImage.fromJson(
                (json['thumbnail']! as Map).cast<String, Object?>())
            : null,
      );

  @override
  bool operator ==(Object other) =>
      other is KitoAiAttachment &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.byteCount == byteCount;

  @override
  int get hashCode => Object.hash(id, name, kind, byteCount);
}

const Object _unset = Object();

/// One message in a conversation. Immutable; use [copyWith] and [applying] for changes.
@immutable
class KitoAiMessage {
  /// Creates a message; [id] defaults to a new unique id and [date] to now.
  KitoAiMessage({
    String? id,
    required this.role,
    this.blocks = const [],
    this.attachments = const [],
    DateTime? date,
    this.isStreaming = false,
    this.wasStopped = false,
    this.errorMessage,
    this.feedback = KitoAiFeedback.none,
    this.followUps = const [],
  })  : id = id ?? kitoAiNewId(),
        date = date ?? DateTime.now();

  /// A message whose content is one markdown block.
  factory KitoAiMessage.text(
    KitoAiRole role,
    String text, {
    String? id,
    List<KitoAiAttachment> attachments = const [],
    DateTime? date,
  }) =>
      KitoAiMessage(
        id: id,
        role: role,
        blocks: [KitoAiMarkdownContent(text)],
        attachments: attachments,
        date: date,
      );

  /// Something the person wrote.
  factory KitoAiMessage.user(String text,
          {String? id,
          List<KitoAiAttachment> attachments = const [],
          DateTime? date}) =>
      KitoAiMessage.text(KitoAiRole.user, text,
          id: id, attachments: attachments, date: date);

  /// A finished assistant reply.
  factory KitoAiMessage.assistant(String text, {String? id, DateTime? date}) =>
      KitoAiMessage.text(KitoAiRole.assistant, text, id: id, date: date);

  /// A centred notice.
  factory KitoAiMessage.system(String text, {String? id, DateTime? date}) =>
      KitoAiMessage.text(KitoAiRole.system, text, id: id, date: date);

  /// Identifies the message.
  final String id;

  /// Who wrote it.
  final KitoAiRole role;

  /// Its content, in order.
  final List<KitoAiContentBlock> blocks;

  /// Files sent with it.
  final List<KitoAiAttachment> attachments;

  /// When it was written.
  final DateTime date;

  /// True while the reply is still arriving.
  final bool isStreaming;

  /// True when the person stopped the reply before it finished.
  final bool wasStopped;

  /// Set when the reply failed; the message shows an error bubble with Retry.
  final String? errorMessage;

  /// Thumbs up or down.
  final KitoAiFeedback feedback;

  /// Suggested next prompts, shown as chips after the latest reply.
  final List<String> followUps;

  /// The markdown and code of the message joined together — what Copy puts on the clipboard.
  String get text => [
        for (final block in blocks)
          if (block case KitoAiMarkdownContent(:final text))
            text
          else if (block case KitoAiCodeContent(:final code, :final language))
            '```${language ?? ''}\n$code\n```',
      ].join('\n\n');

  /// The text without markdown syntax, for previews and screen readers.
  String get plainText => KitoAiMarkdown.plainText(text);

  /// The tool calls, in order.
  List<KitoAiToolCall> get toolCalls => [
        for (final block in blocks)
          if (block case KitoAiToolCallContent(:final call)) call,
      ];

  /// Every citation.
  List<KitoAiCitation> get citations => [
        for (final block in blocks)
          if (block case KitoAiCitationsContent(:final citations)) ...citations,
      ];

  /// False when there's nothing to show yet — the moment to show "Thinking…".
  bool get hasVisibleContent => blocks.any((block) => switch (block) {
        KitoAiMarkdownContent(:final text) => text.trim().isNotEmpty,
        _ => true,
      });

  /// A copy with some fields replaced. Pass `errorMessage: null` to clear the error.
  KitoAiMessage copyWith({
    List<KitoAiContentBlock>? blocks,
    List<KitoAiAttachment>? attachments,
    DateTime? date,
    bool? isStreaming,
    bool? wasStopped,
    Object? errorMessage = _unset,
    KitoAiFeedback? feedback,
    List<String>? followUps,
  }) =>
      KitoAiMessage(
        id: id,
        role: role,
        blocks: blocks ?? this.blocks,
        attachments: attachments ?? this.attachments,
        date: date ?? this.date,
        isStreaming: isStreaming ?? this.isStreaming,
        wasStopped: wasStopped ?? this.wasStopped,
        errorMessage: identical(errorMessage, _unset)
            ? this.errorMessage
            : errorMessage as String?,
        feedback: feedback ?? this.feedback,
        followUps: followUps ?? this.followUps,
      );

  /// This message with one streamed event applied: tokens extend the last markdown block (or
  /// start one after a tool call), tool calls are inserted or updated in place by id, citations
  /// merge into one row.
  KitoAiMessage applying(KitoAiStreamEvent event) {
    switch (event) {
      case KitoAiTokenEvent(:final text):
        if (text.isEmpty) return this;
        final next = [...blocks];
        if (next.isNotEmpty && next.last is KitoAiMarkdownContent) {
          final last = next.removeLast() as KitoAiMarkdownContent;
          next.add(KitoAiMarkdownContent(last.text + text));
        } else {
          next.add(KitoAiMarkdownContent(text));
        }
        return copyWith(blocks: next);
      case KitoAiToolCallEvent(:final call):
        final next = [...blocks];
        final index = next.indexWhere(
            (b) => b is KitoAiToolCallContent && b.call.id == call.id);
        if (index >= 0) {
          next[index] = KitoAiToolCallContent(call);
        } else {
          next.add(KitoAiToolCallContent(call));
        }
        return copyWith(blocks: next);
      case KitoAiCitationsEvent(:final citations):
        final next = [...blocks];
        final index = next.indexWhere((b) => b is KitoAiCitationsContent);
        if (index < 0) {
          next.add(KitoAiCitationsContent(citations));
        } else {
          final existing = (next[index] as KitoAiCitationsContent).citations;
          final known = {for (final c in existing) c.id};
          next[index] = KitoAiCitationsContent([
            ...existing,
            ...citations.where((c) => !known.contains(c.id)),
          ]);
        }
        return copyWith(blocks: next);
      case KitoAiImageEvent(:final image):
        return copyWith(blocks: [...blocks, KitoAiImageContent(image)]);
      case KitoAiFollowUpsEvent(:final suggestions):
        return copyWith(followUps: suggestions);
    }
  }

  /// A JSON-friendly map.
  Map<String, Object?> toJson() => {
        'id': id,
        'role': role.name,
        'blocks': [for (final b in blocks) b.toJson()],
        if (attachments.isNotEmpty)
          'attachments': [for (final a in attachments) a.toJson()],
        'date': date.toIso8601String(),
        if (wasStopped) 'wasStopped': true,
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (feedback != KitoAiFeedback.none) 'feedback': feedback.name,
        if (followUps.isNotEmpty) 'followUps': followUps,
      };

  /// Reads [toJson]'s output. A reply saved mid-stream comes back finished.
  factory KitoAiMessage.fromJson(Map<String, Object?> json) => KitoAiMessage(
        id: json['id'] as String?,
        role: KitoAiRole.values.asNameMap()[json['role']] ?? KitoAiRole.user,
        blocks: [
          for (final b in (json['blocks'] as List?) ?? const [])
            KitoAiContentBlock.fromJson((b as Map).cast<String, Object?>()),
        ],
        attachments: [
          for (final a in (json['attachments'] as List?) ?? const [])
            KitoAiAttachment.fromJson((a as Map).cast<String, Object?>()),
        ],
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        wasStopped: json['wasStopped'] == true,
        errorMessage: json['errorMessage'] as String?,
        feedback: KitoAiFeedback.values.asNameMap()[json['feedback']] ??
            KitoAiFeedback.none,
        followUps: [
          for (final f in (json['followUps'] as List?) ?? const [])
            f.toString(),
        ],
      );
}

/// A whole conversation. Immutable; the session replaces it as things change.
@immutable
class KitoAiConversation {
  /// Creates a conversation; [id] defaults to a new unique id and [updatedAt] to the last
  /// message's date (or now).
  KitoAiConversation({
    String? id,
    this.title,
    this.messages = const [],
    DateTime? updatedAt,
    this.model,
    this.isPinned = false,
  })  : id = id ?? kitoAiNewId(),
        updatedAt = updatedAt ??
            (messages.isEmpty ? DateTime.now() : messages.last.date);

  /// Identifies the conversation.
  final String id;

  /// Leave null to derive one from the first message (see [KitoAiTitle]).
  final String? title;

  /// The messages, oldest first.
  final List<KitoAiMessage> messages;

  /// When it last changed; the list sorts by this.
  final DateTime updatedAt;

  /// The model used, shown as a badge in the conversation list.
  final String? model;

  /// Pinned conversations sit at the top of the list.
  final bool isPinned;

  /// [title], else one made from the first user message, else "New chat".
  String get displayTitle {
    if (title case final t? when t.isNotEmpty) return t;
    for (final m in messages) {
      if (m.role == KitoAiRole.user) return KitoAiTitle.make(m.text);
    }
    return 'New chat';
  }

  /// The latest user or assistant text, without markdown, for a list row.
  String get snippet {
    for (final m in messages.reversed) {
      if ((m.role == KitoAiRole.assistant || m.role == KitoAiRole.user) &&
          m.text.isNotEmpty) {
        return m.plainText.replaceAll('\n', ' ');
      }
    }
    return '';
  }

  /// The latest message the person wrote.
  KitoAiMessage? get lastUserMessage {
    for (final m in messages.reversed) {
      if (m.role == KitoAiRole.user) return m;
    }
    return null;
  }

  /// The latest reply.
  KitoAiMessage? get lastAssistantMessage {
    for (final m in messages.reversed) {
      if (m.role == KitoAiRole.assistant) return m;
    }
    return null;
  }

  /// The position of the message with [id], or -1.
  int indexOf(String id) => messages.indexWhere((m) => m.id == id);

  /// A copy with some fields replaced. Pass `title: null` to go back to the derived title.
  KitoAiConversation copyWith({
    Object? title = _unset,
    List<KitoAiMessage>? messages,
    DateTime? updatedAt,
    Object? model = _unset,
    bool? isPinned,
  }) =>
      KitoAiConversation(
        id: id,
        title: identical(title, _unset) ? this.title : title as String?,
        messages: messages ?? this.messages,
        updatedAt: updatedAt ?? this.updatedAt,
        model: identical(model, _unset) ? this.model : model as String?,
        isPinned: isPinned ?? this.isPinned,
      );

  /// A copy without the messages after the one with [id].
  KitoAiConversation removingMessagesAfter(String id) {
    final index = indexOf(id);
    if (index < 0) return this;
    return copyWith(messages: messages.sublist(0, index + 1));
  }

  /// A JSON-friendly map.
  Map<String, Object?> toJson() => {
        'id': id,
        if (title != null) 'title': title,
        'messages': [for (final m in messages) m.toJson()],
        'updatedAt': updatedAt.toIso8601String(),
        if (model != null) 'model': model,
        if (isPinned) 'isPinned': true,
      };

  /// Reads [toJson]'s output.
  factory KitoAiConversation.fromJson(Map<String, Object?> json) =>
      KitoAiConversation(
        id: json['id'] as String?,
        title: json['title'] as String?,
        messages: [
          for (final m in (json['messages'] as List?) ?? const [])
            KitoAiMessage.fromJson((m as Map).cast<String, Object?>()),
        ],
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
        model: json['model'] as String?,
        isPinned: json['isPinned'] == true,
      );
}

/// A starter prompt for an empty conversation.
@immutable
class KitoAiSuggestion {
  /// Creates a suggestion; [prompt] defaults to the title and subtitle together.
  const KitoAiSuggestion({
    required this.title,
    required this.subtitle,
    String? prompt,
    this.icon = Icons.auto_awesome_rounded,
  }) : _prompt = prompt;

  /// The bold first line, e.g. "Plan a weekend".
  final String title;

  /// The second line, e.g. "in Diani on a budget".
  final String subtitle;

  final String? _prompt;

  /// The card's icon.
  final IconData icon;

  /// What gets sent.
  String get prompt => _prompt ?? '$title $subtitle';

  /// Four East-African flavoured starters that match [KitoAiMockStream]'s replies.
  static const List<KitoAiSuggestion> defaults = [
    KitoAiSuggestion(
        title: 'Plan a weekend',
        subtitle: 'in Diani on a budget',
        prompt: 'Plan a weekend in Diani on a budget',
        icon: Icons.beach_access_rounded),
    KitoAiSuggestion(
        title: 'Explain M-Pesa',
        subtitle: 'STK push in Dart',
        prompt: 'Show me M-Pesa STK push in Dart',
        icon: Icons.code_rounded),
    KitoAiSuggestion(
        title: 'Teach me Swahili',
        subtitle: 'phrases for a safari',
        prompt: 'Teach me Swahili phrases for a safari',
        icon: Icons.translate_rounded),
    KitoAiSuggestion(
        title: 'Compare the SGR',
        subtitle: 'and a matatu to Mombasa',
        prompt: 'Compare the SGR and a matatu to Mombasa',
        icon: Icons.train_rounded),
  ];

  @override
  bool operator ==(Object other) =>
      other is KitoAiSuggestion &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.prompt == prompt;

  @override
  int get hashCode => Object.hash(title, subtitle, prompt);
}

/// A model the person can choose.
@immutable
class KitoAiModelOption {
  /// Creates a model option.
  const KitoAiModelOption({
    required this.id,
    required this.name,
    required this.detail,
    this.icon = Icons.auto_awesome_rounded,
  });

  /// Your model identifier.
  final String id;

  /// What the picker shows, e.g. "Kito Pro".
  final String name;

  /// A short description, e.g. "Deeper reasoning".
  final String detail;

  /// The option's icon.
  final IconData icon;

  /// Three sample models.
  static const List<KitoAiModelOption> defaults = [
    KitoAiModelOption(
        id: 'fast',
        name: 'Kito Fast',
        detail: 'Quick everyday answers',
        icon: Icons.bolt_rounded),
    KitoAiModelOption(
        id: 'pro',
        name: 'Kito Pro',
        detail: 'Deeper reasoning',
        icon: Icons.auto_awesome_rounded),
    KitoAiModelOption(
        id: 'local',
        name: 'Kito Local',
        detail: 'Runs on this device',
        icon: Icons.smartphone_rounded),
  ];

  @override
  bool operator ==(Object other) =>
      other is KitoAiModelOption && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
