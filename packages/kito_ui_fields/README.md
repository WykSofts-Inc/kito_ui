# kito_ui_fields

Form fields that look finished out of the box: one theme drives text, password, phone, one-time
code, currency, card, search, multi-line and stepper fields, in five styles. Validation comes from
[`kito_ui_validation`](../kito_ui_validation) (re-exported), errors appear at the right moment
with a shake, and everything works in right-to-left languages — with phone numbers, codes and card
digits kept left to right, and Arabic or Persian digits understood wherever numbers are typed.

## Install

```yaml
dependencies:
  kito_ui_fields: ^0.1.0
```

```dart
import 'package:kito_ui_fields/kito_ui_fields.dart';
```

## Quick start

```dart
KitoTextField(
  label: 'Email',
  placeholder: 'you@example.com',
  leadingIcon: Icons.mail_outline_rounded,
  keyboardType: TextInputType.emailAddress,
  autofillHints: const [AutofillHints.email],
  rules: [KitoValidationRule.required(), KitoValidationRule.email()],
);
```

Errors show once the user leaves the field (`trigger: KitoValidationTrigger.onBlur`, the default),
live as they type, only after submit, or never. Pass `error:` to show your own (a server reply).

## Styles

```dart
KitoFieldThemeScope(
  theme: const KitoFieldTheme(style: KitoFieldStyle.floatingLabel, showsSuccess: true),
  child: SignUpForm(),
);
```

`outlined` (default), `filled`, `underlined`, `floatingLabel` and `plain`. Colours come from
`KitoTheme`; any field takes a `tint`.

## Password

```dart
KitoPasswordField(
  isNewPassword: true,                         // autofill suggests a strong one
  showsStrength: true,                         // segments that fill and recolour
  requirements: KitoValidationRule.strongPassword(),  // a checklist that ticks off
);
```

## Phone number

```dart
KitoPhoneField(
  initialCountry: KitoFieldCountries.kenya,
  favoriteCountries: const ['KE', 'UG', 'TZ', 'RW'],
  onChanged: (phone) => print(phone.e164),     // +254712345678
);
```

The number is formatted for the region as it's typed ("0712 345 678"), a pasted or autofilled
"+256 772 123456" switches to Uganda by itself, and the picker searches 243 regions by name, ISO or
dial code. `KitoFieldPhoneNumber.parse` and `.format(KitoFieldPhoneFormat.international)` work
on their own too.

## One-time code

```dart
KitoCodeField(
  length: 6,
  groups: const [3, 3],
  onCompleted: (code) => verify(code),
  error: wrongCode ? 'That code is wrong' : null,   // boxes turn red and shake
  showsSuccess: verified,                           // green boxes and a pulse
);
KitoCodeResendButton(onResend: sendCode, cooldown: const Duration(seconds: 30));
```

One hidden text field sits under the boxes, so typing, paste and SMS autofill (`oneTimeCode`) all
just work, and screen readers see a single labelled field.

## Money, cards and numbers

```dart
KitoCurrencyField(currencySymbol: 'KSh', max: 150000, onChanged: (amount) => ...);

KitoCardNumberField(onBrandChanged: (brand) => setState(() => this.brand = brand));
KitoCardExpiryField();
KitoCardCvvField(brand: brand);                // 4 digits for American Express

KitoStepperField(label: 'Guests', value: guests, min: 1, max: 12,
    onChanged: (v) => setState(() => guests = v.toInt()));
```

## Search and multi-line

```dart
KitoFieldSearchBar(placeholder: 'Search products', onSearch: results.load);
KitoTextArea(label: 'Bio', maxLength: 280);    // "12/280", amber near the limit
```

## Forms

Every field registers with a surrounding Flutter `Form`, so `validate()`, `save()` and `reset()`
work as usual. Or share state with a `KitoFormController`:

```dart
final form = KitoFormController()
  ..register('email', rules: [KitoValidationRule.required(), KitoValidationRule.email()]);

KitoTextField(label: 'Email', field: form['email']);
if (await form.submitAsync()) api.signUp(form.values);
```

## Masks and formatters

```dart
TextField(inputFormatters: [const KitoFieldMask('AAA ###A').formatter]);   // KCB 123X
TextField(inputFormatters: [KitoFieldAmountFormatter(decimals: 2)]);       // 12,005.75
TextField(inputFormatters: [KitoFieldDigitsFormatter(digitsOnly: true)]);  // ٣٥٠ → 350
```

Build your own composite field on `KitoFieldShell`, which draws the label, chrome, messages and
motion around any input.

## Accessibility

Fields read their label and their error or helper text; the reveal, clear and country buttons are
labelled with 44-point targets; the stepper offers increase and decrease actions. Text scales with
the system. With Reduce Motion on there's no shake, pulse or blinking caret.

## License

MIT — see [LICENSE](LICENSE).
