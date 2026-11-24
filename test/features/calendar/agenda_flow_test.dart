import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/calendar/calendar_providers.dart';

import '../../helpers/pump_app.dart';

// "Hoje" dos testes: segunda, 23/11/2026, meio-dia. Em 360 dp a semana
// mostra 3 dias (23 a 25), a 56 dp por hora, rolada para começar às 11h.
DateTime d(int day, [int h = 0, int m = 0]) => DateTime(2026, 11, day, h, m);

TasksRepository tasksOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

Future<void> goToAgenda(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Agenda'),
    ),
  );
  await settle(tester);
}

Future<Task> taskNamed(
  WidgetTester tester,
  AppDatabase db,
  String title,
) async => (await tester.runAsync(
  () => (db.select(db.tasks)..where((t) => t.title.equals(title))).getSingle(),
))!;

/// O bloco (área com os gestos) que contém [title].
Finder blockOf(String title) => find
    .ancestor(of: find.text(title), matching: find.byType(GestureDetector))
    .first;

/// Toque longo em [at], arrasta [by] e solta.
Future<void> longDrag(WidgetTester tester, Offset at, Offset by) async {
  final gesture = await tester.startGesture(at);
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  await gesture.moveBy(by / 2);
  await tester.pump();
  await gesture.moveBy(by / 2);
  await tester.pump();
  await gesture.up();
  await settle(tester);
}

