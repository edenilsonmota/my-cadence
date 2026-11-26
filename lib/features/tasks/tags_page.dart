import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/nav_tabs.dart';
import '../../app/nav_tabs_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/appearance_badge.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/gradient_fab.dart';
import '../../shared/widgets/skeleton.dart';
import 'tags_logic.dart';
import 'task_lists.dart';
import 'task_providers.dart';
import 'widgets/tag_form_dialog.dart';

/// Tela de gerenciamento de tags: criar, renomear, trocar cor e excluir
/// (mostrando quantas tarefas usam cada tag).
class TagsPage extends ConsumerWidget {
  const TagsPage({super.key});

  Future<void> _createTag(
    BuildContext context,
    WidgetRef ref,
    List<Tag> existing,
  ) async {
    final repo = ref.read(tasksRepositoryProvider);
    final created = await showTagFormDialog(
      context,
      existingNames: [for (final t in existing) t.name],
    );
    if (created == null) return;
    await repo.createTag(name: created.name, colorKey: created.colorKey);
  }

  Future<void> _editTag(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
    List<Tag> existing,
  ) async {
    final repo = ref.read(tasksRepositoryProvider);
    final updated = await showTagFormDialog(
      context,
      initialName: tag.name,
      initialColorKey: tag.colorKey,
      existingNames: [
        for (final t in existing)
          if (t.id != tag.id) t.name,
      ],
    );
    if (updated == null) return;
    await repo.saveTag(
      tag.copyWith(name: updated.name, colorKey: updated.colorKey),
    );
  }

  Future<void> _changeColor(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final repo = ref.read(tasksRepositoryProvider);
    final picked = await showTagColorDialog(
      context,
      tagName: tag.name,
      currentColorKey: tag.colorKey,
    );
    if (picked == null || picked == tag.colorKey) return;
    await repo.saveTag(tag.copyWith(colorKey: picked));
  }

  Future<void> _deleteTag(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
    int taskCount,
  ) async {
    // Lidos antes do diálogo (regra do projeto: ref pode sumir após await).
    final repo = ref.read(tasksRepositoryProvider);
    final filterNotifier = ref.read(taskFilterProvider.notifier);
    final currentFilter = ref.read(taskFilterProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tagDeleteTitle(tag.name)),
        content: Text(
          taskCount == 0
              ? l10n.tagDeleteUnusedMessage
              : l10n.tagDeleteUsedMessage(taskCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repo.deleteTag(tag.id);
    if (currentFilter.tagIds.contains(tag.id)) {
      filterNotifier.update(
        (f) => f.copyWith(tagIds: {...f.tagIds}..remove(tag.id)),
      );
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.tagDeleted(tag.name))));
  }

  void _viewTasks(BuildContext context, WidgetRef ref, Tag tag) {
    final sort = ref.read(taskFilterProvider).sort;
    ref
        .read(taskFilterProvider.notifier)
        .update((_) => TaskFilter(tagIds: {tag.id}, sort: sort));
    final barTabs = ref.read(navTabsProvider);
    if (barTabs.contains(NavTab.tasks)) {
      context.go(NavTab.tasks.tabRoute);
    } else {
      context.pushReplacement(NavTab.tasks.overlayRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tagsAsync = ref.watch(tagsProvider);
    final tasks = ref.watch(allTasksProvider).value ?? const <Task>[];
    final links = ref.watch(tagIdsByTaskProvider).value ?? const {};
    final counts = countTasksPerTag(
      liveTaskIds: [for (final t in tasks) t.id],
      tagIdsByTask: links,
    );
    final currentTags = tagsAsync.value ?? const <Tag>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTags)),
      floatingActionButton: GradientFab(
        tooltip: l10n.tagNew,
        onPressed: () => _createTag(context, ref, currentTags),
        child: const Icon(AppIcons.add),
      ),
      body: tagsAsync.when(
        loading: () => const SkeletonList(),
        error: (_, _) =>
            EmptyState(icon: AppIcons.error, message: l10n.tagsLoadError),
        data: (tags) => tags.isEmpty
            ? EmptyState(
                icon: AppIcons.tag,
                message: l10n.tagsEmpty,
                action: FilledButton.tonal(
                  onPressed: () => _createTag(context, ref, tags),
                  child: Text(l10n.tagNew),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final count = counts[tag.id] ?? 0;
                  return _TagTile(
                    tag: tag,
                    taskCount: count,
                    onViewTasks: () => _viewTasks(context, ref, tag),
                    onEdit: () => _editTag(context, ref, tag, tags),
                    onChangeColor: () => _changeColor(context, ref, tag),
                    onDelete: () => _deleteTag(context, ref, tag, count),
                  );
                },
              ),
      ),
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({
    required this.tag,
    required this.taskCount,
    required this.onViewTasks,
    required this.onEdit,
    required this.onChangeColor,
    required this.onDelete,
  });

  final Tag tag;
  final int taskCount;
  final VoidCallback onViewTasks;
  final VoidCallback onEdit;
  final VoidCallback onChangeColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: Tooltip(
        message: l10n.tagChangeColor,
        child: InkWell(
          borderRadius: context.radius.mdAll,
          onTap: onChangeColor,
          child: AppearanceBadge(colorKey: tag.colorKey, icon: AppIcons.tag),
        ),
      ),
      title: Text(tag.name),
      subtitle: Text(l10n.tagTaskCount(taskCount)),
      onTap: onEdit,
      trailing: PopupMenuButton<String>(
        tooltip: l10n.tagOptions,
        onSelected: (v) => switch (v) {
          'ver' => onViewTasks(),
          'renomear' => onEdit(),
          'cor' => onChangeColor(),
          'excluir' => onDelete(),
          _ => null,
        },
        itemBuilder: (_) => [
          if (taskCount > 0)
            PopupMenuItem(value: 'ver', child: Text(l10n.tagViewTasks)),
          PopupMenuItem(value: 'renomear', child: Text(l10n.actionRename)),
          PopupMenuItem(value: 'cor', child: Text(l10n.tagChangeColor)),
          PopupMenuItem(value: 'excluir', child: Text(l10n.actionDelete)),
        ],
      ),
    );
  }
}
