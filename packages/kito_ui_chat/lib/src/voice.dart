// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'models.dart';
import 'strings.dart';
import 'timeline.dart';
import 'waveform.dart';

// MARK: - Adapters

/// Plays a voice note's recording. The chat kit ships no audio plugin: implement this with the
/// player you already use (just_audio, audioplayers…) and hand a factory to `KitoChatView` or
/// `KitoChatBubble`. Without one, playback is simulated so the waveform still plays through.
abstract interface class KitoChatAudioPlayer {
  /// Prepares [url] for playback.
  Future<void> load(Uri url);

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Jumps to [position].
  Future<void> seek(Duration position);

  /// Sets the playback rate (1, 1.5 or 2).
  Future<void> setSpeed(double rate);

  /// The playback position, while playing.
  Stream<Duration> get positions;

  /// Fires when playback reaches the end.
  Stream<void> get completions;

  /// Releases the player.
  Future<void> dispose();
}

/// How a recorder answered [KitoChatVoiceRecorder.start].
enum KitoChatRecordingStart {
  /// Recording.
  started,

  /// The permission prompt was shown; try again once it's answered.
  askedPermission,

  /// The microphone can't be used.
  unavailable,
}

/// Records voice notes for [KitoChatComposer]-style hold-to-record. The chat kit ships no audio
/// plugin: implement this with the recorder you use (record, flutter_sound…). Without one the
/// composer records a clearly labelled simulated preview.
abstract interface class KitoChatVoiceRecorder {
  /// Starts recording.
  Future<KitoChatRecordingStart> start();

  /// Loudness 0–1, roughly twenty times a second while recording.
  Stream<double> get levels;

  /// Stops and returns where the recording was saved (null if nothing was kept).
  Future<Uri?> stop();

  /// Stops and throws the recording away.
  Future<void> cancel();

  /// True for recorders that don't use a real microphone.
  bool get isSimulated;
}

/// A recorder that makes up speech-like levels, for previews, tests and the DevKit.
class KitoChatSimulatedRecorder implements KitoChatVoiceRecorder {
  /// Creates a simulated recorder.
  KitoChatSimulatedRecorder({this.interval = const Duration(milliseconds: 50)});

  /// How often a level is produced.
  final Duration interval;

  StreamController<double>? _controller;
  Timer? _timer;
  int _ticks = 0;
  final _random = math.Random(7);

  @override
  bool get isSimulated => true;

  @override
  Stream<double> get levels =>
      (_controller ??= StreamController<double>.broadcast()).stream;

  @override
  Future<KitoChatRecordingStart> start() async {
    _controller ??= StreamController<double>.broadcast();
    _ticks = 0;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      final t = _ticks++ * interval.inMilliseconds / 1000;
      final speech = (math.sin(t * 3.1) * math.sin(t * 7.3 + 1.2)).abs();
      _controller
          ?.add(math.min(1, 0.12 + 0.7 * speech + _random.nextDouble() * 0.15));
    });
    return KitoChatRecordingStart.started;
  }

  @override
  Future<Uri?> stop() async {
    _timer?.cancel();
    return null;
  }

  @override
  Future<void> cancel() async => _timer?.cancel();
}

// MARK: - Playback

/// Drives one voice note: progress, play/pause, seeking and speed. Uses a
/// [KitoChatAudioPlayer] when given one and a URL, otherwise simulates playback.
class KitoChatVoicePlayback extends ChangeNotifier {
  /// Creates playback for a note [duration] long.
  KitoChatVoicePlayback({
    required Duration duration,
    this.url,
    KitoChatAudioPlayer? player,
  })  : duration = duration < const Duration(milliseconds: 100)
            ? const Duration(milliseconds: 100)
            : duration,
        _player = url == null ? null : player;

  /// How long the note is.
  final Duration duration;

  /// The recording, if there's one.
  final Uri? url;

  final KitoChatAudioPlayer? _player;
  bool _loaded = false;
  StreamSubscription<Duration>? _positions;
  StreamSubscription<void>? _completions;
  Timer? _ticker;

  double _progress = 0;
  bool _isPlaying = false;
  KitoChatPlaybackSpeed _speed = KitoChatPlaybackSpeed.normal;
  bool _disposed = false;

  /// How much has played, 0–1.
  double get progress => _progress;

  /// Whether it's playing.
  bool get isPlaying => _isPlaying;

  /// The playback speed.
  KitoChatPlaybackSpeed get speed => _speed;

  /// How much has played.
  Duration get elapsed => duration * _progress;

  /// Whether a real player is used.
  bool get isSimulated => _player == null;

  /// Plays if paused, pauses if playing.
  void toggle() => _isPlaying ? pause() : play();

  /// Starts or resumes; from the start once it has finished.
  Future<void> play() async {
    if (_progress >= 1) _progress = 0;
    _isPlaying = true;
    _notify();
    final player = _player;
    if (player != null) {
      if (!_loaded) {
        await player.load(url!);
        _loaded = true;
        _positions = player.positions.listen((p) {
          _progress = (p.inMicroseconds / duration.inMicroseconds).clamp(0, 1);
          _notify();
        });
        _completions = player.completions.listen((_) => _finish());
      }
      await player.seek(elapsed);
      await player.setSpeed(_speed.rate);
      await player.play();
    } else {
      _ticker?.cancel();
      _ticker = Timer.periodic(_step, (_) => advance(_step));
    }
  }

  /// Pauses.
  void pause() {
    _isPlaying = false;
    _ticker?.cancel();
    _player?.pause();
    _notify();
  }

