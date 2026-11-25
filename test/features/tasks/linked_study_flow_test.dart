import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/pump_app.dart';

TasksRepository tasksOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

Future<void> openHub(WidgetTester tester, String title) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Tarefas'),
    ),
  );
  await settle(tester);
  await tester.tap(find.text(title));
  await settle(tester);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView).first,
    const Offset(0, -200),
  );
  await settle(tester);
}

void main() {
  testWidgets('no formulário vincula book existente e cria deck novo', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await BooksRepository(db.booksDao).createBook(title: 'Física');
        await tasksOf(db).createTask(title: 'Prova');
      },
    );
    await openHub(tester, 'Prova');
    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);

    await scrollTo(tester, find.text('Vincular book'));
    await tester.tap(find.text('Vincular book'));
    await settle(tester);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Física'));
    await settle(tester);
    Navigator.of(tester.element(find.text('Vincular books'))).pop();
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'Física'), findsOneWidget);

    await scrollTo(tester, find.text('Novo deck'));
    await tester.tap(find.text('Novo deck'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Fórmulas');
    await settle(tester);
    await tester.tap(find.text('Criar').last);
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'Fórmulas'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await settle(tester);

    final task = (await tester.runAsync(
      () => tasksOf(db).watchAllTasks().first,
    ))!.single;
    final books = (await tester.runAsync(
      () => BooksRepository(db.booksDao).watchLinkedNotebooks(task.id).first,
    ))!;
    final decks = (await tester.runAsync(
      () => CardsRepository(db.cardsDao).watchLinkedDecks(task.id).first,
    ))!;
    expect(books.map((b) => b.title), ['Física']);
    expect(decks.map((d) => d.name), ['Fórmulas']);

    // O hub mostra os dois.
    await scrollTo(tester, find.text('Física'));
    expect(find.text('Física'), findsOneWidget);
    await scrollTo(tester, find.text('Fórmulas'));
    expect(find.text('Fórmulas'), findsOneWidget);
  });

  testWidgets('excluir tarefa pergunta se exclui os vinculados', (
    tester,
  ) async {
    late String bookId, deckId;
    final db = await pumpApp(
      tester,
      seed: (db) async {
        final books = BooksRepository(db.booksDao);
        final cards = CardsRepository(db.cardsDao);
        bookId = await books.createBook(title: 'Física');
        deckId = await cards.createDeck(name: 'Fórmulas');
        final task = await tasksOf(db).createTask(title: 'Prova');
        await books.setTaskNotebooks(task, {bookId});
        await cards.setTaskDecks(task, {deckId});
      },
    );
    await openHub(tester, 'Prova');
    await tester.tap(find.byTooltip('Excluir'));
    await settle(tester);

    expect(find.text('Excluir tarefa?'), findsOneWidget);
    await tester.tap(find.text('1 book (com as páginas)'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await settle(tester);

    final books = (await tester.runAsync(
      () => BooksRepository(db.booksDao).watchBooks().first,
    ))!;
    final decks = (await tester.runAsync(
      () => CardsRepository(db.cardsDao).watchDecks().first,
    ))!;
    expect(books, isEmpty); // marcado: foi junto
    expect(decks.map((d) => d.id), [deckId]); // não marcado: ficou
    expect(
      (await tester.runAsync(() => tasksOf(db).watchAllTasks().first))!,
      isEmpty,
    );
  });

  testWidgets('sem nada vinculado, exclui direto (com desfazer)', (
    tester,
  ) async {
    await pumpApp(tester, seed: (db) => tasksOf(db).createTask(title: 'Solta'));
    await openHub(tester, 'Solta');
    await tester.tap(find.byTooltip('Excluir'));
    await settle(tester);
    expect(find.text('Excluir tarefa?'), findsNothing);
    expect(find.text('Desfazer'), findsOneWidget);
  });
}
