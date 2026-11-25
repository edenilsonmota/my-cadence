import 'package:drift/drift.dart';

import '../enums.dart';
import '../sync_columns.dart';
import 'books.dart';
import 'tasks.dart';

class Decks extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
}

/// Deck vinculado a uma tarefa (esquema v6), para acompanhar nas métricas e
/// no hub o que se estuda para ela. Muitos para muitos.
class TaskDeckLinks extends Table with SyncColumns {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get deckId => text().references(Decks, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, deckId},
  ];
}

@TableIndex(name: 'flashcards_due', columns: {#due})
@TableIndex(name: 'flashcards_task_id', columns: {#taskId})
class Flashcards extends Table with SyncColumns {
  TextColumn get deckId => text().nullable().references(Decks, #id)();
  TextColumn get taskId => text().nullable().references(Tasks, #id)();

  /// Página de onde o card foi criado.
  TextColumn get sourcePageId => text().nullable().references(NotePages, #id)();
  TextColumn get front => text()();
  TextColumn get back => text()();

  // Estado FSRS (espelha `fsrs.Card`).
  TextColumn get state =>
      textEnum<CardState>().withDefault(Constant(CardState.learning.name))();
  IntColumn get step => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  DateTimeColumn get due => dateTime()();
  DateTimeColumn get lastReview => dateTime().nullable()();

  BoolColumn get suspended => boolean().withDefault(const Constant(false))();
}

class ReviewLogs extends Table with SyncColumns {
  TextColumn get cardId => text().references(Flashcards, #id)();

  /// 1 = Errei, 2 = Difícil, 3 = Bom, 4 = Fácil.
  // ignore: recursive_getters (padrão do drift para CHECK na própria coluna)
  IntColumn get rating => integer().check(rating.isBetweenValues(1, 4))();
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get durationMs => integer().nullable()();
}
