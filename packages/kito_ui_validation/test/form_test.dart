// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_validation/kito_ui_validation.dart';

typedef R = KitoValidationRule;

void main() {
  group('KitoAsyncValidator', () {
    test('debounces and ignores stale answers', () async {
      final calls = <String>[];
      final validator = KitoAsyncValidator(KitoAsyncValidationRule(
        (v) async {
          calls.add(v);
          return v == 'taken' ? 'Taken' : null;
        },
        debounce: const Duration(milliseconds: 40),
      ));
      final first = validator.validate('tak');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = validator.validate('taken');
      expect(validator.status, KitoValidationStatus.validating);
      expect(await second, 'Taken');
      expect(await first, 'Taken');
      expect(calls, ['taken']);
      expect(validator.status, KitoValidationStatus.invalid);
      expect(validator.error, 'Taken');
      expect(await validator.validate('taken'), 'Taken');
      expect(calls, ['taken'], reason: 'an unchanged value is not re-checked');
      await validator.validate('');
      expect(validator.status, KitoValidationStatus.idle);
      validator.dispose();
    });

    test('a slow earlier answer does not overwrite a newer one', () async {
      final gates = <String, Completer<String?>>{};
      final validator = KitoAsyncValidator(KitoAsyncValidationRule(
        (v) => (gates[v] = Completer<String?>()).future,
        debounce: Duration.zero,
      ));
      final first = validator.validate('a');
      final second = validator.validate('b');
      gates['b']!.complete(null);
      await Future<void>.delayed(Duration.zero);
      gates['a']!.complete('bad');
      expect(await first, isNull);
      expect(await second, isNull);
      expect(validator.status, KitoValidationStatus.valid);
      validator.dispose();
    });

    test('available() and thrown errors', () async {
      final taken = KitoAsyncValidator(KitoAsyncValidationRule.available(
          (v) async => v != 'admin',
          message: 'Taken',
          debounce: Duration.zero));
      expect(await taken.validate('admin'), 'Taken');
      expect(await taken.validate('wyk'), isNull);
      final failing = KitoAsyncValidator(KitoAsyncValidationRule(
          (_) => Future<String?>.error(StateError('offline')),
          debounce: Duration.zero));
      expect(await failing.validate('x'), "Couldn't check right now");
      taken.dispose();
      failing.dispose();
    });
  });

  group('KitoFormFieldController', () {
    test('onBlur shows errors only after editing then leaving', () {
      final field = KitoFormFieldController(name: 'email', rules: [
        R.required(),
        R.email(),
      ]);
      expect(field.error, isNull);
      expect(field.currentError, 'This field is required');
      field.didBlur(); // leaving without editing doesn't count
      expect(field.error, isNull);
      field.didChange('a');
      expect(field.error, isNull);
      field.didBlur();
      expect(field.error, 'Enter a valid email address');
      field.didChange('a@b.co');
      expect(field.error, isNull);
      expect(field.isValid, isTrue);
      expect(field.isDirty, isTrue);
      field.dispose();
    });

    test('each trigger', () {
      KitoFormFieldController make(KitoValidationTrigger t) =>
          KitoFormFieldController(
              name: 'x', rules: [R.minLength(3)], trigger: t)
            ..didChange('a');
      expect(make(KitoValidationTrigger.live).error, isNotNull);
      expect(make(KitoValidationTrigger.onSubmit).error, isNull);
      expect(
          (make(KitoValidationTrigger.onSubmit)..didSubmit()).error, isNotNull);
      expect((make(KitoValidationTrigger.never)..didSubmit()).error, isNull);
      expect(KitoValidationTrigger.live.autovalidateMode,
          AutovalidateMode.onUserInteraction);
      expect(KitoValidationTrigger.onBlur.autovalidateMode,
          AutovalidateMode.onUnfocus);
      expect(KitoValidationTrigger.never.autovalidateMode,
          AutovalidateMode.disabled);
    });

    test('external errors show at once and clear on the next edit', () {
      final field = KitoFormFieldController(name: 'x');
      field.externalError = 'Already registered';
      expect(field.error, 'Already registered');
      expect(field.isValid, isFalse);
      field.value = 'programmatic';
      expect(field.error, 'Already registered');
      field.didChange('typed');
      expect(field.error, isNull);
      field.dispose();
    });

    test('textController stays in sync both ways', () {
      final field = KitoFormFieldController(name: 'x', initialValue: 'hi');
      final text = field.textController;
      expect(text.text, 'hi');
      text.text = 'hello';
      expect(field.value, 'hello');
      expect(field.isEdited, isTrue);
      field.value = 'set';
      expect(text.text, 'set');
      field.reset();
      expect(text.text, 'hi');
      expect(field.isEdited, isFalse);
      field.dispose();
    });

    test('async rule runs after sync rules pass', () async {
      final field = KitoFormFieldController(
        name: 'user',
        rules: [R.minLength(3)],
        asyncRule: KitoAsyncValidationRule(
            (v) async => v == 'admin' ? 'Taken' : null,
            debounce: Duration.zero),
        trigger: KitoValidationTrigger.live,
      );
      field.didChange('ad');
      expect(field.error, 'Must be at least 3 characters');
      field.didChange('admin');
      expect(field.status, KitoValidationStatus.validating);
      expect(await field.validateNow(), 'Taken');
      expect(field.error, 'Taken');
      expect(field.status, KitoValidationStatus.invalid);
      field.didChange('wyk');
      expect(await field.validateNow(), isNull);
      expect(field.status, KitoValidationStatus.valid);
      field.dispose();
    });

    test('validator works in a TextFormField', () {
      final field = KitoFormFieldController(name: 'x', rules: [R.required()]);
      expect(field.validator(''), 'This field is required');
      expect(field.validator('ok'), isNull);
      field.externalError = 'Server said no';
      expect(field.validator('ok'), 'Server said no');
      field.dispose();
    });
  });

  group('KitoFormController', () {
    KitoFormController signUp() => KitoFormController()
      ..register('email', rules: [R.required(), R.email()])
      ..register('password', rules: R.strongPassword())
      ..register('nickname');

    test('reports validity, first invalid field and progress', () {
      final form = signUp();
      expect(form.isValid, isFalse);
      expect(form.firstInvalidField, 'email');
      expect(form.validCount, 1);
      expect(form.progress, closeTo(1 / 3, 1e-9));
      form['email'].didChange('a@b.co');
      expect(form.firstInvalidField, 'password');
      form['password'].didChange('Sup3r!pass');
      expect(form.isValid, isTrue);
      expect(form.values,
          {'email': 'a@b.co', 'password': 'Sup3r!pass', 'nickname': ''});
      expect(form.errors, isEmpty);
      form.dispose();
    });

    test('submit reveals every error', () {
      final form = signUp();
      expect(form['email'].error, isNull);
      expect(form.submit(), isFalse);
      expect(form.isSubmitted, isTrue);
      expect(form['email'].error, 'This field is required');
      expect(form.errors.keys, ['email', 'password']);
      form.reset();
      expect(form['email'].error, isNull);
      expect(form.isSubmitted, isFalse);
      form.dispose();
    });

    test('register returns the existing field and [] throws for unknown', () {
      final form = signUp();
      expect(identical(form.register('email'), form['email']), isTrue);
      expect(() => form['missing'], throwsArgumentError);
      expect(form.fields.map((f) => f.name), ['email', 'password', 'nickname']);
      form.dispose();
    });

    test('setErrors shows server errors', () {
      final form = signUp()..setErrors({'email': 'Already registered'});
      expect(form['email'].error, 'Already registered');
      form.dispose();
    });

    test('notifies when a field changes', () {
      final form = signUp();
      var count = 0;
      form.addListener(() => count++);
      form['nickname'].didChange('w');
      expect(count, greaterThan(0));
      expect(form.isDirty, isTrue);
      form.dispose();
    });

    test('submitAsync waits for async rules', () async {
      final form = KitoFormController()
        ..register('user',
            asyncRule: KitoAsyncValidationRule(
                (v) async => v == 'admin' ? 'Taken' : null,
                debounce: const Duration(seconds: 5)));
      form['user'].value = 'admin';
      expect(await form.submitAsync(), isFalse);
      expect(form['user'].error, 'Taken');
      form['user'].value = 'wyk';
      expect(await form.submitAsync(), isTrue);
      form.dispose();
    });
  });

  testWidgets('works with Form, TextFormField and KitoFormScope',
      (tester) async {
    final form = KitoFormController(trigger: KitoValidationTrigger.onSubmit);
    addTearDown(form.dispose);
    final email = form.register('email', rules: [R.required(), R.email()]);
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: KitoFormScope(
          controller: form,
          child: Form(
            key: formKey,
            child: Column(children: [
              TextFormField(
                controller: email.textController,
                focusNode: email.focusNode,
                validator: email.validator,
              ),
              Builder(
                builder: (context) => Text(
                    '${KitoFormScope.of(context).validCount} valid',
                    textDirection: TextDirection.ltr),
              ),
            ]),
          ),
        ),
      ),
    ));
    expect(find.text('0 valid'), findsOneWidget);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('This field is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'a@b.co');
    await tester.pump();
    expect(email.value, 'a@b.co');
    expect(find.text('1 valid'), findsOneWidget);
    expect(formKey.currentState!.validate(), isTrue);

    // submit() moves focus to the first failing field.
    email.value = '';
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(form.submit(), isFalse);
    await tester.pump();
    expect(email.focusNode.hasFocus, isTrue);
  });
}
