// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kenyan mobile numbers: 07XX and 01XX, with or without +254.
abstract final class KitoCheckoutPhone {
  /// "+254712345678", or null when it isn't a Kenyan mobile number.
  static String? normalize(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('254')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length != 9 || !(digits[0] == '7' || digits[0] == '1')) {
      return null;
    }
    return '+254$digits';
  }

  /// "+254 712 345 678".
  static String? display(String input) {
    final e164 = normalize(input);
    if (e164 == null) return null;
    final n = e164.substring(4);
    return '+254 ${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
  }

  /// "0712 ••• 678", for showing which phone an M-Pesa prompt goes to.
  static String? masked(String input) {
    final e164 = normalize(input);
    if (e164 == null) return null;
    final n = e164.substring(4);
    return '0${n.substring(0, 3)} ••• ${n.substring(6)}';
  }
}

/// What an address is called in the list.
enum KitoCheckoutAddressLabel {
  /// Home.
  home('Home', Icons.home_rounded),

  /// Work.
  work('Work', Icons.work_rounded),

  /// Anything else.
  other('Other', Icons.place_rounded);

  const KitoCheckoutAddressLabel(this.title, this.icon);

  /// "Home".
  final String title;

  /// A matching icon.
  final IconData icon;
}

/// A field of the address, for pointing errors at the right place.
enum KitoCheckoutAddressField {
  /// Who receives it.
  recipient,

  /// Their phone.
  phone,

  /// Street, road or building.
  street,

  /// The town.
  town,
}

/// A delivery address in the shape Kenyan addresses are actually given: a building and street,
/// an estate or area, a town and a landmark the rider can look for.
@immutable
class KitoCheckoutAddress {
  /// Creates an address.
  const KitoCheckoutAddress({
    required this.id,
    this.label = KitoCheckoutAddressLabel.home,
    this.customLabel,
    this.recipient = '',
    this.phone = '',
    this.street = '',
    this.building = '',
    this.area = '',
    this.town = '',
    this.landmark = '',
    this.instructions = '',
  });

  /// A stable id.
  final String id;

  /// Home, Work or Other.
  final KitoCheckoutAddressLabel label;

  /// Replaces the label's title: "Mum's place".
  final String? customLabel;

  /// Who receives it.
  final String recipient;

  /// Their phone, any Kenyan format.
  final String phone;

  /// "Argwings Kodhek Road".
  final String street;

  /// "Mvuli Court, Block B, 4th floor".
  final String building;

  /// The estate or neighbourhood: "Kilimani".
  final String area;

  /// "Nairobi".
  final String town;

  /// "Opposite Yaya Centre".
  final String landmark;

  /// A note for the rider: "Call when at the gate".
  final String instructions;

  /// [customLabel] or the label's title.
  String get title {
    final c = customLabel?.trim() ?? '';
    return c.isEmpty ? label.title : c;
  }

  /// "Mvuli Court, Argwings Kodhek Road, Kilimani, Nairobi" — repeats dropped.
  String get singleLine => _join([building, street, area, town]);

  /// "Kilimani, Nairobi".
  String get short {
    final s = _join([area, town]);
    return s.isEmpty ? _join([street]) : s;
  }

  /// Building and street, then area and town, then "Near …" — one per line.
  String get multiLine => [
        _join([building, street]),
        _join([area, town]),
        if (landmark.trim().isNotEmpty) 'Near ${landmark.trim()}',
      ].where((l) => l.isNotEmpty).join('\n');

  /// Everything that stops this address being used, keyed by field. Empty when it's valid.
  Map<KitoCheckoutAddressField, String> validationErrors() {
    final errors = <KitoCheckoutAddressField, String>{};
    if (recipient.trim().length < 2) {
      errors[KitoCheckoutAddressField.recipient] =
          'Enter the name of the person receiving it.';
    }
    if (phone.trim().isEmpty) {
      errors[KitoCheckoutAddressField.phone] =
          'Enter a phone number so the rider can call.';
    } else if (KitoCheckoutPhone.normalize(phone) == null) {
      errors[KitoCheckoutAddressField.phone] =
          'Enter a Kenyan number, e.g. 0712 345 678.';
    }
    if (street.trim().isEmpty && building.trim().isEmpty) {
      errors[KitoCheckoutAddressField.street] =
          'Enter a street, road or building.';
    }
    if (town.trim().isEmpty) {
      errors[KitoCheckoutAddressField.town] = 'Choose a town.';
    }
    return errors;
  }

  /// True when [validationErrors] is empty.
  bool get isValid => validationErrors().isEmpty;

  static String _join(List<String> parts) {
    final seen = <String>{};
    final kept = <String>[];
    for (final p in parts.map((p) => p.trim())) {
      if (p.isNotEmpty && seen.add(p.toLowerCase())) kept.add(p);
    }
    return kept.join(', ');
  }

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutAddress &&
      other.id == id &&
      other.singleLine == singleLine;

