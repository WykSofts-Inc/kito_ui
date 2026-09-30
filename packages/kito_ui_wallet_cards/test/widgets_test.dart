// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_wallet_cards/kito_ui_wallet_cards.dart';

import 'helpers.dart';

final _cards = [
  KitoWalletCard.fromNumber('4111111111114120',
      id: 'visa',
      name: 'Everyday',
      holder: 'Wycliff Njenga',
      expiry: '09/29',
      balance: 74500),
  KitoWalletCard.fromNumber('5500000000008812',
      id: 'mc',
      name: 'Travel',
      holder: 'Wycliff Njenga',
      expiry: '03/28',
      balance: 120300,
      style: KitoWalletCardStyle.midnight),
  KitoWalletCard.fromNumber('378282246310005',
      id: 'amex',
      name: 'Business',
      holder: 'Amina Wanjiru',
      expiry: '11/27',
      balance: 56000,
      style: KitoWalletCardStyle.gold),
  KitoWalletCard.mobileMoney(
      id: 'mpesa', phone: '0712345678', issuer: 'M-PESA', balance: 12450),
];

Widget _page(Widget child,
        {TextDirection direction = TextDirection.ltr,
        bool reduceMotion = false}) =>
    testApp(
        Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16), child: child)),
        direction: direction,
        reduceMotion: reduceMotion);

Future<void> _settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _Host extends StatefulWidget {
  const _Host({required this.builder});

  final Widget Function(String? selected, ValueChanged<String?> pick) builder;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? selected;

  @override
  Widget build(BuildContext context) =>
      widget.builder(selected, (id) => setState(() => selected = id));
}

