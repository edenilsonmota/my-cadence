/// Agregações das métricas: foco, revisões e rotinas. Puro, sem Flutter.
library;

import '../../core/calendar_layout.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../pomodoro/pomodoro_logic.dart';

// ─── Períodos ────────────────────────────────────────────────────────────────

/// Agrupamento do gráfico de foco.
enum Bucket { dia, semana, mes }

/// Início do intervalo que contém [time] no agrupamento [bucket].
DateTime bucketStart(Bucket bucket, DateTime time) => switch (bucket) {
  Bucket.dia => startOfDay(time),
  Bucket.semana => weekStart(time),
  Bucket.mes => DateTime(time.year, time.month),
};

DateTime nextBucket(Bucket bucket, DateTime start) => switch (bucket) {
  Bucket.dia => addDays(start, 1),
  Bucket.semana => addDays(start, 7),
  Bucket.mes => DateTime(start.year, start.month + 1),
};

/// Os últimos [count] intervalos até o que contém [today], do mais antigo ao
/// atual.
List<DateTime> lastBuckets(Bucket bucket, DateTime today, int count) {
  var start = bucketStart(bucket, today);
  final result = [start];
  for (var i = 1; i < count; i++) {
    start = switch (bucket) {
      Bucket.dia => addDays(start, -1),
      Bucket.semana => addDays(start, -7),
      Bucket.mes => DateTime(start.year, start.month - 1),
    };
    result.add(start);
  }
  return result.reversed.toList();
}

// ─── Foco ────────────────────────────────────────────────────────────────────

Iterable<PomodoroSession> _focus(Iterable<PomodoroSession> sessions) =>
    sessions.where((s) => s.kind == PomodoroKind.foco);

/// Tempo de foco em cada intervalo de [buckets] (pela hora de início da
/// sessão, sem as pausas).
List<Duration> focusPerBucket(
  Iterable<PomodoroSession> sessions,
  Bucket bucket,
  List<DateTime> buckets,
  DateTime now,
) {
  final index = {for (final (i, b) in buckets.indexed) b: i};
  final totals = List.filled(buckets.length, Duration.zero);
  for (final s in _focus(sessions)) {
    final i = index[bucketStart(bucket, s.startedAt)];
    if (i != null) totals[i] += elapsed(s, now);
  }
  return totals;
}

/// Foco total das sessões iniciadas em `[from, to)`.
Duration focusBetween(
  Iterable<PomodoroSession> sessions,
  DateTime from,
  DateTime to,
  DateTime now,
) {
  var total = Duration.zero;
  for (final s in _focus(sessions)) {
    if (!s.startedAt.isBefore(from) && s.startedAt.isBefore(to)) {
      total += elapsed(s, now);
    }
  }
  return total;
}

/// Foco agrupado por uma chave da sessão ([keysOf] pode devolver várias,
/// como as tags; sem chave, cai em `null`). Ordena do maior para o menor.
List<({String? key, Duration total})> focusBy(
  Iterable<PomodoroSession> sessions,
  Iterable<String?> Function(PomodoroSession) keysOf,
  DateTime now,
) {
  final totals = <String?, Duration>{};
  for (final s in _focus(sessions)) {
    final time = elapsed(s, now);
    final keys = keysOf(s).toList();
    for (final key in keys.isEmpty ? [null] : keys) {
      totals[key] = (totals[key] ?? Duration.zero) + time;
    }
  }
  final list = [
    for (final MapEntry(:key, :value) in totals.entries)
      (key: key, total: value),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return list;
}

/// Tags que contam para o tempo de uma tarefa: as dela e as das tarefas
/// acima (subtarefa herda as tags da mãe). Uma tarefa com várias tags conta
/// o tempo inteiro em cada uma.
Set<String> tagsWithAncestors(
  String? taskId,
  Map<String, String?> parentOf,
  Map<String, Set<String>> tagsOf,
) {
  final result = <String>{};
  var current = taskId;
  var guard = 0;
  while (current != null && guard++ < 100) {
    result.addAll(tagsOf[current] ?? const {});
    current = parentOf[current];
  }
  return result;
}

typedef EstimateRow = ({Task task, Duration estimated, Duration done});

/// Tarefas com tempo estimado: estimado × foco feito (pomodoros e tempo
/// registrado à mão, somando as subtarefas), das mais recentes para as mais
/// antigas.
List<EstimateRow> estimatedVsDone(
  Iterable<Task> tasks,
  Iterable<PomodoroSession> sessions,
  DateTime now,
) {
  final parentOf = {for (final t in tasks) t.id: t.parentId};
  String? rootWithEstimate(String? id, Set<String> estimated) {
    var current = id;
    var guard = 0;
    while (current != null && guard++ < 100) {
      if (estimated.contains(current)) return current;
      current = parentOf[current];
    }
    return null;
  }

  final withEstimate = [
    for (final t in tasks)
      if ((t.estimatedMinutes ?? 0) > 0) t,
  ];
  final ids = {for (final t in withEstimate) t.id};
  final done = <String, Duration>{};
  for (final s in _focus(sessions)) {
    final root = rootWithEstimate(s.taskId, ids);
    if (root != null) {
      done[root] = (done[root] ?? Duration.zero) + elapsed(s, now);
    }
  }
  return [
    for (final t in withEstimate)
      (
        task: t,
        estimated: Duration(minutes: t.estimatedMinutes!),
        done: done[t.id] ?? Duration.zero,
      ),
  ]..sort((a, b) => b.task.createdAt.compareTo(a.task.createdAt));
}

// ─── Revisões ────────────────────────────────────────────────────────────────

/// Revisões por dia, para cada dia de [days].
List<int> reviewsPerDay(Iterable<ReviewLog> logs, List<DateTime> days) {
  final index = {for (final (i, d) in days.indexed) startOfDay(d): i};
  final counts = List.filled(days.length, 0);
  for (final log in logs) {
    final i = index[startOfDay(log.reviewedAt)];
    if (i != null) counts[i]++;
  }
  return counts;
}

/// Fração de revisões que não foram "Errei" (nota 1), ou `null` sem revisões.
double? accuracy(Iterable<ReviewLog> logs) {
  var total = 0, right = 0;
  for (final log in logs) {
    total++;
    if (log.rating > 1) right++;
  }
  return total == 0 ? null : right / total;
}

/// Cards a vencer em cada um dos próximos [days] dias a partir de [today].
/// Os já vencidos contam no primeiro dia. Ignora suspensos.
List<int> dueForecast(Iterable<Flashcard> cards, DateTime today, int days) {
  final counts = List.filled(days, 0);
  final start = startOfDay(today);
  for (final card in cards) {
    if (card.suspended) continue;
    final offset = startOfDay(card.due).difference(start).inHours / 24;
    final i = offset < 0 ? 0 : offset.round();
    if (i < days) counts[i]++;
  }
  return counts;
}

/// Dias seguidos com pelo menos uma revisão, terminando hoje (ou ontem, se
/// hoje ainda não teve revisão).
int studyStreak(Iterable<ReviewLog> logs, DateTime today) {
  final days = {for (final l in logs) startOfDay(l.reviewedAt)};
  var day = startOfDay(today);
  if (!days.contains(day)) day = addDays(day, -1);
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = addDays(day, -1);
  }
  return streak;
}

