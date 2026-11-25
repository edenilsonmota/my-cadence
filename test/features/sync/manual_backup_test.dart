import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';
import 'package:my_cadence/features/sync/application/manual_backup.dart';
import 'package:my_cadence/features/sync/data/file_transport.dart';
import 'package:my_cadence/features/sync/data/snapshot_repository.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';
import 'package:my_cadence/features/sync/domain/upgraders.dart';
import 'package:my_cadence/features/sync/sync_providers.dart';
import 'package:my_cadence/shared/file_access.dart';

import '../../data/test_db.dart';
import '../../helpers/pump_app.dart';
import 'seed.dart';

final now = DateTime(2026, 11, 24, 12);

ManualBackup backupOf(AppDatabase db, Directory dir) => ManualBackup(
  SnapshotRepository(db),
  () async => LocalBackupStore(dir),
  () => now,
);

void main() {
  test('nome do arquivo de backup', () {
    expect(
      BackupFile.name(DateTime(2026, 11, 4, 9, 5)),
      'my-cadence-backup-2026-11-04-0905.json',
    );
  });

  test('exportar e importar mesclando em outro aparelho', () async {
    final dir = await Directory.systemTemp.createTemp('backup');
    addTearDown(() => dir.delete(recursive: true));
    final a = openTestDb();
    await seedEverything(a);
    final file = await backupOf(a, dir).export();
    final bytes = BackupFile.encode(file.snapshot);

    final b = openTestDb();
    await TasksRepository(b.tasksDao, b.tagsDao).createTask(title: 'Só em B');
    final backup = backupOf(b, dir);
    final preview = backup.preview(bytes);
    expect(
      (preview.tasks, preview.cards, preview.books, preview.pages),
      (
        2, // a excluída não conta
        1,
        1,
        2,
      ),
    );
    final counts = await backup.importMerge(preview);
    expect(counts.inserted, greaterThan(0));

    final titles = {
      for (final t in await TasksRepository(
        b.tasksDao,
        b.tagsDao,
      ).watchAllTasks().first)
        t.title,
    };
    expect(titles, containsAll(['Só em B', 'Estudar', 'Parte 1']));
    // Mesclado localmente: sobe no próximo sync quem é só de B.
    expect(await SnapshotRepository(b).hasDirty(), isTrue);
  });

  test('substituir guarda cópia antes e troca tudo', () async {
    final dir = await Directory.systemTemp.createTemp('backup');
    addTearDown(() => dir.delete(recursive: true));
    final a = openTestDb();
    await seedEverything(a);
    final bytes = BackupFile.encode((await backupOf(a, dir).export()).snapshot);

    final b = openTestDb();
    await TasksRepository(b.tasksDao, b.tagsDao).createTask(title: 'Some');
    final backup = backupOf(b, dir);
    final copy = await backup.importReplace(backup.preview(bytes));

    final titles = {
      for (final t in await TasksRepository(
        b.tasksDao,
        b.tagsDao,
      ).watchAllTasks().first)
        t.title,
    };
    expect(titles, {'Estudar', 'Parte 1'});
    // A cópia tem os dados de antes.
    final saved = BackupFile.decode(await copy.readAsBytes());
    expect(saved.rows('tasks').map((r) => r['title']), ['Some']);
    expect(await LocalBackupStore(dir).list(), hasLength(1));
  });

  test('guarda só as 5 cópias mais recentes', () async {
    final dir = await Directory.systemTemp.createTemp('backup');
    addTearDown(() => dir.delete(recursive: true));
    final db = openTestDb();
    final snapshot = await SnapshotRepository(db).readLocal(now: now);
    final store = LocalBackupStore(dir);
    for (var i = 0; i < 7; i++) {
      await store.save(snapshot, now.add(Duration(minutes: i)));
    }
    final files = await store.list();
    expect(files, hasLength(5));
    expect(files.first.path, endsWith('1206.json'));
  });

  test('arquivo inválido explica o problema', () {
    final db = openTestDb();
    final backup = backupOf(db, Directory.systemTemp);
    expect(
      () => backup.preview(Uint8List.fromList('{"format":"x"}'.codeUnits)),
      throwsA(isA<SnapshotFormatException>()),
    );
  });

  testWidgets('ajustes exportam e importam com prévia', (tester) async {
    Uint8List? saved;
    String? savedName;
    late Uint8List incoming;
    await tester.runAsync(() async {
      final other = openTestDb();
      await TasksRepository(
        other.tasksDao,
        other.tagsDao,
      ).createTask(title: 'Do backup');
      incoming = BackupFile.encode(
        await SnapshotRepository(other).readLocal(now: now),
      );
    });
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('backup'),
    ))!;
    final db = await pumpApp(
      tester,
      overrides: [
        fileSaverProvider.overrideWithValue((name, bytes) async {
          savedName = name;
          saved = bytes;
          return true;
        }),
        importFilesPickerProvider.overrideWithValue(
          () async => [(name: 'b.json', bytes: incoming)],
        ),
        backupStoreProvider.overrideWithValue(
          Future.value(LocalBackupStore(dir)),
        ),
      ],
    );
    await tester.tap(find.byTooltip('Abrir menu de navegação'));
    await settle(tester);
    await tester.tap(find.text('Ajustes'));
    await settle(tester);

    await tester.dragUntilVisible(
      find.text('Exportar JSON'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.ensureVisible(find.text('Exportar JSON'));
    await settle(tester);
    await tester.tap(find.text('Exportar JSON'));
    await settle(tester);
    expect(savedName, startsWith('my-cadence-backup-'));
    expect(BackupFile.decode(saved!).rows('tasks'), isEmpty);
    expect(find.text('Backup exportado.'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Importar JSON'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.ensureVisible(find.text('Importar JSON'));
    await settle(tester);
    await tester.tap(find.text('Importar JSON'));
    await settle(tester);
    expect(find.text('1 tarefa'), findsOneWidget);
    await tester.tap(find.text('Importar'));
    await settle(tester);
    expect(find.textContaining('Backup mesclado: 1 novos'), findsOneWidget);
    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks!.single.title, 'Do backup');
  });

  test('cópia automática: uma por dia, guardando as 7 últimas', () async {
    final dir = await Directory.systemTemp.createTemp('auto');
    addTearDown(() => dir.delete(recursive: true));
    final db = openTestDb();
    var clock = DateTime.now();
    ManualBackup backup() => ManualBackup(
      SnapshotRepository(db),
      () async => LocalBackupStore(dir),
      () => clock,
      autoStore: () async => LocalBackupStore(dir, keep: 7),
    );
    expect(await backup().autoBackupIfDue(), isNotNull);
    // Logo depois: ainda não é hora.
    expect(await backup().autoBackupIfDue(), isNull);
    // Um dia depois (a data do arquivo é a real; avança o relógio do app).
    clock = clock.add(const Duration(hours: 25));
    final f = await backup().autoBackupIfDue();
    expect(f, isNotNull);
    expect(
      BackupFile.decode(await f!.readAsBytes()).schemaVersion,
      currentSchemaVersion,
    );
  });

  testWidgets('restaurar uma cópia guardada passa pela prévia', (tester) async {
    late Uint8List copy;
    await tester.runAsync(() async {
      final other = openTestDb();
      await TasksRepository(
        other.tasksDao,
        other.tagsDao,
      ).createTask(title: 'Da cópia');
      copy = BackupFile.encode(
        await SnapshotRepository(other).readLocal(now: now),
      );
    });
    final db = await pumpApp(
      tester,
      overrides: [
        backupCopiesProvider.overrideWithValue(
          () async => [
            (
              label:
                  '${backupLabel('my-cadence-backup-2026-11-20-0830.json')} '
                  '(automática)',
              read: () async => copy,
            ),
          ],
        ),
      ],
    );
    await tester.tap(find.byTooltip('Conta e sincronização').first);
    await settle(tester);
    await tester.ensureVisible(find.text('Restaurar cópia'));
    await settle(tester);
    await tester.tap(find.text('Restaurar cópia'));
    await settle(tester);
    await tester.tap(find.text('20/11/2026 08:30 (automática)'));
    await settle(tester);
    expect(find.text('1 tarefa'), findsOneWidget);
    await tester.tap(find.text('Importar'));
    await settle(tester);
    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect(tasks!.single.title, 'Da cópia');
  });
}
