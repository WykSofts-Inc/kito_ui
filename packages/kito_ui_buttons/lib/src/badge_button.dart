// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import 'button_motion.dart';
import 'button_strings.dart';
import 'button_theme.dart';
import 'flight.dart';

/// An icon with a count badge that pops every time the count changes or a flight lands on it —
/// the cart button in a toolbar.
///
/// ```dart
/// KitoBadgeButton(
///   icon: Icons.shopping_bag_outlined,
///   activeIcon: Icons.shopping_bag,
///   count: cart.count,
///   semanticLabel: 'Shopping cart',
///   flightAnchor: 'cart',          // flights land here and bounce the badge
///   onPressed: openCart,
/// )
/// ```
class KitoBadgeButton extends StatelessWidget {
  /// Creates a badge button.
  const KitoBadgeButton({
    super.key,
    required this.icon,
    required this.count,
    required this.semanticLabel,
    required this.onPressed,
    this.activeIcon,
    this.badgeColor,
    this.badgeTextColor = Colors.white,
    this.iconColor,
    this.iconSize = 24,
    this.maxCount = 99,
    this.flightAnchor,
    this.bounceTrigger,
    this.haptics = true,
  });

  /// The icon while the count is zero.
  final IconData icon;

  /// The icon while the count is above zero; [icon] when null.
  final IconData? activeIcon;

  /// The number on the badge; the badge hides at zero.
  final int count;

  /// What screen readers call this button ("Shopping cart"); the count is added for you.
  final String semanticLabel;

  /// Called on tap.
  final VoidCallback? onPressed;

  /// Badge fill; the theme's danger colour when null.
  final Color? badgeColor;

  /// Badge text colour.
  final Color badgeTextColor;

  /// Icon colour; the button theme's tint when null.
  final Color? iconColor;

  /// Icon size.
  final double iconSize;

  /// Counts above this show as "99+".
  final int maxCount;

  /// Registers the button as a [KitoFlightAnchor] with this id and bounces when flights land.
  final Object? flightAnchor;

  /// Also bounce whenever this changes.
  final Object? bounceTrigger;

  /// A light tap haptic.
  final bool haptics;

  /// The badge text for [count] using [format] for digits: "7", or "99+" above [maxCount].
  static String badgeText(int count,
      {int maxCount = 99, String Function(int)? format}) {
    final f = format ?? (int n) => '$n';
    return count > maxCount ? '${f(maxCount)}+' : f(count);
  }

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final theme = KitoButtonTheme.of(context);
    final motion = theme.motionFor(context);
    final palette = theme.resolve(kito);
    final material =
        Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
    final format = material?.formatDecimal;
    final text = badgeText(count, maxCount: maxCount, format: format);
    final label = count > 0
        ? KitoButtonStrings.badgeItems(context, semanticLabel, text)
        : semanticLabel;
    final flights =
        flightAnchor == null ? null : KitoFlightLayer.maybeOf(context);

    Widget glyph(Object? landing) => KitoButtonBounce(
          trigger: Object.hash(count, landing, bounceTrigger),
          duration: motion.bounceDuration,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, end: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: motion.morphDuration,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    count > 0 ? (activeIcon ?? icon) : icon,
                    key: ValueKey(count > 0),
                    size: iconSize,
                    color: iconColor ?? palette.tint,
                  ),
                ),
                PositionedDirectional(
                  top: -6,
                  end: -10,
                  child: AnimatedScale(
                    scale: count > 0 ? 1 : 0,
                    duration: motion.morphDuration,
                    curve: count > 0 ? motion.morphCurve : Curves.easeIn,
                    child: AnimatedSwitcher(
                      duration: motion.pressDuration,
                      child: Container(
                        key: ValueKey(text),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeColor ?? kito.colors.danger,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: kito.colors.background, width: 1.5),
                        ),
                        child: Text(
                          text,
                          style: kito.typography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeTextColor,
                              height: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    Widget body = flights == null
        ? glyph(null)
        : ListenableBuilder(
            listenable: flights,
            builder: (context, _) => glyph(flights.landings(flightAnchor!)),
          );
    if (flightAnchor != null) {
      body = KitoFlightAnchor(id: flightAnchor!, child: body);
    }

    final VoidCallback? tap = onPressed == null
        ? null
        : () {
            if (haptics) HapticFeedback.selectionClick();
            onPressed!();
          };
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: tap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(widthFactor: 1, heightFactor: 1, child: body),
          ),
        ),
      ),
    );
  }
}
