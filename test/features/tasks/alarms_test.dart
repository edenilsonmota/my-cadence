import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/notification_id.dart';
import 'package:my_cadence/core/notifications.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/tasks/alarms.dart';

import '../../data/test_db.dart';
import '../../helpers/fake_scheduler.dart';
import 'fixtures.dart';

final now = DateTime(2026, 11, 23, 10);

Task withReminder(
  String id, {
  required DateTime due,
  required int minutes,
  bool hasTime = true,
  TaskStatus status = TaskStatus.aFazer,
}) => makeTask(
  id,
  dueAt: due,
  hasTime: hasTime,
  status: status,
).copyWith(reminderMinutesBefore: Value(minutes));

void main() {
  group('alarmFor', () {
    test('com hora: prazo menos a antecedência', () {
      final alarm = alarmFor(
        withReminder('a', due: DateTime(2026, 11, 23, 15), minutes: 15),
        now,
      )!;
      expect(alarm.time, DateTime(2026, 11, 23, 14, 45));
      expect(alarm.id, notificationIdFor('a'));
      expect(alarm.payload, 'a');
      expect(alarm.body, 'Prazo: Hoje, 15:00');
      expect(alarm.kind, AlarmKind.task);
    });

    test('modo alarme agenda com AlarmKind.taskAlarm', () {
      final alarm = alarmFor(
        withReminder(
          'a',
          due: DateTime(2026, 11, 23, 15),
          minutes: 0,
        ).copyWith(reminderMode: ReminderMode.alarme),
        now,
      )!;
      expect(alarm.kind, AlarmKind.taskAlarm);
    });

    test('com início com hora: conta a partir do início', () {
      final alarm = alarmFor(
        makeTask(
          'a',
          startAt: DateTime(2026, 11, 23, 12),
          dueAt: DateTime(2026, 11, 23, 13),
          hasTime: true,
        ).copyWith(reminderMinutesBefore: const Value(10)),
        now,
      )!;
      expect(alarm.time, DateTime(2026, 11, 23, 11, 50));
      expect(alarm.body, 'Começa: Hoje, 12:00 até 13:00');
    });

    test('só início com hora (sem prazo) também lembra', () {
      final alarm = alarmFor(
        makeTask(
          'a',
          startAt: DateTime(2026, 11, 24, 8),
          hasTime: true,
        ).copyWith(reminderMinutesBefore: const Value(0)),
        now,
      )!;
      expect(alarm.time, DateTime(2026, 11, 24, 8));
      expect(alarm.body, 'Começa: Amanhã, 08:00');
    });

    test('dia inteiro com início ainda usa o prazo às 9h', () {
      final alarm = alarmFor(
        makeTask(
          'a',
          startAt: DateTime(2026, 11, 24),
          dueAt: DateTime(2026, 11, 26),
        ).copyWith(reminderMinutesBefore: const Value(0)),
        now,
      )!;
      expect(alarm.time, DateTime(2026, 11, 26, allDayReminderHour));
    });

    test('dia inteiro usa a hora padrão do lembrete', () {
      final alarm = alarmFor(
        withReminder(
          'a',
          due: DateTime(2026, 11, 25),
          minutes: 1440,
          hasTime: false,
        ),
        now,
      )!;
      expect(alarm.time, DateTime(2026, 11, 24, allDayReminderHour));
      expect(alarm.body, 'Prazo: qua, 25 nov');
    });

    test('sem lembrete, concluída ou no passado não agenda', () {
      expect(alarmFor(makeTask('a', dueAt: DateTime(2026, 12)), now), isNull);
      expect(
        alarmFor(
          withReminder(
            'a',
            due: DateTime(2026, 12),
            minutes: 0,
            status: TaskStatus.feita,
          ),
          now,
        ),
        isNull,
      );
      expect(
        alarmFor(
          withReminder('a', due: DateTime(2026, 11, 23, 9), minutes: 0),
          now,
        ),
        isNull,
      );
    });
  });

  group('AlarmSync', () {
    late FakeScheduler scheduler;
    late AlarmSync sync;

    setUp(() {
      scheduler = FakeScheduler();
      sync = AlarmSync(scheduler, clock: () => now);
    });

    test('mudar a hora do dia inteiro reagenda só esses lembretes', () async {
      final allDay = withReminder(
        'a',
        due: DateTime(2026, 11, 25),
        minutes: 0,
        hasTime: false,
      );
      final timed = withReminder(
        'b',
        due: DateTime(2026, 11, 25, 15),
        minutes: 0,
      );
      await sync.update([allDay, timed]);
      expect(
        scheduler.pending[notificationIdFor('a')]!.time,
        DateTime(2026, 11, 25, allDayReminderHour),
      );
      await sync.setAllDayHour(7);
      expect(
        scheduler.pending[notificationIdFor('a')]!.time,
        DateTime(2026, 11, 25, 7),
      );
      expect(
        scheduler.pending[notificationIdFor('b')]!.time,
        DateTime(2026, 11, 25, 15),
      );
    });

    test('ajuste inválido volta ao padrão', () {
      expect(parseAllDayHour(null), allDayReminderHour);
      expect(parseAllDayHour('25'), allDayReminderHour);
      expect(parseAllDayHour('6'), 6);
    });

    test('na abertura reagenda tudo e limpa o que sobrou', () async {
      // Sobras: de uma tarefa que não existe mais e um "adiar" ainda válido.
      await scheduler.schedule(
        AlarmSpec(id: 999, time: now, title: 'velha', body: '', payload: 'x'),
      );
      final snoozed = withReminder(
        'adiada',
        due: DateTime(2026, 11, 23, 9),
        minutes: 0,
      );
      await scheduler.schedule(alarmForSnooze(snoozed));
      final future = withReminder(
        'futura',
        due: DateTime(2026, 11, 23, 18),
        minutes: 30,
      );

      await sync.update([snoozed, future]);

      expect(
        scheduler.pending.keys,
        unorderedEquals([
          notificationIdFor('adiada'),
          notificationIdFor('futura'),
        ]),
      );
      expect(
        scheduler.pending[notificationIdFor('futura')]!.time,
        DateTime(2026, 11, 23, 17, 30),
      );
    });

    test('depois só mexe no que mudou', () async {
      final a = withReminder('a', due: DateTime(2026, 11, 24, 8), minutes: 0);
      final b = withReminder('b', due: DateTime(2026, 11, 24, 9), minutes: 0);
      await sync.update([a, b]);
      scheduler.log.clear();

      final movedB = b.copyWith(dueAt: Value(DateTime(2026, 11, 25, 9)));
      await sync.update([a, movedB]);
      expect(scheduler.log, ['schedule b ${DateTime(2026, 11, 25, 9)}']);

      scheduler.log.clear();
      await sync.update([movedB.copyWith(status: TaskStatus.feita)]);
      expect(
        scheduler.log,
        unorderedEquals([
          'cancel ${notificationIdFor('a')}',
          'cancel ${notificationIdFor('b')}',
        ]),
      );
      expect(scheduler.pending, isEmpty);
    });

    test('trocar entre notificação e alarme reagenda', () async {
      final a = withReminder('a', due: DateTime(2026, 11, 24, 8), minutes: 0);
      await sync.update([a]);
      expect(scheduler.pending[notificationIdFor('a')]!.kind, AlarmKind.task);
      scheduler.log.clear();

      await sync.update([a.copyWith(reminderMode: ReminderMode.alarme)]);
      expect(scheduler.log, hasLength(1));
      expect(
        scheduler.pending[notificationIdFor('a')]!.kind,
        AlarmKind.taskAlarm,
      );
    });
  });

  group('ações da notificação', () {
    late AppDatabase db;
    late TasksRepository repo;
    late FakeScheduler scheduler;

    setUp(() {
      db = openTestDb();
      repo = TasksRepository(db.tasksDao, db.tagsDao);
      scheduler = FakeScheduler();
    });

    test('Concluir avança a rotina e agenda o próximo lembrete', () async {
      final id = await repo.createTask(
        title: 'Remédio',
        kind: TaskKind.rotina,
        dueAt: DateTime(2026, 11, 23, 9),
        hasTime: true,
        recurrenceRule: 'FREQ=DAILY',
        reminderMinutesBefore: 0,
      );

      await handleAlarmAction(
        actionId: AlarmActions.complete,
        taskId: id,
        repo: repo,
        scheduler: scheduler,
        now: DateTime(2026, 11, 23, 9, 1),
      );

      final task = (await repo.getTask(id))!;
      expect(task.dueAt, DateTime(2026, 11, 24, 9));
      expect(task.status, TaskStatus.aFazer);
      expect(
        scheduler.pending[notificationIdFor(id)]!.time,
        DateTime(2026, 11, 24, 9),
      );
    });

    test('Concluir tarefa simples cancela o lembrete', () async {
      final id = await repo.createTask(
        title: 'Pagar conta',
        dueAt: DateTime(2026, 11, 23, 9),
        hasTime: true,
        reminderMinutesBefore: 0,
      );
      await scheduler.schedule(
        AlarmSpec(
          id: notificationIdFor(id),
          time: now,
          title: '',
          body: '',
          payload: id,
        ),
      );

      await handleAlarmAction(
        actionId: AlarmActions.complete,
        taskId: id,
        repo: repo,
        scheduler: scheduler,
        now: now,
      );

      expect((await repo.getTask(id))!.status, TaskStatus.feita);
      expect(scheduler.pending, isEmpty);
    });

    test('Adiar reagenda 10 minutos depois sem mudar a tarefa', () async {
      final id = await repo.createTask(
        title: 'Ligar',
        dueAt: DateTime(2026, 11, 23, 10),
        hasTime: true,
        reminderMinutesBefore: 0,
      );

      await handleAlarmAction(
        actionId: AlarmActions.snooze,
        taskId: id,
        repo: repo,
        scheduler: scheduler,
        now: now,
      );

      final alarm = scheduler.pending[notificationIdFor(id)]!;
      expect(alarm.time, now.add(snoozeDuration));
      expect(alarm.title, 'Ligar');
      expect(alarm.kind, AlarmKind.task);
      expect((await repo.getTask(id))!.dueAt, DateTime(2026, 11, 23, 10));
    });

    test('Adiar tarefa em modo alarme mantém AlarmKind.taskAlarm', () async {
      final id = await repo.createTask(
        title: 'Acordar',
        dueAt: DateTime(2026, 11, 23, 10),
        hasTime: true,
        reminderMinutesBefore: 0,
        reminderMode: ReminderMode.alarme,
      );

      await handleAlarmAction(
        actionId: AlarmActions.snooze,
        taskId: id,
        repo: repo,
        scheduler: scheduler,
        now: now,
      );

      expect(
        scheduler.pending[notificationIdFor(id)]!.kind,
        AlarmKind.taskAlarm,
      );
    });

    test('tarefa excluída é ignorada', () async {
      final id = await repo.createTask(title: 'x');
      await repo.deleteTask(id);
      await handleAlarmAction(
        actionId: AlarmActions.complete,
        taskId: id,
        repo: repo,
        scheduler: scheduler,
        now: now,
      );
      expect(scheduler.log, isEmpty);
    });
  });
}

/// Lembrete "adiado" de uma tarefa cujo horário original já passou.
AlarmSpec alarmForSnooze(Task task) => AlarmSpec(
  id: notificationIdFor(task.id),
  time: now.add(snoozeDuration),
  title: task.title,
  body: '',
  payload: task.id,
);
