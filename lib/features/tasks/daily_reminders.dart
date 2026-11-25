/// Cálculo puro dos avisos diários opcionais (revisão de cards e resumo do dia).
/// Puro, sem Flutter.
library;

import '../../core/dates.dart';
import '../../core/notification_id.dart';
import '../../core/notifications.dart';
import '../../data/db/database.dart';
import '../cards/review_queue.dart';

/// Preferências dos avisos diários (prefixo `reminders.` → sincroniza entre
/// aparelhos).
class DailyReminderSettings {
  const DailyReminderSettings({
    this.reviewEnabled = false,
    this.reviewHour = 19,
    this.summaryEnabled = false,
    this.summaryHour = 8,
  });

  factory DailyReminderSettings.fromMap(Map<String, String> map) {
    const d = DailyReminderSettings();
    return DailyReminderSettings(
      reviewEnabled: map[keyReviewEnabled] == 'true',
      reviewHour: _parseHour(map[keyReviewHour], d.reviewHour),
      summaryEnabled: map[keySummaryEnabled] == 'true',
      summaryHour: _parseHour(map[keySummaryHour], d.summaryHour),
    );
  }

  static const prefix = 'reminders.';
  static const keyReviewEnabled = 'reminders.dailyReviewEnabled';
  static const keyReviewHour = 'reminders.dailyReviewHour';
  static const keySummaryEnabled = 'reminders.dailySummaryEnabled';
  static const keySummaryHour = 'reminders.dailySummaryHour';

  final bool reviewEnabled;
  final int reviewHour;
  final bool summaryEnabled;
  final int summaryHour;

  @override
  bool operator ==(Object other) =>
      other is DailyReminderSettings &&
      other.reviewEnabled == reviewEnabled &&
      other.reviewHour == reviewHour &&
      other.summaryEnabled == summaryEnabled &&
      other.summaryHour == summaryHour;

  @override
  int get hashCode =>
      Object.hash(reviewEnabled, reviewHour, summaryEnabled, summaryHour);
}

int _parseHour(String? raw, int fallback) {
  final h = int.tryParse(raw ?? '');
  return h == null || h < 0 || h > 23 ? fallback : h;
}

/// Próxima ocorrência futura de [hour]:00 a partir de [now] (hoje se ainda
/// não passou, senão amanhã).
DateTime nextDailyTime(DateTime now, int hour) {
  final todayAt = DateTime(now.year, now.month, now.day, hour);
  return todayAt.isAfter(now) ? todayAt : addDays(todayAt, 1);
}

/// Aviso diário "N cards para revisar", ou `null` se desligado ou se não há
/// cards vencidos no próximo horário de disparo (não avisa com zero).
AlarmSpec? dailyReviewAlarm({
  required DailyReminderSettings settings,
  required List<Flashcard> cards,
  required CardSettings cardSettings,
  required int newStudiedToday,
  required DateTime now,
  String lang = 'pt',
}) {
  if (!settings.reviewEnabled) return null;
  final target = nextDailyTime(now, settings.reviewHour);
  final studiedForTarget = isSameDay(target, now) ? newStudiedToday : 0;
  final due = buildQueue(
    cards,
    target,
    newPerDay: cardSettings.newPerDay,
    newStudiedToday: studiedForTarget,
  ).length;
  if (due == 0) return null;

  final title = switch (lang) {
    'en' => due == 1 ? '1 card to review' : '$due cards to review',
    'es' => due == 1 ? '1 tarjeta para repasar' : '$due tarjetas para repasar',
    _ => due == 1 ? '1 card para revisar' : '$due cards para revisar',
  };
  final body = switch (lang) {
    'en' => 'Tap to start your review session.',
    'es' => 'Toca para empezar tu sesión de repaso.',
    _ => 'Toque para abrir a revisão.',
  };

  return AlarmSpec(
    id: dailyReviewNotificationId,
    time: target,
    title: title,
    body: body,
    payload: dailyReviewPayload,
    kind: AlarmKind.dailyDigest,
  );
}

