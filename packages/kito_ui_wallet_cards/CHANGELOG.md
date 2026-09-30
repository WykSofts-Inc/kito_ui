## 0.1.0

- First release: `KitoWalletCardView` (ID-1 faces with a chip, contactless mark, masked number,
  holder and expiry; balance in the corner; a 3D flip to the signature strip and CVV; gradient,
  patterned and frosted-glass `KitoWalletCardStyle`s), `KitoWalletCardTilt` with a foil sheen,
  `KitoWalletCardStack` (tap to raise with a detail area, drag down to put back),
  `KitoWalletCardCarousel`, `KitoWalletCardFan`, `KitoWalletCardDeck`, `KitoWalletPocket` (a
  stitched pocket the cards spring out of while the total counts up), `KitoWalletBalanceCard`
  (hide/show, change line, sparkline, quick actions) and `KitoWalletPassView` for boarding
  passes, event tickets, coupons and stamp cards; `KitoWalletCard` models that only keep the
  last four digits (or an M-Pesa-style masked phone number); and the pure
  `KitoWalletCardNumber` (brand detection for Visa, Mastercard, Amex, Discover, Diners, JCB,
  UnionPay, Verve and mobile money; grouping, masking, Luhn, expiry), `KitoWalletMoney`,
  `KitoWalletCardNumberFormatter` and `KitoWalletExpiryFormatter`. Right-to-left, Reduce Motion
  and screen readers supported throughout.
