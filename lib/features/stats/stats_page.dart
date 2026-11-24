import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../tasks/hub/hub_stats.dart' show formatDuration;
import '../tasks/task_labels.dart';
import '../tasks/task_providers.dart';
import 'stats_logic.dart';
import 'stats_providers.dart';

/// Métricas: foco, revisões e rotinas.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métricas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          _FocusSection(),
          _FocusBySection(),
          _EstimateSection(),
          _ReviewSection(),
          _RoutineSection(),
        ],
      ),
    );
  }
}

// ─── Peças comuns ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Número em destaque com legenda.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card.filled(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium!
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// Gráfico de barras simples: um valor por rótulo, com dica ao tocar.
class _Bars extends StatelessWidget {
  const _Bars({
    required this.values,
    required this.labels,
    required this.tooltip,
    this.labelEvery = 1,
    this.integers = false,
    this.semanticLabel,
  });

  final List<double> values;
  final List<String> labels;

  /// Texto da dica da barra `i`.
  final String Function(int i) tooltip;

  /// Mostra um rótulo a cada N barras (os demais ficam vazios).
  final int labelEvery;

  /// Contagens: o eixo só mostra números inteiros.
  final bool integers;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = values.fold<double>(0, math.max);
    final small = Theme.of(context).textTheme.labelSmall!
        .copyWith(color: scheme.onSurfaceVariant);
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: maxValue == 0 ? 1 : maxValue * 1.15,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 4,
                    // O topo (máximo com folga) fica sem rótulo.
                    child: Text(
                      value == meta.max ||
                              (integers && value != value.roundToDouble())
                          ? ''
                          : _axisLabel(value),
                      style: small,
                    ),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    final show =
                        i >= 0 &&
                        i < labels.length &&
                        (labels.length - 1 - i) % labelEvery == 0;
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(show ? labels[i] : '', style: small),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItem: (group, _, _, _) => BarTooltipItem(
                  tooltip(group.x),
                  TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                ),
              ),
            ),
            barGroups: [
              for (final (i, v) in values.indexed)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: v,
                      color: scheme.primary,
                      width: math.max(4, math.min(18, 220 / values.length)),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "2", "1,5" (vírgula decimal, sem zeros sobrando).
String _axisLabel(double v) {
  if (v == v.roundToDouble()) return '${v.toInt()}';
  return v.toStringAsFixed(1).replaceAll('.', ',');
}

/// Linha com rótulo, barra proporcional e valor.
class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(value, style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: fraction.clamp(0, 1).toDouble(),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

// ─── Foco ────────────────────────────────────────────────────────────────────

class _FocusSection extends ConsumerWidget {
  const _FocusSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(statsSessionsProvider).value ?? const [];
    final bucket = ref.watch(statsBucketProvider);
    final today = ref.watch(todayProvider);
    final now = ref.watch(clockProvider)();

    final buckets = lastBuckets(bucket, today, bucketCount[bucket]!);
    final totals = focusPerBucket(sessions, bucket, buckets, now);
    Duration total(Bucket b) {
      final start = bucketStart(b, today);
      return focusBetween(sessions, start, nextBucket(b, start), now);
    }

    String label(DateTime start) => switch (bucket) {
      Bucket.dia => '${start.day}',
      Bucket.semana => '${start.day}/${start.month}',
      Bucket.mes => monthShort[start.month - 1],
    };
    String tip(int i) {
      final start = buckets[i];
      final when = switch (bucket) {
        Bucket.dia => formatDate(start, today),
        Bucket.semana => 'Semana de ${start.day}/${two(start.month)}',
        Bucket.mes => '${monthShort[start.month - 1]} ${start.year}',
      };
      return '$when\n${formatDuration(totals[i])}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Tempo de foco'),
        Row(
          children: [
            _Stat(value: formatDuration(total(Bucket.dia)), label: 'Hoje'),
            _Stat(
              value: formatDuration(total(Bucket.semana)),
              label: 'Esta semana',
            ),
            _Stat(value: formatDuration(total(Bucket.mes)), label: 'Este mês'),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<Bucket>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: Bucket.dia, label: Text('Dias')),
            ButtonSegment(value: Bucket.semana, label: Text('Semanas')),
            ButtonSegment(value: Bucket.mes, label: Text('Meses')),
          ],
          selected: {bucket},
          onSelectionChanged: (s) =>
              ref.read(statsBucketProvider.notifier).set(s.single),
        ),
        const SizedBox(height: 12),
        Text(
          'Horas de foco por ${switch (bucket) {
            Bucket.dia => 'dia',
            Bucket.semana => 'semana',
            Bucket.mes => 'mês',
          }}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        _Bars(
          values: [for (final t in totals) t.inMinutes / 60],
          labels: [for (final b in buckets) label(b)],
          labelEvery: bucket == Bucket.mes ? 2 : 3,
          tooltip: tip,
          semanticLabel: 'Gráfico de horas de foco',
        ),
      ],
    );
  }
}

