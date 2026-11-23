/// Estado do formulário de tarefa e conversão para as colunas do banco.
/// Puro, sem Flutter, para ser testado à parte da tela.
library;

import 'package:drift/drift.dart' show Value;

import '../../core/dates.dart';
import '../../core/recurrence.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';

typedef ClockTime = ({int hour, int minute});

enum Repeat { nenhuma, diaria, semanal }

/// Opções de alarme do formulário (minutos antes; 0 = na hora).
const reminderOptions = <int?, String>{
  null: 'Nenhum',
  0: 'Na hora',
  5: '5 min antes',
  10: '10 min antes',
  15: '15 min antes',
  30: '30 min antes',
  60: '1 hora antes',
  1440: '1 dia antes',
};

/// Hora usada quando a tarefa deixa de ser "dia inteiro" sem hora escolhida.
const defaultTime = (hour: 9, minute: 0);

class TaskDraft {
  TaskDraft({
    this.title = '',
    this.notes = '',
    this.kind = TaskKind.simples,
    this.priority = 0,
    this.allDay = true,
    this.startDate,
    this.startTime,
    this.dueDate,
    this.dueTime,
    this.repeat = Repeat.nenhuma,
    this.interval = 1,
    Set<int>? weekdays,
    this.until,
    this.reminderMinutesBefore,
    this.estimatedPomodoros,
    Set<String>? tagIds,
  }) : weekdays = weekdays ?? {},
       tagIds = tagIds ?? {};

  /// Preenche o formulário a partir de uma tarefa existente.
  factory TaskDraft.fromTask(Task task, Set<String> tagIds) {
    final rule = task.recurrenceRule == null
        ? null
        : RecurrenceRule.parse(task.recurrenceRule!);
    ClockTime? timeOf(DateTime? d) =>
        d == null || !task.hasTime ? null : (hour: d.hour, minute: d.minute);
    return TaskDraft(
      title: task.title,
      notes: task.notes ?? '',
      kind: task.kind,
      priority: task.priority,
      allDay: !task.hasTime,
      startDate: task.startAt == null ? null : startOfDay(task.startAt!),
      startTime: timeOf(task.startAt),
      dueDate: task.dueAt == null ? null : startOfDay(task.dueAt!),
      dueTime: timeOf(task.dueAt),
      repeat: switch (rule?.frequency) {
        null => Repeat.nenhuma,
        Frequency.daily => Repeat.diaria,
        Frequency.weekly => Repeat.semanal,
      },
      interval: rule?.interval ?? 1,
      weekdays: {...?rule?.weekdays},
      until: rule?.until,
      reminderMinutesBefore: task.reminderMinutesBefore,
      estimatedPomodoros: task.estimatedPomodoros,
      tagIds: tagIds,
    );
  }

  String title;
  String notes;
  TaskKind kind;
  int priority;

  /// `true` = só datas, sem hora.
  bool allDay;
  DateTime? startDate;
  ClockTime? startTime;
  DateTime? dueDate;
  ClockTime? dueTime;

  Repeat repeat;
  int interval;
  Set<int> weekdays;
  DateTime? until;

  int? reminderMinutesBefore;
  int? estimatedPomodoros;
  Set<String> tagIds;

  RecurrenceRule? get recurrence => switch (repeat) {
    Repeat.nenhuma => null,
    Repeat.diaria => RecurrenceRule(
      frequency: Frequency.daily,
      interval: interval,
      until: until,
    ),
    Repeat.semanal => RecurrenceRule(
      frequency: Frequency.weekly,
      interval: interval,
      weekdays: weekdays,
      until: until,
    ),
  };

  /// Mensagem de erro para mostrar ao usuário, ou `null` se está válido.
  String? validate(DateTime now) {
    if (title.trim().isEmpty) return 'Informe o título.';
    if (interval < 1) return 'O intervalo da repetição deve ser ao menos 1.';
    final fields = toFields(now);
    final start = fields.startAt, due = fields.dueAt;
    if (start != null && due != null && start.isAfter(due)) {
      return 'O início deve ser antes do prazo.';
    }
    if (until != null && due != null && until!.isBefore(startOfDay(due))) {
      return 'A data final da repetição é anterior ao prazo.';
    }
    return null;
  }

  /// Colunas da tarefa. Recorrência sem prazo usa hoje como prazo; alarme
  /// sem prazo é descartado.
  TaskFields toFields(DateTime now) {
    DateTime? combine(DateTime? date, ClockTime? time) {
      if (date == null) return null;
      if (allDay) return startOfDay(date);
      final t = time ?? defaultTime;
      return DateTime(date.year, date.month, date.day, t.hour, t.minute);
    }

    final rule = recurrence;
    final dueDay = dueDate ?? (rule != null ? startOfDay(now) : null);
    final dueAt = combine(dueDay, dueTime);
    final trimmedNotes = notes.trim();
    return TaskFields(
      title: title.trim(),
      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
      kind: kind,
      priority: priority,
      hasTime: !allDay,
      startAt: combine(startDate, startTime),
      dueAt: dueAt,
      recurrenceRule: rule?.toRule(),
      reminderMinutesBefore: dueAt == null ? null : reminderMinutesBefore,
      estimatedPomodoros: estimatedPomodoros,
    );
  }
}

/// Valores prontos para gravar na tabela `tasks`.
class TaskFields {
  const TaskFields({
    required this.title,
    required this.notes,
    required this.kind,
    required this.priority,
    required this.hasTime,
    required this.startAt,
    required this.dueAt,
    required this.recurrenceRule,
    required this.reminderMinutesBefore,
    required this.estimatedPomodoros,
  });

  final String title;
  final String? notes;
  final TaskKind kind;
  final int priority;
  final bool hasTime;
  final DateTime? startAt;
  final DateTime? dueAt;
  final String? recurrenceRule;
  final int? reminderMinutesBefore;
  final int? estimatedPomodoros;

  /// Aplica os campos numa tarefa existente (para `saveTask`).
  Task applyTo(Task task) => task.copyWith(
    title: title,
    notes: Value(notes),
    kind: kind,
    priority: priority,
    hasTime: hasTime,
    startAt: Value(startAt),
    dueAt: Value(dueAt),
    recurrenceRule: Value(recurrenceRule),
    reminderMinutesBefore: Value(reminderMinutesBefore),
    estimatedPomodoros: Value(estimatedPomodoros),
  );
}
