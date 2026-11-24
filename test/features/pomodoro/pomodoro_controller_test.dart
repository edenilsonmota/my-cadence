import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/clock.dart';
import 'package:my_cadence/core/notification_id.dart';
import 'package:my_cadence/core/notifications.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/providers.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/pomodoro/pomodoro_controller.dart';
import 'package:my_cadence/features/pomodoro/pomodoro_logic.dart';
import 'package:my_cadence/features/tasks/alarms.dart';

import '../../data/test_db.dart';
import '../../helpers/fake_scheduler.dart';

/// Deixa o banco e as consultas observadas responderem.
Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late AppDatabase db;
  late FakeScheduler scheduler;
  late DateTime now;

  /// Um "app aberto": container novo sobre o mesmo banco.
  ProviderContainer openApp() {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        alarmSchedulerProvider.overrideWithValue(scheduler),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    // Mantém o controlador vivo e lendo o banco.
    container.listen(pomodoroControllerProvider, (_, _) {});
    return container;
  }

  PomodoroController controllerOf(ProviderContainer c) =>
      c.read(pomodoroControllerProvider.notifier);

  AlarmSpec? endAlarm() => scheduler.pending[pomodoroNotificationId];

  Future<List<PomodoroSession>> allSessions() =>
      PomodoroRepository(db.pomodoroDao)
          .watchSessionsBetween(DateTime(2000), DateTime(2100))
          .first;

  setUp(() {
    db = openTestDb();
    scheduler = FakeScheduler();
    now = DateTime(2026, 11, 23, 9);
  });

  test('iniciar grava a sessão e agenda a notificação do fim', () async {
    final app = openApp();
    await flush();
    final task = await TasksRepository(
      db.tasksDao,
      db.tagsDao,
    ).createTask(title: 'Estudar');

    await controllerOf(app).start(PomodoroKind.foco, taskId: task);
    await flush();

    final running = app.read(pomodoroControllerProvider).running!;
    expect(running.kind, PomodoroKind.foco);
    expect(running.plannedMinutes, 25);
    expect(running.taskId, task);
    expect(endAlarm()!.time, DateTime(2026, 11, 23, 9, 25));
    expect(endAlarm()!.kind, AlarmKind.pomodoro);
    expect(endAlarm()!.payload, pomodoroPayload);
  });

  test('pausar cancela o aviso; retomar reagenda empurrando o fim', () async {
    final app = openApp();
    await flush();
    final c = controllerOf(app);
    await c.start(PomodoroKind.foco);
    await flush();

    now = DateTime(2026, 11, 23, 9, 10);
    await c.pause();
    await flush();
    expect(app.read(pomodoroControllerProvider).isPaused, isTrue);
    expect(endAlarm(), isNull);

    now = DateTime(2026, 11, 23, 9, 17); // 7 min pausado
    await c.resume();
    await flush();
    expect(app.read(pomodoroControllerProvider).isPaused, isFalse);
    expect(endAlarm()!.time, DateTime(2026, 11, 23, 9, 32));
  });

  test('parar registra como interrompida e cancela o aviso', () async {
    final app = openApp();
    await flush();
    await controllerOf(app).start(PomodoroKind.foco);
    await flush();
    now = DateTime(2026, 11, 23, 9, 5);

    await controllerOf(app).stop();
    await flush();

    expect(app.read(pomodoroControllerProvider).running, isNull);
    expect(app.read(pomodoroControllerProvider).finished, isNull);
    expect(endAlarm(), isNull);
    final session = (await allSessions()).single;
    expect(session.completed, isFalse);
    expect(session.endedAt, DateTime(2026, 11, 23, 9, 5));
  });

  test('fechar e reabrir no meio do foco mantém o tempo certo', () async {
    final first = openApp();
    await flush();
    await controllerOf(first).start(PomodoroKind.foco);
    await flush();
    first.dispose(); // app fechado

    now = DateTime(2026, 11, 23, 9, 15);
    scheduler.pending.clear(); // ex.: alarmes perdidos num reboot
    final reopened = openApp();
    await flush();

    final running = reopened.read(pomodoroControllerProvider).running!;
    expect(remaining(running, now), const Duration(minutes: 10));
    expect(endAlarm()!.time, DateTime(2026, 11, 23, 9, 25)); // reagendado
  });

  test('reabrir depois do fim fecha a sessão no horário certo', () async {
    final first = openApp();
    await flush();
    await controllerOf(first).start(PomodoroKind.foco);
    await flush();
    first.dispose();

    now = DateTime(2026, 11, 23, 11); // bem depois das 9h25
    final reopened = openApp();
    await flush();
    await flush();

    final state = reopened.read(pomodoroControllerProvider);
    expect(state.running, isNull);
    expect(state.finished!.kind, PomodoroKind.foco);
    expect(state.suggestedNext, PomodoroKind.pausaCurta);
    final session = (await allSessions()).single;
    expect(session.completed, isTrue);
    expect(session.endedAt, DateTime(2026, 11, 23, 9, 25));
  });

  test('o quarto foco sugere pausa longa', () async {
    final pomodoro = PomodoroRepository(db.pomodoroDao);
    for (var i = 0; i < 3; i++) {
      final id = await pomodoro.startSession(
        kind: PomodoroKind.foco,
        plannedMinutes: 25,
        startedAt: DateTime(2026, 11, 23, 6 + i),
      );
      await pomodoro.finishSession(
        id,
        endedAt: DateTime(2026, 11, 23, 6 + i, 25),
        completed: true,
      );
    }
    final app = openApp();
    await flush();
    await controllerOf(app).start(PomodoroKind.foco);
    await flush();

    now = DateTime(2026, 11, 23, 9, 25);
    await controllerOf(app).checkDue();
    await flush();

    expect(
      app.read(pomodoroControllerProvider).suggestedNext,
      PomodoroKind.pausaLonga,
    );
  });

  test('com "iniciar pausas sozinho", a pausa começa ao fim do foco', () async {
    await SettingsRepository(db.settingsDao)
        .setString(PomodoroSettings.keyAutoBreaks, 'true');
    await SettingsRepository(db.settingsDao)
        .setString(PomodoroSettings.keyShortBreak, '7');
    final app = openApp();
    await flush();
    await controllerOf(app).start(PomodoroKind.foco);
    await flush();

    now = DateTime(2026, 11, 23, 9, 25);
    await controllerOf(app).checkDue();
    await flush();

    final state = app.read(pomodoroControllerProvider);
    expect(state.finished!.kind, PomodoroKind.foco); // aviso continua
    expect(state.running!.kind, PomodoroKind.pausaCurta);
    expect(state.running!.plannedMinutes, 7);
    expect(endAlarm()!.time, DateTime(2026, 11, 23, 9, 32));
  });

  test('iniciar com outra sessão rodando interrompe a anterior', () async {
    final app = openApp();
    await flush();
    await controllerOf(app).start(PomodoroKind.foco);
    await flush();
    now = DateTime(2026, 11, 23, 9, 3);

    await controllerOf(app).start(PomodoroKind.pausaCurta);
    await flush();

    final sessions = await allSessions();
    expect(sessions, hasLength(2));
    expect(sessions.first.completed, isFalse);
    expect(sessions.first.endedAt, DateTime(2026, 11, 23, 9, 3));
    expect(
      app.read(pomodoroControllerProvider).running!.kind,
      PomodoroKind.pausaCurta,
    );
  });
}
