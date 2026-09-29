// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_fields/kito_ui_fields.dart';

import '../catalog/catalog.dart';

typedef _R = KitoValidationRule;

/// The gallery for kito_ui_fields.
final fieldsKit = KitEntry(
  title: 'Fields',
  package: 'kito_ui_fields',
  blurb: 'text, password, phone, OTP, money, card and search fields',
  icon: Icons.text_fields_rounded,
  category: KitCategory.forms,
  isNew: true,
  sections: [
    KitSection('Text', Icons.short_text_rounded, [
      KitSample(
        title: 'Outlined',
        subtitle: 'The default: label above, icon, errors after you leave.',
        code: '''KitoTextField(
  label: 'Email',
  placeholder: 'wycliff@wyksoftsinc.com',
  leadingIcon: Icons.mail_outline_rounded,
  keyboardType: TextInputType.emailAddress,
  rules: [KitoValidationRule.required(), KitoValidationRule.email()],
)''',
        builder: (_) => _Panel(
          child: KitoTextField(
            label: 'Email',
            placeholder: 'wycliff@wyksoftsinc.com',
            leadingIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            rules: [_R.required(), _R.email()],
          ),
        ),
      ),
      KitSample(
        title: 'Filled',
        subtitle: 'A soft fill; the border appears on focus.',
        code: '''KitoTextField(
  label: 'Full name',
  initialValue: 'Wycliff N',
  leadingIcon: Icons.person_outline_rounded,
  style: KitoFieldStyle.filled,
)''',
        builder: (_) => const _Panel(
          child: KitoTextField(
            label: 'Full name',
            initialValue: 'Wycliff N',
            leadingIcon: Icons.person_outline_rounded,
            style: KitoFieldStyle.filled,
          ),
        ),
      ),
      KitSample(
        title: 'Underlined',
        subtitle: 'A single line under the text.',
        code: '''KitoTextField(
  label: 'Town',
  placeholder: 'Kisumu',
  style: KitoFieldStyle.underlined,
)''',
        builder: (_) => const _Panel(
          child: KitoTextField(
            label: 'Town',
            placeholder: 'Kisumu',
            leadingIcon: Icons.location_city_rounded,
            style: KitoFieldStyle.underlined,
          ),
        ),
      ),
      KitSample(
        title: 'Floating label',
        subtitle: 'The label rests inside and lifts when you type.',
        code: '''KitoFieldThemeScope(
  theme: const KitoFieldTheme(style: KitoFieldStyle.floatingLabel),
  child: KitoTextField(label: 'Delivery address', placeholder: 'Ngong Road, Nairobi'),
)''',
        builder: (_) => const _Panel(
          child: KitoFieldThemeScope(
            theme: KitoFieldTheme(style: KitoFieldStyle.floatingLabel),
            child: Column(children: [
              KitoTextField(
                  label: 'Delivery address',
                  placeholder: 'Ngong Road, Nairobi'),
              SizedBox(height: 12),
              KitoTextField(label: 'Apartment', initialValue: 'Block C, 4B'),
            ]),
          ),
        ),
      ),
      KitSample(
        title: 'Clear button and success',
        subtitle: 'A tick once the value passes, and a one-tap clear.',
        code: '''KitoTextField(
  label: 'Till number',
  keyboardType: TextInputType.number,
  showsClearButton: true,
  showsSuccess: true,
  trigger: KitoValidationTrigger.live,
  rules: [KitoValidationRule.numeric(), KitoValidationRule.exactLength(6)],
)''',
        builder: (_) => _Panel(
          child: KitoTextField(
            label: 'Till number',
            initialValue: '5210',
            keyboardType: TextInputType.number,
            showsClearButton: true,
            showsSuccess: true,
            trigger: KitoValidationTrigger.live,
            rules: [_R.numeric(), _R.exactLength(6)],
          ),
        ),
      ),
      KitSample(
        title: 'Helper, required and errors',
        subtitle: 'A shake and a message when something’s wrong.',
        code: '''KitoTextField(
  label: 'M-Pesa name',
  isRequired: true,
  helper: 'As it appears on your M-Pesa statement',
  error: serverError,   // 'Name doesn’t match the number'
)''',
        builder: (_) => const _ServerError(),
      ),
      KitSample(
        title: 'Username with a live check',
        subtitle: 'An async rule shows a spinner while it asks the server.',
        code: '''KitoTextField(
  label: 'Username',
  prefixText: '@',
  trigger: KitoValidationTrigger.live,
  rules: [KitoValidationRule.minLength(3)],
  asyncRule: KitoAsyncValidationRule.available(api.isUsernameFree,
      message: 'That username is taken'),
)''',
        builder: (_) => _Panel(
          child: KitoTextField(
            label: 'Username',
            prefixText: '@',
            placeholder: 'wycliffn',
            showsSuccess: true,
            trigger: KitoValidationTrigger.live,
            rules: [_R.minLength(3), _R.alphanumeric()],
            asyncRule: KitoAsyncValidationRule.available(
              (name) async {
                await Future<void>.delayed(const Duration(milliseconds: 700));
                return !const {'amina', 'baraka', 'wycliff'}
                    .contains(name.toLowerCase());
              },
              message: 'That username is taken',
            ),
          ),
        ),
      ),
    ]),
    KitSection('Password', Icons.lock_rounded, [
      KitSample(
        title: 'Reveal and strength',
        subtitle: 'Show or hide, and a meter that fills as it gets stronger.',
        code: '''KitoPasswordField(isNewPassword: true, showsStrength: true)''',
        builder: (_) => const _Panel(
          child: KitoPasswordField(isNewPassword: true, showsStrength: true),
        ),
      ),
      KitSample(
        title: 'Requirements checklist',
        subtitle: 'Each rule ticks off as the password meets it.',
        code: '''KitoPasswordField(
  isNewPassword: true,
  showsStrength: true,
  meterStyle: KitoPasswordMeterStyle.bar,
  requirements: KitoValidationRule.strongPassword(minLength: 10),
)''',
        builder: (_) => _Panel(
          child: KitoPasswordField(
            isNewPassword: true,
            showsStrength: true,
            meterStyle: KitoPasswordMeterStyle.bar,
            requirements: _R.strongPassword(minLength: 10),
          ),
        ),
      ),
      KitSample(
        title: 'Strength meters',
        subtitle: 'Segments, a bar, or just the label.',
        code: '''KitoPasswordStrengthMeter(
  score: KitoPasswordScore.evaluate(password),
  style: KitoPasswordMeterStyle.segments,
)''',
        builder: (_) => const _Meters(),
      ),
    ]),
    KitSection('Phone', Icons.phone_rounded, [
      KitSample(
        title: 'Kenyan number',
        subtitle: 'Formatted as you type; you get E.164 back.',
        code: '''KitoPhoneField(
  initialCountry: KitoFieldCountries.kenya,
  onChanged: (phone) => setState(() => e164 = phone.e164),
)''',
        builder: (_) => const _KenyaPhone(),
      ),
      KitSample(
        title: 'East African favourites',
        subtitle: 'Pin your markets to the top of the country picker.',
        code: '''KitoPhoneField(
  initialCountry: KitoFieldCountries.byIsoCode('UG'),
  favoriteCountries: const ['KE', 'UG', 'TZ', 'RW', 'BI', 'SS', 'ET'],
)''',
        builder: (_) => _Panel(
          child: KitoPhoneField(
            initialCountry: KitoFieldCountries.byIsoCode('UG'),
            favoriteCountries: const ['KE', 'UG', 'TZ', 'RW', 'BI', 'SS', 'ET'],
          ),
        ),
      ),
      KitSample(
        title: 'International input',
        subtitle: 'A “+255…” number picks Tanzania by itself.',
        code: '''KitoPhoneField(initialValue: '+255 754 123 456');
KitoFieldPhoneNumber.parse('+255 754 123 456')!.country.englishName; // Tanzania''',
        builder: (_) => const _Panel(
          child: KitoPhoneField(initialValue: '+255 754 123 456'),
        ),
      ),
    ]),
    KitSection('Codes', Icons.pin_rounded, [
      KitSample(
        title: 'One-time code',
        subtitle: 'Paste or SMS autofill fills every box; try 482915.',
        code: '''KitoCodeField(
  length: 6,
  groups: const [3, 3],
  error: wrong ? 'That code is wrong' : null,
  showsSuccess: verified,
  onCompleted: verify,
)
KitoCodeResendButton(onResend: sendCode, cooldown: const Duration(seconds: 30))''',
        builder: (_) => const _Otp(),
      ),
      KitSample(
        title: 'PIN',
        subtitle: 'Four hidden digits, filled boxes.',
        code: '''KitoCodeField(
  length: 4,
  obscureText: true,
  boxStyle: KitoCodeBoxStyle.filled,
)''',
        builder: (_) => const KitoCodeField(
          length: 4,
          obscureText: true,
          boxStyle: KitoCodeBoxStyle.filled,
          semanticLabel: 'M-Pesa PIN',
        ),
      ),
      KitSample(
        title: 'Voucher code',
        subtitle: 'Letters and digits, uppercased, in two groups.',
        code: '''KitoCodeField(
  length: 8,
  alphanumeric: true,
  groups: const [4, 4],
  boxStyle: KitoCodeBoxStyle.underline,
)''',
        builder: (_) => const KitoCodeField(
          length: 8,
          alphanumeric: true,
          groups: [4, 4],
          boxStyle: KitoCodeBoxStyle.underline,
          semanticLabel: 'Voucher code',
        ),
      ),
    ]),
    KitSection('Money and numbers', Icons.payments_rounded, [
      KitSample(
        title: 'Amount in shillings',
        subtitle: 'Groups thousands as you type; limits built in.',
        code: '''KitoCurrencyField(
  label: 'Send money',
  currencySymbol: 'KSh',
  min: 10,
  max: 150000,
  onChanged: (amount) => setState(() => this.amount = amount),
)''',
        builder: (_) => const _Amount(),
      ),
      KitSample(
        title: 'Steppers',
        subtitle: 'Hold to repeat; screen readers can increase and decrease.',
        code:
            '''KitoStepperField(label: 'Guests', value: guests, min: 1, max: 8,
    onChanged: (v) => setState(() => guests = v.toInt()));
KitoStepperField(label: 'Nights in Diani', value: nights, max: 14, unit: 'nights', ...);''',
        builder: (_) => const _Steppers(),
      ),
      KitSample(
        title: 'Card details',
        subtitle: 'Brand detection, grouping, Luhn, expiry and CVV.',
        code:
            '''KitoCardNumberField(onBrandChanged: (b) => setState(() => brand = b));
Row(children: [
  Expanded(child: KitoCardExpiryField()),
  const SizedBox(width: 12),
  Expanded(child: KitoCardCvvField(brand: brand)),
]);''',
        builder: (_) => const _Card(),
      ),
    ]),
    KitSection('Search and text', Icons.search_rounded, [
      KitSample(
        title: 'Search bar',
        subtitle: 'Debounced search with clear and Cancel.',
        code: '''KitoFieldSearchBar(
  placeholder: 'Search neighbourhoods',
  onSearch: (query) => setState(() => this.query = query),
)''',
        builder: (_) => const _Search(),
      ),
      KitSample(
        title: 'Review',
        subtitle:
            'Grows with the text; the counter turns amber near the limit.',
        code: '''KitoTextArea(
  label: 'Your review',
  placeholder: 'How was your stay in Lamu?',
  maxLength: 200,
)''',
        builder: (_) => const _Panel(
          child: KitoTextArea(
            label: 'Your review',
            placeholder: 'How was your stay in Lamu?',
            maxLength: 200,
          ),
        ),
      ),
    ]),
    KitSection('Masks and theme', Icons.tune_rounded, [
      KitSample(
        title: 'Number plate mask',
        subtitle: 'KitoFieldMask on any TextField: # digit, A letter.',
        code:
            '''TextField(inputFormatters: [const KitoFieldMask('AAA ###A').formatter]);
// typing "kda123b" shows "KDA 123B"''',
        builder: (_) => const _Plate(),
      ),
      KitSample(
        title: 'One theme for a whole form',
        subtitle: 'Switch every field’s style at once.',
        code: '''KitoFieldThemeScope(
  theme: KitoFieldTheme(style: style, showsSuccess: true),
  child: CheckoutForm(),
)''',
        builder: (_) => const _ThemeSwitch(),
      ),
    ]),
  ],
);

