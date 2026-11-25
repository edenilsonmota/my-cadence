import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/locale_providers.dart';
import '../../app/l10n/locale_settings.dart';
import '../../core/dates.dart';
import '../../core/notification_id.dart';
import '../../core/notifications.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../data/repositories/tasks_repository.dart';
import 'alarm_diagnostics.dart';
import 'reminder_offsets.dart';

/// Hora padrão do lembrete de tarefas de dia inteiro (sem hora própria).
/// A pessoa muda em Ajustes ([allDayReminderHourKey]).
const allDayReminderHour = 9;

/// Ajuste da hora do lembrete de dia inteiro (sincroniza entre aparelhos).
const allDayReminderHourKey = 'tasks.allDayReminderHour';

/// Lê o ajuste; inválido ou ausente vira [allDayReminderHour].
int parseAllDayHour(String? value) {
  final h = int.tryParse(value ?? '');
  return h == null || h < 0 || h > 23 ? allDayReminderHour : h;
}

/// Quanto o "Adiar 10 min" e o "Adiar 1 h" empurram o lembrete.
const snoozeDuration = Duration(minutes: 10);
const snoozeLongDuration = Duration(hours: 1);

/// Amanhã cedo: amanhã na hora configurada para lembretes de dia inteiro.
DateTime tomorrowMorningAt(
  DateTime now, {
  int allDayHour = allDayReminderHour,
}) => DateTime(now.year, now.month, now.day + 1, allDayHour);

/// Horário base de referência dos lembretes da tarefa, ou `null` se sem data.
///
/// Com início com hora, conta a partir do início (bloco da agenda avisa ao
/// começar). Senão, a partir do prazo; dia inteiro usa [allDayHour].
DateTime? reminderBaseTime(Task task, {int allDayHour = allDayReminderHour}) {
  final start = task.hasTime ? task.startAt : null;
  final due = task.dueAt;
  if (start != null) return start;
  if (due == null) return null;
  return task.hasTime
      ? due
      : DateTime(due.year, due.month, due.day, allDayHour);
}

/// Momento do primeiro lembrete da tarefa, ou `null` se ela não tem lembrete.
DateTime? reminderTime(Task task, {int allDayHour = allDayReminderHour}) {
  final offsets = effectiveReminderOffsets(task);
  if (offsets.isEmpty) return null;
  final base = reminderBaseTime(task, allDayHour: allDayHour);
  if (base == null) return null;
  return base.subtract(Duration(minutes: offsets.first));
}

/// A tarefa precisa de lembrete (mesmo que o horário já tenha passado)?
bool wantsAlarm(Task task) =>
    task.deletedAt == null &&
    task.status != TaskStatus.feita &&
    effectiveReminderOffsets(task).isNotEmpty &&
    reminderBaseTime(task) != null;

/// Todos os IDs de notificação que podem pertencer a [task] (lembrete principal,
/// extras e repetições de insistência).
Set<int> allNotificationIdsForTask(Task task) {
  final offsets = effectiveReminderOffsets(task);
  return {
    notificationIdFor(task.id),
    for (final (i, minutes) in offsets.indexed)
      taskReminderNotificationId(task.id, minutes, primary: i == 0),
    for (var step = 1; step <= maxNagRepeats; step++)
      taskNagNotificationId(task.id, step),
  };
}

/// Todos os lembretes futuros a agendar para [task]: todas as antecedências
/// configuradas + até [maxNagRepeats] repetições de insistência se ativado.
List<AlarmSpec> alarmsForTask(
  Task task,
  DateTime now, {
  int allDayHour = allDayReminderHour,
  String lang = 'pt',
}) {
  if (!wantsAlarm(task)) return const [];
  final base = reminderBaseTime(task, allDayHour: allDayHour);
  if (base == null) return const [];
  final offsets = effectiveReminderOffsets(task);
  final specs = <AlarmSpec>[];

  for (final (index, minutes) in offsets.indexed) {
    final time = base.subtract(Duration(minutes: minutes));
    if (!time.isAfter(now)) continue;
    specs.add(
      _spec(
        task,
        time,
        now,
        id: taskReminderNotificationId(task.id, minutes, primary: index == 0),
        lang: lang,
      ),
    );
  }

  final nagMinutes = normalizeNagInterval(task.nagIntervalMinutes);
  if (nagMinutes != null) {
    for (var step = 1; step <= maxNagRepeats; step++) {
      final nagTime = base.add(Duration(minutes: nagMinutes * step));
      if (!nagTime.isAfter(now)) continue;
      specs.add(
        _spec(
          task,
          nagTime,
          now,
          id: taskNagNotificationId(task.id, step),
          isNag: true,
          lang: lang,
        ),
      );
    }
  }
  return specs;
}

