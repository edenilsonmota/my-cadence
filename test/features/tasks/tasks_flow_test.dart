import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/pump_app.dart';

TasksRepository repoOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

Finder inNavBar(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> goTo(WidgetTester tester, String tab) async {
  await tester.tap(inNavBar(tab));
  await settle(tester);
}

/// Lê do banco fora do relógio falso dos testes de widget.
Future<T> read<T>(WidgetTester tester, Future<T> Function() query) async =>
    (await tester.runAsync(query)) as T;

void main() {
  testWidgets('Hoje separa atrasadas, de hoje e sem data', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final repo = repoOf(db);
        await repo.createTask(title: 'Atrasada', dueAt: DateTime(2026, 11, 20));
        await repo.createTask(
          title: 'Reunião',
          dueAt: DateTime(2026, 11, 23, 15),
          hasTime: true,
        );
        await repo.createTask(title: 'Sem prazo');
        await repo.createTask(title: 'Amanhã', dueAt: DateTime(2026, 11, 24));
      },
    );

    expect(find.text('Atrasadas · 1'), findsOneWidget);
    expect(find.text('Atrasada'), findsOneWidget);
    expect(find.text('Hoje · 1'), findsOneWidget);
    expect(find.text('Reunião'), findsOneWidget);
    expect(find.text('Hoje, 15:00'), findsOneWidget);
    expect(find.text('Amanhã'), findsNothing);

    // "Sem data" começa recolhida.
    expect(find.text('Sem data · 1'), findsOneWidget);
    expect(find.text('Sem prazo'), findsNothing);
    await tester.tap(find.text('Sem data · 1'));
    await settle(tester);
    expect(find.text('Sem prazo'), findsOneWidget);
  });

  testWidgets('cria pelo Hoje com prazo hoje e conclui pelo checkbox', (
    tester,
  ) async {
    final db = await pumpApp(tester);

    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Ler');
    await tester.tap(find.text('Estudo'));
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    expect(find.text('Hoje · 1'), findsOneWidget);
    final task = (await read(
      tester,
      () => repoOf(db).watchAllTasks().first,
    )).single;
    expect(task.title, 'Ler');
    expect(task.kind, TaskKind.estudo);
    expect(task.dueAt, DateTime(2026, 11, 23));

    await tester.tap(find.byType(Checkbox));
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);

    final done = (await read(tester, () => repoOf(db).getTask(task.id)))!;
    expect(done.status, TaskStatus.feita);
    expect(done.completedAt, isNotNull);
  });

  testWidgets('fechar o seletor de data não devolve o foco ao título', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);
    final title = find.widgetWithText(TextField, 'Título');
    expect(tester.widget<TextField>(title).focusNode, isNull);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextField>(),
      isNotNull,
    ); // título começa focado

    await tester.tap(find.text('seg, 23 nov'));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextField>(),
      isNull,
    );
  });

  testWidgets('título vazio não salva', (tester) async {
    await pumpApp(tester);
    await goTo(tester, 'Tarefas');
    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);

    await tester.tap(find.text('Salvar'));
    await settle(tester);

    expect(find.text('Informe o título.'), findsOneWidget);
    expect(find.text('Nova tarefa'), findsOneWidget);
  });

  testWidgets('deslizar exclui e Desfazer restaura', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => repoOf(db).createTask(title: 'Descartável'),
    );
    await goTo(tester, 'Tarefas');

    await tester.drag(find.text('Descartável'), const Offset(-500, 0));
    await settle(tester);
    expect(find.text('Descartável'), findsNothing);
    expect(find.text('"Descartável" excluída'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('Descartável'), findsOneWidget);
    expect(
      await read(tester, () => repoOf(db).watchAllTasks().first),
      hasLength(1),
    );
  });

  testWidgets('busca e filtro por tipo na aba Tarefas', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final repo = repoOf(db);
        await repo.createTask(
          title: 'Revisão de cálculo',
          kind: TaskKind.estudo,
        );
        await repo.createTask(title: 'Comprar pão');
        final done = await repo.createTask(title: 'Feita');
        await repo.setStatus(done, TaskStatus.feita);
      },
    );
    await goTo(tester, 'Tarefas');
    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text('Feita'), findsNothing); // concluídas ficam ocultas

    await tester.tap(find.byTooltip('Buscar'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'revisao');
    await settle(tester);
    expect(find.text('Revisão de cálculo'), findsOneWidget);
    expect(find.text('Comprar pão'), findsNothing);

    await tester.tap(find.byTooltip('Fechar busca'));
    await settle(tester);
    await tester.tap(find.byTooltip('Filtrar e ordenar'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Simples'));
    await settle(tester);
    await tester.tapAt(const Offset(180, 40)); // fecha o painel
    await settle(tester);

    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text('Revisão de cálculo'), findsNothing);
  });

  testWidgets('hub: adiciona subtarefas e a árvore mostra os níveis', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) => repoOf(db).createTask(title: 'Projeto'),
    );
    await goTo(tester, 'Tarefas');
    await tester.tap(find.text('Projeto'));
    await settle(tester);

    final input = find.widgetWithText(TextField, 'Adicionar subtarefa');
    await tester.enterText(input, 'Parte 1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    await tester.enterText(input, 'Parte 2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);

    expect(find.text('Subtarefas · 0/2'), findsOneWidget);
    final subtasks = await read(tester, () async {
      final root = (await repoOf(db).watchRootTasks().first).single;
      return repoOf(db).watchSubtasks(root.id).first;
    });
    expect(subtasks.map((t) => t.title), ['Parte 1', 'Parte 2']);

    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);
    expect(find.text('Parte 1'), findsNothing);
    await tester.tap(find.byTooltip('Mostrar subtarefas'));
    await settle(tester);
    expect(find.text('Parte 1'), findsOneWidget);
    expect(find.text('Parte 2'), findsOneWidget);
  });

  testWidgets('editar pelo hub grava as mudanças', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => repoOf(db).createTask(title: 'Rascunho'),
    );
    await goTo(tester, 'Tarefas');
    await tester.tap(find.text('Rascunho'));
    await settle(tester);
    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Final');
    await tester.tap(find.text('Alta'));
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    expect(find.text('Final'), findsOneWidget);
    expect(find.text('Prioridade Alta'), findsOneWidget);
    final task = (await read(
      tester,
      () => repoOf(db).watchAllTasks().first,
    )).single;
    expect(task.priority, 3);
  });
}
