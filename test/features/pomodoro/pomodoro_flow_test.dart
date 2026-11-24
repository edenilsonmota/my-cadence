import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/pomodoro/pomodoro_logic.dart';

import '../../helpers/pump_app.dart';

TasksRepository tasksOf(AppDatabase db) =>
    TasksRepository(db.tasksDao, db.tagsDao);

Future<void> openHubAndStartFocus(WidgetTester tester, String title) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Tarefas'),
    ),
  );
  await settle(tester);
  await tester.tap(find.text(title));
  await settle(tester);
  final start = find.text('Iniciar foco');
  await tester.dragUntilVisible(
    start,
    find.byType(ListView).first,
    const Offset(0, -200),
  );
  await tester.tap(start);
  await settle(tester);
}

void main() {
  testWidgets('do hub ao mini-player: iniciar, pausar e retomar', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 23, 9);
    final awake = <bool>[];
    await pumpApp(
      tester,
      clock: () => now,
      screenAwake: awake,
      seed: (db) async {
        await tasksOf(db).createTask(title: 'Estudar', kind: TaskKind.estudo);
        await SettingsRepository(db.settingsDao)
            .setString(PomodoroSettings.keyScreenOn, 'true');
      },
    );
    await openHubAndStartFocus(tester, 'Estudar');

    // Tela do pomodoro com a tarefa já escolhida.
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Estudar'), findsOneWidget);
    await tester.tap(find.text('Iniciar'));
    await settle(tester);
    expect(find.text('Pausar'), findsOneWidget);
    expect(awake, [true]);

    now = DateTime(2026, 11, 23, 9, 10);
    await tester.tap(find.text('Pausar'));
    await settle(tester);
    expect(find.text('Retomar'), findsOneWidget);
    expect(find.text('Foco · pausado'), findsOneWidget);
    expect(awake, [true, false]);

    now = DateTime(2026, 11, 23, 9, 20); // 10 min pausado: continua 15:00
    await tester.tap(find.text('Retomar'));
    await settle(tester);
    expect(find.text('15:00'), findsOneWidget);

    // Volta às abas: o mini-player mostra o tempo e a tarefa.
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);
    expect(awake.last, isFalse);
    expect(find.text('Foco · 15:00'), findsOneWidget);
    expect(find.text('Estudar'), findsWidgets);

    // Toque no mini-player abre a tela.
    await tester.tap(find.text('Foco · 15:00'));
    await settle(tester);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('Parar'), findsOneWidget);
  });

  testWidgets(
    'ao terminar o foco, sugere a pausa e oferece concluir a tarefa',
    (tester) async {
      var now = DateTime(2026, 11, 23, 9);
      final db = await pumpApp(
        tester,
        clock: () => now,
        seed: (db) =>
            tasksOf(db).createTask(title: 'Ler', kind: TaskKind.estudo),
      );
      await openHubAndStartFocus(tester, 'Ler');
      await tester.tap(find.text('Iniciar'));
      await settle(tester);

      // O tempo passa e o timer do fim dispara.
      now = DateTime(2026, 11, 23, 9, 25);
      await tester.pump(const Duration(minutes: 25));
      await settle(tester);

      expect(find.text('Foco concluído!'), findsOneWidget);
      expect(find.text('Próximo: Pausa curta'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Iniciar'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      expect(find.text('Iniciar'), findsOneWidget); // parado de novo
      await tester.dragUntilVisible(
        find.text('Iniciar pausa curta'),
        find.byType(ListView).first,
        const Offset(0, 200),
      );

      await tester.tap(find.text('Concluir "Ler"'));
      await settle(tester);
      final task = (await tester.runAsync(
        () => tasksOf(db).watchAllTasks().first,
      ))!.single;
      expect(task.status, TaskStatus.feita);

      await tester.tap(find.text('Iniciar pausa curta'));
      await settle(tester);
      expect(find.text('Foco concluído!'), findsNothing);
      expect(find.text('Pausa curta'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
    },
  );

  testWidgets('ajustes do pomodoro são gravados', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await settle(tester);
    await tester.tap(find.text('Ajustes'));
    await settle(tester);

    // Foco: 25 → 26.
    final focusRow = find.widgetWithText(ListTile, 'Foco (min)');
    await tester.ensureVisible(focusRow);
    await settle(tester);
    await tester.tap(
      find.descendant(of: focusRow, matching: find.byTooltip('Aumentar')),
    );
    await settle(tester);
    await tester.ensureVisible(find.text('Iniciar pausas sozinho'));
    await settle(tester);
    await tester.tap(find.text('Iniciar pausas sozinho'));
    await settle(tester);

    final values = await tester.runAsync(
      () =>
          SettingsRepository(db.settingsDao)
              .watchPrefix(PomodoroSettings.prefix)
              .first,
    );
    expect(values![PomodoroSettings.keyFocus], '26');
    expect(values[PomodoroSettings.keyAutoBreaks], 'true');
    await tester.dragUntilVisible(
      focusRow,
      find.byType(ListView).first,
      const Offset(0, 200),
    );
    await settle(tester);
    expect(
      find.descendant(of: focusRow, matching: find.text('26')),
      findsOneWidget,
    );
  });
}