  /// Jumps to [fraction] (0–1) of the note.
  void seek(double fraction) {
    _progress = fraction.clamp(0.0, 1.0);
    _player?.seek(elapsed);
    _notify();
  }

  /// 1× → 1.5× → 2× → 1×.
  void cycleSpeed() {
    _speed = _speed.next;
    _player?.setSpeed(_speed.rate);
    _notify();
  }

  /// Advances simulated playback by [step]; called by the internal timer.
  @visibleForTesting
  void advance(Duration step) {
    if (!_isPlaying) return;
    _progress = math.min(
        1,
        _progress +
            step.inMicroseconds * _speed.rate / duration.inMicroseconds);
    if (_progress >= 1) {
      _finish();
    } else {
      _notify();
    }
  }

  static const _step = Duration(milliseconds: 33);

  void _finish() {
    _isPlaying = false;
    _ticker?.cancel();
    _progress = 0;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _positions?.cancel();
    _completions?.cancel();
    _player?.dispose();
    super.dispose();
  }
}

// MARK: - Voice note

/// Play/pause, a scrubbable waveform, the time and a 1× / 1.5× / 2× pill — the inside of a
/// voice-note bubble.
class KitoChatVoiceNote extends StatefulWidget {
  /// Creates a voice note.
  const KitoChatVoiceNote({
    super.key,
    required this.voice,
    this.seed = 'voice',
    this.foreground,
    this.accent,
    this.onAccent,
    this.onFill = false,
    this.audioPlayer,
  });

  /// The note.
  final KitoChatVoiceContent voice;

  /// Seeds the placeholder waveform when [KitoChatVoiceContent.waveform] is empty.
  final String seed;

  /// Text colour; the theme's text colour when null.
  final Color? foreground;

  /// Play button and played bars; the primary colour when null.
  final Color? accent;

  /// The glyph on the play button; the colour on primary when null.
  final Color? onAccent;

  /// True inside a bubble filled with the accent: controls draw in [foreground] instead.
  final bool onFill;

  /// Makes a real player for notes with a URL.
  final KitoChatAudioPlayer Function()? audioPlayer;

  @override
  State<KitoChatVoiceNote> createState() => _KitoChatVoiceNoteState();
}

class _KitoChatVoiceNoteState extends State<KitoChatVoiceNote> {
  late KitoChatVoicePlayback _playback = _make();
  late List<double> _bars = _makeBars();

  KitoChatVoicePlayback _make() => KitoChatVoicePlayback(
        duration: widget.voice.duration,
        url: widget.voice.url,
        player: widget.voice.url == null ? null : widget.audioPlayer?.call(),
      );

  List<double> _makeBars() => KitoChatWaveform.downsample(
      widget.voice.waveform.isEmpty
          ? KitoChatWaveform.placeholder(
              count: 32, seed: KitoChatWaveform.seedFor(widget.seed))
          : widget.voice.waveform,
      32);

  @override
  void didUpdateWidget(KitoChatVoiceNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voice != widget.voice) {
      _playback.dispose();
      _playback = _make();
      _bars = _makeBars();
    }
  }

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final foreground = widget.foreground ?? kito.colors.onSurface;
    final accent = widget.accent ?? kito.colors.primary;
    final onAccent = widget.onAccent ?? kito.colors.onPrimary;
    final buttonFill = widget.onFill ? foreground : accent;
    final glyph = widget.onFill ? accent : onAccent;
    return ListenableBuilder(
      listenable: _playback,
      builder: (context, _) {
        final p = _playback;
        final shownTime =
            p.isPlaying || p.progress > 0 ? p.elapsed : p.duration;
        return Semantics(
          container: true,
          label: KitoChatStrings.of(context, 'voiceMessageLength',
              {'duration': KitoChatDateFormat.duration(p.duration)}),
          value: p.isPlaying
              ? KitoChatStrings.of(
                  context, 'playing', {'percent': (p.progress * 100).floor()})
              : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Semantics(
              button: true,
              label:
                  KitoChatStrings.of(context, p.isPlaying ? 'pause' : 'play'),
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    p.toggle();
                  },
                  child: KitoPressable(
                    scale: 0.9,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: buttonFill, shape: BoxShape.circle),
                          child: AnimatedSwitcher(
                            duration: KitoMotion.of(context, kito.motion.fast),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Icon(
                              p.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(p.isPlaying),
                              size: 22,
                              color: glyph,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: kito.spacing.xs),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 128,
                  child: KitoChatWaveformView(
                    samples: _bars,
                    progress: p.progress,
                    activeColor: widget.onFill ? foreground : accent,
                    inactiveColor:
                        (widget.onFill ? foreground : kito.colors.onSurface)
                            .withValues(alpha: 0.3),
                    onScrub: p.seek,
                  ),
                ),
                SizedBox(height: kito.spacing.xs),
                Text(
                  KitoChatDateFormat.duration(shownTime),
                  style: kito.typography.caption.copyWith(
                    color: foreground.withValues(alpha: 0.75),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SizedBox(width: kito.spacing.sm),
            Semantics(
              button: true,
              label: KitoChatStrings.of(
                  context, 'speed', {'speed': p.speed.label}),
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: p.cycleSpeed,
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: AnimatedContainer(
                        duration: KitoMotion.of(context, kito.motion.fast),
                        constraints: const BoxConstraints(minWidth: 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kito.radii.pill),
                          color: (widget.onFill
                                  ? foreground
                                  : kito.colors.onSurface)
                              .withValues(alpha: 0.14),
                        ),
                        child: Text(
                          p.speed.label,
                          textAlign: TextAlign.center,
                          style: kito.typography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.onFill
                                ? foreground
                                : kito.colors.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
