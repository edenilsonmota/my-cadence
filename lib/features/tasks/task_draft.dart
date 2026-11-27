/// Estado do formulário de tarefa e conversão para as colunas do banco.
/// Puro, sem Flutter, para ser testado à parte da tela.
library;

import 'package:drift/drift.dart' show Value;

import '../../core/dates.dart';
import '../../core/recurrence.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import 'reminder_offsets.dart';

typedef ClockTime = ({int hour, int minute});

enum Repeat { nenhuma, diaria, semanal }

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
    this.skipMissed = true,
    int? reminderMinutesBefore,
    Set<int>? reminderOffsets,
    this.reminderMode = ReminderMode.notificacao,
    this.nagIntervalMinutes,
    this.estimatedMinutes,
    this.colorKey,
    this.iconKey,
    Set<String>? tagIds,
    Set<String>? notebookIds,
    Set<String>? deckIds,
  }) : weekdays = weekdays ?? {},
       notebookIds = notebookIds ?? {},
       deckIds = deckIds ?? {},
       reminderOffsets =
           reminderOffsets ??
           (reminderMinutesBefore == null ? {} : {reminderMinutesBefore}),
       tagIds = tagIds ?? {};

  /// Preenche o formulário a partir de uma tarefa existente.
  factory TaskDraft.fromTask(
    Task task,
    Set<String> tagIds, {
    Set<String> notebookIds = const {},
    Set<String> deckIds = const {},
  }) {
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
      skipMissed: task.skipMissed,
      reminderOffsets: {...effectiveReminderOffsets(task)},
      reminderMode: task.reminderMode,
      nagIntervalMinutes: normalizeNagInterval(task.nagIntervalMinutes),
      estimatedMinutes: task.estimatedMinutes,
      colorKey: task.colorKey,
      iconKey: task.iconKey,
      tagIds: tagIds,
      notebookIds: {...notebookIds},
      deckIds: {...deckIds},
    );
  }

  String title;
  String notes;
  TaskKind kind;
  int priority;

  /// `true` = só datas, sem hora. Para trocar pelo formulário, use
  /// [setAllDay], que também ajusta os lembretes.
  bool allDay;

  /// Troca entre dia inteiro e com hora, mantendo só os lembretes que fazem
  /// sentido no novo modo ("5 min antes" não existe em tarefa de dia inteiro).
  void setAllDay(bool value) {
    if (value == allDay) return;
    allDay = value;
    final valid = (value ? allDayReminderChoices : timedReminderChoices)
        .toSet();
    reminderOffsets = reminderOffsets.where(valid.contains).toSet();
  }

  bool get repeats => repeat != Repeat.nenhuma;
  DateTime? startDate;
  ClockTime? startTime;
  DateTime? dueDate;
  ClockTime? dueTime;

  Repeat repeat;
  int interval;
  Set<int> weekdays;
  DateTime? until;
  bool skipMissed;

  /// Antecedências selecionadas em minutos (vazio = sem lembrete).
  Set<int> reminderOffsets;

  /// Atalho de compatibilidade para a menor antecedência selecionada.
  int? get reminderMinutesBefore {
    if (reminderOffsets.isEmpty) return null;
    final sorted = reminderOffsets.toList()..sort();
    return sorted.first;
  }

  set reminderMinutesBefore(int? value) {
    reminderOffsets = value == null ? {} : {value};
  }

  ReminderMode reminderMode;

  /// Intervalo em minutos para insistir se atrasar; `null` desliga.
  int? nagIntervalMinutes;
  int? estimatedMinutes;

  /// Chaves de cor e ícone; nulas = herdar (mãe, tag, tipo).
  String? colorKey;
  String? iconKey;
  Set<String> tagIds;

  /// Books já existentes vinculados à tarefa.
  Set<String> notebookIds;

  /// Decks vinculados à tarefa.
  Set<String> deckIds;

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
      return 'A repetição termina antes da primeira vez.';
    }
    return null;
  }

  /// Colunas da tarefa. Recorrência sem prazo usa hoje como prazo; lembretes
  /// sem prazo nem início com hora são descartados.
  ///
  /// Na rotina o formulário mostra só "Começa" (o prazo da 1ª ocorrência) e,
  /// com hora, o horário de início e fim no mesmo dia: o início vira
  /// prazo + hora de início, e em dia inteiro não há início.
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
    final startAt = rule == null
        ? combine(startDate, startTime)
        : allDay || startTime == null
        ? null
        : combine(dueDay, startTime);
    final trimmedNotes = notes.trim();
    final canRemind = dueAt != null || (!allDay && startAt != null);
    final encodedOffsets = canRemind
        ? encodeReminderOffsets(reminderOffsets)
        : null;
    final parsedOffsets = parseReminderOffsets(encodedOffsets);
    final primaryOffset = parsedOffsets.isEmpty ? null : parsedOffsets.first;
    final effectiveNag = primaryOffset == null
        ? null
        : normalizeNagInterval(nagIntervalMinutes);
    return TaskFields(
      title: title.trim(),
      notes: trimmedNotes.isEmpty ? null : trimmedNotes,
      kind: kind,
      priority: priority,
      hasTime: !allDay,
      startAt: startAt,
      dueAt: dueAt,
      recurrenceRule: rule?.toRule(),
      skipMissed: skipMissed,
      reminderMinutesBefore: primaryOffset,
      reminderOffsets: encodedOffsets,
      reminderMode: primaryOffset == null
          ? ReminderMode.notificacao
          : reminderMode,
      nagIntervalMinutes: effectiveNag,
      estimatedMinutes: estimatedMinutes,
      colorKey: colorKey,
      iconKey: iconKey,
    );
  }
}

