import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/app.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/providers.dart';
import 'package:my_cadence/features/tasks/task_providers.dart';

/// "Hoje" fixo, sem o timer da meia-noite.
class FixedToday extends TodayNotifier {
  FixedToday(this.day);

  final DateTime day;

  @override
  DateTime build() => day;
}

/// Abre o app inteiro com banco em memória, numa tela de 360 dp.
/// Devolve o banco para o teste preparar ou conferir dados.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  DateTime? today,
  Future<void> Function(AppDatabase db)? seed,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  if (seed != null) await tester.runAsync(() => seed(db));

  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(
          () => FixedToday(today ?? DateTime(2026, 11, 23)),
        ),
      ],
      child: const CadenceApp(),
    ),
  );
  await settle(tester);

  addTearDown(() async {
    // Desmonta antes de fechar, para encerrar as consultas observadas.
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
  return db;
}

/// Como `pumpAndSettle`, mas deixa o banco (que roda em tempo real) responder
/// às escritas e às consultas observadas entre os quadros.
Future<void> settle(WidgetTester tester) async {
  // Quadros avulsos primeiro: enquanto o banco não responde, pode haver um
  // indicador de carregamento girando, e o pumpAndSettle nunca terminaria.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pumpAndSettle();
}
