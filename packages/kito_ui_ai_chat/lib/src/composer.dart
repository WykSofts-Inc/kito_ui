// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'chips.dart';
import 'models.dart';
import 'parts.dart';
import 'text.dart';

/// The prompt field: grows to [maxLines], shows waiting attachments, suggestion chips while it's
/// empty, an attach button, an accessory (like a [KitoAiModelPicker]) and a send button that
/// morphs into Stop while a reply is generating. Long prompts show a token estimate.
///
/// ```dart
/// KitoAiComposer(
///   onSend: session.send,
///   isGenerating: session.isGenerating,
///   onStop: session.stop,
///   suggestions: const ['Plan a weekend in Diani', 'Explain M-Pesa'],
///   accessory: KitoAiModelPicker(models: models, selected: model, onChanged: pick),
/// )
/// ```
///
/// Enter sends from a hardware keyboard; Shift+Enter adds a line.
class KitoAiComposer extends StatefulWidget {
  /// Creates a composer.
  const KitoAiComposer({
    super.key,
    required this.onSend,
    this.controller,
    this.focusNode,
    this.isGenerating = false,
    this.onStop,
    this.onAttach,
    this.attachments = const [],
    this.onRemoveAttachment,
    this.suggestions = const [],
    this.onSuggestion,
    this.accessory,
    this.placeholder = 'Ask anything',
    this.maxLines = 8,
    this.tokenEstimateThreshold = 280,
    this.clearsOnSend = true,
    this.sendsOnEnter = true,
    this.autofocus = false,
    this.enabled = true,
    this.tint,
  });

  /// Called with the prompt when Send is tapped.
  final ValueChanged<String> onSend;

  /// The text; the composer makes its own when null.
  final TextEditingController? controller;

  /// The field's focus; the composer makes its own when null.
  final FocusNode? focusNode;

  /// Turns Send into Stop.
  final bool isGenerating;

  /// Called when Stop is tapped.
  final VoidCallback? onStop;

  /// Shows a + button that calls this.
  final VoidCallback? onAttach;

  /// Files waiting to be sent, shown above the field.
  final List<KitoAiAttachment> attachments;

  /// Shows an × on each attachment that calls this.
  final ValueChanged<KitoAiAttachment>? onRemoveAttachment;

  /// Prompt chips shown while the field is empty.
  final List<String> suggestions;

  /// Called with a tapped chip; sends it when null.
  final ValueChanged<String>? onSuggestion;

  /// Shown next to the attach button, e.g. a model picker.
  final Widget? accessory;

  /// The hint in the empty field.
  final String placeholder;

  /// How tall the field grows before it scrolls.
  final int maxLines;

  /// Shows "~N tokens" once the prompt is at least this many characters; 0 turns it off.
  final int tokenEstimateThreshold;

  /// Clears the field after sending.
  final bool clearsOnSend;

  /// Enter on a hardware keyboard sends (Shift+Enter adds a line).
  final bool sendsOnEnter;

  /// Focuses the field when it appears.
  final bool autofocus;

  /// False disables typing and sending.
  final bool enabled;

  /// The send button colour; the text colour (black or white) when null.
  final Color? tint;

  @override
  State<KitoAiComposer> createState() => _KitoAiComposerState();
}

