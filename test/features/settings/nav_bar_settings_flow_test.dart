import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/nav_tabs.dart';
import 'package:my_cadence/app/theme/app_theme.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/pomodoro_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';

import '../../helpers/pump_app.dart';

Finder appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

Finder navBarLabel(String text) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(text));

Future<void> openNavBarSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Abrir menu de navegação'));
  await settle(tester);
  await tester.tap(find.text('Ajustes'));
  await settle(tester);
  await tester.tap(find.text('Barra de navegação'));
  await settle(tester);
}

Finder switchOf(String label) => find.descendant(
  of: find.widgetWithText(ListTile, label),
  matching: find.byType(Switch),
);

void main() {
  testWidgets(
    'Ajustes → Barra de navegação respeita limites, grava e restaura padrão',
    (tester) async {
      final db = await pumpApp(tester);
      await openNavBarSettings(tester);

      expect(appBarTitle('Barra de navegação'), findsOneWidget);
      expect(find.text('PRÉVIA · 5 de 5 abas'), findsOneWidget);

      // No máximo (5): interruptores do menu lateral ficam desabilitados com
      // o motivo, e "Restaurar padrão" já começa desabilitado.
      await tester.dragUntilVisible(
        find.text('Pomodoro'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      expect(find.text('Máximo de 5 abas atingido'), findsNWidgets(2));
      expect(tester.widget<Switch>(switchOf('Pomodoro')).onChanged, isNull);

      await tester.dragUntilVisible(
        find.text('Restaurar padrão'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Restaurar padrão'),
            )
            .onPressed,
        isNull,
      );

      // Volta ao topo e desliga Books e Agenda (cai para o mínimo: 3 abas).
      await tester.dragUntilVisible(
        find.text('PRÉVIA · 5 de 5 abas'),
        find.byType(ListView).first,
        const Offset(0, 300),
      );
      await settle(tester);
      await tester.tap(switchOf('Books'));
      await settle(tester);
      await tester.tap(switchOf('Agenda'));
      await settle(tester);

      expect(find.text('PRÉVIA · 3 de 5 abas'), findsOneWidget);
      expect(find.text('Aba inicial · mínimo de 3 abas'), findsOneWidget);
      expect(find.text('Mínimo de 3 abas na barra'), findsNWidgets(2));
      expect(tester.widget<Switch>(switchOf('Hoje')).onChanged, isNull);

      // Liga Pomodoro e Métricas.
      await tester.dragUntilVisible(
        find.text('Métricas'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      await tester.tap(switchOf('Pomodoro'));
      await settle(tester);
      await tester.tap(switchOf('Métricas'));
      await settle(tester);

      final saved = await tester.runAsync(
        () => SettingsRepository(db.settingsDao).getString(navTabsSettingKey),
      );
      expect(saved, 'today,tasks,review,pomodoro,stats');

      // Restaura padrão.
      await tester.dragUntilVisible(
        find.text('Restaurar padrão'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await settle(tester);
      await tester.tap(find.text('Restaurar padrão'));
      await settle(tester);

      final restored = await tester.runAsync(
        () => SettingsRepository(db.settingsDao).getString(navTabsSettingKey),
      );
      expect(restored, encodeNavTabs(defaultNavTabs));
    },
  );

  testWidgets('arrastar na tela de barra de navegação altera a ordem salva', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await openNavBarSettings(tester);

    // Arrasta "Tarefas" (posição 1) para cima de "Hoje" (posição 0).
    final handle = find.descendant(
      of: find.widgetWithText(ListTile, 'Tarefas'),
      matching: find.byIcon(AppIcons.dragHandle),
    );
    await tester.ensureVisible(handle);
    await settle(tester);
    final handleCenter = tester.getCenter(handle);
    final todayTop = tester
        .getTopLeft(find.widgetWithText(ListTile, 'Hoje'))
        .dy;
    final gesture = await tester.startGesture(handleCenter);
    await tester.pump();
    final dy = (todayTop - handleCenter.dy) / 5;
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(Offset(0, dy));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await settle(tester);

    final saved = await tester.runAsync<String?>(
      () => SettingsRepository(db.settingsDao).getString(navTabsSettingKey),
    );
    expect(saved, 'tasks,today,agenda,review,books');
  });

  testWidgets(
    'barra customizada abre na 1ª aba, leva o selo de Revisar e põe o resto no menu',
    (tester) async {
      await pumpApp(
        tester,
        seed: (db) async {
          await SettingsRepository(db.settingsDao)
              .setString(navTabsSettingKey, 'pomodoro,stats,review');
          final cards = CardsRepository(db.cardsDao);
          await cards.createCard(
            front: 'f1',
            back: 'v1',
            now: DateTime(2026, 11, 20),
          );
          await cards.createCard(
            front: 'f2',
            back: 'v2',
            now: DateTime(2026, 11, 20),
          );
        },
      );

      // Abre diretamente em Pomodoro (1ª da barra), com a barra inferior.
      expect(appBarTitle('Pomodoro'), findsOneWidget);
      expect(navBarLabel('Pomodoro'), findsOneWidget);
      expect(navBarLabel('Métricas'), findsOneWidget);
      expect(navBarLabel('Revisar'), findsOneWidget);
      expect(navBarLabel('Hoje'), findsNothing);
      expect(navBarLabel('Books'), findsNothing);

      // O selo de 2 cards vencidos acompanha Revisar na barra.
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // Troca para a aba Métricas dentro do shell (continua com barra e menu).
      await tester.tap(navBarLabel('Métricas'));
      await settle(tester);
      expect(appBarTitle('Métricas'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byTooltip('Abrir menu de navegação'), findsOneWidget);

      // Telas fora da barra aparecem no menu lateral e abrem por cima do shell.
      await tester.tap(find.byTooltip('Abrir menu de navegação'));
      await settle(tester);
      for (final label in ['Hoje', 'Tarefas', 'Agenda', 'Books', 'Ajustes']) {
        expect(
          find.descendant(
            of: find.byType(NavigationDrawer),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.text('Pomodoro'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.text('Books'),
        ),
      );
      await settle(tester);
      expect(appBarTitle('Books'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      expect(appBarTitle('Métricas'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );

  testWidgets('selo de Revisar acompanha Revisar no menu lateral', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await SettingsRepository(db.settingsDao)
            .setString(navTabsSettingKey, 'today,tasks,agenda');
        await CardsRepository(db.cardsDao)
            .createCard(front: 'f', back: 'v', now: DateTime(2026, 11, 20));
      },
    );

    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('Revisar'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'remover a aba ativa nos ajustes volta para a nova 1ª aba sem erro',
    (tester) async {
      await pumpApp(tester);
      expect(appBarTitle('Hoje'), findsOneWidget);

      await openNavBarSettings(tester);
      await tester.tap(switchOf('Hoje'));
      await settle(tester);

      // Volta para Ajustes e depois para o shell.
      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);

      expect(appBarTitle('Tarefas'), findsOneWidget);
      expect(navBarLabel('Hoje'), findsNothing);
      expect(navBarLabel('Tarefas'), findsOneWidget);
    },
  );

  testWidgets(
    'com Pomodoro na barra, mini-player só aparece nas outras abas e troca para ela',
    (tester) async {
      await pumpApp(
        tester,
        clock: () => DateTime(2026, 11, 23, 9, 5),
        seed: (db) async {
          await SettingsRepository(db.settingsDao)
              .setString(navTabsSettingKey, 'today,tasks,pomodoro');
          await PomodoroRepository(db.pomodoroDao).startSession(
            kind: PomodoroKind.foco,
            plannedMinutes: 25,
            startedAt: DateTime(2026, 11, 23, 9),
          );
        },
      );

      // Em Hoje, o mini-player aparece com 20:00.
      expect(appBarTitle('Hoje'), findsOneWidget);
      expect(find.text('Foco · 20:00'), findsOneWidget);

      // Tocar no mini-player troca para a aba Pomodoro e oculta o mini-player.
      await tester.tap(find.text('Foco · 20:00'));
      await settle(tester);
      expect(appBarTitle('Pomodoro'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Foco · 20:00'), findsNothing);
    },
  );
}
