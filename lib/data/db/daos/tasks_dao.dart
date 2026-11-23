import 'package:drift/drift.dart';

import '../database.dart';
import '../sync_writes.dart';
import '../tables/tasks.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks, TaskCompletions])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.attachedDatabase);

  Future<void> insertTask(TasksCompanion row) => insertSynced(tasks, row);

  Future<void> updateTask(String id, TasksCompanion patch) =>
      updateSynced(tasks, id, patch);

  SimpleSelectStatement<$TasksTable, Task> _alive() =>
      select(tasks)..where((t) => t.deletedAt.isNull());

  Future<Task?> getTask(String id) =>
      (_alive()..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Task?> watchTask(String id) =>
      (_alive()..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<List<Task>> watchRootTasks() =>
      (_alive()
            ..where((t) => t.parentId.isNull())
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  Stream<List<Task>> watchSubtasks(String parentId) =>
      (_alive()
            ..where((t) => t.parentId.equals(parentId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  /// Tarefas com prazo em `[from, to)`.
  Stream<List<Task>> watchTasksDueBetween(DateTime from, DateTime to) =>
      (_alive()
            ..where(
              (t) =>
                  t.dueAt.isBiggerOrEqualValue(from) &
                  t.dueAt.isSmallerThanValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
          .watch();

  /// Ids da tarefa e de todas as subtarefas vivas, em qualquer profundidade.
  Future<List<String>> taskTreeIds(String rootId) async {
    final ids = [rootId];
    var frontier = [rootId];
    while (frontier.isNotEmpty) {
      final children =
          await (selectOnly(tasks)
                ..addColumns([tasks.id])
                ..where(
                  tasks.parentId.isIn(frontier) & tasks.deletedAt.isNull(),
                ))
              .map((row) => row.read(tasks.id)!)
              .get();
      ids.addAll(children);
      frontier = children;
    }
    return ids;
  }

  /// Exclui (logicamente) a tarefa e todas as subtarefas.
  Future<void> softDeleteTaskTree(String id) => transaction(() async {
    for (final taskId in await taskTreeIds(id)) {
      await softDeleteSynced(tasks, taskId);
    }
  });

  Future<void> insertCompletion(TaskCompletionsCompanion row) =>
      insertSynced(taskCompletions, row);

  Future<void> softDeleteCompletion(String id) =>
      softDeleteSynced(taskCompletions, id);

  /// Conclusões da tarefa, da mais recente para a mais antiga.
  Stream<List<TaskCompletion>> watchCompletions(String taskId) =>
      (select(taskCompletions)
            ..where((c) => c.taskId.equals(taskId) & c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.desc(c.occurrence)]))
          .watch();
}