  @override
  int get hashCode => Object.hash(id, singleLine);
}

/// When an order arrives.
@immutable
class KitoCheckoutEta {
  const KitoCheckoutEta._(this._unit, this.from, this.to, this._text);

  /// "30–45 min".
  const KitoCheckoutEta.minutes(int from, int to) : this._(0, from, to, null);

  /// "2–3 hours".
  const KitoCheckoutEta.hours(int from, int to) : this._(1, from, to, null);

  /// Days from today: 0 is today, 1 tomorrow. "Tomorrow", "2–4 days".
  const KitoCheckoutEta.days(int from, int to) : this._(2, from, to, null);

  /// Your own words: "At your chosen time".
  const KitoCheckoutEta.text(String text) : this._(3, 0, 0, text);

  final int _unit;
  final String? _text;

  /// The low end of the range.
  final int from;

  /// The high end of the range.
  final int to;

  String get _range => from == to ? '$from' : '$from–$to';

  /// "30–45 min", "2–3 hours", "Tomorrow", "2–4 days".
  String get label => switch (_unit) {
        0 => '$_range min',
        1 => '$_range ${to == 1 ? 'hour' : 'hours'}',
        2 => to == 0
            ? 'Today'
            : (from == 1 && to == 1)
                ? 'Tomorrow'
                : from == 0
                    ? 'Within $to days'
                    : '$_range days',
        _ => _text ?? '',
      };

  /// For a confirmation: "Arrives in 30–45 min", "Arrives tomorrow".
  String get arrivalText => switch (_unit) {
        0 || 1 => 'Arrives in $label',
        2 => to <= 1 ? 'Arrives ${label.toLowerCase()}' : 'Arrives in $label',
        _ => _text ?? '',
      };

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutEta &&
      other._unit == _unit &&
      other.from == from &&
      other.to == to &&
      other._text == _text;

  @override
  int get hashCode => Object.hash(_unit, from, to, _text);
}

/// The kinds of delivery.
enum KitoCheckoutDeliveryKind {
  /// The usual courier.
  standard(Icons.local_shipping_rounded),

  /// A rider, fast.
  express(Icons.bolt_rounded),

  /// Collect from a shop or locker.
  pickup(Icons.storefront_rounded),

  /// A booked day and window.
  scheduled(Icons.event_available_rounded);

  const KitoCheckoutDeliveryKind(this.icon);

  /// A matching icon.
  final IconData icon;
}

/// A way to get the order.
@immutable
class KitoCheckoutDeliveryOption {
  /// Creates an option; [price] is in cents.
  const KitoCheckoutDeliveryOption({
    required this.id,
    required this.kind,
    required this.title,
    required this.price,
    required this.eta,
    this.subtitle,
    this.badge,
    this.unavailableReason,
  });

  /// Standard delivery.
  const KitoCheckoutDeliveryOption.standard(
      {required int price,
      KitoCheckoutEta eta = const KitoCheckoutEta.days(1, 2),
      String title = 'Standard delivery'})
      : this(
            id: 'standard',
            kind: KitoCheckoutDeliveryKind.standard,
            title: title,
            price: price,
            eta: eta);

  /// Express by rider, tagged "Fastest".
  const KitoCheckoutDeliveryOption.express(
      {required int price,
      KitoCheckoutEta eta = const KitoCheckoutEta.minutes(30, 45),
      String title = 'Express'})
      : this(
            id: 'express',
            kind: KitoCheckoutDeliveryKind.express,
            title: title,
            price: price,
            eta: eta,
            badge: 'Fastest');

  /// Collect it yourself.
  const KitoCheckoutDeliveryOption.pickup(
      {int price = 0,
      KitoCheckoutEta eta = const KitoCheckoutEta.hours(2, 4),
      String title = 'Pick up',
      String subtitle = 'Collect from a pickup point near you'})
      : this(
            id: 'pickup',
            kind: KitoCheckoutDeliveryKind.pickup,
            title: title,
            subtitle: subtitle,
            price: price,
            eta: eta);

  /// A day and a window of the customer's choosing.
  const KitoCheckoutDeliveryOption.scheduled(
      {required int price, String title = 'Choose a time'})
      : this(
            id: 'scheduled',
            kind: KitoCheckoutDeliveryKind.scheduled,
            title: title,
            subtitle: 'Pick a day and a 2-hour window',
            price: price,
            eta: const KitoCheckoutEta.text('At your chosen time'));

  /// A stable id.
  final String id;

  /// What kind it is.
  final KitoCheckoutDeliveryKind kind;

  /// "Express".
  final String title;

