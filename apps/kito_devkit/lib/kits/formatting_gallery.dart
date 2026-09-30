// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_formatting/kito_ui_formatting.dart';

import '../catalog/catalog.dart';
import '../gallery/demo_width.dart';

/// The gallery for kito_ui_formatting.
final formattingKit = KitEntry(
  title: 'Formatting',
  package: 'kito_ui_formatting',
  blurb: 'money, numbers, dates, phones and animated numbers',
  icon: Icons.pin_rounded,
  category: KitCategory.data,
  isNew: true,
  sections: [
    KitSection('Money', Icons.payments_rounded, [
      KitSample(
        title: 'Shillings, fixed',
        subtitle:
            'The same "KES 1,250.50" on every phone, whatever its region.',
        code:
            '''1250.kitoAmount(KitoCurrency.kes);                          // KES 1,250
1250.5.kitoAmount(KitoCurrency.kes);                        // KES 1,250.50
1250.5.kitoAmount(KitoCurrency.kes, display: KitoCurrencyDisplay.symbol); // KSh 1,250.50''',
        builder: (_) => _Table([
          ('1250.kitoAmount(kes)', 1250.kitoAmount(KitoCurrency.kes)),
          ('1250.5.kitoAmount(kes)', 1250.5.kitoAmount(KitoCurrency.kes)),
          (
            'display: symbol',
            1250.5.kitoAmount(KitoCurrency.kes,
                display: KitoCurrencyDisplay.symbol)
          ),
          ('1.005 rounds half up', 1.005.kitoAmount(KitoCurrency.kes)),
        ]),
      ),
      KitSample(
        title: 'When cents show',
        subtitle: 'Auto, always or never.',
        code:
            '''KitoMoneyFormatting.string(1250, KitoCurrency.kes, cents: KitoMoneyCents.always); // KES 1,250.00
KitoMoneyFormatting.string(1250.5, KitoCurrency.kes, cents: KitoMoneyCents.never); // KES 1,251''',
        builder: (_) => _Table([
          for (final c in KitoMoneyCents.values) ...[
            (
              '1250 · ${c.name}',
              KitoMoneyFormatting.string(1250, KitoCurrency.kes, cents: c)
            ),
            (
              '1250.5 · ${c.name}',
              KitoMoneyFormatting.string(1250.5, KitoCurrency.kes, cents: c)
            ),
          ],
        ]),
      ),
      KitSample(
        title: 'M-Pesa statement',
        subtitle: 'Signed amounts with a true minus, for money in and out.',
        code:
            '''Text(KitoMoneyFormatting.signed(txn.amount, KitoCurrency.kes)); // +KES 5,000 / −KES 780''',
        builder: (_) => const _Statement(),
      ),
      KitSample(
        title: 'Compact stat tiles',
        subtitle: '"KES 1.2M" for dashboards and chart labels.',
        code:
            '''Text(1240000.kitoCompactAmount(KitoCurrency.kes));   // KES 1.2M
Text(KitoMoneyFormatting.compact(48300, KitoCurrency.usd, display: KitoCurrencyDisplay.symbol)); // \$48.3K''',
        builder: (_) => const _StatTiles(),
      ),
      KitSample(
        title: 'East African currencies',
        subtitle: 'KES, UGX, TZS and friends, with flags and minor units.',
        code: '''for (final c in KitoCurrency.values)
  ListTile(
    leading: Text(c.flag),
    title: Text(c.code),
    trailing: Text(KitoMoneyFormatting.string(2500, c, display: KitoCurrencyDisplay.symbol)),
  );''',
        builder: (_) => const _Currencies(),
      ),
      KitSample(
        title: 'In the user’s locale',
        subtitle:
            'The same amount in English (Kenya), Swahili, French and German.',
        code:
            '''KitoMoneyFormatting.localized(1250.5, KitoCurrency.kes, locale: 'sw_KE');
KitoMoneyFormatting.localized(1250.5, KitoCurrency.eur, locale: 'de');''',
        builder: (_) => _Table([
          for (final l in ['en_KE', 'sw_KE', 'fr', 'de'])
            (
              l,
              KitoMoneyFormatting.localized(1250.5, KitoCurrency.kes, locale: l)
            ),
          (
            'JPY · en',
            KitoMoneyFormatting.localizedCode(1250, 'JPY', locale: 'en')
          ),
        ]),
      ),
    ]),
    KitSection('Numbers', Icons.numbers_rounded, [
      KitSample(
        title: 'Compact numbers',
        subtitle: 'Followers, views and chart axes.',
        code: '''KitoNumberFormatting.compact(47200);    // 47.2K
KitoNumberFormatting.compact(2100000);  // 2.1M
KitoNumberFormatting.compact(999950);   // 1M''',
        builder: (_) => _Table([
          for (final n in [940, 47200, 999950, 2100000, 3400000000])
            ('$n', KitoNumberFormatting.compact(n)),
        ]),
      ),
      KitSample(
        title: 'Percents and changes',
        subtitle:
            'A fraction as a percent, and signed changes that always show their sign.',
        code:
            '''KitoNumberFormatting.percent(0.847, fractionDigits: 1);  // 84.7%
KitoNumberFormatting.signedPercent(0.124);               // +12.4%
KitoNumberFormatting.signedPercent(-0.032);              // −3.2%''',
        builder: (_) => _Table([
          (
            'percent(0.847, 1)',
            KitoNumberFormatting.percent(0.847, fractionDigits: 1)
          ),
          ('signedPercent(0.124)', KitoNumberFormatting.signedPercent(0.124)),
          ('signedPercent(-0.032)', KitoNumberFormatting.signedPercent(-0.032)),
          (
            'signedPercent(0.00001)',
            KitoNumberFormatting.signedPercent(0.00001)
          ),
        ]),
      ),
      KitSample(
        title: 'Ordinals',
        subtitle: 'A savings-chama leaderboard.',
        code:
            '''Text('\${KitoNumberFormatting.ordinal(rank)} · \${member.name}');''',
        builder: (_) => const _Leaderboard(),
      ),
    ]),
    KitSection('Dates and time', Icons.schedule_rounded, [
      KitSample(
        title: 'Relative',
        subtitle:
            'Activity feeds and order updates, in English, Swahili or French.',
        code:
            '''KitoDateFormatting.relative(order.placedAt);                 // 2 minutes ago
KitoDateFormatting.relative(order.placedAt, locale: 'sw');   // dakika 2 zilizopita''',
        builder: (_) => const _Relative(),
      ),
      KitSample(
        title: 'Chat timestamps',
        subtitle: 'now, 5m, 3h, 2d, 3w, then a date.',
        code: '''Text(KitoDateFormatting.abbreviated(message.sentAt));''',
        builder: (_) => const _ChatList(),
      ),
      KitSample(
        title: 'Day headers and greetings',
        subtitle:
            'Today, Yesterday, a weekday — and a greeting for the home screen.',
        code: '''Text('\${KitoDateFormatting.greeting()}, Wycliff');
Text(KitoDateFormatting.dayLabel(section.date));''',
        builder: (_) => const _DayLabels(),
      ),
      KitSample(
        title: 'Delivery windows',
        subtitle: 'A shared AM or PM is written once.',
        code:
            '''KitoDateFormatting.timeRange(slot.start, slot.end); // 9:00 – 10:30 AM''',
        builder: (_) => const _Slots(),
      ),
    ]),
    KitSection('Units', Icons.straighten_rounded, [
      KitSample(
        title: 'Durations',
        subtitle: 'Voice notes, ETAs and spelled-out times for screen readers.',
        code:
            '''KitoDurationFormatting.clock(const Duration(seconds: 245));      // 4:05
KitoDurationFormatting.short(const Duration(seconds: 3900));      // 1h 5m
KitoDurationFormatting.spelledOut(const Duration(seconds: 3900)); // 1 hour, 5 minutes''',
        builder: (_) => _Table([
          (
            'clock(245 s)',
            KitoDurationFormatting.clock(const Duration(seconds: 245))
          ),
          (
            'clock(3,729 s)',
            KitoDurationFormatting.clock(const Duration(seconds: 3729))
          ),
          (
            'short(3,900 s)',
            KitoDurationFormatting.short(const Duration(seconds: 3900))
          ),
          (
            'short(2d 3h 9m)',
            KitoDurationFormatting.short(
                const Duration(days: 2, hours: 3, minutes: 9))
          ),
          (
            'spelledOut(3,900 s)',
            KitoDurationFormatting.spelledOut(const Duration(seconds: 3900))
          ),
          (
            'spelledOut · sw',
            KitoDurationFormatting.spelledOut(
                const Duration(minutes: 12, seconds: 30),
                locale: 'sw')
          ),
        ]),
      ),
      KitSample(
        title: 'File sizes',
        subtitle: 'Attachments and downloads, with progress.',
        code: '''KitoFileSizeFormatting.string(1200000);             // 1.2 MB
KitoFileSizeFormatting.progress(received, total);   // 1.2 MB of 4.5 MB''',
        builder: (_) => const _Downloads(),
      ),
      KitSample(
        title: 'Distances',
        subtitle: 'Metric or imperial, the way ride apps round them.',
        code:
            '''KitoDistanceFormatting.string(1240);                                   // 1.2 km
KitoDistanceFormatting.string(805, system: KitoDistanceSystem.imperial); // 0.5 mi''',
        builder: (_) => const _Distances(),
      ),
    ]),
    KitSection('Kenyan phone numbers', Icons.phone_iphone_rounded, [
      KitSample(
        title: 'Type, parse and print',
        subtitle:
            'Groups as you type; E.164, international, local and masked forms.',
        code: '''TextField(
  keyboardType: TextInputType.phone,
  inputFormatters: [KitoKenyanPhoneInputFormatter()],
);
final phone = KitoKenyanPhoneNumber.tryParse(text);
phone?.e164;           // +254712345678
phone?.masked;         // +254 7•• ••• 678''',
        builder: (_) => const _PhoneField(),
      ),
      KitSample(
        title: 'Carrier and wallet',
        subtitle: 'A best guess from the prefix — numbers can be ported.',
        code: '''final phone = KitoKenyanPhoneNumber.tryParse('0733 123 456')!;
phone.carrier.displayName;   // Airtel
phone.carrier.walletName;    // Airtel Money''',
        builder: (_) => const _Carriers(),
      ),
    ]),
    KitSection('Animated numbers', Icons.animation_rounded, [
      KitSample(
        title: 'Rolling balance',
        subtitle:
            'Only the digits that change roll — up when it grows, down when it shrinks.',
        code: '''KitoFormattedNumberText(
  balance,
  format: (v) => KitoMoneyFormatting.string(v, KitoCurrency.kes, cents: KitoMoneyCents.always),
  style: Theme.of(context).textTheme.headlineMedium,
);''',
        builder: (_) => const _Rolling(),
      ),
      KitSample(
        title: 'Counting stats',
        subtitle: 'Counts in like a scoreboard; jumps under Reduce Motion.',
        code:
            '''KitoFormattedCountingText(12480, style: context.kito.typography.display);''',
        builder: (_) => const _Counting(),
      ),
      KitSample(
        title: 'Change badges',
        subtitle: 'Pill, plain or solid; invert colours when down is good.',
        code: '''KitoFormattedChangeBadge(0.124);
KitoFormattedChangeBadge(-0.08, invertColors: true);   // spending went down
KitoFormattedChangeBadge(0.05, style: KitoFormattedChangeBadgeStyle.solid);''',
        builder: (_) => const _Badges(),
      ),
    ]),
  ],
);

