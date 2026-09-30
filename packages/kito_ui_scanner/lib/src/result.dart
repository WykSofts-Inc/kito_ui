// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'code.dart';

/// What the customer can do with a scan.
enum KitoScanActionKind {
  /// Open a link.
  open,

  /// Copy the text (handled by the card, then reported).
  copy,

  /// Call a number.
  call,

  /// Write an email.
  email,

  /// Send a text.
  message,

  /// Join a Wi-Fi network.
  joinWifi,

  /// Pay a till, paybill or phone.
  pay,

  /// Save a contact.
  addContact,

  /// Get directions.
  directions,

  /// Search the web for a product or text.
  search,
}

/// One button on the result card. The kit shows it; [KitoScanResultCard.onAction] does it.
@immutable
class KitoScanAction {
  /// Creates an action.
  const KitoScanAction(this.kind, this.label, this.icon, this.value);

  /// What it does.
  final KitoScanActionKind kind;

  /// "Open link".
  final String label;

  /// A matching icon.
  final IconData icon;

  /// The thing to act on: the URL, number, password or raw text.
  final String value;

  /// The actions that make sense for [code], most useful first. Copy is always last.
  static List<KitoScanAction> forCode(KitoScannedCode code) {
    final p = code.payload;
    final primary = switch (p) {
      KitoScanUrl(:final uri) => [
        KitoScanAction(
          KitoScanActionKind.open,
          'Open link',
          Icons.open_in_new_rounded,
          uri.toString(),
        ),
      ],
      KitoScanWifi(:final ssid) => [
        KitoScanAction(
          KitoScanActionKind.joinWifi,
          'Join network',
          Icons.wifi_rounded,
          ssid,
        ),
      ],
      KitoScanContact(:final phones) => [
        KitoScanAction(
          KitoScanActionKind.addContact,
          'Add contact',
          Icons.person_add_alt_1_rounded,
          code.raw,
        ),
        if (phones.isNotEmpty)
          KitoScanAction(
            KitoScanActionKind.call,
            'Call',
            Icons.call_rounded,
            phones.first,
          ),
      ],
      KitoScanPhone(:final number) => [
        KitoScanAction(
          KitoScanActionKind.call,
          'Call',
          Icons.call_rounded,
          number,
        ),
        KitoScanAction(
          KitoScanActionKind.message,
          'Text',
          Icons.sms_rounded,
          number,
        ),
      ],
      KitoScanEmail(:final address) => [
        KitoScanAction(
          KitoScanActionKind.email,
          'Write email',
          Icons.email_rounded,
          address,
        ),
      ],
      KitoScanSms(:final number) => [
        KitoScanAction(
          KitoScanActionKind.message,
          'Send text',
          Icons.sms_rounded,
          number,
        ),
      ],
      KitoScanGeo(:final coordinateText) => [
        KitoScanAction(
          KitoScanActionKind.directions,
          'Directions',
          Icons.directions_rounded,
          coordinateText,
        ),
      ],
      KitoScanPayment(:final number, :final formattedAmount) => [
        KitoScanAction(
          KitoScanActionKind.pay,
          formattedAmount == null ? 'Pay' : 'Pay $formattedAmount',
          Icons.payments_rounded,
          number,
        ),
      ],
      KitoScanProduct(:final digits) => [
        KitoScanAction(
          KitoScanActionKind.search,
          'Look it up',
          Icons.search_rounded,
          digits,
        ),
      ],
      KitoScanText(:final text) => [
        KitoScanAction(
          KitoScanActionKind.search,
          'Search',
          Icons.search_rounded,
          text,
        ),
      ],
    };
    return [
      ...primary,
      KitoScanAction(
        KitoScanActionKind.copy,
        'Copy',
        Icons.copy_rounded,
        switch (p) {
          KitoScanWifi(:final password) => password ?? p.ssid,
          _ => code.raw,
        },
      ),
    ];
  }
}