/// Base dos lembretes: o início se tem hora, senão o prazo; em dia inteiro,
/// o dia do prazo às [allDayHour]. Mesma regra de `reminderBaseTime`.
DateTime? draftReminderBase(TaskFields f, {required int allDayHour}) {
  if (f.hasTime && f.startAt != null) return f.startAt;
  final due = f.dueAt;
  if (due == null) return null;
  return f.hasTime ? due : DateTime(due.year, due.month, due.day, allDayHour);
}

/// Quando cada lembrete escolhido vai tocar (na 1ª ocorrência), em ordem.
List<DateTime> draftReminderTimes(TaskFields f, {required int allDayHour}) {
  final base = draftReminderBase(f, allDayHour: allDayHour);
  if (base == null) return const [];
  final offsets = parseReminderOffsets(f.reminderOffsets);
  return [
    for (final m in offsets.reversed) base.subtract(Duration(minutes: m)),
  ];
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
    this.skipMissed = true,
    required this.reminderMinutesBefore,
    this.reminderOffsets,
    this.reminderMode = ReminderMode.notificacao,
    this.nagIntervalMinutes,
    required this.estimatedMinutes,
    this.colorKey,
    this.iconKey,
  });

  final String title;
  final String? notes;
  final TaskKind kind;
  final int priority;
  final bool hasTime;
  final DateTime? startAt;
  final DateTime? dueAt;
  final String? recurrenceRule;
  final bool skipMissed;
  final int? reminderMinutesBefore;
  final String? reminderOffsets;
  final ReminderMode reminderMode;
  final int? nagIntervalMinutes;
  final int? estimatedMinutes;
  final String? colorKey;
  final String? iconKey;

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
    skipMissed: skipMissed,
    reminderMinutesBefore: Value(reminderMinutesBefore),
    reminderOffsets: Value(reminderOffsets),
    reminderMode: reminderMode,
    nagIntervalMinutes: Value(nagIntervalMinutes),
    estimatedMinutes: Value(estimatedMinutes),
    colorKey: Value(colorKey),
    iconKey: Value(iconKey),
  );
}
