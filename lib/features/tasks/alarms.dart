import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/notification_id.dart';
import '../../core/notifications.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../data/repositories/tasks_repository.dart';

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

/// Quanto o "Adiar" empurra o lembrete.
const snoozeDuration = Duration(minutes: 10);

/// Momento do lembrete da tarefa, ou `null` se ela não tem lembrete.
///
/// Com início com hora, a antecedência conta a partir do início (um bloco da
/// agenda avisa quando começa, não quando termina). Senão, a partir do prazo;
/// tarefa de dia inteiro usa [allDayHour] no dia do prazo.
DateTime? reminderTime(Task task, {int allDayHour = allDayReminderHour}) {
  final minutes = task.reminderMinutesBefore;
  if (minutes == null) return null;
  final start = task.hasTime ? task.startAt : null;
  final due = task.dueAt;
  final DateTime base;
  if (start != null) {
    base = start;
  } else if (due == null) {
    return null;
  } else {
    base = task.hasTime
        ? due
        : DateTime(due.year, due.month, due.day, allDayHour);
  }
  return base.subtract(Duration(minutes: minutes));
}

/// A tarefa precisa de lembrete (mesmo que o horário já tenha passado)?
bool wantsAlarm(Task task) =>
    task.deletedAt == null &&
    task.status != TaskStatus.feita &&
    reminderTime(task) != null;

/// Lembrete a agendar para a tarefa, ou `null` se não há ou já passou.
AlarmSpec? alarmFor(
  Task task,
  DateTime now, {
  int allDayHour = allDayReminderHour,
}) {
  if (!wantsAlarm(task)) return null;
  final time = reminderTime(task, allDayHour: allDayHour)!;
  return time.isAfter(now) ? _spec(task, time, now) : null;
}

AlarmSpec _spec(Task task, DateTime time, DateTime now) {
  final start = task.hasTime ? task.startAt : null;
  final due = task.dueAt;
  return AlarmSpec(
    id: notificationIdFor(task.id),
    time: time,
    title: task.title,
    body: start != null
        ? 'Começa: ${formatRelative(start, now, withTime: true)}'
              '${due != null && due.isAfter(start) ? ' até ${formatTime(due)}' : ''}'
        : due == null
        ? 'Lembrete'
        : 'Prazo: ${formatRelative(due, now, withTime: task.hasTime)}',
    payload: task.id,
    kind: task.reminderMode == ReminderMode.alarme
        ? AlarmKind.taskAlarm
        : AlarmKind.task,
  );
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

  Map<String, AlarmSpec> _scheduled = {};
  bool _initialized = false;
  Future<void> _queue = Future.value();
  List<Task>? _last;

  /// Hora do lembrete das tarefas de dia inteiro (ajuste).
  int get allDayHour => _allDayHour;
  int _allDayHour = allDayReminderHour;

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
    final desired = <String, AlarmSpec>{
      for (final task in tasks)
        task.id: ?alarmFor(task, now, allDayHour: _allDayHour),
    };

    if (!_initialized) {
      // Cancela o que sobrou de tarefas que não querem mais lembrete. Os de
      // tarefas que ainda querem, com horário passado, ficam (ex.: um "Adiar").
      final keep = {
        pomodoroNotificationId, // cuidado pelo controlador do pomodoro
        for (final task in tasks)
          if (wantsAlarm(task)) notificationIdFor(task.id),
      };
      for (final id in await _scheduler.pendingIds()) {
        if (!keep.contains(id)) await _scheduler.cancel(id);
      }
      for (final alarm in desired.values) {
        await _scheduler.schedule(alarm);
      }
      _initialized = true;
    } else {
      for (final MapEntry(key: taskId, value: alarm) in desired.entries) {
        if (_scheduled[taskId] != alarm) await _scheduler.schedule(alarm);
      }
      for (final MapEntry(key: taskId, value: alarm) in _scheduled.entries) {
        if (!desired.containsKey(taskId)) await _scheduler.cancel(alarm.id);
      }
    }
    _scheduled = desired;
  }
}

final alarmSchedulerProvider = Provider<AlarmScheduler>(
  (ref) => NotificationService.instance,
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
  ref.onDispose(subscription.cancel);
  ref.onDispose(hour.cancel);
  return sync;
});

/// Executa uma ação de notificação ("Concluir" ou "Adiar"). Usado pelo
/// isolate de segundo plano, que não tem o [AlarmSync] rodando, então
/// reagenda o lembrete da tarefa aqui mesmo.
Future<void> handleAlarmAction({
  required String? actionId,
  required String? taskId,
  required TasksRepository repo,
  required AlarmScheduler scheduler,
  required DateTime now,
  int allDayHour = allDayReminderHour,
}) async {
  if (taskId == null) return;
  final task = await repo.getTask(taskId);
  if (task == null) return;
  final id = notificationIdFor(task.id);

  switch (actionId) {
    case AlarmActions.complete:
      final updated = await repo.completeTask(task.id, now: now);
      final next = updated == null
          ? null
          : alarmFor(updated, now, allDayHour: allDayHour);
      if (next != null) {
        await scheduler.schedule(next);
      } else {
        await scheduler.cancel(id);
      }
    case AlarmActions.snooze:
      await scheduler.schedule(_spec(task, now.add(snoozeDuration), now));
  }
}