// MARK: Helpers

class _Table extends StatelessWidget {
  const _Table(this.rows);
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return DemoWidth(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(
                  child: Text(k,
                      style: kito.typography.caption.copyWith(
                          color:
                              kito.colors.onBackground.withValues(alpha: 0.6))),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(v,
                      textAlign: TextAlign.end,
                      style: kito.typography.bodyEmphasized.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

// MARK: Money

class _Statement extends StatelessWidget {
  const _Statement();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    const rows = [
      ('Received from Amina K', 5000.0),
      ('Java House, Kimathi St', -780.0),
      ('KPLC prepaid tokens', -1000.0),
      ('Received from Otieno M', 2150.5),
      ('Fuliza repayment', -312.4),
    ];
    return DemoWidth(
      width: 340,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final (name, amount) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: (amount > 0
                        ? kito.colors.success
                        : kito.colors.onBackground)
                    .withValues(alpha: 0.12),
                child: Icon(
                    amount > 0
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 16,
                    color: amount > 0
                        ? kito.colors.success
                        : kito.colors.onBackground),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: kito.typography.label)),
              Text(KitoMoneyFormatting.signed(amount, KitoCurrency.kes),
                  style: kito.typography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: amount > 0 ? kito.colors.success : null)),
            ]),
          ),
      ]),
    );
  }
}

