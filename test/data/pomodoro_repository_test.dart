import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late PomodoroRepository repo;
  late TasksRepository tasks;

  setUp(() {
    db = openTestDb();
    repo = PomodoroRepository(db.pomodoroDao);
    tasks = TasksRepository(db.tasksDao, db.tagsDao);
  });

  test('sessão em andamento fica no banco até ser encerrada', () async {
    final task = await tasks.createTask(title: 'Estudar');
    final start = DateTime(2026, 11, 23, 9);
    final id = await repo.startSession(
      kind: PomodoroKind.foco,
      plannedMinutes: 25,
      startedAt: start,
      taskId: task,
    );

    final running = (await repo.getRunning())!;
    expect(running.id, id);
    expect(running.kind, PomodoroKind.foco);
    expect(running.startedAt, start);
    expect(running.plannedMinutes, 25);
    expect(running.pausedAt, isNull);
    expect(running.pausedTotalMs, 0);
    expect(running.completed, isFalse);

    final end = DateTime(2026, 11, 23, 9, 25);
    await repo.finishSession(id, endedAt: end, completed: true);

    expect(await repo.getRunning(), isNull);
    final sessions = await repo.watchSessionsOfTasks([task]).first;
    expect(sessions.single.endedAt, end);
    expect(sessions.single.completed, isTrue);
  });

  test('sessões da tarefa e das subtarefas juntas', () async {
    final root = await tasks.createTask(title: 'Projeto');
    final child = await tasks.createTask(title: 'Parte', parentId: root);
    final other = await tasks.createTask(title: 'Outra');
    for (final (task, hour) in [(root, 8), (child, 9), (other, 10)]) {
      await repo.startSession(
        kind: PomodoroKind.foco,
        plannedMinutes: 25,
        startedAt: DateTime(2026, 11, 23, hour),
        taskId: task,
      );
    }

    final ids = await tasks.taskTreeIds(root);
    final sessions = await repo.watchSessionsOfTasks(ids).first;
    expect(sessions.map((s) => s.startedAt.hour), [8, 9]);
  });

  test('pausar e retomar acumulam o tempo pausado', () async {
    final id = await repo.startSession(
      kind: PomodoroKind.foco,
      plannedMinutes: 25,
      startedAt: DateTime(2026, 11, 23, 9),
    );
    await repo.pauseSession(id, at: DateTime(2026, 11, 23, 9, 10));
    var s = (await repo.getRunning())!;
    expect(s.pausedAt, DateTime(2026, 11, 23, 9, 10));

    await repo.resumeSession(s, at: DateTime(2026, 11, 23, 9, 13));
    s = (await repo.getRunning())!;
    expect(s.pausedAt, isNull);
    expect(s.pausedTotalMs, 3 * 60 * 1000);

    await repo.pauseSession(id, at: DateTime(2026, 11, 23, 9, 20));
    await repo.resumeSession(
      (await repo.getRunning())!,
      at: DateTime(2026, 11, 23, 9, 22),
    );
    expect((await repo.getRunning())!.pausedTotalMs, 5 * 60 * 1000);
  });

  test('troca a tarefa da sessão', () async {
    final task = await tasks.createTask(title: 'T');
    final id = await repo.startSession(
      kind: PomodoroKind.foco,
      plannedMinutes: 25,
      startedAt: DateTime(2026, 11, 23, 9),
    );
    await repo.setSessionTask(id, task);
    expect((await repo.getRunning())!.taskId, task);
    await repo.setSessionTask(id, null);
    expect((await repo.getRunning())!.taskId, isNull);
  });

  test('sessões por período e exclusão', () async {
    final early = await repo.startSession(
      kind: PomodoroKind.foco,
      plannedMinutes: 25,
      startedAt: DateTime(2026, 11, 22, 23),
    );
    final today = await repo.startSession(
      kind: PomodoroKind.pausaCurta,
      plannedMinutes: 5,
      startedAt: DateTime(2026, 11, 23, 8),
    );

    var list = await repo
        .watchSessionsBetween(DateTime(2026, 11, 23), DateTime(2026, 11, 24))
        .first;
    expect(list.map((s) => s.id), [today]);

    await repo.deleteSession(today);
    list = await repo
        .watchSessionsBetween(DateTime(2026, 11, 22), DateTime(2026, 11, 24))
        .first;
    expect(list.map((s) => s.id), [early]);
  });
}
