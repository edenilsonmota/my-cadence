/// Reagendar uma tarefa para outro dia. Puro, sem Flutter.
library;

import '../../core/dates.dart';
import '../../data/db/database.dart';

typedef RescheduledDates = ({DateTime? startAt, DateTime? dueAt, bool hasTime});

/// Leva a tarefa para [day] mantendo a hora e a distância entre início e
/// prazo (os dois andam o mesmo número de dias). Sem datas, vira uma tarefa
/// de dia inteiro com prazo em [day].
RescheduledDates rescheduleToDay(Task task, DateTime day) {
  final target = startOfDay(day);
  final anchor = task.dueAt ?? task.startAt;
  if (anchor == null) {
    return (startAt: null, dueAt: target, hasTime: false);
  }
  final days = target.difference(startOfDay(anchor)).inHours ~/ 24;
  // Pelo construtor (e não somando Duration) para não escorregar no horário
  // de verão.
  DateTime? shift(DateTime? d) => d == null
      ? null
      : DateTime(d.year, d.month, d.day + days, d.hour, d.minute);
  return (
    startAt: shift(task.startAt),
    dueAt: shift(task.dueAt),
    hasTime: task.hasTime,
  );
}
