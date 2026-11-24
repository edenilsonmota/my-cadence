import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/app.dart';
import 'package:my_cadence/app/clock.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/providers.dart';
import 'package:my_cadence/features/pomodoro/pomodoro_controller.dart';
import 'package:my_cadence/features/sync/application/account_controller.dart';
import 'package:my_cadence/features/sync/application/sync_service.dart';
import 'package:my_cadence/features/sync/data/google_account.dart';
import 'package:my_cadence/features/sync/domain/sync_transport.dart';
import 'package:my_cadence/features/tasks/alarms.dart';
import 'package:my_cadence/features/tasks/task_providers.dart';
import 'package:my_cadence/features/update/update_providers.dart';

import 'fake_scheduler.dart';
import 'fake_sync.dart';

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
  FakeScheduler? scheduler,
  DateTime Function()? clock,
  List<bool>? screenAwake,
  List<Override> overrides = const [],
  GoogleAccountApi? accountApi,
  SyncTransport? syncTransport,
  ReleaseFetcher? releaseFetcher,
  List<String>? openedUrls,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  if (seed != null) await tester.runAsync(() => seed(db));

  // Plugin de altura do teclado (usado pela barra do editor) não existe no
  // ambiente de teste.
  tester.binding.defaultBinaryMessenger.setMockStreamHandler(
    const EventChannel('keyboardHeightEventChannel'),
    MockStreamHandler.inline(onListen: (_, _) {}),
  );
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...overrides,
        databaseProvider.overrideWithValue(db),
        // Sem Google nem Drive de verdade nos testes.
        googleAccountApiProvider.overrideWithValue(
          accountApi ?? FakeAccountApi(),
        ),
        syncTransportProvider.overrideWithValue(
          syncTransport ?? FakeSyncTransport(),
        ),
        photoFileProvider.overrideWithValue(
          Future.value(File('${Directory.systemTemp.path}/cadence_test_photo')),
        ),
        alarmSchedulerProvider.overrideWithValue(scheduler ?? FakeScheduler()),
        // Sem GitHub nem plugin de versão nos testes.
        releaseFetcherProvider.overrideWithValue(
          releaseFetcher ?? () async => null,
        ),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
        urlOpenerProvider.overrideWithValue((url) async {
          openedUrls?.add(url);
          return true;
        }),
        // Padrão: meio-dia do "hoje" fixo.
        clockProvider.overrideWithValue(
          clock ??
              () => (today ?? DateTime(2026, 11, 23)).add(
                const Duration(hours: 12),
              ),
        ),
        // Sem batida de segundo (o pumpAndSettle nunca terminaria); as telas
        // usam o relógio acima.
        tickerProvider.overrideWith((ref) => const Stream.empty()),
        screenAwakeProvider.overrideWithValue(
          (on) async => screenAwake?.add(on),
        ),
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