  /// A second line.
  final String? subtitle;

  /// Cents.
  final int price;

  /// When it arrives.
  final KitoCheckoutEta eta;

  /// A tag: "Fastest", "Cheapest".
  final String? badge;

  /// Why it can't be chosen now ("Express is busy — try again later").
  final String? unavailableReason;

  /// True when [unavailableReason] is null.
  bool get isAvailable => unavailableReason == null;

  /// Pickup doesn't need an address.
  bool get requiresAddress => kind != KitoCheckoutDeliveryKind.pickup;

  /// Whether the customer picks a slot.
  bool get usesSlots => kind == KitoCheckoutDeliveryKind.scheduled;

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutDeliveryOption &&
      other.id == id &&
      other.price == price;

  @override
  int get hashCode => Object.hash(id, price);
}

/// A daily delivery window in minutes after midnight: `KitoCheckoutTimeWindow(8, 10)` is 8–10 AM.
@immutable
class KitoCheckoutTimeWindow {
  /// Whole hours.
  const KitoCheckoutTimeWindow(int startHour, int endHour)
      : startMinutes = startHour * 60,
        endMinutes = endHour * 60;

  /// Any minutes.
  const KitoCheckoutTimeWindow.minutes(this.startMinutes, this.endMinutes);

  /// Minutes after midnight when it opens.
  final int startMinutes;

  /// Minutes after midnight when it closes.
  final int endMinutes;

  /// "8–10 AM", "11 AM–1 PM", or "08:00–10:00" with [use24Hour].
  String label({bool use24Hour = false}) {
    if (use24Hour) return '${_clock24(startMinutes)}–${_clock24(endMinutes)}';
    final sp = _isPm(startMinutes), ep = _isPm(endMinutes);
    if (sp == ep) {
      return '${_clock12(startMinutes)}–${_clock12(endMinutes)} ${ep ? 'PM' : 'AM'}';
    }
    return '${_clock12(startMinutes)} ${sp ? 'PM' : 'AM'}–${_clock12(endMinutes)} ${ep ? 'PM' : 'AM'}';
  }

  static bool _isPm(int m) => (m ~/ 60) % 24 >= 12;

  static String _clock12(int m) {
    final h24 = (m ~/ 60) % 24;
    final min = m % 60;
    final h = h24 % 12 == 0 ? 12 : h24 % 12;
    return min == 0 ? '$h' : '$h:${min.toString().padLeft(2, '0')}';
  }

  static String _clock24(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is KitoCheckoutTimeWindow &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(startMinutes, endMinutes);
}

/// Whether a slot can be booked now.
enum KitoCheckoutSlotStatus {
  /// Plenty of room.
  available,

  /// Bookable, but only a few places left.
  fewLeft,

  /// No room.
  full,

  /// Too close to the start, or past the same-day cut-off.
  cutOff,

  /// Already over.
  past;

  /// Whether it can be picked.
  bool get isSelectable => this == available || this == fewLeft;
}

/// One bookable window on one day.
@immutable
class KitoCheckoutSlot {
  /// Creates a slot.
  const KitoCheckoutSlot({
    required this.id,
    required this.start,
    required this.end,
    required this.window,
    required this.capacity,
    this.booked = 0,
  });

  /// "2026-09-30-1400": the day and start time.
  final String id;

  /// When it opens.
  final DateTime start;

  /// When it closes.
  final DateTime end;

  /// The daily window it came from.
  final KitoCheckoutTimeWindow window;

  /// Orders it can take.
  final int capacity;

  /// Orders already booked.
  final int booked;

  /// Places left.
  int get remaining => math.max(capacity - booked, 0);

  @override
  bool operator ==(Object other) => other is KitoCheckoutSlot && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A day in the slot picker.
@immutable
class KitoCheckoutSlotDay {
  /// Creates a day.
  const KitoCheckoutSlotDay(this.date, this.slots);

  /// Midnight at the start of the day.
  final DateTime date;

  /// Its slots, in order.
  final List<KitoCheckoutSlot> slots;
}

/// Builds the days and slots from your rules and bookings, and answers whether a slot can
/// still be chosen.
///
/// ```dart
/// const schedule = KitoCheckoutSchedule(
///   windows: [KitoCheckoutTimeWindow(8, 10), KitoCheckoutTimeWindow(10, 12)],
///   closedWeekdays: {DateTime.sunday},
///   booked: {'2026-10-01-0800': 6},
/// );
/// schedule.days(from: DateTime.now());
/// ```
@immutable
class KitoCheckoutSchedule {
  /// Creates a schedule.
  const KitoCheckoutSchedule({
    this.windows = const [
      KitoCheckoutTimeWindow(8, 10),
      KitoCheckoutTimeWindow(10, 12),
      KitoCheckoutTimeWindow(12, 14),
      KitoCheckoutTimeWindow(14, 16),
      KitoCheckoutTimeWindow(16, 18),
      KitoCheckoutTimeWindow(18, 20),
    ],
    this.daysAhead = 7,
    this.leadTime = const Duration(hours: 1),
    this.sameDayCutoffMinutes,
    this.closedWeekdays = const {},
    this.capacity = 6,
    this.fewLeftThreshold = 2,
    this.booked = const {},
  });

