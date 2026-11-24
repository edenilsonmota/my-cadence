import 'package:drift/drift.dart';

import '../sync_columns.dart';
import 'tasks.dart';

class Notebooks extends Table with SyncColumns {
  TextColumn get title => text()();

  /// Preenchido = caderno próprio da tarefa.
  TextColumn get taskId => text().nullable().references(Tasks, #id)();

  /// Chave da paleta; nula = cor neutra.
  TextColumn get colorKey => text().nullable()();

  /// Chave do catálogo de ícones; nula = ícone de book.
  TextColumn get iconKey => text().nullable()();
}

@TableIndex(
  name: 'note_pages_notebook_sort',
  columns: {#notebookId, #sortOrder},
)
class NotePages extends Table with SyncColumns {
  TextColumn get notebookId => text().references(Notebooks, #id)();

  /// Subpágina quando preenchido.
  TextColumn get parentPageId => text().nullable().references(NotePages, #id)();
  TextColumn get title => text()();

  /// JSON do documento do editor (fonte da verdade da página).
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Chave do catálogo de ícones (`IconCatalog`); sem ícone, o de página.
  TextColumn get iconKey => text().nullable()();
}

/// Página de um book vinculada a uma tarefa.
class TaskPageLinks extends Table with SyncColumns {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get pageId => text().references(NotePages, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, pageId},
  ];
}
