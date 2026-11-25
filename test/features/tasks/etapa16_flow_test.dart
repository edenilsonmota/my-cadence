import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_cadence/app/router.dart';
import 'package:my_cadence/app/theme/app_theme.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/books_repository.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/data/repositories/templates_repository.dart';

import '../../helpers/pump_app.dart';

// Hoje dos testes: segunda, 23/11/2026, meio-dia.

TasksRepository tasksOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

Future<T> read<T>(WidgetTester tester, Future<T> Function() query) async =>
    (await tester.runAsync(query)) as T;

Future<void> goTo(WidgetTester tester, String tab) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)),
  );
  await settle(tester);
}

Future<void> openHub(WidgetTester tester, String title) async {
  await goTo(tester, 'Tarefas');
  await tester.tap(find.text(title));
  await settle(tester);
}

Future<Task> taskNamed(
  WidgetTester tester,
  AppDatabase db,
  String title,
) async => (await read(
  tester,
  () => tasksOf(db).watchAllTasks().first,
)).singleWhere((t) => t.title == title);

void main() {
  testWidgets('pausar tira do Hoje; retomar volta', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) =>
          tasksOf(db).createTask(title: 'Ler', dueAt: DateTime(2026, 11, 23)),
    );
    expect(find.text('Ler'), findsOneWidget);

    await openHub(tester, 'Ler');
    await tester.tap(find.byTooltip('Mudar status'));
    await settle(tester);
    await tester.tap(find.text('Pausada').last);
    await settle(tester);
    expect(find.textContaining('Pausada: não aparece no Hoje'), findsOneWidget);
    expect((await taskNamed(tester, db, 'Ler')).status, TaskStatus.pausada);

    await tester.tap(find.text('Retomar'));
    await settle(tester);
    expect((await taskNamed(tester, db, 'Ler')).status, TaskStatus.aFazer);
  });

  testWidgets('pausada some do Hoje e aparece em Tarefas com selo', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final id = await tasksOf(db)
            .createTask(title: 'Em espera', dueAt: DateTime(2026, 11, 20));
        await tasksOf(db).setStatus(id, TaskStatus.pausada);
      },
    );
    expect(find.text('Em espera'), findsNothing); // nem nas atrasadas
    await goTo(tester, 'Tarefas');
    expect(find.text('Em espera'), findsOneWidget);
    expect(find.text('Pausada'), findsOneWidget);
  });

  testWidgets('reagendar pelo hub mantém a hora', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTask(
        title: 'Reunião',
        dueAt: DateTime(2026, 11, 20, 15),
        hasTime: true,
      ),
    );
    await openHub(tester, 'Reunião');
    await tester.tap(find.widgetWithText(ActionChip, 'Reagendar'));
    await settle(tester);
    await tester.tap(find.text('Amanhã'));
    await settle(tester);
    expect(
      (await taskNamed(tester, db, 'Reunião')).dueAt,
      DateTime(2026, 11, 24, 15),
    );
    expect(find.text('Reagendada para Amanhã.'), findsOneWidget);
  });

  testWidgets('#tag na adição rápida cria e vincula a tag', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTag(name: 'Estudos', colorKey: 'azul'),
    );
    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);
    await tester.enterText(
      find.byType(TextField).last,
      'Verbos #estudos #Inglês',
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Adicionar tarefa'));
    await settle(tester);

    final task = await taskNamed(tester, db, 'Verbos');
    final tags = await read(
      tester,
      () => tasksOf(db).watchTagsOfTask(task.id).first,
    );
    expect(tags.map((t) => t.name), ['Estudos', 'Inglês']);
  });

  testWidgets('tempo estimado no formulário', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTask(title: 'TCC'),
    );
    await openHub(tester, 'TCC');
    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);
    await tester.dragUntilVisible(
      find.widgetWithText(ChoiceChip, '30 min'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await settle(tester);
    // Horas: o primeiro "+" logo acima dos chips de minutos.
    final hoursRow = find
        .ancestor(of: find.text('Horas'), matching: find.byType(Row))
        .first;
    await tester.tap(
      find.descendant(of: hoursRow, matching: find.byIcon(AppIcons.add)),
    );
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '30 min'));
    await settle(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    expect((await taskNamed(tester, db, 'TCC')).estimatedMinutes, 90);
  });

  testWidgets('busca geral acha tarefa, página e card', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await tasksOf(db).createTask(title: 'Estudar Newton');
        final books = BooksRepository(db.booksDao);
        final book = await books.createBook(title: 'Física');
        await books.createPage(notebookId: book, title: 'Leis de Newton');
        await CardsRepository(db.cardsDao).createCard(
          front: 'Quem formulou a gravitação?',
          back: 'Isaac Newton',
          now: DateTime(2026, 11, 23),
        );
      },
    );
    await tester.tap(find.byTooltip('Buscar em tudo'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'newton');
    await settle(tester);
    expect(find.text('Estudar Newton'), findsOneWidget);
    expect(find.text('Leis de Newton'), findsOneWidget);
    expect(find.text('Quem formulou a gravitação?'), findsOneWidget);

    await tester.tap(find.text('Estudar Newton'));
    await settle(tester);
    expect(find.byTooltip('Editar'), findsOneWidget); // hub aberto
  });

  testWidgets('revisão da semana: atrasadas vão todas para hoje', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await tasksOf(db)
            .createTask(title: 'Atrasada A', dueAt: DateTime(2026, 11, 20));
        await tasksOf(db)
            .createTask(title: 'Atrasada B', dueAt: DateTime(2026, 11, 21));
      },
    );
    unawaited(
      GoRouter.of(tester.element(find.byType(NavigationBar)))
          .push(Routes.weekReview),
    );
    await settle(tester);
    expect(find.text('Atrasada A'), findsOneWidget);

    await tester.tap(find.text('Todas para hoje'));
    await settle(tester);
    expect(find.text('2 tarefas movidas para hoje.'), findsOneWidget);
    expect(
      (await taskNamed(tester, db, 'Atrasada A')).dueAt,
      DateTime(2026, 11, 23),
    );
    expect(find.text('Nada atrasado. Boa!'), findsOneWidget);
  });

  testWidgets('modelo: salvar pelo hub e criar pela adição rápida', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        final tasks = tasksOf(db);
        final tag = await tasks.createTag(name: 'Faculdade', colorKey: 'rosa');
        final id = await tasks.createTask(
          title: 'Prova',
          estimatedMinutes: 120,
        );
        await tasks.setTaskTags(id, {tag});
        await tasks.createTask(title: 'Resumo', parentId: id);
      },
    );
    await openHub(tester, 'Prova');
    await tester.tap(find.byTooltip('Salvar como modelo'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Prova padrão');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await settle(tester);
    final templates = await read(
      tester,
      () => TemplatesRepository(db.templatesDao).watchTemplates().first,
    );
    expect(templates.single.name, 'Prova padrão');
  });
}
