import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../tasks/task_providers.dart';
import 'trash_logic.dart';

final _deletedTasksProvider = StreamProvider.autoDispose<List<Task>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchDeletedTasks(),
);

final _deletedTagsProvider = StreamProvider.autoDispose<List<Tag>>(
  (ref) => ref.watch(tasksRepositoryProvider).watchDeletedTags(),
);

final _deletedDecksProvider = StreamProvider.autoDispose<List<Deck>>(
  (ref) => ref.watch(cardsRepositoryProvider).watchDeletedDecks(),
);

final _deletedCardsProvider = StreamProvider.autoDispose<List<Flashcard>>(
  (ref) => ref.watch(cardsRepositoryProvider).watchDeletedCards(),
);

final _deletedBooksProvider = StreamProvider.autoDispose<List<Notebook>>(
  (ref) => ref.watch(booksRepositoryProvider).watchDeletedBooks(),
);

final _deletedPagesProvider =
    StreamProvider.autoDispose<List<(NotePage, Notebook)>>(
      (ref) => ref.watch(booksRepositoryProvider).watchDeletedPages(),
    );

/// Lixeira: lista itens excluídos recentemente (tarefas, cards, decks, books,
/// páginas e tags) e permite restaurar em um toque.
class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  TrashFilter _filter = TrashFilter.all;

  Future<void> _restore(TrashItem item) async {
    final tasksRepo = ref.read(tasksRepositoryProvider);
    final cardsRepo = ref.read(cardsRepositoryProvider);
    final booksRepo = ref.read(booksRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    await switch (item.kind) {
      TrashKind.task => tasksRepo.restoreTaskFromTrash(item.id),
      TrashKind.tag => tasksRepo.restoreTag(item.id),
      TrashKind.deck => cardsRepo.restoreDeck(item.id),
      TrashKind.card => cardsRepo.restoreCardFromTrash(item.id),
      TrashKind.book => booksRepo.restoreNotebook(item.id),
      TrashKind.page => booksRepo.restorePage(item.id),
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.trashRestored(item.title))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = context.space;
    final today = ref.watch(todayProvider);

    final tasks = ref.watch(_deletedTasksProvider).value ?? const <Task>[];
    final tags = ref.watch(_deletedTagsProvider).value ?? const <Tag>[];
    final decks = ref.watch(_deletedDecksProvider).value ?? const <Deck>[];
    final cards = ref.watch(_deletedCardsProvider).value ?? const <Flashcard>[];
    final books = ref.watch(_deletedBooksProvider).value ?? const <Notebook>[];
    final pages =
        ref.watch(_deletedPagesProvider).value ??
        const <(NotePage, Notebook)>[];

    final all = sortTrashItems([
      for (final t in tasks)
        if (t.deletedAt case final at?)
          TrashItem(
            kind: TrashKind.task,
            id: t.id,
            title: t.title,
            deletedAt: at,
          ),
      for (final tag in tags)
        if (tag.deletedAt case final at?)
          TrashItem(
            kind: TrashKind.tag,
            id: tag.id,
            title: tag.name,
            deletedAt: at,
          ),
      for (final d in decks)
        if (d.deletedAt case final at?)
          TrashItem(
            kind: TrashKind.deck,
            id: d.id,
            title: d.name,
            deletedAt: at,
          ),
      for (final c in cards)
        if (c.deletedAt case final at?)
          TrashItem(
            kind: TrashKind.card,
            id: c.id,
            title: c.front,
            deletedAt: at,
          ),
      for (final b in books)
        if (b.deletedAt case final at?)
          TrashItem(
            kind: TrashKind.book,
            id: b.id,
            title: b.title,
            deletedAt: at,
          ),
      for (final (page, book) in pages)
        if (page.deletedAt case final at?)
          TrashItem(
            kind: TrashKind.page,
            id: page.id,
            title: page.title,
            subtitle: book.title,
            deletedAt: at,
          ),
    ]);

    final filtered = filterTrashItems(all, _filter);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTrash)),
      body: all.isEmpty
          ? EmptyState(icon: AppIcons.delete, message: l10n.trashEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    space.lg,
                    space.sm,
                    space.lg,
                    space.xs,
                  ),
                  child: Text(
                    l10n.trashHint,
                    style: context.text.bodySmall!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: space.lg,
                    vertical: space.xs,
                  ),
                  child: Row(
                    children: [
                      for (final entry in [
                        (TrashFilter.all, l10n.trashFilterAll),
                        (TrashFilter.tasks, l10n.navTasks),
                        (TrashFilter.cards, l10n.trashFilterCards),
                        (TrashFilter.books, l10n.navBooks),
                        (TrashFilter.tags, l10n.navTags),
                      ])
                        Padding(
                          padding: EdgeInsets.only(right: space.sm),
                          child: ChoiceChip(
                            label: Text(entry.$2),
                            selected: _filter == entry.$1,
                            onSelected: (_) =>
                                setState(() => _filter = entry.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: AppIcons.delete,
                          message: l10n.trashEmpty,
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(bottom: space.xl),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final kindLabel = switch (item.kind) {
                              TrashKind.task => l10n.trashKindTask,
                              TrashKind.tag => l10n.trashKindTag,
                              TrashKind.deck => l10n.trashKindDeck,
                              TrashKind.card => l10n.trashKindCard,
                              TrashKind.book => l10n.trashKindBook,
                              TrashKind.page => l10n.trashKindPage,
                            };
                            final icon = switch (item.kind) {
                              TrashKind.task => AppIcons.task,
                              TrashKind.tag => AppIcons.tag,
                              TrashKind.deck => AppIcons.deck,
                              TrashKind.card => AppIcons.flashcard,
                              TrashKind.book => AppIcons.book,
                              TrashKind.page => AppIcons.page,
                            };
                            final when = formatDate(
                              item.deletedAt,
                              today,
                              lang: context.lang,
                            );
                            final meta = item.subtitle == null
                                ? '$kindLabel · $when'
                                : '$kindLabel · ${item.subtitle} · $when';
                            return ListTile(
                              leading: Icon(icon),
                              title: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(meta),
                              trailing: TextButton(
                                onPressed: () => _restore(item),
                                child: Text(l10n.trashRestore),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
