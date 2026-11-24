import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/app.dart';
import 'package:my_cadence/app/clock.dart';
import 'package:my_cadence/app/nav_tabs.dart';
import 'package:my_cadence/app/nav_tabs_providers.dart';
import 'package:my_cadence/app/notification_navigation.dart';
import 'package:my_cadence/app/router.dart';
import 'package:my_cadence/core/notifications.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/providers.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/tasks/alarms.dart';
import 'package:my_cadence/features/tasks/task_providers.dart';

import '../helpers/fake_scheduler.dart';
import '../helpers/pump_app.dart';

Finder appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

void main() {
  test('rota de cada payload', () {
    expect(NotificationNavigator.routeFor(pomodoroPayload), Routes.pomodoro());
    expect(
      NotificationNavigator.routeFor(pomodoroPayload, pomodoroAsTab: true),
      NavTab.pomodoro.tabRoute,
    );
    expect(NotificationNavigator.routeFor('abc'), Routes.task('abc'));
  });

  testWidgets('aberto pela notificação: empilha sobre as abas, uma vez só', (
    tester,
  ) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        alarmSchedulerProvider.overrideWithValue(FakeScheduler()),
        todayProvider.overrideWith(() => FixedToday(DateTime(2026, 11, 23))),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 23, 12)),
        tickerProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await db.close();
    });
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Como no main: o toque chega antes do primeiro quadro, e duas vezes.
    final navigator = NotificationNavigator(container.read(routerProvider));
    navigator.open(pomodoroPayload);
    navigator.open(pomodoroPayload);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CadenceApp(),
      ),
    );
    await settle(tester);

    expect(appBarTitle('Pomodoro'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await settle(tester);
    expect(appBarTitle('Hoje'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
    'com Pomodoro na barra, notificação abre a aba Pomodoro e tarefa empilha por cima',
    (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      const tabs = [NavTab.today, NavTab.tasks, NavTab.pomodoro];
      final taskId = (await tester.runAsync(() async {
        await SettingsRepository(db.settingsDao)
            .setString(navTabsSettingKey, encodeNavTabs(tabs));
        return TasksRepository(
          db.tasksDao,
          db.tagsDao,
        ).createTask(title: 'Ler');
      }))!;
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialNavTabsProvider.overrideWithValue(tabs),
          alarmSchedulerProvider.overrideWithValue(FakeScheduler()),
          todayProvider.overrideWith(() => FixedToday(DateTime(2026, 11, 23))),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 23, 12)),
          tickerProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await db.close();
      });
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final navigator = NotificationNavigator(
        container.read(routerProvider),
        readNavTabs: () => tabs,
      );
      navigator.open(pomodoroPayload);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CadenceApp(),
        ),
      );
      await settle(tester);

      // Abriu diretamente na aba Pomodoro, com a barra inferior visível.
      expect(appBarTitle('Pomodoro'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Notificação de tarefa empilha o hub por cima da aba atual.
      navigator.open(taskId);
      await settle(tester);
      expect(find.text('Ler'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      expect(appBarTitle('Pomodoro'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );
}
