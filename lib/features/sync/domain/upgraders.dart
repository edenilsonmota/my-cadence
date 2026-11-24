/// Atualiza snapshots de esquemas antigos para o atual. Puro, sem Flutter.
library;

import 'snapshot.dart';

/// Esquema do banco nesta versão do app (igual a `AppDatabase.schemaVersion`;
/// um teste garante que andam juntos).
const currentSchemaVersion = 3;

typedef SnapshotUpgrader = Map<String, List<SyncRow>> Function(
  Map<String, List<SyncRow>> tables,
);

/// `upgraders[n]` leva as linhas da versão n para a n + 1.
final Map<int, SnapshotUpgrader> upgraders = {1: _v1ToV2, 2: _v2ToV3};

/// v2 → v3: páginas ganham `icon_key` (vazio).
Map<String, List<SyncRow>> _v2ToV3(Map<String, List<SyncRow>> tables) => {
  ...tables,
  'note_pages': [
    for (final row in tables['note_pages'] ?? const <SyncRow>[])
      {...row, 'icon_key': row['icon_key']},
  ],
};

/// O snapshot no esquema [target], aplicando os upgraders em sequência.
/// Lança [SnapshotFormatException] se for de um esquema mais novo.
Snapshot upgradeSnapshot(
  Snapshot snapshot, {
  int target = currentSchemaVersion,
}) {
  if (snapshot.schemaVersion > target) {
    throw const SnapshotFormatException(
      'Os dados foram gerados por uma versão mais nova do app. '
      'Atualize o app neste aparelho para sincronizar.',
    );
  }
  var tables = snapshot.tables;
  for (var v = snapshot.schemaVersion; v < target; v++) {
    final step = upgraders[v];
    if (step == null) {
      throw SnapshotFormatException('Não sei atualizar dados da versão $v.');
    }
    tables = step(tables);
  }
  return snapshot.copyWith(schemaVersion: target, tables: tables);
}

/// v1 → v2: cores ARGB das tags viram chave da paleta; tarefas e books
/// perdem `color`/`icon` e ganham `color_key`/`icon_key` (mesma regra da
/// migração do banco).
Map<String, List<SyncRow>> _v1ToV2(Map<String, List<SyncRow>> tables) {
  const tagColors = {
    0xFF1E88E5: 'azul',
    0xFF43A047: 'verde',
    0xFFF4511E: 'laranja',
    0xFF8E24AA: 'violeta',
    0xFFFDD835: 'ambar',
    0xFF00ACC1: 'ciano',
    0xFFD81B60: 'rosa',
    0xFF6D4C41: 'ardosia',
  };
  SyncRow without(SyncRow row, String column, SyncRow extra) => {
    for (final e in row.entries)
      if (e.key != column) e.key: e.value,
    ...extra,
  };
  return {
    ...tables,
    'tags': [
      for (final r in tables['tags'] ?? const <SyncRow>[])
        without(r, 'color', {'color_key': tagColors[r['color']] ?? 'azul'}),
    ],
    'tasks': [
      for (final r in tables['tasks'] ?? const <SyncRow>[])
        without(r, 'color', {'color_key': null, 'icon_key': null}),
    ],
    'notebooks': [
      for (final r in tables['notebooks'] ?? const <SyncRow>[])
        without(r, 'icon', {'color_key': null, 'icon_key': null}),
    ],
  };
}