class _StatTiles extends StatelessWidget {
  const _StatTiles();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final tiles = [
      ('Sales this month', 1240000.kitoCompactAmount(KitoCurrency.kes), 0.124),
      ('Chama savings', 386500.kitoCompactAmount(KitoCurrency.kes), 0.041),
      (
        'Export orders',
        KitoMoneyFormatting.compact(48300, KitoCurrency.usd,
            display: KitoCurrencyDisplay.symbol),
        -0.028
      ),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (final (label, value, change) in tiles)
        SizedBox(
          width: 150,
          child: KitoSurface(
            border: true,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: kito.typography.caption),
                const SizedBox(height: 6),
                Text(value, style: kito.typography.title),
                const SizedBox(height: 8),
                KitoFormattedChangeBadge(change),
              ],
            ),
          ),
        ),
    ]);
  }
}

class _Currencies extends StatelessWidget {
  const _Currencies();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return DemoWidth(
      width: 320,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final c in KitoCurrency.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text(c.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              SizedBox(
                  width: 48, child: Text(c.code, style: kito.typography.label)),
              Expanded(
                child: Text(
                  KitoMoneyFormatting.string(2500.75, c,
                      display: KitoCurrencyDisplay.symbol),
                  textAlign: TextAlign.end,
                  style: kito.typography.bodyEmphasized,
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// MARK: Numbers

class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    const members = [
      ('Wanjiku M', 48200),
      ('Wycliff N', 45750),
      ('Achieng O', 39900),
      ('Kiprono T', 31400),
      ('Halima A', 28800),
    ];
    return DemoWidth(
      width: 320,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < members.length; i++)
          ListTile(
            dense: true,
            leading: SizedBox(
              width: 40,
              child: Text(KitoNumberFormatting.ordinal(i + 1),
                  style: kito.typography.headline),
            ),
            title: Text(members[i].$1),
            trailing: Text(members[i].$2.kitoAmount(KitoCurrency.kes),
                style: kito.typography.label),
          ),
      ]),
    );
  }
}

