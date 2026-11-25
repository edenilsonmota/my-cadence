import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../app/nav_tabs.dart';
import '../../app/nav_tabs_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/tab_scaffold.dart';
import '../tasks/hub/hub_stats.dart' show formatDuration;
import '../tasks/task_providers.dart';
import 'stats_logic.dart';
import 'stats_providers.dart';

/// Métricas: foco, revisões e rotinas.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabScaffold(
      title: context.l10n.navStats,
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

/// Indicador da linha de resumo.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.delta});

  final String value;
  final String label;
  final ({String text, bool? up})? delta;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: context.space.xs),
      child: MetricCard(
        value: value,
        label: label,
        delta: delta?.text,
        deltaUp: delta?.up,
      ),
    ),
  );
}

/// Sem dados: frase e, se houver, a ação (nunca um gráfico vazio).
class _Empty extends StatelessWidget {
  const _Empty(this.text, {this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.space.lg),
    child: Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
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
                  context.text.labelMedium!.copyWith(
                    color: scheme.onInverseSurface,
                  ),
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
    this.color,
  });

  final String label;
  final String value;
  final double fraction;

  /// Cor da barra (da tarefa, tag ou tipo); padrão, a do tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.space.xs),
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
              SizedBox(width: context.space.sm),
              Text(value, style: theme.textTheme.labelLarge!.tabular),
            ],
          ),
          SizedBox(height: context.space.xs),
          LinearProgressIndicator(
            value: fraction.clamp(0, 1).toDouble(),
            minHeight: 6,
            color: color,
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
    final l10n = context.l10n;
    final lang = context.lang;
    final months = monthsShortFor(lang);
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

    /// Variação em relação ao período anterior (ontem, semana, mês).
    ({String text, bool? up}) delta(Bucket b, String vs) {
      final start = bucketStart(b, today);
      final previous = lastBuckets(b, today, 2).first;
      final d = durationDelta(
        total(b),
        focusBetween(sessions, previous, start, now),
      );
      return (
        text: d.up == null ? l10n.statsSameAs(vs) : l10n.statsVs(d.text, vs),
        up: d.up,
      );
    }

    String label(DateTime start) => switch (bucket) {
      Bucket.dia => '${start.day}',
      Bucket.semana => '${start.day}/${start.month}',
      Bucket.mes => months[start.month - 1],
    };
    String tip(int i) {
      final start = buckets[i];
      final when = switch (bucket) {
        Bucket.dia => formatDate(start, today, lang: lang),
        Bucket.semana => l10n.statsWeekOf('${start.day}/${two(start.month)}'),
        Bucket.mes => '${months[start.month - 1]} ${start.year}',
      };
      return '$when\n${formatDuration(totals[i])}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.statsFocusTime),
        Row(
          children: [
            _Stat(
              value: formatDuration(total(Bucket.dia)),
              label: l10n.navToday,
              delta: delta(Bucket.dia, l10n.statsYesterday),
            ),
            _Stat(
              value: formatDuration(total(Bucket.semana)),
              label: l10n.statsThisWeek,
              delta: delta(Bucket.semana, l10n.statsPrevious),
            ),
            _Stat(
              value: formatDuration(total(Bucket.mes)),
              label: l10n.statsThisMonth,
              delta: delta(Bucket.mes, l10n.statsPrevious),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<Bucket>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: Bucket.dia, label: Text(l10n.statsDays)),
            ButtonSegment(value: Bucket.semana, label: Text(l10n.statsWeeks)),
            ButtonSegment(value: Bucket.mes, label: Text(l10n.statsMonths)),
          ],
          selected: {bucket},
          onSelectionChanged: (s) =>
              ref.read(statsBucketProvider.notifier).set(s.single),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.statsFocusHoursPer(switch (bucket) {
            Bucket.dia => l10n.statsUnitDay,
            Bucket.semana => l10n.statsUnitWeek,
            Bucket.mes => l10n.statsUnitMonth,
          }),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (totals.every((t) => t.inMinutes == 0))
          _Empty(
            l10n.statsNoFocusInPeriod,
            action: l10n.statsStartFocus,
            onAction: () =>
                openNavTab(context, ref.read(navTabsProvider), NavTab.pomodoro),
          )
        else
          _Bars(
            values: [for (final t in totals) t.inMinutes / 60],
            labels: [for (final b in buckets) label(b)],
            labelEvery: bucket == Bucket.mes ? 2 : 3,
            tooltip: tip,
            semanticLabel: l10n.statsFocusChartSemantics,
          ),
      ],
    );
  }
}

