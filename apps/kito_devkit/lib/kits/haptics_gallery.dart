// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_haptics/kito_ui_haptics.dart';

import '../catalog/catalog.dart';

/// The gallery for kito_ui_haptics.
final hapticsKit = KitEntry(
  title: 'Haptics',
  package: 'kito_ui_haptics',
  blurb: 'semantic haptics, timed patterns and a visualizer',
  icon: Icons.vibration_rounded,
  category: KitCategory.feedback,
  isNew: true,
  sections: [
    KitSection('Semantic', Icons.touch_app_rounded, [
      KitSample(
        title: 'Success',
        subtitle: 'A light tap rising into a medium one — it went well.',
        code: '''await mpesa.send(to: amina, amount: 1500);
KitoHaptics.success();''',
        builder: (_) => const _Feel(
            label: 'Payment sent',
            icon: Icons.check_circle_rounded,
            haptic: KitoHaptics.success),
      ),
      KitSample(
        title: 'Warning',
        subtitle: 'Two even taps before something you can’t undo.',
        code: '''KitoHaptics.warning();
showDialog(context: context, builder: (_) => const ConfirmDeleteDialog());''',
        builder: (_) => const _Feel(
            label: 'Delete saved card',
            icon: Icons.warning_amber_rounded,
            haptic: KitoHaptics.warning),
      ),
      KitSample(
        title: 'Error',
        subtitle: 'Three heavy taps — that didn’t work.',
        code: '''if (!pinIsCorrect) KitoHaptics.error();''',
        builder: (_) => const _Feel(
            label: 'Wrong M-Pesa PIN',
            icon: Icons.error_rounded,
            haptic: KitoHaptics.error),
      ),
      KitSample(
        title: 'Selection',
        subtitle: 'A crisp tick as a picker moves.',
        code: '''SegmentedButton<String>(
  selected: {period},
  onSelectionChanged: (s) {
    KitoHaptics.selection();
    setState(() => period = s.first);
  },
  segments: ...,
);''',
        builder: (_) => const _Selection(),
      ),
      KitSample(
        title: 'Impact weights',
        subtitle: 'Selection, light, medium, heavy and the system vibration.',
        code: '''KitoHaptics.impact(KitoHapticImpactStyle.light);
KitoHaptics.impact(KitoHapticImpactStyle.heavy);''',
        builder: (_) => const _Impacts(),
      ),
      KitSample(
        title: 'Settings switch',
        subtitle: 'One flag silences every haptic in the app.',
        code: '''SwitchListTile(
  title: const Text('Haptic feedback'),
  value: KitoHaptics.isEnabled,
  onChanged: (on) => setState(() => KitoHaptics.isEnabled = on),
);''',
        builder: (_) => const _Switch(),
      ),
    ]),
    KitSection('Patterns', Icons.graphic_eq_rounded, [
      KitSample(
        title: 'Presets',
        subtitle: 'Nine patterns — tap one to play it and watch the playhead.',
        code: '''KitoHaptics.play(KitoHapticPattern.heartbeat);
// Also: successChime, ticks, rumble, knock, rampUp, rampDown, failure, nudge.''',
        builder: (_) => const _Presets(),
      ),
      KitSample(
        title: 'Visualizer',
        subtitle: 'Height is intensity, colour is sharpness; tap to play.',
        code: '''KitoHapticVisualizer(
  KitoHapticPattern.successChime,
  playedAt: playedAt,
  height: 100,
);''',
        builder: (_) =>
            const _Player(pattern: null, style: KitoHapticVisualizerStyle.bars),
      ),
      KitSample(
        title: 'Waveform',
        subtitle: 'A mirrored envelope, filled in as it plays.',
        code: '''KitoHapticVisualizer(
  KitoHapticPattern.rumble,
  playedAt: playedAt,
  style: KitoHapticVisualizerStyle.waveform,
);''',
        builder: (_) => const _Player(
            pattern: null, style: KitoHapticVisualizerStyle.waveform),
      ),
      KitSample(
        title: 'Your own pattern',
        subtitle: 'Taps and a ramping buzz: a drumroll for a prize draw.',
        code: '''final drumroll = KitoHapticPattern('Drumroll', [
  for (var i = 0; i < 6; i++)
    KitoHapticEvent.tap(Duration(milliseconds: i * 70), intensity: 0.4 + i * 0.1, sharpness: 0.8),
  KitoHapticEvent.hold(const Duration(milliseconds: 420),
      duration: const Duration(milliseconds: 500), intensity: 0.2, endIntensity: 1),
  KitoHapticEvent.tap(const Duration(milliseconds: 950), intensity: 1, sharpness: 1),
]);
KitoHaptics.play(drumroll);''',
        builder: (_) =>
            _Player(pattern: _drumroll, style: KitoHapticVisualizerStyle.bars),
      ),
      KitSample(
        title: 'Gentler and repeated',
        subtitle: 'Scale a pattern down, or play it again with a gap.',
        code: '''KitoHaptics.play(KitoHapticPattern.knock.scaled(0.5));
KitoHaptics.play(KitoHapticPattern.nudge.repeated(3, gap: const Duration(milliseconds: 250)));''',
        builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
          _Player(
              pattern: KitoHapticPattern.knock.scaled(0.5),
              style: KitoHapticVisualizerStyle.bars),
          const SizedBox(height: 16),
          _Player(
              pattern: KitoHapticPattern.nudge
                  .repeated(3, gap: const Duration(milliseconds: 250)),
              style: KitoHapticVisualizerStyle.bars),
        ]),
      ),
      KitSample(
        title: 'Ticks dial',
        subtitle:
            'Build a pattern from a count: drag to choose how many clicks.',
        code:
            '''KitoHaptics.play(KitoHapticPattern.ticksOf(count, const Duration(milliseconds: 60)));''',
        builder: (_) => const _Ticks(),
      ),
      KitSample(
        title: 'What actually plays',
        subtitle:
            'Each pattern becomes timed platform taps — here is the list.',
        code:
            '''for (final impact in KitoHapticPattern.successChime.impacts()) {
  print('\${impact.at.inMilliseconds} ms · \${impact.style.name}');
}''',
        builder: (_) => const _ImpactList(),
      ),
    ]),
    KitSection('Reactions', Icons.bolt_rounded, [
      KitSample(
        title: 'When an order is delivered',
        subtitle: 'Play a pattern when a value changes, not on a tap.',
        code: '''KitoHapticOnChange(
  value: order.isDelivered,
  pattern: KitoHapticPattern.successChime,
  child: OrderStatus(order),
);''',
        builder: (_) => const _Delivered(),
      ),
      KitSample(
        title: 'When an error appears',
        subtitle: 'A filter fires only when the field turns invalid.',
        code: '''KitoHapticOnChange<bool>(
  value: phoneIsInvalid,
  when: (before, now) => now,
  haptic: KitoHaptics.error,
  child: phoneField,
);''',
        builder: (_) => const _FormError(),
      ),
      KitSample(
        title: 'Stop a pattern',
        subtitle: 'A long rumble, cut short.',
        code: '''KitoHaptics.play(KitoHapticPattern.rumble.repeated(4));
// Later:
KitoHaptics.stop();''',
        builder: (_) => const _Stop(),
      ),
    ]),
  ],
);

