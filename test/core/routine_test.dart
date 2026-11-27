import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/notification_id.dart';
import 'package:my_cadence/core/recurrence.dart';
import 'package:my_cadence/core/routine.dart';

final daily = RecurrenceRule(frequency: Frequency.daily);
final monWedFri = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');

void main() {
  group('notificationIdFor', () {
    test('FNV-1a reduzido a 31 bits, estável', () {
      // Vetores conhecidos do FNV-1a 32 bits, com o bit de sinal zerado.
      expect(notificationIdFor(''), 0x811c9dc5 & 0x7FFFFFFF);
      expect(notificationIdFor('a'), 0xe40c292c & 0x7FFFFFFF);
      expect(notificationIdFor('foobar'), 0xbf9cf968 & 0x7FFFFFFF);
    });

    test('sempre positivo e diferente para UUIDs diferentes', () {
      final a = notificationIdFor('019a0000-0000-7000-8000-000000000001');
      final b = notificationIdFor('019a0000-0000-7000-8000-000000000002');
      expect(a, isNot(b));
      expect(a, inInclusiveRange(0, 0x7FFFFFFF));
      expect(notificationIdFor('019a0000-0000-7000-8000-000000000001'), a);
    });
  });

  group('advanceRoutine', () {
    test(
      'concluir a de hoje com hora vai para amanhã, mesmo antes da hora',
      () {
        final r = advanceRoutine(
          rule: daily,
          dueAt: DateTime(2026, 11, 23, 18),
          hasTime: true,
          now: DateTime(2026, 11, 23, 10),
        );
        expect(r.occurrence, DateTime(2026, 11, 23, 18));
        expect(r.nextDue, DateTime(2026, 11, 24, 18));
        expect(r.finished, isFalse);
      },
    );

    test('atrasada com hora pula as que já passaram', () {
      final r = advanceRoutine(
        rule: daily,
        dueAt: DateTime(2026, 11, 20, 9),
        hasTime: true,
        now: DateTime(2026, 11, 23, 10),
      );
      expect(r.nextDue, DateTime(2026, 11, 24, 9));
    });

    test('atrasada de dia inteiro para na de hoje', () {
      final r = advanceRoutine(
        rule: daily,
        dueAt: DateTime(2026, 11, 20),
        hasTime: false,
        now: DateTime(2026, 11, 23, 22),
      );
      expect(r.nextDue, DateTime(2026, 11, 23));
    });

    test('início acompanha o prazo', () {
      final r = advanceRoutine(
        rule: monWedFri,
        dueAt: DateTime(2026, 11, 23, 8),
        startAt: DateTime(2026, 11, 23, 7, 30),
        hasTime: true,
        now: DateTime(2026, 11, 23, 8, 5),
      );
      expect(r.nextDue, DateTime(2026, 11, 25, 8));
      expect(r.nextStart, DateTime(2026, 11, 25, 7, 30));
    });

    test('depois do UNTIL a série termina', () {
      final r = advanceRoutine(
        rule: RecurrenceRule.parse('FREQ=DAILY;UNTIL=20261123'),
        dueAt: DateTime(2026, 11, 23),
        hasTime: false,
        now: DateTime(2026, 11, 23, 9),
      );
      expect(r.finished, isTrue);
      expect(r.nextStart, isNull);
    });
  });

  group('routineStreak', () {
    final now = DateTime(2026, 11, 23, 12); // segunda

    test('sem conclusões é zero', () {
      expect(routineStreak(daily, const [], now), 0);
    });

    test('conta dias seguidos até hoje', () {
      final days = [for (var d = 19; d <= 23; d++) DateTime(2026, 11, d, 7)];
      expect(routineStreak(daily, days, now), 5);
    });

    test('a de hoje ainda pendente não quebra a sequência', () {
      final days = [for (var d = 20; d <= 22; d++) DateTime(2026, 11, d)];
      expect(routineStreak(daily, days, now), 3);
    });

    test('um dia perdido no meio reinicia a contagem', () {
      final days = [
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 19),
        DateTime(2026, 11, 21),
        DateTime(2026, 11, 22),
      ];
      expect(routineStreak(daily, days, now), 2);
    });

    test('um dia perdido depois da última zera', () {
      final days = [DateTime(2026, 11, 20), DateTime(2026, 11, 21)];
      expect(routineStreak(daily, days, now), 0);
    });

    test('semanal conta ocorrências, não dias corridos', () {
      final days = [
        DateTime(2026, 11, 16), // seg
        DateTime(2026, 11, 18), // qua
        DateTime(2026, 11, 20), // sex
        DateTime(2026, 11, 23), // seg
      ];
      expect(routineStreak(monWedFri, days, now), 4);
    });
  });

  group('rolloverMissedRoutine', () {
    test('retorna null se prazo já é hoje ou futuro', () {
      expect(
        rolloverMissedRoutine(
          rule: daily,
          dueAt: DateTime(2026, 11, 23, 8),
          today: DateTime(2026, 11, 23),
        ),
        isNull,
      );
      expect(
        rolloverMissedRoutine(
          rule: daily,
          dueAt: DateTime(2026, 11, 24),
          today: DateTime(2026, 11, 23),
        ),
        isNull,
      );
    });

    test('registra dias perdidos e avança mantendo a duração com início', () {
      final r = rolloverMissedRoutine(
        rule: daily,
        dueAt: DateTime(2026, 11, 20, 9),
        startAt: DateTime(2026, 11, 20, 8),
        today: DateTime(2026, 11, 23),
      )!;
      expect(r.missedOccurrences, [
        DateTime(2026, 11, 20, 9),
        DateTime(2026, 11, 21, 9),
        DateTime(2026, 11, 22, 9),
      ]);
      expect(r.nextDue, DateTime(2026, 11, 23, 9));
      expect(r.nextStart, DateTime(2026, 11, 23, 8));
      expect(r.finished, isFalse);
    });

    test('encerra série se UNTIL ficou no passado', () {
      final ending = RecurrenceRule(
        frequency: Frequency.daily,
        until: DateTime(2026, 11, 21),
      );
      final r = rolloverMissedRoutine(
        rule: ending,
        dueAt: DateTime(2026, 11, 20),
        today: DateTime(2026, 11, 23),
      )!;
      expect(r.missedOccurrences, [
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 21),
      ]);
      expect(r.finished, isTrue);
    });
  });
}
