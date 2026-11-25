import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/gradient_fab.dart';
import '../../shared/widgets/skeleton.dart';
import '../tasks/task_providers.dart';
import 'book_actions.dart';
import 'book_markdown.dart';
import 'books_providers.dart';

/// Um book (ou o caderno de uma tarefa): a árvore de páginas.
class BookPage extends ConsumerWidget {
  const BookPage({required this.notebookId, super.key});

  final String notebookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(notebookProvider(notebookId)).value;
    final pages = ref.watch(pagesOfNotebookProvider(notebookId));
    final task = book?.taskId == null
        ? null
        : ref.watch(taskProvider(book!.taskId!)).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(book?.title ?? context.l10n.bookFallbackTitle),
        actions: [
          if (book != null)
            PopupMenuButton<String>(
              tooltip: context.l10n.bookOptions,
              onSelected: (v) => switch (v) {
                'importar' => importPagesFlow(context, ref, notebookId),
                'exportar' => exportBookFlow(context, ref, book),
                'renomear' => renameBookFlow(context, ref, book),
                'icone' => pickBookIconFlow(context, ref, book),
                _ => null,
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'importar',
                  child: Text(context.l10n.bookImportPages),
                ),
                PopupMenuItem(
                  value: 'exportar',
                  child: Text(context.l10n.bookExportZip),
                ),
                PopupMenuItem(
                  value: 'renomear',
                  child: Text(context.l10n.actionRename),
                ),
                PopupMenuItem(
                  value: 'icone',
                  child: Text(context.l10n.fieldIconAndColor),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: GradientFab(
        tooltip: context.l10n.pageNew,
        onPressed: () => createPageFlow(context, ref, notebookId: notebookId),
        child: const Icon(AppIcons.add),
      ),
      body: pages.when(
        loading: () => const SkeletonList(),
        error: (_, _) => EmptyState(
          icon: AppIcons.error,
          message: context.l10n.pagesLoadError,
        ),
        data: (pages) {
          final tree = flattenPages(pages);
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              if (task != null)
                ListTile(
                  dense: true,
                  leading: const Icon(AppIcons.task),
                  title: Text(context.l10n.bookTaskNotebook(task.title)),
                  onTap: () => context.push(Routes.task(task.id)),
                ),
              if (tree.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.space.xxxl),
                  child: EmptyState(
                    icon: AppIcons.page,
                    message: context.l10n.pagesEmpty,
                    action: FilledButton.tonal(
                      onPressed: () =>
                          createPageFlow(context, ref, notebookId: notebookId),
                      child: Text(context.l10n.pageCreate),
                    ),
                  ),
                ),
              for (final (page, depth) in tree)
                _PageTile(
                  page: page,
                  depth: depth,
                  allPages: pages,
                  color: context.palette
                      .byName(book?.colorKey ?? defaultBookColor)
                      .strong,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PageTile extends ConsumerWidget {
  const _PageTile({
    required this.page,
    required this.depth,
    required this.allPages,
    required this.color,
  });

  final NotePage page;
  final int depth;
  final List<NotePage> allPages;

  /// Cor do book (as páginas herdam).
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siblings = siblingsOf(page, allPages);
    final index = siblings.indexWhere((p) => p.id == page.id);
    return ListTile(
      contentPadding: EdgeInsetsDirectional.only(
        start: 16 + 24.0 * depth,
        end: 4,
      ),
      leading: Icon(
        AppIcons.of(
          page.iconKey,
          fallback: depth == 0 ? AppIcons.page : AppIcons.subtask,
        ),
        color: color,
      ),
      title: Text(page.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => context.push(Routes.page(page.id)),
      trailing: PopupMenuButton<String>(
        tooltip: context.l10n.pageOptions,
        onSelected: (v) => switch (v) {
          'sub' => createPageFlow(
            context,
            ref,
            notebookId: page.notebookId,
            parentId: page.id,
          ),
          'subir' => movePage(ref, page, allPages, -1),
          'descer' => movePage(ref, page, allPages, 1),
          'renomear' => renamePageFlow(context, ref, page),
          'exportar' => exportPageFlow(context, ref, page),
          'excluir' => deletePageFlow(context, ref, page),
          _ => null,
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'sub', child: Text(context.l10n.pageNewSub)),
          if (index > 0)
            PopupMenuItem(
              value: 'subir',
              child: Text(context.l10n.actionMoveUp),
            ),
          if (index >= 0 && index < siblings.length - 1)
            PopupMenuItem(
              value: 'descer',
              child: Text(context.l10n.actionMoveDown),
            ),
          PopupMenuItem(
            value: 'renomear',
            child: Text(context.l10n.actionRename),
          ),
          PopupMenuItem(
            value: 'exportar',
            child: Text(context.l10n.pageExportMd),
          ),
          PopupMenuItem(
            value: 'excluir',
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
  }
}
