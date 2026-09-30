// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'indicators.dart';
import 'models.dart';
import 'motion.dart';
import 'strings.dart';
import 'style.dart';
import 'timeline.dart';
import 'voice.dart';
import 'waveform.dart';

/// Where a hold-to-record gesture is.
enum KitoChatRecordingPhase {
  /// Not recording.
  idle,

  /// Recording while the finger is down.
  recording,

  /// Locked: recording hands-free until sent or deleted.
  locked,
}

/// The message bar: a growing text field, an attach button, and a send button that morphs from
/// a microphone into a paper plane as you type. Hold the microphone to record a voice note —
/// slide toward the leading edge to cancel, slide up to lock and keep recording hands-free.
///
/// Recording goes through a [KitoChatVoiceRecorder] you provide; without one the composer
/// records a simulated, clearly labelled "Preview" unless [simulatesRecordingWhenUnavailable]
/// is false.
///
/// ```dart
/// KitoChatComposer(
///   replyTo: replyingTo,
///   onCancelReply: () => setState(() => replyingTo = null),
///   onSend: (content) => send(content), // KitoChatTextContent or KitoChatVoiceContent
/// )
/// ```
class KitoChatComposer extends StatefulWidget {
  /// Creates a composer.
  const KitoChatComposer({
    super.key,
    required this.onSend,
    this.controller,
    this.focusNode,
    this.replyTo,
    this.onCancelReply,
    this.placeholder,
    this.allowsVoice = true,
    this.recorder,
    this.simulatesRecordingWhenUnavailable = true,
    this.tint,
    this.onAttach,
    this.onRecordingChanged,
  });

  /// Called with a [KitoChatTextContent] or a [KitoChatVoiceContent].
  final ValueChanged<KitoChatContent> onSend;

  /// The draft; one is made when null.
  final TextEditingController? controller;

  /// The field's focus; one is made when null.
  final FocusNode? focusNode;

  /// The message being replied to, shown above the field.
  final KitoChatReply? replyTo;

  /// Called when the reply preview's close button is tapped.
  final VoidCallback? onCancelReply;

  /// The field's placeholder; "Message" when null.
  final String? placeholder;

  /// Show the microphone when the field is empty.
  final bool allowsVoice;

  /// Records voice notes. Null records a simulated preview (or shows a hint when
  /// [simulatesRecordingWhenUnavailable] is false).
  final KitoChatVoiceRecorder? recorder;

  /// Record a simulated preview when there's no [recorder].
  final bool simulatesRecordingWhenUnavailable;

  /// Overrides the primary colour.
  final Color? tint;

  /// Shows an attach button.
  final VoidCallback? onAttach;

  /// Called as recording starts, locks and stops.
  final ValueChanged<KitoChatRecordingPhase>? onRecordingChanged;

  /// Recordings shorter than this are discarded.
  static const minimumRecording = Duration(milliseconds: 600);

  /// How far to slide toward the leading edge to cancel.
  static const cancelDistance = 110.0;

  /// How far to slide up to lock.
  static const lockDistance = 90.0;

  @override
  State<KitoChatComposer> createState() => _KitoChatComposerState();
}

