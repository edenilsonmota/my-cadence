import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/gradient_fab.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tab_scaffold.dart';
import 'quick_add_sheet.dart';
import 'task_providers.dart';
import 'widgets/task_tile.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(todayProvider);
    final overdue = ref.watch(overdueTasksProvider);
    final dueToday = ref.watch(todayTasksProvider);
    final undated = ref.watch(undatedTasksProvider);

    final Widget body;
    if (overdue.hasError || dueToday.hasError || undated.hasError) {
      body = EmptyState(icon: AppIcons.error, message: l10n.tasksLoadError);
    } else if (!overdue.hasValue || !dueToday.hasValue || !undated.hasValue) {
      body = const SkeletonList();
    } else if (overdue.requireValue.isEmpty &&
        dueToday.requireValue.isEmpty &&
        undated.requireValue.isEmpty) {
      body = EmptyState(
        icon: AppIcons.today,
        message: l10n.todayEmpty,
        action: FilledButton.tonal(
          onPressed: () => showQuickAdd(context, dueToday: true),
          child: Text(l10n.tasksCreate),
        ),
      );
    } else {
      List<Widget> tiles(List<Task> tasks) => [
        for (final task in tasks)
          SwipeableTaskTile(
            key: ValueKey(task.id),
            tile: TaskTile(task: task, today: today),
          ),
      ];
      body = ListView(
        padding: EdgeInsets.only(
          bottom: context.space.xxxl * 2 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (overdue.requireValue.isNotEmpty) ...[
            SectionHeader(
              l10n.todayOverdue,
              detail: '${overdue.requireValue.length}',
              color: context.palette.danger.strong,
            ),
            ...tiles(overdue.requireValue),
          ],
          if (dueToday.requireValue.isNotEmpty) ...[
            SectionHeader(
              l10n.navToday,
              detail: '${dueToday.requireValue.length}',
            ),
            ...tiles(dueToday.requireValue),
          ],
          if (undated.requireValue.isNotEmpty)
            ExpansionTile(
              // Sem as linhas que o ExpansionTile desenha ao abrir.
              shape: const Border(),
              collapsedShape: const Border(),
              title: SectionHeader(
                l10n.todayUndated,
                detail: '${undated.requireValue.length}',
                padding: EdgeInsets.zero,
              ),
              tilePadding: EdgeInsets.symmetric(horizontal: context.space.page),
              childrenPadding: EdgeInsets.zero,
              children: tiles(undated.requireValue),
            ),
        ],
      );
    }

    return TabScaffold(
      title: l10n.navToday,
      body: body,
      floatingActionButton: GradientFab(
        // Cada aba tem seu FAB vivo no IndexedStack: sem Hero, para não colidir.
        heroTag: null,
        tooltip: l10n.tasksNew,
        onPressed: () => showQuickAdd(context, dueToday: true),
        child: const Icon(AppIcons.add),
      ),
    );
  }
}
