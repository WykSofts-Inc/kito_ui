// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';

import '../kits/core_gallery.dart';

/// One sample: a live preview, the code behind it, and a line saying what it shows.
class KitSample {
  const KitSample({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final String code;
  final WidgetBuilder builder;
}

/// A titled group of samples inside a kit's gallery.
class KitSection {
  const KitSection(this.title, this.icon, this.samples);

  final String title;
  final IconData icon;
  final List<KitSample> samples;
}

/// Where a kit sits on the home screen.
enum KitCategory {
  foundations('Foundations', Icons.layers_rounded, Color(0xFF00BFA5)),
  components('Components', Icons.widgets_rounded, Color(0xFF00B8D4)),
  feedback('Feedback', Icons.notifications_active_rounded, Color(0xFFFF9100)),
  navigation('Navigation', Icons.view_sidebar_rounded, Color(0xFF7C4DFF)),
  forms('Forms', Icons.edit_note_rounded, Color(0xFFFF4081)),
  data('Data & Charts', Icons.insights_rounded, Color(0xFF00C853)),
  communication('Communication', Icons.forum_rounded, Color(0xFF2979FF)),
  commerce('Commerce', Icons.shopping_bag_rounded, Color(0xFFFF5252)),
  device('Device', Icons.phone_iphone_rounded, Color(0xFF1DE9B6)),
  media('Media', Icons.perm_media_rounded, Color(0xFFFFC400));

  const KitCategory(this.title, this.icon, this.color);

  final String title;
  final IconData icon;
  final Color color;
}

/// A kit on the home screen and the gallery behind it.
class KitEntry {
  const KitEntry({
    required this.title,
    required this.package,
    required this.blurb,
    required this.icon,
    required this.category,
    required this.sections,
    this.isNew = false,
  });

  final String title;
  final String package;
  final String blurb;
  final IconData icon;
  final KitCategory category;
  final List<KitSection> sections;
  final bool isNew;

  int get sampleCount => sections.fold(0, (sum, s) => sum + s.samples.length);
}

/// A kit that's on its way, shown dimmed in "Coming soon".
class UpcomingKit {
  const UpcomingKit(this.title, this.icon, this.category);

  final String title;
  final IconData icon;
  final KitCategory category;
}

/// A search hit: a sample and the kit it belongs to.
class SampleHit {
  const SampleHit(this.kit, this.section, this.sample);

  final KitEntry kit;
  final KitSection section;
  final KitSample sample;
}

/// Every kit in the app. Add a kit's [KitEntry] here when its package lands.
abstract final class KitCatalog {
  static final List<KitEntry> kits = [coreKit];

  static const List<UpcomingKit> upcoming = [
    UpcomingKit('Buttons', Icons.touch_app_rounded, KitCategory.components),
    UpcomingKit('Fields', Icons.text_fields_rounded, KitCategory.forms),
    UpcomingKit('Validation', Icons.verified_rounded, KitCategory.forms),
    UpcomingKit('Toasts', Icons.chat_bubble_rounded, KitCategory.feedback),
    UpcomingKit('Loaders', Icons.autorenew_rounded, KitCategory.feedback),
    UpcomingKit('Modals', Icons.web_asset_rounded, KitCategory.feedback),
    UpcomingKit('Empty States', Icons.inbox_rounded, KitCategory.feedback),
    UpcomingKit('Haptics', Icons.vibration_rounded, KitCategory.feedback),
    UpcomingKit(
        'Navigation', Icons.view_sidebar_rounded, KitCategory.navigation),
    UpcomingKit(
        'Onboarding', Icons.auto_awesome_rounded, KitCategory.navigation),
    UpcomingKit('Formatting', Icons.pin_rounded, KitCategory.data),
    UpcomingKit('Charts', Icons.show_chart_rounded, KitCategory.data),
    UpcomingKit('Calendar', Icons.calendar_month_rounded, KitCategory.data),
    UpcomingKit(
        'Carousels', Icons.view_carousel_rounded, KitCategory.components),
    UpcomingKit('Chat', Icons.forum_rounded, KitCategory.communication),
    UpcomingKit('AI Chat', Icons.auto_awesome_motion_rounded,
        KitCategory.communication),
    UpcomingKit(
        'Wallet Cards', Icons.credit_card_rounded, KitCategory.commerce),
    UpcomingKit(
        'Checkout', Icons.shopping_cart_checkout_rounded, KitCategory.commerce),
    UpcomingKit('Maps', Icons.map_rounded, KitCategory.device),
    UpcomingKit('Scanner', Icons.qr_code_scanner_rounded, KitCategory.device),
  ];

  static int get sampleCount => kits.fold(0, (sum, k) => sum + k.sampleCount);

  static KitEntry? byTitle(String title) {
    for (final kit in kits) {
      if (kit.title == title) return kit;
    }
    return null;
  }

  /// Kits whose title, package or blurb match [query].
  static List<KitEntry> searchKits(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return kits
        .where(
          (k) =>
              k.title.toLowerCase().contains(q) ||
              k.package.contains(q) ||
              k.blurb.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Samples whose title, subtitle or section match [query], best first, at most [limit].
  static List<SampleHit> searchSamples(String query, {int limit = 60}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = <(int, SampleHit)>[];
    for (final kit in kits) {
      for (final section in kit.sections) {
        for (final sample in section.samples) {
          final title = sample.title.toLowerCase();
          final score = title.startsWith(q)
              ? 0
              : title.contains(q)
                  ? 1
                  : sample.subtitle.toLowerCase().contains(q) ||
                          section.title.toLowerCase().contains(q)
                      ? 2
                      : -1;
          if (score >= 0) hits.add((score, SampleHit(kit, section, sample)));
        }
      }
    }
    hits.sort((a, b) => a.$1.compareTo(b.$1));
    return hits.take(limit).map((h) => h.$2).toList();
  }
}
