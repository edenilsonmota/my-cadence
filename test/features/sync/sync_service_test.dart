import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/providers.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/sync/application/account_controller.dart';
import 'package:my_cadence/features/sync/application/sync_service.dart';
import 'package:my_cadence/features/sync/application/sync_status.dart';
import 'package:my_cadence/features/sync/data/google_account.dart';
import 'package:my_cadence/features/sync/data/snapshot_repository.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';
import 'package:my_cadence/features/sync/domain/sync_transport.dart';

import '../../data/test_db.dart';
import '../../helpers/fake_sync.dart';
import '../../helpers/pump_app.dart';

const me = AccountInfo(id: '1', email: 'eu@exemplo.com', name: 'Eu Mesmo');

/// Transporte que sempre falha com um erro genérico.
class BrokenTransport extends FakeSyncTransport {
  @override
  Future<({Snapshot? snapshot, String? version})> fetch() async =>
      throw StateError('quebrado');
}

Future<ProviderContainer> containerFor(
  AppDatabase db,
  SyncTransport transport, {
  bool connected = true,
  bool auto = true,
}) async {
  final settings = SettingsRepository(db.settingsDao);
  if (connected) await settings.setString(SyncKeys.account, me.toJson());
  if (!auto) await settings.setString(SyncKeys.auto, 'false');
  final dir = await Directory.systemTemp.createTemp('sync');
  addTearDown(() => dir.delete(recursive: true));
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      googleAccountApiProvider.overrideWithValue(
        FakeAccountApi(configured: true, account: me),
      ),
      syncTransportProvider.overrideWithValue(transport),
      photoFileProvider.overrideWithValue(Future.value(File('${dir.path}/p'))),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Espera o serviço sair de "sincronizando".
Future<SyncStatus> settled(ProviderContainer c) async {
  for (var i = 0; i < 100; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final s = c.read(syncServiceProvider);
    if (s.phase != SyncPhase.syncing) return s;
  }
  return c.read(syncServiceProvider);
}

/// Lê o serviço mantendo-o vivo (e a conta carregada).
Future<SyncStatus> start(ProviderContainer c) async {
  c.listen(syncServiceProvider, (_, _) {});
  await c.read(accountProvider.future);
  return settled(c);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('desconectado: nada acontece', () async {
    final db = openTestDb();
    final drive = FakeSyncTransport();
    final c = await containerFor(db, drive, connected: false);
    expect((await start(c)).phase, SyncPhase.disconnected);
    expect(drive.fetches, 0);
  });

  test('conectado: sincroniza ao abrir e registra no log', () async {
    final db = openTestDb();
    await TasksRepository(db.tasksDao, db.tagsDao).createTask(title: 'X');
    final drive = FakeSyncTransport();
    final c = await containerFor(db, drive);
    final status = await start(c);
    expect(status.phase, SyncPhase.idle);
    expect(status.lastSyncAt, isNotNull);
    expect(drive.stored!.rows('tasks'), hasLength(1));
    final log = decodeSyncLog(
      await SettingsRepository(db.settingsDao).getString(SyncKeys.log),
    );
    expect(log.single.result, 'ok');
  });

  test(
    'automático desligado: não sincroniza ao abrir, só pelo botão',
    () async {
      final db = openTestDb();
      final drive = FakeSyncTransport();
      final c = await containerFor(db, drive, auto: false);
      await start(c);
      expect(drive.fetches + drive.versionChecks, 0);
      await c.read(syncServiceProvider.notifier).sync();
      expect(drive.stored, isNotNull);
    },
  );

  test('sem rede fica offline e depois sincroniza', () async {
    final db = openTestDb();
    await TasksRepository(db.tasksDao, db.tagsDao).createTask(title: 'X');
    final drive = FakeSyncTransport()..offlineCalls = 1;
    final c = await containerFor(db, drive);
    expect((await start(c)).phase, SyncPhase.offline);
    await c.read(syncServiceProvider.notifier).sync();
    expect(c.read(syncServiceProvider).phase, SyncPhase.idle);
    expect(await SnapshotRepository(db).hasDirty(), isFalse);
  });

  test('erro só aparece depois de falhas seguidas', () async {
    final db = openTestDb();
    final c = await containerFor(db, BrokenTransport(), auto: false);
    await start(c);
    final service = c.read(syncServiceProvider.notifier);
    await service.sync();
    expect(c.read(syncServiceProvider).phase, SyncPhase.pending);
    await service.sync();
    await service.sync();
    final status = c.read(syncServiceProvider);
    expect(status.phase, SyncPhase.error);
    expect(status.message, isNotNull);
  });

  test('um sync por vez: pedido no meio roda de novo ao terminar', () async {
    final db = openTestDb();
    final drive = FakeSyncTransport();
    final c = await containerFor(db, drive, auto: false);
    await start(c);
    final service = c.read(syncServiceProvider.notifier);
    final first = service.sync();
    final second = service.sync(); // durante o primeiro
    await Future.wait([first, second]);
    await settled(c);
    final log = decodeSyncLog(
      await SettingsRepository(db.settingsDao).getString(SyncKeys.log),
    );
    expect(log, hasLength(2));
    expect(drive.pushes, 1); // o segundo não tinha nada a enviar
  });

  testWidgets('folha da conta sem login configurado oferece o backup', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Conta e sincronização').first);
    await settle(tester);
    expect(find.text('Conectar com Google'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Conectar com Google'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text('Login com Google ainda não configurado neste app.'),
      findsOneWidget,
    );
    expect(find.text('Exportar JSON'), findsOneWidget);
    expect(find.text('Importar JSON'), findsOneWidget);
  });

  testWidgets('conectar com dados dos dois lados pergunta e junta', (
    tester,
  ) async {
    final drive = FakeSyncTransport();
    late Snapshot remote;
    await tester.runAsync(() async {
      final other = openTestDb();
      await TasksRepository(
        other.tasksDao,
        other.tagsDao,
      ).createTask(title: 'Da nuvem');
      remote = await SnapshotRepository(other).readLocal(now: DateTime.now());
    });
    drive.store(remote);
    final api = FakeAccountApi(configured: true, account: me);
    final db = await pumpApp(
      tester,
      seed: (db) =>
          TasksRepository(db.tasksDao, db.tagsDao).createTask(title: 'Local'),
      accountApi: api,
      syncTransport: drive,
    );
    await tester.tap(find.byTooltip('Conta e sincronização').first);
    await settle(tester);
    await tester.tap(find.text('Conectar com Google'));
    await settle(tester);
    expect(find.text('Já existem dados na nuvem'), findsOneWidget);
    await tester.tap(find.text('Juntar'));
    await settle(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await settle(tester);

    final titles = {
      for (final t in (await tester.runAsync(() => db.select(db.tasks).get()))!)
        t.title,
    };
    expect(titles, {'Local', 'Da nuvem'});
    expect(find.text('eu@exemplo.com'), findsOneWidget);
    expect(drive.stored!.rows('tasks').map((r) => r['title']).toSet(), {
      'Local',
      'Da nuvem',
    });
  });
}
