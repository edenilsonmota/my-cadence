import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/calendar_layout.dart' show weekStart;
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/share_row.dart';
import '../stats/stats_providers.dart';
import '../tasks/hub/hub_stats.dart' show formatDuration;
import '../tasks/reschedule.dart';
import '../tasks/task_providers.dart';
import '../tasks/widgets/reschedule_sheet.dart';
import 'week_review_logic.dart';

final _completionsProvider = StreamProvider.autoDispose
    .family<List<TaskCompletion>, DateTime>(
      (ref, start) => ref
          .watch(tasksRepositoryProvider)
          .watchCompletionsBetween(start, addDays(start, 7)),
    );

/// Revisão da semana: concluídas, rotinas, foco por tag e o que ficou para
/// trás (com reagendar).
class WeekReviewPage extends ConsumerStatefulWidget {
  const WeekReviewPage({super.key});

  @override
  ConsumerState<WeekReviewPage> createState() => _WeekReviewPageState();
}

class _WeekReviewPageState extends ConsumerState<WeekReviewPage> {
  /// Semanas antes da atual (0 = esta semana).
  int _back = 0;

  Future<void> _allToToday(List<Task> overdue) async {
    final repo = ref.read(tasksRepositoryProvider);
    final today = ref.read(todayProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    for (final t in overdue) {
      final dates = rescheduleToDay(t, today);
      await repo.rescheduleTask(
        t.id,
        startAt: dates.startAt,
        dueAt: dates.dueAt,
        hasTime: dates.hasTime,
      );
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.weekMovedToToday(overdue.length))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.lang;
    final space = context.space;
    final today = ref.watch(todayProvider);
    final now = ref.watch(clockProvider)();
    final start = addDays(weekStart(today), -7 * _back);
    final tags = {
      for (final t in ref.watch(tagsProvider).value ?? const <Tag>[]) t.id: t,
    };
    final review = buildWeekReview(
      weekOf: start,
      now: now,
      tasks: ref.watch(allTasksProvider).value ?? const [],
      sessions: ref.watch(statsSessionsProvider).value ?? const [],
      completions: ref.watch(_completionsProvider(start)).value ?? const [],
      tagsOf: ref.watch(tagIdsByTaskProvider).value ?? const {},
    );
    final last = addDays(review.end, -1);
    final range =
        '${formatDate(review.start, today, lang: lang)} – '
        '${formatDate(last, today, lang: lang)}';
    final topTags = review.byTag.take(8).toList();
    final maxTag = topTags.isEmpty ? Duration.zero : topTags.first.total;

    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(value, style: context.type.metric),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weekReviewTitle)),
      body: ListView(
        padding: EdgeInsets.only(bottom: space.xxl),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space.sm),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.weekPrevious,
                  icon: const Icon(AppIcons.chevronLeft),
                  onPressed: () => setState(() => _back++),
                ),
                Expanded(
                  child: Text(
                    range,
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.weekNext,
                  icon: const Icon(AppIcons.chevronRight),
                  onPressed: _back == 0 ? null : () => setState(() => _back--),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: space.page,
              vertical: space.md,
            ),
            child: Row(
              children: [
                stat('${review.completed.length}', l10n.weekCompleted),
                stat(
                  review.routineMissed > 0
                      ? '${review.routineDone}/${review.routineDone + review.routineMissed}'
                      : '${review.routineDone}',
                  l10n.weekRoutines,
                ),
                stat(formatDuration(review.focus), l10n.weekFocus),
              ],
            ),
          ),
          if (_back == 0) ...[
            SectionHeader(
              l10n.weekOverdue,
              detail: '${review.overdue.length}',
              action: review.overdue.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => _allToToday(review.overdue),
                      child: Text(l10n.weekAllToToday),
                    ),
            ),
            if (review.overdue.isEmpty)
              ListTile(title: Text(l10n.weekNoOverdue))
            else
              for (final t in review.overdue)
                ListTile(
                  title: Text(t.title),
                  subtitle: Text(
                    formatRelative(
                      t.dueAt!,
                      today,
                      withTime: t.hasTime,
                      lang: lang,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => showRescheduleSheet(context, ref, t),
                    child: Text(l10n.rescheduleAction),
                  ),
                  onTap: () => context.push(Routes.task(t.id)),
                ),
          ],
          SectionHeader(l10n.weekByTag),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space.page),
            child: topTags.isEmpty
                ? Text(l10n.weekNoFocus)
                : Column(
                    children: [
                      for (final r in topTags)
                        ShareRow(
                          label: r.key == null
                              ? l10n.statsNoTag
                              : tags[r.key]?.name ?? l10n.statsDeletedTag,
                          value: formatDuration(r.total),
                          color: r.key == null || tags[r.key] == null
                              ? context.colors.outline
                              : context.palette
                                    .byName(tags[r.key]!.colorKey)
                                    .strong,
                          fraction: maxTag == Duration.zero
                              ? 0
                              : r.total.inSeconds / maxTag.inSeconds,
                        ),
                    ],
                  ),
          ),
          SectionHeader(
            l10n.weekCompleted,
            detail: '${review.completed.length}',
          ),
          if (review.completed.isEmpty)
            ListTile(title: Text(l10n.weekNoCompleted))
          else
            for (final t in review.completed)
              ListTile(
                leading: const Icon(AppIcons.check),
                title: Text(t.title),
                subtitle: Text(
                  formatRelative(t.completedAt!, today, lang: lang),
                ),
                onTap: () => context.push(Routes.task(t.id)),
              ),
        ],
      ),
    );
  }
}
