import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/tasks/reschedule.dart';

import 'fixtures.dart';

void main() {
  test('mantém hora e distância do início', () {
    final task = makeTask(
      'a',
      dueAt: DateTime(2026, 11, 20, 16),
      hasTime: true,
    ).copyWith(startAt: Value(DateTime(2026, 11, 19, 14)));
    final r = rescheduleToDay(task, DateTime(2026, 11, 27, 8));
    expect(r.startAt, DateTime(2026, 11, 26, 14));
    expect(r.dueAt, DateTime(2026, 11, 27, 16));
    expect(r.hasTime, isTrue);
  });

  test('sem datas vira dia inteiro no dia escolhido', () {
    final r = rescheduleToDay(makeTask('b'), DateTime(2026, 11, 27, 15));
    expect(
      (r.startAt, r.dueAt, r.hasTime),
      (null, DateTime(2026, 11, 27), false),
    );
  });

  test('só início: anda o início', () {
    final task = makeTask('c').copyWith(startAt: Value(DateTime(2026, 11, 20)));
    final r = rescheduleToDay(task, DateTime(2026, 12, 1));
    expect((r.startAt, r.dueAt), (DateTime(2026, 12, 1), null));
  });

  test('atravessa a troca de mês e ano', () {
    final task = makeTask('d', dueAt: DateTime(2026, 12, 30));
    expect(
      rescheduleToDay(task, DateTime(2027, 1, 2)).dueAt,
      DateTime(2027, 1, 2),
    );
  });
}
