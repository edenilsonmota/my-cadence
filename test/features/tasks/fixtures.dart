import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';

/// Tarefa em memória para testes de lógica pura.
Task makeTask(
  String id, {
  String? title,
  String? parentId,
  TaskKind kind = TaskKind.simples,
  TaskStatus status = TaskStatus.aFazer,
  int priority = 0,
  DateTime? startAt,
  DateTime? dueAt,
  bool hasTime = false,
  String? recurrenceRule,
  int sortOrder = 0,
}) => Task(
  id: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  dirty: true,
  title: title ?? id,
  parentId: parentId,
  kind: kind,
  status: status,
  priority: priority,
  startAt: startAt,
  dueAt: dueAt,
  hasTime: hasTime,
  recurrenceRule: recurrenceRule,
  sortOrder: sortOrder,
);