Color _kindColor(KitoScanPayload p) => switch (p) {
  KitoScanUrl() => const Color(0xFF2F80ED),
  KitoScanWifi() => const Color(0xFF00A9A5),
  KitoScanContact() => const Color(0xFF8C5CF0),
  KitoScanPhone() || KitoScanSms() => const Color(0xFF21A86B),
  KitoScanEmail() => const Color(0xFFF58C29),
  KitoScanGeo() => const Color(0xFFE5484D),
  KitoScanPayment() => const Color(0xFF2FB24C),
  KitoScanProduct() => const Color(0xFFF5A524),
  KitoScanText() => const Color(0xFF6B7280),
};

/// The card for a scan: what kind of code it is, the key facts (a Wi-Fi password you can
/// reveal, a till number and amount, a contact's numbers) and the right actions.
///
/// ```dart
/// KitoScanResultCard(
///   code: code,
///   onAction: (action) => switch (action.kind) {
///     KitoScanActionKind.open => launchUrl(Uri.parse(action.value)),
///     _ => null,
///   },
///   onScanAgain: controller.start,
/// )
/// ```
class KitoScanResultCard extends StatefulWidget {
  /// Creates a card.
  const KitoScanResultCard({
    super.key,
    required this.code,
    this.onAction,
    this.onScanAgain,
    this.actions,
  });

  /// The scan.
  final KitoScannedCode code;

  /// Called for every action; copy has already been done.
  final ValueChanged<KitoScanAction>? onAction;

  /// Shows **Scan again** when set.
  final VoidCallback? onScanAgain;

  /// Replaces [KitoScanAction.forCode].
  final List<KitoScanAction>? actions;

  @override
  State<KitoScanResultCard> createState() => _KitoScanResultCardState();
}

