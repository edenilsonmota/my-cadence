import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/recurrence.dart';

// 23/11/2026 é uma segunda-feira.
final monday = DateTime(2026, 11, 23, 9, 30);

void main() {
  group('parse e toRule', () {
    test('ida e volta preserva a regra', () {
      for (final text in [
        'FREQ=DAILY',
        'FREQ=DAILY;INTERVAL=3',
        'FREQ=WEEKLY',
        'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;UNTIL=20261231',
      ]) {
        expect(RecurrenceRule.parse(text).toRule(), text);
      }
    });

    test('aceita prefixo RRULE:, minúsculas e BYDAY fora de ordem', () {
      final rule = RecurrenceRule.parse('RRULE:freq=weekly;byday=fr,mo');
      expect(rule.frequency, Frequency.weekly);
      expect(rule.weekdays, {DateTime.monday, DateTime.friday});
      expect(rule.toRule(), 'FREQ=WEEKLY;BYDAY=MO,FR');
    });

    test('UNTIL com hora local guarda só a data', () {
      final rule = RecurrenceRule.parse('FREQ=DAILY;UNTIL=20261231T235959');
      expect(rule.until, DateTime(2026, 12, 31));
    });

    test('UNTIL em UTC é convertido para o fuso local', () {
      final rule = RecurrenceRule.parse('FREQ=DAILY;UNTIL=20261231T120000Z');
      final local = DateTime.utc(2026, 12, 31, 12).toLocal();
      expect(rule.until, DateTime(local.year, local.month, local.day));
    });

    test('rejeita o que está fora do subconjunto', () {
      for (final text in [
        '',
        'INTERVAL=2',
        'FREQ=MONTHLY',
        'FREQ=DAILY;INTERVAL=0',
        'FREQ=DAILY;BYDAY=MO',
        'FREQ=WEEKLY;BYDAY=XX',
        'FREQ=WEEKLY;COUNT=3',
        'FREQ=DAILY;UNTIL=2026-12-31',
      ]) {
        expect(
          () => RecurrenceRule.parse(text),
          throwsFormatException,
          reason: text,
        );
      }
    });

    test('igualdade por valor', () {
      expect(
        RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=WE,MO'),
        RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE'),
      );
    });
  });

  group('next', () {
    test('diário', () {
      final rule = RecurrenceRule(frequency: Frequency.daily);
      expect(rule.next(monday), DateTime(2026, 11, 24, 9, 30));
    });

    test('diário com intervalo', () {
      final rule = RecurrenceRule(frequency: Frequency.daily, interval: 3);
      expect(rule.next(monday), DateTime(2026, 11, 26, 9, 30));
    });

    test('semanal sem BYDAY repete o dia da semana', () {
      final rule = RecurrenceRule(frequency: Frequency.weekly);
      expect(rule.next(monday), DateTime(2026, 11, 30, 9, 30));
    });

    test('semanal com vários dias percorre a semana e volta', () {
      final rule = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');
      final wednesday = rule.next(monday)!;
      expect(wednesday, DateTime(2026, 11, 25, 9, 30));
      final friday = rule.next(wednesday)!;
      expect(friday, DateTime(2026, 11, 27, 9, 30));
      expect(rule.next(friday), DateTime(2026, 11, 30, 9, 30));
    });

    test('a cada 2 semanas pula a semana do meio', () {
      final rule = RecurrenceRule.parse('FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH');
      final tuesday = DateTime(2026, 11, 24, 8);
      final thursday = rule.next(tuesday)!;
      expect(thursday, DateTime(2026, 11, 26, 8));
      expect(rule.next(thursday), DateTime(2026, 12, 8, 8));
    });

    test('ocorrência fora do BYDAY vai para o próximo dia da regra', () {
      final rule = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE');
      final tuesday = DateTime(2026, 11, 24);
      expect(rule.next(tuesday), DateTime(2026, 11, 25));
      final sunday = DateTime(2026, 11, 29);
      expect(rule.next(sunday), DateTime(2026, 11, 30));
    });

    test('vira o mês e o ano', () {
      final daily = RecurrenceRule(frequency: Frequency.daily);
      expect(daily.next(DateTime(2026, 1, 31, 7)), DateTime(2026, 2, 1, 7));
      expect(daily.next(DateTime(2026, 12, 31, 7)), DateTime(2027, 1, 1, 7));
      expect(daily.next(DateTime(2028, 2, 28)), DateTime(2028, 2, 29));

      final weekly = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO');
      expect(weekly.next(DateTime(2026, 12, 28)), DateTime(2027, 1, 4));
    });

    test('UNTIL inclui o próprio dia e corta depois dele', () {
      final rule = RecurrenceRule.parse('FREQ=DAILY;UNTIL=20261125');
      final tuesday = rule.next(monday)!;
      final wednesday = rule.next(tuesday)!;
      expect(wednesday, DateTime(2026, 11, 25, 9, 30));
      expect(rule.next(wednesday), isNull);
    });

    test('nextAfter pula as ocorrências que ficaram no passado', () {
      final rule = RecurrenceRule(frequency: Frequency.daily, interval: 2);
      final now = DateTime(2026, 11, 30, 12);
      // 23, 25, 27, 29 ficaram para trás; 01/12 às 9h30 é a próxima.
      expect(rule.nextAfter(monday, now), DateTime(2026, 12, 1, 9, 30));
    });

    test('nextAfter respeita UNTIL', () {
      final rule = RecurrenceRule.parse('FREQ=DAILY;UNTIL=20261125');
      expect(rule.nextAfter(monday, DateTime(2026, 12, 1)), isNull);
    });
  });

  group('describe', () {
    test('textos em português', () {
      String d(String rule) => RecurrenceRule.parse(rule).describe();
      expect(d('FREQ=DAILY'), 'Todo dia');
      expect(d('FREQ=DAILY;INTERVAL=3'), 'A cada 3 dias');
      expect(d('FREQ=WEEKLY'), 'Toda semana');
      expect(d('FREQ=WEEKLY;BYDAY=SA'), 'Toda semana: sáb');
      expect(d('FREQ=WEEKLY;BYDAY=MO,WE,FR'), 'Toda semana: seg, qua e sex');
      expect(
        d('FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;UNTIL=20270105'),
        'A cada 2 semanas: ter e qui, até 05/01/2027',
      );
    });
  });
}
