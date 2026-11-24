import 'dart:io';
import 'dart:typed_data';

import '../data/file_transport.dart';
import '../data/snapshot_repository.dart';
import '../domain/merge.dart';
import '../domain/snapshot.dart';
import '../domain/upgraders.dart';

/// O que um arquivo de backup traz, para a prévia antes de importar.
class ImportPreview {
  ImportPreview(this.snapshot)
    : tasks = _alive(snapshot, 'tasks'),
      cards = _alive(snapshot, 'flashcards'),
      books = _alive(snapshot, 'notebooks', where: (r) => r['task_id'] == null),
      pages = _alive(snapshot, 'note_pages');

  /// Já atualizado para o esquema atual.
  final Snapshot snapshot;
  final int tasks;
  final int cards;
  final int books;
  final int pages;

  DateTime get generatedAt => snapshot.generatedAt;
  String get deviceName => snapshot.deviceName;

  static int _alive(
    Snapshot s,
    String table, {
    bool Function(SyncRow)? where,
  }) => s
      .rows(table)
      .where((r) => r['deleted_at'] == null && (where?.call(r) ?? true))
      .length;
}

/// Exportar e importar o snapshot como arquivo.
class ManualBackup {
  ManualBackup(this._repo, this._store, this._clock);

  final SnapshotRepository _repo;
  final Future<LocalBackupStore> Function() _store;
  final DateTime Function() _clock;

  /// Arquivo com todos os dados deste aparelho: nome e conteúdo.
  Future<({String name, Snapshot snapshot})> export() async {
    final now = _clock();
    return (
      name: BackupFile.name(now),
      snapshot: await _repo.readLocal(now: now),
    );
  }

  /// Valida o arquivo e monta a prévia. Lança [SnapshotFormatException]
  /// (arquivo inválido, formato ou esquema mais novo).
  ImportPreview preview(List<int> bytes) => ImportPreview(
    upgradeSnapshot(
      BackupFile.decode(bytes is Uint8List ? bytes : Uint8List.fromList(bytes)),
    ),
  );

  /// Mescla o arquivo com os dados locais (nada local é apagado).
  Future<MergeCounts> importMerge(ImportPreview preview) async {
    final now = _clock();
    final result = merge(
      await _repo.readLocal(now: now),
      preview.snapshot,
      now: now,
      checkInactive: false,
    );
    await _repo.apply(result);
    return result.counts;
  }

  /// Substitui tudo pelos dados do arquivo, guardando antes uma cópia dos
  /// dados locais. Devolve o arquivo da cópia.
  Future<File> importReplace(ImportPreview preview) async {
    final now = _clock();
    final backup = await (await _store()).save(
      await _repo.readLocal(now: now),
      now,
    );
    await _repo.replaceAll(preview.snapshot, markDirty: true);
    return backup;
  }
}
