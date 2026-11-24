import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tag_chip.dart';
import 'quick_add_sheet.dart';
import 'task_labels.dart';
import 'task_lists.dart';
import 'task_providers.dart';
import 'widgets/task_tile.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  final _search = TextEditingController();
  bool _searching = false;

  /// Tarefas com subtarefas abertas.
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(taskFilterProvider).query;
    _searching = _search.text.isNotEmpty;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String query) => ref
      .read(taskFilterProvider.notifier)
      .update((f) => f.copyWith(query: query));

  void _closeSearch() {
    _search.clear();
    _setQuery('');
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(taskFilterProvider);
    final tree = ref.watch(taskTreeProvider);
    final today = ref.watch(todayProvider);
    // Com busca ou filtro ativo, tudo aberto para mostrar onde estão os achados.
    final expandAll = filter.query.trim().isNotEmpty || filter.activeCount > 0;

    return Scaffold(
      appBar: AppBar(
        leading: _searching
            ? IconButton(
                tooltip: 'Fechar busca',
                icon: const Icon(AppIcons.back),
                onPressed: _closeSearch,
              )
            : null,
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar pelo título',
                  border: InputBorder.none,
                ),
                onChanged: _setQuery,
              )
            : const Text('Tarefas'),
        actions: [
          if (!_searching)
            IconButton(
              tooltip: 'Buscar',
              icon: const Icon(AppIcons.search),
              onPressed: () => setState(() => _searching = true),
            ),
          IconButton(
            tooltip: 'Filtrar e ordenar',
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: const Icon(AppIcons.filter),
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const _FilterSheet(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        // Cada aba tem seu FAB vivo no IndexedStack: sem Hero, para não colidir.
        heroTag: null,
        tooltip: 'Nova tarefa',
        onPressed: () => showQuickAdd(context),
        child: const Icon(AppIcons.add),
      ),
      body: tree.when(
        loading: () => const SkeletonList(),
        error: (_, _) => const EmptyState(
          icon: AppIcons.error,
          message: 'Não foi possível carregar as tarefas.',
        ),
        data: (nodes) {
          if (nodes.isEmpty) {
            return expandAll
                ? EmptyState(
                    icon: AppIcons.filterOff,
                    message: 'Nenhuma tarefa com esses filtros.',
                    action: TextButton(
                      onPressed: () {
                        _closeSearch();
                        ref.read(taskFilterProvider.notifier).clear();
                      },
                      child: const Text('Limpar filtros'),
                    ),
                  )
                : EmptyState(
                    icon: AppIcons.tasks,
                    message: 'Nenhuma tarefa criada.',
                    action: FilledButton.tonal(
                      onPressed: () => showQuickAdd(context),
                      child: const Text('Criar tarefa'),
                    ),
                  );
          }
          final rows = <Widget>[];
          void addRows(List<TaskNode> level, int depth) {
            for (final node in level) {
              final id = node.task.id;
              final open = expandAll || _expanded.contains(id);
              rows.add(
                SwipeableTaskTile(
                  key: ValueKey(id),
                  tile: TaskTile(
                    task: node.task,
                    today: today,
                    depth: depth,
                    trailing: node.children.isEmpty || expandAll
                        ? null
                        : IconButton(
                            tooltip: open
                                ? 'Recolher subtarefas'
                                : 'Mostrar subtarefas',
                            icon: Icon(
                              open ? AppIcons.collapse : AppIcons.expand,
                            ),
                            onPressed: () => setState(
                              () => open
                                  ? _expanded.remove(id)
                                  : _expanded.add(id),
                            ),
                          ),
                  ),
                ),
              );
              if (open) addRows(node.children, depth + 1);
            }
          }

          addRows(nodes, 0);
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: rows,
          );
        },
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final notifier = ref.read(taskFilterProvider.notifier);
    final tags = ref.watch(tagsProvider).value ?? const [];

    Set<T> toggled<T>(Set<T> set, T value) =>
        set.contains(value) ? ({...set}..remove(value)) : {...set, value};

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtrar e ordenar',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: notifier.clear,
                  child: const Text('Limpar'),
                ),
              ],
            ),
            _ChipGroup(
              title: 'Ordenar por',
              children: [
                for (final sort in TaskSort.values)
                  ChoiceChip(
                    label: Text(sort.label),
                    selected: filter.sort == sort,
                    onSelected: (_) =>
                        notifier.update((f) => f.copyWith(sort: sort)),
                  ),
              ],
            ),
            _ChipGroup(
              title: 'Status',
              children: [
                for (final status in TaskStatus.values)
                  FilterChip(
                    label: Text(status.label),
                    selected: filter.statuses.contains(status),
                    onSelected: (_) => notifier.update(
                      (f) => f.copyWith(statuses: toggled(f.statuses, status)),
                    ),
                  ),
              ],
            ),
            _ChipGroup(
              title: 'Tipo',
              children: [
                for (final kind in TaskKind.values)
                  FilterChip(
                    avatar: Icon(kind.icon, size: 18),
                    label: Text(kind.label),
                    selected: filter.kinds.contains(kind),
                    onSelected: (_) => notifier.update(
                      (f) => f.copyWith(kinds: toggled(f.kinds, kind)),
                    ),
                  ),
              ],
            ),
            _ChipGroup(
              title: 'Prioridade',
              children: [
                for (var p = 3; p >= 0; p--)
                  FilterChip(
                    label: Text(priorityLabels[p]),
                    selected: filter.priorities.contains(p),
                    onSelected: (_) => notifier.update(
                      (f) => f.copyWith(priorities: toggled(f.priorities, p)),
                    ),
                  ),
              ],
            ),
            if (tags.isNotEmpty)
              _ChipGroup(
                title: 'Tags',
                children: [
                  for (final tag in tags)
                    TagChip(
                      name: tag.name,
                      colorKey: tag.colorKey,
                      selected: filter.tagIds.contains(tag.id),
                      onSelected: (_) => notifier.update(
                        (f) => f.copyWith(tagIds: toggled(f.tagIds, tag.id)),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: children),
        ],
      ),
    );
  }
}
