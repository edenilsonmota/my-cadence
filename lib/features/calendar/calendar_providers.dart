import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
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

/// Cor (ARGB) da primeira tag de cada tarefa, na ordem alfabética das tags.
final tagColorByTaskProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final tags = ref.watch(tagsProvider).value ?? const [];
  final links = ref.watch(tagIdsByTaskProvider).value ?? const {};
  return {
    for (final MapEntry(key: taskId, value: ids) in links.entries)
      if (tags.where((t) => ids.contains(t.id)).firstOrNull case final tag?)
        taskId: tag.color,
  };
});

/// Cor do bloco: a da tarefa, senão a da primeira tag, senão a do tipo.
Color entryColor(Task task, Map<String, int> tagColors) => Color(
  task.color ??
      tagColors[task.id] ??
      switch (task.kind) {
        TaskKind.simples => 0xFF1E88E5,
        TaskKind.estudo => 0xFF8E24AA,
        TaskKind.rotina => 0xFF43A047,
        TaskKind.evento => 0xFFF4511E,
      },
);

/// Cor do título sobre o fundo claro do bloco, legível nos dois temas.
Color entryTextColor(Color base, Brightness brightness) =>
    brightness == Brightness.dark
    ? Color.lerp(base, Colors.white, 0.45)!
    : Color.lerp(base, Colors.black, 0.35)!;

/// Fundo do bloco: a cor bem clara sobre a superfície.
Color entryBackground(Color base, ColorScheme scheme) => Color.alphaBlend(
  base.withValues(alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.16),
  scheme.surface,
);
