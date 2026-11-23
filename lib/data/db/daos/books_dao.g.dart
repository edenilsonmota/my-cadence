// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books_dao.dart';

// ignore_for_file: type=lint
mixin _$BooksDaoMixin on DatabaseAccessor<AppDatabase> {
  $TasksTable get tasks => attachedDatabase.tasks;
  $NotebooksTable get notebooks => attachedDatabase.notebooks;
  $NotePagesTable get notePages => attachedDatabase.notePages;
  $TaskPageLinksTable get taskPageLinks => attachedDatabase.taskPageLinks;
  BooksDaoManager get managers => BooksDaoManager(this);
}

class BooksDaoManager {
  final _$BooksDaoMixin _db;
  BooksDaoManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db.attachedDatabase, _db.notebooks);
  $$NotePagesTableTableManager get notePages =>
      $$NotePagesTableTableManager(_db.attachedDatabase, _db.notePages);
  $$TaskPageLinksTableTableManager get taskPageLinks =>
      $$TaskPageLinksTableTableManager(_db.attachedDatabase, _db.taskPageLinks);
}
