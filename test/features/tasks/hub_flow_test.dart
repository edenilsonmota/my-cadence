import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/pump_app.dart';

TasksRepository tasksOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

/// Abre o hub da primeira tarefa raiz pela aba Tarefas.
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

Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -200),
    );

void main() {
  testWidgets('tarefa simples mostra atalhos; criar card faz a seção surgir', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTask(title: 'Mercado'),
    );
    await openHub(tester, 'Mercado');

    expect(find.text('ADICIONAR'), findsOneWidget);
    expect(find.text('FLASHCARDS'), findsNothing);
    expect(find.text('PÁGINAS'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, 'Flashcard'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Frente'), 'Capital');
    await tester.enterText(find.widgetWithText(TextField, 'Verso'), 'Brasília');
    await settle(tester); // habilita o botão
    await tester.tap(find.text('Salvar card'));
    await settle(tester);

    expect(find.widgetWithText(ActionChip, 'Flashcard'), findsNothing);
    await scrollTo(tester, find.text('Revisar desta tarefa'));
    expect(find.text('1 card'), findsOneWidget);
    expect(find.text('1 para revisar agora'), findsOneWidget);

    final cards = await tester.runAsync(
      () => CardsRepository(db.cardsDao).watchCards().first,
    );
    expect(cards!.single.front, 'Capital');
    expect(cards.single.taskId, isNotNull);
  });

  testWidgets('pomodoro soma subtarefas e mostra estimado × feito', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final tasks = tasksOf(db);
        final pomodoro = PomodoroRepository(db.pomodoroDao);
        final root = await tasks.createTask(
          title: 'TCC',
          estimatedMinutes: 100,
        );
        final child = await tasks.createTask(title: 'Cap. 1', parentId: root);
        for (final (task, hour) in [(root, 8), (child, 9)]) {
          final id = await pomodoro.startSession(
            kind: PomodoroKind.foco,
            plannedMinutes: 25,
            startedAt: DateTime(2026, 11, 23, hour),
            taskId: task,
          );
          await pomodoro.finishSession(
            id,
            endedAt: DateTime(2026, 11, 23, hour, 25),
            completed: true,
          );
        }
      },
    );
    await openHub(tester, 'TCC');

    await scrollTo(tester, find.text('Iniciar foco'));
    expect(find.text('Tempo de foco: 50 min'), findsOneWidget);
    expect(find.textContaining('2 sessões de foco'), findsOneWidget);
    expect(find.text('Estimado × feito: 50 min de 1 h 40 min'), findsOneWidget);
  });

  testWidgets('cria página no caderno da tarefa e vincula página de book', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await tasksOf(db).createTask(title: 'Prova');
        final books = BooksRepository(db.booksDao);
        final book = await books.createBook(title: 'Cálculo');
        await books.createPage(notebookId: book, title: 'Derivadas');
      },
    );
    await openHub(tester, 'Prova');

    // Sem páginas, os dois atalhos ficam no topo.
    expect(
      find.widgetWithText(ActionChip, 'Vincular página existente'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ActionChip, 'Página'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Resumo');
    await settle(tester);
    await tester.tap(find.text('Criar'));
    await settle(tester);
    expect(find.text('Resumo'), findsOneWidget);

    await tester.ensureVisible(find.text('Vincular página existente'));
    await settle(tester);
    await tester.tap(find.text('Vincular página existente'));
    await settle(tester);
    expect(find.text('Derivadas'), findsOneWidget);
    expect(find.text('Cálculo'), findsOneWidget);
    await tester.tap(find.text('Derivadas'));
    await settle(tester);
    await tester.tapAt(const Offset(180, 40)); // fecha o painel
    await settle(tester);

    await scrollTo(tester, find.byTooltip('Desvincular'));
    expect(find.text('Derivadas'), findsOneWidget);

    final notebooks = await tester.runAsync(
      () => db.select(db.notebooks).get(),
    );
    // O book "Cálculo" e o caderno criado para a tarefa.
    expect(notebooks, hasLength(2));
  });
}