// MARK: Pieces

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(width: double.infinity, child: child),
      );
}

class _Readout extends StatelessWidget {
  const _Readout(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        Text(label,
            style: t.typography.caption
                .copyWith(color: t.colors.onSurface.withValues(alpha: 0.55))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              textDirection: TextDirection.ltr,
              textAlign: context.isRtl ? TextAlign.left : TextAlign.right,
              style: t.typography.label.copyWith(
                  color: t.colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ]),
    );
  }
}

class _ServerError extends StatefulWidget {
  const _ServerError();

  @override
  State<_ServerError> createState() => _ServerErrorState();
}

class _ServerErrorState extends State<_ServerError> {
  String? _error;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitoTextField(
              label: 'M-Pesa name',
              initialValue: 'Wycliff N',
              isRequired: true,
              helper: 'As it appears on your M-Pesa statement',
              error: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _error =
                  _error == null ? 'Name doesn’t match 0712 345 678' : null),
              child:
                  Text(_error == null ? 'Check with Safaricom' : 'Clear error'),
            ),
          ],
        ),
      );
}

class _Meters extends StatelessWidget {
  const _Meters();

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(children: [
          for (final (style, score) in const [
            (KitoPasswordMeterStyle.segments, KitoPasswordScore.medium),
            (KitoPasswordMeterStyle.bar, KitoPasswordScore.strong),
            (KitoPasswordMeterStyle.label, KitoPasswordScore.veryStrong),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: KitoPasswordStrengthMeter(score: score, style: style),
            ),
        ]),
      );
}