class _KitoAiComposerState extends State<KitoAiComposer> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(KitoAiComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _canSend =>
      widget.enabled &&
      !widget.isGenerating &&
      (_controller.text.trim().isNotEmpty || widget.attachments.isNotEmpty);

  void _send() {
    if (!_canSend) return;
    final text = _controller.text.trim();
    HapticFeedback.lightImpact();
    widget.onSend(text);
    if (widget.clearsOnSend) _controller.clear();
  }

  void _stop() {
    HapticFeedback.selectionClick();
    widget.onStop?.call();
  }

  void _suggest(String prompt) {
    if (widget.onSuggestion case final pick?) {
      pick(prompt);
    } else {
      HapticFeedback.lightImpact();
      widget.onSend(prompt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final text = _controller.text;
    final showsChips = widget.suggestions.isNotEmpty &&
        text.isEmpty &&
        !widget.isGenerating &&
        widget.enabled;
    final tokens = widget.tokenEstimateThreshold > 0 &&
            text.length >= widget.tokenEstimateThreshold
        ? KitoAiTextStats.estimatedTokens(text)
        : null;
    final motion = KitoMotion.of(context, theme.motion.medium);

    Widget field = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        minLines: 1,
        maxLines: widget.maxLines,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        style: theme.typography.body.copyWith(color: theme.colors.onSurface),
        cursorColor: aiStrong(theme, widget.tint),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.placeholder,
          hintStyle: theme.typography.body.copyWith(color: aiMuted(theme, 0.4)),
          contentPadding: EdgeInsetsDirectional.fromSTEB(theme.spacing.xs,
              theme.spacing.sm, theme.spacing.xs, theme.spacing.sm),
        ),
      ),
    );
    if (widget.sendsOnEnter) {
      field = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _send,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _send,
        },
        child: field,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: motion,
          curve: theme.motion.standard,
          alignment: AlignmentDirectional.bottomStart,
          child: showsChips
              ? Padding(
                  padding: EdgeInsets.only(bottom: theme.spacing.sm),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.suggestions.length; i++) ...[
                          if (i > 0) SizedBox(width: theme.spacing.xs + 2),
                          AiEntrance(
                            delay: Duration(milliseconds: 40 * i),
                            child: _SuggestionChip(
                                label: widget.suggestions[i],
                                onTap: () => _suggest(widget.suggestions[i])),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surface,
            borderRadius: BorderRadius.circular(theme.radii.xl + 2),
            border: Border.all(color: theme.colors.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.3 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(theme.spacing.sm, theme.spacing.sm,
                theme.spacing.sm, theme.spacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: motion,
                  curve: theme.motion.standard,
                  alignment: AlignmentDirectional.topStart,
                  child: widget.attachments.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: EdgeInsets.only(bottom: theme.spacing.sm),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final a in widget.attachments) ...[
                                  AiEntrance(
                                    child: KitoAiAttachmentChip(
                                      attachment: a,
                                      tint: widget.tint,
                                      onRemove: widget.onRemoveAttachment ==
                                              null
                                          ? null
                                          : () => widget.onRemoveAttachment!(a),
                                    ),
                                  ),
                                  SizedBox(width: theme.spacing.xs + 2),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: theme.spacing.xs),
                  child: field,
                ),
                SizedBox(height: theme.spacing.xs),
                Row(
                  children: [
                    if (widget.onAttach != null)
                      AiTap(
                        onTap: widget.enabled ? widget.onAttach : null,
                        label: 'Attach a file',
                        minSize: 40,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colors.border),
                          ),
                          child: Icon(Icons.add_rounded,
                              size: 20, color: aiMuted(theme, 0.7)),
                        ),
                      ),
                    if (widget.accessory case final accessory?) ...[
                      SizedBox(width: theme.spacing.xs),
                      Flexible(child: accessory),
                    ],
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: KitoMotion.of(context, theme.motion.fast),
                      child: tokens == null
                          ? const SizedBox.shrink()
                          : Padding(
                              key: const ValueKey('tokens'),
                              padding: EdgeInsetsDirectional.only(
                                  end: theme.spacing.sm),
                              child: Text('~$tokens tokens',
                                  style: theme.typography.caption
                                      .copyWith(color: aiMuted(theme, 0.45))),
                            ),
                    ),
                    _SendButton(
                      isGenerating: widget.isGenerating,
                      canSend: _canSend,
                      onSend: _send,
                      onStop: widget.onStop == null ? null : _stop,
                      tint: widget.tint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return AiTap(
      onTap: onTap,
      label: label,
      minSize: 40,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md, vertical: theme.spacing.sm),
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(theme.radii.pill),
          border: Border.all(color: theme.colors.border),
        ),
        child: Text(label,
            style: theme.typography.label
                .copyWith(color: theme.colors.onSurface, fontSize: 13.5)),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isGenerating,
    required this.canSend,
    required this.onSend,
    required this.onStop,
    required this.tint,
  });

  final bool isGenerating;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback? onStop;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final strong = aiStrong(theme, tint);
    final onStrong = aiOnStrong(theme, tint);
    final active = isGenerating || canSend;
    final fill = active ? strong : theme.colors.surfaceMuted;
    final iconColor = active ? onStrong : aiMuted(theme, 0.35);
    return AiTap(
      onTap: isGenerating ? onStop : (canSend ? onSend : null),
      label: isGenerating ? 'Stop generating' : 'Send',
      minSize: 44,
      child: AnimatedContainer(
        duration: KitoMotion.of(context, theme.motion.fast),
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: AnimatedSwitcher(
          duration: KitoMotion.of(context, theme.motion.medium),
          switchInCurve: theme.motion.spring,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: isGenerating
              ? Container(
                  key: const ValueKey('stop'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: iconColor, borderRadius: BorderRadius.circular(3)),
                )
              : Icon(Icons.arrow_upward_rounded,
                  key: const ValueKey('send'), size: 20, color: iconColor),
        ),
      ),
    );
  }
}

