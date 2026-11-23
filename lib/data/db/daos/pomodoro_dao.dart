import 'package:drift/drift.dart';

import '../database.dart';
import '../sync_writes.dart';
import '../tables/pomodoro.dart';

part 'pomodoro_dao.g.dart';

@DriftAccessor(tables: [PomodoroSessions])
class PomodoroDao extends DatabaseAccessor<AppDatabase>
    with _$PomodoroDaoMixin {
  PomodoroDao(super.attachedDatabase);

  Future<void> insertSession(PomodoroSessionsCompanion row) =>
      insertSynced(pomodoroSessions, row);

  Future<void> updateSession(String id, PomodoroSessionsCompanion patch) =>
      updateSynced(pomodoroSessions, id, patch);

  Future<void> softDeleteSession(String id) =>
      softDeleteSynced(pomodoroSessions, id);

  SimpleSelectStatement<$PomodoroSessionsTable, PomodoroSession> _running() =>
      select(pomodoroSessions)
        ..where((s) => s.endedAt.isNull() & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
        ..limit(1);

  /// Sessão em andamento (sem `endedAt`), se houver.
  Future<PomodoroSession?> getRunning() => _running().getSingleOrNull();

  Stream<PomodoroSession?> watchRunning() => _running().watchSingleOrNull();

  /// Sessões de um conjunto de tarefas (ex.: tarefa + subtarefas).
  Stream<List<PomodoroSession>> watchSessionsOfTasks(List<String> taskIds) =>
      (select(pomodoroSessions)
            ..where((s) => s.taskId.isIn(taskIds) & s.deletedAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
          .watch();

  /// Sessões iniciadas em `[from, to)`.
  Stream<List<PomodoroSession>> watchSessionsBetween(
    DateTime from,
    DateTime to,
  ) =>
      (select(pomodoroSessions)
            ..where(
              (s) =>
                  s.startedAt.isBiggerOrEqualValue(from) &
                  s.startedAt.isSmallerThanValue(to) &
                  s.deletedAt.isNull(),
            )
            ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
          .watch();
}
