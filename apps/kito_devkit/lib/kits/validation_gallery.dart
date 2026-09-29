// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

import '../catalog/catalog.dart';

typedef _R = KitoValidationRule;

/// The gallery for kito_ui_validation.
final validationKit = KitEntry(
  title: 'Validation',
  package: 'kito_ui_validation',
  blurb: 'rules, password scores, async checks and form state',
  icon: Icons.verified_rounded,
  category: KitCategory.forms,
  isNew: true,
  sections: [
    KitSection('Rules', Icons.rule_rounded, [
      KitSample(
        title: 'Required and email',
        subtitle: 'Plain TextFormField; the first failure wins.',
        code: '''TextFormField(
  autovalidateMode: AutovalidateMode.onUserInteraction,
  validator: [
    KitoValidationRule.required(),
    KitoValidationRule.email(),
  ].formValidator,
);''',
        builder: (_) => _RuleField(
          label: 'Email',
          hint: 'wycliff@wyksoftsinc.com',
          rules: [_R.required(), _R.email()],
        ),
      ),
      KitSample(
        title: 'Length',
        subtitle: 'Minimum, maximum and exact; emoji count as one character.',
        code: '''final rules = [
  KitoValidationRule.minLength(3),
  KitoValidationRule.maxLength(12),
];
kitoValidate('Wy', rules); // 'Must be at least 3 characters\'''',
        builder: (_) => _Checklist(
          label: 'Display name',
          initial: 'Wy',
          rules: [_R.minLength(3), _R.maxLength(12), _R.noWhitespace()],
        ),
      ),
      KitSample(
        title: 'Phone numbers',
        subtitle: '9–15 digits; Arabic and Persian digits count too.',
        code: '''KitoValidationRule.phone().validate('0712 345 678');  // null
KitoValidationRule.phone().validate('٠٧١٢٣٤٥٦٧٨');     // null''',
        builder: (_) => _Examples(
          rule: _R.phone(),
          inputs: const [
            '0712 345 678',
            '+256 772 123456',
            '٠٧١٢٣٤٥٦٧٨',
            '07123'
          ],
        ),
      ),
      KitSample(
        title: 'Web address',
        subtitle: 'http or https with a dotted host; optional when empty.',
        code: '''KitoValidationRule.url().optional''',
        builder: (_) => _RuleField(
          label: 'Website (optional)',
          hint: 'https://safarirally.co.ke',
          rules: [_R.url().optional],
        ),
      ),
      KitSample(
        title: 'Numbers in range',
        subtitle: 'Understands 1,200.50 and ١٢٠٠.',
        code: '''KitoValidationRule.numberInRange(10, 150000,
    message: 'Send between KSh 10 and KSh 150,000')''',
        builder: (_) => _RuleField(
          label: 'Amount (KSh)',
          hint: '2,500',
          keyboardType: TextInputType.number,
          rules: [
            _R.required(),
            _R.numberInRange(10, 150000,
                message: 'Send between KSh 10 and KSh 150,000'),
          ],
        ),
      ),
      KitSample(
        title: 'Card checks',
        subtitle: 'Luhn checksum, expiry that hasn’t passed, and CVV.',
        code:
            '''KitoValidationRule.luhn().validate('4242 4242 4242 4242'); // null
KitoValidationRule.cardExpiry().validate('08/24');            // 'Check the expiry date'
KitoValidationRule.cvv().validate('12');                      // 'Check the security code\'''',
        builder: (_) => const _CardChecks(),
      ),
      KitSample(
        title: 'Allow and block lists',
        subtitle: 'Reserved usernames and live promo codes, ignoring case.',
        code: '''KitoValidationRule.notOneOf(['admin', 'mpesa', 'support'],
    message: 'That username is reserved');
KitoValidationRule.oneOf(['KARIBU10', 'JAMBO25'],
    message: 'That code isn’t active');''',
        builder: (_) => Column(children: [
          _RuleField(
            label: 'Username',
            hint: 'wycliffn',
            rules: [
              _R.required(),
              _R.notOneOf(const ['admin', 'mpesa', 'support'],
                  message: 'That username is reserved'),
            ],
          ),
          const SizedBox(height: 12),
          _RuleField(
            label: 'Promo code',
            hint: 'KARIBU10',
            rules: [
              _R.oneOf(const ['KARIBU10', 'JAMBO25'],
                  message: 'That code isn’t active')
            ],
          ),
        ]),
      ),
    ]),
    KitSection('Compose', Icons.merge_type_rounded, [
      KitSample(
        title: 'First failure wins',
        subtitle: 'Rules run in order, so only one message shows at a time.',
        code: '''final error = kitoValidate(value, [
  KitoValidationRule.required(),
  KitoValidationRule.minLength(3),
  KitoValidationRule.alphanumeric(),
]);''',
        builder: (_) => _RuleField(
          label: 'Username',
          hint: 'wycliffn',
          rules: [_R.required(), _R.minLength(3), _R.alphanumeric()],
        ),
      ),
      KitSample(
        title: 'Either or',
        subtitle: 'An email or a phone number: combine rules with |.',
        code:
            '''final contact = KitoValidationRule.email() | KitoValidationRule.phone();
contact.withMessage('Enter an email or a phone number');''',
        builder: (_) => _RuleField(
          label: 'Email or phone',
          hint: 'wycliff@… or 0712 345 678',
          rules: [
            (_R.email() | _R.phone())
                .withMessage('Enter an email or a phone number')
          ],
        ),
      ),
      KitSample(
        title: 'Conditional rules',
        subtitle: 'A KRA PIN is required only for business accounts.',
        code: '''KitoValidationRule.required(message: 'Enter your KRA PIN')
    .when(() => isBusiness) &
KitoValidationRule.pattern(RegExp(r'^[AP]\\d{9}[A-Z]\$'),
    message: 'A KRA PIN looks like A123456789Z').optional''',
        builder: (_) => const _Conditional(),
      ),
      KitSample(
        title: 'Confirm password',
        subtitle: 'matches() reads the other value each time it runs.',
        code: '''TextFormField(validator: [
  KitoValidationRule.required(),
  KitoValidationRule.matches(() => password.text,
      message: 'Passwords don’t match'),
].formValidator);''',
        builder: (_) => const _Confirm(),
      ),
    ]),
    KitSection('Passwords', Icons.password_rounded, [
      KitSample(
        title: 'Strength score',
        subtitle: 'Very weak to very strong, with what would help.',
        code: '''final score = KitoPasswordScore.evaluate(password);
LinearProgressIndicator(value: score.fraction);
Text(score.label);
KitoPasswordScore.suggestions(password); // ['Add a number', …]''',
        builder: (_) => const _Strength(),
      ),
      KitSample(
        title: 'Requirements checklist',
        subtitle: 'Every rule’s result at once, from kitoEvaluate.',
        code: '''for (final r in kitoEvaluate(password,
    KitoValidationRule.strongPassword(minLength: 10)))
  Row(children: [Icon(r.passed ? Icons.check : Icons.close), Text(r.message)]);''',
        builder: (_) => _Checklist(
          label: 'New password',
          initial: 'nairobi',
          obscure: true,
          rules: _R.strongPassword(minLength: 10),
        ),
      ),
      KitSample(
        title: 'Common passwords',
        subtitle: 'Well-known passwords always score very weak.',
        code: '''KitoPasswordScore.evaluate('P@ssw0rd'); // veryWeak
KitoPasswordScore.evaluate('Twiga-Kilimanjaro-7'); // veryStrong''',
        builder: (_) => const _CommonPasswords(),
      ),
    ]),
    KitSection('Async', Icons.cloud_sync_rounded, [
      KitSample(
        title: 'Username availability',
        subtitle: 'Debounced, and a slow earlier answer never wins.',
        code:
            '''final username = KitoAsyncValidator(KitoAsyncValidationRule.available(
  (name) => api.isUsernameFree(name),
  message: 'That username is taken',
));
TextField(onChanged: username.validate);''',
        builder: (_) => const _Availability(),
      ),
      KitSample(
        title: 'Promo code on the server',
        subtitle: 'Any async check that returns an error message or null.',
        code: '''KitoAsyncValidationRule((code) async {
  final promo = await api.promo(code);
  return promo.active ? null : 'That code expired on \${promo.endDate}';
})''',
        builder: (_) => const _Promo(),
      ),
    ]),
    KitSection('Form state', Icons.fact_check_rounded, [
      KitSample(
        title: 'Sign-up form',
        subtitle: 'Progress, submit that focuses the first bad field, values.',
        code: '''final form = KitoFormController()
  ..register('name', rules: [KitoValidationRule.required()])
  ..register('email', rules: [KitoValidationRule.required(), KitoValidationRule.email()])
  ..register('phone', rules: [KitoValidationRule.phone()])
  ..register('password', rules: KitoValidationRule.strongPassword());

Text('\${form.validCount} of \${form.fields.length} complete');
if (form.submit()) api.signUp(form.values);''',
        builder: (_) => const _SignUp(),
      ),
      KitSample(
        title: 'When errors appear',
        subtitle: 'Live, after leaving the field, after submit, or never.',
        code: '''final field = KitoFormFieldController(
  name: 'email',
  rules: [KitoValidationRule.email()],
  trigger: KitoValidationTrigger.onBlur,
);''',
        builder: (_) => const _Triggers(),
      ),
      KitSample(
        title: 'Server errors',
        subtitle: 'Show what the API said until the user edits the field.',
        code: '''final result = await api.signUp(form.values);
form.setErrors(result.fieldErrors); // {'email': 'Already registered'}''',
        builder: (_) => const _ServerErrors(),
      ),
      KitSample(
        title: 'Flutter Form',
        subtitle:
            'Form.validate() with rules and a matching autovalidate mode.',
        code: '''Form(
  key: formKey,
  autovalidateMode: KitoValidationTrigger.onBlur.autovalidateMode,
  child: TextFormField(validator: rules.formValidator),
);
formKey.currentState!.validate();''',
        builder: (_) => const _FlutterForm(),
      ),
    ]),
    KitSection('Digits', Icons.translate_rounded, [
      KitSample(
        title: 'Digits in any script',
        subtitle: 'Arabic-Indic, Persian and Devanagari digits become ASCII.',
        code: ''''٠٧١٢٣٤٥٦٧٨'.kitoNormalizedDigits; // '0712345678'
'+254 (712) 345'.kitoAsciiDigits;   // '254712345'
kitoParseNumber('١٬٢٠٠٫٥');           // 1200.5''',
        builder: (_) => const _Digits(),
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

InputDecoration _decoration(BuildContext context, String label, String? hint) {
  final t = context.kito;
  OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radii.md),
      borderSide: BorderSide(color: c));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: t.colors.surface,
    border: border(t.colors.border),
    enabledBorder: border(t.colors.border),
    focusedBorder: border(t.colors.primary),
    errorBorder: border(t.colors.danger),
    focusedErrorBorder: border(t.colors.danger),
  );
}

class _Verdict extends StatelessWidget {
  const _Verdict(this.error, {this.empty = false});
  final String? error;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    final ok = error == null;
    final color = empty
        ? t.colors.onSurface.withValues(alpha: 0.4)
        : ok
            ? t.colors.success
            : t.colors.danger;
    return AnimatedSwitcher(
      duration: KitoMotion.of(context, t.motion.fast),
      child: Row(
        key: ValueKey('$empty$error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              empty
                  ? Icons.radio_button_unchecked_rounded
                  : ok
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
              size: 16,
              color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(empty ? 'Waiting for input' : (error ?? 'Looks good'),
                style: t.typography.caption.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _RuleField extends StatelessWidget {
  const _RuleField({
    required this.label,
    required this.rules,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final String? hint;
  final List<KitoValidationRule> rules;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => _Panel(
        child: TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: keyboardType,
          decoration: _decoration(context, label, hint),
          validator: rules.formValidator,
        ),
      );
}

class _Checklist extends StatefulWidget {
  const _Checklist({
    required this.label,
    required this.rules,
    this.initial = '',
    this.obscure = false,
  });

  final String label;
  final List<KitoValidationRule> rules;
  final String initial;
  final bool obscure;

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            obscureText: widget.obscure,
            decoration: _decoration(context, widget.label, null),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          for (final r in kitoEvaluate(_controller.text, widget.rules))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: KitoMotion.of(context, t.motion.medium),
                  transitionBuilder: (c, a) => ScaleTransition(
                      scale: CurvedAnimation(parent: a, curve: t.motion.spring),
                      child: c),
                  child: Icon(
                    r.passed
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    key: ValueKey(r.passed),
                    size: 18,
                    color: r.passed ? t.colors.success : t.colors.danger,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(r.message,
                      style: t.typography.label
                          .copyWith(color: t.colors.onSurface)),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Examples extends StatelessWidget {
  const _Examples({required this.rule, required this.inputs});
  final KitoValidationRule rule;
  final List<String> inputs;

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return _Panel(
      child: Column(
        children: [
          for (final input in inputs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(input,
                        textAlign:
                            context.isRtl ? TextAlign.right : TextAlign.left,
                        style: t.typography.bodyEmphasized
                            .copyWith(color: t.colors.onSurface)),
                  ),
                ),
                Flexible(child: _Verdict(rule.validate(input))),
              ]),
            ),
        ],
      ),
    );
  }
}

class _CardChecks extends StatelessWidget {
  const _CardChecks();

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    final rows = <(String, String, KitoValidationRule)>[
      ('Card', '4242 4242 4242 4242', _R.luhn()),
      ('Card', '4242 4242 4242 4241', _R.luhn()),
      ('Expiry', '12/29', _R.cardExpiry()),
      ('Expiry', '08/24', _R.cardExpiry()),
      ('CVV', '123', _R.cvv()),
      ('CVV', '12', _R.cvv()),
    ];
    return _Panel(
      child: Column(children: [
        for (final (kind, input, rule) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(
                width: 60,
                child: Text(kind,
                    style: t.typography.caption.copyWith(
                        color: t.colors.onSurface.withValues(alpha: 0.6))),
              ),
              Expanded(
                child: Text(input,
                    textDirection: TextDirection.ltr,
                    style: t.typography.label.copyWith(
                        color: t.colors.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              Flexible(child: _Verdict(rule.validate(input))),
            ]),
          ),
      ]),
    );
  }
}

class _Conditional extends StatefulWidget {
  const _Conditional();

  @override
  State<_Conditional> createState() => _ConditionalState();
}

class _ConditionalState extends State<_Conditional> {
  bool _business = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final rules = [
      _R.required(message: 'Enter your KRA PIN').when(() => _business),
      _R
          .pattern(RegExp(r'^[AP]\d{9}[A-Z]$'),
              message: 'A KRA PIN looks like A123456789Z')
          .optional,
    ];
    return _Panel(
      child: Form(
        key: _formKey,
        child: Column(children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Business account'),
            value: _business,
            onChanged: (v) {
              setState(() => _business = v);
              _formKey.currentState!.validate();
            },
          ),
          TextFormField(
            textCapitalization: TextCapitalization.characters,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _decoration(context, 'KRA PIN', 'A123456789Z'),
            validator: rules.formValidator,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: () => _formKey.currentState!.validate(),
              child: const Text('Continue'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Confirm extends StatefulWidget {
  const _Confirm();

  @override
  State<_Confirm> createState() => _ConfirmState();
}

class _ConfirmState extends State<_Confirm> {
  final _password = TextEditingController(text: 'Twiga-2026!');

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(children: [
          TextField(
            controller: _password,
            obscureText: true,
            decoration: _decoration(context, 'Password', null),
          ),
          const SizedBox(height: 12),
          TextFormField(
            obscureText: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _decoration(context, 'Confirm password', null),
            validator: [
              _R.required(),
              _R.matches(() => _password.text,
                  message: 'Passwords don’t match'),
            ].formValidator,
          ),
        ]),
      );
}

class _Strength extends StatefulWidget {
  const _Strength();

  @override
  State<_Strength> createState() => _StrengthState();
}

class _StrengthState extends State<_Strength> {
  String _value = 'safari';

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    final score = KitoPasswordScore.evaluate(_value);
    final color = [
      t.colors.danger,
      Color.lerp(t.colors.danger, t.colors.warning, 0.5)!,
      t.colors.warning,
      Color.lerp(t.colors.warning, t.colors.success, 0.6)!,
      t.colors.success,
    ][score.index];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: _value,
            decoration: _decoration(context, 'Password', null),
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: score.fraction),
              duration: KitoMotion.of(context, t.motion.medium),
              curve: t.motion.spring,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v.clamp(0, 1),
                minHeight: 6,
                color: color,
                backgroundColor: t.colors.surfaceMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(score.label,
              style: t.typography.label
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final tip in KitoPasswordScore.suggestions(_value))
            Text('• $tip',
                style: t.typography.caption.copyWith(
                    color: t.colors.onSurface.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _CommonPasswords extends StatelessWidget {
  const _CommonPasswords();

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    const examples = [
      'password',
      'P@ssw0rd',
      '123456',
      'Nairobi2026',
      'Twiga-Kilimanjaro-7'
    ];
    return _Panel(
      child: Column(children: [
        for (final p in examples)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(
                child: Text(p,
                    textDirection: TextDirection.ltr,
                    textAlign: context.isRtl ? TextAlign.right : TextAlign.left,
                    style: t.typography.bodyEmphasized
                        .copyWith(color: t.colors.onSurface)),
              ),
              Text(KitoPasswordScore.evaluate(p).label,
                  style: t.typography.caption.copyWith(
                      color: KitoPasswordScore.evaluate(p) >=
                              KitoPasswordScore.strong
                          ? t.colors.success
                          : t.colors.danger,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }
}

/// A pretend API: a short delay, then an answer.
Future<bool> _isUsernameFree(String name) async {
  await Future<void>.delayed(const Duration(milliseconds: 700));
  return !const {'wycliff', 'wycliffn', 'amina', 'admin', 'baraka'}
      .contains(name.toLowerCase());
}

class _Availability extends StatefulWidget {
  const _Availability();

  @override
  State<_Availability> createState() => _AvailabilityState();
}

class _AvailabilityState extends State<_Availability> {
  final _validator = KitoAsyncValidator(KitoAsyncValidationRule.available(
      _isUsernameFree,
      message: 'That username is taken'));

  @override
  void dispose() {
    _validator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return _Panel(
      child: ListenableBuilder(
        listenable: _validator,
        builder: (context, _) {
          final status = _validator.status;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration:
                    _decoration(context, 'Username', 'wycliffn').copyWith(
                  suffixIcon: switch (status) {
                    KitoValidationStatus.validating => const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    KitoValidationStatus.valid =>
                      Icon(Icons.check_circle_rounded, color: t.colors.success),
                    KitoValidationStatus.invalid =>
                      Icon(Icons.cancel_rounded, color: t.colors.danger),
                    KitoValidationStatus.idle => null,
                  },
                ),
                onChanged: _validator.validate,
              ),
              const SizedBox(height: 8),
              Text(
                switch (status) {
                  KitoValidationStatus.idle =>
                    'Try “amina” or “baraka” — both taken.',
                  KitoValidationStatus.validating => 'Checking…',
                  KitoValidationStatus.valid => 'It’s yours.',
                  KitoValidationStatus.invalid => _validator.error!,
                },
                style: t.typography.caption.copyWith(
                    color: status == KitoValidationStatus.invalid
                        ? t.colors.danger
                        : t.colors.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Promo extends StatefulWidget {
  const _Promo();

  @override
  State<_Promo> createState() => _PromoState();
}

class _PromoState extends State<_Promo> {
  final _validator = KitoAsyncValidator(KitoAsyncValidationRule((code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return switch (code.toUpperCase()) {
      'KARIBU10' => null,
      'MADARAKA' => 'That code expired on 1 June',
      _ => 'We don’t recognise that code',
    };
  }, debounce: const Duration(milliseconds: 500)));

  @override
  void dispose() {
    _validator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Panel(
        child: ListenableBuilder(
          listenable: _validator,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                textCapitalization: TextCapitalization.characters,
                decoration: _decoration(context, 'Promo code', 'KARIBU10'),
                onChanged: _validator.validate,
              ),
              const SizedBox(height: 8),
              _Verdict(_validator.error,
                  empty: _validator.status == KitoValidationStatus.idle ||
                      _validator.isValidating),
            ],
          ),
        ),
      );
}

class _SignUp extends StatefulWidget {
  const _SignUp();

  @override
  State<_SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<_SignUp> {
  final _form = KitoFormController()
    ..register('name', initialValue: 'Wycliff N', rules: [_R.required()])
    ..register('email', rules: [_R.required(), _R.email()])
    ..register('phone', rules: [_R.required(), _R.phone()])
    ..register('password', rules: _R.strongPassword());
  String? _result;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    return _Panel(
      child: KitoFormScope(
        controller: _form,
        child: ListenableBuilder(
          listenable: _form,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${_form.validCount} of ${_form.fields.length} complete',
                  style:
                      t.typography.label.copyWith(color: t.colors.onSurface)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                  value: _form.progress,
                  minHeight: 4,
                  backgroundColor: t.colors.surfaceMuted),
              const SizedBox(height: 14),
              for (final (name, label, obscure) in const [
                ('name', 'Full name', false),
                ('email', 'Email', false),
                ('phone', 'Phone', false),
                ('password', 'Password', true),
              ]) ...[
                TextField(
                  controller: _form[name].textController,
                  focusNode: _form[name].focusNode,
                  obscureText: obscure,
                  decoration: _decoration(context, label, null)
                      .copyWith(errorText: _form[name].error),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                onPressed: () => setState(() => _result = _form.submit()
                    ? 'Karibu, ${_form.values['name']}!'
                    : 'Fix ${_form.firstInvalidField} first'),
                child: const Text('Create account'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 8),
                Text(_result!,
                    textAlign: TextAlign.center,
                    style: t.typography.caption.copyWith(
                        color: _form.isValid
                            ? t.colors.success
                            : t.colors.danger)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Triggers extends StatefulWidget {
  const _Triggers();

  @override
  State<_Triggers> createState() => _TriggersState();
}

class _TriggersState extends State<_Triggers> {
  KitoValidationTrigger _trigger = KitoValidationTrigger.onBlur;
  late KitoFormFieldController _field = _make();

  KitoFormFieldController _make() => KitoFormFieldController(
      name: 'email', rules: [_R.required(), _R.email()], trigger: _trigger);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<KitoValidationTrigger>(
              showSelectedIcon: false,
              segments: [
                for (final t in KitoValidationTrigger.values)
                  ButtonSegment(value: t, label: Text(t.name)),
              ],
              selected: {_trigger},
              onSelectionChanged: (s) => setState(() {
                _trigger = s.first;
                final old = _field;
                _field = _make();
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => old.dispose());
              }),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              key: ObjectKey(_field),
              listenable: _field,
              builder: (context, _) => TextField(
                controller: _field.textController,
                focusNode: _field.focusNode,
                decoration: _decoration(context, 'Email', 'amina@example.co.ke')
                    .copyWith(errorText: _field.error),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: () => _field.didSubmit(),
                child: const Text('Submit')),
          ],
        ),
      );
}

class _ServerErrors extends StatefulWidget {
  const _ServerErrors();

  @override
  State<_ServerErrors> createState() => _ServerErrorsState();
}

class _ServerErrorsState extends State<_ServerErrors> {
  final _form = KitoFormController()
    ..register('email',
        initialValue: 'wycliff@wyksoftsinc.com',
        rules: [_R.required(), _R.email()]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _form['email'];
    return _Panel(
      child: ListenableBuilder(
        listenable: email,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: email.textController,
              decoration: _decoration(context, 'Email', null)
                  .copyWith(errorText: email.error),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () => _form.setErrors(
                  {'email': 'An account with this email already exists'}),
              child: const Text('Sign up (server says no)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlutterForm extends StatefulWidget {
  const _FlutterForm();

  @override
  State<_FlutterForm> createState() => _FlutterFormState();
}

class _FlutterFormState extends State<_FlutterForm> {
  final _key = GlobalKey<FormState>();
  String? _saved;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Form(
          key: _key,
          autovalidateMode: KitoValidationTrigger.onBlur.autovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: _decoration(context, 'County', 'Nairobi'),
                validator: [_R.required(), _R.minLength(3)].formValidator,
                onSaved: (v) => _saved = v,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: _decoration(context, 'Postal code', '00100'),
                keyboardType: TextInputType.number,
                validator: [_R.required(), _R.numeric(), _R.exactLength(5)]
                    .formValidator,
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () {
                  if (_key.currentState!.validate()) {
                    _key.currentState!.save();
                    setState(() {});
                  }
                },
                child: const Text('Save address'),
              ),
              if (_saved != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Saved: $_saved', textAlign: TextAlign.center)),
            ],
          ),
        ),
      );
}

class _Digits extends StatelessWidget {
  const _Digits();

  @override
  Widget build(BuildContext context) {
    final t = context.kito;
    const inputs = ['٠٧١٢٣٤٥٦٧٨', '۰۷۱۲۳۴۵۶۷۸', '०७१२३४५६७८', '１２３４'];
    return _Panel(
      child: Column(children: [
        for (final input in inputs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(
                  child: Text(input,
                      textDirection: TextDirection.ltr,
                      style: t.typography.bodyEmphasized
                          .copyWith(color: t.colors.onSurface))),
              Icon(
                  context.isRtl
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  size: 16,
                  color: t.colors.onSurface.withValues(alpha: 0.4)),
              Expanded(
                  child: Text(input.kitoNormalizedDigits,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.end,
                      style: t.typography.bodyEmphasized.copyWith(
                          color: t.colors.success,
                          fontFeatures: const [FontFeature.tabularFigures()]))),
            ]),
          ),
      ]),
    );
  }
}