/// A capsule showing the chosen model; tap it for a sheet of the others.
///
/// ```dart
/// KitoAiModelPicker(
///   models: KitoAiModelOption.defaults,
///   selected: model,
///   onChanged: (id) => setState(() => model = id),
/// )
/// ```
class KitoAiModelPicker extends StatelessWidget {
  /// Creates a picker.
  const KitoAiModelPicker({
    super.key,
    this.models = KitoAiModelOption.defaults,
    required this.selected,
    required this.onChanged,
    this.title = 'Model',
    this.tint,
  });

  /// The choices.
  final List<KitoAiModelOption> models;

  /// The chosen model's id.
  final String selected;

  /// Called with the new model's id.
  final ValueChanged<String> onChanged;

  /// The sheet's title.
  final String title;

  /// The check and icon colour; the theme's primary when null.
  final Color? tint;

  KitoAiModelOption? get _current {
    for (final m in models) {
      if (m.id == selected) return m;
    }
    return models.isEmpty ? null : models.first;
  }

  Future<void> _open(BuildContext context) async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.kito.colors.surface,
      builder: (context) => _ModelSheet(
          title: title, models: models, selected: selected, tint: tint),
    );
    if (picked != null && picked != selected) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final current = _current;
    return AiTap(
      onTap: models.isEmpty ? null : () => _open(context),
      label: '$title, ${current?.name ?? 'none'}',
      minSize: 40,
      child: Container(
        padding: EdgeInsetsDirectional.only(
            start: theme.spacing.sm + 2,
            end: theme.spacing.sm,
            top: theme.spacing.xs + 2,
            bottom: theme.spacing.xs + 2),
        decoration: BoxDecoration(
          color: theme.colors.surfaceMuted.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(theme.radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current != null)
              Icon(current.icon, size: 15, color: aiAccent(theme, tint)),
            SizedBox(width: theme.spacing.xs + 1),
            Flexible(
              child: AnimatedSwitcher(
                duration: KitoMotion.of(context, theme.motion.fast),
                child: Text(current?.name ?? title,
                    key: ValueKey(current?.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.label.copyWith(
                        color: theme.colors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: aiMuted(theme, 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ModelSheet extends StatelessWidget {
  const _ModelSheet({
    required this.title,
    required this.models,
    required this.selected,
    required this.tint,
  });

  final String title;
  final List<KitoAiModelOption> models;
  final String selected;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final accent = aiAccent(theme, tint);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            theme.spacing.lg, 0, theme.spacing.lg, theme.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title,
                  style: theme.typography.headline
                      .copyWith(color: theme.colors.onSurface)),
            ),
            SizedBox(height: theme.spacing.md),
            for (final m in models)
              AiTap(
                onTap: () => Navigator.of(context).pop(m.id),
                label: '${m.name}, ${m.detail}',
                selected: m.id == selected,
                radius: theme.radii.md,
                scale: 0.98,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: theme.spacing.sm, horizontal: theme.spacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(theme.radii.md),
                        ),
                        child: Icon(m.icon, size: 18, color: accent),
                      ),
                      SizedBox(width: theme.spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name,
                                style: theme.typography.label.copyWith(
                                    color: theme.colors.onSurface,
                                    fontWeight: FontWeight.w600)),
                            Text(m.detail,
                                style: theme.typography.caption
                                    .copyWith(color: aiMuted(theme, 0.55))),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: m.id == selected ? 1 : 0,
                        duration: KitoMotion.of(context, theme.motion.fast),
                        child: Icon(Icons.check_rounded, color: accent),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
