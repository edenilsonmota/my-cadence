import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Usado pelo código gerado (clientDefault do id em SyncColumns).
import '../../core/ids.dart';

import 'daos/books_dao.dart';
import 'daos/cards_dao.dart';
import 'daos/pomodoro_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tags_dao.dart';
import 'daos/tasks_dao.dart';
import 'database.steps.dart';
import 'enums.dart';
import 'tables/books.dart';
import 'tables/cards.dart';
import 'tables/pomodoro.dart';
import 'tables/settings.dart';
import 'tables/tasks.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    TaskCompletions,
    Tags,
    TaskTags,
    PomodoroSessions,
    Decks,
    Flashcards,
    ReviewLogs,
    Notebooks,
    NotePages,
    TaskPageLinks,
    TaskNotebookLinks,
    TaskDeckLinks,
    AppSettings,
  ],
  daos: [TasksDao, TagsDao, PomodoroDao, CardsDao, BooksDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Banco do app no armazenamento do aparelho.
  ///
  /// Compartilhado entre isolates (as ações das notificações rodam em outro):
  /// quando os dois estão na mesma engine, as consultas observadas se
  /// atualizam dos dois lados.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'my_cadence',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    ),
  );

  // Ao mudar o esquema: incrementar a versão, rodar
  // `dart run drift_dev make-migrations` e escrever o passo em `onUpgrade`.
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2: cores por chave da paleta e ícones por chave do catálogo.
      from1To2: (m, schema) async {
        await m.alterTable(
          TableMigration(
            schema.tags,
            columnTransformer: {
              // As 8 cores ARGB que o app oferecia viram a chave equivalente.
              schema.tags.colorKey: const CustomExpression<String>(
                'CASE color '
                "WHEN 4280191205 THEN 'azul' "
                "WHEN 4282622023 THEN 'verde' "
                "WHEN 4294201630 THEN 'laranja' "
                "WHEN 4287505578 THEN 'violeta' "
                "WHEN 4294826037 THEN 'ambar' "
                "WHEN 4278234305 THEN 'ciano' "
                "WHEN 4292352864 THEN 'rosa' "
                "WHEN 4285353025 THEN 'ardosia' "
                "ELSE 'azul' END",
              ),
            },
          ),
        );
        // A cor ARGB das tarefas nunca foi gravada pela interface; o emoji
        // dos books não existe no catálogo de ícones. Os dois são descartados.
        await m.alterTable(
          TableMigration(
            schema.tasks,
            newColumns: [schema.tasks.colorKey, schema.tasks.iconKey],
          ),
        );
        await m.alterTable(
          TableMigration(
            schema.notebooks,
            newColumns: [schema.notebooks.colorKey, schema.notebooks.iconKey],
          ),
        );
      },
      // v3: ícone das páginas.
      from2To3: (m, schema) async {
        await m.addColumn(schema.notePages, schema.notePages.iconKey);
      },
      // v4: modo do lembrete nas tarefas (notificação ou alarme).
      from3To4: (m, schema) async {
        await m.addColumn(schema.tasks, schema.tasks.reminderMode);
      },
      // v5: múltiplos lembretes por tarefa e insistência se atrasar.
      from4To5: (m, schema) async {
        await m.addColumn(schema.tasks, schema.tasks.reminderOffsets);
        await m.addColumn(schema.tasks, schema.tasks.nagIntervalMinutes);
      },
      // v6: books e decks vinculados a tarefas.
      from5To6: (m, schema) async {
        await m.createTable(schema.taskNotebookLinks);
        await m.createTable(schema.taskDeckLinks);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Se a ação da notificação abrir uma segunda conexão (outra engine),
      // WAL e espera evitam "database is locked".
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
