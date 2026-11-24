/// Snapshot de sincronização: um documento JSON com todas as linhas de todas
/// as tabelas (inclusive as excluídas). Puro, sem Flutter.
library;

import 'dart:convert';

/// Uma linha: coluna (snake_case, igual ao SQLite) → valor JSON. Datas em ISO
/// 8601 UTC com milissegundos; booleanos como `bool`; enums pelo nome.
typedef SyncRow = Map<String, Object?>;

/// Tabelas sincronizadas, na ordem em que aparecem no snapshot.
const syncTables = [
  'tasks',
  'tags',
  'task_tags',
  'task_completions',
  'pomodoro_sessions',
  'decks',
  'flashcards',
  'review_logs',
  'notebooks',
  'note_pages',
  'task_page_links',
  'app_settings',
];

/// Colunas que identificam a linha para mesclar. Tabelas de vínculo e de
/// ajustes têm chave única natural: dois aparelhos podem criar o mesmo
/// vínculo com ids diferentes, e precisam virar uma linha só.
const naturalKeys = <String, List<String>>{
  'task_tags': ['task_id', 'tag_id'],
  'task_page_links': ['task_id', 'page_id'],
  'app_settings': ['key'],
};

/// Colunas de estado local, que nunca entram no snapshot.
const localColumns = {'dirty', 'server_version'};

/// Ajustes que pertencem ao aparelho (não sincronizam): identificação e
/// estado do sync, preferências de tela.
const localSettingPrefixes = ['sync.', 'device.', 'calendar.'];

bool isLocalSetting(String key) =>
    localSettingPrefixes.any((p) => key.startsWith(p));

/// Chave de mesclagem da linha na [table].
String mergeKey(String table, SyncRow row) {
  final cols = naturalKeys[table];
  if (cols == null) return row['id']! as String;
  return cols.map((c) => '${row[c]}').join('\u0000');
}

/// Data do snapshot (ISO) → [DateTime] UTC; `null` fica `null`.
DateTime? parseSyncDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

/// [DateTime] → texto do snapshot (UTC, com milissegundos).
String formatSyncDate(DateTime date) => date.toUtc().toIso8601String();

/// JSON canônico (chaves ordenadas), para comparar e desempatar linhas.
String canonicalJson(SyncRow row) {
  final keys = row.keys.toList()..sort();
  return jsonEncode({for (final k in keys) k: row[k]});
}

class DeviceInfo {
  const DeviceInfo({required this.name, this.lastSyncAt});

  final String name;
  final DateTime? lastSyncAt;

  Map<String, Object?> toJson() => {
    'name': name,
    'lastSyncAt': lastSyncAt == null ? null : formatSyncDate(lastSyncAt!),
  };

  static DeviceInfo fromJson(Map<String, Object?> json) => DeviceInfo(
    name: json['name'] as String? ?? '',
    lastSyncAt: parseSyncDate(json['lastSyncAt']),
  );
}

/// Snapshot inválido ou incompatível (mensagem em português, para a tela).
class SnapshotFormatException implements Exception {
  const SnapshotFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class Snapshot {
  const Snapshot({
    required this.schemaVersion,
    required this.generatedAt,
    required this.deviceId,
    required this.deviceName,
    required this.devices,
    required this.tables,
  });

  static const format = 'my-cadence-sync';
  static const formatVersion = 1;

  /// Versão do esquema do banco que gerou as linhas.
  final int schemaVersion;
  final DateTime generatedAt;

  /// Aparelho que gerou o snapshot.
  final String deviceId;
  final String deviceName;

  /// Aparelhos que já sincronizaram, com o último sync de cada um.
  final Map<String, DeviceInfo> devices;

  /// Linhas por tabela (todas as de [syncTables], mesmo vazias).
  final Map<String, List<SyncRow>> tables;

  List<SyncRow> rows(String table) => tables[table] ?? const [];

  Snapshot copyWith({
    int? schemaVersion,
    DateTime? generatedAt,
    String? deviceId,
    String? deviceName,
    Map<String, DeviceInfo>? devices,
    Map<String, List<SyncRow>>? tables,
  }) => Snapshot(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    generatedAt: generatedAt ?? this.generatedAt,
    deviceId: deviceId ?? this.deviceId,
    deviceName: deviceName ?? this.deviceName,
    devices: devices ?? this.devices,
    tables: tables ?? this.tables,
  );

  Map<String, Object?> toJson() => {
    'format': format,
    'formatVersion': formatVersion,
    'schemaVersion': schemaVersion,
    'generatedAt': formatSyncDate(generatedAt),
    'generatedBy': {'deviceId': deviceId, 'deviceName': deviceName},
    'devices': {for (final e in devices.entries) e.key: e.value.toJson()},
    'tables': {for (final t in syncTables) t: rows(t)},
  };

  String encode({bool pretty = false}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  /// Lê e valida (formato e versão do formato). A compatibilidade de
  /// `schemaVersion` fica com a mesclagem.
  static Snapshot fromJson(Map<String, Object?> json) {
    if (json['format'] != format) {
      throw const SnapshotFormatException(
        'Este arquivo não é um backup do My Cadence.',
      );
    }
    final version = json['formatVersion'];
    if (version is! int || version > formatVersion || version < 1) {
      throw const SnapshotFormatException(
        'Formato de backup desconhecido. Atualize o app para lê-lo.',
      );
    }
    final by = (json['generatedBy'] as Map?)?.cast<String, Object?>() ?? {};
    final devices = (json['devices'] as Map?)?.cast<String, Object?>() ?? {};
    final tables = (json['tables'] as Map?)?.cast<String, Object?>() ?? {};
    return Snapshot(
      schemaVersion: json['schemaVersion']! as int,
      generatedAt: parseSyncDate(json['generatedAt'])!,
      deviceId: by['deviceId'] as String? ?? '',
      deviceName: by['deviceName'] as String? ?? '',
      devices: {
        for (final e in devices.entries)
          e.key: DeviceInfo.fromJson((e.value! as Map).cast<String, Object?>()),
      },
      tables: {
        for (final t in syncTables)
          t: [
            for (final row in (tables[t] as List?) ?? const [])
              (row as Map).cast<String, Object?>(),
          ],
      },
    );
  }

  static Snapshot decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const SnapshotFormatException('O arquivo não é um JSON válido.');
    }
    if (json is! Map) {
      throw const SnapshotFormatException(
        'Este arquivo não é um backup do My Cadence.',
      );
    }
    return fromJson(json.cast<String, Object?>());
  }
}
