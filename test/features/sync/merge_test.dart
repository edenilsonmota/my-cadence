import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/sync/domain/merge.dart';
import 'package:my_cadence/features/sync/domain/snapshot.dart';
import 'package:my_cadence/features/sync/domain/upgraders.dart';

final now = DateTime.utc(2026, 11, 24, 12);

String at(int day, [int hour = 0]) =>
    formatSyncDate(DateTime.utc(2026, 11, day, hour));

SyncRow task(String id, String updated, {String? title, String? deleted}) => {
  'id': id,
  'created_at': at(1),
  'updated_at': updated,
  'deleted_at': deleted,
  'title': title ?? id,
  'parent_id': null,
};

Snapshot snap(
  String device,
  Map<String, List<SyncRow>> tables, {
  int schemaVersion = currentSchemaVersion,
  Map<String, DeviceInfo> devices = const {},
}) => Snapshot(
  schemaVersion: schemaVersion,
  generatedAt: now,
  deviceId: device,
  deviceName: device,
  devices: devices,
  tables: {for (final t in syncTables) t: tables[t] ?? const []},
);

List<String> ids(MergeResult r, String table) => [
  for (final row in r.merged.rows(table)) row['id']! as String,
];

void main() {
  group('linha a linha', () {
    test('só local fica e sobe; só remota entra no local', () {
      final r = merge(
        snap('A', {
          'tasks': [task('a', at(20))],
        }),
        snap('B', {
          'tasks': [task('b', at(20))],
        }),
        now: now,
      );
      expect(ids(r, 'tasks'), ['a', 'b']);
      expect(r.toWrite['tasks']!.map((t) => t['id']), ['b']);
      expect(r.remoteChanged, isTrue);
      expect(r.counts.inserted, 1);
    });

    test('nos dois lados vence o updated_at mais recente', () {
      final local = snap('A', {
        'tasks': [
          task('x', at(20), title: 'local mais novo'),
          task('y', at(10), title: 'local velho'),
        ],
      });
      final remote = snap('B', {
        'tasks': [
          task('x', at(10), title: 'remoto velho'),
          task('y', at(21), title: 'remoto mais novo'),
        ],
      });
      final r = merge(local, remote, now: now);
      final titles = {
        for (final t in r.merged.rows('tasks')) t['id']: t['title'],
      };
      expect(titles, {'x': 'local mais novo', 'y': 'remoto mais novo'});
      expect(r.toWrite['tasks']!.map((t) => t['id']), ['y']);
      expect(r.counts.updated, 1);
      expect(r.remoteChanged, isTrue);
    });

    test('empate de updated_at converge igual nos dois sentidos', () {
      final a = snap('A', {
        'tasks': [task('x', at(20), title: 'Alfa')],
      });
      final b = snap('B', {
        'tasks': [task('x', at(20), title: 'Beta')],
      });
      final ab = merge(a, b, now: now);
      final ba = merge(b, a, now: now);
      expect(ab.merged.rows('tasks'), ba.merged.rows('tasks'));
      expect(ab.counts.conflicts, 1);
    });

    test('exclusão × edição: vence a mais recente, nos dois sentidos', () {
      final deleted = task('x', at(21), deleted: at(21));
      final edited = task('x', at(20), title: 'editada antes');
      var r = merge(
        snap('A', {
          'tasks': [edited],
        }),
        snap('B', {
          'tasks': [deleted],
        }),
        now: now,
      );
      expect(r.merged.rows('tasks').single['deleted_at'], at(21));
      expect(r.counts.deleted, 1);

      final editedLater = task('x', at(22), title: 'editada depois');
      r = merge(
        snap('A', {
          'tasks': [deleted],
        }),
        snap('B', {
          'tasks': [editedLater],
        }),
        now: now,
      );
      expect(r.merged.rows('tasks').single['deleted_at'], isNull);
      expect(r.merged.rows('tasks').single['title'], 'editada depois');
    });

    test('idempotente: mesclar de novo com o mesmo remoto não muda nada', () {
      final a = snap('A', {
        'tasks': [task('a', at(20)), task('x', at(10), title: 'velho')],
      });
      final b = snap('B', {
        'tasks': [task('b', at(20)), task('x', at(11), title: 'novo')],
      });
      final once = merge(a, b, now: now);
      final twice = merge(once.merged, b, now: now);
      expect(twice.merged.tables, once.merged.tables);
      expect(twice.localChanged, isFalse);

      // E o remoto atualizado com o resultado não precisa de nova escrita.
      final again = merge(once.merged, once.merged, now: now);
      expect(again.remoteChanged, isFalse);
    });

    test('nada mudou: sem escritas nem envio', () {
      final a = snap('A', {
        'tasks': [task('a', at(20))],
      });
      final r = merge(a, a, now: now);
      expect(r.localChanged, isFalse);
      expect(r.remoteChanged, isFalse);
    });
  });

  test('vínculos com chave natural viram uma linha só', () {
    SyncRow link(String id, String updated) => {
      'id': id,
      'created_at': at(1),
      'updated_at': updated,
      'deleted_at': null,
      'task_id': 't',
      'tag_id': 'g',
    };
    final ab = merge(
      snap('A', {
        'task_tags': [link('L1', at(20))],
      }),
      snap('B', {
        'task_tags': [link('L2', at(21))],
      }),
      now: now,
    );
    expect(ids(ab, 'task_tags'), ['L2']);
    expect(ab.toWrite['task_tags']!.single['id'], 'L2');
  });

  group('tombstones', () {
    test('exclusão com mais de 180 dias sai do resultado e do local', () {
      final old = formatSyncDate(DateTime.utc(2026, 5, 1));
      final r = merge(
        snap('A', {
          'tasks': [task('velha', old, deleted: old), task('viva', at(20))],
        }),
        snap('B', {
          'tasks': [task('velha', old, deleted: old)],
        }),
        now: now,
      );
      expect(ids(r, 'tasks'), ['viva']);
      expect(r.toPurge['tasks'], ['velha']);
      expect(r.counts.purged, 1);
      expect(r.remoteChanged, isTrue);
    });

    test('aparelho inativo há mais de 180 dias não mescla', () {
      final remote = snap(
        'B',
        const {},
        devices: {
          'A': DeviceInfo(name: 'A', lastSyncAt: DateTime.utc(2026, 4, 1)),
        },
      );
      expect(
        () => merge(snap('A', const {}), remote, now: now),
        throwsA(isA<DeviceInactiveException>()),
      );
    });

    test('registra o aparelho e o último sync', () {
      final r = merge(
        snap('A', const {}),
        snap(
          'B',
          const {},
          devices: {'B': DeviceInfo(name: 'B', lastSyncAt: DateTime.utc(2026))},
        ),
        now: now,
      );
      expect(r.merged.devices.keys.toSet(), {'A', 'B'});
      expect(r.merged.devices['A']!.lastSyncAt, now);
    });
  });

  test('updated_at muito no futuro vira aviso', () {
    final r = merge(
      snap('A', const {}),
      snap('B', {
        'tasks': [task('x', formatSyncDate(DateTime.utc(2026, 11, 27)))],
      }),
      now: now,
    );
    expect(r.warnings, hasLength(1));
  });

  test('ajustes do aparelho não entram na mesclagem', () {
    SyncRow setting(String id, String key) => {
      'id': id,
      'created_at': at(1),
      'updated_at': at(20),
      'deleted_at': null,
      'key': key,
      'value': '1',
    };
    final r = merge(
      snap('A', {
        'app_settings': [setting('s1', 'sync.deviceId')],
      }),
      snap('B', {
        'app_settings': [
          setting('s2', 'sync.deviceId'),
          setting('s3', 'calendar.mode'),
          setting('s4', 'pomodoro.focus'),
        ],
      }),
      now: now,
    );
    expect(ids(r, 'app_settings'), ['s4']);
  });

  group('esquema', () {
    test('remoto mais novo é recusado', () {
      expect(
        () => merge(
          snap('A', const {}),
          snap('B', const {}, schemaVersion: currentSchemaVersion + 1),
          now: now,
        ),
        throwsA(isA<SnapshotFormatException>()),
      );
    });

    test('remoto v1 é atualizado antes de mesclar', () {
      final remote = snap('B', {
        'tags': [
          {
            'id': 'g',
            'created_at': at(1),
            'updated_at': at(20),
            'deleted_at': null,
            'name': 'Faculdade',
            'color': 0xFF43A047,
          },
        ],
        'tasks': [
          {...task('t', at(20)), 'color': 123},
        ],
        'notebooks': [
          {
            'id': 'n',
            'created_at': at(1),
            'updated_at': at(20),
            'deleted_at': null,
            'title': 'Física',
            'task_id': null,
            'icon': '📘',
          },
        ],
      }, schemaVersion: 1);
      final r = merge(snap('A', const {}), remote, now: now);
      final tag = r.merged.rows('tags').single;
      expect((tag['color_key'], tag.containsKey('color')), ('verde', false));
      final t = r.merged.rows('tasks').single;
      expect(
        (
          t['color_key'],
          t['icon_key'],
          t['reminder_mode'],
          t.containsKey('color'),
        ),
        (null, null, 'notificacao', false),
      );
      final book = r.merged.rows('notebooks').single;
      expect(book.containsKey('icon'), isFalse);
      expect(r.merged.schemaVersion, currentSchemaVersion);
    });

    test('remoto v3 recebe reminder_mode padrão notificacao', () {
      final remote = snap('B', {
        'tasks': [task('t', at(20))],
      }, schemaVersion: 3);
      final r = merge(snap('A', const {}), remote, now: now);
      expect(r.merged.rows('tasks').single['reminder_mode'], 'notificacao');
      expect(r.merged.schemaVersion, currentSchemaVersion);
    });

    test('remoto v7: tipo vira cor/ícone e estimativa vira tempo', () {
      final remote = snap('B', {
        'tasks': [
          {
            ...task('t', at(20)),
            'kind': 'estudo',
            'color_key': null,
            'icon_key': null,
            'estimated_pomodoros': 2,
          },
        ],
      }, schemaVersion: 7);
      final r = merge(snap('A', const {}), remote, now: now);
      final row = r.merged.rows('tasks').single;
      expect(
        (row['color_key'], row['icon_key'], row['estimated_minutes']),
        ('violeta', 'graduation-cap', 50),
      );
      expect(r.merged.rows('task_templates'), isEmpty);
    });

    test('remoto v6: sessões ganham manual falso', () {
      final remote = snap('B', {
        'pomodoro_sessions': [
          {
            'id': 's',
            'created_at': at(1),
            'updated_at': at(20),
            'deleted_at': null,
            'task_id': null,
            'kind': 'foco',
            'started_at': at(1),
            'ended_at': at(2),
            'planned_minutes': 25,
            'paused_at': null,
            'paused_total_ms': 0,
            'completed': true,
          },
        ],
      }, schemaVersion: 6);
      final r = merge(snap('A', const {}), remote, now: now);
      expect(r.merged.rows('pomodoro_sessions').single['manual'], isFalse);
      expect(r.merged.schemaVersion, currentSchemaVersion);
    });

    test('remoto v5 ganha as tabelas de vínculo de books e decks', () {
      final remote = snap('B', {
        'tasks': [task('t', at(20))],
      }, schemaVersion: 5);
      final r = merge(snap('A', const {}), remote, now: now);
      expect(r.merged.rows('task_notebook_links'), isEmpty);
      expect(r.merged.rows('task_deck_links'), isEmpty);
      expect(r.merged.schemaVersion, currentSchemaVersion);
    });

    test('remoto v4 recebe reminder_offsets e nag_interval_minutes nulos', () {
      final remote = snap('B', {
        'tasks': [
          {...task('t', at(20)), 'reminder_mode': 'alarme'},
        ],
      }, schemaVersion: 4);
      final r = merge(snap('A', const {}), remote, now: now);
      final row = r.merged.rows('tasks').single;
      expect(row['reminder_mode'], 'alarme');
      expect(row.containsKey('reminder_offsets'), isTrue);
      expect(row['reminder_offsets'], isNull);
      expect(row.containsKey('nag_interval_minutes'), isTrue);
      expect(row['nag_interval_minutes'], isNull);
      expect(r.merged.schemaVersion, currentSchemaVersion);
    });

    test('formato desconhecido é recusado com mensagem clara', () {
      expect(
        () => Snapshot.decode('{"format": "outro"}'),
        throwsA(isA<SnapshotFormatException>()),
      );
      expect(
        () => Snapshot.decode(
          '{"format": "my-cadence-sync", "formatVersion": 99}',
        ),
        throwsA(
          isA<SnapshotFormatException>().having(
            (e) => e.message,
            'mensagem',
            contains('Atualize o app'),
          ),
        ),
      );
      expect(
        () => Snapshot.decode('não é json'),
        throwsA(isA<SnapshotFormatException>()),
      );
    });
  });

  test('ida e volta pelo JSON preserva o snapshot', () {
    final s = snap(
      'A',
      {
        'tasks': [task('x', at(20), deleted: at(21))],
      },
      devices: {'A': DeviceInfo(name: 'Pixel', lastSyncAt: now)},
    );
    final back = Snapshot.decode(s.encode());
    expect(back.toJson(), s.toJson());
  });
}