class _KitoScanResultCardState extends State<KitoScanResultCard> {
  bool _reveal = false;
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _run(KitoScanAction a) {
    HapticFeedback.selectionClick();
    if (a.kind == KitoScanActionKind.copy) {
      Clipboard.setData(ClipboardData(text: a.value));
      setState(() => _copied = true);
      _reset?.cancel();
      _reset = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _copied = false);
      });
    }
    widget.onAction?.call(a);
  }

  List<(String, String)> _details(KitoScanPayload p) => switch (p) {
    KitoScanUrl(:final uri) => [('Address', uri.toString())],
    KitoScanWifi(:final security, :final hidden) => [
      ('Security', security.title),
      if (hidden) ('Visibility', 'Hidden network'),
    ],
    KitoScanContact(
      :final phones,
      :final emails,
      :final organization,
      :final jobTitle,
      :final address,
      :final website,
    ) =>
      [
        if (organization != null)
          (
            'Company',
            [organization, if (jobTitle != null) jobTitle].join(' · '),
          ),
        for (final ph in phones) ('Phone', ph),
        for (final e in emails) ('Email', e),
        if (address != null) ('Address', address),
        if (website != null) ('Website', website),
      ],
    KitoScanPhone(:final number) => [('Number', number)],
    KitoScanEmail(:final subject, :final body) => [
      if (subject != null) ('Subject', subject),
      if (body != null) ('Message', body),
    ],
    KitoScanSms(:final body) => [if (body != null) ('Message', body)],
    KitoScanGeo(:final coordinateText) => [('Coordinates', coordinateText)],
    KitoScanPayment(
      :final kind,
      :final number,
      :final account,
      :final formattedAmount,
      :final note,
    ) =>
      [
        (kind.title, number),
        if (account != null) ('Account', account),
        if (formattedAmount != null) ('Amount', formattedAmount),
        if (note != null) ('Reference', note),
      ],
    KitoScanProduct(:final format, :final isValid, :final origin) => [
      ('Format', format.title),
      ('Check digit', isValid ? 'Valid' : 'Doesn’t match'),
      if (origin != null) ('Registered in', origin),
    ],
    KitoScanText() => const [],
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final p = widget.code.payload;
    final color = _kindColor(p);
    final muted = theme.colors.onSurface.withValues(alpha: 0.6);
    final actions = widget.actions ?? KitoScanAction.forCode(widget.code);
    final primary =
        actions.where((a) => a.kind != KitoScanActionKind.copy).toList();
    final copy =
        actions.where((a) => a.kind == KitoScanActionKind.copy).firstOrNull;
    final t = widget.code.scannedAt;
    final stamp =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Material(
      color: theme.colors.surface,
      borderRadius: BorderRadius.circular(theme.radii.xl),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: context.reduceMotion ? 1 : 0.4, end: 1),
                  duration: KitoMotion.of(context, theme.motion.slow),
                  curve: const KitoSpringCurve(),
                  builder:
                      (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(p.icon, color: color),
                  ),
                ),
                SizedBox(width: theme.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.kindTitle.toUpperCase(),
                        style: theme.typography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${widget.code.format.title} · $stamp',
                        style: theme.typography.caption.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                if (copy != null)
                  IconButton(
                    tooltip: _copied ? 'Copied' : copy.label,
                    onPressed: () => _run(copy),
                    icon: AnimatedSwitcher(
                      duration: KitoMotion.of(context, theme.motion.fast),
                      transitionBuilder:
                          (c, a) => ScaleTransition(scale: a, child: c),
                      child: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        key: ValueKey(_copied),
                        color: _copied ? theme.colors.success : muted,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: theme.spacing.md),
            Semantics(
              header: true,
              child: SelectableText(
                p is KitoScanPayment && p.merchant != null
                    ? p.merchant!
                    : p.summary,
                maxLines: 3,
                style: theme.typography.title.copyWith(
                  color: theme.colors.onSurface,
                ),
              ),
            ),
            for (final (label, value) in _details(p))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: MergeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 104,
                        child: Text(
                          label,
                          style: theme.typography.caption.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          value,
                          style: theme.typography.label.copyWith(
                            color: theme.colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (p is KitoScanWifi && p.password != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(
                        'Password',
                        style: theme.typography.caption.copyWith(color: muted),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        label:
                            _reveal
                                ? 'Password ${p.password}'
                                : 'Password hidden',
                        excludeSemantics: true,
                        child: Text(
                          _reveal
                              ? p.password!
                              : '•' * p.password!.length.clamp(6, 14),
                          style: theme.typography.label.copyWith(
                            color: theme.colors.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: _reveal ? 0.5 : 2,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _reveal ? 'Hide password' : 'Show password',
                      onPressed: () => setState(() => _reveal = !_reveal),
                      icon: Icon(
                        _reveal
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            if (primary.isNotEmpty || widget.onScanAgain != null) ...[
              SizedBox(height: theme.spacing.lg),
              for (final (i, a) in primary.indexed) ...[
                if (i > 0) SizedBox(height: theme.spacing.sm),
                i == 0
                    ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colors.primary,
                        foregroundColor: theme.colors.onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        textStyle: theme.typography.button,
                      ),
                      onPressed: () => _run(a),
                      icon: Icon(a.icon, size: 18),
                      label: Text(a.label),
                    )
                    : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colors.onSurface,
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: theme.colors.border),
                        textStyle: theme.typography.button,
                      ),
                      onPressed: () => _run(a),
                      icon: Icon(a.icon, size: 18),
                      label: Text(a.label),
                    ),
              ],
              if (widget.onScanAgain != null)
                Padding(
                  padding: EdgeInsets.only(top: theme.spacing.sm),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: muted,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: widget.onScanAgain,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Scan again'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a [KitoScanResultCard] in a bottom sheet.
abstract final class KitoScanResultSheet {
  /// Opens the sheet; completes when it closes.
  static Future<void> show(
    BuildContext context,
    KitoScannedCode code, {
    ValueChanged<KitoScanAction>? onAction,
    VoidCallback? onScanAgain,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              child: KitoScanResultCard(
                code: code,
                onAction: onAction,
                onScanAgain:
                    onScanAgain == null
                        ? null
                        : () {
                          Navigator.of(context).pop();
                          onScanAgain();
                        },
              ),
            ),
          ),
        ),
  );
}