final _drumroll = KitoHapticPattern('Drumroll', [
  for (var i = 0; i < 6; i++)
    KitoHapticEvent.tap(Duration(milliseconds: i * 70),
        intensity: 0.4 + i * 0.1, sharpness: 0.8),
  KitoHapticEvent.hold(const Duration(milliseconds: 420),
      duration: const Duration(milliseconds: 500),
      intensity: 0.2,
      endIntensity: 1),
  KitoHapticEvent.tap(const Duration(milliseconds: 950),
      intensity: 1, sharpness: 1),
]);

// MARK: Semantic

class _Feel extends StatelessWidget {
  const _Feel({required this.label, required this.icon, required this.haptic});

  final String label;
  final IconData icon;
  final Future<void> Function() haptic;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: haptic,
            icon: Icon(icon),
            label: Text(label),
          ),
          const SizedBox(height: 8),
          Text('Tap to feel it on a phone',
              style: context.kito.typography.caption.copyWith(
                  color: context.kito.colors.onBackground
                      .withValues(alpha: 0.55))),
        ],
      );
}

class _Selection extends StatefulWidget {
  const _Selection();

  @override
  State<_Selection> createState() => _SelectionState();
}

class _SelectionState extends State<_Selection> {
  String _period = 'Weekly';

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
        selected: {_period},
        onSelectionChanged: (s) {
          KitoHaptics.selection();
          setState(() => _period = s.first);
        },
        segments: const [
          ButtonSegment(value: 'Daily', label: Text('Daily')),
          ButtonSegment(value: 'Weekly', label: Text('Weekly')),
          ButtonSegment(value: 'Monthly', label: Text('Monthly')),
        ],
      );
}