class _FocusBySection extends ConsumerWidget {
  const _FocusBySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(statsSessionsProvider).value ?? const [];
    final bucket = ref.watch(statsBucketProvider);
    final group = ref.watch(focusGroupProvider);
    final today = ref.watch(todayProvider);
    final now = ref.watch(clockProvider)();
    final tasks = {
      for (final t in ref.watch(allTasksProvider).value ?? const <Task>[])
        t.id: t,
    };
    final tags = {
      for (final t in ref.watch(tagsProvider).value ?? const <Tag>[]) t.id: t,
    };
    final links = ref.watch(tagIdsByTaskProvider).value ?? const {};

    // Mesmo período do gráfico acima.
    final from = lastBuckets(bucket, today, bucketCount[bucket]!).first;
    final inPeriod = [
      for (final s in sessions)
        if (!s.startedAt.isBefore(from)) s,
    ];
    final rows = focusBy(inPeriod, (s) {
      final id = s.taskId;
      return switch (group) {
        FocusGroup.tarefa => [id],
        FocusGroup.tag => id == null ? const [] : (links[id] ?? const {}),
        FocusGroup.tipo => [if (tasks[id] case final t?) t.kind.name],
      };
    }, now);

    String name(String? key) => switch (group) {
      FocusGroup.tarefa when key == null => 'Sem tarefa',
      FocusGroup.tarefa => tasks[key]?.title ?? 'Tarefa excluída',
      FocusGroup.tag when key == null => 'Sem tag',
      FocusGroup.tag => tags[key]?.name ?? 'Tag excluída',
      FocusGroup.tipo when key == null => 'Sem tarefa',
      FocusGroup.tipo =>
        [
              for (final t in tasks.values)
                if (t.kind.name == key) t.kind.label,
            ].firstOrNull ??
            key!,
    };

    final top = rows.take(8).toList();
    final max = top.isEmpty ? Duration.zero : top.first.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Foco por'),
        SegmentedButton<FocusGroup>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: FocusGroup.tarefa, label: Text('Tarefa')),
            ButtonSegment(value: FocusGroup.tag, label: Text('Tag')),
            ButtonSegment(value: FocusGroup.tipo, label: Text('Tipo')),
          ],
          selected: {group},
          onSelectionChanged: (s) =>
              ref.read(focusGroupProvider.notifier).set(s.single),
        ),
        const SizedBox(height: 8),
        if (top.isEmpty)
          const _Empty('Nenhum foco no período.')
        else
          for (final r in top)
            _ShareRow(
              label: name(r.key),
              value: formatDuration(r.total),
              fraction: max == Duration.zero
                  ? 0
                  : r.total.inSeconds / max.inSeconds,
            ),
      ],
    );
  }
}

class _EstimateSection extends ConsumerWidget {
  const _EstimateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(statsSessionsProvider).value ?? const [];
    final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
    final rows = estimatedVsDone(tasks, sessions).take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Pomodoros: estimado × realizado'),
        if (rows.isEmpty)
          const _Empty('Nenhuma tarefa com pomodoros estimados.')
        else
          for (final r in rows)
            _ShareRow(
              label: r.task.title,
              value: '${r.done} de ${r.estimated}',
              fraction: r.done / r.estimated,
            ),
      ],
    );
  }
}

