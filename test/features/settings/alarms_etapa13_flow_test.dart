import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/notification_id.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/tasks/alarm_diagnostics.dart';
import 'package:my_cadence/features/tasks/daily_reminders.dart';
import 'package:my_cadence/features/tasks/reminder_offsets.dart';

import '../../helpers/fake_scheduler.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Diagnóstico em Ajustes lista problemas e abre tela do sistema; '
      'formulário avisa quando o lembrete não vai tocar', (tester) async {
    final scheduler = FakeScheduler(
      diagnostics: const AlarmDiagnostics(
        notificationsEnabled: false,
        alarmsChannelMuted: true,
        batteryOptimizationIgnored: false,
      ),
    );
    await pumpApp(
      tester,
      scheduler: scheduler,
      seed: (db) => TasksRepository(db.tasksDao, db.tagsDao).createTask(
        title: 'Reunião',
        dueAt: DateTime(2026, 11, 24, 15),
        hasTime: true,
      ),
    );

    // Abre Ajustes → Diagnóstico de alarmes.
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await settle(tester);
    await tester.tap(find.text('Ajustes'));
    await settle(tester);

    final diagTile = find.text('Diagnóstico de alarmes');
    await tester.dragUntilVisible(
      diagTile,
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    await settle(tester);
    expect(find.text('3 ajustes recomendados'), findsOneWidget);

    await tester.tap(diagTile);
    await settle(tester);
    expect(find.text('Notificações do app'), findsOneWidget);

    // Toca no primeiro botão "Abrir ajustes" (notificações).
    await tester.tap(find.text('Abrir ajustes').first);
    await settle(tester);
    expect(
      scheduler.openedDiagnostics,
      contains(AlarmDiagnosticAction.notifications),
    );

    // Rola até "Otimização de bateria" no fim da lista.
    final batteryCard = find.text('Otimização de bateria');
    await tester.dragUntilVisible(
      batteryCard,
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await settle(tester);
    expect(batteryCard, findsOneWidget);

    // Volta para a tela inicial e abre o formulário da tarefa.
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Tarefas'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Reunião'));
    await settle(tester);
    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);

    // Marca um lembrete → banner de diagnóstico bloqueante aparece.
    final chip = find.widgetWithText(FilterChip, 'Na hora');
    await tester.dragUntilVisible(
      chip,
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await settle(tester);
    await tester.tap(chip);
    await settle(tester);

    final verDiag = find.text('Ver diagnóstico');
    await tester.dragUntilVisible(
      verDiag,
      find.byType(ListView).first,
      const Offset(0, -150),
    );
    await settle(tester);
    expect(verDiag, findsOneWidget);
  });

  testWidgets(
    'Ajustes liga avisos diários de tarefas e flashcards e persiste horários',
    (tester) async {
      final scheduler = FakeScheduler();
      final db = await pumpApp(tester, scheduler: scheduler);

      await tester.tap(find.byTooltip('Abrir menu de navegação'));
      await settle(tester);
      await tester.tap(find.text('Ajustes'));
      await settle(tester);

      final summarySwitch = find.text('Resumo diário de tarefas');
      await tester.dragUntilVisible(
        summarySwitch,
        find.byType(ListView).first,
        const Offset(0, -250),
      );
      await settle(tester);
      await tester.tap(summarySwitch);
      await settle(tester);

      final reviewSwitch = find.text('Aviso diário de flashcards');
      await tester.dragUntilVisible(
        reviewSwitch,
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      await tester.tap(reviewSwitch);
      await settle(tester);

      final repo = SettingsRepository(db.settingsDao);
      expect(
        await tester.runAsync(
          () => repo.getString(DailyReminderSettings.keySummaryEnabled),
        ),
        'true',
      );
      expect(
        await tester.runAsync(
          () => repo.getString(DailyReminderSettings.keyReviewEnabled),
        ),
        'true',
      );
      expect(scheduler.permissionRequests, greaterThanOrEqualTo(2));
    },
  );

  testWidgets(
    'formulário salva múltiplos lembretes + insistência; hub exibe e adia para amanhã cedo',
    (tester) async {
      final scheduler = FakeScheduler();
      final now = DateTime(2026, 11, 23, 12);
      final db = await pumpApp(
        tester,
        scheduler: scheduler,
        clock: () => now,
        seed: (db) => TasksRepository(db.tasksDao, db.tagsDao).createTask(
          title: 'Entregar TCC',
          dueAt: DateTime(2026, 11, 25, 14),
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
      await tester.tap(find.text('Entregar TCC'));
      await settle(tester);
      await tester.tap(find.byTooltip('Editar'));
      await settle(tester);

      // Seleciona dois lembretes: "Na hora" e "1 dia antes".
      final onTime = find.widgetWithText(FilterChip, 'Na hora');
      await tester.dragUntilVisible(
        onTime,
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      await tester.tap(onTime);
      await settle(tester);

      final oneDay = find.widgetWithText(FilterChip, '1 dia antes');
      await tester.ensureVisible(oneDay);
      await tester.tap(oneDay);
      await settle(tester);

      // Ativa "Insistir se atrasar": A cada 15 min.
      final nag15 = find.widgetWithText(ChoiceChip, 'A cada 15 min');
      await tester.dragUntilVisible(
        nag15,
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      await tester.tap(nag15);
      await settle(tester);

      await tester.tap(find.text('Salvar'));
      await settle(tester);

      // Confere no banco e no hub.
      final task = (await tester.runAsync(
        () => TasksRepository(db.tasksDao, db.tagsDao).watchAllTasks().first,
      ))!.single;
      expect(effectiveReminderOffsets(task), [0, 1440]);
      expect(task.nagIntervalMinutes, 15);
      expect(find.text('Na hora, 1 dia antes'), findsOneWidget);
      expect(find.text('A cada 15 min (até 5×)'), findsOneWidget);

      // Adia para "Amanhã cedo (09:00)" pelo hub.
      final snoozeButton = find.byTooltip('Adiar');
      await tester.dragUntilVisible(
        snoozeButton,
        find.byType(ListView).first,
        const Offset(0, -150),
      );
      await settle(tester);
      await tester.tap(snoozeButton);
      await settle(tester);
      await tester.tap(find.text('Amanhã cedo (09:00)'));
      await settle(tester);

      expect(
        scheduler.pending[notificationIdFor(task.id)]!.time,
        DateTime(2026, 11, 24, 9),
      );
      expect(find.textContaining('Lembrete adiado para'), findsOneWidget);
    },
  );
}
