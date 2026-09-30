// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_wallet_cards/kito_ui_wallet_cards.dart';

import '../catalog/catalog.dart';

List<KitoWalletCard> _wallet() => [
      KitoWalletCard.fromNumber('4111 1111 1111 4120',
          id: 'everyday',
          name: 'Everyday',
          holder: 'Wycliff Njenga',
          expiry: '09/29',
          balance: 74500,
          issuer: 'Equity',
          style: KitoWalletCardStyle.ocean),
      KitoWalletCard.fromNumber('5500 0000 0000 8812',
          id: 'travel',
          name: 'Travel',
          holder: 'Wycliff Njenga',
          expiry: '03/28',
          balance: 120300,
          style: KitoWalletCardStyle.midnight),
      KitoWalletCard.fromNumber('3782 822463 10005',
          id: 'business',
          name: 'Business',
          holder: 'Amina Wanjiru',
          expiry: '11/27',
          balance: 56000,
          style: KitoWalletCardStyle.gold),
      KitoWalletCard.mobileMoney(
          id: 'mpesa',
          phone: '0712 345 678',
          name: 'Daily spend',
          issuer: 'M-PESA',
          holder: 'Wycliff N',
          balance: 12450),
    ];

const Map<String, List<(String, String, double)>> _transactions = {
  'everyday': [
    ('Naivas Westgate', 'Groceries', -2300.0),
    ('Java House', 'Coffee', -480.0),
    ('Salary', 'Kito Ltd', 185000.0),
  ],
  'travel': [
    ('Kenya Airways', 'NBO → MBA', -14200.0),
    ('Madaraka Express', 'First class', -4500.0),
  ],
  'business': [
    ('Safaricom Business', 'Airtime', -5000.0),
    ('KPLC tokens', 'Office', -3200.0),
  ],
  'mpesa': [
    ('Mama Mboga', 'Lipa na M-Pesa', -350.0),
    ('Otieno', 'Received', 1500.0),
    ('Matatu fare', 'Till 552211', -100.0),
  ],
};

const _sgr = KitoWalletPass(
  id: 'sgr',
  kind: KitoWalletPassKind.boarding,
  title: 'Madaraka Express',
  subtitle: 'Economy · Coach 4',
  from:
      KitoWalletPassStop(code: 'NBO', name: 'Nairobi Terminus', time: '08:00'),
  to: KitoWalletPassStop(code: 'MSA', name: 'Mombasa Terminus', time: '13:55'),
  fields: [
    KitoWalletPassField('Date', 'Fri 17 Oct'),
    KitoWalletPassField('Seat', '42B'),
    KitoWalletPassField('Passenger', 'Wycliff N'),
  ],
  code: 'SGR-7Q2K-42B',
  codeLabel: 'SGR7Q2K',
);

