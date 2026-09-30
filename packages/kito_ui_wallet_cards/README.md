# kito_ui_wallet_cards

Payment cards and wallets for Flutter: card faces with brand detection and masked numbers,
gradient and frosted-glass styles, a flip to the CVV, a tilt with a foil sheen, a wallet stack, a
carousel, a fan and a swipeable deck, a stitched pocket that reveals your total, a balance card,
and passes, tickets and loyalty cards. Part of [Kito UI](https://github.com/WykSofts-Inc/kito_ui);
everything follows `KitoTheme`, right-to-left layouts, text scaling and Reduce Motion.

Cards only ever hold the last four digits (or a masked phone number for mobile money). Brand
marks are drawn — a wordmark, an icon or two circles — so bring your own artwork where you have
the rights to it. No native plugins, so there's no platform setup.

## Install

```yaml
dependencies:
  kito_ui_wallet_cards: ^0.1.0
```

```dart
import 'package:kito_ui_wallet_cards/kito_ui_wallet_cards.dart';
```

## Cards

```dart
final everyday = KitoWalletCard.fromNumber(
  '4111 1111 1111 4120',          // brand detected, only "4120" is kept
  name: 'Everyday',
  holder: 'Wycliff Njenga',
  expiry: '09/29',
  balance: 74500,
  style: KitoWalletCardStyle.ocean,
);

final mpesa = KitoWalletCard.mobileMoney(phone: '0712 345 678', issuer: 'M-PESA', balance: 12450);
// shown as "0712 ••• 678" on a green face

KitoWalletCardView(card: everyday)                                   // front
KitoWalletCardView(card: everyday, showsBalance: true)               // balance in the corner
KitoWalletCardView(card: everyday, isFlipped: flipped, cvv: '123',   // 3D flip to the back
    onTap: () => setState(() => flipped = !flipped))
KitoWalletCardTilt(child: KitoWalletCardView(card: everyday))        // tilts toward your finger
```

Styles: `ocean`, `sunset`, `aqua`, `midnight`, `lavender`, `lime`, `pearl`, `gold`, `safari` and
`glass` (frosted, over whatever is behind it), or your own
`KitoWalletCardStyle(colors:, foreground:, pattern:)` with `waves`, `circles`, `brushed`, `dots`
or `gloss`. Marks: `KitoWalletCardMark.wordmark('NOVA', italic: true)`, `.icon(...)`,
`.circles(a, b)` or `KitoWalletCardMark.forBrand(brand)`.

## Numbers

```dart
KitoWalletCardNumber.brandOf('3782 82');                // amex
KitoWalletCardNumber.brandOf('+254 712 345 678');       // mobileMoney
KitoWalletCardNumber.format('378282246310005');         // "3782 822463 10005"
KitoWalletCardNumber.masked('0005', brand: KitoWalletCardBrand.amex);   // "•••• •••••• •0005"
KitoWalletCardNumber.maskedPhone('0712345678');         // "0712 ••• 678"
KitoWalletCardNumber.isValid('4242 4242 4242 4242');    // Luhn
KitoWalletCardNumber.isExpiryValid('09/29');

TextField(inputFormatters: [KitoWalletCardNumberFormatter()])   // groups as you type
TextField(inputFormatters: [KitoWalletExpiryFormatter()])       // "MM/YY"

KitoWalletMoney.format(263250, 'KES');                  // "KES 263,250"
cards.totalBalance;
```

Brands: Visa, Mastercard, American Express, Discover, Diners Club, JCB, UnionPay, Verve and
mobile money, each with its digit grouping and CVV length.

## Stack, carousel, fan and deck

```dart
KitoWalletCardStack(
  cards: cards,
  selectedId: selected,
  onSelect: (id) => setState(() => selected = id),
  height: 520,
  detailBuilder: (card) => RecentTransactions(card),
)
KitoWalletCardCarousel(cards: cards, onChanged: (card) => setState(() => current = card))
KitoWalletCardFan(cards: cards, selectedId: picked, onSelect: (id) => setState(() => picked = id))
KitoWalletCardDeck(cards: cards, onChanged: (top) => setState(() => current = top))
```

Tap a card in the stack to raise it (the rest tuck into a pile) and tap it again, or drag it
down, to put it back. Swipe the deck's top card either way to send it to the back; screen
readers get a "Next card" action.

## The pocket

```dart
KitoWalletPocket(
  cards: cards,
  isRevealed: revealed,
  onChanged: (v) => setState(() => revealed = v),
  style: KitoWalletPocketStyle.midnight,     // slate, tan, forest
)
```

Cards peek out of a stitched pocket with the total hidden. Reveal it and they spring out and fan,
each showing its balance, while a glow blooms behind them and the total counts up.

## Balance card

```dart
KitoWalletBalanceCard(
  title: 'M-Pesa balance',
  balance: 12450,
  change: '+KES 3,200 this week',
  subtitle: 'Fuliza limit KES 5,000',
  trend: const [8, 9.5, 9, 11, 10.2, 12.45],
  isHidden: hidden,
  onToggleHidden: () => setState(() => hidden = !hidden),
  style: KitoWalletCardStyle.safari,
  actions: [
    KitoWalletAction(icon: Icons.send_rounded, label: 'Send', onTap: send),
    KitoWalletAction(icon: Icons.storefront_rounded, label: 'Lipa', onTap: pay),
  ],
)
```

## Passes, tickets and loyalty cards

```dart
KitoWalletPassView(
  pass: const KitoWalletPass(
    id: 'sgr',
    kind: KitoWalletPassKind.boarding,
    title: 'Madaraka Express',
    subtitle: 'Economy · Coach 4',
    from: KitoWalletPassStop(code: 'NBO', name: 'Nairobi Terminus', time: '08:00'),
    to: KitoWalletPassStop(code: 'MSA', name: 'Mombasa Terminus', time: '13:55'),
    fields: [KitoWalletPassField('Seat', '42B')],
    code: 'SGR-7Q2K-42B',
    codeLabel: 'SGR7Q2K',
  ),
  codeBuilder: (data) => MyQrCode(data),   // optional: a real, scannable code
)
```

Kinds: `boarding` (from → to), `event`, `coupon` (a big `headline`) and `loyalty` (`stamps` of
`stampsTotal`). Without `codeBuilder` the code is a decorative pattern made from the data — it
is not scannable.

## Right-to-left and accessibility

Faces, patterns, the stack, fan, carousel and passes mirror with the text direction; numbers and
codes stay left-to-right. The flip turns the other way, the carousel's neighbours still turn to
face the centre, the deck follows your finger, and the tilt leans toward it. Every card reads as
"Everyday Visa ending 4120" (plus the balance when shown), buttons have labels and 44-point
targets, and every animation falls back to a plain ease or fade with Reduce Motion.

## License

MIT — see [LICENSE](LICENSE).
