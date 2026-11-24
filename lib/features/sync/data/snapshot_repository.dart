import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;

import '../../../core/ids.dart';
import '../../../data/db/database.dart';
import '../domain/merge.dart';
import '../domain/snapshot.dart';

/// Ponte entre o banco e o snapshot: lê todas as linhas (pelos metadados das
/// tabelas, por nome de coluna) e aplica o resultado de uma mesclagem.
class SnapshotRepository {
  SnapshotRepository(this._db);

  final AppDatabase _db;

  static const deviceIdKey = 'sync.deviceId';
  static const deviceNameKey = 'sync.deviceName';

  Map<String, TableInfo<Table, dynamic>> get _tables => {
    for (final t in _db.allTables)
      if (syncTables.contains(t.actualTableName)) t.actualTableName: t,
  };

  /// Id deste aparelho (UUID gerado na primeira vez, guardado só aqui).
  Future<String> deviceId() async {
    final dao = _db.settingsDao;
    final existing = await dao.getValue(deviceIdKey);
    if (existing != null) return existing;
    final id = newId();
    await dao.setValue(deviceIdKey, id);
    return id;
  }

  Future<String> deviceName() async =>
      await _db.settingsDao.getValue(deviceNameKey) ?? 'Este aparelho';

  Future<void> setDeviceName(String name) =>
      _db.settingsDao.setValue(deviceNameKey, name);

  /// Snapshot com todas as linhas locais (inclusive excluídas), sem as
  /// colunas de estado local nem os ajustes do aparelho.
  Future<Snapshot> readLocal({required DateTime now}) async {
    final tables = <String, List<SyncRow>>{};
    for (final name in syncTables) {
      final info = _tables[name]!;
      final raw = await _db
          .customSelect('SELECT * FROM "$name" ORDER BY id')
          .get();
      tables[name] = [
        for (final r in raw)
          if (name != 'app_settings' ||
              !isLocalSetting(r.data['key']! as String))
            _toSync(info, r.data),
      ];
    }
    return Snapshot(
      schemaVersion: _db.schemaVersion,
      generatedAt: now,
      deviceId: await deviceId(),
      deviceName: await deviceName(),
      devices: const {},
      tables: tables,
    );
  }