/// Primeiro lembrete futuro a agendar para a tarefa, ou `null` se não há.
AlarmSpec? alarmFor(
  Task task,
  DateTime now, {
  int allDayHour = allDayReminderHour,
  String lang = 'pt',
}) {
  final list = alarmsForTask(task, now, allDayHour: allDayHour, lang: lang);
  return list.isEmpty ? null : list.first;
}

AlarmSpec _spec(
  Task task,
  DateTime time,
  DateTime now, {
  int? id,
  bool isNag = false,
  String lang = 'pt',
}) {
  final start = task.hasTime ? task.startAt : null;
  final due = task.dueAt;
  final body = isNag
      ? switch (lang) {
          'en' => 'Overdue · tap to complete or snooze',
          'es' => 'Atrasada · toca para completar o posponer',
          _ => 'Atrasada · toque para concluir ou adiar',
        }
      : start != null
      ? '${switch (lang) {
              'en' => 'Starts',
              'es' => 'Empieza',
              _ => 'Começa',
            }}: ${formatRelative(start, now, withTime: true, lang: lang)}'
            '${due != null && due.isAfter(start) ? ' ${switch (lang) {
                    'en' => 'to',
                    'es' => 'a',
                    _ => 'até',
                  }} ${formatTime(due)}' : ''}'
      : due == null
      ? switch (lang) {
          'en' => 'Reminder',
          'es' => 'Recordatorio',
          _ => 'Lembrete',
        }
      : '${switch (lang) {
          'en' => 'Due',
          'es' => 'Plazo',
          _ => 'Prazo',
        }}: ${formatRelative(due, now, withTime: task.hasTime, lang: lang)}';

  return AlarmSpec(
    id: id ?? notificationIdFor(task.id),
    time: time,
    title: task.title,
    body: body,
    payload: task.id,
    kind: task.reminderMode == ReminderMode.alarme
        ? AlarmKind.taskAlarm
        : AlarmKind.task,
    lang: lang,
  );
}

/// Reagenda o lembrete da tarefa para [targetTime] e cancela repetições de
/// insistência pendentes desta ocorrência.
Future<void> snoozeTaskAlarm({
  required Task task,
  required DateTime targetTime,
  required DateTime now,
  required AlarmScheduler scheduler,
  String lang = 'pt',
}) async {
  for (var step = 1; step <= maxNagRepeats; step++) {
    await scheduler.cancel(taskNagNotificationId(task.id, step));
  }
  await scheduler.schedule(_spec(task, targetTime, now, lang: lang));
}

