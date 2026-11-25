import 'package:drift/drift.dart';

import '../database.dart';
import '../sync_writes.dart';
import '../tables/tasks.dart';

part 'templates_dao.g.dart';

@DriftAccessor(tables: [TaskTemplates])
class TemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$TemplatesDaoMixin {
  TemplatesDao(super.attachedDatabase);

  Future<void> insertTemplate(TaskTemplatesCompanion row) =>
      insertSynced(taskTemplates, row);

  Future<void> updateTemplate(String id, TaskTemplatesCompanion patch) =>
      updateSynced(taskTemplates, id, patch);

  Future<void> softDeleteTemplate(String id) =>
      softDeleteSynced(taskTemplates, id);

  Stream<List<TaskTemplate>> watchTemplates() =>
      (select(taskTemplates)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();
}
