import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/sync/application/sync_engine.dart';
import 'package:my_cadence/features/sync/data/snapshot_repository.dart';
import 'package:my_cadence/features/sync/domain/sync_transport.dart';

import '../../data/test_db.dart';
import '../../helpers/fake_sync.dart';

/// Um "aparelho": banco próprio, o mesmo Drive falso.
class Device {
  Device(this.drive) : db = openTestDb();

  final FakeSyncTransport drive;
  final AppDatabase db;
  String? version;
  DateTime now = DateTime.now();

  TasksRepository get tasks => TasksRepository(db.tasksDao, db.tagsDao);
  SnapshotRepository get repo => SnapshotRepository(db);

  SyncEngine get engine => SyncEngine(
    repo: repo,
    transport: drive,
    loadVersion: () async => version,
    saveVersion: (v) async => version = v,
    clock: () => now,
  );

  Future<Set<String>> titles() async => {
    for (final t in await tasks.watchAllTasks().first) t.title,
  };
}

void main() {
  late FakeSyncTransport drive;
  setUp(() => drive = FakeSyncTransport());

  test(
    'primeiro sync com o Drive vazio envia tudo e limpa o pendente',
    () async {
      final a = Device(drive);
      await a.tasks.createTask(title: 'Primeira');
      final run = await a.engine.run();
      expect(run.pushed, isTrue);
      expect(drive.stored!.rows('tasks').single['title'], 'Primeira');
      expect(await a.repo.hasDirty(), isFalse);
      expect(a.version, drive.currentVersion);
    },
  );

  test('criar em A e ver em B; excluir em B some em A', () async {
    final a = Device(drive), b = Device(drive);
    final id = await a.tasks.createTask(title: 'De A');
    await a.engine.run();
    await b.engine.run();
    expect(await b.titles(), {'De A'});

    await Future<void>.delayed(const Duration(seconds: 1));
    await b.tasks.deleteTask(id);
    await b.engine.run();
    await a.engine.run();
    expect(await a.titles(), isEmpty);
  });

  test(
    'editar a mesma tarefa nos dois offline: vence a mais recente',
    () async {
      final a = Device(drive), b = Device(drive);
      final id = await a.tasks.createTask(title: 'Original');
      await a.engine.run();
      await b.engine.run();

      final ta = (await a.tasks.getTask(id))!;
      await a.tasks.saveTask(ta.copyWith(title: 'Editada em A'));
      await Future<void>.delayed(const Duration(seconds: 1));
      final tb = (await b.tasks.getTask(id))!;
      await b.tasks.saveTask(tb.copyWith(title: 'Editada em B (depois)'));

      await a.engine.run();
      await b.engine.run();
      await a.engine.run();
      expect(await a.titles(), {'Editada em B (depois)'});
      expect(await b.titles(), {'Editada em B (depois)'});
    },
  );

  test('nada mudou: não baixa nem envia', () async {
    final a = Device(drive);
    await a.tasks.createTask(title: 'X');
    await a.engine.run();
    final fetches = drive.fetches, pushes = drive.pushes;
    final run = await a.engine.run();
    expect(run.skipped, isTrue);
    expect((drive.fetches, drive.pushes), (fetches, pushes));
  });

  test('outro aparelho grava no meio: repete e não perde nada', () async {
    final a = Device(drive), b = Device(drive);
    await b.tasks.createTask(title: 'De B');
    await b.engine.run();

    await a.tasks.createTask(title: 'De A');
    var interfered = false;
    drive.afterFetch = () async {
      if (interfered) return;
      interfered = true;
      // B sincroniza algo novo entre a leitura e a gravação de A.
      await b.tasks.createTask(title: 'De B, no meio');
      drive.afterFetch = null;
      await b.engine.run();
    };
    await a.engine.run();
    expect(interfered, isTrue);
    expect(await a.titles(), {'De A', 'De B', 'De B, no meio'});
    await b.engine.run();
    expect(await b.titles(), {'De A', 'De B', 'De B, no meio'});
  });

  test('edição local durante o sync continua pendente', () async {
    final a = Device(drive);
    final id = await a.tasks.createTask(title: 'Antes');
    drive.beforePush = () async {
      drive.beforePush = null;
      await Future<void>.delayed(const Duration(seconds: 1));
      final t = (await a.tasks.getTask(id))!;
      await a.tasks.saveTask(t.copyWith(title: 'Durante'));
    };
    await a.engine.run();
    expect(await a.repo.hasDirty(), isTrue);
    await a.engine.run();
    expect(drive.stored!.rows('tasks').single['title'], 'Durante');
    expect(await a.repo.hasDirty(), isFalse);
  });

  test('sem rede: lança offline sem mexer no local', () async {
    final a = Device(drive);
    await a.tasks.createTask(title: 'X');
    drive.offlineCalls = 1;
    await expectLater(a.engine.run(), throwsA(isA<SyncOfflineException>()));
    expect(await a.repo.hasDirty(), isTrue);
    await a.engine.run();
    expect(await a.repo.hasDirty(), isFalse);
  });

  test('usar só os da nuvem substitui e registra o aparelho', () async {
    final a = Device(drive), b = Device(drive);
    await a.tasks.createTask(title: 'Na nuvem');
    await a.engine.run();
    await b.tasks.createTask(title: 'Só local');
    await b.engine.replaceWithRemote();
    expect(await b.titles(), {'Na nuvem'});
    final deviceB = await b.repo.deviceId();
    expect(drive.stored!.devices.keys, contains(deviceB));
    // E o próximo sync segue normal.
    final run = await b.engine.run();
    expect(run.skipped, isTrue);
  });
}
