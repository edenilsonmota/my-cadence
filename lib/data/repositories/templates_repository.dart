import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/daos/templates_dao.dart';
import '../db/database.dart';

/// Modelos de tarefa: nome e o JSON com o que a tarefa nova recebe.
class TemplatesRepository {
  TemplatesRepository(this._dao);

  final TemplatesDao _dao;

  Stream<List<TaskTemplate>> watchTemplates() => _dao.watchTemplates();

  Future<String> createTemplate({
    required String name,
    required String payload,
  }) async {
    final id = newId();
    await _dao.insertTemplate(
      TaskTemplatesCompanion.insert(
        id: Value(id),
        name: name,
        payload: payload,
      ),
    );
    return id;
  }

  Future<void> renameTemplate(String id, String name) =>
      _dao.updateTemplate(id, TaskTemplatesCompanion(name: Value(name)));

  Future<void> deleteTemplate(String id) => _dao.softDeleteTemplate(id);
}
