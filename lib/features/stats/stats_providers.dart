import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../tasks/task_providers.dart';
import 'stats_logic.dart';

/// Quantos intervalos o gráfico de foco mostra em cada agrupamento.
const bucketCount = {Bucket.dia: 14, Bucket.semana: 12, Bucket.mes: 12};

/// Semanas do heatmap de rotinas (cabe em 360 dp).
const heatmapWeeks = 17;

/// Agrupamento escolhido no gráfico de foco.
final statsBucketProvider = NotifierProvider<StatsBucketNotifier, Bucket>(
  StatsBucketNotifier.new,
);

class StatsBucketNotifier extends Notifier<Bucket> {
  @override
  Bucket build() => Bucket.dia;

  void set(Bucket b) => state = b;
}

enum FocusGroup { tarefa, tag }

final focusGroupProvider = NotifierProvider<FocusGroupNotifier, FocusGroup>(
  FocusGroupNotifier.new,
);

class FocusGroupNotifier extends Notifier<FocusGroup> {
  @override
  FocusGroup build() => FocusGroup.tarefa;

  void set(FocusGroup g) => state = g;
}

/// Sessões dos últimos 12 meses (cobre todos os agrupamentos).
final statsSessionsProvider = StreamProvider.autoDispose<List<PomodoroSession>>(
  (ref) {
    final today = ref.watch(todayProvider);
    return ref
        .watch(pomodoroRepositoryProvider)
        .watchSessionsBetween(
          DateTime(today.year, today.month - 11),
          addDays(today, 1),
        );
  },
);

/// Revisões do último ano (gráfico, taxa de acerto e sequência).
final statsReviewLogsProvider = StreamProvider.autoDispose<List<ReviewLog>>((
  ref,
) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(cardsRepositoryProvider)
      .watchReviewLogsSince(addDays(today, -365));
});

final statsCardsProvider = StreamProvider.autoDispose<List<Flashcard>>(
  (ref) => ref.watch(cardsRepositoryProvider).watchCards(),
);

/// Conclusões de rotina no período do heatmap.
final statsCompletionsProvider =
    StreamProvider.autoDispose<List<TaskCompletion>>((ref) {
      final today = ref.watch(todayProvider);
      return ref
          .watch(tasksRepositoryProvider)
          .watchCompletionsBetween(
            heatmapStart(today, heatmapWeeks),
            addDays(today, 1),
          );
    });
