// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

/// An AI chat UI that works with any model: streaming markdown replies, code blocks with Copy,
/// tool and source chips, Stop and Regenerate, feedback, edit-and-resend, a composer with
/// suggestion chips and a model picker, a conversation list and a welcome screen. No network
/// code of its own — hand it a stream of tokens.
library;

export 'src/chat_view.dart';
export 'src/chips.dart';
export 'src/code_block.dart' show KitoAiCodeBlock, KitoAiCodePalette;
export 'src/composer.dart';
export 'src/conversation_list.dart';
export 'src/inline.dart';
export 'src/markdown.dart';
export 'src/markdown_view.dart';
export 'src/message_view.dart';
export 'src/mock_stream.dart';
export 'src/models.dart';
export 'src/orb.dart';
export 'src/scroll_policy.dart';
export 'src/session.dart';
export 'src/stream.dart';
export 'src/syntax.dart';
export 'src/text.dart';
export 'src/welcome.dart';
