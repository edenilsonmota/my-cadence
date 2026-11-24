/// Cor e ícone de uma tarefa, com herança. Puro, sem Flutter.
///
/// Cor: da tarefa → da tarefa mãe (subindo) → da primeira tag → do tipo.
/// Ícone: da tarefa → da mãe (subindo) → do tipo. Chave desconhecida (fora da
/// paleta ou do catálogo) é ignorada e a herança continua.
library;

import '../../data/db/database.dart';
import '../../data/db/enums.dart';

/// Cor padrão de cada tipo (chave da paleta).
String kindColorKey(TaskKind kind) => switch (kind) {
  TaskKind.simples => 'azul',
  TaskKind.estudo => 'violeta',
  TaskKind.rotina => 'verde',
  TaskKind.evento => 'laranja',
};

/// Ícone padrão de cada tipo (chave do catálogo).
String kindIconKey(TaskKind kind) => switch (kind) {
  TaskKind.simples => 'square-check',
  TaskKind.estudo => 'graduation-cap',
  TaskKind.rotina => 'repeat',
  TaskKind.evento => 'calendar-clock',
};

typedef Appearance = ({String colorKey, String iconKey});

class AppearanceResolver {
  AppearanceResolver({
    required Iterable<Task> tasks,
    required this.firstTagColor,
    required this.validColors,
    required this.validIcons,
  }) : _byId = {for (final t in tasks) t.id: t};

  final Map<String, Task> _byId;

  /// Cor da primeira tag (ordem alfabética) de cada tarefa que tem tag.
  final Map<String, String> firstTagColor;
  final Set<String> validColors;
  final Set<String> validIcons;

  Appearance of(Task task) =>
      (colorKey: colorKeyOf(task), iconKey: iconKeyOf(task));

  String colorKeyOf(Task task) {
    for (final t in _lineage(task)) {
      if (validColors.contains(t.colorKey)) return t.colorKey!;
    }
    final tag = firstTagColor[task.id];
    if (validColors.contains(tag)) return tag!;
    return kindColorKey(task.kind);
  }

  String iconKeyOf(Task task) {
    for (final t in _lineage(task)) {
      if (validIcons.contains(t.iconKey)) return t.iconKey!;
    }
    return kindIconKey(task.kind);
  }

  /// A tarefa e as mães, da mais próxima à raiz (com trava contra ciclos).
  Iterable<Task> _lineage(Task task) sync* {
    Task? current = task;
    final seen = <String>{};
    while (current != null && seen.add(current.id)) {
      yield current;
      final parent = current.parentId;
      current = parent == null ? null : _byId[parent];
    }
  }
}