/// The gallery for kito_ui_wallet_cards.
final walletCardsKit = KitEntry(
  title: 'Wallet Cards',
  package: 'kito_ui_wallet_cards',
  blurb: 'card faces, brand detection, wallets, balances and passes',
  icon: Icons.credit_card_rounded,
  category: KitCategory.commerce,
  isNew: true,
  sections: [
    KitSection('Cards', Icons.credit_card_rounded, [
      KitSample(
        title: 'Card faces',
        subtitle:
            'Visa, Mastercard, Amex and an M-Pesa wallet; only the last four digits are kept.',
        code: '''final card = KitoWalletCard.fromNumber(
  '4111 1111 1111 4120',          // brand detected, only "4120" kept
  name: 'Everyday',
  holder: 'Wycliff Njenga',
  expiry: '09/29',
  balance: 74500,
);
final mpesa = KitoWalletCard.mobileMoney(phone: '0712 345 678', issuer: 'M-PESA');

KitoWalletCardView(card: card)''',
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, card) in _wallet().indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: KitoWalletCardView(card: card, showsBalance: i == 1),
              ),
          ],
        ),
      ),
      KitSample(
        title: 'Flip to the CVV',
        subtitle:
            'Tap the card to turn it over in 3D; Reduce Motion cross-fades.',
        code: '''KitoWalletCardView(
  card: card,
  isFlipped: flipped,
  cvv: '284',
  onTap: () => setState(() => flipped = !flipped),
)''',
        builder: (_) => const _Flip(),
      ),
      KitSample(
        title: 'Glass and tilt',
        subtitle:
            'A frosted card over a Maasai-market gradient; press and drag to tilt it.',
        code: '''KitoWalletCardTilt(
  child: KitoWalletCardView(
    card: card.copyWith(style: KitoWalletCardStyle.glass),
  ),
)''',
        builder: (_) => ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE11D48),
                  Color(0xFFF59E0B),
                  Color(0xFF7C3AED)
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: KitoWalletCardTilt(
                child: KitoWalletCardView(
                  card: _wallet()
                      .first
                      .copyWith(style: KitoWalletCardStyle.glass),
                ),
              ),
            ),
          ),
        ),
      ),
      KitSample(
        title: 'Styles',
        subtitle:
            'Every preset: gradients with waves, circles, brushed metal, dots and gloss.',
        code:
            '''KitoWalletCardStyle.ocean   // sunset, aqua, midnight, lavender,
                            // lime, pearl, gold, safari, glass
KitoWalletCardStyle(
  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  pattern: KitoWalletCardPattern.waves,
)''',
        builder: (_) => const _Styles(),
      ),
    ]),
    KitSection('Numbers', Icons.pin_rounded, [
      KitSample(
        title: 'Live brand detection',
        subtitle:
            'Type or pick a test number: it groups, detects the brand and checks Luhn.',
        code: '''TextField(inputFormatters: [KitoWalletCardNumberFormatter()])

KitoWalletCardNumber.brandOf(text);     // visa, amex, mobileMoney…
KitoWalletCardNumber.isValid(text);     // Luhn
KitoWalletCardView(card: KitoWalletCard.fromNumber(text, name: 'New card'))''',
        builder: (_) => const _LiveNumber(),
      ),
      KitSample(
        title: 'Masking',
        subtitle: 'Grouped per brand, with M-Pesa-style phone masking.',
        code:
            '''KitoWalletCardNumber.masked('4120', brand: KitoWalletCardBrand.visa);
KitoWalletCardNumber.masked('0005', brand: KitoWalletCardBrand.amex);
KitoWalletCardNumber.maskedPhone('+254 712 345 678');
KitoWalletMoney.format(263250, 'KES');''',
        builder: (_) => const _Masking(),
      ),
    ]),
    KitSection('Wallets', Icons.account_balance_wallet_rounded, [
      KitSample(
        title: 'Wallet stack',
        subtitle:
            'Tap a card to raise it with its transactions; tap again or drag down to put it back.',
        code: '''KitoWalletCardStack(
  cards: cards,
  selectedId: selected,
  onSelect: (id) => setState(() => selected = id),
  height: 560,
  detailBuilder: (card) => Transactions(card),
)''',
        builder: (_) => const _Stack(),
      ),
      KitSample(
        title: 'The pocket',
        subtitle:
            'Cards tucked in a stitched pocket; reveal them and the total counts up.',
        code: '''KitoWalletPocket(
  cards: cards,
  isRevealed: revealed,
  onChanged: (v) => setState(() => revealed = v),
)''',
        builder: (_) => const _Pocket(),
      ),
      KitSample(
        title: 'Carousel',
        subtitle: 'Neighbours turn away and shrink; the travel card is frozen.',
        code: '''KitoWalletCardCarousel(
  cards: cards,
  onChanged: (card) => setState(() => current = card),
  overlayBuilder: (card) => frozen.contains(card.id) ? const FrostLayer() : null,
)''',
        builder: (_) => const _Carousel(),
      ),
      KitSample(
        title: 'Fan',
        subtitle: 'A hand of cards; tap one to lift it out.',
        code: '''KitoWalletCardFan(
  cards: cards,
  selectedId: picked,
  onSelect: (id) => setState(() => picked = id),
)''',
        builder: (_) => const _Fan(),
      ),
      KitSample(
        title: 'Deck',
        subtitle: 'Swipe the top card either way and it tucks in at the back.',
        code: '''KitoWalletCardDeck(
  cards: cards,
  onChanged: (top) => setState(() => current = top),
)''',
        builder: (_) => KitoWalletCardDeck(cards: _wallet()),
      ),
    ]),
    KitSection('Balances and passes', Icons.confirmation_number_rounded, [
      KitSample(
        title: 'M-Pesa balance',
        subtitle:
            'Hide it with the eye; the amount counts up; quick actions below.',
        code: '''KitoWalletBalanceCard(
  title: 'M-Pesa balance',
  balance: 12450,
  change: '+KES 3,200 this week',
  subtitle: 'Fuliza limit KES 5,000',
  trend: const [8, 9.5, 9, 11, 10.2, 12.45],
  isHidden: hidden,
  onToggleHidden: () => setState(() => hidden = !hidden),
  style: KitoWalletCardStyle.safari,
  actions: [KitoWalletAction(icon: Icons.send_rounded, label: 'Send', onTap: send)],
)''',
        builder: (_) => const _Balance(),
      ),
      KitSample(
        title: 'Dollar account',
        subtitle: 'Two decimals, a dip this month, on brushed midnight.',
        code: '''KitoWalletBalanceCard(
  title: 'USD account',
  balance: 1204.5,
  currencyCode: 'USD',
  decimals: 2,
  change: r'−\$86.20 this month',
  changeIsPositive: false,
)''',
        builder: (_) => const KitoWalletBalanceCard(
          title: 'USD account · Stanbic',
          balance: 1204.5,
          currencyCode: 'USD',
          decimals: 2,
          change: r'−$86.20 this month',
          changeIsPositive: false,
          trend: [1320, 1290, 1300, 1250, 1204.5],
        ),
      ),
      KitSample(
        title: 'SGR boarding pass',
        subtitle: 'From → to, seat and a code behind a perforated tear line.',
        code: '''KitoWalletPassView(
  pass: const KitoWalletPass(
    id: 'sgr',
    kind: KitoWalletPassKind.boarding,
    title: 'Madaraka Express',
    from: KitoWalletPassStop(code: 'NBO', name: 'Nairobi Terminus', time: '08:00'),
    to: KitoWalletPassStop(code: 'MSA', name: 'Mombasa Terminus', time: '13:55'),
    fields: [KitoWalletPassField('Seat', '42B')],
    code: 'SGR-7Q2K-42B',
  ),
  codeBuilder: (data) => MyQrCode(data),   // optional, for a scannable code
)''',
        builder: (_) => const KitoWalletPassView(pass: _sgr),
      ),
      KitSample(
        title: 'Match ticket and coupon',
        subtitle: 'An event with a headline, and a Naivas voucher.',
        code: '''KitoWalletPass(
  id: 'stars',
  kind: KitoWalletPassKind.event,
  title: 'Kasarani Stadium',
  headline: 'Harambee Stars vs Uganda',
  fields: [KitoWalletPassField('Gate', '3'), KitoWalletPassField('Seat', 'VIP 12')],
  code: 'KSR-2210-VIP12',
)''',
        builder: (_) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KitoWalletPassView(
              pass: KitoWalletPass(
                id: 'stars',
                kind: KitoWalletPassKind.event,
                title: 'Kasarani Stadium',
                subtitle: 'Sat 22 Nov · 16:00',
                colors: [Color(0xFFB91C1C), Color(0xFF15803D)],
                headline: 'Harambee Stars vs Uganda',
                fields: [
                  KitoWalletPassField('Gate', '3'),
                  KitoWalletPassField('Seat', 'VIP 12'),
                ],
                code: 'KSR-2210-VIP12',
                codeLabel: 'KSR2210',
              ),
            ),
            SizedBox(height: 18),
            KitoWalletPassView(
              pass: KitoWalletPass(
                id: 'naivas',
                kind: KitoWalletPassKind.coupon,
                title: 'Naivas',
                subtitle: 'Fresh produce · until 31 Oct',
                colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
                headline: '20% OFF',
              ),
            ),
          ],
        ),
      ),
      KitSample(
        title: 'Loyalty stamps',
        subtitle: 'Java House coffee card: stamps pop in one after another.',
        code: '''KitoWalletPass(
  id: 'java',
  kind: KitoWalletPassKind.loyalty,
  title: 'Java House Rewards',
  stamps: 7,
  stampsTotal: 10,
)''',
        builder: (_) => const KitoWalletPassView(
          pass: KitoWalletPass(
            id: 'java',
            kind: KitoWalletPassKind.loyalty,
            title: 'Java House Rewards',
            subtitle: 'Gold member',
            colors: [Color(0xFF7C2D12), Color(0xFFB45309)],
            stamps: 7,
            stampsTotal: 10,
            fields: [KitoWalletPassField('Points', '1,240')],
          ),
        ),
      ),
    ]),
  ],
);

