/// Montagem das listas de tarefas (Hoje e árvore de Tarefas). Puro, sem Flutter.
library;

import '../../data/db/database.dart';
import '../../data/db/enums.dart';

// ─── Hoje ────────────────────────────────────────────────────────────────────

/// Ordem da seção "de hoje": primeiro as de dia inteiro (por prioridade e
/// ordem manual), depois as com hora (por horário). Concluídas vão para o fim.
List<Task> sortToday(Iterable<Task> tasks) {
  int rank(Task t) => t.status == TaskStatus.feita ? 2 : (t.hasTime ? 1 : 0);
  return tasks.toList()..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    if (a.hasTime && b.hasTime) return a.dueAt!.compareTo(b.dueAt!);
    final byPriority = b.priority.compareTo(a.priority);
    if (byPriority != 0) return byPriority;
    return a.sortOrder.compareTo(b.sortOrder);
  });
}

// ─── Tarefas ─────────────────────────────────────────────────────────────────

enum TaskSort {
  manual('Manual'),
  prazo('Prazo'),
  prioridade('Prioridade'),
  criacao('Mais recentes'),
  titulo('Título');

  const TaskSort(this.label);
  final String label;
}

class TaskFilter {
  const TaskFilter({
    this.query = '',
    this.kinds = const {},
    this.statuses = defaultStatuses,
    this.priorities = const {},
    this.tagIds = const {},
    this.sort = TaskSort.manual,
  });

  static const defaultStatuses = {TaskStatus.aFazer, TaskStatus.fazendo};

  /// Busca no título (sem diferenciar maiúsculas nem acentos).
  final String query;

  // Conjunto vazio = sem filtro naquele critério.
  final Set<TaskKind> kinds;
  final Set<TaskStatus> statuses;
  final Set<int> priorities;

  /// A tarefa precisa ter ao menos uma destas tags.
  final Set<String> tagIds;
  final TaskSort sort;

  /// Quantos critérios (além da busca e da ordenação) diferem do padrão.
  int get activeCount =>
      (kinds.isNotEmpty ? 1 : 0) +
      (_sameSet(statuses, defaultStatuses) ? 0 : 1) +
      (priorities.isNotEmpty ? 1 : 0) +
      (tagIds.isNotEmpty ? 1 : 0);

  bool matches(Task task, Set<String> taskTagIds) {
    if (kinds.isNotEmpty && !kinds.contains(task.kind)) return false;
    if (statuses.isNotEmpty && !statuses.contains(task.status)) return false;
    if (priorities.isNotEmpty && !priorities.contains(task.priority)) {
      return false;
    }
    if (tagIds.isNotEmpty && !taskTagIds.any(tagIds.contains)) return false;
    final q = normalize(query.trim());
    return q.isEmpty || normalize(task.title).contains(q);
  }

  TaskFilter copyWith({
    String? query,
    Set<TaskKind>? kinds,
    Set<TaskStatus>? statuses,
    Set<int>? priorities,
    Set<String>? tagIds,
    TaskSort? sort,
  }) => TaskFilter(
    query: query ?? this.query,
    kinds: kinds ?? this.kinds,
    statuses: statuses ?? this.statuses,
    priorities: priorities ?? this.priorities,
    tagIds: tagIds ?? this.tagIds,
    sort: sort ?? this.sort,
  );
}

class TaskNode {
  const TaskNode(this.task, this.children, {required this.matches});

  final Task task;
  final List<TaskNode> children;

  /// `false` quando a tarefa só aparece porque uma subtarefa casou com o filtro.
  final bool matches;
}

/// Monta a árvore filtrada e ordenada. Uma tarefa aparece se casa com o filtro
/// ou se alguma descendente casa (para manter o contexto).
List<TaskNode> buildTaskTree(
  List<Task> tasks,
  TaskFilter filter,
  Map<String, Set<String>> tagIdsByTask,
) {
  final ids = {for (final t in tasks) t.id};
  final childrenOf = <String?, List<Task>>{};
  for (final task in tasks) {
    // Pai ausente (não deveria acontecer) vira raiz.
    final parent = ids.contains(task.parentId) ? task.parentId : null;
    (childrenOf[parent] ??= []).add(task);
  }

  List<TaskNode> build(String? parentId) {
    final nodes = <TaskNode>[];
    for (final task in sortTasks(
      childrenOf[parentId] ?? const [],
      filter.sort,
    )) {
      final children = build(task.id);
      final matches = filter.matches(task, tagIdsByTask[task.id] ?? const {});
      if (matches || children.isNotEmpty) {
        nodes.add(TaskNode(task, children, matches: matches));
      }
    }
    return nodes;
  }

  return build(null);
}

List<Task> sortTasks(Iterable<Task> tasks, TaskSort sort) {
  final list = tasks.toList();
  int manual(Task a, Task b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
  }

  int byDue(Task a, Task b) {
    final da = a.dueAt, db = b.dueAt;
    if (da == null && db == null) return 0;
    if (da == null) return 1; // sem prazo vai para o fim
    if (db == null) return -1;
    return da.compareTo(db);
  }

  final Comparator<Task> compare = switch (sort) {
    TaskSort.manual => manual,
    TaskSort.prazo => (a, b) => _then(byDue(a, b), manual(a, b)),
    TaskSort.prioridade => (a, b) => _then(
      b.priority.compareTo(a.priority),
      _then(byDue(a, b), manual(a, b)),
    ),
    // UUID v7 é ordenável pelo momento da criação.
    TaskSort.criacao => (a, b) => b.id.compareTo(a.id),
    TaskSort.titulo => (a, b) => _then(
      normalize(a.title).compareTo(normalize(b.title)),
      manual(a, b),
    ),
  };
  return list..sort(compare);
}

int _then(int first, int second) => first != 0 ? first : second;

bool _sameSet<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

/// Minúsculas e sem acentos, para busca e ordenação por título.
String normalize(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}
