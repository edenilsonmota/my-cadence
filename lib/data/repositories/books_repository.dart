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

  Future<String> createBook({
    required String title,
    String? colorKey,
    String? iconKey,
  }) async {
    final id = newId();
    await _dao.insertNotebook(
      NotebooksCompanion.insert(
        id: Value(id),
        title: title,
        colorKey: Value(colorKey),
        iconKey: Value(iconKey),
      ),
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
      colorKey: Value(notebook.colorKey),
      iconKey: Value(notebook.iconKey),
    ),
  );

  /// Exclui o caderno e todas as páginas dele.
  Future<void> deleteNotebook(String id) => _dao.softDeleteNotebook(id);

  Stream<List<Notebook>> watchDeletedBooks() => _dao.watchDeletedBooks();

  Future<void> restoreNotebook(String id) => _dao.restoreNotebook(id);

  Stream<List<(NotePage, Notebook)>> watchDeletedPages() =>
      _dao.watchDeletedPages();

  Future<void> restorePage(String id) => _dao.restorePage(id);

  Stream<Notebook?> watchTaskNotebook(String taskId) =>
      _dao.watchTaskNotebook(taskId);

  /// Páginas de todos os books, com o book de cada uma.
  Stream<List<(NotePage, Notebook)>> watchBookPages() => _dao.watchBookPages();

  /// Todas as páginas (books e cadernos de tarefa), para a busca geral.
  Stream<List<(NotePage, Notebook)>> watchAllPages() => _dao.watchAllPages();

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

  /// Troca o ícone da página (`null` = ícone padrão).
  Future<void> setPageIcon(String id, String? iconKey) =>
      _dao.updatePage(id, NotePagesCompanion(iconKey: Value(iconKey)));

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

  /// Vincula a tarefa exatamente a estes books (cria, revive ou desfaz).
  Future<void> setTaskNotebooks(String taskId, Set<String> notebookIds) =>
      _dao.setTaskNotebooks(taskId, notebookIds);

  Future<void> unlinkNotebook(String taskId, String notebookId) =>
      _dao.unlinkNotebook(taskId, notebookId);

  Stream<List<Notebook>> watchLinkedNotebooks(String taskId) =>
      _dao.watchLinkedNotebooks(taskId);

  Stream<List<Task>> watchTasksLinkedToNotebook(String notebookId) =>
      _dao.watchTasksLinkedToNotebook(notebookId);
}
