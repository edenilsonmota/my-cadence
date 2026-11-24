import 'package:drift/drift.dart';

import '../database.dart';
import '../enums.dart';
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

  /// Todas as tarefas vivas (a árvore é montada pelo chamador).
  Stream<List<Task>> watchAllTasks() =>
      (_alive()..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .watch();

  /// Não concluídas com prazo antes de [before].
  Stream<List<Task>> watchOverdue(DateTime before) =>
      (_alive()
            ..where(
              (t) =>
                  t.dueAt.isSmallerThanValue(before) &
                  t.status.equalsValue(TaskStatus.feita).not(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
          .watch();

  /// Tarefas raiz sem prazo e não concluídas.
  Stream<List<Task>> watchUndatedRoots() =>
      (_alive()
            ..where(
              (t) =>
                  t.dueAt.isNull() &
                  t.parentId.isNull() &
                  t.status.equalsValue(TaskStatus.feita).not(),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .watch();

  /// Maior `sortOrder` entre as irmãs (subtarefas de [parentId], ou raízes).
  Future<int> maxSortOrder(String? parentId) async {
    final max = tasks.sortOrder.max();
    final query = selectOnly(tasks)
      ..addColumns([max])
      ..where(
        (parentId == null
                ? tasks.parentId.isNull()
                : tasks.parentId.equals(parentId)) &
            tasks.deletedAt.isNull(),
      );
    return await query.map((row) => row.read(max)).getSingle() ?? -1;
  }

  /// Grava `sortOrder` = posição na lista, para as tarefas em [orderedIds].
  Future<void> reorder(List<String> orderedIds) => transaction(() async {
    for (final (index, id) in orderedIds.indexed) {
      await updateSynced(tasks, id, TasksCompanion(sortOrder: Value(index)));
    }
  });

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

  /// Tarefas do calendário em `[from, to)`: as que têm início ou prazo
  /// tocando o intervalo, mais todas as rotinas com prazo antes de [to] (as
  /// ocorrências delas são calculadas depois).
  Stream<List<Task>> watchTasksInRange(DateTime from, DateTime to) =>
      (_alive()..where((t) {
            final first = coalesce([t.startAt, t.dueAt]);
            final last = coalesce([t.dueAt, t.startAt]);
            return (first.isSmallerThanValue(to) &
                    last.isBiggerOrEqualValue(from)) |
                (t.recurrenceRule.isNotNull() & t.dueAt.isSmallerThanValue(to));
          }))
          .watch();

  /// Conclusões de rotina com ocorrência em `[from, to)`.
  Stream<List<TaskCompletion>> watchCompletionsBetween(
    DateTime from,
    DateTime to,
  ) =>
      (select(taskCompletions)..where(
            (c) =>
                c.occurrence.isBiggerOrEqualValue(from) &
                c.occurrence.isSmallerThanValue(to) &
                c.deletedAt.isNull(),
          ))
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

  /// Exclui (logicamente) a tarefa e todas as subtarefas. Devolve os ids
  /// excluídos, para permitir desfazer com [restoreTasks].
  Future<List<String>> softDeleteTaskTree(String id) => transaction(() async {
    final ids = await taskTreeIds(id);
    for (final taskId in ids) {
      await softDeleteSynced(tasks, taskId);
    }
    return ids;
  });

  /// Desfaz uma exclusão lógica.
  Future<void> restoreTasks(List<String> ids) => transaction(() async {
    for (final id in ids) {
      await updateSynced(
        tasks,
        id,
        const TasksCompanion(deletedAt: Value(null)),
      );
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
