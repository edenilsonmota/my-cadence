import 'dart:io';
import 'dart:typed_data';

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

/// Cópias automáticas diárias (as 7 últimas).
final autoBackupStoreProvider = Provider<Future<LocalBackupStore>>((ref) async {
  final dir = await getApplicationSupportDirectory();
  return LocalBackupStore(Directory('${dir.path}/backups/auto'), keep: 7);
});

final manualBackupProvider = Provider<ManualBackup>(
  (ref) => ManualBackup(
    ref.watch(snapshotRepositoryProvider),
    () => ref.read(backupStoreProvider),
    ref.watch(clockProvider),
    autoStore: () => ref.read(autoBackupStoreProvider),
  ),
);

/// Uma cópia guardada no app: rótulo para a lista e o conteúdo.
typedef BackupCopy = ({String label, Future<Uint8List> Function() read});

/// Cópias guardadas (automáticas e de antes de substituir), da mais nova
/// para a mais antiga. Os testes trocam por uma lista em memória.
final backupCopiesProvider = Provider<Future<List<BackupCopy>> Function()>(
  (ref) => () async {
    final auto = await ref.read(autoBackupStoreProvider);
    final pre = await ref.read(backupStoreProvider);
    final copies = [
      for (final f in await auto.list()) (f, true),
      for (final f in await pre.list()) (f, false),
    ];
    String name(File f) => f.uri.pathSegments.last;
    copies.sort((a, b) => name(b.$1).compareTo(name(a.$1)));
    return [
      for (final (file, isAuto) in copies)
        (
          label:
              '${backupLabel(name(file))} '
              '(${isAuto ? 'automática' : 'antes de substituir'})',
          read: file.readAsBytes,
        ),
    ];
  },
);

/// "24/11/2026 14:15" a partir de `my-cadence-backup-2026-11-24-1415.json`.
String backupLabel(String fileName) {
  final m = RegExp(r'(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})')
      .firstMatch(fileName);
  return m == null ? fileName : '${m[3]}/${m[2]}/${m[1]} ${m[4]}:${m[5]}';
}
