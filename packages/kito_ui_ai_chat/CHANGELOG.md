## 0.1.0

- First release: `KitoAiChatView` (welcome and starter prompts, streaming replies that follow
  the bottom until you scroll up, a Jump to latest pill, follow-up chips, edit-and-resend) on
  `KitoAiChatSession` (send, stop, regenerate, retry, feedback, attachments, JSON-friendly
  history); `KitoAiStream` for any model, `KitoAiTokenStream` for any `Stream<String>` and
  `KitoAiMockStream` (canned Kenyan replies with realistic jitter, tools, sources, failures, an
  instant timer-free mode); `KitoAiMarkdownView` and `KitoAiStreamingMarkdown` (headings, lists,
  tasks, quotes, tables, rules, inline styles, links) with `KitoAiStreamAssembler` holding back
  unfinished syntax; `KitoAiCodeBlock` with syntax colours and Copy; `KitoAiMessageView`,
  `KitoAiErrorBubble`, `KitoAiToolChip`, `KitoAiCitationChips`, `KitoAiFollowUpChips`,
  `KitoAiSuggestedPrompts`, `KitoAiAttachmentChip`, `KitoAiComposer`, `KitoAiModelPicker`,
  `KitoAiConversationList`, `KitoAiWelcome`, `KitoAiOrb`, `KitoAiThinkingIndicator`,
  `KitoAiShimmer` and `KitoAiStreamingCursor`; and the pure `KitoAiMarkdown`,
  `KitoAiInlineMarkdown`, `KitoAiSyntaxHighlighter`, `KitoAiTitle`, `KitoAiTextStats`,
  `KitoAiGreeting`, `KitoAiDateFormat`, `KitoAiConversationGrouping` and
  `KitoAiAutoScrollPolicy`. Right-to-left, Reduce Motion and screen readers supported
  throughout.
