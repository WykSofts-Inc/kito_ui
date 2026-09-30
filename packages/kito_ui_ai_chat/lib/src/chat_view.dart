// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'chips.dart';
import 'composer.dart';
import 'message_view.dart';
import 'models.dart';
import 'parts.dart';
import 'scroll_policy.dart';
import 'session.dart';
import 'welcome.dart';

/// A whole AI chat: the welcome screen and starter prompts, streaming replies with their tool
/// chips, sources and actions, follow-up chips, a "Jump to latest" pill, edit-and-resend and the
/// composer with Stop.
///
/// ```dart
/// final session = KitoAiChatSession(stream: KitoAiMockStream());
///
/// KitoAiChatView(
///   session: session,
///   userName: 'Wycliff N',
///   accessory: KitoAiModelPicker(selected: model, onChanged: pick),
/// )
/// ```
///
/// The conversation follows new text while you're at the bottom, stops following the moment
/// you scroll up (see [KitoAiAutoScrollPolicy]) and resumes when you jump back or send. Give it
/// a height — it scrolls on its own.
class KitoAiChatView extends StatefulWidget {
  /// Creates a chat for [session].
  const KitoAiChatView({
    super.key,
    required this.session,
    this.userName,
    this.accessory,
    this.onAttach,
    this.composerSuggestions = const [],
    this.placeholder = 'Ask anything',
    this.welcome,
    this.onLinkTap,
    this.onCitationTap,
    this.showsFeedback = true,
    this.padding,
    this.tint,
  });

  /// The state behind the chat. You own it; dispose it when you're done.
  final KitoAiChatSession session;

  /// Used in the greeting ("Good evening, Wycliff").
  final String? userName;

  /// Shown in the composer next to the attach button — a [KitoAiModelPicker], say.
  final Widget? accessory;

  /// Shows the composer's + button.
  final VoidCallback? onAttach;

  /// Prompt chips above the composer while it's empty.
  final List<String> composerSuggestions;

  /// The composer's hint.
  final String placeholder;

  /// Replaces the welcome shown above the starter prompts.
  final Widget? welcome;

  /// Called with a link's url when it's tapped.
  final ValueChanged<String>? onLinkTap;

  /// Called when a source chip is tapped.
  final ValueChanged<KitoAiCitation>? onCitationTap;

  /// Shows thumbs up and down under replies.
  final bool showsFeedback;

  /// Around the conversation and composer.
  final EdgeInsetsGeometry? padding;

  /// Links, the orb, chips and the send button; theme colours when null.
  final Color? tint;

  @override
  State<KitoAiChatView> createState() => _KitoAiChatViewState();
}

class _KitoAiChatViewState extends State<KitoAiChatView> {
  final _scroll = ScrollController();
  final _draft = TextEditingController();
  final _focus = FocusNode();
  final _policy = KitoAiAutoScrollPolicy();
  bool _showsJump = false;
  bool _followScheduled = false;
  final _seen = <String>{};

  KitoAiChatSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _session.addListener(_sessionChanged);
    _seen.addAll(_session.messages.map((m) => m.id));
  }

  @override
  void didUpdateWidget(KitoAiChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_sessionChanged);
      widget.session.addListener(_sessionChanged);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    _scroll.dispose();
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {});
    if (_policy.isFollowing) _scheduleFollow();
  }

  void _scheduleFollow({bool animate = false}) {
    if (_followScheduled) return;
    _followScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followScheduled = false;
      if (!mounted || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animate && !context.reduceMotion) {
        _scroll.animateTo(target,
            duration: context.kito.motion.medium, curve: Curves.easeOutCubic);
      } else if ((_scroll.position.pixels - target).abs() > 0.5) {
        _scroll.jumpTo(target);
      }
    });
  }

  void _observe(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) return;
    _policy.observe(
      distanceFromBottom: metrics.maxScrollExtent - metrics.pixels,
      contentHeight: metrics.maxScrollExtent + metrics.viewportDimension,
      viewportHeight: metrics.viewportDimension,
    );
    final shows = _policy.showsJumpToLatest;
    if (shows != _showsJump) setState(() => _showsJump = shows);
  }

  void _send(String text) {
    _policy.didSendMessage();
    _session.send(text);
    _scheduleFollow(animate: true);
  }

  void _edit() {
    final text = _session.beginEditing();
    if (text == null) return;
    _draft.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
    _focus.requestFocus();
  }

  void _cancelEdit() {
    _session.cancelEditing();
    _draft.clear();
  }

  void _jump() {
    _policy.jumpToLatest();
    setState(() => _showsJump = false);
    _scheduleFollow(animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final messages = _session.messages;
    final padding =
        widget.padding ?? EdgeInsets.symmetric(horizontal: theme.spacing.lg);
    final followUps = _session.followUps;
    final editing = _session.editingMessageId != null;

    final Widget body = messages.isEmpty
        ? _empty(theme, padding)
        : NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) {
              _observe(n.metrics);
              return false;
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification ||
                    n is ScrollEndNotification) {
                  _observe(n.metrics);
                }
                return false;
              },
              child: ListView.builder(
                controller: _scroll,
                padding: padding
                    .add(EdgeInsets.symmetric(vertical: theme.spacing.lg)),
                itemCount: messages.length + (followUps.isEmpty ? 0 : 1),
                itemBuilder: (context, index) {
                  final gap = index == 0 ? 0.0 : theme.spacing.xl;
                  if (index == messages.length) {
                    return Padding(
                      padding: EdgeInsetsDirectional.only(
                          top: theme.spacing.lg, start: 24 + theme.spacing.md),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: KitoAiFollowUpChips(
                            suggestions: followUps,
                            onSelect: _send,
                            tint: widget.tint),
                      ),
                    );
                  }
                  final m = messages[index];
                  final isLast = index == messages.length - 1;
                  final fresh = _seen.add(m.id);
                  return Padding(
                    key: ValueKey(m.id),
                    padding: EdgeInsets.only(top: gap),
                    child: AiEntrance(
                      animate: fresh,
                      child: KitoAiMessageView(
                        message: m,
                        tint: widget.tint,
                        onRegenerate: isLast && m.role == KitoAiRole.assistant
                            ? _session.regenerate
                            : null,
                        onRetry: _session.retry,
                        onFeedback: widget.showsFeedback
                            ? (f) => _session.setFeedback(f, m.id)
                            : null,
                        onEdit: m.id == _session.editableMessageId && !editing
                            ? _edit
                            : null,
                        onLinkTap: widget.onLinkTap,
                        onCitationTap: widget.onCitationTap,
                      ),
                    ),
                  );
                },
              ),
            ),
          );

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: theme.spacing.md,
                child: Center(
                  child: IgnorePointer(
                    ignoring: !_showsJump,
                    child: AnimatedScale(
                      scale: _showsJump ? 1 : 0.8,
                      duration: KitoMotion.of(context, theme.motion.medium),
                      curve: theme.motion.spring,
                      child: AnimatedOpacity(
                        opacity: _showsJump ? 1 : 0,
                        duration: KitoMotion.of(context, theme.motion.fast),
                        child: _JumpPill(onTap: _jump),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: KitoMotion.of(context, theme.motion.medium),
          curve: theme.motion.standard,
          child: editing
              ? Padding(
                  padding:
                      padding.add(EdgeInsets.only(bottom: theme.spacing.xs)),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 16, color: aiMuted(theme, 0.6)),
                      SizedBox(width: theme.spacing.sm),
                      Expanded(
                        child: Text('Editing your message',
                            style: theme.typography.caption
                                .copyWith(color: aiMuted(theme, 0.6))),
                      ),
                      AiTap(
                        onTap: _cancelEdit,
                        label: 'Cancel editing',
                        radius: theme.radii.pill,
                        minSize: 36,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: theme.spacing.sm),
                          child: Text('Cancel',
                              style: theme.typography.caption.copyWith(
                                  color: theme.colors.onSurface,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Padding(
          padding: padding.add(EdgeInsets.only(bottom: theme.spacing.sm)),
          child: KitoAiComposer(
            controller: _draft,
            focusNode: _focus,
            onSend: _send,
            isGenerating: _session.isGenerating,
            onStop: _session.stop,
            onAttach: widget.onAttach,
            attachments: _session.attachments,
            onRemoveAttachment: (a) => _session.removeAttachment(a.id),
            suggestions:
                messages.isEmpty ? widget.composerSuggestions : const [],
            accessory: widget.accessory,
            placeholder: editing ? 'Edit your message' : widget.placeholder,
            tint: widget.tint,
          ),
        ),
      ],
    );
  }

  Widget _empty(KitoTheme theme, EdgeInsetsGeometry padding) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: theme.spacing.xl),
              widget.welcome ??
                  KitoAiWelcome(name: widget.userName, tint: widget.tint),
              SizedBox(height: theme.spacing.xl),
              if (_session.suggestions.isNotEmpty)
                KitoAiSuggestedPrompts(
                  suggestions: _session.suggestions,
                  onSelect: (s) => _send(s.prompt),
                  tint: widget.tint,
                ),
              SizedBox(height: theme.spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _JumpPill extends StatelessWidget {
  const _JumpPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return AiTap(
      onTap: onTap,
      label: 'Jump to latest',
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md, vertical: theme.spacing.sm),
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(theme.radii.pill),
          border: Border.all(color: theme.colors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_downward_rounded,
                size: 16, color: theme.colors.onSurface),
            SizedBox(width: theme.spacing.xs),
            Text('Jump to latest',
                style: theme.typography.caption.copyWith(
                    color: theme.colors.onSurface,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