class _KitoChatComposerState extends State<KitoChatComposer> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  KitoChatRecordingPhase _phase = KitoChatRecordingPhase.idle;
  KitoChatVoiceRecorder? _activeRecorder;
  KitoChatSimulatedRecorder? _simulated;
  StreamSubscription<double>? _levelSub;
  final _levels = <double>[];
  Duration _elapsed = Duration.zero;
  Timer? _holdTimer;
  bool _heldLong = false;
  Timer? _clock;

  bool _pressing = false;
  bool _pressStartedRecording = false;
  Offset _pressOrigin = Offset.zero;
  Offset _drag = Offset.zero;
  bool _focused = false;

  String? _hint;
  Timer? _hintTimer;
  int _sendCount = 0;

  bool get _recordingActive => _phase != KitoChatRecordingPhase.idle;
  bool get _showsSend =>
      _controller.text.trim().isNotEmpty ||
      _phase == KitoChatRecordingPhase.locked ||
      !widget.allowsVoice;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(KitoChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onText);
      _controller.addListener(_onText);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    if (widget.replyTo != null && widget.replyTo != oldWidget.replyTo) {
      _focus.requestFocus();
    }
  }

  void _onText() => setState(() {});
  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _focus.removeListener(_onFocus);
    _ownController?.dispose();
    _ownFocus?.dispose();
    _clock?.cancel();
    _hintTimer?.cancel();
    _holdTimer?.cancel();
    _levelSub?.cancel();
    if (_recordingActive) _activeRecorder?.cancel();
    _simulated?.cancel();
    super.dispose();
  }

  // MARK: Recording

  Future<void> _beginRecording() async {
    _focus.unfocus();
    final recorder = widget.recorder ??
        (widget.simulatesRecordingWhenUnavailable
            ? (_simulated ??= KitoChatSimulatedRecorder())
            : null);
    if (recorder == null) {
      _showHint('micOff');
      return;
    }
    final result = await recorder.start();
    if (!mounted) return;
    switch (result) {
      case KitoChatRecordingStart.askedPermission:
        _showHint('micAsked');
        return;
      case KitoChatRecordingStart.unavailable:
        _showHint('micOff');
        return;
      case KitoChatRecordingStart.started:
        break;
    }
    if (!_pressing) {
      // Let go before the recorder was ready.
      await recorder.cancel();
      _showHint('recordHint');
      return;
    }
    HapticFeedback.mediumImpact();
    _activeRecorder = recorder;
    _levels.clear();
    _levelSub?.cancel();
    _levelSub = recorder.levels.listen((l) {
      _levels.add(l.clamp(0.0, 1.0));
      if (_levels.length > 4000) _levels.removeRange(0, _levels.length - 4000);
    });
    _elapsed = Duration.zero;
    _clock?.cancel();
    _clock = Timer.periodic(_tick, (t) {
      if (mounted) setState(() => _elapsed = _tick * t.tick);
    });
    setState(() {
      _pressStartedRecording = true;
      _phase = KitoChatRecordingPhase.recording;
    });
    widget.onRecordingChanged?.call(_phase);
  }

  static const _tick = Duration(milliseconds: 50);

  void _stopClock() {
    _clock?.cancel();
    _levelSub?.cancel();
    _levelSub = null;
  }

  Future<void> _cancelRecording({bool haptic = true}) async {
    if (!_recordingActive) return;
    final recorder = _activeRecorder;
    _stopClock();
    setState(() {
      _phase = KitoChatRecordingPhase.idle;
      _pressStartedRecording = false;
      _drag = Offset.zero;
    });
    widget.onRecordingChanged?.call(_phase);
    if (haptic) HapticFeedback.heavyImpact();
    await recorder?.cancel();
  }

  Future<void> _sendRecording() async {
    if (!_recordingActive) return;
    final recorder = _activeRecorder;
    final duration = _elapsed;
    final waveform = KitoChatWaveform.downsample(List.of(_levels), 40);
    _stopClock();
    setState(() {
      _phase = KitoChatRecordingPhase.idle;
      _pressStartedRecording = false;
      _drag = Offset.zero;
    });
    widget.onRecordingChanged?.call(_phase);
    if (duration < KitoChatComposer.minimumRecording) {
      await recorder?.cancel();
      _showHint('tooShort');
      return;
    }
    final url = await recorder?.stop();
    widget.onSend(
        KitoChatVoiceContent(duration: duration, waveform: waveform, url: url));
    HapticFeedback.lightImpact();
    setState(() => _sendCount++);
  }

  void _lock() {
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = KitoChatRecordingPhase.locked;
      _drag = Offset.zero;
    });
    widget.onRecordingChanged?.call(_phase);
  }

  // MARK: Gestures

  void _onPointerDown(PointerDownEvent e) {
    _pressing = true;
    _heldLong = false;
    _holdTimer?.cancel();
    _holdTimer =
        Timer(const Duration(milliseconds: 300), () => _heldLong = true);
    _pressOrigin = e.position;
    _pressStartedRecording = false;
    if (!_showsSend) _beginRecording();
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_phase != KitoChatRecordingPhase.recording || !_pressStartedRecording) {
      return;
    }
    final delta = e.position - _pressOrigin;
    final semantic = Offset(delta.dx * (context.isRtl ? -1 : 1), delta.dy);
    setState(() => _drag = semantic);
    if (semantic.dx < -KitoChatComposer.cancelDistance) {
      _cancelRecording();
    } else if (semantic.dy < -KitoChatComposer.lockDistance) {
      _lock();
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    final moved = (e.position - _pressOrigin).distance;
    final wasRecording =
        _phase == KitoChatRecordingPhase.recording && _pressStartedRecording;
    final startedHere = _pressStartedRecording;
    _pressing = false;
    _pressStartedRecording = false;
    if (wasRecording) {
      if (!_heldLong) {
        _cancelRecording(haptic: false);
        _showHint('recordHint');
      } else {
        _sendRecording();
      }
    } else if (!startedHere && _showsSend && moved < 30) {
      _send();
    }
    if (_drag != Offset.zero) setState(() => _drag = Offset.zero);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pressing = false;
    if (_phase == KitoChatRecordingPhase.recording) _cancelRecording();
  }

  // MARK: Sending

  void _send() {
    if (_phase == KitoChatRecordingPhase.locked) {
      _sendRecording();
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(KitoChatTextContent(text));
    _controller.clear();
    HapticFeedback.lightImpact();
    setState(() => _sendCount++);
  }

  void _showHint(String key) {
    _hintTimer?.cancel();
    setState(() => _hint = key);
    _hintTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  // MARK: Build

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final accent = KitoChatAccent.of(context, widget.tint);
    final dur = KitoMotion.of(context, kito.motion.medium);
    final curve = context.reduceMotion ? Curves.easeInOut : kito.motion.spring;
    final reply = widget.replyTo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kito.colors.surface.withValues(alpha: 0.96),
        border: Border(
            top: BorderSide(
                color: kito.colors.border.withValues(alpha: 0.6), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(kito.spacing.md,
              kito.spacing.sm, kito.spacing.md, kito.spacing.sm),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSize(
              duration: kitoChatSizeDuration(dur),
              curve: kito.motion.standard,
              child: _hint == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(bottom: kito.spacing.sm),
                      child: _HintBubble(
                          text: KitoChatStrings.of(context, _hint!)),
                    ),
            ),
            AnimatedSize(
              duration: kitoChatSizeDuration(dur),
              curve: kito.motion.standard,
              child: reply == null || _recordingActive
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(bottom: kito.spacing.sm),
                      child: _ReplyPreview(
                        reply: reply,
                        tint: accent.tint,
                        onCancel: widget.onCancelReply,
                      ),
                    ),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: dur,
                  switchInCurve: curve,
                  transitionBuilder: (child, animation) {
                    final isBar = child.key == const ValueKey('bar');
                    return FadeTransition(
                      opacity: animation,
                      child: isBar && !context.reduceMotion
                          ? SlideTransition(
                              position: Tween(
                                      begin:
                                          Offset(context.isRtl ? -0.3 : 0.3, 0),
                                      end: Offset.zero)
                                  .animate(animation),
                              child: child)
                          : child,
                    );
                  },
                  child: _recordingActive
                      ? KeyedSubtree(
                          key: const ValueKey('bar'),
                          child: _recordingBar(context, accent))
                      : KeyedSubtree(
                          key: const ValueKey('input'),
                          child: _inputRow(context, accent)),
                ),
              ),
              SizedBox(width: kito.spacing.sm),
              _actionButton(context, accent),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _inputRow(BuildContext context, KitoChatAccent accent) {
    final kito = context.kito;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (widget.onAttach != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: KitoChatIconButton(
            icon: Icons.add_rounded,
            label: KitoChatStrings.of(context, 'attach'),
            onPressed: widget.onAttach!,
          ),
        ),
        SizedBox(width: kito.spacing.xxs),
      ],
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: AnimatedContainer(
            duration: KitoMotion.of(context, kito.motion.fast),
            constraints: const BoxConstraints(minHeight: 38),
            decoration: BoxDecoration(
              color: kito.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: _focused
                    ? accent.tint.withValues(alpha: 0.45)
                    : kito.colors.border.withValues(alpha: 0.7),
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              minLines: 1,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: accent.tint,
              style:
                  kito.typography.body.copyWith(color: kito.colors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.placeholder ??
                    KitoChatStrings.of(context, 'message'),
                hintStyle: kito.typography.body.copyWith(
                    color: kito.colors.onSurface.withValues(alpha: 0.4)),
                contentPadding: EdgeInsetsDirectional.symmetric(
                    horizontal: kito.spacing.md + 2, vertical: 9),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _recordingBar(BuildContext context, KitoChatAccent accent) {
    final kito = context.kito;
    final locked = _phase == KitoChatRecordingPhase.locked;
    final cancelProgress =
        (-_drag.dx / KitoChatComposer.cancelDistance).clamp(0.0, 1.0);
    final recent = _levels.length > 30
        ? _levels.sublist(_levels.length - 30)
        : List.of(_levels);
    final padded = [
      for (var i = recent.length; i < 30; i++) 0.05,
      ...recent,
    ];
    final simulated = _activeRecorder?.isSimulated ?? false;
    final elapsed =
        KitoChatDateFormat.duration(Duration(seconds: _elapsed.inSeconds));
    return Semantics(
      container: true,
      liveRegion: true,
      label: KitoChatStrings.of(context, 'recording', {'duration': elapsed}),
      child: Row(children: [
        if (locked)
          KitoChatIconButton(
            icon: Icons.delete_rounded,
            label: KitoChatStrings.of(context, 'deleteRecording'),
            color: kito.colors.danger,
            background: kito.colors.danger.withValues(alpha: 0.12),
            onPressed: _cancelRecording,
          ),
        Expanded(
          child: Container(
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding:
                EdgeInsetsDirectional.symmetric(horizontal: kito.spacing.md),
            decoration: BoxDecoration(
              color: kito.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(19),
            ),
            child: ExcludeSemantics(
              child: Row(children: [
                _BlinkingDot(color: kito.colors.danger),
                SizedBox(width: kito.spacing.sm),
                Text(
                  elapsed,
                  style: kito.typography.bodyEmphasized.copyWith(
                    color: kito.colors.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(width: kito.spacing.sm),
                if (locked)
                  Expanded(
                    child: KitoChatWaveformView(
                      samples: padded,
                      progress: 1,
                      activeColor: kito.colors.danger.withValues(alpha: 0.85),
                      barWidth: 2.5,
                      height: 22,
                    ),
                  )
                else ...[
                  SizedBox(
                    width: 70,
                    child: KitoChatWaveformView(
                      samples: padded,
                      progress: 1,
                      activeColor: kito.colors.danger.withValues(alpha: 0.85),
                      barWidth: 2.5,
                      height: 22,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Transform.translate(
                        offset: Offset(
                            (_drag.dx * 0.5).clamp(
                                    -KitoChatComposer.cancelDistance, 0.0) *
                                (context.isRtl ? -1 : 1),
                            0),
                        child: Opacity(
                          opacity: 1 - cancelProgress * 0.9,
                          child: _SlideToCancel(
                              color:
                                  kito.colors.onSurface.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                  ),
                ],
                if (simulated) ...[
                  SizedBox(width: kito.spacing.xs),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kito.radii.pill),
                      border: Border.all(
                          color: kito.colors.onSurface.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      KitoChatStrings.of(context, 'preview'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kito.colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _actionButton(BuildContext context, KitoChatAccent accent) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    final recording = _phase == KitoChatRecordingPhase.recording;
    final lockProgress =
        (-_drag.dy / KitoChatComposer.lockDistance).clamp(0.0, 1.0);
    final send = _showsSend;
    final level = _levels.isEmpty ? 0.0 : _levels.last;
    final dx = recording
        ? _drag.dx.clamp(-KitoChatComposer.cancelDistance, 0.0) *
            (context.isRtl ? -1 : 1)
        : 0.0;
    final dy = recording
        ? _drag.dy.clamp(-KitoChatComposer.lockDistance, 0.0) * 0.5
        : 0.0;
    final button = SizedBox.square(
      dimension: 44,
      child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (recording)
              Positioned(
                bottom: 44 + 14,
                child:
                    _LockIndicator(progress: lockProgress, tint: accent.tint),
              ),
            Transform.translate(
              offset: Offset(dx, dy),
              child: AnimatedScale(
                scale: recording ? 1.45 : 1,
                duration: KitoMotion.of(context, kito.motion.medium),
                curve: reduce ? Curves.easeOut : kito.motion.spring,
                child: Stack(alignment: Alignment.center, children: [
                  if (recording)
                    AnimatedScale(
                      scale: reduce ? 1.7 : 1.6 + level * 0.7,
                      duration: const Duration(milliseconds: 80),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.tint.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: KitoMotion.of(context, kito.motion.medium),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.tint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.tint
                              .withValues(alpha: recording ? 0.45 : 0.2),
                          blurRadius: recording ? 12 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _SendGlyph(
                        send: send, color: accent.onTint, bounce: _sendCount),
                  ),
                ]),
              ),
            ),
          ]),
    );
    return Semantics(
      button: true,
      label: KitoChatStrings.of(context, send ? 'send' : 'record'),
      hint: send ? null : KitoChatStrings.of(context, 'recordHint'),
      onTap: () => send ? _send() : _showHint('recordHint'),
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: button,
        ),
      ),
    );
  }
}

/// The microphone that turns into a paper plane, bouncing up on each send.
class _SendGlyph extends StatelessWidget {
  const _SendGlyph(
      {required this.send, required this.color, required this.bounce});
  final bool send;
  final Color color;
  final int bounce;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final reduce = context.reduceMotion;
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, kito.motion.medium),
      switchInCurve: reduce ? Curves.easeOut : kito.motion.spring,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: reduce
            ? child
            : RotationTransition(
                turns: Tween(begin: -0.12, end: 0.0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
      ),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$send-$bounce'),
        tween: Tween(begin: reduce || bounce == 0 ? 0 : 1, end: 0),
        duration: KitoMotion.of(context, const Duration(milliseconds: 420)),
        curve: Curves.easeOut,
        builder: (context, t, child) =>
            Transform.translate(offset: Offset(0, -6 * t), child: child),
        child: Icon(send ? Icons.send_rounded : Icons.mic_rounded,
            size: 18, color: color),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.reply, required this.tint, this.onCancel});
  final KitoChatReply reply;
  final Color tint;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Container(
      padding: EdgeInsetsDirectional.only(
          start: kito.spacing.md, end: kito.spacing.xs),
      decoration: BoxDecoration(
        color: kito.colors.surface,
        borderRadius: BorderRadius.circular(kito.radii.lg),
        border: Border.all(color: kito.colors.border.withValues(alpha: 0.7)),
      ),
      child: Row(children: [
        Icon(Icons.reply_rounded, size: 18, color: tint),
        SizedBox(width: kito.spacing.sm),
        Container(
          width: 3,
          height: 34,
          decoration: BoxDecoration(
              color: tint, borderRadius: BorderRadius.circular(2)),
        ),
        SizedBox(width: kito.spacing.sm),
        Expanded(
          child: Semantics(
            container: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KitoChatStrings.of(
                      context, 'replyingTo', {'name': reply.authorName}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kito.typography.caption
                      .copyWith(fontWeight: FontWeight.w600, color: tint),
                ),
                Row(children: [
                  if (reply.icon != null) ...[
                    Icon(reply.icon,
                        size: 13,
                        color: kito.colors.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      reply.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kito.typography.caption.copyWith(
                          color: kito.colors.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
        if (onCancel != null)
          KitoChatIconButton(
            icon: Icons.close_rounded,
            label: KitoChatStrings.of(context, 'cancelReply'),
            onPressed: onCancel!,
            size: 26,
            iconSize: 14,
            color: kito.colors.onSurface.withValues(alpha: 0.7),
          ),
        if (onCancel == null) SizedBox(height: 50, width: kito.spacing.sm),
      ]),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: kito.spacing.md, vertical: kito.spacing.xs + 2),
        decoration: BoxDecoration(
          color: kito.colors.surface,
          borderRadius: BorderRadius.circular(kito.radii.pill),
          border: Border.all(color: kito.colors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: kito.typography.caption.copyWith(color: kito.colors.onSurface),
        ),
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot({required this.color});
  final Color color;

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.25).animate(_c),
        child: Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      );
}

class _SlideToCancel extends StatefulWidget {
  const _SlideToCancel({required this.color});
  final Color color;

  @override
  State<_SlideToCancel> createState() => _SlideToCancelState();
}

class _SlideToCancelState extends State<_SlideToCancel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = context.isRtl;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            -6 * Curves.easeInOut.transform(_c.value) * (rtl ? -1 : 1), 0),
        child: child,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.chevron_left_rounded, size: 16, color: widget.color),
        Flexible(
            child: Text(
          KitoChatStrings.of(context, 'slideToCancel'),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: widget.color),
        )),
      ]),
    );
  }
}

class _LockIndicator extends StatelessWidget {
  const _LockIndicator({required this.progress, required this.tint});
  final double progress;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final done = progress >= 1;
    final color = done ? tint : kito.colors.onSurface.withValues(alpha: 0.6);
    return Semantics(
      label: KitoChatStrings.of(context, 'slideUpToLock'),
      child: Container(
        width: 36,
        height: 76 - progress * 20,
        decoration: BoxDecoration(
          color: kito.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kito.colors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Transform.translate(
            offset: Offset(0, progress * 6),
            child: Icon(done ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: 1 - progress,
            child:
                Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: color),
          ),
        ]),
      ),
    );
  }
}
