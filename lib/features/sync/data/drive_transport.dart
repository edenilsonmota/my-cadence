import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../domain/snapshot.dart';
import '../domain/sync_transport.dart';
import 'google_account.dart';

/// Snapshot compactado na pasta privada do app no Google Drive
/// (`appDataFolder`), com controle de concorrência pelo campo `version`.
class DriveTransport implements SyncTransport {
  DriveTransport({
    required this.client,
    required this.loadFileId,
    required this.saveFileId,
  });

  static const fileName = 'my-cadence-sync.json.gz';
  static const prevFileName = 'my-cadence-sync.prev.json.gz';
  static const _space = 'appDataFolder';

  /// Cliente HTTP autorizado para o Drive.
  final Future<http.Client> Function() client;

  /// Id do arquivo principal guardado localmente.
  final Future<String?> Function() loadFileId;
  final Future<void> Function(String? id) saveFileId;

  drive.DriveApi? _api;
  Future<drive.DriveApi> _drive() async =>
      _api ??= drive.DriveApi(await client());

  /// Erros de rede viram [SyncOfflineException]; 401/403 viram
  /// [AccountAuthException] (entrar de novo).
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException catch (e) {
      throw SyncOfflineException(e);
    } on http.ClientException catch (e) {
      throw SyncOfflineException(e);
    } on TimeoutException catch (e) {
      throw SyncOfflineException(e);
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) {
        throw const AccountAuthException(
          'O acesso ao Google Drive expirou. Entre novamente.',
        );
      }
      rethrow;
    }
  }

  Future<String?> _findId(String name) async {
    final api = await _drive();
    final list = await api.files.list(
      spaces: _space,
      q: "name = '$name' and trashed = false",
      $fields: 'files(id)',
    );
    return list.files?.firstOrNull?.id;
  }

  /// Id do arquivo principal (guardado localmente depois da 1ª busca).
  Future<String?> _fileId() async {
    final saved = await loadFileId();
    if (saved != null && saved.isNotEmpty) return saved;
    final found = await _findId(fileName);
    if (found != null) await saveFileId(found);
    return found;
  }

  Future<String?> _versionOf(String id) async {
    try {
      final file = await (await _drive()).files.get(
        id,
        $fields: 'version',
      ) as drive.File;
      return file.version;
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        await saveFileId(null); // apagado por fora: procura de novo
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<String?> version() => _guard(() async {
    final id = await _fileId();
    return id == null ? null : _versionOf(id);
  });

  @override
  Future<({Snapshot? snapshot, String? version})> fetch() => _guard(() async {
    final id = await _fileId();
    if (id == null) return (snapshot: null, version: null);
    final version = await _versionOf(id);
    if (version == null) return (snapshot: null, version: null);
    final media = await (await _drive()).files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final bytes = <int>[];
    await media.stream.forEach(bytes.addAll);
    final text = utf8.decode(gzip.decode(bytes));
    return (snapshot: Snapshot.decode(text), version: version);
  });

  @override
  Future<String> push(Snapshot snapshot, {String? expectedVersion}) =>
      _guard(() async {
        final api = await _drive();
        final bytes = gzip.encode(utf8.encode(snapshot.encode()));
        drive.Media media() => drive.Media(
          Stream.value(bytes),
          bytes.length,
          contentType: 'application/gzip',
        );
        final id = await _fileId();
        // Outro aparelho gravou depois da nossa leitura: refaz o ciclo.
        final current = id == null ? null : await _versionOf(id);
        if (current != expectedVersion) throw const VersionConflict();

        if (id == null || current == null) {
          final created = await api.files.create(
            drive.File(name: fileName, parents: [_space]),
            uploadMedia: media(),
            $fields: 'id,version',
          );
          await saveFileId(created.id);
          return created.version!;
        }

        // Uma geração de backup do remoto anterior, para recuperação.
        final prev = await _findId(prevFileName);
        if (prev != null) await api.files.delete(prev);
        await api.files.copy(
          drive.File(name: prevFileName, parents: [_space]),
          id,
          $fields: 'id',
        );

        final updated = await api.files.update(
          drive.File(),
          id,
          uploadMedia: media(),
          $fields: 'version',
        );
        return updated.version!;
      });
}
