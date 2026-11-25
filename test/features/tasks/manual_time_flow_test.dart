import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
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

void main() {
  testWidgets('registra tempo à mão pelo hub e pode excluir', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTask(title: 'Relatório'),
    );
    await openHub(tester, 'Relatório');

    // Tarefa simples sem sessões: atalho no topo.
    await tester.tap(find.widgetWithText(ActionChip, 'Registrar tempo'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '1 h 30 min'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar tempo'));
    await settle(tester);

    expect(find.text('1 h 30 min registrados.'), findsOneWidget);
    final sessions = (await tester.runAsync(
      () => db.select(db.pomodoroSessions).get(),
    ))!;
    final s = sessions.single;
    expect(s.manual, isTrue);
    expect(s.endedAt!.difference(s.startedAt), const Duration(minutes: 90));
    // Hoje, terminando agora (relógio do teste: meio-dia).
    expect(s.endedAt, DateTime(2026, 11, 23, 12));

    // O hub mostra o tempo e o registro.
    await tester.dragUntilVisible(
      find.text('Registros manuais'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await settle(tester);
    expect(find.text('Tempo de foco: 1 h 30 min'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir registro'));
    await settle(tester);
    final left = (await tester.runAsync(
      () =>
          PomodoroRepository(db.pomodoroDao)
              .watchSessionsOfTasks([s.taskId!])
              .first,
    ))!;
    expect(left, isEmpty);
  });
}
