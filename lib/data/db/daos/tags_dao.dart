import 'package:drift/drift.dart';

import '../database.dart';
import '../sync_writes.dart';
import '../tables/tasks.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags, TaskTags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.attachedDatabase);

  Future<void> insertTag(TagsCompanion row) => insertSynced(tags, row);

  Future<void> updateTag(String id, TagsCompanion patch) =>
      updateSynced(tags, id, patch);

  /// Exclui a tag e os vínculos dela com tarefas.
  Future<void> softDeleteTag(String id) => transaction(() async {
    final links = await (select(
      taskTags,
    )..where((l) => l.tagId.equals(id) & l.deletedAt.isNull())).get();
    for (final link in links) {
      await softDeleteSynced(taskTags, link.id);
    }
    await softDeleteSynced(tags, id);
  });

  Stream<List<Tag>> watchTags() =>
      (select(tags)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Stream<List<Tag>> watchTagsOfTask(String taskId) {
    final query =
        select(tags)
            .join([innerJoin(taskTags, taskTags.tagId.equalsExp(tags.id))])
          ..where(
            taskTags.taskId.equals(taskId) &
                taskTags.deletedAt.isNull() &
                tags.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(tags)],
    );
  }

  /// Vincula a tag à tarefa. Se o vínculo já existiu e foi excluído, revive
  /// a mesma linha (o par tarefa/tag é único).
  Future<void> addTagToTask(String taskId, String tagId) => transaction(
    () async {
      final existing =
          await (select(taskTags)
                ..where((l) => l.taskId.equals(taskId) & l.tagId.equals(tagId)))
              .getSingleOrNull();
      if (existing == null) {
        await insertSynced(
          taskTags,
          TaskTagsCompanion.insert(taskId: taskId, tagId: tagId),
        );
      } else if (existing.deletedAt != null) {
        await updateSynced(
          taskTags,
          existing.id,
          const TaskTagsCompanion(deletedAt: Value(null)),
        );
      }
    },
  );

  Future<void> removeTagFromTask(String taskId, String tagId) =>
      transaction(() async {
        final existing =
            await (select(taskTags)..where(
                  (l) =>
                      l.taskId.equals(taskId) &
                      l.tagId.equals(tagId) &
                      l.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (existing != null) await softDeleteSynced(taskTags, existing.id);
      });
}
