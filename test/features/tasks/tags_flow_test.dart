import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/pump_app.dart';

Future<void> openTagsFromDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Abrir menu de navegação'));
  await settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationDrawer),
      matching: find.text('Tags'),
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets(
    'menu Tags cria, renomeia, troca cor e exclui avisando quantas tarefas usam',
    (tester) async {
      final db = await pumpApp(
        tester,
        seed: (db) async {
          final repo = TasksRepository(db.tasksDao, db.tagsDao);
          final work = await repo.createTag(name: 'Trabalho', colorKey: 'azul');
          await repo.createTag(name: 'Vazia', colorKey: 'verde');
          final t1 = await repo.createTask(title: 'Enviar relatório');
          final t2 = await repo.createTask(title: 'Revisar código');
          await repo.addTagToTask(t1, work);
          await repo.addTagToTask(t2, work);
        },
      );

      await openTagsFromDrawer(tester);

      expect(find.text('Trabalho'), findsOneWidget);
      expect(find.text('2 tarefas'), findsOneWidget);
      expect(find.text('Vazia'), findsOneWidget);
      expect(find.text('Nenhuma tarefa'), findsOneWidget);

      // Criar nova tag pela tela de Tags.
      await tester.tap(find.byTooltip('Nova tag'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Estudo');
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Violeta'));
      await settle(tester);
      await tester.tap(find.text('Criar'));
      await settle(tester);
      expect(find.text('Estudo'), findsOneWidget);

      // Renomear "Trabalho" para "Projetos" (bloqueando duplicado antes).
      await tester.tap(find.text('Trabalho'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'estudo');
      await settle(tester);
      expect(find.text('Já existe uma tag com esse nome.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Projetos');
      await settle(tester);
      await tester.tap(find.text('Salvar'));
      await settle(tester);
      expect(find.text('Projetos'), findsOneWidget);
      expect(find.text('Trabalho'), findsNothing);

      // Trocar a cor de "Projetos" para Laranja pelo menu de opções.
      final projetosTile = find.ancestor(
        of: find.text('Projetos'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(
          of: projetosTile,
          matching: find.byTooltip('Opções da tag'),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Trocar cor'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Laranja'));
      await settle(tester);

      final tagsAfterColor = (await tester.runAsync(
        () => TasksRepository(db.tasksDao, db.tagsDao).watchTags().first,
      ))!;
      final projetos = tagsAfterColor.firstWhere((t) => t.name == 'Projetos');
      expect(projetos.colorKey, 'laranja');

      // Excluir "Projetos": avisa que está em 2 tarefas; tarefas continuam vivas.
      await tester.tap(
        find.descendant(
          of: projetosTile,
          matching: find.byTooltip('Opções da tag'),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Excluir'));
      await settle(tester);

      expect(find.text('Excluir "Projetos"?'), findsOneWidget);
      expect(
        find.text('Esta tag está em 2 tarefas; elas perdem a tag.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await settle(tester);

      expect(find.text('Projetos'), findsNothing);
      expect(find.text('Tag "Projetos" excluída.'), findsOneWidget);

      final repo = TasksRepository(db.tasksDao, db.tagsDao);
      final remainingTasks = (await tester.runAsync(
        () => repo.watchAllTasks().first,
      ))!;
      expect(remainingTasks, hasLength(2));
      final links = (await tester.runAsync(
        () => repo.watchTagIdsByTask().first,
      ))!;
      expect(links, isEmpty);
    },
  );

  testWidgets('Ver tarefas pela tela de Tags abre Tarefas filtrada pela tag', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final repo = TasksRepository(db.tasksDao, db.tagsDao);
        final tag = await repo.createTag(name: 'Foco', colorKey: 'verde');
        final t1 = await repo.createTask(title: 'Ler artigo');
        await repo.createTask(title: 'Outra tarefa');
        await repo.addTagToTask(t1, tag);
      },
    );

    await openTagsFromDrawer(tester);
    await tester.tap(find.byTooltip('Opções da tag'));
    await settle(tester);
    await tester.tap(find.text('Ver tarefas'));
    await settle(tester);

    expect(find.text('Ler artigo'), findsOneWidget);
    expect(find.text('Outra tarefa'), findsNothing);
  });
}
