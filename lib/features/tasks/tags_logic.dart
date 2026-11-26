/// Lógica pura do gerenciamento de tags (contagem de uso e validação).
/// Sem Flutter.
library;

/// Conta quantas tarefas vivas usam cada tag.
///
/// Considera apenas ids presentes em [liveTaskIds], evitando contar vínculos
/// antigos de tarefas já excluídas.
Map<String, int> countTasksPerTag({
  required Iterable<String> liveTaskIds,
  required Map<String, Set<String>> tagIdsByTask,
}) {
  final live = liveTaskIds is Set<String> ? liveTaskIds : liveTaskIds.toSet();
  final counts = <String, int>{};
  for (final MapEntry(key: taskId, value: tagIds) in tagIdsByTask.entries) {
    if (!live.contains(taskId)) continue;
    for (final tagId in tagIds) {
      counts[tagId] = (counts[tagId] ?? 0) + 1;
    }
  }
  return counts;
}

/// Normaliza o nome de uma tag para comparação sem diferenciar maiúsculas ou
/// espaços nas pontas.
String normalizeTagName(String name) => name.trim().toLowerCase();

/// `true` se já existe outra tag com o mesmo nome (ignorando maiúsculas e
/// espaços extras), desconsiderando [ignoreId] ao renomear.
bool isDuplicateTagName(
  String candidate,
  Iterable<({String id, String name})> existing, {
  String? ignoreId,
}) {
  final target = normalizeTagName(candidate);
  if (target.isEmpty) return false;
  return existing.any(
    (t) => t.id != ignoreId && normalizeTagName(t.name) == target,
  );
}
