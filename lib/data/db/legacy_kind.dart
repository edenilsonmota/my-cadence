/// Fim do "tipo" de tarefa (esquema v8): calcula onde gravar cor e ícone
/// próprios para que cada tarefa continue com a mesma aparência. Usado pela
/// migração do banco e pelo upgrader do snapshot. Puro, sem Flutter.
library;

/// Linha mínima de tarefa para o cálculo.
typedef LegacyTaskRow = ({
  String id,
  String? parentId,
  String kind,
  String? colorKey,
  String? iconKey,
  bool repeats,
});

const _kindColor = {
  'simples': 'azul',
  'estudo': 'violeta',
  'rotina': 'verde',
  'evento': 'laranja',
};
const _kindIcon = {
  'simples': 'square-check',
  'estudo': 'graduation-cap',
  'rotina': 'repeat',
  'evento': 'calendar-clock',
};

/// Padrão novo, sem tipo: tarefa que repete é verde com ícone de repetição;
/// as outras, azul com o ícone de tarefa.
String defaultColorKeyFor({required bool repeats}) =>
    repeats ? 'verde' : 'azul';
String defaultIconKeyFor({required bool repeats}) =>
    repeats ? 'repeat' : 'square-check';

/// Para cada tarefa cuja aparência mudaria, a cor e/ou o ícone a gravar
/// (`null` no campo = não mexer). [firstTagColor] = cor da 1ª tag
/// (alfabética) de cada tarefa que tem tag.
Map<String, ({String? colorKey, String? iconKey})> legacyKindFixes(
  Iterable<LegacyTaskRow> tasks,
  Map<String, String> firstTagColor,
) {
  final byId = {for (final t in tasks) t.id: t};
  // Valores explícitos depois das correções (as mães são resolvidas antes).
  final color = {for (final t in tasks) t.id: t.colorKey};
  final icon = {for (final t in tasks) t.id: t.iconKey};

  Iterable<String> lineage(String id) sync* {
    String? current = id;
    final seen = <String>{};
    while (current != null && seen.add(current) && byId[current] != null) {
      yield current;
      current = byId[current]!.parentId;
    }
  }

  int depth(String id) => lineage(id).length;

  String? firstIn(String id, Map<String, String?> values) {
    for (final a in lineage(id)) {
      if (values[a] case final v?) return v;
    }
    return null;
  }

  String? firstOriginal(String id, String? Function(LegacyTaskRow) pick) {
    for (final a in lineage(id)) {
      if (pick(byId[a]!) case final v?) return v;
    }
    return null;
  }

  final ordered = tasks.toList()
    ..sort((a, b) => depth(a.id).compareTo(depth(b.id)));
  final fixes = <String, ({String? colorKey, String? iconKey})>{};
  for (final t in ordered) {
    final oldColor =
        firstOriginal(t.id, (r) => r.colorKey) ??
        firstTagColor[t.id] ??
        _kindColor[t.kind] ??
        'azul';
    final oldIcon =
        firstOriginal(t.id, (r) => r.iconKey) ??
        _kindIcon[t.kind] ??
        'square-check';
    final newColor =
        firstIn(t.id, color) ??
        firstTagColor[t.id] ??
        defaultColorKeyFor(repeats: t.repeats);
    final newIcon =
        firstIn(t.id, icon) ?? defaultIconKeyFor(repeats: t.repeats);
    final setColor = newColor == oldColor ? null : oldColor;
    final setIcon = newIcon == oldIcon ? null : oldIcon;
    if (setColor != null) color[t.id] = setColor;
    if (setIcon != null) icon[t.id] = setIcon;
    if (setColor != null || setIcon != null) {
      fixes[t.id] = (colorKey: setColor, iconKey: setIcon);
    }
  }
  return fixes;
}