class _KenyaPhone extends StatefulWidget {
  const _KenyaPhone();

  @override
  State<_KenyaPhone> createState() => _KenyaPhoneState();
}

class _KenyaPhoneState extends State<_KenyaPhone> {
  KitoFieldPhoneNumber? _phone;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(children: [
          KitoPhoneField(
            initialCountry: KitoFieldCountries.kenya,
            initialValue: '0712 345 678',
            onChanged: (p) => setState(() => _phone = p),
          ),
          _Readout('E.164', _phone?.e164 ?? '+254712345678'),
          _Readout(
              'International',
              _phone?.format(KitoFieldPhoneFormat.international) ??
                  '+254 712 345 678'),
        ]),
      );
}

class _Otp extends StatefulWidget {
  const _Otp();

  @override
  State<_Otp> createState() => _OtpState();
}

class _OtpState extends State<_Otp> {
  String? _error;
  bool _verified = false;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return _Panel(
      child: Column(children: [
        Text('Enter the code sent to +254 712 345 678',
            textAlign: TextAlign.center,
            style: t.typography.label
                .copyWith(color: t.colors.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 14),
        KitoCodeField(
          length: 6,
          groups: const [3, 3],
          error: _error,
          showsSuccess: _verified,
          onChanged: (_) {
            if (_error != null || _verified) {
              setState(() {
                _error = null;
                _verified = false;
              });
            }
          },
          onCompleted: (code) => setState(() {
            _verified = code == '482915';
            _error = _verified ? null : 'That code is wrong. Try 482915.';
          }),
        ),
        const SizedBox(height: 6),
        KitoCodeResendButton(
            onResend: () {}, cooldown: const Duration(seconds: 30)),
      ]),
    );
  }
}