/// Mantém os lembretes agendados iguais ao que as tarefas pedem.
///
/// Recebe a lista de tarefas vivas a cada mudança no banco, então qualquer
/// criação, edição, conclusão, exclusão ou "desfazer" reagenda sozinha. Na
/// primeira lista (abertura do app) reagenda tudo, porque alguns aparelhos
/// perdem os alarmes no reboot.
class AlarmSync {
  AlarmSync(this._scheduler, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AlarmScheduler _scheduler;
  final DateTime Function() _clock;

  Map<int, AlarmSpec> _scheduled = {};
  bool _initialized = false;
  Future<void> _queue = Future.value();
  List<Task>? _last;

  /// Hora do lembrete das tarefas de dia inteiro (ajuste).
  int get allDayHour => _allDayHour;
  int _allDayHour = allDayReminderHour;

  /// Idioma do texto e dos botões das notificações.
  String _lang = 'pt';

  /// Muda o idioma e reagenda os lembretes com o texto novo.
  Future<void> setLang(String lang) async {
    if (lang == _lang) return;
    _lang = lang;
    if (_last case final tasks?) await update(tasks);
  }

  /// Muda a hora e reagenda os lembretes de dia inteiro.
  Future<void> setAllDayHour(int hour) async {
    if (hour == _allDayHour) return;
    _allDayHour = hour;
    if (_last case final tasks?) await update(tasks);
  }

  /// Enfileira a lista (as aplicações rodam uma de cada vez, em ordem).
  Future<void> update(List<Task> tasks) {
    _last = tasks;
    return _queue = _queue.then((_) => _apply(tasks)).catchError((Object _) {});
  }

  /// Esquece o que foi agendado e reagenda tudo na próxima lista.
  void reset() => _initialized = false;

  Future<void> _apply(List<Task> tasks) async {
    final now = _clock();
    final desired = <int, AlarmSpec>{};
    for (final task in tasks) {
      for (final alarm in alarmsForTask(
        task,
        now,
        allDayHour: _allDayHour,
        lang: _lang,
      )) {
        desired[alarm.id] = alarm;
      }
    }

    if (!_initialized) {
      // Cancela o que sobrou de tarefas que não querem mais lembrete. Os de
      // tarefas que ainda querem, com horário passado, ficam (ex.: um "Adiar").
      final keep = {
        pomodoroNotificationId, // cuidado pelo controlador do pomodoro
        dailyReviewNotificationId, // cuidado pelo DailyReminderSync
        dailySummaryNotificationId, // cuidado pelo DailyReminderSync
        for (final task in tasks)
          if (wantsAlarm(task)) ...allNotificationIdsForTask(task),
      };
      for (final id in await _scheduler.pendingIds()) {
        if (!keep.contains(id)) await _scheduler.cancel(id);
      }
      for (final alarm in desired.values) {
        await _scheduler.schedule(alarm);
      }
      _initialized = true;
    } else {
      for (final MapEntry(key: id, value: alarm) in desired.entries) {
        if (_scheduled[id] != alarm) await _scheduler.schedule(alarm);
      }
      for (final id in _scheduled.keys) {
        if (!desired.containsKey(id)) await _scheduler.cancel(id);
      }
    }
    _scheduled = desired;
  }
}

final alarmSchedulerProvider = Provider<AlarmScheduler>(
  (ref) => NotificationService.instance,
);

/// Diagnóstico atual de permissões e canais de alarme do aparelho.
final alarmDiagnosticsProvider = FutureProvider.autoDispose<AlarmDiagnostics>(
  (ref) => ref.watch(alarmSchedulerProvider).getDiagnostics(),
);

/// Liga o [AlarmSync] às tarefas do banco. Basta ler uma vez (em `main`).
final alarmSyncProvider = Provider<AlarmSync>((ref) {
  final sync = AlarmSync(ref.watch(alarmSchedulerProvider));
  final subscription = ref
      .watch(tasksRepositoryProvider)
      .watchAllTasks()
      .listen(sync.update);
  final hour = ref
      .watch(settingsRepositoryProvider)
      .watchString(allDayReminderHourKey)
      .listen((v) => sync.setAllDayHour(parseAllDayHour(v)));
  sync.setLang(langOfLocale(ref.read(appLocaleProvider)));
  ref.listen(appLocaleProvider, (_, next) => sync.setLang(langOfLocale(next)));
  ref.onDispose(subscription.cancel);
  ref.onDispose(hour.cancel);
  return sync;
});

/// Código do idioma efetivo para textos fora da árvore de widgets.
String langOfLocale(AppLocale locale) => resolveLangCode(
  locale,
  systemCode: PlatformDispatcher.instance.locale.languageCode,
);

/// Executa uma ação de notificação ("Concluir", "Adiar 10 min" ou "Adiar 1 h").
/// Usado pelo isolate de segundo plano, que não tem o [AlarmSync] rodando,
/// então reagenda ou cancela os lembretes da tarefa aqui mesmo.
Future<void> handleAlarmAction({
  required String? actionId,
  required String? taskId,
  required TasksRepository repo,
  required AlarmScheduler scheduler,
  required DateTime now,
  int allDayHour = allDayReminderHour,
  String lang = 'pt',
}) async {
  if (taskId == null) return;
  final task = await repo.getTask(taskId);
  if (task == null) return;

  switch (actionId) {
    case AlarmActions.complete:
      final oldIds = allNotificationIdsForTask(task);
      final updated = await repo.completeTask(task.id, now: now);
      final nextAlarms = updated == null
          ? const <AlarmSpec>[]
          : alarmsForTask(updated, now, allDayHour: allDayHour, lang: lang);
      final nextIds = {for (final a in nextAlarms) a.id};
      for (final id in oldIds) {
        if (!nextIds.contains(id)) await scheduler.cancel(id);
      }
      for (final alarm in nextAlarms) {
        await scheduler.schedule(alarm);
      }
    case AlarmActions.snooze:
      await snoozeTaskAlarm(
        task: task,
        targetTime: now.add(snoozeDuration),
        now: now,
        scheduler: scheduler,
        lang: lang,
      );
    case AlarmActions.snooze1h:
      await snoozeTaskAlarm(
        task: task,
        targetTime: now.add(snoozeLongDuration),
        now: now,
        scheduler: scheduler,
        lang: lang,
      );
  }
}
