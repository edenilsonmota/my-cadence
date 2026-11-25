import 'package:drift/drift.dart';

import '../enums.dart';
import '../sync_columns.dart';

@TableIndex(name: 'tasks_parent_id', columns: {#parentId})
@TableIndex(name: 'tasks_due_at', columns: {#dueAt})
class Tasks extends Table with SyncColumns {
  /// Subtarefa quando preenchido.
  TextColumn get parentId => text().nullable().references(Tasks, #id)();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get kind =>
      textEnum<TaskKind>().withDefault(Constant(TaskKind.simples.name))();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(Constant(TaskStatus.aFazer.name))();

  /// 0 (nenhuma) a 3 (alta).
  IntColumn get priority => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters (padrão do drift para CHECK na própria coluna)
      .check(priority.isBetweenValues(0, 3))();
  DateTimeColumn get startAt => dateTime().nullable()();
  DateTimeColumn get dueAt => dateTime().nullable()();

  /// `false` = dia inteiro (vale só a data de [startAt]/[dueAt]).
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();

  /// RRULE (subconjunto de `core/recurrence.dart`).
  TextColumn get recurrenceRule => text().nullable()();
  IntColumn get reminderMinutesBefore => integer().nullable()();

  /// Lista ordenada de antecedências em minutos separadas por vírgula
  /// (ex.: `'0,15,1440'`). Quando preenchida, prevalece sobre
  /// [reminderMinutesBefore] (que guarda a menor antecedência por compatibilidade).
  TextColumn get reminderOffsets => text().nullable()();

  /// Como o lembrete avisa (`notificacao` comum ou `alarme` insistente).
  TextColumn get reminderMode => textEnum<ReminderMode>().withDefault(
    Constant(ReminderMode.notificacao.name),
  )();

  /// Intervalo em minutos para insistir se a tarefa atrasar; `null` desliga.
  IntColumn get nagIntervalMinutes => integer().nullable()();
  IntColumn get estimatedPomodoros => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Chave da paleta (`PaletteKey.name`); nula = herda (mãe, tag, tipo).
  TextColumn get colorKey => text().nullable()();

  /// Chave do catálogo de ícones (ex.: `book-open`); nula = herda.
  TextColumn get iconKey => text().nullable()();
}

/// Histórico de conclusões de rotinas (uma linha por ocorrência concluída).
class TaskCompletions extends Table with SyncColumns {
  TextColumn get taskId => text().references(Tasks, #id)();
  DateTimeColumn get occurrence => dateTime()();
}

class Tags extends Table with SyncColumns {
  TextColumn get name => text()();

  /// Chave da paleta (`PaletteKey.name`).
  TextColumn get colorKey => text().withDefault(const Constant('azul'))();
}

class TaskTags extends Table with SyncColumns {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, tagId},
  ];
}
