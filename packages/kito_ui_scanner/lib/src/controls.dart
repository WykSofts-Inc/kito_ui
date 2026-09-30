// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

/// The scanner's frosted control pill: torch, camera switch and optional close and
/// photo-library buttons. Buttons without a callback are left out. Pure UI, so it works over
/// a placeholder too; `KitoScannerView` wires it to the camera.
class KitoScannerControlBar extends StatelessWidget {
  /// Creates the bar.
  const KitoScannerControlBar({
    super.key,
    this.torchOn = false,
    this.onTorch,
    this.onSwitchCamera,
    this.onPickImage,
    this.onClose,
    this.tint,
  });

  /// Lights the torch button.
  final bool torchOn;

  /// Toggles the torch; hidden when null (e.g. no torch on this camera).
  final VoidCallback? onTorch;

  /// Flips between front and back cameras.
  final VoidCallback? onSwitchCamera;

  /// Scans a photo from the library.
  final VoidCallback? onPickImage;

  /// Closes the scanner.
  final VoidCallback? onClose;

  /// The lit torch colour; amber when null.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (onClose != null)
        _RoundButton(
          icon: Icons.close_rounded,
          label: 'Close',
          onTap: onClose!,
        ),
      if (onPickImage != null)
        _RoundButton(
          icon: Icons.photo_library_rounded,
          label: 'Scan a photo',
          onTap: onPickImage!,
        ),
      if (onTorch != null)
        _RoundButton(
          icon:
              torchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
          label: torchOn ? 'Turn torch off' : 'Turn torch on',
          active: torchOn,
          activeColor: tint ?? const Color(0xFFFFC53D),
          onTap: onTorch!,
        ),
      if (onSwitchCamera != null)
        _RoundButton(
          icon: Icons.cameraswitch_rounded,
          label: 'Switch camera',
          onTap: onSwitchCamera!,
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, b) in buttons.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                b,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        toggled: active ? true : null,
        label: label,
        excludeSemantics: true,
        child: KitoPressable(
          scale: 0.9,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: AnimatedContainer(
              duration: KitoMotion.of(context, theme.motion.medium),
              curve: theme.motion.standard,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    active ? activeColor : Colors.white.withValues(alpha: 0.16),
                boxShadow:
                    active
                        ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.5),
                            blurRadius: 18,
                          ),
                        ]
                        : const [],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: KitoMotion.of(context, theme.motion.fast),
                transitionBuilder:
                    (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  color: active ? Colors.black : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