void main() {
  testWidgets('semana mostra blocos, dia inteiro, rotina e a próxima tarefa', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final tasks = tasksOf(db);
        await tasks.createTask(
          title: 'Reunião',
          startAt: d(23, 14),
          dueAt: d(23, 15),
          hasTime: true,
        );
        await tasks.createTask(title: 'Aniversário', dueAt: d(24));
        await tasks.createTask(
          title: 'Correr',
          kind: TaskKind.rotina,
          dueAt: d(23, 18),
          hasTime: true,
          recurrenceRule: 'FREQ=DAILY',
        );
        await tasks.createTask(title: 'Fora', dueAt: d(27, 14), hasTime: true);
      },
    );
    await goToAgenda(tester);

    expect(find.text('Novembro'), findsOneWidget);
    expect(find.text('Reunião'), findsOneWidget);
    expect(find.text('14:00–15:00'), findsOneWidget);
    expect(find.text('Aniversário'), findsOneWidget);
    expect(find.text('Correr'), findsNWidgets(3)); // real + 2 virtuais
    expect(find.text('Fora'), findsNothing);
    expect(
      find.textContaining(
        'Próxima tarefa em 2 h\n14:00 · Reunião',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reunião'));
    await settle(tester);
    expect(find.text('Tarefa'), findsOneWidget); // hub
  });

  testWidgets('arrastar reagenda mantendo a duração; a borda muda o fim', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTask(
        title: 'Estudo',
        startAt: d(23, 14),
        dueAt: d(23, 15),
        hasTime: true,
      ),
    );
    await goToAgenda(tester);

    // Uma hora para baixo (56 dp) e um dia para a direita.
    const dayWidth = (360 - 48) / 3;
    await longDrag(
      tester,
      tester.getCenter(blockOf('Estudo')),
      const Offset(dayWidth, 56),
    );
    var task = await taskNamed(tester, db, 'Estudo');
    expect((task.startAt, task.dueAt), (d(24, 15), d(24, 16)));

    // Borda de baixo: +30 min.
    final block = tester.getRect(blockOf('Estudo'));
    await longDrag(
      tester,
      Offset(block.center.dx, block.bottom - 6),
      const Offset(0, 28),
    );
    task = await taskNamed(tester, db, 'Estudo');
    expect((task.startAt, task.dueAt), (d(24, 15), d(24, 16, 30)));
  });

  testWidgets('arrastar ocorrência virtual reagenda a rotina inteira', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTask(
        title: 'Ler',
        kind: TaskKind.rotina,
        dueAt: d(23, 14),
        hasTime: true,
        recurrenceRule: 'FREQ=DAILY',
      ),
    );
    await goToAgenda(tester);

    final virtual = find.text('Ler').at(1); // dia 24
    await longDrag(
      tester,
      tester.getCenter(
        find
            .ancestor(of: virtual, matching: find.byType(GestureDetector))
            .first,
      ),
      const Offset(0, -56),
    );
    final task = await taskNamed(tester, db, 'Ler');
    expect(task.dueAt, d(23, 13));
    expect(
      find.text('Rotina reagendada (todas as ocorrências).'),
      findsOneWidget,
    );
  });

  testWidgets('toque longo em horário vazio cria tarefa ali (15 min)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await goToAgenda(tester);

    // 15:20 no primeiro dia: o topo da grade está em 11h.
    final grid = tester.getTopLeft(find.byType(SingleChildScrollView).last);
    final y = grid.dy + (15 - 11) * 56 + 20 * 56 / 60;
    await tester.longPressAt(Offset(grid.dx + 48 + 20, y));
    await settle(tester);

    expect(find.text('Nova tarefa'), findsOneWidget);
    expect(find.text('15:15'), findsOneWidget);
    expect(find.text('16:15'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Ligar');
    await settle(tester);
    await tester.tap(find.text('Salvar'));
    await settle(tester);

    final task = await taskNamed(tester, db, 'Ligar');
    expect(
      (task.startAt, task.dueAt, task.hasTime),
      (d(23, 15, 15), d(23, 16, 15), true),
    );
    expect(find.text('Ligar'), findsOneWidget); // de volta à agenda
  });

  testWidgets('mês: chips, +N, lembra o modo e tocar abre o dia', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        final tasks = tasksOf(db);
        for (var i = 1; i <= 5; i++) {
          await tasks.createTask(
            title: 'T$i',
            dueAt: d(25, 8 + i),
            hasTime: true,
          );
        }
      },
    );
    await goToAgenda(tester);
    await tester.tap(find.byTooltip('Visualização'));
    await settle(tester);
    await tester.tap(find.text('Mês'));
    await settle(tester);

    expect(find.text('T1'), findsOneWidget);
    expect(find.text('T3'), findsOneWidget);
    expect(find.text('T4'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    final saved = await tester.runAsync(
      () =>
          SettingsRepository(db.settingsDao)
              .getString(CalendarSettings.modeKey),
    );
    expect(saved, 'mes');

    await tester.tap(find.text('25'));
    await settle(tester);
    expect(find.text('T5'), findsOneWidget); // visão Dia do dia 25
    expect(find.text('+2'), findsNothing);
  });

  testWidgets('busca leva ao dia da tarefa', (tester) async {
    await pumpApp(
      tester,
      seed: (db) => tasksOf(
        db,
      ).createTask(title: 'Prova de cálculo', dueAt: d(10, 14), hasTime: true),
    );
    await goToAgenda(tester);
    await tester.tap(find.byTooltip('Buscar'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'calculo');
    await settle(tester);
    await tester.tap(find.text('Prova de cálculo'));
    await settle(tester);

    expect(find.text('Prova de cálculo'), findsOneWidget);
    expect(find.text('ter'), findsOneWidget); // visão Dia: 10/11 é terça
    // Volta para hoje.
    await tester.tap(find.byTooltip('Ir para hoje'));
    await settle(tester);
    expect(find.text('Prova de cálculo'), findsNothing);
  });

  testWidgets('camada de pomodoros mostra as sessões de foco', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        final pomodoro = PomodoroRepository(db.pomodoroDao);
        final id = await pomodoro.startSession(
          kind: PomodoroKind.foco,
          plannedMinutes: 25,
          startedAt: d(23, 11, 10),
        );
        await pomodoro.finishSession(
          id,
          endedAt: d(23, 11, 35),
          completed: true,
        );
        await pomodoro.startSession(
          kind: PomodoroKind.pausaCurta,
          plannedMinutes: 5,
          startedAt: d(23, 11, 35),
        );
      },
    );
    await goToAgenda(tester);
    expect(find.byTooltip('Foco 11:10–11:35'), findsNothing);

    await tester.tap(find.byTooltip('Visualização'));
    await settle(tester);
    await tester.tap(find.text('Pomodoros realizados'));
    await settle(tester);
    expect(find.byTooltip('Foco 11:10–11:35'), findsOneWidget);
    expect(find.byType(Tooltip), findsWidgets);
  });

  testWidgets('deslizar troca de período e a linha do tempo continua viva', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        for (var day = 23; day < 30; day++) {
          await tasksOf(db)
              .createTask(title: 'T$day', dueAt: d(day, 14), hasTime: true);
        }
      },
    );
    await goToAgenda(tester);
    for (final expected in ['T26', 'T29']) {
      await tester.flingFrom(
        const Offset(300, 400),
        const Offset(-250, 0),
        1500,
      );
      await settle(tester);
      // Fora do dia de hoje (sem a linha da hora atual) a grade já chegou a
      // ficar com largura 0 e parar de receber toques.
      expect(find.text(expected).hitTestable(), findsOneWidget);
    }
    await tester.flingFrom(const Offset(100, 400), const Offset(250, 0), 1500);
    await settle(tester);
    expect(find.text('T26').hitTestable(), findsOneWidget);
  });

  testWidgets('bloco curto (15 min) não estoura a altura', (tester) async {
    await pumpApp(
      tester,
      seed: (db) => tasksOf(db).createTask(
        title: 'Rápida com título comprido',
        startAt: d(23, 14),
        dueAt: d(23, 14, 15),
        hasTime: true,
      ),
    );
    await goToAgenda(tester);
    expect(find.text('Rápida com título comprido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