class _Amount extends StatefulWidget {
  const _Amount();

  @override
  State<_Amount> createState() => _AmountState();
}

class _AmountState extends State<_Amount> {
  double? _amount = 2500;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(children: [
          KitoCurrencyField(
            label: 'Send money',
            currencySymbol: 'KSh',
            initialValue: 2500,
            min: 10,
            max: 150000,
            trigger: KitoValidationTrigger.live,
            onChanged: (v) => setState(() => _amount = v),
          ),
          _Readout(
              'Transaction fee',
              _amount == null
                  ? '—'
                  : 'KSh ${(_amount! * 0.01).clamp(0, 108).toStringAsFixed(0)}'),
        ]),
      );
}

class _Steppers extends StatefulWidget {
  const _Steppers();

  @override
  State<_Steppers> createState() => _SteppersState();
}

class _SteppersState extends State<_Steppers> {
  int _guests = 2;
  int _nights = 3;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(children: [
          KitoStepperField(
              label: 'Guests',
              value: _guests,
              min: 1,
              max: 8,
              onChanged: (v) => setState(() => _guests = v.toInt())),
          const SizedBox(height: 8),
          KitoStepperField(
              label: 'Nights in Diani',
              value: _nights,
              min: 1,
              max: 14,
              onChanged: (v) => setState(() => _nights = v.toInt())),
        ]),
      );
}

