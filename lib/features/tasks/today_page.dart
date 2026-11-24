import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../shared/widgets/empty_state.dart';
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
    final today = ref.watch(todayProvider);
    final overdue = ref.watch(overdueTasksProvider);
    final dueToday = ref.watch(todayTasksProvider);
    final undated = ref.watch(undatedTasksProvider);

    final Widget body;
    if (overdue.hasError || dueToday.hasError || undated.hasError) {
      body = const EmptyState(
        icon: AppIcons.error,
        message: 'Não foi possível carregar as tarefas.',
      );
    } else if (!overdue.hasValue || !dueToday.hasValue || !undated.hasValue) {
      body = const SkeletonList();
    } else if (overdue.requireValue.isEmpty &&
        dueToday.requireValue.isEmpty &&
        undated.requireValue.isEmpty) {
      body = EmptyState(
        icon: AppIcons.today,
        message: 'Nada para hoje ainda.',
        action: FilledButton.tonal(
          onPressed: () => showQuickAdd(context, dueToday: true),
          child: const Text('Criar tarefa'),
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
        padding: EdgeInsets.only(bottom: context.space.xxxl * 2),
        children: [
          if (overdue.requireValue.isNotEmpty) ...[
            SectionHeader(
              'Atrasadas',
              detail: '${overdue.requireValue.length}',
              color: context.palette.danger.strong,
            ),
            ...tiles(overdue.requireValue),
          ],
          if (dueToday.requireValue.isNotEmpty) ...[
            SectionHeader('Hoje', detail: '${dueToday.requireValue.length}'),
            ...tiles(dueToday.requireValue),
          ],
          if (undated.requireValue.isNotEmpty)
            ExpansionTile(
              // Sem as linhas que o ExpansionTile desenha ao abrir.
              shape: const Border(),
              collapsedShape: const Border(),
              title: SectionHeader(
                'Sem data',
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
      title: 'Hoje',
      body: body,
      floatingActionButton: FloatingActionButton(
        // Cada aba tem seu FAB vivo no IndexedStack: sem Hero, para não colidir.
        heroTag: null,
        tooltip: 'Nova tarefa',
        onPressed: () => showQuickAdd(context, dueToday: true),
        child: const Icon(AppIcons.add),
      ),
    );
  }
}
