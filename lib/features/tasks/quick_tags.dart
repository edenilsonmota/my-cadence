/// `#tag` no texto da adição rápida. Puro, sem Flutter.
library;

import 'task_lists.dart' show normalize;

final _tagPattern = RegExp(r'(^|\s)#([\p{L}\p{N}_\-]+)', unicode: true);

/// Separa o título das `#tags` digitadas ("Estudar #inglês #Estudos" →
/// título "Estudar", tags ["inglês", "Estudos"]). Tags repetidas (sem
/// diferenciar maiúsculas e acentos) contam uma vez.
({String title, List<String> tags}) parseQuickTags(String text) {
  final tags = <String>[];
  final seen = <String>{};
  for (final m in _tagPattern.allMatches(text)) {
    final name = m.group(2)!;
    if (seen.add(normalize(name))) tags.add(name);
  }
  final title = text
      .replaceAll(_tagPattern, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return (title: title, tags: tags);
}

/// Para cada nome digitado, o id da tag existente com o mesmo nome (sem
/// diferenciar maiúsculas e acentos) ou `null` (precisa criar).
Map<String, String?> matchQuickTags(
  List<String> names,
  Map<String, String> existingIdByName,
) {
  final byNormalized = {
    for (final MapEntry(key: name, value: id) in existingIdByName.entries)
      normalize(name): id,
  };
  return {for (final n in names) n: byNormalized[normalize(n)]};
}