  /// Grava no banco as linhas vindas do remoto e remove os tombstones
  /// vencidos. Uma transação, com as chaves estrangeiras adiadas (subtarefa
  /// pode chegar antes da mãe, página filha antes da página mãe).
  Future<void> apply(MergeResult result) async {
    final tables = _tables;
    final touched = <TableInfo<Table, dynamic>>{};
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final MapEntry(key: name, value: rows) in result.toWrite.entries) {
        final info = tables[name]!;
        touched.add(info);
        for (final row in rows) {
          await _upsert(info, row);
        }
      }
    });
    // Tombstones vencidos: um a um e fora da transação acima, para que uma
    // linha ainda referenciada (o banco recusa) só fique para depois.
    for (final MapEntry(key: name, value: ids) in result.toPurge.entries) {
      final info = tables[name]!;
      for (final id in ids) {
        try {
          await _db.customUpdate(
            'DELETE FROM "$name" WHERE id = ?',
            variables: [Variable<String>(id)],
            updates: {info},
            updateKind: UpdateKind.delete,
          );
        } on SqliteException {
          // Ainda referenciada por outra linha: tenta no próximo sync.
        }
      }
    }
    if (touched.isNotEmpty) {
      _db.notifyUpdates({
        for (final t in touched)
          TableUpdate.onTable(t, kind: UpdateKind.update),
      });
    }
  }

  /// Substitui todos os dados sincronizáveis pelos de [snapshot] (já no
  /// esquema atual). Os ajustes do aparelho ficam. [markDirty]: as linhas
  /// novas sobem no próximo sync (importação manual) ou já estão em sincronia
  /// (dados vindos da nuvem).
  Future<void> replaceAll(Snapshot snapshot, {required bool markDirty}) async {
    final tables = _tables;
    final localSettings = [
      for (final p in localSettingPrefixes) "key NOT LIKE '$p%'",
    ].join(' AND ');
    await _db.transaction(() async {
      await _db.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final name in syncTables.reversed) {
        await _db.customStatement(
          name == 'app_settings'
              ? 'DELETE FROM "$name" WHERE $localSettings'
              : 'DELETE FROM "$name"',
        );
      }
      for (final name in syncTables) {
        for (final row in snapshot.rows(name)) {
          if (name == 'app_settings' && isLocalSetting(row['key']! as String)) {
            continue;
          }
          await _upsert(tables[name]!, row, dirty: markDirty);
        }
      }
    });
    _db.notifyUpdates({
      for (final t in tables.values)
        TableUpdate.onTable(t, kind: UpdateKind.update),
    });
  }

  /// Depois de enviar [sent]: limpa `dirty` só nas linhas cujo `updated_at`
  /// local ainda é o enviado (uma edição feita durante o sync continua suja).
  Future<void> markClean(Snapshot sent) async {
    await _db.transaction(() async {
      for (final name in syncTables) {
        for (final row in sent.rows(name)) {
          await _db.customStatement(
            'UPDATE "$name" SET dirty = 0 WHERE id = ? AND updated_at = ?',
            [row['id'], _seconds(row['updated_at'])],
          );
        }
      }
    });
  }

  /// O aparelho tem dados da pessoa (para a pergunta da primeira conexão)?
  Future<bool> hasUserData() async {
    for (final name in ['tasks', 'flashcards', 'notebooks', 'decks', 'tags']) {
      final row = await _db
          .customSelect(
            'SELECT 1 FROM "$name" WHERE deleted_at IS NULL LIMIT 1',
          )
          .getSingleOrNull();
      if (row != null) return true;
    }
    return false;
  }

  /// Há alguma alteração local ainda não enviada?
  Future<bool> hasDirty() async {
    // Ajustes do aparelho não sobem, então não contam como pendentes.
    final localSettings = [
      for (final p in localSettingPrefixes) "key NOT LIKE '$p%'",
    ].join(' AND ');
    for (final name in syncTables) {
      final filter = name == 'app_settings' ? ' AND $localSettings' : '';
      final row = await _db
          .customSelect('SELECT 1 FROM "$name" WHERE dirty = 1$filter LIMIT 1')
          .getSingleOrNull();
      if (row != null) return true;
    }
    return false;
  }

  Future<void> _upsert(
    TableInfo<Table, dynamic> info,
    SyncRow row, {
    bool dirty = false,
  }) async {
    final name = info.actualTableName;
    // Tabela com chave natural: se o local tem a mesma linha com outro id,
    // ela passa a usar o id vencedor (sem nada referenciando esses ids).
    final natural = naturalKeys[name];
    if (natural != null) {
      await _db.customStatement(
        'UPDATE "$name" SET id = ? WHERE id <> ? AND '
        '${natural.map((c) => '"$c" = ?').join(' AND ')}',
        [row['id'], row['id'], for (final c in natural) row[c]],
      );
    }
    final columns = <String>[], values = <Object?>[];
    for (final col in info.$columns) {
      if (col.name == 'dirty') {
        columns.add('dirty');
        // Veio do remoto: já está sincronizada (salvo importação manual).
        values.add(dirty ? 1 : 0);
      } else if (row.containsKey(col.name) && col.name != 'server_version') {
        columns.add(col.name);
        values.add(_toDb(col, row[col.name]));
      }
    }
    final quoted = columns.map((c) => '"$c"').join(', ');
    final updates = [
      for (final c in columns)
        if (c != 'id') '"$c" = excluded."$c"',
    ].join(', ');
    await _db.customStatement(
      'INSERT INTO "$name" ($quoted) '
      'VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $updates',
      values,
    );
  }

  SyncRow _toSync(TableInfo<Table, dynamic> info, Map<String, Object?> data) =>
      {
        for (final col in info.$columns)
          if (!localColumns.contains(col.name))
            col.name: _fromDb(col, data[col.name]),
      };
}

Object? _fromDb(GeneratedColumn<Object> col, Object? value) {
  if (value == null) return null;
  if (col.type == DriftSqlType.dateTime) {
    return formatSyncDate(
      DateTime.fromMillisecondsSinceEpoch((value as int) * 1000, isUtc: true),
    );
  }
  if (col.type == DriftSqlType.bool) return value == 1;
  return value;
}

Object? _toDb(GeneratedColumn<Object> col, Object? value) {
  if (value == null) return null;
  if (col.type == DriftSqlType.dateTime) return _seconds(value);
  if (col.type == DriftSqlType.bool) return value == true ? 1 : 0;
  if (col.type == DriftSqlType.double && value is int) return value.toDouble();
  return value;
}

/// Data do snapshot → segundos desde a época (o formato do banco).
int? _seconds(Object? iso) =>
    iso == null ? null : parseSyncDate(iso)!.millisecondsSinceEpoch ~/ 1000;
