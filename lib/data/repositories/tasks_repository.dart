import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/daos/tags_dao.dart';
import '../db/daos/tasks_dao.dart';
import '../db/database.dart';
import '../db/enums.dart';

/// Tarefas, subtarefas, histórico de rotinas e tags.
class TasksRepository {
  TasksRepository(this._tasks, this._tags);

  final TasksDao _tasks;
  final TagsDao _tags;

  // Leitura

  Future<Task?> getTask(String id) => _tasks.getTask(id);
  Stream<Task?> watchTask(String id) => _tasks.watchTask(id);
  Stream<List<Task>> watchRootTasks() => _tasks.watchRootTasks();
  Stream<List<Task>> watchAllTasks() => _tasks.watchAllTasks();
  Stream<List<Task>> watchOverdue(DateTime before) =>
      _tasks.watchOverdue(before);
  Stream<List<Task>> watchUndatedRoots() => _tasks.watchUndatedRoots();
  Stream<List<Task>> watchSubtasks(String parentId) =>
      _tasks.watchSubtasks(parentId);
  Stream<List<Task>> watchTasksDueBetween(DateTime from, DateTime to) =>
      _tasks.watchTasksDueBetween(from, to);

  /// Ids da tarefa e de todas as subtarefas (para somar pomodoros, cards etc.).
  Future<List<String>> taskTreeIds(String id) => _tasks.taskTreeIds(id);

  // Escrita

  /// Cria a tarefa e devolve o id.
  Future<String> createTask({
    required String title,
    String? parentId,
    TaskKind kind = TaskKind.simples,
    String? notes,
    int priority = 0,
    DateTime? startAt,
    DateTime? dueAt,
    bool hasTime = false,
    String? recurrenceRule,
    int? reminderMinutesBefore,
    int? estimatedPomodoros,
    int? sortOrder,
    int? color,
  }) async {
    final id = newId();
    // Sem ordem explícita, entra no fim da lista das irmãs.
    final order = sortOrder ?? await _tasks.maxSortOrder(parentId) + 1;
    await _tasks.insertTask(
      TasksCompanion.insert(
        id: Value(id),
        title: title,
        parentId: Value(parentId),
        kind: Value(kind),
        notes: Value(notes),
        priority: Value(priority),
        startAt: Value(startAt),
        dueAt: Value(dueAt),
        hasTime: Value(hasTime),
        recurrenceRule: Value(recurrenceRule),
        reminderMinutesBefore: Value(reminderMinutesBefore),
        estimatedPomodoros: Value(estimatedPomodoros),
        sortOrder: Value(order),
        color: Value(color),
      ),
    );
    return id;
  }

  /// Grava os campos editáveis de [task] (as colunas de sync não são tocadas).
  Future<void> saveTask(Task task) => _tasks.updateTask(
    task.id,
    TasksCompanion(
      parentId: Value(task.parentId),
      title: Value(task.title),
      notes: Value(task.notes),
      kind: Value(task.kind),
      status: Value(task.status),
      priority: Value(task.priority),
      startAt: Value(task.startAt),
      dueAt: Value(task.dueAt),
      hasTime: Value(task.hasTime),
      recurrenceRule: Value(task.recurrenceRule),
      reminderMinutesBefore: Value(task.reminderMinutesBefore),
      estimatedPomodoros: Value(task.estimatedPomodoros),
      sortOrder: Value(task.sortOrder),
      completedAt: Value(task.completedAt),
      color: Value(task.color),
    ),
  );

  /// Muda o status. `feita` grava [now] em `completedAt`; os outros limpam.
  ///
  /// Rotinas ainda são concluídas como tarefas comuns; avançar para a próxima
  /// ocorrência entra na Etapa 3.
  Future<void> setStatus(String id, TaskStatus status, {DateTime? now}) =>
      _tasks.updateTask(
        id,
        TasksCompanion(
          status: Value(status),
          completedAt: Value(
            status == TaskStatus.feita ? now ?? DateTime.now() : null,
          ),
        ),
      );

  /// Grava a nova ordem das irmãs (posição na lista = `sortOrder`).
  Future<void> reorder(List<String> orderedIds) => _tasks.reorder(orderedIds);

  /// Exclui a tarefa e todas as subtarefas. Devolve os ids excluídos, para
  /// desfazer com [restoreTasks].
  Future<List<String>> deleteTask(String id) => _tasks.softDeleteTaskTree(id);

  Future<void> restoreTasks(List<String> ids) => _tasks.restoreTasks(ids);

  // Histórico de rotinas

  Stream<List<TaskCompletion>> watchCompletions(String taskId) =>
      _tasks.watchCompletions(taskId);

  Future<String> addCompletion(String taskId, DateTime occurrence) async {
    final id = newId();
    await _tasks.insertCompletion(
      TaskCompletionsCompanion.insert(
        id: Value(id),
        taskId: taskId,
        occurrence: occurrence,
      ),
    );
    return id;
  }

  Future<void> deleteCompletion(String id) => _tasks.softDeleteCompletion(id);

  // Tags

  Stream<List<Tag>> watchTags() => _tags.watchTags();
  Stream<List<Tag>> watchTagsOfTask(String taskId) =>
      _tags.watchTagsOfTask(taskId);

  /// Mapa tarefa → ids das tags dela.
  Stream<Map<String, Set<String>>> watchTagIdsByTask() =>
      _tags.watchAllLinks().map((links) {
        final map = <String, Set<String>>{};
        for (final link in links) {
          (map[link.taskId] ??= {}).add(link.tagId);
        }
        return map;
      });

  /// Deixa a tarefa exatamente com as tags [tagIds].
  Future<void> setTaskTags(String taskId, Set<String> tagIds) =>
      _tags.transaction(() async {
        final current = {
          for (final tag in await _tags.watchTagsOfTask(taskId).first) tag.id,
        };
        for (final id in tagIds.difference(current)) {
          await _tags.addTagToTask(taskId, id);
        }
        for (final id in current.difference(tagIds)) {
          await _tags.removeTagFromTask(taskId, id);
        }
      });

  Future<String> createTag({required String name, required int color}) async {
    final id = newId();
    await _tags.insertTag(
      TagsCompanion.insert(id: Value(id), name: name, color: color),
    );
    return id;
  }

  Future<void> saveTag(Tag tag) => _tags.updateTag(
    tag.id,
    TagsCompanion(name: Value(tag.name), color: Value(tag.color)),
  );

  Future<void> deleteTag(String id) => _tags.softDeleteTag(id);

  Future<void> addTagToTask(String taskId, String tagId) =>
      _tags.addTagToTask(taskId, tagId);

  Future<void> removeTagFromTask(String taskId, String tagId) =>
      _tags.removeTagFromTask(taskId, tagId);
}