class _Card extends StatefulWidget {
  const _Card();

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  KitoFieldCardBrand _brand = KitoFieldCardBrand.unknown;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(children: [
          KitoCardNumberField(
              onBrandChanged: (b) => setState(() => _brand = b)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: KitoCardExpiryField()),
              const SizedBox(width: 12),
              Expanded(child: KitoCardCvvField(brand: _brand)),
            ],
          ),
        ]),
      );
}

class _Search extends StatefulWidget {
  const _Search();

  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  static const _places = [
    'Westlands',
    'Kilimani',
    'Karen',
    'Lavington',
    'Kileleshwa',
    'Parklands',
    'South B',
    'Runda',
    'Eastleigh',
    'Gigiri',
  ];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    final hits = _places
        .where((p) => p.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitoFieldSearchBar(
            placeholder: 'Search neighbourhoods',
            onSearch: (q) => setState(() => _query = q),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in hits)
                Chip(
                  label: Text(p),
                  backgroundColor: t.colors.surfaceMuted,
                  side: BorderSide.none,
                ),
              if (hits.isEmpty)
                Text('No neighbourhood matches “$_query”',
                    style: t.typography.caption.copyWith(
                        color: t.colors.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Plate extends StatefulWidget {
  const _Plate();

  @override
  State<_Plate> createState() => _PlateState();
}

class _PlateState extends State<_Plate> {
  static const _mask = KitoFieldMask('AAA ###A');
  String _text = 'KDA 123B';

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return _Panel(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Text(_text.isEmpty ? '— — —' : _text,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.black)),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: _text,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [_mask.formatter],
          textDirection: TextDirection.ltr,
          onChanged: (v) => setState(() => _text = v),
          decoration: InputDecoration(
            labelText: 'Number plate',
            helperText: _mask.isComplete(_text) ? 'Complete' : 'e.g. KDA 123B',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radii.md)),
          ),
        ),
      ]),
    );
  }
}

class _ThemeSwitch extends StatefulWidget {
  const _ThemeSwitch();

  @override
  State<_ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<_ThemeSwitch> {
  KitoFieldStyle _style = KitoFieldStyle.floatingLabel;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in KitoFieldStyle.values)
                  ChoiceChip(
                    label: Text(s.name),
                    selected: s == _style,
                    onSelected: (_) => setState(() => _style = s),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            KitoFieldThemeScope(
              theme: KitoFieldTheme(style: _style, showsSuccess: true),
              child: Column(children: [
                const KitoTextField(
                    label: 'Name on order', initialValue: 'Wycliff N'),
                const SizedBox(height: 12),
                KitoTextField(
                  label: 'Pickup point',
                  placeholder: 'Sarit Centre, Westlands',
                  leadingIcon: Icons.storefront_rounded,
                  rules: [_R.required()],
                ),
              ]),
            ),
          ],
        ),
      );
}