class _Impacts extends StatelessWidget {
  const _Impacts();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final s in KitoHapticImpactStyle.values)
            OutlinedButton(
              onPressed: () => KitoHaptics.impact(s),
              child: Text(s.name),
            ),
        ],
      );
}

class _Switch extends StatefulWidget {
  const _Switch();

  @override
  State<_Switch> createState() => _SwitchState();
}

class _SwitchState extends State<_Switch> {
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 320,
        child: Material(
          type: MaterialType.transparency,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SwitchListTile(
              title: const Text('Haptic feedback'),
              subtitle: const Text('Vibrate on taps, payments and errors'),
              value: KitoHaptics.isEnabled,
              onChanged: (on) => setState(() => KitoHaptics.isEnabled = on),
            ),
            const TextButton(
                onPressed: KitoHaptics.success, child: Text('Try it')),
          ]),
        ),
      );
}

// MARK: Patterns

class _Player extends StatefulWidget {
  const _Player({required this.pattern, required this.style});

  /// Null plays a preset picked with chips.
  final KitoHapticPattern? pattern;
  final KitoHapticVisualizerStyle style;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> {
  late KitoHapticPattern _pattern = widget.pattern ??
      (widget.style == KitoHapticVisualizerStyle.waveform
          ? KitoHapticPattern.rumble
          : KitoHapticPattern.successChime);
  DateTime? _playedAt;

  void _play() {
    KitoHaptics.play(_pattern);
    setState(() => _playedAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pattern == null) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final p in KitoHapticPattern.presets)
                  ChoiceChip(
                    label: Text(p.name),
                    selected: p == _pattern,
                    onSelected: (_) => setState(() {
                      _pattern = p;
                      _playedAt = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: _play,
            child: KitoSurface(
              border: true,
              padding: const EdgeInsets.all(8),
              child: KitoHapticVisualizer(_pattern,
                  playedAt: _playedAt, style: widget.style, height: 100),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text(_pattern.name,
                  overflow: TextOverflow.ellipsis,
                  style: kito.typography.headline),
            ),
            Text('${_pattern.duration.inMilliseconds} ms',
                style: kito.typography.caption),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Play',
              onPressed: _play,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Presets extends StatefulWidget {
  const _Presets();

  @override
  State<_Presets> createState() => _PresetsState();
}

class _PresetsState extends State<_Presets> {
  final Map<String, DateTime> _played = {};

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in KitoHapticPattern.presets)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                KitoHaptics.play(p);
                setState(() => _played[p.name] = DateTime.now());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(children: [
                  SizedBox(
                      width: 104,
                      child: Text(p.name, style: kito.typography.label)),
                  Expanded(
                    child: KitoHapticVisualizer(p,
                        playedAt: _played[p.name], showGrid: false, height: 44),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Ticks extends StatefulWidget {
  const _Ticks();

  @override
  State<_Ticks> createState() => _TicksState();
}

class _TicksState extends State<_Ticks> {
  double _count = 8;
  DateTime? _playedAt;

  @override
  Widget build(BuildContext context) {
    final pattern = KitoHapticPattern.ticksOf(
        _count.round(), const Duration(milliseconds: 60));
    return SizedBox(
      width: 320,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        KitoHapticVisualizer(pattern, playedAt: _playedAt, height: 70),
        Slider(
          value: _count,
          min: 1,
          max: 20,
          divisions: 19,
          label: '${_count.round()} ticks',
          onChanged: (v) {
            if (v.round() != _count.round()) KitoHaptics.selection();
            setState(() => _count = v);
          },
          onChangeEnd: (_) {
            KitoHaptics.play(pattern);
            setState(() => _playedAt = DateTime.now());
          },
        ),
      ]),
    );
  }
}

class _ImpactList extends StatelessWidget {
  const _ImpactList();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final impacts = KitoHapticPattern.successChime.impacts();
    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Success chime → ${impacts.length} taps',
              style: kito.typography.headline),
          const SizedBox(height: 8),
          for (final i in impacts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(
                    width: 64,
                    child: Text('${i.at.inMilliseconds} ms',
                        style: kito.typography.caption)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: i.intensity, minHeight: 8),
                  ),
                ),
                SizedBox(
                    width: 80,
                    child: Text(i.style.name,
                        textAlign: TextAlign.end,
                        style: kito.typography.caption)),
              ]),
            ),
        ],
      ),
    );
  }
}