class _Flip extends StatefulWidget {
  const _Flip();

  @override
  State<_Flip> createState() => _FlipState();
}

class _FlipState extends State<_Flip> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KitoWalletCardView(
          card: _wallet()[1],
          isFlipped: _flipped,
          cvv: '284',
          onTap: () => setState(() => _flipped = !_flipped),
          semanticHint: 'Flips the card',
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _flipped = !_flipped),
          icon: const Icon(Icons.flip_rounded, size: 18),
          label: Text(_flipped ? 'Show the front' : 'Show the CVV'),
        ),
      ],
    );
  }
}

class _Styles extends StatelessWidget {
  const _Styles();

  static const _names = [
    'Ocean',
    'Sunset',
    'Aqua',
    'Midnight',
    'Lavender',
    'Lime',
    'Pearl',
    'Gold',
    'Safari',
    'Glass',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    const styles = KitoWalletCardStyle.presets;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF334155)]),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (context, constraints) {
          final width = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < styles.length; i++)
                SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      KitoWalletCardView(
                        card: KitoWalletCard(
                          id: 'style$i',
                          name: _names[i],
                          last4: '${4100 + i * 7}',
                          holder: 'Wanjiru K',
                          expiry: '0${1 + i % 9}/30',
                          brand: i.isEven
                              ? KitoWalletCardBrand.visa
                              : KitoWalletCardBrand.mastercard,
                          style: styles[i],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_names[i],
                          style: theme.typography.caption
                              .copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _LiveNumber extends StatefulWidget {
  const _LiveNumber();

  @override
  State<_LiveNumber> createState() => _LiveNumberState();
}

class _LiveNumberState extends State<_LiveNumber> {
  final _number = TextEditingController(text: '4242 4242 4242 4242');

  static const _samples = [
    ('Visa', '4242424242424242'),
    ('Mastercard', '5555555555554444'),
    ('Amex', '378282246310005'),
    ('Verve', '5061000000000000000'),
    ('M-Pesa', '0712345678'),
  ];

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _pick(String number) {
    final formatted = KitoWalletCardNumber.format(number);
    _number.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final text = _number.text;
    final brand = KitoWalletCardNumber.brandOf(text);
    final card = brand.isMobileMoney
        ? KitoWalletCard.mobileMoney(
            id: 'live', phone: text, issuer: 'M-PESA', holder: 'Wycliff N')
        : KitoWalletCard.fromNumber(text.isEmpty ? '0000' : text,
            id: 'live',
            name: 'New card',
            holder: 'Wycliff Njenga',
            expiry: '09/29',
            style: switch (brand) {
              KitoWalletCardBrand.visa => KitoWalletCardStyle.ocean,
              KitoWalletCardBrand.mastercard => KitoWalletCardStyle.midnight,
              KitoWalletCardBrand.amex => KitoWalletCardStyle.gold,
              KitoWalletCardBrand.verve => KitoWalletCardStyle.sunset,
              _ => KitoWalletCardStyle.lavender,
            });
    final valid = brand.isMobileMoney
        ? KitoWalletCardNumber.digits(text).length >= 10
        : KitoWalletCardNumber.isValid(text);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: theme.motion.medium,
          child: KeyedSubtree(
            key: ValueKey(brand),
            child: KitoWalletCardView(card: card),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [KitoWalletCardNumberFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Card or M-Pesa number',
            border: const OutlineInputBorder(),
            suffixIcon: Icon(
              valid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: valid ? theme.colors.success : theme.colors.warning,
            ),
            helperText:
                '${brand.displayName}${brand.cvvLength > 0 ? ' · ${brand.cvvLength}-digit CVV' : ''}'
                ' · ${valid ? 'looks valid' : 'keep typing'}',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, number) in _samples)
              ActionChip(label: Text(label), onPressed: () => _pick(number)),
          ],
        ),
      ],
    );
  }
}

