/// Regras de conclusão de rotinas (tarefas recorrentes). Puro, sem Flutter.
library;

import 'dates.dart';
import 'recurrence.dart';

class RoutineAdvance {
  const RoutineAdvance({
    required this.occurrence,
    required this.nextDue,
    required this.nextStart,
  });

  /// Ocorrência concluída (o prazo atual), gravada no histórico.
  final DateTime occurrence;

  /// Próximo prazo, ou `null` se a série terminou (passou do UNTIL).
  final DateTime? nextDue;
  final DateTime? nextStart;

  bool get finished => nextDue == null;
}

class RoutineRollover {
  const RoutineRollover({
    required this.missedOccurrences,
    required this.nextDue,
    required this.nextStart,
  });

  /// Ocorrências de dias anteriores a `today` que não foram feitas e viram
  /// `naoConcluida` no histórico.
  final List<DateTime> missedOccurrences;

  /// Próximo prazo (em `today` ou depois), ou `null` se a série terminou.
  final DateTime? nextDue;
  final DateTime? nextStart;

  bool get finished => nextDue == null;
}

/// Teto de faltas gravadas de uma só vez caso o app fique meses sem abrir.
const maxRecordedMissedOccurrences = 90;

/// Se a rotina tem [dueAt] em um dia anterior a [today], calcula as ocorrências
/// perdidas até [today] e o próximo prazo (em [today] ou depois). Devolve `null`
/// se [dueAt] já é hoje ou futuro.
RoutineRollover? rolloverMissedRoutine({
  required RecurrenceRule rule,
  required DateTime dueAt,
  required DateTime today,
  DateTime? startAt,
}) {
  final todayStart = startOfDay(today);
  if (!startOfDay(dueAt).isBefore(todayStart)) return null;

  final missed = <DateTime>[];
  DateTime? cursor = dueAt;
  var guard = 0;
  while (cursor != null &&
      startOfDay(cursor).isBefore(todayStart) &&
      guard++ < 5000) {
    missed.add(cursor);
    cursor = rule.next(cursor);
  }
  final recorded = missed.length > maxRecordedMissedOccurrences
      ? missed.sublist(missed.length - maxRecordedMissedOccurrences)
      : missed;
  final nextDue = cursor;
  return RoutineRollover(
    missedOccurrences: recorded,
    nextDue: nextDue,
    nextStart: nextDue == null || startAt == null
        ? null
        : nextDue.subtract(dueAt.difference(startAt)),
  );
}

/// Conclui a ocorrência [dueAt] e calcula a próxima, pulando as que ficaram
/// no passado. Em tarefa de dia inteiro, a ocorrência de hoje ainda conta como
/// futura; com hora, só as depois de [now]. O início acompanha o prazo,
/// mantendo a mesma distância.
RoutineAdvance advanceRoutine({
  required RecurrenceRule rule,
  required DateTime dueAt,
  required bool hasTime,
  required DateTime now,
  DateTime? startAt,
}) {
  final after = hasTime
      ? now
      : startOfDay(now).subtract(const Duration(seconds: 1));
  final next = rule.nextAfter(dueAt, after);
  return RoutineAdvance(
    occurrence: dueAt,
    nextDue: next,
    nextStart: next == null || startAt == null
        ? null
        : next.subtract(dueAt.difference(startAt)),
  );
}

/// Quantas ocorrências seguidas foram concluídas até agora.
///
/// Conta de trás para frente enquanto cada conclusão é a ocorrência seguinte
/// da anterior. Se uma ocorrência de um dia anterior a hoje ficou sem
/// conclusão, a sequência zera.
int routineStreak(
  RecurrenceRule rule,
  Iterable<DateTime> completedOccurrences,
  DateTime now,
) {
  final days = {for (final d in completedOccurrences) startOfDay(d)}.toList()
    ..sort();
  if (days.isEmpty) return 0;

  final expected = rule.next(days.last);
  if (expected != null && startOfDay(expected).isBefore(startOfDay(now))) {
    return 0; // perdeu uma ocorrência depois da última conclusão
  }
  var streak = 1;
  for (var i = days.length - 1; i > 0; i--) {
    final next = rule.next(days[i - 1]);
    if (next == null || !isSameDay(next, days[i])) break;
    streak++;
  }
  return streak;
}
