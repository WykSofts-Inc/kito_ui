// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'code.dart';
import 'controls.dart';
import 'overlay.dart';

/// The Kito format for a mobile_scanner format.
KitoScanFormat kitoScanFormatOf(BarcodeFormat format) => switch (format) {
  BarcodeFormat.qrCode || BarcodeFormat.microQrCode => KitoScanFormat.qr,
  BarcodeFormat.aztec => KitoScanFormat.aztec,
  BarcodeFormat.pdf417 => KitoScanFormat.pdf417,
  BarcodeFormat.dataMatrix => KitoScanFormat.dataMatrix,
  BarcodeFormat.ean13 => KitoScanFormat.ean13,
  BarcodeFormat.ean8 => KitoScanFormat.ean8,
  BarcodeFormat.upcA => KitoScanFormat.upcA,
  BarcodeFormat.upcE => KitoScanFormat.upcE,
  BarcodeFormat.code128 => KitoScanFormat.code128,
  BarcodeFormat.code39 => KitoScanFormat.code39,
  BarcodeFormat.code93 => KitoScanFormat.code93,
  BarcodeFormat.itf14 ||
  BarcodeFormat.itf2of5 ||
  BarcodeFormat.itf2of5WithChecksum => KitoScanFormat.itf,
  BarcodeFormat.codabar => KitoScanFormat.codabar,
  _ => KitoScanFormat.unknown,
};

/// A live camera scanner: the mobile_scanner preview under a [KitoScanOverlay], a torch and
/// camera-switch pill, and a friendly screen when the camera isn't allowed. Each code is
/// reported once (the same code is ignored for [repeatDelay]) and the viewfinder locks green
/// for a moment.
///
/// This widget opens the camera, so never build it in widget tests — test your screen with
/// [KitoScanOverlay] over a placeholder instead.
///
/// ```dart
/// KitoScannerView(
///   hint: 'Scan the QR code on the till',
///   onDetect: (code) => KitoScanResultSheet.show(context, code),
///   onClose: () => Navigator.pop(context),
/// )
/// ```
class KitoScannerView extends StatefulWidget {
  /// Creates a scanner.
  const KitoScannerView({
    super.key,
    required this.onDetect,
    this.controller,
    this.formats = const [],
    this.style = KitoScanOverlayStyle.corners,
    this.aspectRatio = 1,
    this.hint = 'Point the camera at a code',
    this.pausesOnDetect = false,
    this.repeatDelay = const Duration(seconds: 2),
    this.restrictToWindow = true,
    this.onClose,
    this.onPickImage,
    this.tint,
  });

  /// Called once per new code.
  final ValueChanged<KitoScannedCode> onDetect;

  /// Your own mobile_scanner controller; the view makes and disposes one when null.
  final MobileScannerController? controller;

  /// Formats to look for; empty looks for all. Fewer is faster.
  final List<BarcodeFormat> formats;

  /// The viewfinder style.
  final KitoScanOverlayStyle style;

  /// The window's width over height: 1 for QR, ~1.8 for barcodes.
  final double aspectRatio;

  /// The line under the window.
  final String? hint;

  /// Stops the camera after a code; call `controller.start()` to scan again.
  final bool pausesOnDetect;

  /// How long the same code is ignored after it's reported.
  final Duration repeatDelay;

  /// Only reads codes inside the window.
  final bool restrictToWindow;

  /// Shows a close button.
  final VoidCallback? onClose;

  /// Shows a photo-library button.
  final VoidCallback? onPickImage;

  /// The laser and accent colour.
  final Color? tint;

  @override
  State<KitoScannerView> createState() => _KitoScannerViewState();
}

class _KitoScannerViewState extends State<KitoScannerView> {
  MobileScannerController? _own;
  MobileScannerController get _controller =>
      widget.controller ??
      (_own ??= MobileScannerController(formats: widget.formats));

  String? _last;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _locked = false;
  Timer? _unlock;

  @override
  void dispose() {
    _unlock?.cancel();
    _own?.dispose();
    super.dispose();
  }

  void _handle(BarcodeCapture capture) {
    final barcode =
        capture.barcodes
            .where((b) => (b.rawValue ?? '').isNotEmpty)
            .firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue!;
    final now = DateTime.now();
    if (raw == _last && now.difference(_lastAt) < widget.repeatDelay) return;
    _last = raw;
    _lastAt = now;
    HapticFeedback.mediumImpact();
    setState(() => _locked = true);
    _unlock?.cancel();
    _unlock = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _locked = false);
    });
    if (widget.pausesOnDetect) unawaited(_controller.stop());
    widget.onDetect(
      KitoScannedCode(
        raw,
        format: kitoScanFormatOf(barcode.format),
        scannedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        final window = KitoScanWindow.rect(
          size,
          aspectRatio: widget.aspectRatio,
        );
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              KitoScanOverlay(
                style: widget.style,
                aspectRatio: widget.aspectRatio,
                locked: _locked,
                hint: widget.hint,
                tint: widget.tint,
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _handle,
                  scanWindow: widget.restrictToWindow ? window : null,
                  errorBuilder:
                      (context, error) =>
                          _ScannerError(error: error, onClose: widget.onClose),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: theme.spacing.xl,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        final torch = state.torchState;
                        return KitoScannerControlBar(
                          torchOn: torch == TorchState.on,
                          onTorch:
                              torch == TorchState.unavailable
                                  ? null
                                  : () => unawaited(_controller.toggleTorch()),
                          onSwitchCamera:
                              (state.availableCameras ?? 2) > 1
                                  ? () => unawaited(_controller.switchCamera())
                                  : null,
                          onPickImage: widget.onPickImage,
                          onClose: widget.onClose,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, this.onClose});

  final MobileScannerException error;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final unsupported = error.errorCode == MobileScannerErrorCode.unsupported;
    return ColoredBox(
      color: const Color(0xFF0B0B0F),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  denied
                      ? Icons.no_photography_rounded
                      : Icons.videocam_off_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: theme.spacing.lg),
              Text(
                denied
                    ? 'Camera access is off'
                    : unsupported
                    ? 'Scanning isn’t supported here'
                    : 'The camera couldn’t start',
                textAlign: TextAlign.center,
                style: theme.typography.title.copyWith(color: Colors.white),
              ),
              SizedBox(height: theme.spacing.sm),
              Text(
                denied
                    ? 'Allow camera access in Settings to scan codes.'
                    : 'Try again, or close and come back.',
                textAlign: TextAlign.center,
                style: theme.typography.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              if (onClose != null) ...[
                SizedBox(height: theme.spacing.lg),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(140, 48),
                  ),
                  onPressed: onClose,
                  child: const Text('Close'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