// MARK: Dates

class _Relative extends StatefulWidget {
  const _Relative();

  @override
  State<_Relative> createState() => _RelativeState();
}

class _RelativeState extends State<_Relative> {
  String _locale = 'en';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final events = [
      ('Order confirmed', now.subtract(const Duration(seconds: 20))),
      ('Rider picked up your order', now.subtract(const Duration(minutes: 2))),
      ('Delivery expected', now.add(const Duration(hours: 1))),
      ('Paid KPLC tokens', now.subtract(const Duration(days: 1))),
      ('Joined Kito', now.subtract(const Duration(days: 400))),
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SegmentedButton<String>(
        selected: {_locale},
        onSelectionChanged: (s) => setState(() => _locale = s.first),
        segments: const [
          ButtonSegment(value: 'en', label: Text('English')),
          ButtonSegment(value: 'sw', label: Text('Kiswahili')),
          ButtonSegment(value: 'fr', label: Text('Français')),
        ],
      ),
      const SizedBox(height: 12),
      _Table([
        for (final (what, at) in events)
          (what, KitoDateFormatting.relative(at, now: now, locale: _locale)),
      ]),
    ]);
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final kito = context.kito;
    final chats = [
      ('Amina K', 'Niko njiani 🚶🏾‍♀️', const Duration(seconds: 30)),
      (
        'Chama ya Jumamosi',
        'Contributions due Saturday',
        const Duration(minutes: 5)
      ),
      ('Otieno M', 'Sent you KES 2,150', const Duration(hours: 3)),
      ('Mama', 'Umefika salama?', const Duration(days: 2)),
      ('Landlord', 'Rent reminder', const Duration(days: 21)),
      ('Safari crew', 'Maasai Mara photos 📸', const Duration(days: 90)),
    ];
    return DemoWidth(
      width: 330,
      child: Material(
        type: MaterialType.transparency,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (name, last, ago) in chats)
            ListTile(
              dense: true,
              leading: CircleAvatar(child: Text(name.substring(0, 1))),
              title: Text(name, style: kito.typography.label),
              subtitle:
                  Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(
                  KitoDateFormatting.abbreviated(now.subtract(ago), now: now),
                  style: kito.typography.caption),
            ),
        ]),
      ),
    );
  }
}

