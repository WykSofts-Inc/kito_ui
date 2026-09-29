// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// One destination in a Kito tab bar or side rail.
@immutable
class KitoTabItem {
  /// Creates a tab.
  const KitoTabItem({
    required this.id,
    required this.title,
    required this.icon,
    this.selectedIcon,
    this.badgeCount = 0,
  });

  /// Unique among the tabs.
  final String id;

  /// The label, also read by screen readers.
  final String title;

  /// The icon.
  final IconData icon;

  /// The icon while selected; [icon] when null.
  final IconData? selectedIcon;

  /// A count on a red badge; hidden at 0.
  final int badgeCount;

  /// A copy with some fields replaced.
  KitoTabItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    IconData? selectedIcon,
    int? badgeCount,
  }) =>
      KitoTabItem(
        id: id ?? this.id,
        title: title ?? this.title,
        icon: icon ?? this.icon,
        selectedIcon: selectedIcon ?? this.selectedIcon,
        badgeCount: badgeCount ?? this.badgeCount,
      );

  /// The badge text: the count, or "99+".
  static String badgeText(int count) => count > 99 ? '99+' : '$count';

  @override
  bool operator ==(Object other) =>
      other is KitoTabItem &&
      other.id == id &&
      other.title == title &&
      other.icon == icon &&
      other.selectedIcon == selectedIcon &&
      other.badgeCount == badgeCount;

  @override
  int get hashCode => Object.hash(id, title, icon, selectedIcon, badgeCount);
}

/// Owns which tab is selected, and tells a re-tap on the selected tab ("scroll to top", "back
/// to this tab's root") apart from a switch.
///
/// [items] can change — badges, titles, the set of tabs — without rebuilding the controller;
/// the selection is kept while its tab is still there and falls back to the first tab
/// otherwise.
class KitoTabBarController extends ChangeNotifier {
  /// Creates a controller. [items] must not be empty.
  KitoTabBarController({
    required List<KitoTabItem> items,
    String? selectedId,
    this.onReselect,
  })  : assert(items.isNotEmpty, 'KitoTabBarController needs at least one tab'),
        _items = List.unmodifiable(items),
        _selectedId = selectedId != null && items.any((i) => i.id == selectedId)
            ? selectedId
            : items.first.id;

  List<KitoTabItem> _items;
  String _selectedId;

  /// Called with the id of the selected tab when it's tapped again.
  ValueChanged<String>? onReselect;

  /// The tabs, in order.
  List<KitoTabItem> get items => _items;

  set items(List<KitoTabItem> value) {
    assert(value.isNotEmpty, 'KitoTabBarController needs at least one tab');
    if (value.isEmpty || listEquals(value, _items)) return;
    _items = List.unmodifiable(value);
    if (!_items.any((i) => i.id == _selectedId)) _selectedId = _items.first.id;
    notifyListeners();
  }

  /// The selected tab's id.
  String get selectedId => _selectedId;

  /// The selected tab's position in [items].
  int get selectedIndex {
    final index = _items.indexWhere((i) => i.id == _selectedId);
    return index < 0 ? 0 : index;
  }

  /// Selects [id], or reports a re-tap through [onReselect] when it's already selected.
  /// Unknown ids are ignored.
  void select(String id) {
    if (id == _selectedId) {
      onReselect?.call(id);
      return;
    }
    if (!_items.any((i) => i.id == id)) return;
    _selectedId = id;
    notifyListeners();
  }

  /// The badge count of [id], 0 for unknown ids.
  int badgeCount(String id) {
    for (final item in _items) {
      if (item.id == id) return item.badgeCount;
    }
    return 0;
  }

  /// Updates one tab's badge (a bag count, unread messages). Negative counts are treated as
  /// zero; unknown ids are ignored; the selection is unchanged.
  void setBadge(int count, String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final value = count < 0 ? 0 : count;
    if (_items[index].badgeCount == value) return;
    items = [
      for (var i = 0; i < _items.length; i++)
        i == index ? _items[i].copyWith(badgeCount: value) : _items[i],
    ];
  }
}
