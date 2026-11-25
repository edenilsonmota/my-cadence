import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/app/theme/theme_settings.dart';
import 'package:my_cadence/app/theme/widget_palette.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/widgets/home_widget_snapshot.dart';
import 'package:my_cadence/features/widgets/home_widget_sync.dart';

import '../../helpers/fake_home_widget.dart';
import '../tasks/fixtures.dart';

void main() {
  final today = DateTime(2026, 11, 24);

  group('buildHomeWidgetSnapshot', () {
    test(
      'monta atrasadas antes de hoje, ignora concluídas e respeita idioma/tema',
      () {
        final overdue = makeTask(
          'atrasada',
          title: 'Pagar boleto',
          dueAt: DateTime(2026, 11, 22),
        );
        final timed = makeTask(
          'hora',
          title: 'Consulta',
          dueAt: DateTime(2026, 11, 24, 15, 30),
          hasTime: true,
        ).copyWith(colorKey: const Value('rosa'));
        final allDay = makeTask(
          'dia',
          title: 'Estudar Dart',
          dueAt: DateTime(2026, 11, 24),
          priority: 2,
        );
        final done = makeTask(
          'feita',
          title: 'Já fiz',
          dueAt: DateTime(2026, 11, 24),
          status: TaskStatus.feita,
        );
        final future = makeTask(
          'futura',
          title: 'Próxima semana',
          dueAt: DateTime(2026, 11, 30),
        );

        final snap = buildHomeWidgetSnapshot(
          tasks: [future, timed, done, allDay, overdue],
          tags: const [],
          tagIdsByTask: const {},
          today: today,
          theme: const ThemeSettings(
            mode: AppThemeMode.dark,
            accent: AppAccentColor.rosa,
            lightsOut: true,
          ),
          lang: 'en',
        );

        expect(snap.dateIso, '2026-11-24');
        expect(snap.themeMode, 'dark');
        expect(snap.lightsOut, isTrue);
        expect(snap.accentArgb, AppAccentColor.rosa.argb);
        expect(snap.todayTitle, 'Today');
        expect(snap.todayDateLabel, 'Tue, Nov 24');
        expect(snap.emptyTodayLabel, 'Nothing for today yet.');
        expect(snap.overdueCount, 1);
        expect(snap.todayCount, 2);
        expect(snap.todayItems.map((e) => e.id).toList(), [
          'atrasada',
          'dia',
          'hora',
        ]);
        expect(snap.todayItems.first.overdue, isTrue);
        expect(snap.todayItems.last.timeLabel, '15:30');
        expect(snap.todayItems.last.colorArgb, argbForWidgetColorKey('rosa'));

        final decoded = jsonDecode(snap.encode()) as Map<String, Object?>;
        expect(decoded['version'], 1);
        expect((decoded['todayItems']! as List).length, 3);
      },
    );

    test('inclui ocorrências virtuais de rotinas que caem hoje', () {
      final routine = makeTask(
        'r1',
        title: 'Correr',
        kind: TaskKind.rotina,
        dueAt: DateTime(2026, 11, 20, 7),
        hasTime: true,
        recurrenceRule: 'FREQ=DAILY',
      );

      final snap = buildHomeWidgetSnapshot(
        tasks: [routine],
        tags: const [],
        tagIdsByTask: const {},
        today: today,
        theme: const ThemeSettings(),
        lang: 'pt',
      );

      // Como o prazo real está em 20/11, entra como atrasada (uma vez só).
      expect(snap.todayItems.map((e) => e.id), ['r1']);
      expect(snap.todayDateLabel, 'Ter, 24 nov');
    });

    test('herda cor da tag quando tarefa não tem cor própria', () {
      final tag = Tag(
        id: 'tag1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        dirty: true,
        name: 'Saúde',
        colorKey: 'verde',
      );
      final task = makeTask('t1', title: 'Academia', dueAt: today);

      final snap = buildHomeWidgetSnapshot(
        tasks: [task],
        tags: [tag],
        tagIdsByTask: const {
          't1': {'tag1'},
        },
        today: today,
        theme: const ThemeSettings(),
      );

      expect(snap.todayItems.single.colorArgb, argbForWidgetColorKey('verde'));
    });
  });

  group('HomeWidgetSync', () {
    test('deduplica payloads iguais e republica quando algo muda', () async {
      final bridge = FakeHomeWidgetBridge();
      final sync = HomeWidgetSync(bridge);
      final task = makeTask('t1', title: 'Ler', dueAt: today);

      await sync.update(
        tasks: [task],
        today: today,
        theme: const ThemeSettings(),
        lang: 'pt',
      );
      expect(bridge.snapshots, hasLength(1));

      // Mesmos dados → não dispara outra escrita nativa.
      await sync.update(tasks: [task]);
      expect(bridge.snapshots, hasLength(1));

      // Troca idioma → republica imediatamente.
      await sync.update(lang: 'es');
      expect(bridge.snapshots, hasLength(2));
      expect(bridge.snapshots.last, contains('"todayTitle":"Hoy"'));
    });
  });

  group('buildWidgetMonth', () {
    test('grade de 42 dias começando na segunda, com hoje e cores', () {
      final a = makeTask('a', dueAt: DateTime(2026, 11, 24));
      final b = makeTask(
        'b',
        dueAt: DateTime(2026, 11, 24, 9),
        hasTime: true,
      ).copyWith(colorKey: const Value('rosa'));
      final many = [
        for (var i = 0; i < 5; i++)
          makeTask('m$i', dueAt: DateTime(2026, 11, 10)),
      ];
      final month = buildWidgetMonth(
        tasks: [a, b, ...many],
        today: DateTime(2026, 11, 24, 15),
        colorKeyOf: (t) => t.colorKey ?? 'azul',
      );
      expect(month.title, 'Novembro 2026');
      expect(month.weekdays, ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']);
      expect(month.days, hasLength(42));
      // 1º/11/2026 é domingo: a grade começa na segunda 26/10.
      expect(month.days.first.iso, '2026-10-26');
      expect(month.days.first.inMonth, isFalse);
      final today = month.days.singleWhere((d) => d.today);
      expect(today.iso, '2026-11-24');
      expect(today.colors, [
        argbForWidgetColorKey('azul'),
        argbForWidgetColorKey('rosa'),
      ]);
      final busy = month.days.singleWhere((d) => d.iso == '2026-11-10');
      expect(busy.colors, hasLength(maxMonthDots));
      expect(busy.more, 2);
    });

    test('rotina diária marca os dias seguintes do mês', () {
      final routine = makeTask(
        'r',
        kind: TaskKind.rotina,
        dueAt: DateTime(2026, 11, 28, 7),
        hasTime: true,
        recurrenceRule: 'FREQ=DAILY',
      );
      final month = buildWidgetMonth(
        tasks: [routine],
        today: DateTime(2026, 11, 24),
        colorKeyOf: (_) => 'verde',
        lang: 'en',
      );
      expect(month.title, 'November 2026');
      final marked = [
        for (final d in month.days)
          if (d.colors.isNotEmpty) d.iso,
      ];
      expect(marked.first, '2026-11-28');
      expect(marked, contains('2026-12-06'));
    });
  });
}
