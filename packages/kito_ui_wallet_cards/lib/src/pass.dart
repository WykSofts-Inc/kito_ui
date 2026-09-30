// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// What a pass is for; it changes the layout.
enum KitoWalletPassKind {
  /// A train, bus or flight: from → to with times.
  boarding,

  /// A concert, match or conference ticket.
  event,

  /// A stamp or points card.
  loyalty,

  /// A discount or voucher.
  coupon,
}

/// A labelled value on a pass: "SEAT 14B", "GATE 3".
@immutable
class KitoWalletPassField {
  /// Creates a field.
  const KitoWalletPassField(this.label, this.value);

  /// Small caps label.
  final String label;

  /// The value.
  final String value;
}

/// One end of a journey.
@immutable
class KitoWalletPassStop {
  /// Creates a stop.
  const KitoWalletPassStop({required this.code, required this.name, this.time});

  /// A short code: "NBO", "MSA".
  final String code;

  /// "Nairobi Terminus".
  final String name;

  /// "08:00".
  final String? time;
}

/// A pass, ticket or loyalty card.
@immutable
class KitoWalletPass {
  /// Creates a pass.
  const KitoWalletPass({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.icon,
    this.colors = const [Color(0xFF1E3A8A), Color(0xFF7C3AED)],
    this.foreground = Colors.white,
    this.from,
    this.to,
    this.fields = const [],
    this.code,
    this.codeLabel,
    this.stamps = 0,
    this.stampsTotal = 0,
    this.headline,
  });

  /// Identifies the pass.
  final String id;

  /// The layout.
  final KitoWalletPassKind kind;

  /// "Madaraka Express", "Java House Rewards".
  final String title;

  /// "Economy · Coach 4", "Gold member".
  final String? subtitle;

  /// Shown in the header; a sensible default per kind when null.
  final IconData? icon;

  /// The header gradient.
  final List<Color> colors;

  /// Text on the header.
  final Color foreground;

  /// Where a boarding pass starts.
  final KitoWalletPassStop? from;

  /// Where it ends.
  final KitoWalletPassStop? to;

  /// Labelled values under the header.
  final List<KitoWalletPassField> fields;

  /// The payload for the code at the bottom; no code when null.
  final String? code;

  /// Under the code, e.g. the booking reference.
  final String? codeLabel;

  /// Stamps collected on a loyalty card.
  final int stamps;

  /// Stamps needed for the reward.
  final int stampsTotal;

  /// A big line for events and coupons: "20% OFF", "Harambee Stars vs Uganda".
  final String? headline;

  /// The header icon.
  IconData get resolvedIcon =>
      icon ??
      switch (kind) {
        KitoWalletPassKind.boarding => Icons.train_rounded,
        KitoWalletPassKind.event => Icons.confirmation_number_rounded,
        KitoWalletPassKind.loyalty => Icons.loyalty_rounded,
        KitoWalletPassKind.coupon => Icons.local_offer_rounded,
      };

  /// What screen readers say about the pass.
  String get semanticLabel => [
        title,
        if (subtitle != null) subtitle!,
        if (from != null && to != null)
          'from ${from!.name}${from!.time == null ? '' : ' at ${from!.time}'} to ${to!.name}${to!.time == null ? '' : ' at ${to!.time}'}',
        if (headline != null) headline!,
        if (kind == KitoWalletPassKind.loyalty && stampsTotal > 0)
          '$stamps of $stampsTotal stamps',
        for (final f in fields) '${f.label} ${f.value}',
      ].join(', ');
}

/// A pass, ticket or loyalty card: a coloured header, the journey or headline, labelled
/// fields, a perforated tear line with notches, and a code at the bottom. Loyalty cards show
/// their stamps.
///
/// The code is a decorative pattern made from [KitoWalletPass.code] — it is not scannable. To
/// show a real QR or barcode, pass [codeBuilder] with your own code widget.
///
/// ```dart
/// KitoWalletPassView(pass: sgrTicket)
/// KitoWalletPassView(pass: ticket, codeBuilder: (data) => MyQrCode(data))
/// ```
class KitoWalletPassView extends StatelessWidget {
  /// Shows [pass].
  const KitoWalletPassView(
      {super.key, required this.pass, this.onTap, this.codeBuilder});

