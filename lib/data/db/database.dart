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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Se a ação da notificação abrir uma segunda conexão (outra engine),
      // WAL e espera evitam "database is locked".
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
