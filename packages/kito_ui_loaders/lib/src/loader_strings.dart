// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/widgets.dart';

/// The screen-reader strings the loaders produce, in English, Swahili and French. Set
/// [provider] to override them or add languages.
abstract final class KitoLoaderStrings {
  /// Consulted first; return null to fall back to the bundled strings.
  static String? Function(String key, Locale locale)? provider;

  /// Keys: `loading`, `typing`, `progress`, `inProgress`, `refreshing`, `pullToRefresh`,
  /// `complete`, `percent` (with `{value}`), `step` (with `{current}` and `{total}`).
  static const Map<String, Map<String, String>> bundled = {
    'en': {
      'loading': 'Loading',
      'typing': 'Typing',
      'progress': 'Progress',
      'inProgress': 'In progress',
      'refreshing': 'Refreshing',
      'pullToRefresh': 'Pull to refresh',
      'complete': 'Complete',
      'percent': '{value} percent',
      'step': 'Step {current} of {total}',
    },
    'sw': {
      'loading': 'Inapakia',
      'typing': 'Anaandika',
      'progress': 'Maendeleo',
      'inProgress': 'Inaendelea',
      'refreshing': 'Inaonyesha upya',
      'pullToRefresh': 'Vuta ili kuonyesha upya',
      'complete': 'Imekamilika',
      'percent': 'asilimia {value}',
      'step': 'Hatua {current} kati ya {total}',
    },
    'fr': {
      'loading': 'Chargement',
      'typing': 'En train d’écrire',
      'progress': 'Progression',
      'inProgress': 'En cours',
      'refreshing': 'Actualisation',
      'pullToRefresh': 'Tirer pour actualiser',
      'complete': 'Terminé',
      'percent': '{value} pour cent',
      'step': 'Étape {current} sur {total}',
    },
  };

  /// The string for [key] in [locale], falling back to English.
  static String lookup(String key, Locale locale) {
    final custom = provider?.call(key, locale);
    if (custom != null) return custom;
    return bundled[locale.languageCode]?[key] ?? bundled['en']![key] ?? key;
  }

  /// The string for [key] in the locale around [context], with `{placeholders}` filled.
  static String of(BuildContext context, String key,
      [Map<String, Object> args = const {}]) {
    var s =
        lookup(key, Localizations.maybeLocaleOf(context) ?? const Locale('en'));
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// "42 percent" for a 0–1 [fraction], rounded down.
  static String percent(BuildContext context, double fraction) =>
      of(context, 'percent', {'value': (fraction.clamp(0, 1) * 100).floor()});
}
