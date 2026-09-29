// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'mask.dart';
import 'text_field.dart';

/// A capsule search bar: magnifier, clear button, debounced [onSearch], and a Cancel button that
/// slides in while it's focused.
///
/// ```dart
/// KitoFieldSearchBar(
///   placeholder: 'Search products',
///   onSearch: (query) => results.load(query),
/// )
/// ```
class KitoFieldSearchBar extends StatefulWidget {
  /// Creates a search bar.
  const KitoFieldSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSearch,
    this.onSubmitted,
    this.debounce = const Duration(milliseconds: 300),
    this.showsCancel = true,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.autofocus = false,
    this.trailing,
    this.tint,
  });

  /// Your controller.
  final TextEditingController? controller;

  /// Your focus node.
  final FocusNode? focusNode;

  /// Shown while empty.
  final String placeholder;

  /// Every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called once typing pauses for [debounce], and at once on clear or submit.
  final ValueChanged<String>? onSearch;

  /// The search key.
  final ValueChanged<String>? onSubmitted;

  /// How long typing must pause before [onSearch].
  final Duration debounce;

  /// A Cancel button while focused.
  final bool showsCancel;

  /// The Cancel button's title.
  final String cancelLabel;

  /// Runs after Cancel clears and unfocuses.
  final VoidCallback? onCancel;

  /// Focus on first build.
  final bool autofocus;

  /// After the clear button: a filter or microphone button.
  final Widget? trailing;

  /// Cursor and focus colour.
  final Color? tint;

  @override
  State<KitoFieldSearchBar> createState() => _KitoFieldSearchBarState();
}

class _KitoFieldSearchBarState extends State<KitoFieldSearchBar> {
  TextEditingController? _own;
  FocusNode? _ownFocus;
  Timer? _timer;
  bool _focused = false;
  String _last = '';

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'KitoSearch'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
    _last = _controller.text;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onText);
    _focus.removeListener(_onFocus);
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus != _focused) setState(() => _focused = _focus.hasFocus);
  }

  void _onText() {
    final text = _controller.text;
    if (text == _last) return;
    _last = text;
    widget.onChanged?.call(text);
    _timer?.cancel();
    if (text.isEmpty) {
      widget.onSearch?.call(text);
    } else {
      _timer = Timer(widget.debounce, () => widget.onSearch?.call(text));
    }
    setState(() {});
  }

  void _cancel() {
    _controller.clear();
    _focus.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = kito.accent(widget.tint);
    final medium = KitoMotion.of(context, kito.motion.medium);
    final style = kito.typography.body.copyWith(color: kito.colors.onSurface);
    final hasText = _controller.text.isNotEmpty;

    final bar = AnimatedContainer(
      duration: medium,
      curve: kito.motion.standard,
      height: 44,
      padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
      decoration: BoxDecoration(
        color: kito.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(kito.radii.pill),
        border: Border.all(
            color:
                _focused ? accent.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.2),
      ),
      child: Row(
        children: [
          AnimatedScale(
            scale: _focused ? 1.08 : 1,
            duration: medium,
            curve: kito.motion.spring,
            child: Icon(Icons.search_rounded,
                size: 20,
                color: _focused
                    ? accent
                    : kito.colors.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: widget.placeholder,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.search,
                inputFormatters: [KitoFieldDigitsFormatter()],
                style: style,
                cursorColor: accent,
                onSubmitted: (v) {
                  _timer?.cancel();
                  widget.onSearch?.call(v);
                  widget.onSubmitted?.call(v);
                },
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.placeholder,
                  hintStyle: style.copyWith(
                      color: kito.colors.onSurface.withValues(alpha: 0.45)),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: KitoMotion.of(context, kito.motion.fast),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: hasText
                ? KitoFieldIconButton(
                    key: const ValueKey('clear'),
                    icon: Icons.cancel_rounded,
                    semanticLabel: 'Clear search',
                    size: 18,
                    onPressed: _controller.clear,
                  )
                : const SizedBox(key: ValueKey('none'), width: 8),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );

    if (!widget.showsCancel) return bar;
    return Row(
      children: [
        Expanded(child: bar),
        ClipRect(
          child: AnimatedAlign(
            duration: medium,
            curve: kito.motion.standard,
            alignment: AlignmentDirectional.centerStart,
            widthFactor: _focused ? 1 : 0,
            child: Semantics(
              button: true,
              label: widget.cancelLabel,
              excludeSemantics: true,
              onTap: _cancel,
              child: GestureDetector(
                onTap: _cancel,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 12, end: 4),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(widget.cancelLabel,
                          style: kito.typography.label.copyWith(
                              color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
