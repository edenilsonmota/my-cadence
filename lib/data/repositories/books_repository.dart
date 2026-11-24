import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/daos/books_dao.dart';
import '../db/database.dart';

/// Books, cadernos das tarefas, páginas e vínculos página ↔ tarefa.
class BooksRepository {
  BooksRepository(this._dao);

  final BooksDao _dao;

  // Cadernos

  Stream<List<Notebook>> watchBooks() => _dao.watchBooks();
  Stream<Notebook?> watchNotebook(String id) => _dao.watchNotebook(id);

  /// Executa [action] numa transação (ex.: importar um book inteiro).
  Future<T> transaction<T>(Future<T> Function() action) =>
      _dao.transaction(action);

  Future<String> createBook({required String title, String? icon}) async {
    final id = newId();
    await _dao.insertNotebook(
      NotebooksCompanion.insert(id: Value(id), title: title, icon: Value(icon)),
    );
    return id;
  }

  /// Caderno próprio da tarefa: devolve o existente ou cria um novo.
  Future<String> taskNotebookId(String taskId, {required String title}) =>
      _dao.transaction(() async {
        final existing = await _dao.getTaskNotebook(taskId);
        if (existing != null) return existing.id;
        final id = newId();
        await _dao.insertNotebook(
          NotebooksCompanion.insert(
            id: Value(id),
            title: title,
            taskId: Value(taskId),
          ),
        );
        return id;
      });

  Future<void> saveNotebook(Notebook notebook) => _dao.updateNotebook(
    notebook.id,
    NotebooksCompanion(
      title: Value(notebook.title),
      icon: Value(notebook.icon),
    ),
  );

  /// Exclui o caderno e todas as páginas dele.
  Future<void> deleteNotebook(String id) => _dao.softDeleteNotebook(id);

  Stream<Notebook?> watchTaskNotebook(String taskId) =>
      _dao.watchTaskNotebook(taskId);

  /// Páginas de todos os books, com o book de cada uma.
  Stream<List<(NotePage, Notebook)>> watchBookPages() => _dao.watchBookPages();

  // Páginas

  Future<NotePage?> getPage(String id) => _dao.getPage(id);
  Stream<NotePage?> watchPage(String id) => _dao.watchPage(id);

  /// Nova ordem das irmãs (posição na lista = `sortOrder`).
  Future<void> reorderPages(List<String> orderedIds) =>
      _dao.reorderPages(orderedIds);
  Stream<List<NotePage>> watchPages(String notebookId) =>
      _dao.watchPages(notebookId);

  Future<String> createPage({
    required String notebookId,
    required String title,
    String? parentPageId,
    String content = '',
    int sortOrder = 0,
  }) async {
    final id = newId();
    await _dao.insertPage(
      NotePagesCompanion.insert(
        id: Value(id),
        notebookId: notebookId,
        title: title,
        parentPageId: Value(parentPageId),
        content: Value(content),
        sortOrder: Value(sortOrder),
      ),
    );
    return id;
  }

  Future<void> savePage(NotePage page) => _dao.updatePage(
    page.id,
    NotePagesCompanion(
      notebookId: Value(page.notebookId),
      parentPageId: Value(page.parentPageId),
      title: Value(page.title),
      content: Value(page.content),
      sortOrder: Value(page.sortOrder),
    ),
  );

  /// Grava só título e conteúdo (o editor não mexe em ordem nem em pai, e
  /// assim não desfaz uma reordenação feita em outra tela).
  Future<void> savePageContent(
    String id, {
    required String title,
    required String content,
  }) => _dao.updatePage(
    id,
    NotePagesCompanion(title: Value(title), content: Value(content)),
  );

  /// Exclui a página e todas as subpáginas.
  Future<void> deletePage(String id) => _dao.softDeletePageTree(id);

  // Vínculos

  Future<void> linkPage(String taskId, String pageId) =>
      _dao.linkPage(taskId, pageId);

  Future<void> unlinkPage(String taskId, String pageId) =>
      _dao.unlinkPage(taskId, pageId);

  Stream<List<NotePage>> watchLinkedPages(String taskId) =>
      _dao.watchLinkedPages(taskId);

  Stream<List<Task>> watchTasksLinkedToPage(String pageId) =>
      _dao.watchTasksLinkedToPage(pageId);
}
