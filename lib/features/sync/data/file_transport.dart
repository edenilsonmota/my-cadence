import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/snapshot.dart';

/// Backup manual: o mesmo snapshot do sync, em JSON legível.
abstract final class BackupFile {
  /// `my-cadence-backup-AAAA-MM-DD-HHmm.json`.
  static String name(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'my-cadence-backup-${now.year}-${two(now.month)}-${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}.json';
  }

  static Uint8List encode(Snapshot snapshot) =>
      Uint8List.fromList(utf8.encode(snapshot.encode(pretty: true)));

  /// Lê o arquivo; lança [SnapshotFormatException] com mensagem para a tela.
  static Snapshot decode(Uint8List bytes) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const SnapshotFormatException('O arquivo não é um texto JSON.');
    }
    return Snapshot.decode(text);
  }
}

/// Cópias automáticas dos dados locais, feitas antes de substituir tudo.
/// Guarda as [keep] mais recentes numa pasta do app.
class LocalBackupStore {
  LocalBackupStore(this.directory, {this.keep = 5});

  final Directory directory;
  final int keep;

  Future<File> save(Snapshot snapshot, DateTime now) async {
    await directory.create(recursive: true);
    final file = File('${directory.path}/${BackupFile.name(now)}');
    await file.writeAsBytes(BackupFile.encode(snapshot), flush: true);
    final all = await list();
    for (final old in all.skip(keep)) {
      await old.delete();
    }
    return file;
  }

  /// Cópias existentes, da mais nova para a mais antiga.
  Future<List<File>> list() async {
    if (!await directory.exists()) return [];
    final files = [
      await for (final f in directory.list())
        if (f is File && f.path.endsWith('.json')) f,
    ]..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }
}