void main() {
  for (final direction in TextDirection.values) {
    for (final reduce in [false, true]) {
      testWidgets(
          'faces and flips, ${direction.name}${reduce ? ', reduced motion' : ''}',
          (tester) async {
        var flipped = false;
        await tester.pumpWidget(_page(
          StatefulBuilder(
            builder: (context, setState) => Column(children: [
              KitoWalletCardView(
                card: _cards.first,
                isFlipped: flipped,
                cvv: '123',
                onTap: () => setState(() => flipped = !flipped),
              ),
              for (final c in _cards.skip(1))
                KitoWalletCardView(card: c, showsBalance: true),
              KitoWalletCardView(
                  card:
                      _cards.first.copyWith(style: KitoWalletCardStyle.glass)),
              const KitoWalletCardTilt(
                  child: SizedBox(width: 300, height: 190)),
            ]),
          ),
          direction: direction,
          reduceMotion: reduce,
        ));
        await tester.pump();
        expect(find.text('•••• •••• •••• 4120'), findsNWidgets(2));
        expect(find.text('•••• •••••• •0005'), findsOneWidget);
        expect(find.text('0712 ••• 678'), findsOneWidget);
        expect(find.text('KES 120,300'), findsOneWidget);
        expect(find.text('VISA'), findsNWidgets(2));
        expect(find.bySemanticsLabel(RegExp('Everyday Visa ending 4120')),
            findsNWidgets(2));

        await tester.tap(find.byType(KitoWalletCardView).first);
        await _settle(tester);
        expect(find.text('123'), findsOneWidget);
        expect(
            find.bySemanticsLabel(
                'Everyday Visa ending 4120, showing the back, security code 123'),
            findsOneWidget);
        await tester.tap(find.byType(KitoWalletCardView).first);
        await _settle(tester);
        expect(find.text('123'), findsNothing);

        final tilt = tester.getCenter(find.byType(KitoWalletCardTilt));
        final gesture = await tester.startGesture(tilt + const Offset(100, 40));
        await tester.pump();
        await gesture.moveBy(const Offset(-50, -20));
        await tester.pump();
        await gesture.up();
        await _settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the stack raises a card and puts it back by tap or drag',
      (tester) async {
    await tester.pumpWidget(_page(_Host(
      builder: (selected, pick) => KitoWalletCardStack(
        cards: _cards,
        selectedId: selected,
        onSelect: pick,
        height: 560,
        detailBuilder: (card) => Text('Transactions for ${card.name}'),
      ),
    )));
    await tester.pump();
    expect(find.text('Transactions for Business'), findsNothing);

    await tester.tap(find.text('BUSINESS'));
    await _settle(tester);
    expect(find.text('Transactions for Business'), findsOneWidget);
    expect(find.text('KES 56,000'), findsOneWidget);

    await tester.drag(find.text('KES 56,000'), const Offset(0, 160));
    await _settle(tester);
    expect(find.text('Transactions for Business'), findsNothing);

    await tester.tap(find.text('TRAVEL'));
    await _settle(tester);
    expect(find.text('KES 120,300'), findsOneWidget);
    await tester.tap(find.text('KES 120,300'));
    await _settle(tester);
    expect(find.text('KES 120,300'), findsNothing);
  });

  testWidgets('carousel reports the centred card', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(_page(KitoWalletCardCarousel(
        cards: _cards, onChanged: (c) => seen.add(c.id))));
    await tester.pump();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await _settle(tester);
    expect(seen, ['mc']);
  });

  testWidgets('carousel scrolls the other way in RTL', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(_page(
        KitoWalletCardCarousel(cards: _cards, onChanged: (c) => seen.add(c.id)),
        direction: TextDirection.rtl));
    await tester.pump();
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await _settle(tester);
    expect(seen, ['mc']);
  });

  testWidgets('fan lifts a card', (tester) async {
    await tester.pumpWidget(_page(_Host(
      builder: (selected, pick) => KitoWalletCardFan(
          cards: _cards, selectedId: selected, onSelect: pick),
    )));
    await tester.pump();
    final wallet = find.bySemanticsLabel(RegExp('Mobile money M-PESA'));
    await tester.tap(wallet);
    await _settle(tester);
    expect(find.text('KES 12,450'), findsOneWidget);
  });

  testWidgets('deck: swipe the top card to the back, or use the action',
      (tester) async {
    final tops = <String>[];
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_page(
        KitoWalletCardDeck(cards: _cards, onChanged: (c) => tops.add(c.id))));
    await tester.pump();
    expect(find.text('KES 74,500'), findsOneWidget);
    await tester.drag(find.text('KES 74,500'), const Offset(260, 0));
    await _settle(tester);
    expect(tops, ['mc']);
    expect(find.text('KES 120,300'), findsOneWidget);

    await tester.drag(find.text('KES 120,300'), const Offset(30, 0));
    await _settle(tester);
    expect(tops, ['mc']);

    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('1 of 4')));
    final action = CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Next card'));
    node.owner!.performAction(node.id, SemanticsAction.customAction, action);
    await _settle(tester);
    expect(tops, ['mc', 'amex']);
    handle.dispose();
  });

  testWidgets('pocket reveals the cards and counts up the total',
      (tester) async {
    var revealed = false;
    await tester.pumpWidget(_page(StatefulBuilder(
      builder: (context, setState) => KitoWalletPocket(
        cards: _cards,
        isRevealed: revealed,
        onChanged: (v) => setState(() => revealed = v),
      ),
    )));
    await tester.pump();
    expect(find.text('••••••'), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel('Show the balance'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Show the balance'));
    await _settle(tester, 30);
    expect(find.text('KES 263,250'), findsOneWidget);
    expect(find.bySemanticsLabel('Total balance KES 263,250'), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel('Hide the balance'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Hide the balance'));
    await _settle(tester, 30);
    expect(find.text('••••••'), findsOneWidget);
  });

  testWidgets('balance card hides the amount and runs actions', (tester) async {
    var hidden = false;
    var sent = 0;
    await tester.pumpWidget(_page(StatefulBuilder(
      builder: (context, setState) => KitoWalletBalanceCard(
        title: 'M-Pesa balance',
        balance: 12450,
        change: '+KES 3,200 this week',
        trend: const [8, 9.5, 9, 11, 12.45],
        isHidden: hidden,
        onToggleHidden: () => setState(() => hidden = !hidden),
        actions: [
          KitoWalletAction(
              icon: Icons.send_rounded, label: 'Send', onTap: () => sent++),
        ],
      ),
    )));
    await _settle(tester);
    expect(find.text('KES 12,450'), findsOneWidget);
    expect(find.text('+KES 3,200 this week'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Send'));
    expect(sent, 1);
    await tester.tap(find.bySemanticsLabel('Hide balance'));
    await _settle(tester);
    expect(find.text('KES 12,450'), findsNothing);
    expect(find.bySemanticsLabel('M-Pesa balance, hidden'), findsOneWidget);
  });

  for (final direction in TextDirection.values) {
    testWidgets('passes, ${direction.name}', (tester) async {
      await tester.pumpWidget(_page(
        Column(children: [
          KitoWalletPassView(
            pass: const KitoWalletPass(
              id: 'sgr',
              kind: KitoWalletPassKind.boarding,
              title: 'Madaraka Express',
              subtitle: 'Economy · Coach 4',
              from: KitoWalletPassStop(
                  code: 'NBO', name: 'Nairobi Terminus', time: '08:00'),
              to: KitoWalletPassStop(
                  code: 'MSA', name: 'Mombasa Terminus', time: '13:55'),
              fields: [KitoWalletPassField('Seat', '42B')],
              code: 'SGR-7Q2K',
              codeLabel: 'SGR7Q2K',
            ),
            codeBuilder: (data) => Text('code:$data'),
          ),
          const KitoWalletPassView(
            pass: KitoWalletPass(
                id: 'java',
                kind: KitoWalletPassKind.loyalty,
                title: 'Java House Rewards',
                stamps: 7,
                stampsTotal: 10),
          ),
          const KitoWalletPassView(
            pass: KitoWalletPass(
                id: 'coupon',
                kind: KitoWalletPassKind.coupon,
                title: 'Naivas',
                headline: '20% OFF',
                code: 'NAIVAS20'),
          ),
        ]),
        direction: direction,
      ));
      await _settle(tester);
      expect(find.text('NBO'), findsOneWidget);
      expect(find.text('code:SGR-7Q2K'), findsOneWidget);
      expect(find.text('3 more for your reward'), findsOneWidget);
      expect(find.byType(KitoWalletPassCode), findsOneWidget);
      expect(
          find.bySemanticsLabel(RegExp(
              'Madaraka Express, Economy · Coach 4, from Nairobi Terminus at 08:00 to Mombasa Terminus at 13:55')),
          findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('7 of 10 stamps')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a number field with the formatter drives a live card',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_page(StatefulBuilder(
      builder: (context, setState) => Column(children: [
        TextField(
          controller: controller,
          inputFormatters: [KitoWalletCardNumberFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        KitoWalletCardView(
            card: KitoWalletCard.fromNumber(controller.text, name: 'New')),
      ]),
    )));
    await tester.enterText(find.byType(TextField), '378282246310005');
    await tester.pump();
    expect(controller.text, '3782 822463 10005');
    expect(find.text('AMEX'), findsOneWidget);
    expect(find.text('•••• •••••• •0005'), findsOneWidget);
  });
}
