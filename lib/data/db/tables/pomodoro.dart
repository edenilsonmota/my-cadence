import 'package:drift/drift.dart';

import '../enums.dart';
import '../sync_columns.dart';
import 'tasks.dart';

@TableIndex(
  name: 'pomodoro_sessions_task_started',
  columns: {#taskId, #startedAt},
)
class PomodoroSessions extends Table with SyncColumns {
  TextColumn get taskId => text().nullable().references(Tasks, #id)();
  TextColumn get kind => textEnum<PomodoroKind>()();
  DateTimeColumn get startedAt => dateTime()();

  /// Nulo enquanto a sessão está em andamento.
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get plannedMinutes => integer()();

  /// Preenchido enquanto a sessão está pausada.
  DateTimeColumn get pausedAt => dateTime().nullable()();

  /// Soma das pausas já encerradas.
  IntColumn get pausedTotalMs => integer().withDefault(const Constant(0))();

  /// `true` se chegou ao fim; `false` se foi interrompida.
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}
