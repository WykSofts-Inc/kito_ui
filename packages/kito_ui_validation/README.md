# kito_ui_validation

Composable validation for Flutter forms: small rules you combine, a password strength score,
debounced async checks ("is this username free?") and form state that knows when to show each
error. It plugs straight into Flutter's `Form` / `TextFormField` and into the Kito fields in
`kito_ui_fields`.

## Install

```yaml
dependencies:
  kito_ui_validation: ^0.1.0
```

```dart
import 'package:kito_ui_validation/kito_ui_validation.dart';
```

## Quick start

```dart
TextFormField(
  validator: [
    KitoValidationRule.required(),
    KitoValidationRule.email(),
  ].formValidator,
);
```

Rules run in order and the first failure wins, so a field showing "This field is required" never
also flashes "Enter a valid email address".

## Rules

`required`, `minLength`, `maxLength`, `exactLength`, `email`, `phone`, `url`, `numeric`,
`alphanumeric`, `pattern`, `numberInRange`, `luhn`, `cardExpiry`, `cvv`, `containsUppercase`,
`containsLowercase`, `containsDigit`, `containsSymbol`, `noWhitespace`, `matches`, `oneOf`,
`notOneOf`, `custom` and `strongPassword()` (one rule per requirement, ready for a checklist).
Every message can be replaced.

Digits typed in other scripts count: `٠٧١٢٣٤٥٦٧٨` passes `phone()`, `١٢٠٠` passes
`numberInRange`. Use `'۱۲۳'.kitoNormalizedDigits` or `.kitoAsciiDigits` yourself when you need it.

## Compose

```dart
final code = KitoValidationRule.exactLength(6) & KitoValidationRule.numeric();
final contact = KitoValidationRule.email() | KitoValidationRule.phone();
final website = KitoValidationRule.url().optional;          // empty is fine
final vat = KitoValidationRule.required().when(() => isBusiness);
final confirm = KitoValidationRule.matches(() => password.text);
final friendly = KitoValidationRule.email().withMessage('That email looks off');
```

## Checklists and summaries

```dart
final rules = KitoValidationRule.strongPassword(minLength: 10);
for (final r in kitoEvaluate(password, rules)) {
  print('${r.passed ? '✓' : '·'} ${r.message}');
}
final everything = kitoValidateAll(password, rules); // every failure, in order
```

## Password strength

```dart
final score = KitoPasswordScore.evaluate(password); // veryWeak … veryStrong
LinearProgressIndicator(value: score.fraction);
Text(score.label);
for (final tip in KitoPasswordScore.suggestions(password)) Text(tip);
```

## Async checks

```dart
final username = KitoAsyncValidator(KitoAsyncValidationRule.available(
  (name) => api.isUsernameFree(name),
  message: 'That username is taken',
));

onChanged: username.validate,  // debounced; a slow earlier answer never wins
// username.status: idle / validating / valid / invalid, username.error
```

## Form state

```dart
final form = KitoFormController(trigger: KitoValidationTrigger.onBlur)
  ..register('email', rules: [KitoValidationRule.required(), KitoValidationRule.email()])
  ..register('username',
      rules: [KitoValidationRule.minLength(3)],
      asyncRule: KitoAsyncValidationRule.available(api.isUsernameFree))
  ..register('password', rules: KitoValidationRule.strongPassword());

final email = form['email'];
TextField(
  controller: email.textController,   // kept in sync with email.value
  focusNode: email.focusNode,         // records blur for the onBlur trigger
  decoration: InputDecoration(errorText: email.error),
);

Future<void> signUp() async {
  if (!await form.submitAsync()) return;   // reveals errors, focuses the first bad field
  final result = await api.signUp(form.values);
  form.setErrors(result.fieldErrors);      // server errors show until the user edits
}
```

`form.isValid`, `form.firstInvalidField`, `form.validCount` and `form.progress` drive "3 of 5
complete" headers and disabled submit buttons. Put `KitoFormScope(controller: form, child: …)`
above the fields so any widget can read it with `KitoFormScope.of(context)`.

Triggers: `live` (from the first edit), `onBlur` (after leaving an edited field), `onSubmit` and
`never` (only errors you set). `trigger.autovalidateMode` gives the matching `AutovalidateMode`
for a plain `Form`.

## License

MIT — see [LICENSE](LICENSE).
