import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import 'task_appearance.dart';
import 'task_lists.dart';
import 'task_metrics.dart';

/// Dia atual (meia-noite local), atualizado sozinho na virada do dia.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    _scheduleMidnight();
    return startOfDay(DateTime.now());
  }

  void _scheduleMidnight() {
    final now = DateTime.now();
    final tomorrow = addDays(startOfDay(now), 1);
    _timer = Timer(tomorrow.difference(now) + const Duration(seconds: 1), () {
      state = startOfDay(DateTime.now());
      _scheduleMidnight();
    });
  }
}

// ─── Hoje ────────────────────────────────────────────────────────────────────

final overdueTasksProvider = StreamProvider.autoDispose<List<Task>>(
  (ref) =>
      ref.watch(tasksRepositoryProvider).watchOverdue(ref.watch(todayProvider)),
);

final todayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(tasksRepositoryProvider)
      .watchTasksDueBetween(today, addDays(today, 1))
      // Pausada sai do Hoje (volta quando for retomada).
      .map((ts) => sortToday(ts.where((t) => t.status != TaskStatus.pausada)));
});

final undatedTasksProvider = StreamProvider.autoDispose<List<Task>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchUndatedRoots(),
);

// ─── Tarefas ─────────────────────────────────────────────────────────────────

final allTasksProvider = StreamProvider.autoDispose<List<Task>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchAllTasks(),
);

final tagsProvider = StreamProvider.autoDispose<List<Tag>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchTags(),
);

final tagIdsByTaskProvider =
    StreamProvider.autoDispose<Map<String, Set<String>>>(
      (ref) => ref.watch(tasksRepositoryProvider).watchTagIdsByTask(),
    );

final taskFilterProvider = NotifierProvider<TaskFilterNotifier, TaskFilter>(
  TaskFilterNotifier.new,
);

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void update(TaskFilter Function(TaskFilter) change) => state = change(state);

  /// Limpa filtros e busca, mantendo a ordenação escolhida.
  void clear() => state = TaskFilter(sort: state.sort);
}

/// Árvore da aba Tarefas, já filtrada e ordenada.
final taskTreeProvider = Provider.autoDispose<AsyncValue<List<TaskNode>>>((
  ref,
) {
  final tasks = ref.watch(allTasksProvider);
  final tags = ref.watch(tagIdsByTaskProvider);
  final filter = ref.watch(taskFilterProvider);
  return switch ((tasks, tags)) {
    (AsyncData(value: final t), AsyncData(value: final m)) => AsyncData(
      buildTaskTree(t, filter, m),
    ),
    (AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});

// ─── Uma tarefa ──────────────────────────────────────────────────────────────

final taskProvider = StreamProvider.autoDispose.family<Task?, String>(
  (ref, id) => ref.watch(tasksRepositoryProvider).watchTask(id),
);

final subtasksProvider = StreamProvider.autoDispose.family<List<Task>, String>(
  (ref, id) => ref.watch(tasksRepositoryProvider).watchSubtasks(id),
);

final taskTagsProvider = StreamProvider.autoDispose.family<List<Tag>, String>(
  (ref, id) => ref.watch(tasksRepositoryProvider).watchTagsOfTask(id),
);

/// Conclusões de rotina, da mais recente para a mais antiga.
final completionsProvider = StreamProvider.autoDispose
    .family<List<TaskCompletion>, String>(
      (ref, id) => ref.watch(tasksRepositoryProvider).watchCompletions(id),
    );

// ─── Aparência (cor e ícone com herança) ─────────────────────────────────────

/// Resolve cor e ícone de qualquer tarefa (tarefa → mãe → 1ª tag → tipo).
final appearanceResolverProvider = Provider.autoDispose<AppearanceResolver>((
  ref,
) {
  final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
  final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
  final links = ref.watch(tagIdsByTaskProvider).value ?? const {};
  return AppearanceResolver(
    tasks: tasks,
    firstTagColor: {
      for (final MapEntry(key: taskId, value: ids) in links.entries)
        if (tags.where((t) => ids.contains(t.id)).firstOrNull case final tag?)
          taskId: tag.colorKey,
    },
    validColors: {for (final k in PaletteKey.values) k.name},
    validIcons: {for (final i in IconCatalog.all) i.key},
  );
});

// ─── Métricas do item (subtarefas, cards vencidos, foco) ─────────────────────

final _allSessionsProvider = StreamProvider.autoDispose<List<PomodoroSession>>(
  (ref) => ref
      .watch(pomodoroRepositoryProvider)
      .watchSessionsBetween(DateTime(2000), DateTime(2100)),
);

final _allCardsForMetricsProvider = StreamProvider.autoDispose<List<Flashcard>>(
  (ref) => ref.watch(cardsRepositoryProvider).watchCards(),
);

final taskMetricsProvider = Provider.autoDispose<Map<String, TaskMetrics>>((
  ref,
) {
  return computeTaskMetrics(
    tasks: ref.watch(allTasksProvider).value ?? const [],
    cards: ref.watch(_allCardsForMetricsProvider).value ?? const [],
    sessions: ref.watch(_allSessionsProvider).value ?? const [],
    now: ref.watch(clockProvider)(),
  );
});
