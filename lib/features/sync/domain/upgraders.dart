/// Atualiza snapshots de esquemas antigos para o atual. Puro, sem Flutter.
library;

import 'snapshot.dart';

/// Esquema do banco nesta versão do app (igual a `AppDatabase.schemaVersion`;
/// um teste garante que andam juntos).
const currentSchemaVersion = 7;

typedef SnapshotUpgrader = Map<String, List<SyncRow>> Function(
  Map<String, List<SyncRow>> tables,
);

/// `upgraders[n]` leva as linhas da versão n para a n + 1.
final Map<int, SnapshotUpgrader> upgraders = {
  1: _v1ToV2,
  2: _v2ToV3,
  3: _v3ToV4,
  4: _v4ToV5,
  5: _v5ToV6,
  6: _v6ToV7,
};

/// v6 → v7: sessões de pomodoro ganham `manual` (falso).
Map<String, List<SyncRow>> _v6ToV7(Map<String, List<SyncRow>> tables) => {
  ...tables,
  'pomodoro_sessions': [
    for (final row in tables['pomodoro_sessions'] ?? const <SyncRow>[])
      {...row, 'manual': row['manual'] ?? false},
  ],
};

/// v5 → v6: novas tabelas `task_notebook_links` e `task_deck_links` (vazias).
Map<String, List<SyncRow>> _v5ToV6(Map<String, List<SyncRow>> tables) => {
  ...tables,
  'task_notebook_links': tables['task_notebook_links'] ?? const [],
  'task_deck_links': tables['task_deck_links'] ?? const [],
};

/// v4 → v5: tarefas ganham `reminder_offsets` e `nag_interval_minutes` (nulos).
Map<String, List<SyncRow>> _v4ToV5(Map<String, List<SyncRow>> tables) => {
  ...tables,
  'tasks': [
    for (final row in tables['tasks'] ?? const <SyncRow>[])
      {
        ...row,
        'reminder_offsets': row['reminder_offsets'],
        'nag_interval_minutes': row['nag_interval_minutes'],
      },
  ],
};

/// v3 → v4: tarefas ganham `reminder_mode` (padrão `notificacao`).
Map<String, List<SyncRow>> _v3ToV4(Map<String, List<SyncRow>> tables) => {
  ...tables,
  'tasks': [
    for (final row in tables['tasks'] ?? const <SyncRow>[])
      {...row, 'reminder_mode': row['reminder_mode'] ?? 'notificacao'},
  ],
};

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