class _DayLabels extends StatelessWidget {
  const _DayLabels();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final kito = context.kito;
    return DemoWidth(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${KitoDateFormatting.greeting()}, Wycliff',
              style: kito.typography.title),
          Text('${KitoDateFormatting.greeting(locale: 'sw')}, Wycliff',
              style: kito.typography.label),
          const SizedBox(height: 14),
          for (final d in [0, -1, -3, -12])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                KitoDateFormatting.dayLabel(now.add(Duration(days: d)),
                        now: now)
                    .toUpperCase(),
                style: kito.typography.caption.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: kito.colors.onBackground.withValues(alpha: 0.55)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    DateTime at(int h, [int m = 0]) =>
        DateTime(today.year, today.month, today.day, h, m);
    final slots = [
      (at(9), at(10, 30)),
      (at(11), at(13)),
      (at(14), at(15, 30)),
      (at(17), at(19)),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final (a, b) in slots)
        ChoiceChip(
          selected: a.hour == 11,
          onSelected: (_) {},
          avatar: const Icon(Icons.local_shipping_rounded, size: 18),
          label: Text(KitoDateFormatting.timeRange(a, b)),
        ),
    ]);
  }
}

// MARK: Units

class _Downloads extends StatelessWidget {
  const _Downloads();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    const files = [
      ('KRA PIN certificate.pdf', 845, 845),
      ('Receipt scan.jpg', 1200000, 460000),
      ('Chama minutes.docx', 38400, 38400),
      ('Safari video.mp4', 3456000000, 1200000000),
    ];
    return DemoWidth(
      width: 330,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final (name, total, got) in files)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              const Icon(Icons.insert_drive_file_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: kito.typography.label),
                    Text(
                      got == total
                          ? KitoFileSizeFormatting.string(total)
                          : KitoFileSizeFormatting.progress(got, total),
                      style: kito.typography.caption,
                    ),
                  ],
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _Distances extends StatefulWidget {
  const _Distances();

  @override
  State<_Distances> createState() => _DistancesState();
}

class _DistancesState extends State<_Distances> {
  KitoDistanceSystem _system = KitoDistanceSystem.metric;

  @override
  Widget build(BuildContext context) {
    const trips = [
      ('Boda to Yaya Centre', 850.0),
      ('Matatu to Rongai', 18400.0),
      ('Walk to the stage', 42.0),
      ('Nairobi to Naivasha', 92000.0),
      ('Jog around Karura', 5300.0),
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SegmentedButton<KitoDistanceSystem>(
        selected: {_system},
        onSelectionChanged: (s) => setState(() => _system = s.first),
        segments: const [
          ButtonSegment(
              value: KitoDistanceSystem.metric, label: Text('Metric')),
          ButtonSegment(
              value: KitoDistanceSystem.imperial, label: Text('Imperial')),
        ],
      ),
      const SizedBox(height: 10),
      _Table([
        for (final (name, m) in trips)
          (name, KitoDistanceFormatting.string(m, system: _system)),
      ]),
    ]);
  }
}

