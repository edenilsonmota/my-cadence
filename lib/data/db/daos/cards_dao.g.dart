// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cards_dao.dart';

// ignore_for_file: type=lint
mixin _$CardsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTable get decks => attachedDatabase.decks;
  $TasksTable get tasks => attachedDatabase.tasks;
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $NotePagesTable get notePages => attachedDatabase.notePages;
  $FlashcardsTable get flashcards => attachedDatabase.flashcards;
  $ReviewLogsTable get reviewLogs => attachedDatabase.reviewLogs;
  $TaskDeckLinksTable get taskDeckLinks => attachedDatabase.taskDeckLinks;
  CardsDaoManager get managers => CardsDaoManager(this);
}

class CardsDaoManager {
  final _$CardsDaoMixin _db;
  CardsDaoManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db.attachedDatabase, _db.decks);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$NotePagesTableTableManager get notePages =>
      $$NotePagesTableTableManager(_db.attachedDatabase, _db.notePages);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db.attachedDatabase, _db.flashcards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db.attachedDatabase, _db.reviewLogs);
  $$TaskDeckLinksTableTableManager get taskDeckLinks =>
      $$TaskDeckLinksTableTableManager(_db.attachedDatabase, _db.taskDeckLinks);
}