// ─── Revisões ────────────────────────────────────────────────────────────────

class _ReviewSection extends ConsumerWidget {
  const _ReviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(statsReviewLogsProvider).value ?? const [];
    final cards = ref.watch(statsCardsProvider).value ?? const [];
    final today = ref.watch(todayProvider);

    final days = lastBuckets(Bucket.dia, today, 14);
    final perDay = reviewsPerDay(logs, days);
    final last30 = [
      for (final l in logs)
        if (!l.reviewedAt.isBefore(addDays(today, -29))) l,
    ];
    final rate = accuracy(last30);
    final streak = studyStreak(logs, today);
    final forecast = dueForecast(cards, today, 7);
    final todayCount = perDay.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Revisões'),
        Row(
          children: [
            _Stat(value: '$todayCount', label: 'Hoje'),
            _Stat(
              value: rate == null ? '–' : '${(rate * 100).round()}%',
              label: 'Acerto (30 dias)',
            ),
            _Stat(
              value: '$streak',
              label: streak == 1 ? 'Dia seguido' : 'Dias seguidos',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Revisões por dia', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _Bars(
          values: [for (final c in perDay) c.toDouble()],
          labels: [for (final d in days) '${d.day}'],
          labelEvery: 3,
          integers: true,
          tooltip: (i) =>
              '${formatDate(days[i], today)}\n${perDay[i]} '
              '${perDay[i] == 1 ? 'revisão' : 'revisões'}',
          semanticLabel: 'Gráfico de revisões por dia',
        ),
        const SizedBox(height: 16),
        Text(
          'Cards a vencer nos próximos 7 dias',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        _Bars(
          integers: true,
          values: [for (final c in forecast) c.toDouble()],
          labels: [
            for (var i = 0; i < 7; i++)
              i == 0 ? 'hoje' : weekdayShort[addDays(today, i).weekday - 1],
          ],
          tooltip: (i) =>
              '${i == 0 ? 'Hoje (com atrasados)' : formatDate(addDays(today, i), today)}'
              '\n${forecast[i]} ${forecast[i] == 1 ? 'card' : 'cards'}',
          semanticLabel: 'Gráfico de cards a vencer',
        ),
      ],
    );
  }
}

// ─── Rotinas ─────────────────────────────────────────────────────────────────

class _RoutineSection extends ConsumerWidget {
  const _RoutineSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(statsCompletionsProvider).value ?? const [];
    final today = ref.watch(todayProvider);
    final grid = routineHeatmap(completions, today, heatmapWeeks);
    final start = heatmapStart(today, heatmapWeeks);
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.labelSmall!
        .copyWith(color: scheme.onSurfaceVariant, fontSize: 10);
    final total = completions.length;

    Color colorOf(int? count) {
      if (count == null) return Colors.transparent;
      if (count == 0) return scheme.surfaceContainerHighest;
      final level = math.min(count, 4) / 4;
      return Color.lerp(
        scheme.primary.withValues(alpha: 0.3),
        scheme.primary,
        level,
      )!;
    }

    Widget cell(Color color, {String? tip}) {
      final box = Container(
        width: 13,
        height: 13,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      );
      return tip == null ? box : Tooltip(message: tip, child: box);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Rotinas concluídas'),
        Text(
          '$total ${total == 1 ? 'conclusão' : 'conclusões'} nas últimas '
          '$heatmapWeeks semanas',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // começa mostrando a semana atual
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    SizedBox(
                      height: 16,
                      width: 28,
                      child: Text(
                        d.isEven ? weekdayShort[d] : '',
                        style: small,
                      ),
                    ),
                ],
              ),
              for (final (w, week) in grid.indexed)
                Column(
                  children: [
                    for (final (d, count) in week.indexed)
                      cell(
                        colorOf(count),
                        tip: count == null
                            ? null
                            : '${formatDate(addDays(start, 7 * w + d), today)}: '
                                  '$count',
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('menos', style: small),
            for (final c in [0, 1, 2, 3, 4]) cell(colorOf(c)),
            Text('mais', style: small),
          ],
        ),
      ],
    );
  }
}
