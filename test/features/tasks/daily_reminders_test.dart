import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/notification_id.dart';
import 'package:my_cadence/core/notifications.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/cards/review_queue.dart';
import 'package:my_cadence/features/tasks/daily_reminders.dart';

import '../../helpers/fake_scheduler.dart';
import 'fixtures.dart';

Flashcard makeCard(
  String id, {
  required DateTime due,
  DateTime? lastReview,
  bool suspended = false,
}) => Flashcard(
  id: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  dirty: true,
  front: 'F $id',
  back: 'B $id',
  state: lastReview == null ? CardState.learning : CardState.review,
  due: due,
  lastReview: lastReview,
  suspended: suspended,
);

void main() {
  final now = DateTime(2026, 11, 23, 10);

  group('DailyReminderSettings', () {
    test('parseia defaults e ignora horas inválidas', () {
      final defaults = DailyReminderSettings.fromMap(const {});
      expect(defaults.reviewEnabled, isFalse);
      expect(defaults.reviewHour, 19);
      expect(defaults.summaryEnabled, isFalse);
      expect(defaults.summaryHour, 8);

      final custom = DailyReminderSettings.fromMap(const {
        DailyReminderSettings.keyReviewEnabled: 'true',
        DailyReminderSettings.keyReviewHour: '21',
        DailyReminderSettings.keySummaryEnabled: 'true',
        DailyReminderSettings.keySummaryHour: '99',
      });
      expect(custom.reviewEnabled, isTrue);
      expect(custom.reviewHour, 21);
      expect(custom.summaryEnabled, isTrue);
      expect(custom.summaryHour, 8);
    });
  });

  group('dailyReviewAlarm', () {
    test('não avisa quando desligado ou com zero cards vencidos', () {
      expect(
        dailyReviewAlarm(
          settings: const DailyReminderSettings(reviewEnabled: false),
          cards: [makeCard('c1', due: DateTime(2026, 11, 23, 9))],
          cardSettings: const CardSettings(),
          newStudiedToday: 0,
          now: now,
        ),
        isNull,
      );

      expect(
        dailyReviewAlarm(
          settings: const DailyReminderSettings(
            reviewEnabled: true,
            reviewHour: 19,
          ),
          cards: [makeCard('c1', due: DateTime(2026, 11, 25))],
          cardSettings: const CardSettings(),
          newStudiedToday: 0,
          now: now,
        ),
        isNull,
      );
    });

    test('agenda para hoje quando ainda não passou e conta cards vencidos', () {
      final alarm = dailyReviewAlarm(
        settings: const DailyReminderSettings(
          reviewEnabled: true,
          reviewHour: 19,
        ),
        cards: [
          makeCard('c1', due: DateTime(2026, 11, 23, 12)),
          makeCard('c2', due: DateTime(2026, 11, 23, 18)),
          makeCard('c3', due: DateTime(2026, 11, 24, 12)),
        ],
        cardSettings: const CardSettings(),
        newStudiedToday: 0,
        now: now,
      )!;
      expect(alarm.id, dailyReviewNotificationId);
      expect(alarm.time, DateTime(2026, 11, 23, 19));
      expect(alarm.title, '2 cards para revisar');
      expect(alarm.payload, dailyReviewPayload);
      expect(alarm.kind, AlarmKind.dailyDigest);
    });

    test(
      'se a hora de hoje já passou, agenda para amanhã zerando limite de novos',
      () {
        final lateNow = DateTime(2026, 11, 23, 21);
        final alarm = dailyReviewAlarm(
          settings: const DailyReminderSettings(
            reviewEnabled: true,
            reviewHour: 19,
          ),
          cards: [makeCard('c1', due: DateTime(2026, 11, 23, 9))],
          cardSettings: const CardSettings(newPerDay: 1),
          newStudiedToday: 1, // limite de hoje já atingido, amanhã zera!
          now: lateNow,
        )!;
        expect(alarm.time, DateTime(2026, 11, 24, 19));
        expect(alarm.title, '1 card para revisar');
      },
    );
  });

  group('dailySummaryAlarm', () {
    test('conta tarefas de hoje e atrasadas e omite se ambas forem zero', () {
      final none = dailySummaryAlarm(
        settings: const DailyReminderSettings(
          summaryEnabled: true,
          summaryHour: 12,
        ),
        tasks: [
          makeTask('fut', dueAt: DateTime(2026, 11, 26)),
          makeTask(
            'feita',
            dueAt: DateTime(2026, 11, 23),
            status: TaskStatus.feita,
          ),
        ],
        now: now,
      );
      expect(none, isNull);

      final alarm = dailySummaryAlarm(
        settings: const DailyReminderSettings(
          summaryEnabled: true,
          summaryHour: 12,
        ),
        tasks: [
          makeTask('atrasada', dueAt: DateTime(2026, 11, 20)),
          makeTask('hoje1', dueAt: DateTime(2026, 11, 23)),
          makeTask('hoje2', dueAt: DateTime(2026, 11, 23, 16), hasTime: true),
        ],
        now: now,
      )!;
      expect(alarm.id, dailySummaryNotificationId);
      expect(alarm.time, DateTime(2026, 11, 23, 12));
      expect(alarm.title, 'Resumo do dia');
      expect(alarm.body, '2 para hoje · 1 atrasada');
      expect(alarm.payload, dailySummaryPayload);
    });
  });

  group('DailyReminderSync', () {
    test('reagenda ao ligar/mudar dados e cancela quando zera', () async {
      final scheduler = FakeScheduler();
      final sync = DailyReminderSync(scheduler, clock: () => now);

      await sync.update(
        settings: const DailyReminderSettings(
          reviewEnabled: true,
          reviewHour: 19,
          summaryEnabled: true,
          summaryHour: 12,
        ),
        cards: [makeCard('c1', due: DateTime(2026, 11, 23, 9))],
        tasks: [makeTask('t1', dueAt: DateTime(2026, 11, 23))],
      );
      expect(
        scheduler.pending.keys,
        unorderedEquals([
          dailyReviewNotificationId,
          dailySummaryNotificationId,
        ]),
      );

      // Conclui a tarefa e revisa todos os cards → ambos cancelados.
      await sync.update(
        cards: [makeCard('c1', due: DateTime(2026, 11, 30))],
        tasks: [
          makeTask(
            't1',
            dueAt: DateTime(2026, 11, 23),
            status: TaskStatus.feita,
          ),
        ],
      );
      expect(scheduler.pending, isEmpty);
    });
  });
}
