## 0.1.0

- First release: `KitoCheckoutProgress` (dots, segmented and text styles; tap finished steps
  to go back), `KitoCheckoutSummary` (collapsible line items, rolling amounts, struck-through
  waived delivery, free-delivery progress), `KitoCheckoutPromoField` (async check, applied
  chip, shake on error), `KitoCheckoutDeliveryOptions`, `KitoCheckoutAddressList`,
  `KitoCheckoutSlotPicker` (day chips and windows with places left), `KitoCheckoutPaymentPicker`
  (M-Pesa, cards, Apple Pay, Google Pay, cash and wallet as rows or tiles, UI only),
  `KitoCheckoutTipSelector`, `KitoCheckoutPlaceOrderButton` (idle, processing, success and
  failure states), `KitoCheckoutTotalBar`, `KitoCheckoutReceipt` and `KitoCheckoutSuccess`.
  Pure models and maths: `KitoCheckoutTotals` (promo, discounts, free delivery, service fee,
  inclusive or exclusive VAT, tips, whole-unit rounding), `KitoCheckoutPromoValidator`,
  `KitoCheckoutSchedule`, `KitoCheckoutPhone`, `KitoCheckoutOrderNumber` and
  `KitoCheckoutMoney`. Money is whole cents plus a currency code, KES by default.
  Right-to-left, Reduce Motion and screen readers supported throughout.