// ─── Rotinas ─────────────────────────────────────────────────────────────────

/// Grade do heatmap: [weeks] semanas (colunas, de segunda a domingo) até a
/// semana de [today]. Cada célula é o número de conclusões de rotina do dia
/// (apenas `concluida`); dias depois de hoje ficam `null`.
List<List<int?>> routineHeatmap(
  Iterable<TaskCompletion> completions,
  DateTime today,
  int weeks,
) => _routineGrid(
  completions.where((c) => c.status == OccurrenceStatus.concluida),
  today,
  weeks,
);

/// Mesma grade do heatmap contando ocorrências fechadas como `naoConcluida`.
List<List<int?>> routineMissedHeatmap(
  Iterable<TaskCompletion> completions,
  DateTime today,
  int weeks,
) => _routineGrid(
  completions.where((c) => c.status == OccurrenceStatus.naoConcluida),
  today,
  weeks,
);

List<List<int?>> _routineGrid(
  Iterable<TaskCompletion> completions,
  DateTime today,
  int weeks,
) {
  final counts = <DateTime, int>{};
  for (final c in completions) {
    final day = startOfDay(c.occurrence);
    counts[day] = (counts[day] ?? 0) + 1;
  }
  final last = startOfDay(today);
  final first = addDays(weekStart(today), -7 * (weeks - 1));
  return [
    for (var w = 0; w < weeks; w++)
      [
        for (var d = 0; d < 7; d++)
          switch (addDays(first, 7 * w + d)) {
            final day when day.isAfter(last) => null,
            final day => counts[day] ?? 0,
          },
      ],
  ];
}

/// Resumo de cumprimento de rotinas: concluídas, não concluídas e taxa (0..1).
({int done, int missed, double? rate}) routineSummary(
  Iterable<TaskCompletion> completions,
) {
  var done = 0, missed = 0;
  for (final c in completions) {
    if (c.status == OccurrenceStatus.naoConcluida) {
      missed++;
    } else {
      done++;
    }
  }
  final total = done + missed;
  return (done: done, missed: missed, rate: total == 0 ? null : done / total);
}

/// Primeiro dia da grade de [routineHeatmap].
DateTime heatmapStart(DateTime today, int weeks) =>
    addDays(weekStart(today), -7 * (weeks - 1));

// ─── Variação ────────────────────────────────────────────────────────────────

/// Variação de tempo entre o período atual e o anterior: "+15 min", "−1 h 05
/// min" ou "igual". `up` é `null` quando não mudou.
({String text, bool? up}) durationDelta(Duration current, Duration previous) {
  final diff = current - previous;
  if (diff.inMinutes == 0) return (text: 'igual', up: null);
  final abs = diff.abs();
  final h = abs.inHours, m = abs.inMinutes % 60;
  final value = h == 0 ? '$m min' : '$h h ${m.toString().padLeft(2, '0')} min';
  return (text: '${diff.isNegative ? '−' : '+'}$value', up: !diff.isNegative);
}

/// Variação de contagem: "+3", "−1" ou "igual".
({String text, bool? up}) countDelta(int current, int previous) {
  final diff = current - previous;
  if (diff == 0) return (text: 'igual', up: null);
  return (text: diff > 0 ? '+$diff' : '−${diff.abs()}', up: diff > 0);
}