class _FocusBySection extends ConsumerWidget {
  const _FocusBySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
      FocusGroup.tarefa when key == null => l10n.pomodoroNoTask,
      FocusGroup.tarefa => tasks[key]?.title ?? l10n.statsDeletedTask,
      FocusGroup.tag when key == null => l10n.statsNoTag,
      FocusGroup.tag => tags[key]?.name ?? l10n.statsDeletedTag,
      FocusGroup.tipo when key == null => l10n.pomodoroNoTask,
      FocusGroup.tipo =>
        [
              for (final t in tasks.values)
                if (t.kind.name == key) t.kind.labelFor(l10n),
            ].firstOrNull ??
            key!,
    };

    final top = rows.take(8).toList();
    final max = top.isEmpty ? Duration.zero : top.first.total;
    final palette = context.palette;
    final resolver = ref.watch(appearanceResolverProvider);
    Color? colorOf(String? key) => switch (group) {
      _ when key == null => context.colors.outline,
      FocusGroup.tarefa when tasks[key] != null =>
        palette.byName(resolver.colorKeyOf(tasks[key]!)).strong,
      FocusGroup.tag when tags[key] != null =>
        palette.byName(tags[key]!.colorKey).strong,
      FocusGroup.tipo =>
        palette.of(AppPalette.kindKey(TaskKind.values.byName(key))).strong,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.statsFocusBy),
        SegmentedButton<FocusGroup>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: FocusGroup.tarefa,
              label: Text(l10n.statsGroupTask),
            ),
            ButtonSegment(
              value: FocusGroup.tag,
              label: Text(l10n.statsGroupTag),
            ),
            ButtonSegment(
              value: FocusGroup.tipo,
              label: Text(l10n.statsGroupType),
            ),
          ],
          selected: {group},
          onSelectionChanged: (s) =>
              ref.read(focusGroupProvider.notifier).set(s.single),
        ),
        const SizedBox(height: 8),
        if (top.isEmpty)
          _Empty(l10n.statsNoFocusGroup)
        else
          for (final r in top)
            _ShareRow(
              label: name(r.key),
              value: formatDuration(r.total),
              color: colorOf(r.key),
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
    final l10n = context.l10n;
    final sessions = ref.watch(statsSessionsProvider).value ?? const [];
    final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
    final rows = estimatedVsDone(tasks, sessions).take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.statsEstimatedVsDone),
        if (rows.isEmpty)
          _Empty(l10n.statsNoEstimated)
        else
          for (final r in rows)
            _ShareRow(
              label: r.task.title,
              value: l10n.statsOf(r.done, r.estimated),
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
    final l10n = context.l10n;
    final lang = context.lang;
    final weekdays = weekdaysShortFor(lang);
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
    final vsYesterday = countDelta(todayCount, perDay[perDay.length - 2]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.statsReviews),
        Row(
          children: [
            _Stat(
              value: '$todayCount',
              label: l10n.navToday,
              delta: (
                text: vsYesterday.up == null
                    ? l10n.statsSameAs(l10n.statsYesterday)
                    : l10n.statsVs(vsYesterday.text, l10n.statsYesterday),
                up: vsYesterday.up,
              ),
            ),
            _Stat(
              value: rate == null ? '–' : '${(rate * 100).round()}%',
              label: l10n.statsAccuracy30Days,
            ),
            _Stat(
              value: '$streak',
              label: streak == 1 ? l10n.statsStreakDay : l10n.statsStreakDays,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.statsReviewsPerDay,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (perDay.every((c) => c == 0))
          _Empty(
            l10n.statsNoReviews14Days,
            action: l10n.reviewNow,
            onAction: () =>
                openNavTab(context, ref.read(navTabsProvider), NavTab.review),
          )
        else
          _Bars(
            values: [for (final c in perDay) c.toDouble()],
            labels: [for (final d in days) '${d.day}'],
            labelEvery: 3,
            integers: true,
            tooltip: (i) =>
                '${formatDate(days[i], today, lang: lang)}\n${perDay[i]} '
                '${perDay[i] == 1 ? l10n.statsUnitReview : l10n.statsUnitReviews}',
            semanticLabel: l10n.statsReviewsChartSemantics,
          ),
        const SizedBox(height: 16),
        Text(
          l10n.statsDueNext7Days,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (forecast.every((c) => c == 0))
          _Empty(l10n.statsNoDueThisWeek)
        else
          _Bars(
            integers: true,
            values: [for (final c in forecast) c.toDouble()],
            labels: [
              for (var i = 0; i < 7; i++)
                i == 0
                    ? l10n.statsTodayLower
                    : weekdays[addDays(today, i).weekday - 1],
            ],
            tooltip: (i) =>
                '${i == 0 ? l10n.statsTodayWithOverdue : formatDate(addDays(today, i), today, lang: lang)}'
                '\n${forecast[i]} ${forecast[i] == 1 ? l10n.unitCard : l10n.unitCards}',
            semanticLabel: l10n.statsDueChartSemantics,
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
    final l10n = context.l10n;
    final lang = context.lang;
    final weekdays = weekdaysShortFor(lang);
    final completions = ref.watch(statsCompletionsProvider).value ?? const [];
    final today = ref.watch(todayProvider);
    final grid = routineHeatmap(completions, today, heatmapWeeks);
    final start = heatmapStart(today, heatmapWeeks);
    final scheme = Theme.of(context).colorScheme;
    final small = context.type.micro;
    // Tons de uma única cor, do claro ao forte.
    final heat = context.palette.of(PaletteKey.verde);
    final total = completions.length;

    Color? colorOf(int? count) {
      if (count == null) return null; // dia futuro
      if (count == 0) return scheme.surfaceContainerHighest;
      return Color.lerp(heat.tint, heat.strong, math.min(count, 4) / 4)!;
    }

    Widget cell(Color? color, {String? tip}) {
      final box = Container(
        width: 13,
        height: 13,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: context.radius.xsAll,
        ),
      );
      return tip == null ? box : Tooltip(message: tip, child: box);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.statsRoutinesDone),
        Text(
          l10n.statsRoutineTotal(
            total,
            total == 1 ? l10n.unitCompletion : l10n.unitCompletions,
            heatmapWeeks,
          ),
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
                      child: Text(d.isEven ? weekdays[d] : '', style: small),
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
                            : '${formatDate(addDays(start, 7 * w + d), today, lang: lang)}: '
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
            Text(l10n.statsLess, style: small),
            for (final c in [0, 1, 2, 3, 4]) cell(colorOf(c)),
            Text(l10n.statsMore, style: small),
          ],
        ),
      ],
    );
  }
}