  /// The pass.
  final KitoWalletPass pass;

  /// Called on tap.
  final VoidCallback? onTap;

  /// Draws a real, scannable code for the payload.
  final Widget Function(String data)? codeBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final fg = pass.foreground;
    final body = theme.colors.surface;
    final onBody = theme.colors.onSurface;
    final muted = onBody.withValues(alpha: 0.55);
    const codeSize = 132.0;
    final hasTear = pass.code != null;
    final stubHeight =
        hasTear ? 18 + codeSize + (pass.codeLabel != null ? 28 : 0) + 18 : 0.0;
    final clipper = _TicketClipper(
        radius: theme.radii.xl,
        notch: hasTear ? 12 : 0,
        fromBottom: stubHeight);
    return Semantics(
      container: true,
      button: onTap != null,
      label: pass.semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _TicketShadowPainter(clipper: clipper),
          child: ClipPath(
            clipper: clipper,
            child: ColoredBox(
              color: body,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header.
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart
                            .resolve(Directionality.of(context)),
                        end: AlignmentDirectional.bottomEnd
                            .resolve(Directionality.of(context)),
                        colors: pass.colors.length == 1
                            ? [pass.colors.first, pass.colors.first]
                            : pass.colors,
                      ),
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: fg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: fg.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(pass.resolvedIcon,
                                    size: 19, color: fg),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pass.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.typography.headline
                                            .copyWith(
                                                color: fg,
                                                fontWeight: FontWeight.w700)),
                                    if (pass.subtitle != null)
                                      Text(pass.subtitle!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.typography.caption
                                              .copyWith(
                                                  color: fg.withValues(
                                                      alpha: 0.75))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (pass.from != null && pass.to != null) ...[
                            const SizedBox(height: 18),
                            _Journey(from: pass.from!, to: pass.to!, color: fg),
                          ],
                          if (pass.headline != null) ...[
                            const SizedBox(height: 14),
                            Text(pass.headline!,
                                style: theme.typography.title.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w800,
                                    fontSize:
                                        pass.kind == KitoWalletPassKind.coupon
                                            ? 30
                                            : 22)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (pass.fields.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          for (final f in pass.fields)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(f.label.toUpperCase(),
                                    style: theme.typography.caption.copyWith(
                                        color: muted,
                                        fontSize: 10.5,
                                        letterSpacing: 0.8,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(f.value,
                                    style: theme.typography.bodyEmphasized
                                        .copyWith(color: onBody, fontSize: 15)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  if (pass.kind == KitoWalletPassKind.loyalty &&
                      pass.stampsTotal > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                      child: _Stamps(
                          filled: pass.stamps,
                          total: pass.stampsTotal,
                          color: pass.colors.first,
                          empty: theme.colors.surfaceMuted),
                    ),
                  SizedBox(height: hasTear ? 14 : 16),
                  if (pass.code case final code?)
                    SizedBox(
                      height: stubHeight,
                      child: Column(
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 1),
                            painter: _DashPainter(color: theme.colors.border),
                          ),
                          const Spacer(),
                          SizedBox.square(
                            dimension: codeSize,
                            child: codeBuilder?.call(code) ??
                                KitoWalletPassCode(
                                    data: code, color: onBody, size: codeSize),
                          ),
                          if (pass.codeLabel != null)
                            SizedBox(
                              height: 28,
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(pass.codeLabel!,
                                      style: theme.typography.caption.copyWith(
                                          color: muted,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          const Spacer(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Journey extends StatelessWidget {
  const _Journey({required this.from, required this.to, required this.color});

  final KitoWalletPassStop from;
  final KitoWalletPassStop to;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    Widget stop(KitoWalletPassStop s, CrossAxisAlignment align) => Column(
          crossAxisAlignment: align,
          children: [
            Text(s.code,
                style: TextStyle(
                    color: color,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1)),
            const SizedBox(height: 4),
            Text(s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption
                    .copyWith(color: color.withValues(alpha: 0.8))),
            if (s.time != null)
              Text(s.time!,
                  style: theme.typography.label.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        );
    return Row(
      children: [
        Expanded(child: stop(from, CrossAxisAlignment.start)),
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter:
                          _DashPainter(color: color.withValues(alpha: 0.5)))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Transform.flip(
                  flipX: context.isRtl,
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: color.withValues(alpha: 0.9)),
                ),
              ),
              Expanded(
                  child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter:
                          _DashPainter(color: color.withValues(alpha: 0.5)))),
            ],
          ),
        ),
        Expanded(child: stop(to, CrossAxisAlignment.end)),
      ],
    );
  }
}

class _Stamps extends StatelessWidget {
  const _Stamps(
      {required this.filled,
      required this.total,
      required this.color,
      required this.empty});

  final int filled;
  final int total;
  final Color color;
  final Color empty;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            filled >= total
                ? 'Reward ready!'
                : '${total - filled} more for your reward',
            style: theme.typography.label.copyWith(
                color: theme.colors.onSurface, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < total; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: i < filled ? 1 : 0),
                duration: KitoMotion.of(
                    context, Duration(milliseconds: 300 + 60 * i)),
                curve: const KitoSpringCurve(damping: 0.6),
                builder: (context, t, _) => Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(empty, color, t.clamp(0, 1)),
                    border: Border.all(
                        color: color.withValues(alpha: 0.35), width: 1.2),
                  ),
                  child: Transform.scale(
                    scale: t.clamp(0, 1.3),
                    child: const Icon(Icons.check_rounded,
                        size: 17, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A decorative matrix code drawn from [data]: the same data always gives the same pattern, with
/// finder squares in three corners. It is **not** a scannable QR code — use your own QR or
/// barcode widget (via `KitoWalletPassView.codeBuilder`) for anything that must scan.
class KitoWalletPassCode extends StatelessWidget {
  /// Draws [data].
  const KitoWalletPassCode(
      {super.key,
      required this.data,
      this.size = 132,
      this.color = Colors.black});

  /// The payload the pattern is made from.
  final String data;

  /// Width and height.
  final double size;

  /// The modules.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _MatrixPainter(data: data, color: color)),
        ),
      ),
    );
  }
}

class _MatrixPainter extends CustomPainter {
  const _MatrixPainter({required this.data, required this.color});

  final String data;
  final Color color;

  static const _n = 25;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    final paint = Paint()..color = color;
    var h = 0x811C9DC5;
    for (final u in data.codeUnits) {
      h = ((h ^ u) * 0x01000193) & 0x7FFFFFFF;
    }
    int next() {
      h = (h * 48271) % 2147483647;
      return h;
    }

    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final isSeparator =
            (r <= 7 && (c <= 7 || c >= _n - 8)) || (r >= _n - 8 && c <= 7);
        if (isSeparator) continue;
        if (next() % 100 < 47) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(c * cell, r * cell, cell, cell).deflate(0.3),
                  Radius.circular(cell * 0.25)),
              paint);
        }
      }
    }
    void finder(int r0, int c0) {
      final outer = Rect.fromLTWH(c0 * cell, r0 * cell, cell * 7, cell * 7);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              outer.deflate(cell / 2), Radius.circular(cell * 1.4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell
            ..color = color);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              outer.deflate(cell * 2), Radius.circular(cell * 0.8)),
          paint);
    }

    finder(0, 0);
    finder(0, _n - 7);
    finder(_n - 7, 0);
  }

  @override
  bool shouldRepaint(_MatrixPainter old) =>
      old.data != data || old.color != color;
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, y), Offset((x + 6).clamp(0, size.width), y), paint);
      x += 10;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _TicketShadowPainter extends CustomPainter {
  const _TicketShadowPainter({required this.clipper});

  final _TicketClipper clipper;

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    canvas.drawPath(
      path.shift(const Offset(0, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(_TicketShadowPainter old) =>
      clipper.shouldReclip(old.clipper);
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper(
      {required this.radius, required this.notch, required this.fromBottom});

  final double radius;
  final double notch;

  /// The tear line's distance from the bottom.
  final double fromBottom;

  @override
  Path getClip(Size size) {
    final shape = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    if (notch <= 0) return shape;
    final y = size.height - fromBottom;
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(size.width, y), radius: notch));
    return Path.combine(PathOperation.difference, shape, holes);
  }

  @override
  bool shouldReclip(_TicketClipper old) =>
      old.radius != radius ||
      old.notch != notch ||
      old.fromBottom != fromBottom;
}