  /// The daily windows.
  final List<KitoCheckoutTimeWindow> windows;

  /// How many days to offer, today included.
  final int daysAhead;

  /// A slot stops taking orders this long before it starts.
  final Duration leadTime;

  /// After this time of day (minutes after midnight) no more same-day slots.
  final int? sameDayCutoffMinutes;

  /// `DateTime.sunday` and friends with no deliveries.
  final Set<int> closedWeekdays;

  /// Orders each slot can take.
  final int capacity;

  /// At or below this many places a slot shows "n left".
  final int fewLeftThreshold;

  /// Orders already booked, by slot id.
  final Map<String, int> booked;

  /// "2026-09-30-1400".
  static String slotId(DateTime day, KitoCheckoutTimeWindow window) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${day.year.toString().padLeft(4, '0')}-${two(day.month)}-${two(day.day)}-'
        '${two(window.startMinutes ~/ 60)}${two(window.startMinutes % 60)}';
  }

  /// The open days from [from], skipping closed weekdays.
  List<KitoCheckoutSlotDay> days({required DateTime from}) {
    final today = DateTime(from.year, from.month, from.day);
    return [
      for (var i = 0; i < math.max(daysAhead, 1); i++)
        if (!closedWeekdays
            .contains(DateTime(today.year, today.month, today.day + i).weekday))
          KitoCheckoutSlotDay(DateTime(today.year, today.month, today.day + i),
              slotsOn(DateTime(today.year, today.month, today.day + i))),
    ];
  }

  /// The slots on [day].
  List<KitoCheckoutSlot> slotsOn(DateTime day) {
    final midnight = DateTime(day.year, day.month, day.day);
    return [
      for (final w in windows)
        KitoCheckoutSlot(
          id: slotId(midnight, w),
          start: midnight.add(Duration(minutes: w.startMinutes)),
          end: midnight.add(Duration(minutes: w.endMinutes)),
          window: w,
          capacity: capacity,
          booked: booked[slotId(midnight, w)] ?? 0,
        ),
    ];
  }

  /// Whether [slot] can be booked at [now].
  KitoCheckoutSlotStatus status(KitoCheckoutSlot slot,
      {required DateTime now}) {
    if (!now.isBefore(slot.end)) return KitoCheckoutSlotStatus.past;
    if (now.isAfter(slot.start.subtract(leadTime))) {
      return KitoCheckoutSlotStatus.cutOff;
    }
    final cutoff = sameDayCutoffMinutes;
    if (cutoff != null &&
        DateUtils.isSameDay(slot.start, now) &&
        now.hour * 60 + now.minute >= cutoff) {
      return KitoCheckoutSlotStatus.cutOff;
    }
    final left = slot.remaining;
    if (left == 0) return KitoCheckoutSlotStatus.full;
    if (left <= fewLeftThreshold) return KitoCheckoutSlotStatus.fewLeft;
    return KitoCheckoutSlotStatus.available;
  }

  /// "4 left", "Last one", "Full", "Closed".
  String statusLabel(KitoCheckoutSlot slot, {required DateTime now}) =>
      switch (status(slot, now: now)) {
        KitoCheckoutSlotStatus.available ||
        KitoCheckoutSlotStatus.fewLeft =>
          slot.remaining == 1 ? 'Last one' : '${slot.remaining} left',
        KitoCheckoutSlotStatus.full => 'Full',
        _ => 'Closed',
      };

  /// The earliest slot that can still be booked.
  KitoCheckoutSlot? firstAvailable({required DateTime now}) {
    for (final d in days(from: now)) {
      for (final s in d.slots) {
        if (status(s, now: now).isSelectable) return s;
      }
    }
    return null;
  }

  /// "Today", "Tomorrow" or "Sat".
  static String dayTitle(DateTime day, {required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = (d.difference(today).inHours / 24).round();
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ][d.weekday - 1];
  }

  /// "Today, 2–4 PM", "Sat 3, 10 AM–12 PM".
  static String label(KitoCheckoutSlot slot,
      {required DateTime now, bool use24Hour = false}) {
    final t = dayTitle(slot.start, now: now);
    final near = t == 'Today' || t == 'Tomorrow';
    return '${near ? t : '$t ${slot.start.day}'}, ${slot.window.label(use24Hour: use24Hour)}';
  }
}
