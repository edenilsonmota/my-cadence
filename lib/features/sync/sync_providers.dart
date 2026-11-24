import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/clock.dart';
import '../../data/providers.dart';
import 'application/manual_backup.dart';
import 'data/file_transport.dart';
import 'data/snapshot_repository.dart';

final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => SnapshotRepository(ref.watch(databaseProvider)),
);

/// Pasta das cópias automáticas (os testes trocam por uma pasta temporária).
final backupStoreProvider = Provider<Future<LocalBackupStore>>((ref) async {
  final dir = await getApplicationSupportDirectory();
  return LocalBackupStore(Directory('${dir.path}/backups'));
});

final manualBackupProvider = Provider<ManualBackup>(
  (ref) => ManualBackup(
    ref.watch(snapshotRepositoryProvider),
    () => ref.read(backupStoreProvider),
    ref.watch(clockProvider),
  ),
);
