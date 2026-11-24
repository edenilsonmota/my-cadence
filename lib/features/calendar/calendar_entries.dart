/// O que aparece no calendário: tarefas viram blocos (com hora) ou itens de
/// dia inteiro, e rotinas ganham ocorrências futuras virtuais.
/// Puro, sem Flutter.
library;

import '../../core/dates.dart';
import '../../core/recurrence.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';

/// Duração de uma tarefa com hora que só tem um dos horários (ou os dois
/// iguais).
const defaultBlockDuration = Duration(minutes: 30);

/// Menor duração ao redimensionar.
const minBlockDuration = Duration(minutes: 15);

class CalendarEntry {
  const CalendarEntry({
    required this.task,
    required this.start,
    required this.end,
    required this.allDay,
    this.virtual = false,
    this.done = false,
  });

  final Task task;

  /// Com hora: o intervalo do bloco. Dia inteiro: meia-noite do primeiro dia
  /// até a meia-noite seguinte ao último (exclusivo).
  final DateTime start;
  final DateTime end;
  final bool allDay;

  /// Ocorrência futura de rotina, calculada (não existe linha no banco).
  final bool virtual;

  /// Concluída: tarefa feita ou ocorrência do histórico da rotina.
  final bool done;

  bool get isRoutine => task.recurrenceRule != null;

  /// Dá para arrastar: tem hora e não é histórico.
  bool get movable => !allDay && !(isRoutine && done);

  String get key => '${task.id}@${start.millisecondsSinceEpoch}';

  bool occursOn(DateTime day) {
    final d = startOfDay(day);
    return start.isBefore(addDays(d, 1)) && end.isAfter(d);
  }

  @override
  String toString() =>
      'CalendarEntry(${task.title}, $start, $end${allDay ? ', dia inteiro' : ''}'
      '${virtual ? ', virtual' : ''}${done ? ', feita' : ''})';
}

/// Intervalo da tarefa como está no banco, ou `null` se não tem data.
({DateTime start, DateTime end, bool allDay})? taskSpan(Task task) {
  final first = task.startAt ?? task.dueAt;
  final last = task.dueAt ?? task.startAt;
  if (first == null || last == null) return null;
  if (!task.hasTime) {
    final end = startOfDay(last);
    return (
      start: startOfDay(first),
      end: addDays(end.isBefore(first) ? startOfDay(first) : end, 1),
      allDay: true,
    );
  }
  final end = last.isAfter(first) ? last : first.add(defaultBlockDuration);
  return (start: first, end: end, allDay: false);
}

/// Entradas do calendário que tocam `[from, to)`, em ordem de início.
///
/// Rotinas: o prazo atual é a ocorrência real; as seguintes (até [to] ou o
/// UNTIL) são virtuais; [completions] viram ocorrências concluídas no
/// histórico, com a mesma duração da rotina.
List<CalendarEntry> expandOccurrences(
  Iterable<Task> tasks,
  DateTime from,
  DateTime to, {
  Iterable<TaskCompletion> completions = const [],
}) {
  final result = <CalendarEntry>[];
  bool touches(DateTime start, DateTime end) =>
      start.isBefore(to) && end.isAfter(from);

  final byId = <String, Task>{};
  for (final task in tasks) {
    byId[task.id] = task;
    final span = taskSpan(task);
    if (span == null) continue;
    final done = task.status == TaskStatus.feita;
    final rule = task.recurrenceRule == null || task.dueAt == null || done
        ? null
        : RecurrenceRule.tryParse(task.recurrenceRule!);

    if (rule == null) {
      if (touches(span.start, span.end)) {
        result.add(
          CalendarEntry(
            task: task,
            start: span.start,
            end: span.end,
            allDay: span.allDay,
            done: done,
          ),
        );
      }
      continue;
    }

    final length = span.end.difference(span.start);
    final lead = span.start.difference(_anchor(task)); // início antes do prazo
    DateTime? due = task.dueAt;
    var guard = 0;
    while (due != null && guard++ < 5000) {
      final start = _occurrenceStart(task, due, lead);
      if (!start.isBefore(to)) break;
      final end = _occurrenceEnd(task, start, length);
      if (touches(start, end)) {
        result.add(
          CalendarEntry(
            task: task,
            start: start,
            end: end,
            allDay: span.allDay,
            virtual: due != task.dueAt,
          ),
        );
      }
      due = rule.next(due);
    }
  }

  for (final c in completions) {
    final task = byId[c.taskId];
    final span = task == null ? null : taskSpan(task);
    if (task == null || span == null) continue;
    final start = _occurrenceStart(
      task,
      c.occurrence,
      span.start.difference(_anchor(task)),
    );
    final end = _occurrenceEnd(task, start, span.end.difference(span.start));
    if (touches(start, end)) {
      result.add(
        CalendarEntry(
          task: task,
          start: start,
          end: end,
          allDay: span.allDay,
          done: true,
        ),
      );
    }
  }

  result.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    return byStart != 0 ? byStart : a.task.title.compareTo(b.task.title);
  });
  return result;
}

DateTime _anchor(Task task) {
  final due = task.dueAt!;
  return task.hasTime ? due : startOfDay(due);
}

DateTime _occurrenceStart(Task task, DateTime due, Duration lead) {
  final anchor = task.hasTime ? due : startOfDay(due);
  return anchor.add(lead);
}

DateTime _occurrenceEnd(Task task, DateTime start, Duration length) {
  if (!task.hasTime) {
    // Dias inteiros: soma dias de calendário (imune a horário de verão).
    return addDays(start, (length.inHours / 24).round());
  }
  return start.add(length);
}

/// Separa as entradas de [day] em dia inteiro e com hora.
({List<CalendarEntry> allDay, List<CalendarEntry> timed}) entriesOfDay(
  Iterable<CalendarEntry> entries,
  DateTime day,
) {
  final allDay = <CalendarEntry>[], timed = <CalendarEntry>[];
  for (final e in entries) {
    if (!e.occursOn(day)) continue;
    (e.allDay ? allDay : timed).add(e);
  }
  return (allDay: allDay, timed: timed);
}

typedef TaskTimes = ({DateTime? startAt, DateTime? dueAt});

/// Novos horários da tarefa ao arrastar [entry] para começar em [newStart].
/// Desloca início e prazo juntos (numa rotina, isso vale para todas as
/// ocorrências).
TaskTimes moveEntry(CalendarEntry entry, DateTime newStart) {
  final delta = newStart.difference(entry.start);
  final task = entry.task;
  return (startAt: task.startAt?.add(delta), dueAt: task.dueAt?.add(delta));
}

/// Novos horários ao arrastar o fim de [entry] para [newEnd]: o bloco passa
/// a ter início e prazo explícitos (duração mínima de 15 min).
TaskTimes resizeEntry(CalendarEntry entry, DateTime newEnd) {
  final task = entry.task;
  final base = task.startAt ?? task.dueAt!;
  var length = newEnd.difference(entry.start);
  if (length < minBlockDuration) length = minBlockDuration;
  return (startAt: base, dueAt: base.add(length));
}

/// Próxima entrada com hora, não concluída, que começa depois de [now].
CalendarEntry? nextUpcoming(Iterable<CalendarEntry> entries, DateTime now) {
  CalendarEntry? best;
  for (final e in entries) {
    if (e.allDay || e.done || !e.start.isAfter(now)) continue;
    if (best == null || e.start.isBefore(best.start)) best = e;
  }
  return best;
}
