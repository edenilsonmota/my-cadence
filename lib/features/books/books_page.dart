import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/appearance_badge.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tab_scaffold.dart';
import '../tasks/task_providers.dart';
import 'book_actions.dart';
import 'books_format.dart';
import 'books_providers.dart';

/// Aba Books: os cadernos que não pertencem a uma tarefa.
class BooksPage extends ConsumerWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final books = ref.watch(booksProvider);
    return TabScaffold(
      title: l10n.navBooks,
      actions: [
        IconButton(
          tooltip: l10n.booksImportMarkdown,
          icon: const Icon(AppIcons.import),
          onPressed: () => importBookFlow(context, ref),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: null, // abas vivas no IndexedStack; ver CLAUDE.md
        tooltip: l10n.booksNew,
        onPressed: () => createBookFlow(context, ref),
        child: const Icon(AppIcons.add),
      ),
      body: books.when(
        loading: () => const SkeletonList(),
        error: (_, _) =>
            EmptyState(icon: AppIcons.error, message: l10n.booksLoadError),
        data: (books) => books.isEmpty
            ? EmptyState(
                icon: AppIcons.book,
                message: l10n.booksEmpty,
                action: FilledButton.tonal(
                  onPressed: () => importBookFlow(context, ref),
                  child: Text(l10n.booksImportMarkdown),
                ),
              )
            : ListView(
                padding: EdgeInsets.only(bottom: context.space.xxxl * 2),
                children: [for (final book in books) _BookTile(book: book)],
              ),
      ),
    );
  }
}

class _BookTile extends ConsumerWidget {
  const _BookTile({required this.book});

  final Notebook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.lang;
    final pages = ref.watch(pagesOfNotebookProvider(book.id)).value;
    final today = ref.watch(todayProvider);
    // Última edição: a página mais recente, ou o próprio book.
    final edited = [
      book.updatedAt,
      for (final p in pages ?? const <NotePage>[]) p.updatedAt,
    ].reduce((a, b) => a.isAfter(b) ? a : b);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.space.page,
        vertical: context.space.xs,
      ),
      leading: AppearanceBadge(
        colorKey: book.colorKey ?? defaultBookColor,
        icon: bookIcon(book),
      ),
      title: Text(book.title, style: context.text.titleMedium),
      subtitle: pages == null
          ? null
          : Text(
              '${pagesLabel(pages.length, lang: lang)} · '
              '${editedLabel(edited, today, lang: lang)}',
            ),
      onTap: () => context.push(Routes.book(book.id)),
      trailing: _BookMenu(book: book),
    );
  }
}

class _BookMenu extends ConsumerWidget {
  const _BookMenu({required this.book});

  final Notebook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.booksOptions,
      onSelected: (v) async {
        switch (v) {
          case 'renomear':
            await renameBookFlow(context, ref, book);
          case 'icone':
            await pickBookIconFlow(context, ref, book);
          case 'exportar':
            await exportBookFlow(context, ref, book);
          case 'excluir':
            if (await confirmDelete(
              context,
              title: l10n.booksDeleteTitle(book.title),
              message: l10n.booksDeleteMessage,
            )) {
              await ref.read(booksRepositoryProvider).deleteNotebook(book.id);
            }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'renomear', child: Text(l10n.actionRename)),
        PopupMenuItem(value: 'icone', child: Text(l10n.fieldIconAndColor)),
        PopupMenuItem(value: 'exportar', child: Text(l10n.booksExportZip)),
        PopupMenuItem(value: 'excluir', child: Text(l10n.actionDelete)),
      ],
    );
  }
}
