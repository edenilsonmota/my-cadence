import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/daos/pomodoro_dao.dart';
import '../db/database.dart';
import '../db/enums.dart';

/// Sessões de pomodoro. O tempo restante é sempre calculado a partir das
/// colunas (ver `features/pomodoro/pomodoro_logic.dart`), nunca acumulado.
class PomodoroRepository {
  PomodoroRepository(this._dao);

  final PomodoroDao _dao;

  Future<PomodoroSession?> getRunning() => _dao.getRunning();
  Stream<PomodoroSession?> watchRunning() => _dao.watchRunning();

  Stream<List<PomodoroSession>> watchSessionsOfTasks(List<String> taskIds) =>
      _dao.watchSessionsOfTasks(taskIds);

  Stream<List<PomodoroSession>> watchSessionsBetween(
    DateTime from,
    DateTime to,
  ) => _dao.watchSessionsBetween(from, to);

  /// Inicia uma sessão e devolve o id.
  Future<String> startSession({
    required PomodoroKind kind,
    required int plannedMinutes,
    required DateTime startedAt,
    String? taskId,
  }) async {
    final id = newId();
    await _dao.insertSession(
      PomodoroSessionsCompanion.insert(
        id: Value(id),
        taskId: Value(taskId),
        kind: kind,
        startedAt: startedAt,
        plannedMinutes: plannedMinutes,
      ),
    );
    return id;
  }

  /// Encerra a sessão. [completed] = chegou ao fim (e não foi interrompida).
  Future<void> finishSession(
    String id, {
    required DateTime endedAt,
    required bool completed,
  }) => _dao.updateSession(
    id,
    PomodoroSessionsCompanion(
      endedAt: Value(endedAt),
      completed: Value(completed),
      pausedAt: const Value(null),
    ),
  );

  /// Pausa: grava o momento da pausa.
  Future<void> pauseSession(String id, {required DateTime at}) =>
      _dao.updateSession(id, PomodoroSessionsCompanion(pausedAt: Value(at)));

  /// Retoma: soma a pausa em `pausedTotalMs` e limpa `pausedAt`.
  Future<void> resumeSession(PomodoroSession session, {required DateTime at}) {
    final pausedAt = session.pausedAt;
    if (pausedAt == null) return Future.value();
    final pause = at.difference(pausedAt).inMilliseconds;
    return _dao.updateSession(
      session.id,
      PomodoroSessionsCompanion(
        pausedAt: const Value(null),
        pausedTotalMs: Value(session.pausedTotalMs + (pause < 0 ? 0 : pause)),
      ),
    );
  }

  /// Troca (ou remove) a tarefa vinculada à sessão.
  Future<void> setSessionTask(String id, String? taskId) =>
      _dao.updateSession(id, PomodoroSessionsCompanion(taskId: Value(taskId)));

  Future<void> deleteSession(String id) => _dao.softDeleteSession(id);
}
