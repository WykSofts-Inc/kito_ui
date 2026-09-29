// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_toasts/kito_ui_toasts.dart';

void main() {
  group('KitoToast', () {
    test('toasts with unfinished work stay until dismissed', () {
      expect(KitoToast(message: 'a').duration, const Duration(seconds: 3));
      expect(KitoToast(message: 'a', isLoading: true).duration, isNull);
      expect(KitoToast(message: 'a', progress: 0.2).duration, isNull);
      final action = KitoToastAction(label: 'View', onPressed: () {});
      expect(KitoToast(message: 'a', actions: [action]).duration, isNull);
      expect(
          KitoToast(message: 'a', actions: [action], showsCountdown: true)
              .duration,
          const Duration(seconds: 3));
      expect(
          KitoToast(
                  message: 'a',
                  actions: [action],
                  showsCountdown: true,
                  duration: null)
              .duration,
          const Duration(seconds: 5));
    });

    test('ids are unique, copyWith keeps them, progress is clamped', () {
      final a = KitoToast(message: 'a');
      final b = KitoToast(message: 'b');
      expect(a.id, isNot(b.id));
      final c = a.copyWith(message: 'c', progress: 3);
      expect(c.id, a.id);
      expect(c.message, 'c');
      expect(c.progress, 1);
      expect(c.copyWith(clearProgress: true).progress, isNull);
      expect(KitoToast(message: 'x', progress: -1).progress, 0);
    });

    test('accessibility label joins title and message', () {
      expect(KitoToast(message: 'Saved', title: 'Done').accessibilityLabel,
          'Done. Saved');
      expect(
          KitoToast(message: 'Saved', semanticLabel: 'All saved')
              .accessibilityLabel,
          'All saved');
    });
  });

  group('KitoToastCenter', () {
    testWidgets('single presentation queues and auto-dismisses',
        (tester) async {
      final center = KitoToastCenter();
      final first = center.success('One');
      center.info('Two');
      expect(center.current?.id, first);
      expect(center.queued, hasLength(1));
      await tester.pump(const Duration(seconds: 3));
      expect(center.current?.message, 'Two');
      await tester.pump(const Duration(seconds: 3));
      expect(center.current, isNull);
      center.dispose();
    });

    testWidgets('stack keeps the newest on top and drops past maxVisible',
        (tester) async {
      final center = KitoToastCenter(
          presentation: const KitoToastPresentation.stack(maxVisible: 2));
      center.info('1');
      center.info('2');
      center.info('3');
      expect(center.visible.map((t) => t.message), ['3', '2']);
      center.presentation = const KitoToastPresentation.stack(maxVisible: 1);
      expect(center.visible.map((t) => t.message), ['3']);
      center.dismissAll();
      await tester.pump(const Duration(seconds: 5));
      center.dispose();
    });

    testWidgets('fanning the stack out pauses timers, folding resumes them',
        (tester) async {
      final center =
          KitoToastCenter(presentation: KitoToastPresentation.stacked);
      final a = center.info('a');
      center.info('b');
      await tester.pump(const Duration(seconds: 1));
      center.isStackExpanded = true;
      expect(center.isPaused, isTrue);
      expect(center.remainingFor(a), const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 10));
      expect(center.visible, hasLength(2));
      center.toggleStack();
      expect(center.isPaused, isFalse);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(center.visible, hasLength(2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(center.visible, isEmpty);
      expect(center.isStackExpanded, isFalse);
      center.dispose();
    });

    test('a single toast cannot be expanded', () {
      final center =
          KitoToastCenter(presentation: KitoToastPresentation.stacked)
            ..showMessage('only', duration: null);
      center.isStackExpanded = true;
      expect(center.isStackExpanded, isFalse);
      center.dispose();
    });

    testWidgets('pause calls nest', (tester) async {
      final center = KitoToastCenter()..info('x');
      center.pause();
      center.pause();
      center.resume();
      await tester.pump(const Duration(seconds: 5));
      expect(center.current, isNotNull);
      center.resume();
      center.resume(); // extra resumes are ignored
      await tester.pump(const Duration(seconds: 3));
      expect(center.current, isNull);
      center.dispose();
    });

    testWidgets('progress updates in place, then complete starts the timer',
        (tester) async {
      final center = KitoToastCenter();
      final id = center.show(KitoToast(message: 'Uploading', progress: 0));
      center.updateProgress(id, 0.5);
      expect(center.current?.progress, 0.5);
      expect(center.current?.id, id);
      await tester.pump(const Duration(seconds: 10));
      expect(center.current, isNotNull, reason: 'progress toasts stay');
      center.complete(id, style: KitoToastStyle.success, message: 'Uploaded');
      expect(center.current?.message, 'Uploaded');
      expect(center.current?.progress, isNull);
      expect(center.current?.style, KitoToastStyle.success);
      await tester.pump(const Duration(seconds: 3));
      expect(center.current, isNull);
      expect(center.update('gone', (t) => t), isFalse);
      center.dispose();
    });

    testWidgets('promise shows loading, then success or error', (tester) async {
      final center =
          KitoToastCenter(presentation: KitoToastPresentation.stacked);
      final value = center.promise(Future.value(42),
          loading: 'Saving', success: (v) => 'Saved $v');
      expect(center.current?.isLoading, isTrue);
      expect(await value, 42);
      expect(center.current?.message, 'Saved 42');
      expect(center.current?.isLoading, isFalse);

      await expectLater(
        center.promise<int>(Future.error(StateError('x')),
            loading: 'Saving',
            success: (_) => 'ok',
            error: (e) => 'Failed: offline'),
        throwsStateError,
      );
      expect(center.current?.style, KitoToastStyle.error);
      expect(center.current?.message, 'Failed: offline');
      center.dismissAll();
      center.dispose();
    });

    testWidgets('undo runs onUndo when tapped, onExpire otherwise',
        (tester) async {
      final center = KitoToastCenter();
      var undone = 0;
      var expired = 0;
      center.undo('Deleted', onUndo: () => undone++, onExpire: () => expired++);
      expect(center.current?.showsCountdown, isTrue);
      expect(center.current?.duration, const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(expired, 1);
      expect(undone, 0);

      center.undo('Deleted', onUndo: () => undone++, onExpire: () => expired++);
      center.current!.actions.first.onPressed();
      center.dismissCurrent();
      expect(undone, 1);
      expect(expired, 1);

      center.undo('Deleted', onUndo: () => undone++, onExpire: () => expired++);
      center.dismissCurrent(); // swiped away: commit
      expect(expired, 2);
      center.dispose();
    });

    test('notifies listeners and changes position', () {
      final center = KitoToastCenter();
      var count = 0;
      center.addListener(() => count++);
      center.position = KitoToastPosition.bottom;
      center.showMessage('x', duration: null);
      center.dismiss('nope');
      expect(count, 2);
      expect(center.toastWithId(center.current!.id), isNotNull);
      center.dispose();
    });
  });
}