class _Masking extends StatelessWidget {
  const _Masking();

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final rows = [
      (
        'Visa',
        KitoWalletCardNumber.masked('4120', brand: KitoWalletCardBrand.visa)
      ),
      (
        'Amex',
        KitoWalletCardNumber.masked('0005', brand: KitoWalletCardBrand.amex)
      ),
      (
        'Diners',
        KitoWalletCardNumber.masked('5904',
            brand: KitoWalletCardBrand.dinersClub)
      ),
      ('Short', KitoWalletCardNumber.short('4111111111114120')),
      ('M-Pesa', KitoWalletCardNumber.maskedPhone('+254 712 345 678')),
      ('Total', KitoWalletMoney.format(_wallet().totalBalance, 'KES')),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(label,
                      style: theme.typography.caption.copyWith(
                          color:
                              theme.colors.onSurface.withValues(alpha: 0.6))),
                ),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(value,
                        textAlign: TextAlign.end,
                        style: theme.typography.bodyEmphasized.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Stack extends StatefulWidget {
  const _Stack();

  @override
  State<_Stack> createState() => _StackState();
}

class _StackState extends State<_Stack> {
  final _cards = _wallet();
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return KitoWalletCardStack(
      cards: _cards,
      selectedId: _selected,
      onSelect: (id) => setState(() => _selected = id),
      height: 560,
      detailBuilder: (card) => ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text('Recent', style: theme.typography.headline),
          const SizedBox(height: 6),
          for (final (name, detail, amount)
              in _transactions[card.id] ?? const <(String, String, double)>[])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colors.surfaceMuted,
                    child: Icon(
                        amount > 0
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        size: 16,
                        color: amount > 0
                            ? theme.colors.success
                            : theme.colors.onSurface),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.label),
                        Text(detail, style: theme.typography.caption),
                      ],
                    ),
                  ),
                  Text(
                    '${amount > 0 ? '+' : ''}${KitoWalletMoney.format(amount, card.currencyCode)}',
                    style: theme.typography.label.copyWith(
                        color: amount > 0 ? theme.colors.success : null,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pocket extends StatefulWidget {
  const _Pocket();

  @override
  State<_Pocket> createState() => _PocketState();
}

class _PocketState extends State<_Pocket> {
  final _cards = _wallet();
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: KitoWalletPocket(
        cards: _cards,
        isRevealed: _revealed,
        onChanged: (v) => setState(() => _revealed = v),
      ),
    );
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel();

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _cards = _wallet();
  late KitoWalletCard _current = _cards.first;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KitoWalletCardCarousel(
          cards: _cards,
          onChanged: (c) => setState(() => _current = c),
          overlayBuilder: (card) => card.id == 'travel'
              ? ColoredBox(
                  color: Colors.white.withValues(alpha: 0.35),
                  child: const Center(
                    child: Chip(
                      avatar: Icon(Icons.ac_unit_rounded, size: 16),
                      label: Text('Frozen'),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: theme.motion.fast,
          child: Text('${_current.name} · ${_current.formattedBalance}',
              key: ValueKey(_current.id), style: theme.typography.headline),
        ),
      ],
    );
  }
}

class _Fan extends StatefulWidget {
  const _Fan();

  @override
  State<_Fan> createState() => _FanState();
}

class _FanState extends State<_Fan> {
  final _cards = _wallet();
  String? _picked;

  @override
  Widget build(BuildContext context) => KitoWalletCardFan(
        cards: _cards,
        selectedId: _picked,
        onSelect: (id) => setState(() => _picked = id),
      );
}

class _Balance extends StatefulWidget {
  const _Balance();

  @override
  State<_Balance> createState() => _BalanceState();
}

class _BalanceState extends State<_Balance> {
  bool _hidden = false;
  double _balance = 12450;

  @override
  Widget build(BuildContext context) {
    return KitoWalletBalanceCard(
      title: 'M-Pesa balance',
      balance: _balance,
      change: '+KES 3,200 this week',
      subtitle: 'Fuliza limit KES 5,000',
      trend: [8, 9.5, 9, 11, 10.2, _balance / 1000],
      isHidden: _hidden,
      onToggleHidden: () => setState(() => _hidden = !_hidden),
      style: KitoWalletCardStyle.safari,
      actions: [
        KitoWalletAction(
            icon: Icons.send_rounded,
            label: 'Send',
            onTap: () => setState(() => _balance -= 500)),
        KitoWalletAction(
            icon: Icons.storefront_rounded,
            label: 'Lipa',
            onTap: () => setState(() => _balance -= 350)),
        KitoWalletAction(
            icon: Icons.account_balance_rounded,
            label: 'Withdraw',
            onTap: () => setState(() => _balance -= 1000)),
        KitoWalletAction(
            icon: Icons.add_rounded,
            label: 'Top up',
            onTap: () => setState(() => _balance += 2000)),
      ],
    );
  }
}
