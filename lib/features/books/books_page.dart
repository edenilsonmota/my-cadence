import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_icons.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tab_scaffold.dart';
import 'book_actions.dart';
import 'books_providers.dart';

/// Aba Books: os cadernos que não pertencem a uma tarefa.
class BooksPage extends ConsumerWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    return TabScaffold(
      title: 'Books',
      actions: [
        IconButton(
          tooltip: 'Importar Markdown',
          icon: const Icon(AppIcons.import),
          onPressed: () => importBookFlow(context, ref),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: null, // abas vivas no IndexedStack; ver CLAUDE.md
        tooltip: 'Novo book',
        onPressed: () => createBookFlow(context, ref),
        child: const Icon(AppIcons.add),
      ),
      body: books.when(
        loading: () => const SkeletonList(),
        error: (_, _) => const EmptyState(
          icon: AppIcons.error,
          message: 'Não foi possível carregar os books.',
        ),
        data: (books) => books.isEmpty
            ? EmptyState(
                icon: AppIcons.book,
                message: 'Nenhum book criado.\nCrie um no + ou importe arquivos .md.',
                action: FilledButton.tonal(
                  onPressed: () => importBookFlow(context, ref),
                  child: const Text('Importar Markdown'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 88),
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
    final pages = ref.watch(pagesOfNotebookProvider(book.id)).value;
    return ListTile(
      leading: book.icon == null
          ? const Icon(AppIcons.book)
          : Text(book.icon!, style: const TextStyle(fontSize: 26)),
      title: Text(book.title),
      subtitle: pages == null
          ? null
          : Text('${pages.length} ${pages.length == 1 ? 'página' : 'páginas'}'),
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
    return PopupMenuButton<String>(
      tooltip: 'Opções do book',
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
              title: 'Excluir "${book.title}"?',
              message: 'Todas as páginas do book serão excluídas.',
            )) {
              await ref.read(booksRepositoryProvider).deleteNotebook(book.id);
            }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'renomear', child: Text('Renomear')),
        PopupMenuItem(value: 'icone', child: Text('Ícone')),
        PopupMenuItem(value: 'exportar', child: Text('Exportar (.zip)')),
        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
      ],
    );
  }
}
