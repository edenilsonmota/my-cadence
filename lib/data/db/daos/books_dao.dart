import 'package:drift/drift.dart';

import '../database.dart';
import '../sync_writes.dart';
import '../tables/books.dart';
import '../tables/tasks.dart';

part 'books_dao.g.dart';

@DriftAccessor(tables: [Notebooks, NotePages, TaskPageLinks, Tasks])
class BooksDao extends DatabaseAccessor<AppDatabase> with _$BooksDaoMixin {
  BooksDao(super.attachedDatabase);

  // Cadernos

  Future<void> insertNotebook(NotebooksCompanion row) =>
      insertSynced(notebooks, row);

  Future<void> updateNotebook(String id, NotebooksCompanion patch) =>
      updateSynced(notebooks, id, patch);

  /// Exclui o caderno e todas as páginas dele.
  Future<void> softDeleteNotebook(String id) => transaction(() async {
    final pages = await (select(
      notePages,
    )..where((p) => p.notebookId.equals(id) & p.deletedAt.isNull())).get();
    for (final page in pages) {
      await softDeleteSynced(notePages, page.id);
    }
    await softDeleteSynced(notebooks, id);
  });

  Stream<Notebook?> watchNotebook(String id) => (select(
    notebooks,
  )..where((n) => n.id.equals(id) & n.deletedAt.isNull())).watchSingleOrNull();

  Stream<NotePage?> watchPage(String id) => (select(
    notePages,
  )..where((p) => p.id.equals(id) & p.deletedAt.isNull())).watchSingleOrNull();

  /// Grava `sortOrder` = posição, para as páginas em [orderedIds].
  Future<void> reorderPages(List<String> orderedIds) => transaction(() async {
    for (final (index, id) in orderedIds.indexed) {
      await updateSynced(
        notePages,
        id,
        NotePagesCompanion(sortOrder: Value(index)),
      );
    }
  });

  /// Books (cadernos que não pertencem a uma tarefa).
  Stream<List<Notebook>> watchBooks() =>
      (select(notebooks)
            ..where((n) => n.taskId.isNull() & n.deletedAt.isNull())
            ..orderBy([(n) => OrderingTerm.asc(n.title)]))
          .watch();

  /// Caderno próprio da tarefa, se já existir.
  Future<Notebook?> getTaskNotebook(String taskId) =>
      (select(notebooks)
            ..where((n) => n.taskId.equals(taskId) & n.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

  Stream<Notebook?> watchTaskNotebook(String taskId) =>
      (select(notebooks)
            ..where((n) => n.taskId.equals(taskId) & n.deletedAt.isNull())
            ..limit(1))
          .watchSingleOrNull();

  /// Páginas de todos os books (cadernos que não são de tarefa), com o book.
  Stream<List<(NotePage, Notebook)>> watchBookPages() {
    final query =
        select(notePages).join([
            innerJoin(notebooks, notebooks.id.equalsExp(notePages.notebookId)),
          ])
          ..where(
            notebooks.taskId.isNull() &
                notebooks.deletedAt.isNull() &
                notePages.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(notebooks.title),
            OrderingTerm.asc(notePages.sortOrder),
            OrderingTerm.asc(notePages.id),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (row.readTable(notePages), row.readTable(notebooks)),
      ],
    );
  }

  // Páginas

  Future<void> insertPage(NotePagesCompanion row) =>
      insertSynced(notePages, row);

  Future<void> updatePage(String id, NotePagesCompanion patch) =>
      updateSynced(notePages, id, patch);

  Future<NotePage?> getPage(String id) => (select(
    notePages,
  )..where((p) => p.id.equals(id) & p.deletedAt.isNull())).getSingleOrNull();

  /// Todas as páginas vivas do caderno (a árvore é montada pelo chamador).
  Stream<List<NotePage>> watchPages(String notebookId) =>
      (select(notePages)
            ..where(
              (p) => p.notebookId.equals(notebookId) & p.deletedAt.isNull(),
            )
            ..orderBy([
              (p) => OrderingTerm.asc(p.sortOrder),
              (p) => OrderingTerm.asc(p.id),
            ]))
          .watch();

  /// Exclui a página e todas as subpáginas.
  Future<void> softDeletePageTree(String id) => transaction(() async {
    final ids = [id];
    var frontier = [id];
    while (frontier.isNotEmpty) {
      final children =
          await (selectOnly(notePages)
                ..addColumns([notePages.id])
                ..where(
                  notePages.parentPageId.isIn(frontier) &
                      notePages.deletedAt.isNull(),
                ))
              .map((row) => row.read(notePages.id)!)
              .get();
      ids.addAll(children);
      frontier = children;
    }
    for (final pageId in ids) {
      await softDeleteSynced(notePages, pageId);
    }
  });

  // Vínculos página ↔ tarefa

  /// Vincula a página à tarefa, revivendo o vínculo se já existiu.
  Future<void> linkPage(String taskId, String pageId) => transaction(() async {
    final existing =
        await (select(taskPageLinks)
              ..where((l) => l.taskId.equals(taskId) & l.pageId.equals(pageId)))
            .getSingleOrNull();
    if (existing == null) {
      await insertSynced(
        taskPageLinks,
        TaskPageLinksCompanion.insert(taskId: taskId, pageId: pageId),
      );
    } else if (existing.deletedAt != null) {
      await updateSynced(
        taskPageLinks,
        existing.id,
        const TaskPageLinksCompanion(deletedAt: Value(null)),
      );
    }
  });

  Future<void> unlinkPage(String taskId, String pageId) =>
      transaction(() async {
        final existing =
            await (select(taskPageLinks)..where(
                  (l) =>
                      l.taskId.equals(taskId) &
                      l.pageId.equals(pageId) &
                      l.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (existing != null) {
          await softDeleteSynced(taskPageLinks, existing.id);
        }
      });

  /// Páginas de books vinculadas à tarefa.
  Stream<List<NotePage>> watchLinkedPages(String taskId) {
    final query =
        select(notePages).join([
            innerJoin(
              taskPageLinks,
              taskPageLinks.pageId.equalsExp(notePages.id),
            ),
          ])
          ..where(
            taskPageLinks.taskId.equals(taskId) &
                taskPageLinks.deletedAt.isNull() &
                notePages.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(notePages.title)]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(notePages)],
    );
  }

  /// Tarefas vinculadas à página.
  Stream<List<Task>> watchTasksLinkedToPage(String pageId) {
    final query =
        select(tasks).join([
            innerJoin(taskPageLinks, taskPageLinks.taskId.equalsExp(tasks.id)),
          ])
          ..where(
            taskPageLinks.pageId.equals(pageId) &
                taskPageLinks.deletedAt.isNull() &
                tasks.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(tasks.title)]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(tasks)],
    );
  }
}
