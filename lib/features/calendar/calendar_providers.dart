import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../tasks/task_appearance.dart';
import '../tasks/task_providers.dart';
import 'calendar_entries.dart';

enum CalendarMode { dia, semana, mes }

/// Ajustes da agenda em `AppSettings`, com prefixo `calendar.`.
class CalendarSettings {
  const CalendarSettings({
    this.mode = CalendarMode.semana,
    this.showPomodoros = false,
  });

  factory CalendarSettings.fromMap(Map<String, String> map) => CalendarSettings(
    mode: CalendarMode.values.asNameMap()[map[modeKey]] ?? CalendarMode.semana,
    showPomodoros: map[pomodorosKey] == 'true',
  );

  static const prefix = 'calendar.';
  static const modeKey = 'calendar.mode';
  static const pomodorosKey = 'calendar.pomodoros';

  final CalendarMode mode;

  /// Camada "Pomodoros realizados".
  final bool showPomodoros;
}

final calendarSettingsProvider = StreamProvider<CalendarSettings>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchPrefix(CalendarSettings.prefix)
      .map(CalendarSettings.fromMap),
);

/// Dia em foco na agenda (o "hoje" até o usuário navegar).
final calendarDayProvider = NotifierProvider<CalendarDayNotifier, DateTime>(
  CalendarDayNotifier.new,
);

class CalendarDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => ref.watch(todayProvider);

  void show(DateTime day) => state = DateTime(day.year, day.month, day.day);
}

typedef DateRange = ({DateTime from, DateTime to});

final _tasksInRangeProvider = StreamProvider.autoDispose
    .family<List<Task>, DateRange>(
      (ref, r) =>
          ref.watch(tasksRepositoryProvider).watchTasksInRange(r.from, r.to),
    );

final _completionsInRangeProvider = StreamProvider.autoDispose
    .family<List<TaskCompletion>, DateRange>(
      (ref, r) => ref
          .watch(tasksRepositoryProvider)
          .watchCompletionsBetween(r.from, r.to),
    );

/// Entradas do calendário em `[from, to)`, já com as ocorrências das rotinas.
final calendarEntriesProvider = Provider.autoDispose
    .family<AsyncValue<List<CalendarEntry>>, DateRange>((ref, r) {
      final tasks = ref.watch(_tasksInRangeProvider(r));
      final completions = ref.watch(_completionsInRangeProvider(r));
      return switch ((tasks, completions)) {
        (AsyncData(value: final t), AsyncData(value: final c)) => AsyncData(
          expandOccurrences(t, r.from, r.to, completions: c),
        ),
        (AsyncError(:final error, :final stackTrace), _) ||
        (
          _,
          AsyncError(:final error, :final stackTrace),
        ) => AsyncError(error, stackTrace),
        _ => const AsyncLoading(),
      };
    });

/// Sessões de foco iniciadas em `[from, to)` (camada de pomodoros).
final focusSessionsProvider = StreamProvider.autoDispose
    .family<List<PomodoroSession>, DateRange>(
      (ref, r) => ref
          .watch(pomodoroRepositoryProvider)
          .watchSessionsBetween(r.from, r.to)
          .map(
            (list) => [
              for (final s in list)
                if (s.kind == PomodoroKind.foco) s,
            ],
          ),
    );

/// Tons da tarefa no calendário (cor resolvida: tarefa, mãe, tag, tipo).
Tones entryTones(BuildContext context, Task task, AppearanceResolver r) =>
    context.palette.byName(r.colorKeyOf(task));

/// Ícone resolvido da tarefa.
IconData entryIcon(Task task, AppearanceResolver r) => AppIcons.of(
  r.iconKeyOf(task),
  fallback: AppIcons.taskDefault(repeats: task.recurrenceRule != null),
);
