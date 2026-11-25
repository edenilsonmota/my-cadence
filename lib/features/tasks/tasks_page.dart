import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/shell.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/gradient_fab.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tab_scaffold.dart';
import '../../shared/widgets/tag_chip.dart';
import '../sync/presentation/account_avatar.dart';
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
    final l10n = context.l10n;
    final filter = ref.watch(taskFilterProvider);
    final tree = ref.watch(taskTreeProvider);
    final today = ref.watch(todayProvider);
    // Com busca ou filtro ativo, tudo aberto para mostrar onde estão os achados.
    final expandAll = filter.query.trim().isNotEmpty || filter.activeCount > 0;
    final isTab = AppShell.isTab(context);

    return Scaffold(
      appBar: AppBar(
        leading: _searching
            ? IconButton(
                tooltip: l10n.tasksCloseSearch,
                icon: const Icon(AppIcons.back),
                onPressed: _closeSearch,
              )
            : null,
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.tasksSearchHint,
                  border: InputBorder.none,
                ),
                onChanged: _setQuery,
              )
            : Text(l10n.navTasks),
        actions: [
          if (!_searching)
            IconButton(
              tooltip: l10n.actionSearch,
              icon: const Icon(AppIcons.search),
              onPressed: () => setState(() => _searching = true),
            ),
          IconButton(
            tooltip: l10n.tasksFilterAndSort,
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: const Icon(AppIcons.filter),
            ),
            onPressed: () => showModalBottomSheet<void>(
              useRootNavigator: true,
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const _FilterSheet(),
            ),
          ),
          if (!_searching && isTab) const AccountAvatar(),
        ],
      ),
      drawer: isTab ? const AppDrawer() : null,
      floatingActionButton: AboveNavBar(
        child: GradientFab(
          // Cada aba tem seu FAB vivo no IndexedStack: sem Hero, para não colidir.
          heroTag: null,
          tooltip: l10n.tasksNew,
          onPressed: () => showQuickAdd(context),
          child: const Icon(AppIcons.add),
        ),
      ),
      body: tree.when(
        loading: () => const SkeletonList(),
        error: (_, _) =>
            EmptyState(icon: AppIcons.error, message: l10n.tasksLoadError),
        data: (nodes) {
          if (nodes.isEmpty) {
            return expandAll
                ? EmptyState(
                    icon: AppIcons.filterOff,
                    message: l10n.tasksNoMatches,
                    action: TextButton(
                      onPressed: () {
                        _closeSearch();
                        ref.read(taskFilterProvider.notifier).clear();
                      },
                      child: Text(l10n.tasksClearFilters),
                    ),
                  )
                : EmptyState(
                    icon: AppIcons.tasks,
                    message: l10n.tasksEmptyCreated,
                    action: FilledButton.tonal(
                      onPressed: () => showQuickAdd(context),
                      child: Text(l10n.tasksCreate),
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
                                ? l10n.tasksCollapseSubtasks
                                : l10n.tasksExpandSubtasks,
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
            padding: EdgeInsets.only(
              bottom: 88 + MediaQuery.paddingOf(context).bottom,
            ),
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
    final l10n = context.l10n;
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
                    l10n.tasksFilterAndSort,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: notifier.clear,
                  child: Text(l10n.actionClear),
                ),
              ],
            ),
            _ChipGroup(
              title: l10n.tasksSortBy,
              children: [
                for (final sort in TaskSort.values)
                  ChoiceChip(
                    label: Text(sort.labelFor(l10n)),
                    selected: filter.sort == sort,
                    onSelected: (_) =>
                        notifier.update((f) => f.copyWith(sort: sort)),
                  ),
              ],
            ),
            _ChipGroup(
              title: l10n.fieldStatus,
              children: [
                for (final status in TaskStatus.values)
                  FilterChip(
                    label: Text(status.labelFor(l10n)),
                    selected: filter.statuses.contains(status),
                    onSelected: (_) => notifier.update(
                      (f) => f.copyWith(statuses: toggled(f.statuses, status)),
                    ),
                  ),
              ],
            ),
            _ChipGroup(
              title: l10n.fieldType,
              children: [
                for (final kind in TaskKind.values)
                  FilterChip(
                    avatar: Icon(kind.icon, size: 18),
                    label: Text(kind.labelFor(l10n)),
                    selected: filter.kinds.contains(kind),
                    onSelected: (_) => notifier.update(
                      (f) => f.copyWith(kinds: toggled(f.kinds, kind)),
                    ),
                  ),
              ],
            ),
            _ChipGroup(
              title: l10n.fieldPriority,
              children: [
                for (var p = 3; p >= 0; p--)
                  FilterChip(
                    label: Text(priorityLabel(p, l10n)),
                    selected: filter.priorities.contains(p),
                    onSelected: (_) => notifier.update(
                      (f) => f.copyWith(priorities: toggled(f.priorities, p)),
                    ),
                  ),
              ],
            ),
            if (tags.isNotEmpty)
              _ChipGroup(
                title: l10n.fieldTags,
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
