import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 23, 12);

Future<void> openTrashFromDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Abrir menu de navegação'));
  await settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationDrawer),
      matching: find.text('Lixeira'),
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets('Lixeira lista itens excluídos e restaura tarefa, book e card', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        final tasks = TasksRepository(db.tasksDao, db.tagsDao);
        final cards = CardsRepository(db.cardsDao);
        final books = BooksRepository(db.booksDao);

        final taskId = await tasks.createTask(title: 'Tarefa apagada');
        await tasks.deleteTask(taskId);

        final tagId = await tasks.createTag(name: 'Antiga', colorKey: 'azul');
        await tasks.deleteTag(tagId);

        final cardId = await cards.createCard(
          front: 'Card apagado',
          back: 'verso',
          now: now,
        );
        await cards.deleteCard(cardId);

        final bookId = await books.createBook(title: 'Caderno apagado');
        await books.createPage(notebookId: bookId, title: 'Capítulo 1');
        await books.deleteNotebook(bookId);
      },
    );

    await openTrashFromDrawer(tester);

    expect(find.text('Tarefa apagada'), findsOneWidget);
    expect(find.text('Antiga'), findsOneWidget);
    expect(find.text('Card apagado'), findsOneWidget);
    expect(find.text('Caderno apagado'), findsOneWidget);
    // Páginas de um book apagado não poluem a lista (voltam junto com o book).
    expect(find.text('Capítulo 1'), findsNothing);

    // Filtra por Books e restaura o caderno.
    await tester.ensureVisible(find.text('Books'));
    await tester.tap(find.text('Books'));
    await settle(tester);
    expect(find.text('Caderno apagado'), findsOneWidget);
    expect(find.text('Tarefa apagada'), findsNothing);

    await tester.tap(find.text('Restaurar'));
    await settle(tester);
    expect(find.text('"Caderno apagado" restaurado.'), findsOneWidget);

    // Volta para Tudo e restaura a tarefa e a tag.
    await tester.ensureVisible(find.text('Tudo'));
    await tester.tap(find.text('Tudo'));
    await settle(tester);

    final taskTile = find.ancestor(
      of: find.text('Tarefa apagada'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: taskTile, matching: find.text('Restaurar')),
    );
    await settle(tester);

    final tasksRepo = TasksRepository(db.tasksDao, db.tagsDao);
    final booksRepo = BooksRepository(db.booksDao);

    final liveTasks = (await tester.runAsync(
      () => tasksRepo.watchAllTasks().first,
    ))!;
    expect(liveTasks.map((t) => t.title), ['Tarefa apagada']);

    final liveBooks = (await tester.runAsync(
      () => booksRepo.watchBooks().first,
    ))!;
    expect(liveBooks.map((b) => b.title), ['Caderno apagado']);
    final livePages = (await tester.runAsync(
      () => booksRepo.watchPages(liveBooks.single.id).first,
    ))!;
    expect(livePages.map((p) => p.title), ['Capítulo 1']);
  });
}
