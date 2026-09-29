// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:intl/intl.dart';

/// The words KitoFormatting produces itself — relative dates, day labels, greetings, spelled-out
/// durations and trend names — in English, Swahili and French. Set [provider] to override them
/// or add languages.
abstract final class KitoFormattingStrings {
  /// Consulted first with a key and a language code; return null to fall back.
  static String? Function(String key, String language)? provider;

  /// Keys use `{n}` for counts. Units have `.one` and `.other` forms.
  static const Map<String, Map<String, String>> bundled = {
    'en': {
      'now': 'now',
      'justNow': 'just now',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'tomorrow': 'Tomorrow',
      'ago': '{v} ago',
      'in': 'in {v}',
      'second.one': '{n} second',
      'second.other': '{n} seconds',
      'minute.one': '{n} minute',
      'minute.other': '{n} minutes',
      'hour.one': '{n} hour',
      'hour.other': '{n} hours',
      'day.one': '{n} day',
      'day.other': '{n} days',
      'week.one': '{n} week',
      'week.other': '{n} weeks',
      'month.one': '{n} month',
      'month.other': '{n} months',
      'year.one': '{n} year',
      'year.other': '{n} years',
      'list': ', ',
      'morning': 'Good morning',
      'afternoon': 'Good afternoon',
      'evening': 'Good evening',
      'up': 'Up',
      'down': 'Down',
      'flat': 'Unchanged',
      'of': 'of',
    },
    'sw': {
      'now': 'sasa',
      'justNow': 'sasa hivi',
      'today': 'Leo',
      'yesterday': 'Jana',
      'tomorrow': 'Kesho',
      'ago': '{v} zilizopita',
      'in': 'baada ya {v}',
      'second.one': 'sekunde {n}',
      'second.other': 'sekunde {n}',
      'minute.one': 'dakika {n}',
      'minute.other': 'dakika {n}',
      'hour.one': 'saa {n}',
      'hour.other': 'saa {n}',
      'day.one': 'siku {n}',
      'day.other': 'siku {n}',
      'week.one': 'wiki {n}',
      'week.other': 'wiki {n}',
      'month.one': 'mwezi {n}',
      'month.other': 'miezi {n}',
      'year.one': 'mwaka {n}',
      'year.other': 'miaka {n}',
      'list': ', ',
      'morning': 'Habari za asubuhi',
      'afternoon': 'Habari za mchana',
      'evening': 'Habari za jioni',
      'up': 'Juu',
      'down': 'Chini',
      'flat': 'Hakuna mabadiliko',
      'of': 'kati ya',
    },
    'fr': {
      'now': 'maintenant',
      'justNow': 'à l’instant',
      'today': 'Aujourd’hui',
      'yesterday': 'Hier',
      'tomorrow': 'Demain',
      'ago': 'il y a {v}',
      'in': 'dans {v}',
      'second.one': '{n} seconde',
      'second.other': '{n} secondes',
      'minute.one': '{n} minute',
      'minute.other': '{n} minutes',
      'hour.one': '{n} heure',
      'hour.other': '{n} heures',
      'day.one': '{n} jour',
      'day.other': '{n} jours',
      'week.one': '{n} semaine',
      'week.other': '{n} semaines',
      'month.one': '{n} mois',
      'month.other': '{n} mois',
      'year.one': '{n} an',
      'year.other': '{n} ans',
      'list': ', ',
      'morning': 'Bonjour',
      'afternoon': 'Bon après-midi',
      'evening': 'Bonsoir',
      'up': 'En hausse',
      'down': 'En baisse',
      'flat': 'Inchangé',
      'of': 'sur',
    },
  };

  /// The language code for [locale] (or the current Intl locale).
  static String language(String? locale) => Intl.shortLocale(
      Intl.canonicalizedLocale(locale ?? Intl.getCurrentLocale()));

  /// The string for [key] in [locale], falling back to English.
  static String lookup(String key, {String? locale}) {
    final lang = language(locale);
    return provider?.call(key, lang) ??
        bundled[lang]?[key] ??
        bundled['en']![key] ??
        key;
  }

  /// "3 minutes" / "dakika 3" for a [unit] (`second`, `minute`, `hour`, `day`, `week`,
  /// `month`, `year`) and a count.
  static String unit(String unit, int n, {String? locale}) =>
      lookup('$unit.${n.abs() == 1 ? 'one' : 'other'}', locale: locale)
          .replaceAll('{n}', '$n');
}
