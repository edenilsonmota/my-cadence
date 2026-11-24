import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tab_scaffold.dart';
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
      body = const EmptyState(
        icon: AppIcons.today,
        message: 'Nada para hoje ainda.',
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
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          if (overdue.requireValue.isNotEmpty) ...[
            _SectionHeader(
              'Atrasadas',
              count: overdue.requireValue.length,
              color: Theme.of(context).colorScheme.error,
            ),
            ...tiles(overdue.requireValue),
          ],
          if (dueToday.requireValue.isNotEmpty) ...[
            _SectionHeader('Hoje', count: dueToday.requireValue.length),
            ...tiles(dueToday.requireValue),
          ],
          if (undated.requireValue.isNotEmpty)
            Theme(
              // Sem as linhas que o ExpansionTile desenha ao abrir.
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: _SectionTitle(
                  'Sem data',
                  count: undated.requireValue.length,
                ),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: EdgeInsets.zero,
                children: tiles(undated.requireValue),
              ),
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
        onPressed: () => context.push(Routes.newTask(dueToday: true)),
        child: const Icon(AppIcons.add),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.count, this.color});

  final String title;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: _SectionTitle(title, count: count, color: color),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.count, this.color});

  final String title;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall!
        .copyWith(color: color ?? Theme.of(context).colorScheme.primary);
    return Text('$title · $count', style: style);
  }
}
