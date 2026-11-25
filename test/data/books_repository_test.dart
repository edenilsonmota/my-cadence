import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import 'test_db.dart';

void main() {
  late AppDatabase db;
  late BooksRepository repo;
  late TasksRepository tasks;

  setUp(() {
    db = openTestDb();
    repo = BooksRepository(db.booksDao);
    tasks = TasksRepository(db.tasksDao, db.tagsDao);
  });

  group('cadernos', () {
    test('books listam só cadernos que não são de tarefa', () async {
      await repo.createBook(
        title: 'Flutter',
        colorKey: 'azul',
        iconKey: 'code',
      );
      await repo.createBook(title: 'Algoritmos');
      final task = await tasks.createTask(title: 'Estudar');
      await repo.taskNotebookId(task, title: 'Estudar');

      final books = await repo.watchBooks().first;
      expect(books.map((b) => b.title), ['Algoritmos', 'Flutter']);
      expect((books.last.colorKey, books.last.iconKey), ('azul', 'code'));
    });

    test('caderno da tarefa é criado uma vez só', () async {
      final task = await tasks.createTask(title: 'Estudar');
      final first = await repo.taskNotebookId(task, title: 'Estudar');
      final second = await repo.taskNotebookId(task, title: 'Estudar');

      expect(second, first);
      expect(await db.select(db.notebooks).get(), hasLength(1));
    });

    test('renomeia e exclui com as páginas', () async {
      final book = await repo.createBook(title: 'Rascunho');
      final page = await repo.createPage(notebookId: book, title: 'P1');

      final notebook = (await repo.watchBooks().first).single;
      await repo.saveNotebook(notebook.copyWith(title: 'Final'));
      expect((await repo.watchBooks().first).single.title, 'Final');

      await repo.deleteNotebook(book);
      expect(await repo.watchBooks().first, isEmpty);
      expect(await repo.getPage(page), isNull);
    });
  });

  group('páginas', () {
    test('cria, edita conteúdo e lista em ordem', () async {
      final book = await repo.createBook(title: 'B');
      await repo.createPage(notebookId: book, title: 'Segunda', sortOrder: 2);
      final first = await repo.createPage(
        notebookId: book,
        title: 'Primeira',
        sortOrder: 1,
      );

      final page = (await repo.getPage(first))!;
      expect(page.content, '');
      await repo.savePage(page.copyWith(content: '{"document":{}}'));
      expect((await repo.getPage(first))!.content, '{"document":{}}');

      final pages = await repo.watchPages(book).first;
      expect(pages.map((p) => p.title), ['Primeira', 'Segunda']);
    });

    test('excluir página leva as subpáginas junto', () async {
      final book = await repo.createBook(title: 'B');
      final parent = await repo.createPage(notebookId: book, title: 'Pai');
      final child = await repo.createPage(
        notebookId: book,
        title: 'Filha',
        parentPageId: parent,
      );
      final grandchild = await repo.createPage(
        notebookId: book,
        title: 'Neta',
        parentPageId: child,
      );
      final sibling = await repo.createPage(notebookId: book, title: 'Irmã');

      await repo.deletePage(parent);

      for (final id in [parent, child, grandchild]) {
        expect(await repo.getPage(id), isNull);
      }
      expect(await repo.getPage(sibling), isNotNull);
    });
  });

  group('vínculos com tarefas', () {
    test('vincula nos dois sentidos, desvincula e revive', () async {
      final book = await repo.createBook(title: 'B');
      final page = await repo.createPage(notebookId: book, title: 'Resumo');
      final task = await tasks.createTask(title: 'Prova');

      await repo.linkPage(task, page);
      await repo.linkPage(task, page); // repetir não duplica
      expect((await repo.watchLinkedPages(task).first).map((p) => p.id), [
        page,
      ]);
      expect((await repo.watchTasksLinkedToPage(page).first).map((t) => t.id), [
        task,
      ]);

      await repo.unlinkPage(task, page);
      expect(await repo.watchLinkedPages(task).first, isEmpty);

      await repo.linkPage(task, page);
      expect(await db.select(db.taskPageLinks).get(), hasLength(1));
      expect(await repo.watchLinkedPages(task).first, hasLength(1));
    });

    test('página ou tarefa excluída some dos vínculos', () async {
      final book = await repo.createBook(title: 'B');
      final page = await repo.createPage(notebookId: book, title: 'Resumo');
      final task = await tasks.createTask(title: 'Prova');
      await repo.linkPage(task, page);

      await tasks.deleteTask(task);
      expect(await repo.watchTasksLinkedToPage(page).first, isEmpty);

      final other = await tasks.createTask(title: 'Outra');
      await repo.linkPage(other, page);
      await repo.deletePage(page);
      expect(await repo.watchLinkedPages(other).first, isEmpty);
    });
  });

  group('books vinculados a tarefas', () {
    test('define o conjunto, desfaz os que saíram e revive', () async {
      final fisica = await repo.createBook(title: 'Física');
      final calculo = await repo.createBook(title: 'Cálculo');
      final task = await tasks.createTask(title: 'Prova');

      await repo.setTaskNotebooks(task, {fisica, calculo});
      expect(
        (await repo.watchLinkedNotebooks(task).first).map((b) => b.title),
        ['Cálculo', 'Física'],
      );
      expect(
        (await repo.watchTasksLinkedToNotebook(fisica).first).map((t) => t.id),
        [task],
      );

      await repo.setTaskNotebooks(task, {fisica});
      expect((await repo.watchLinkedNotebooks(task).first).map((b) => b.id), [
        fisica,
      ]);

      await repo.setTaskNotebooks(task, {fisica, calculo});
      expect(await db.select(db.taskNotebookLinks).get(), hasLength(2));

      await repo.unlinkNotebook(task, calculo);
      expect(await repo.watchLinkedNotebooks(task).first, hasLength(1));
    });

    test('book excluído some dos vínculos', () async {
      final book = await repo.createBook(title: 'Física');
      final task = await tasks.createTask(title: 'Prova');
      await repo.setTaskNotebooks(task, {book});

      await repo.deleteNotebook(book);
      expect(await repo.watchLinkedNotebooks(task).first, isEmpty);
    });
  });
}
