import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import '../../helpers/pump_app.dart';

/// A lista da tela (o heatmap também rola, na horizontal).
final list = find.byType(Scrollable).first;

// "Hoje" dos testes: segunda, 23/11/2026, meio-dia.
DateTime d(int day, [int h = 0, int m = 0]) => DateTime(2026, 11, day, h, m);

void main() {
  testWidgets('métricas de foco, revisões e rotinas refletem o banco', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final tasks = TasksRepository(db.tasksDao, db.tagsDao);
        final calc = await tasks.createTask(
          title: 'Cálculo',
          estimatedPomodoros: 4,
        );
        final tag = await tasks.createTag(name: 'Faculdade', colorKey: 'azul');
        await tasks.setTaskTags(calc, {tag});
        final routine = await tasks.createTask(
          title: 'Correr',
          dueAt: d(24),
          recurrenceRule: 'FREQ=DAILY',
        );
        await tasks.addCompletion(routine, d(20));
        await tasks.addCompletion(routine, d(23));

        final pomodoro = PomodoroRepository(db.pomodoroDao);
        Future<void> focus(DateTime at, int minutes, {String? task}) async {
          final id = await pomodoro.startSession(
            kind: PomodoroKind.foco,
            plannedMinutes: minutes,
            startedAt: at,
            taskId: task,
          );
          await pomodoro.finishSession(
            id,
            endedAt: at.add(Duration(minutes: minutes)),
            completed: true,
          );
        }

        await focus(d(23, 9), 25, task: calc);
        await focus(d(23, 10), 25, task: calc);
        await focus(d(20, 9), 30);
        await pomodoro.startSession(
          kind: PomodoroKind.pausaCurta,
          plannedMinutes: 5,
          startedAt: d(23, 11),
        );

        final cards = CardsRepository(db.cardsDao);
        final card = await cards.createCard(front: 'f', back: 'v', now: d(1));
        await cards.addReviewLog(cardId: card, rating: 4, reviewedAt: d(22, 9));
        await cards.addReviewLog(cardId: card, rating: 3, reviewedAt: d(23, 9));
        await cards.addReviewLog(
          cardId: card,
          rating: 1,
          reviewedAt: d(23, 10),
        );
      },
    );
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await settle(tester);
    await tester.tap(find.text('Métricas'));
    await settle(tester);

    // Hoje, esta semana (começa hoje, segunda) e este mês.
    expect(find.text('50 min'), findsNWidgets(3)); // hoje, semana, Cálculo
    expect(find.text('1 h 20 min'), findsOneWidget);
    expect(find.text('Cálculo'), findsNWidgets(2)); // foco e estimado
    expect(find.text('Sem tarefa'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);

    await tester.tap(find.text('Tag'));
    await settle(tester);
    expect(find.text('Faculdade'), findsOneWidget);
    expect(find.text('Sem tag'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('2 de 4'), 200, scrollable: list);
    expect(find.text('2 de 4'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Acerto (30 dias)'),
      200,
      scrollable: list,
    );
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('Dias seguidos'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('2 conclusões nas últimas 17 semanas'),
      200,
      scrollable: list,
    );
    expect(find.byTooltip('seg, 23 nov: 1'), findsOneWidget);
    expect(find.byTooltip('sex, 20 nov: 1'), findsOneWidget);
  });

  testWidgets('sem dados, as seções mostram estados vazios', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await settle(tester);
    await tester.tap(find.text('Métricas'));
    await settle(tester);
    expect(find.text('Nenhum foco no período.'), findsOneWidget);
    expect(
      find.text('Iniciar foco'),
      findsOneWidget,
    ); // ação, não gráfico vazio
    await tester.scrollUntilVisible(
      find.text('Nenhuma tarefa com pomodoros estimados.'),
      200,
      scrollable: list,
    );
    expect(
      find.text('Nenhuma tarefa com pomodoros estimados.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Acerto (30 dias)'),
      200,
      scrollable: list,
    );
    expect(find.text('–'), findsOneWidget); // sem revisões, sem taxa
    await tester.scrollUntilVisible(
      find.text('0 conclusões nas últimas 17 semanas'),
      200,
      scrollable: list,
    );
  });
}
