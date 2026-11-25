import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/nav_tabs.dart';
import 'package:my_cadence/app/notification_navigation.dart';
import 'package:my_cadence/core/notification_id.dart';
import 'package:my_cadence/core/notifications.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/tasks/alarm_diagnostics.dart';
import 'package:my_cadence/features/tasks/alarms.dart';
import 'package:my_cadence/features/tasks/reminder_offsets.dart';
import 'package:my_cadence/features/tasks/task_draft.dart';

import '../../data/test_db.dart';
import '../../helpers/fake_scheduler.dart';
import 'fixtures.dart';

void main() {
  final now = DateTime(2026, 11, 23, 10);

  group('AlarmDiagnostics (Fase 2)', () {
    test('detecta bloqueio conforme o modo de lembrete', () {
      const ok = AlarmDiagnostics.allGood;
      expect(ok.hasAnyIssue, isFalse);
      expect(ok.hasBlockingIssueFor(ReminderMode.notificacao), isFalse);
      expect(ok.hasBlockingIssueFor(ReminderMode.alarme), isFalse);

      const mutedAlarms = AlarmDiagnostics(alarmsChannelMuted: true);
      expect(
        mutedAlarms.hasBlockingIssueFor(ReminderMode.notificacao),
        isFalse,
      );
      expect(mutedAlarms.hasBlockingIssueFor(ReminderMode.alarme), isTrue);

      const mutedReminders = AlarmDiagnostics(remindersChannelMuted: true);
      expect(
        mutedReminders.hasBlockingIssueFor(ReminderMode.notificacao),
        isTrue,
      );
      expect(mutedReminders.hasBlockingIssueFor(ReminderMode.alarme), isFalse);

      const noNotif = AlarmDiagnostics(
        notificationsEnabled: false,
        batteryOptimizationIgnored: false,
      );
      expect(noNotif.issueCount, 2);
      expect(noNotif.hasBlockingIssueFor(ReminderMode.notificacao), isTrue);
      expect(noNotif.hasBlockingIssueFor(ReminderMode.alarme), isTrue);
    });
  });

  group('Adiar com opções (Fase 3)', () {
    test('Adiar 1 h reagenda 1 hora depois e cancela insistências', () async {
      final db = openTestDb();
      addTearDown(db.close);
      final repo = TasksRepository(db.tasksDao, db.tagsDao);
      final scheduler = FakeScheduler();

      final id = await repo.createTask(
        title: 'Enviar relatório',
        dueAt: DateTime(2026, 11, 23, 10),
        hasTime: true,
        reminderMinutesBefore: 0,
        reminderOffsets: '0',
        nagIntervalMinutes: 10,
      );
      // Simula nags já agendados.
      for (var step = 1; step <= maxNagRepeats; step++) {
        await scheduler.schedule(
          AlarmSpec(
            id: taskNagNotificationId(id, step),
            time: now.add(Duration(minutes: 10 * step)),
            title: 'Enviar relatório',
            body: '',
            payload: id,
          ),
        );
      }

      await handleAlarmAction(
        actionId: AlarmActions.snooze1h,
        taskId: id,
        repo: repo,
        scheduler: scheduler,
        now: now,
      );

      expect(scheduler.pending.keys, [notificationIdFor(id)]);
      expect(
        scheduler.pending[notificationIdFor(id)]!.time,
        now.add(snoozeLongDuration),
      );
    });

    test('tomorrowMorningAt usa a hora configurada para dia inteiro', () {
      expect(
        tomorrowMorningAt(DateTime(2026, 11, 23, 18, 45), allDayHour: 8),
        DateTime(2026, 11, 24, 8),
      );
    });
  });

  group('Vários lembretes por tarefa (Fase 5)', () {
    test('parseReminderOffsets ordena, deduplica e descarta inválidos', () {
      expect(parseReminderOffsets('1440, 0, 15, 0, -5, abc'), [0, 15, 1440]);
      expect(parseReminderOffsets(null), isEmpty);
      expect(encodeReminderOffsets([60, 0, 60]), '0,60');
      expect(encodeReminderOffsets([]), isNull);
    });

    test('alarmsForTask agenda um alarme por antecedência com IDs únicos', () {
      final task =
          makeTask(
            't1',
            dueAt: DateTime(2026, 11, 25, 14),
            hasTime: true,
          ).copyWith(
            reminderMinutesBefore: const Value(0),
            reminderOffsets: const Value('0,30,1440'),
          );

      final alarms = alarmsForTask(task, now);
      expect(alarms, hasLength(3));
      expect(alarms.map((a) => a.time), [
        DateTime(2026, 11, 25, 14),
        DateTime(2026, 11, 25, 13, 30),
        DateTime(2026, 11, 24, 14),
      ]);
      // Todos os IDs são distintos e o primeiro mantém compatibilidade.
      final ids = alarms.map((a) => a.id).toSet();
      expect(ids, hasLength(3));
      expect(alarms.first.id, notificationIdFor('t1'));
    });

    test('TaskDraft preserva múltiplos lembretes e limpa se sem data', () {
      final draft = TaskDraft(
        title: 'Prova',
        dueDate: DateTime(2026, 11, 26),
        reminderOffsets: {0, 1440},
        nagIntervalMinutes: 15,
      );
      final fields = draft.toFields(now);
      expect(fields.reminderOffsets, '0,1440');
      expect(fields.reminderMinutesBefore, 0);
      expect(fields.nagIntervalMinutes, 15);

      draft.dueDate = null;
      final withoutDate = draft.toFields(now);
      expect(withoutDate.reminderOffsets, isNull);
      expect(withoutDate.reminderMinutesBefore, isNull);
      expect(withoutDate.nagIntervalMinutes, isNull);
    });
  });

  group('Insistir se atrasar (Fase 6)', () {
    test('agenda até maxNagRepeats repetições após o horário', () {
      final task =
          makeTask(
            'nag1',
            dueAt: DateTime(2026, 11, 23, 12),
            hasTime: true,
          ).copyWith(
            reminderMinutesBefore: const Value(0),
            reminderOffsets: const Value('0'),
            nagIntervalMinutes: const Value(15),
          );

      final alarms = alarmsForTask(task, now);
      // 1 lembrete na hora + 5 repetições a cada 15 min.
      expect(alarms, hasLength(1 + maxNagRepeats));
      expect(alarms.first.time, DateTime(2026, 11, 23, 12));
      expect(alarms[1].time, DateTime(2026, 11, 23, 12, 15));
      expect(alarms.last.time, DateTime(2026, 11, 23, 13, 15));
      expect(alarms[1].body, contains('Atrasada'));
    });

    test(
      'AlarmSync cancela todas as insistências ao concluir a tarefa',
      () async {
        final scheduler = FakeScheduler();
        final sync = AlarmSync(scheduler, clock: () => now);
        final task =
            makeTask(
              'nag2',
              dueAt: DateTime(2026, 11, 23, 12),
              hasTime: true,
            ).copyWith(
              reminderMinutesBefore: const Value(0),
              reminderOffsets: const Value('0,10'),
              nagIntervalMinutes: const Value(10),
            );

        await sync.update([task]);
        expect(scheduler.pending, hasLength(2 + maxNagRepeats));

        await sync.update([task.copyWith(status: TaskStatus.feita)]);
        expect(scheduler.pending, isEmpty);
      },
    );

    test(
      'AlarmSync preserva notificações de avisos diários na abertura',
      () async {
        final scheduler = FakeScheduler();
        await scheduler.schedule(
          AlarmSpec(
            id: dailyReviewNotificationId,
            time: now.add(const Duration(hours: 2)),
            title: '5 cards para revisar',
            body: '',
            payload: dailyReviewPayload,
            kind: AlarmKind.dailyDigest,
          ),
        );
        await scheduler.schedule(
          AlarmSpec(
            id: dailySummaryNotificationId,
            time: now.add(const Duration(hours: 1)),
            title: 'Resumo do dia',
            body: '',
            payload: dailySummaryPayload,
            kind: AlarmKind.dailyDigest,
          ),
        );
        final sync = AlarmSync(scheduler, clock: () => now);
        await sync.update(const []);
        expect(
          scheduler.pending.keys,
          unorderedEquals([
            dailyReviewNotificationId,
            dailySummaryNotificationId,
          ]),
        );
      },
    );
  });

  group('Deep links dos avisos diários', () {
    test('dailyReviewPayload e dailySummaryPayload respeitam a barra', () {
      expect(
        NotificationNavigator.routeFor(
          dailyReviewPayload,
          navTabs: const [NavTab.today, NavTab.tasks, NavTab.review],
        ),
        NavTab.review.tabRoute,
      );
      expect(
        NotificationNavigator.routeFor(
          dailyReviewPayload,
          navTabs: const [NavTab.today, NavTab.tasks, NavTab.agenda],
        ),
        NavTab.review.overlayRoute,
      );
      expect(
        NotificationNavigator.routeFor(
          dailySummaryPayload,
          navTabs: const [NavTab.tasks, NavTab.agenda, NavTab.review],
        ),
        NavTab.today.overlayRoute,
      );
    });
  });
}
