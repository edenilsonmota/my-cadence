import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/shared/debounced_saver.dart';

void main() {
  test('várias mudanças seguidas viram um salvamento, 800 ms depois', () {
    fakeAsync((async) {
      var saves = 0;
      final saver = DebouncedSaver(() async => saves++);
      saver.schedule();
      async.elapse(const Duration(milliseconds: 500));
      saver.schedule();
      async.elapse(const Duration(milliseconds: 500));
      saver.schedule();
      expect(saves, 0);
      async.elapse(const Duration(milliseconds: 799));
      expect(saves, 0);
      async.elapse(const Duration(milliseconds: 1));
      expect(saves, 1);
      async.elapse(const Duration(seconds: 5));
      expect(saves, 1);
    });
  });

  test('flush salva na hora e só se houver pendência', () {
    fakeAsync((async) {
      var saves = 0;
      final saver = DebouncedSaver(() async => saves++);
      saver.flush();
      async.flushMicrotasks();
      expect(saves, 0);
      saver.schedule();
      saver.flush();
      async.flushMicrotasks();
      expect(saves, 1);
      async.elapse(const Duration(seconds: 1));
      expect(saves, 1); // o timer foi cancelado
    });
  });
}
