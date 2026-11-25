import 'package:drift/drift.dart'
    show DatabaseConnection, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/clock.dart';
import 'package:my_cadence/app/l10n/l10n.dart';
import 'package:my_cadence/app/theme/app_theme.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/providers.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/tasks/task_providers.dart';
import 'package:my_cadence/features/tasks/widgets/task_tile.dart';
import 'package:my_cadence/shared/widgets/appearance_picker.dart';
import 'package:my_cadence/shared/widgets/metric_card.dart';
import 'package:my_cadence/shared/widgets/tag_chip.dart';

import '../helpers/golden_fonts.dart';
import '../helpers/pump_app.dart' show FixedToday;

final today = DateTime(2026, 11, 24);

/// Os componentes do catálogo, comparados com as imagens de referência em
/// `test/golden/goldens/`. Atualizar: `flutter test --update-goldens test/golden`.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(loadGoldenFonts);

  Future<void> pumpComponent(
    WidgetTester tester,
    Brightness brightness,
    Widget child, {
    AppDatabase? db,
    Size size = const Size(360, 200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (db != null) databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(
            () => today.add(const Duration(hours: 12)),
          ),
          todayProvider.overrideWith(() => FixedToday(today)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(brightness),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en'),
            Locale('es'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(body: child),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final b in Brightness.values) {
    testWidgets('item de tarefa (${b.name})', (tester) async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(() async {
        // Desmonta antes de fechar, para encerrar as consultas observadas.
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      });
      late Task task;
      await tester.runAsync(() async {
        final repo = TasksRepository(db.tasksDao, db.tagsDao);
        final id = await repo.createTask(
          title: 'Estudar FSRS',
          dueAt: DateTime(2026, 11, 24, 15),
          hasTime: true,
          priority: 3,
          colorKey: 'violeta',
          iconKey: 'brain',
          recurrenceRule: 'FREQ=DAILY',
          reminderMinutesBefore: 10,
        );
        await repo.createTask(title: 'Parte 1', parentId: id);
        task = (await repo.getTask(id))!;
      });
      await pumpComponent(
        tester,
        b,
        Column(
          children: [
            TaskTile(task: task, today: today),
            TaskTile(
              task: task.copyWith(
                title: 'Atrasada e concluída',
                dueAt: Value(DateTime(2026, 11, 20)),
              ),
              today: today,
            ),
          ],
        ),
        db: db,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/task_tile_${b.name}.png'),
      );
    });

    testWidgets('chips de tag e cartões de indicador (${b.name})', (
      tester,
    ) async {
      await pumpComponent(
        tester,
        b,
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  TagChip(name: 'Faculdade', colorKey: 'azul'),
                  TagChip(name: 'Saúde', colorKey: 'verde'),
                  TagChip(name: 'Casa', colorKey: 'laranja'),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      value: '1 h 20 min',
                      label: 'Esta semana',
                      delta: '+15 min vs anterior',
                      deltaUp: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: MetricCard(value: '91%', label: 'Acerto (30 dias)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/tag_metric_${b.name}.png'),
      );
    });

    testWidgets('seletor de ícone e cor (${b.name})', (tester) async {
      await pumpComponent(
        tester,
        b,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showAppearancePicker(
                context,
                colorKey: 'teal',
                iconKey: 'book-open',
                inheritedColor: 'azul',
                inheritedIcon: AppIcons.task,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
        size: const Size(360, 720),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/appearance_picker_${b.name}.png'),
      );
    });
  }
}