// MARK: Phone

class _PhoneField extends StatefulWidget {
  const _PhoneField();

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  final _controller = TextEditingController(text: '0712 345 678');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = KitoKenyanPhoneNumber.tryParse(_controller.text);
    return DemoWidth(
      width: 330,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [KitoKenyanPhoneInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'M-Pesa number',
            prefixIcon: const Icon(Icons.phone_android_rounded),
            border: const OutlineInputBorder(),
            errorText: _controller.text.length > 3 && phone == null
                ? 'Not a Kenyan mobile number yet'
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (phone != null)
          _Table([
            ('e164', phone.e164),
            ('international', phone.international),
            ('local', phone.local),
            ('masked', phone.masked),
            ('carrier', phone.carrier.displayName),
          ]),
      ]),
    );
  }
}

class _Carriers extends StatelessWidget {
  const _Carriers();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    const numbers = [
      '0712 345 678',
      '0110 234 567',
      '0733 123 456',
      '0772 987 654',
      '0760 111 222'
    ];
    return DemoWidth(
      width: 330,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final n in numbers)
          Builder(builder: (context) {
            final p = KitoKenyanPhoneNumber.tryParse(n)!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(child: Text(p.local, style: kito.typography.label)),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(p.carrier.walletName ?? p.carrier.displayName),
                ),
              ]),
            );
          }),
      ]),
    );
  }
}

// MARK: Animated

class _Rolling extends StatefulWidget {
  const _Rolling();

  @override
  State<_Rolling> createState() => _RollingState();
}

class _RollingState extends State<_Rolling> {
  double _balance = 24580;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('M-Pesa balance', style: kito.typography.caption),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: KitoFormattedNumberText(
          _balance,
          format: (v) => KitoMoneyFormatting.string(v, KitoCurrency.kes,
              cents: KitoMoneyCents.always),
          style: kito.typography.display.copyWith(fontSize: 30),
        ),
      ),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: [
        FilledButton.tonal(
            onPressed: () => setState(() => _balance += 1500),
            child: const Text('+ KES 1,500')),
        OutlinedButton(
            onPressed: () => setState(() => _balance -= 780.5),
            child: const Text('− KES 780.50')),
      ]),
    ]);
  }
}

class _Counting extends StatefulWidget {
  const _Counting();

  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  int _round = 0;

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    final stats = [
      ('Customers', 12480.0 + _round * 312),
      ('Orders', 3920.0 + _round * 87),
      ('Riders', 146.0 + _round * 3),
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (label, value) in stats)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: [
                KitoFormattedCountingText(value, style: kito.typography.title),
                Text(label, style: kito.typography.caption),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () => setState(() => _round++),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('New week'),
      ),
    ]);
  }
}

class _Badges extends StatelessWidget {
  const _Badges();

  @override
  Widget build(BuildContext context) {
    final kito = context.kito;
    Widget row(String label, Widget badge) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(label, style: kito.typography.label)),
            badge,
          ]),
        );
    return DemoWidth(
      width: 320,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        row('Safaricom shares', const KitoFormattedChangeBadge(0.124)),
        row('Maize price', const KitoFormattedChangeBadge(-0.031)),
        row('Rent', const KitoFormattedChangeBadge(0)),
        row('Transport spending',
            const KitoFormattedChangeBadge(-0.08, invertColors: true)),
        row(
            'Inline',
            const KitoFormattedChangeBadge(0.052,
                style: KitoFormattedChangeBadgeStyle.plain)),
        row(
            'Hero number',
            const KitoFormattedChangeBadge(0.05,
                style: KitoFormattedChangeBadgeStyle.solid)),
      ]),
    );
  }
}
