import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/fake_scheduler.dart';
import '../../helpers/pump_app.dart';

TasksRepository repoOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

void main() {
  testWidgets('concluir rotina no Hoje avança e avisa a próxima', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) => repoOf(db).createTask(
        title: 'Meditar',
        kind: TaskKind.rotina,
        dueAt: DateTime(2026, 11, 23),
        recurrenceRule: 'FREQ=DAILY',
      ),
    );
    expect(find.text('Meditar'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Concluir'));
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);

    expect(find.textContaining('Rotina concluída. Próxima:'), findsOneWidget);
    expect(find.text('Meditar'), findsNothing); // foi para amanhã
    final task = (await tester.runAsync(
      () => repoOf(db).watchAllTasks().first,
    ))!.single;
    expect(task.status, TaskStatus.aFazer);
  });

  testWidgets('hub da rotina mostra a sequência', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final repo = repoOf(db);
        final id = await repo.createTask(
          title: 'Ler 10 páginas',
          dueAt: DateTime(2026, 11, 23),
          recurrenceRule: 'FREQ=DAILY',
        );
        for (var d = 20; d <= 22; d++) {
          await repo.addCompletion(id, DateTime(2026, 11, d));
        }
      },
    );

    await tester.tap(find.text('Ler 10 páginas'));
    await settle(tester);
    await tester.dragUntilVisible(
      find.text('3 dias seguidos'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );

    expect(find.text('HISTÓRICO'), findsOneWidget);
    expect(find.text('3 dias seguidos'), findsOneWidget);
    expect(find.text('3 conclusões no total'), findsOneWidget);
    expect(find.text('Todo dia'), findsOneWidget);
  });

  testWidgets('salvar tarefa com alarme pede permissão de notificação', (
    tester,
  ) async {
    final scheduler = FakeScheduler();
    await pumpApp(tester, scheduler: scheduler);

    await tester.tap(find.byTooltip('Nova tarefa'));
    await settle(tester);
    // Adição rápida → formulário completo.
    await tester.tap(find.text('Mais opções'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Ligar');
    // Rola até o campo seguinte, para o alarme ficar inteiro na tela.
    await tester.dragUntilVisible(
      find.text('Pomodoros estimados'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await settle(tester);
    await tester.tap(find.text('Nenhum'));
    await settle(tester);
    await tester.tap(find.text('Na hora').last);
    await settle(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    expect(scheduler.permissionRequests, 1);
  });
}