/// Resumo diário de tarefas (hoje e atrasadas), ou `null` se desligado ou se
/// não há nenhuma tarefa para hoje nem atrasada no próximo horário de disparo.
AlarmSpec? dailySummaryAlarm({
  required DailyReminderSettings settings,
  required List<Task> tasks,
  required DateTime now,
  String lang = 'pt',
}) {
  if (!settings.summaryEnabled) return null;
  final target = nextDailyTime(now, settings.summaryHour);
  final targetDay = startOfDay(target);
  final nextDay = addDays(targetDay, 1);

  var overdue = 0;
  var todayCount = 0;
  for (final task in tasks) {
    if (task.deletedAt != null || !task.status.isActive) continue;
    final due = task.dueAt;
    if (due == null) continue;
    if (due.isBefore(targetDay)) {
      overdue++;
    } else if (due.isBefore(nextDay)) {
      todayCount++;
    }
  }
  if (overdue == 0 && todayCount == 0) return null;

  final title = switch (lang) {
    'en' => 'Daily summary',
    'es' => 'Resumen del día',
    _ => 'Resumo do dia',
  };
  final parts = <String>[
    if (todayCount > 0)
      switch (lang) {
        'en' => '$todayCount for today',
        'es' => '$todayCount para hoy',
        _ => '$todayCount para hoje',
      },
    if (overdue > 0)
      switch (lang) {
        'en' => '$overdue overdue',
        'es' => overdue == 1 ? '1 atrasada' : '$overdue atrasadas',
        _ => overdue == 1 ? '1 atrasada' : '$overdue atrasadas',
      },
  ];
  return AlarmSpec(
    id: dailySummaryNotificationId,
    time: target,
    title: title,
    body: parts.join(' · '),
    payload: dailySummaryPayload,
    kind: AlarmKind.dailyDigest,
  );
}

/// Mantém os avisos diários sincronizados com os dados e preferências.
class DailyReminderSync {
  DailyReminderSync(this._scheduler, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AlarmScheduler _scheduler;
  final DateTime Function() _clock;

  DailyReminderSettings _settings = const DailyReminderSettings();
  CardSettings _cardSettings = const CardSettings();
  List<Task> _tasks = const [];
  List<Flashcard> _cards = const [];
  int _newStudiedToday = 0;
  String _lang = 'pt';

  AlarmSpec? _scheduledReview;
  AlarmSpec? _scheduledSummary;
  bool _initialized = false;
  Future<void> _queue = Future.value();

  void reset() => _initialized = false;

  Future<void> update({
    DailyReminderSettings? settings,
    CardSettings? cardSettings,
    List<Task>? tasks,
    List<Flashcard>? cards,
    int? newStudiedToday,
    String? lang,
  }) {
    if (lang != null) _lang = lang;
    if (settings != null) _settings = settings;
    if (cardSettings != null) _cardSettings = cardSettings;
    if (tasks != null) _tasks = tasks;
    if (cards != null) _cards = cards;
    if (newStudiedToday != null) _newStudiedToday = newStudiedToday;
    return _queue = _queue.then((_) => _apply()).catchError((Object _) {});
  }

  Future<void> _apply() async {
    final now = _clock();
    final review = dailyReviewAlarm(
      settings: _settings,
      cards: _cards,
      cardSettings: _cardSettings,
      newStudiedToday: _newStudiedToday,
      now: now,
      lang: _lang,
    );
    final summary = dailySummaryAlarm(
      settings: _settings,
      tasks: _tasks,
      now: now,
      lang: _lang,
    );

    Future<void> syncOne(int id, AlarmSpec? desired, AlarmSpec? current) async {
      if (desired == null) {
        if (!_initialized || current != null) await _scheduler.cancel(id);
      } else if (!_initialized || current != desired) {
        await _scheduler.schedule(desired);
      }
    }

    await syncOne(dailyReviewNotificationId, review, _scheduledReview);
    await syncOne(dailySummaryNotificationId, summary, _scheduledSummary);
    _scheduledReview = review;
    _scheduledSummary = summary;
    _initialized = true;
  }
}