// MARK: Reactions

class _Delivered extends StatefulWidget {
  const _Delivered();

  @override
  State<_Delivered> createState() => _DeliveredState();
}

class _DeliveredState extends State<_Delivered> {
  bool _delivered = false;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return KitoHapticOnChange(
      value: _delivered,
      pattern: KitoHapticPattern.successChime,
      child: SizedBox(
        width: 320,
        child: KitoSurface(
          border: true,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            AnimatedSwitcher(
              duration: KitoMotion.of(context, kito.motion.medium),
              child: Icon(
                _delivered
                    ? Icons.check_circle_rounded
                    : Icons.delivery_dining_rounded,
                key: ValueKey(_delivered),
                size: 36,
                color: _delivered ? kito.colors.success : kito.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _delivered
                    ? 'Delivered to Kilimani'
                    : 'Rider Otieno is 3 min away',
                style: kito.typography.headline,
              ),
            ),
            Switch(
                value: _delivered,
                onChanged: (v) => setState(() => _delivered = v)),
          ]),
        ),
      ),
    );
  }
}

class _FormError extends StatefulWidget {
  const _FormError();

  @override
  State<_FormError> createState() => _FormErrorState();
}

class _FormErrorState extends State<_FormError> {
  final _controller = TextEditingController(text: '0712');
  String _text = '0712';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _invalid =>
      _text.replaceAll(RegExp(r'\D'), '').length > 10 ||
      (_text.isNotEmpty && !_text.startsWith('07') && !_text.startsWith('01'));

  @override
  Widget build(BuildContext context) => KitoHapticOnChange<bool>(
        value: _invalid,
        when: (before, now) => now,
        haptic: KitoHaptics.error,
        child: SizedBox(
          width: 300,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            onChanged: (v) => setState(() => _text = v),
            decoration: InputDecoration(
              labelText: 'Phone number',
              hintText: '0712 345 678',
              errorText: _invalid ? 'Use a Kenyan number, 07… or 01…' : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      );
}

class _Stop extends StatefulWidget {
  const _Stop();

  @override
  State<_Stop> createState() => _StopState();
}

class _StopState extends State<_Stop> {
  final _long = KitoHapticPattern.rumble.repeated(4);
  DateTime? _playedAt;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 340,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          KitoHapticVisualizer(_long,
              playedAt: _playedAt,
              style: KitoHapticVisualizerStyle.waveform,
              height: 80),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(
              onPressed: () {
                KitoHaptics.play(_long);
                setState(() => _playedAt = DateTime.now());
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Rumble'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {
                KitoHaptics.stop();
                setState(() => _playedAt = null);
              },
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
            ),
          ]),
        ]),
      );
}
