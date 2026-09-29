// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_core/kito_ui_core.dart';
import 'package:kito_ui_fields/kito_ui_fields.dart';

typedef R = KitoValidationRule;

Widget host(Widget child,
        {bool reduceMotion = false,
        TextDirection direction = TextDirection.ltr,
        KitoFieldTheme? fieldTheme,
        KitoTheme theme = KitoTheme.light}) =>
    MaterialApp(
      theme: theme.toThemeData(),
      home: MediaQuery(
        data: MediaQueryData(
            disableAnimations: reduceMotion, size: const Size(400, 800)),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: fieldTheme == null
                  ? child
                  : KitoFieldThemeScope(theme: fieldTheme, child: child),
            ),
          ),
        ),
      ),
    );

Future<void> blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  group('KitoTextField', () {
    testWidgets('onBlur shows the error after leaving, live clears it',
        (tester) async {
      await tester.pumpWidget(host(Column(children: [
        const KitoTextField(
          label: 'Email',
          placeholder: 'you@example.com',
          rules: [],
        ),
        KitoTextField(
          label: 'Work email',
          rules: [R.required(), R.email()],
        ),
      ])));
      final field = find.byType(TextField).last;
      await tester.enterText(field, 'wyk');
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsNothing);
      await blur(tester);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      await tester.enterText(field, 'wyk@ke.co');
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsNothing);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('an error shakes the field; reduce motion does not',
        (tester) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(host(
            KitoTextField(
                label: 'Name',
                rules: [R.required()],
                trigger: KitoValidationTrigger.live),
            reduceMotion: reduce));
        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump();
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final translate = tester
            .widgetList<Transform>(find.ancestor(
                of: find.byType(TextField), matching: find.byType(Transform)))
            .map((t) => t.transform.getTranslation().x.abs())
            .fold<double>(0, (a, b) => a > b ? a : b);
        if (reduce) {
          expect(translate, 0);
        } else {
          expect(translate, greaterThan(0.5));
        }
        await tester.pumpAndSettle();
        expect(find.text('This field is required'), findsOneWidget);
      }
    });

    testWidgets('works inside a Flutter Form: validate, save and reset',
        (tester) async {
      final key = GlobalKey<FormState>();
      String? saved;
      await tester.pumpWidget(host(Form(
        key: key,
        child: KitoTextField(
          label: 'Username',
          initialValue: 'wy',
          rules: [R.minLength(3)],
          trigger: KitoValidationTrigger.onSubmit,
          onSaved: (v) => saved = v,
        ),
      )));
      expect(find.text('Must be at least 3 characters'), findsNothing);
      expect(key.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Must be at least 3 characters'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'wyk');
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), isTrue);
      key.currentState!.save();
      expect(saved, 'wyk');
      key.currentState!.reset();
      await tester.pumpAndSettle();
      expect(find.text('wy'), findsOneWidget);
    });

    testWidgets('shares state with a KitoFormController', (tester) async {
      final form = KitoFormController(trigger: KitoValidationTrigger.live);
      addTearDown(form.dispose);
      final email = form.register('email', rules: [R.required(), R.email()]);
      await tester
          .pumpWidget(host(KitoTextField(label: 'Email', field: email)));
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pumpAndSettle();
      expect(email.value, 'x');
      expect(find.text('Enter a valid email address'), findsOneWidget);
      form.setErrors({'email': 'Already registered'});
      await tester.pumpAndSettle();
      expect(find.text('Already registered'), findsOneWidget);
    });

    testWidgets('async rule shows a spinner then its result', (tester) async {
      await tester.pumpWidget(host(KitoTextField(
        label: 'Username',
        trigger: KitoValidationTrigger.live,
        asyncRule: KitoAsyncValidationRule(
            (v) async => v == 'admin' ? 'Taken' : null,
            debounce: const Duration(milliseconds: 100)),
      )));
      await tester.enterText(find.byType(TextField), 'admin');
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Taken'), findsOneWidget);
    });

    testWidgets('success tick, clear button and counter', (tester) async {
      await tester.pumpWidget(host(Column(children: [
        KitoTextField(
          label: 'Code',
          rules: [R.exactLength(3)],
          showsSuccess: true,
          showsClearButton: true,
          trigger: KitoValidationTrigger.live,
        ),
        const KitoTextArea(label: 'Bio', maxLength: 10),
      ])));
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('abc'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      await tester.enterText(find.byType(TextField).last, 'Hello world, again');
      await tester.pumpAndSettle();
      expect(find.text('10/10'), findsOneWidget);
      expect(find.text('Hello worl'), findsOneWidget);
    });

    testWidgets('floating label lifts on focus', (tester) async {
      await tester.pumpWidget(host(
        const KitoTextField(label: 'City', placeholder: 'Nairobi'),
        fieldTheme: const KitoFieldTheme(style: KitoFieldStyle.floatingLabel),
      ));
      final restY = tester.getTopLeft(find.text('City')).dy;
      expect(find.text('Nairobi'), findsNothing,
          reason: 'the label stands in for the placeholder at rest');
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('City')).dy, lessThan(restY));
    });

    testWidgets('every style renders, light and dark, and RTL', (tester) async {
      for (final theme in [KitoTheme.light, KitoTheme.dark]) {
        for (final style in KitoFieldStyle.values) {
          await tester.pumpWidget(host(
            KitoTextField(
              label: 'Label',
              placeholder: 'Placeholder',
              helper: 'Helper',
              leadingIcon: Icons.person_rounded,
              style: style,
            ),
            theme: theme,
            direction: TextDirection.rtl,
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$style');
          final icon = tester.getCenter(find.byIcon(Icons.person_rounded)).dx;
          final input = tester.getCenter(find.byType(TextField)).dx;
          expect(icon, greaterThan(input),
              reason: 'leading is on the right in RTL');
        }
      }
    });

    testWidgets('semantics carry the label and the error', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(
          const KitoTextField(label: 'Email', error: 'Already registered')));
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.byType(TextField));
      expect(node.label, contains('Email'));
      expect(node.hint, contains('Already registered'));
      handle.dispose();
    });

    testWidgets('normalises Arabic digits as they are typed', (tester) async {
      String? value;
      await tester.pumpWidget(
          host(KitoTextField(label: 'Amount', onChanged: (v) => value = v)));
      await tester.enterText(find.byType(TextField), '٣٥٠');
      await tester.pump();
      expect(value, '350');
    });
  });

  group('KitoPasswordField', () {
    testWidgets('reveal toggle, strength meter and checklist', (tester) async {
      await tester.pumpWidget(host(KitoPasswordField(
        showsStrength: true,
        requirements: R.strongPassword(),
      )));
      TextField input() => tester.widget<TextField>(find.byType(TextField));
      expect(input().obscureText, isTrue);
      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pump();
      expect(input().obscureText, isFalse);
      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);

      expect(find.byType(KitoPasswordStrengthMeter), findsNothing);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();
      expect(find.text('Very weak'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget,
          reason: 'only "one lowercase" is met');
      await tester.enterText(find.byType(TextField), 'Sup3r!secret');
      await tester.pumpAndSettle();
      expect(find.text('Very strong'), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
      final autofill = input().autofillHints;
      expect(autofill, [AutofillHints.password]);
    });

    testWidgets('meter styles', (tester) async {
      for (final style in KitoPasswordMeterStyle.values) {
        await tester.pumpWidget(host(KitoPasswordStrengthMeter(
            score: KitoPasswordScore.strong, style: style)));
        await tester.pumpAndSettle();
        expect(find.text('Strong'), findsOneWidget);
      }
    });
  });

  group('KitoPhoneField', () {
    testWidgets('formats for Kenya and reports E.164', (tester) async {
      KitoFieldPhoneNumber? last;
      await tester.pumpWidget(host(KitoPhoneField(
        initialCountry: KitoFieldCountries.kenya,
        onChanged: (p) => last = p,
      )));
      expect(find.text('🇰🇪'), findsOneWidget);
      expect(find.text('+254'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '0712345678');
      await tester.pump();
      expect(find.text('0712 345 678'), findsOneWidget);
      expect(last!.e164, '+254712345678');
      expect(last!.isValid, isTrue);
    });

    testWidgets('a pasted international number switches the country',
        (tester) async {
      KitoFieldCountry? changed;
      await tester.pumpWidget(host(KitoPhoneField(
        initialCountry: KitoFieldCountries.kenya,
        onCountryChanged: (c) => changed = c,
      )));
      await tester.enterText(find.byType(TextField), '+256 772 123456');
      await tester.pump();
      expect(changed?.isoCode, 'UG');
      expect(find.text('🇺🇬'), findsOneWidget);
      expect(find.text('772 123456'), findsOneWidget);
    });

    testWidgets('invalid length shows an error on blur', (tester) async {
      await tester.pumpWidget(
          host(KitoPhoneField(initialCountry: KitoFieldCountries.kenya)));
      await tester.enterText(find.byType(TextField), '7123');
      await blur(tester);
      expect(find.text('Enter a valid phone number'), findsOneWidget);
    });

    testWidgets('the picker searches and selects', (tester) async {
      await tester.pumpWidget(host(KitoPhoneField(
        initialCountry: KitoFieldCountries.kenya,
        favoriteCountries: const ['KE', 'TZ'],
      )));
      await tester.tap(find.bySemanticsLabel(RegExp('^Country: Kenya')));
      await tester.pumpAndSettle();
      expect(find.text('Country or region'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'rwa');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rwanda'));
      await tester.pumpAndSettle();
      expect(find.text('🇷🇼'), findsOneWidget);
      expect(find.text('+250'), findsOneWidget);
    });

    testWidgets('digits stay left to right in RTL', (tester) async {
      await tester.pumpWidget(host(
          KitoPhoneField(initialCountry: KitoFieldCountries.kenya),
          direction: TextDirection.rtl));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.ltr);
      expect(field.textAlign, TextAlign.right);
    });
  });

  group('KitoCodeField', () {
    testWidgets('fills boxes, completes once, and stays LTR in RTL',
        (tester) async {
      final completed = <String>[];
      await tester.pumpWidget(host(
          KitoCodeField(length: 4, onCompleted: completed.add),
          direction: TextDirection.rtl));
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(tester.getCenter(find.text('1')).dx,
          lessThan(tester.getCenter(find.text('2')).dx));
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      expect(completed, ['1234']);
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      expect(completed, ['1234'], reason: 'capped, no second completion');
    });

    testWidgets('paste and autofill replace the code, Arabic digits convert',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(KitoCodeField(controller: controller)));
      await tester.enterText(find.byType(TextField), 'Code: ٤٨٢٩١٥');
      await tester.pump();
      expect(controller.text, '482915');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, [AutofillHints.oneTimeCode]);
    });

    testWidgets('obscured, grouped, error and success', (tester) async {
      await tester.pumpWidget(host(
          const KitoCodeField(length: 6, obscureText: true, groups: [3, 3])));
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('●'), findsNWidgets(3));
      expect(find.text('1'), findsNothing);

      await tester.pumpWidget(
          host(const KitoCodeField(length: 6, error: 'That code is wrong')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('That code is wrong'), findsOneWidget);
      await tester
          .pumpWidget(host(const KitoCodeField(length: 6, showsSuccess: true)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('screen readers get one labelled text field', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const KitoCodeField()));
      expect(find.bySemanticsLabel('Verification code'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('resend counts down, then sends', (tester) async {
      var sent = 0;
      await tester.pumpWidget(host(KitoCodeResendButton(
          onResend: () => sent++, cooldown: const Duration(seconds: 3))));
      expect(find.text('Resend in 0:03'), findsOneWidget);
      await tester.tap(find.text('Resend in 0:03'));
      expect(sent, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Resend code'), findsOneWidget);
      await tester.tap(find.text('Resend code'));
      await tester.pump();
      expect(sent, 1);
      expect(find.text('Resend in 0:03'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('money, cards, search and steppers', () {
    testWidgets('currency groups as typed and enforces limits', (tester) async {
      double? amount;
      await tester.pumpWidget(host(KitoCurrencyField(
        currencySymbol: 'KSh',
        max: 1000,
        trigger: KitoValidationTrigger.live,
        onChanged: (v) => amount = v,
      )));
      expect(find.text('KSh'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '1250.5');
      await tester.pumpAndSettle();
      expect(amount, 1250.5);
      expect(find.text('The maximum is 1,000'), findsOneWidget);
    });

    testWidgets('card number detects the brand and checks Luhn',
        (tester) async {
      final brands = <KitoFieldCardBrand>[];
      await tester.pumpWidget(host(Column(children: [
        KitoCardNumberField(
            onBrandChanged: brands.add, trigger: KitoValidationTrigger.live),
        KitoCardExpiryField(
            now: () => DateTime(2026, 9, 29),
            trigger: KitoValidationTrigger.live),
        const KitoCardCvvField(brand: KitoFieldCardBrand.amex),
      ])));
      await tester.enterText(find.byType(TextField).first, '4242424242424242');
      await tester.pumpAndSettle();
      expect(find.text('4242 4242 4242 4242'), findsOneWidget);
      expect(brands, [KitoFieldCardBrand.visa]);
      expect(find.text('VISA'), findsOneWidget);
      expect(find.text('Check the card number'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '4242424242424241');
      await tester.pumpAndSettle();
      expect(find.text('Check the card number'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), '0825');
      await tester.pumpAndSettle();
      expect(find.text('08/25'), findsOneWidget);
      expect(find.text('Check the expiry date'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pump();
      expect(
          tester
              .widget<TextField>(find.byType(TextField).last)
              .controller!
              .text,
          '1234');
    });

    testWidgets('search debounces and clears', (tester) async {
      final searches = <String>[];
      await tester.pumpWidget(host(KitoFieldSearchBar(
          onSearch: searches.add,
          debounce: const Duration(milliseconds: 200))));
      await tester.enterText(find.byType(TextField), 'ke');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'kenya');
      await tester.pump(const Duration(milliseconds: 250));
      expect(searches, ['kenya']);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear search'));
      await tester.pumpAndSettle();
      expect(searches, ['kenya', '']);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.context?.widget,
          isNot(isA<EditableText>()));
    });

    testWidgets('stepper steps within limits, with a11y actions',
        (tester) async {
      final handle = tester.ensureSemantics();
      var value = 1;
      await tester.pumpWidget(StatefulBuilder(
        builder: (context, setState) => host(KitoStepperField(
          label: 'Guests',
          value: value,
          min: 1,
          max: 3,
          onChanged: (v) => setState(() => value = v.toInt()),
        )),
      ));
      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(value, 1, reason: 'already at the minimum');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(value, 2);
      expect(find.text('2'), findsOneWidget);
      final node = tester.getSemantics(find.text('2'));
      expect(node.value, '2');
      tester.binding.renderViews.first.owner!.semanticsOwner!
          .performAction(node.id, SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(value, 3);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(value, 3, reason: 'capped at the maximum');
      handle.dispose();
    });
  });
}
