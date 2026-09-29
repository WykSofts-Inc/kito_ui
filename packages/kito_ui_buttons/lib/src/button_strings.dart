// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

/// The few strings KitoButtons produces itself — default cart titles and screen-reader values —
/// in English, Swahili and French. Set [provider] to override them or add languages.
///
/// ```dart
/// KitoButtonStrings.provider = (key, locale) => myStrings.lookup('kito.$key', locale);
/// ```
abstract final class KitoButtonStrings {
  /// Consulted first; return null to fall back to the bundled strings.
  static String? Function(String key, Locale locale)? provider;

  /// Keys: `phase.loading`, `phase.succeeded`, `phase.failed`, `phase.inProgress`,
  /// `cart.addToCart`, `cart.added`, `cart.adding`, `badge.items` (with `{name}` and `{count}`).
  static const Map<String, Map<String, String>> bundled = {
    'en': {
      'phase.loading': 'Loading',
      'phase.succeeded': 'Succeeded',
      'phase.failed': 'Failed',
      'phase.inProgress': 'In progress',
      'cart.addToCart': 'Add to cart',
      'cart.added': 'Added',
      'cart.adding': 'Adding',
      'badge.items': '{name}, {count} items',
    },
    'sw': {
      'phase.loading': 'Inapakia',
      'phase.succeeded': 'Imefaulu',
      'phase.failed': 'Imeshindikana',
      'phase.inProgress': 'Inaendelea',
      'cart.addToCart': 'Ongeza kwenye kikapu',
      'cart.added': 'Imeongezwa',
      'cart.adding': 'Inaongeza',
      'badge.items': '{name}, bidhaa {count}',
    },
    'fr': {
      'phase.loading': 'Chargement',
      'phase.succeeded': 'Réussi',
      'phase.failed': 'Échec',
      'phase.inProgress': 'En cours',
      'cart.addToCart': 'Ajouter au panier',
      'cart.added': 'Ajouté',
      'cart.adding': 'Ajout en cours',
      'badge.items': '{name}, {count} articles',
    },
  };

  /// The string for [key] in [locale], falling back to English.
  static String lookup(String key, Locale locale) {
    final custom = provider?.call(key, locale);
    if (custom != null) return custom;
    return bundled[locale.languageCode]?[key] ?? bundled['en']![key] ?? key;
  }

  /// The string for [key] in the locale around [context].
  static String of(BuildContext context, String key) =>
      lookup(key, Localizations.maybeLocaleOf(context) ?? const Locale('en'));

  /// "Cart, 3 items" in the locale around [context].
  static String badgeItems(BuildContext context, String name, String count) =>
      of(context, 'badge.items')
          .replaceAll('{name}', name)
          .replaceAll('{count}', count);
}
