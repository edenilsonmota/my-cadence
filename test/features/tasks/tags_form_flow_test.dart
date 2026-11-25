import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/pump_app.dart';

TasksRepository tasksOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView).first,
    const Offset(0, -200),
  );
  await settle(tester);
}

void main() {
  testWidgets('cria tag no formulário, vincula e grava', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);
    await tester.tap(find.text('Mais opções'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Ler');
    await settle(tester);

    await scrollTo(tester, find.text('Nova tag'));
    await tester.tap(find.text('Nova tag'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Faculdade');
    await settle(tester);
    await tester.tap(find.text('Criar'));
    await settle(tester);
    expect(find.text('Faculdade'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await settle(tester);

    final task = (await tester.runAsync(
      () => tasksOf(db).watchAllTasks().first,
    ))!.single;
    final tags = (await tester.runAsync(
      () => tasksOf(db).watchTagsOfTask(task.id).first,
    ))!;
    expect(tags.map((t) => t.name), ['Faculdade']);
  });

  testWidgets('marca tag existente ao editar e grava', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await tasksOf(db).createTag(name: 'Casa', colorKey: 'azul');
        await tasksOf(db).createTask(title: 'Lavar');
      },
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Tarefas'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Lavar'));
    await settle(tester);
    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);
    await scrollTo(tester, find.text('Casa'));
    await tester.tap(find.text('Casa'));
    await settle(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    final task = (await tester.runAsync(
      () => tasksOf(db).watchAllTasks().first,
    ))!.single;
    final tags = (await tester.runAsync(
      () => tasksOf(db).watchTagsOfTask(task.id).first,
    ))!;
    expect(tags.map((t) => t.name), ['Casa']);
  });

  testWidgets('"Mais opções" leva título e tag da adição rápida', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTag(name: 'Casa', colorKey: 'azul'),
    );
    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Lavar louça');
    await settle(tester);
    await tester.tap(find.text('Tag'));
    await settle(tester);
    await tester.tap(find.text('Casa').last);
    await settle(tester);
    await tester.tap(find.text('Mais opções'));
    await settle(tester);

    expect(find.widgetWithText(TextField, 'Lavar louça'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    final task = (await tester.runAsync(
      () => tasksOf(db).watchAllTasks().first,
    ))!.single;
    final tags = (await tester.runAsync(
      () => tasksOf(db).watchTagsOfTask(task.id).first,
    ))!;
    expect(task.title, 'Lavar louça');
    expect(tags.map((t) => t.name), ['Casa']);
  });
}
