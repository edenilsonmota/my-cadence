import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/notifications.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/tasks/alarms.dart';

import '../../helpers/fake_scheduler.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'formulário salva modo Alarme, guia permissão de tela cheia e mostra no hub',
    (tester) async {
      final scheduler = FakeScheduler(fullScreenIntentGranted: false);
      final db = await pumpApp(
        tester,
        scheduler: scheduler,
        seed: (db) => TasksRepository(db.tasksDao, db.tagsDao).createTask(
          title: 'Tomar remédio',
          dueAt: DateTime(2026, 11, 24, 8),
          hasTime: true,
        ),
      );

      // Abre a tarefa e entra em Editar.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Tarefas'),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Tomar remédio'));
      await settle(tester);
      await tester.tap(find.byTooltip('Editar'));
      await settle(tester);

      // Escolhe lembrete "Na hora".
      final dropdown = find.byType(DropdownButtonFormField<int?>);
      await tester.dragUntilVisible(
        dropdown,
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      await tester.tap(dropdown);
      await settle(tester);
      await tester.tap(find.text('Na hora').last);
      await settle(tester);

      // Seletor Notificação / Alarme aparece; padrão é Notificação.
      expect(find.text('Notificação'), findsOneWidget);
      final alarmButton = find.descendant(
        of: find.byType(SegmentedButton<ReminderMode>),
        matching: find.text('Alarme'),
      );
      await tester.dragUntilVisible(
        alarmButton,
        find.byType(ListView).first,
        const Offset(0, -150),
      );
      await settle(tester);
      await tester.tap(alarmButton);
      await settle(tester);

      // Sem permissão de tela cheia: mostra aviso com botão para permitir.
      final allowButton = find.text('Permitir tela cheia');
      await tester.dragUntilVisible(
        allowButton,
        find.byType(ListView).first,
        const Offset(0, -150),
      );
      await settle(tester);
      expect(allowButton, findsOneWidget);

      await tester.tap(allowButton);
      await settle(tester);
      expect(scheduler.fullScreenPermissionRequests, 1);
      expect(allowButton, findsNothing);

      // Salva e confere no banco, no agendador e no hub.
      await tester.tap(find.text('Salvar'));
      await settle(tester);

      final task = (await tester.runAsync(
        () => TasksRepository(db.tasksDao, db.tagsDao).watchAllTasks().first,
      ))!.single;
      expect(task.reminderMode, ReminderMode.alarme);
      expect(
        alarmFor(task, DateTime(2026, 11, 23, 12))!.kind,
        AlarmKind.taskAlarm,
      );
      expect(scheduler.permissionRequests, 1);
      expect(find.text('Na hora · Alarme'), findsOneWidget);
    },
  );
}
