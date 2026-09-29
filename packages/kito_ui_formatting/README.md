# kito_ui_formatting

Formatting for real apps — money (KES and more, compact and signed), numbers, percents, dates,
durations, file sizes, distances and Kenyan phone numbers — plus rolling and counting numbers
and change badges. The Flutter edition of KitoFormatting, built on `intl`.

Two kinds of output:

- **Fixed** (`KitoMoneyFormatting.string`, `KitoNumberFormatting.grouped`, `compact`) —
  "KES 1,250.50" on every device, so receipts, carts and screenshots don't change with the
  phone's region.
- **Localised** (`localized…`, `percent`, `decimal`, dates) — follow a `locale` you pass, or
  intl's current locale.

## Install

```yaml
dependencies:
  kito_ui_formatting: ^0.1.0
```

```dart
import 'package:kito_ui_formatting/kito_ui_formatting.dart';
```

For dates in languages other than English, initialise intl's date data once (apps using
`flutter_localizations` already do):

```dart
import 'package:intl/date_symbol_data_local.dart';
await initializeDateFormatting();
```

## Money

```dart
1250.kitoAmount(KitoCurrency.kes);                                        // KES 1,250
1250.5.kitoAmount(KitoCurrency.kes, display: KitoCurrencyDisplay.symbol); // KSh 1,250.50
KitoMoneyFormatting.string(1250, KitoCurrency.kes, cents: KitoMoneyCents.always); // KES 1,250.00
1200000.kitoCompactAmount(KitoCurrency.kes);                              // KES 1.2M
KitoMoneyFormatting.signed(-1200, KitoCurrency.kes);                      // −KES 1,200

KitoMoneyFormatting.localized(1250.5, KitoCurrency.eur, locale: 'de');    // 1.250,50 €
KitoMoneyFormatting.localizedCode(1250, 'JPY', locale: 'en');             // ¥1,250
```

`KitoCurrency` covers KES, USD, EUR, GBP, NGN, ZAR, UGX and TZS with symbols, flags and minor
units. Amounts round half up on their decimal form, so `1.005` becomes `1.01`.

## Numbers

```dart
KitoNumberFormatting.compact(47200);                      // 47.2K
KitoNumberFormatting.grouped(1250.5, fractionDigits: 2);  // 1,250.50
KitoNumberFormatting.percent(0.847, fractionDigits: 1);   // 84.7%
KitoNumberFormatting.signedPercent(0.124);                // +12.4%
KitoNumberFormatting.ordinal(22);                         // 22nd
```

## Dates

```dart
KitoDateFormatting.relative(order.placedAt);        // 2 minutes ago · yesterday · in 3 hours
KitoDateFormatting.abbreviated(message.sentAt);     // now · 5m · 3h · 2d · Sep 21
KitoDateFormatting.dayLabel(transaction.date);      // Today · Yesterday · Monday
KitoDateFormatting.timeRange(slot.start, slot.end); // 9:00 – 10:30 AM
KitoDateFormatting.greeting();                      // Good morning
KitoDateFormatting.shortTime(eta);                  // 4:32 PM
KitoDateFormatting.mediumDate(invoice.date);        // Sep 21, 2026
```

Every function takes `locale:` (and `now:` where it compares against the present, for previews
and tests). Relative words ship in English, Swahili and French.

## Durations, sizes, distances

```dart
KitoDurationFormatting.short(const Duration(seconds: 3900));      // 1h 5m
KitoDurationFormatting.clock(const Duration(seconds: 245));       // 4:05
KitoDurationFormatting.spelledOut(const Duration(seconds: 3900)); // 1 hour, 5 minutes
KitoFileSizeFormatting.string(1200000);                           // 1.2 MB
KitoFileSizeFormatting.progress(1200000, 4500000);                // 1.2 MB of 4.5 MB
KitoDistanceFormatting.string(1240);                              // 1.2 km
KitoDistanceFormatting.string(805, system: KitoDistanceSystem.imperial); // 0.5 mi
```

## Kenyan phone numbers

```dart
final phone = KitoKenyanPhoneNumber.tryParse('0712 345 678')!;
phone.e164;            // +254712345678
phone.international;   // +254 712 345 678
phone.local;           // 0712 345 678
phone.masked;          // +254 7•• ••• 678
phone.carrier;         // KitoKenyanCarrier.safaricom (best effort; numbers can be ported)
phone.carrier.walletName; // M-Pesa
phone.callUri;         // tel:+254712345678

KitoPhoneFormatting.kenyanAsYouType('071234');     // 0712 34

TextField(
  keyboardType: TextInputType.phone,
  inputFormatters: [KitoKenyanPhoneInputFormatter()],
);
```

## Widgets

```dart
// Digits roll to the new value — only the ones that changed move.
KitoFormattedNumberText(
  balance,
  format: (v) => KitoMoneyFormatting.string(v, KitoCurrency.kes),
  style: Theme.of(context).textTheme.headlineMedium,
);

// Counts up like a scoreboard (from 0 on first appearance).
KitoFormattedCountingText(12480);

// "+12.4%" in green with an up arrow; "−3.1%" in red; grey when flat.
KitoFormattedChangeBadge(0.124);
KitoFormattedChangeBadge(-0.08, invertColors: true);   // spending went down: good
KitoFormattedChangeBadge(0.05, style: KitoFormattedChangeBadgeStyle.solid);
```

Both number widgets use tabular figures, read as one value to screen readers and skip the
animation under Reduce Motion. The badge's arrows mirror in RTL and its label is localised
("Up +12.4%").

## Localisation

```dart
KitoFormattingStrings.provider = (key, language) => myStrings.lookup('kito.$key', language);
```

## License

MIT — see [LICENSE](LICENSE).
