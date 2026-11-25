/// Busca geral em tarefas, páginas dos books e cards. Puro, sem Flutter.
library;

import 'dart:convert';

import '../../data/db/database.dart';
import '../tasks/task_lists.dart' show normalize;

enum SearchKind { task, page, card }

/// Um resultado: o que abrir ([id]), o título, um trecho com o termo
/// ([snippet], quando o termo não está no título) e o lugar (book, deck).
typedef SearchHit = ({
  SearchKind kind,
  String id,
  String title,
  String? snippet,
  String? place,
});

/// Texto puro de uma página (JSON do editor): junta os trechos `insert`.
String pageText(String content) {
  if (content.isEmpty) return '';
  final Object? json;
  try {
    json = jsonDecode(content);
  } on FormatException {
    return '';
  }
  final out = <String>[];
  void walk(Object? node) {
    if (node is Map) {
      final insert = node['insert'];
      if (insert is String) out.add(insert);
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(json);
  return out.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Trecho de [text] em volta da primeira ocorrência de [query] (sem
/// diferenciar maiúsculas e acentos), com reticências; `null` se não houver.
String? snippetAround(String text, String query, {int radius = 40}) {
  final q = normalize(query.trim());
  if (q.isEmpty) return null;
  // `normalize` troca letra por letra, então as posições batem com [text].
  final i = normalize(text).indexOf(q);
  if (i < 0) return null;
  var start = (i - radius).clamp(0, text.length);
  var end = (i + q.length + radius).clamp(0, text.length);
  // Não corta palavra no meio.
  while (start > 0 && text[start - 1] != ' ') {
    start--;
  }
  while (end < text.length && text[end - 1] != ' ' && text[end] != ' ') {
    end++;
  }
  return '${start > 0 ? '…' : ''}${text.substring(start, end).trim()}'
      '${end < text.length ? '…' : ''}';
}

/// Busca [query] (mín. 2 letras) e devolve até [limit] resultados por tipo:
/// tarefas (título e notas), páginas (título e texto) e cards (frente e
/// verso). Quem casa no título vem antes.
List<SearchHit> searchAll(
  String query, {
  required Iterable<Task> tasks,
  required Iterable<(NotePage, Notebook)> pages,
  required Iterable<Flashcard> cards,
  Map<String, String> deckNames = const {},
  int limit = 20,
}) {
  final q = normalize(query.trim());
  if (q.length < 2) return const [];
  bool has(String? text) => text != null && normalize(text).contains(q);

  List<SearchHit> rank(List<(bool, SearchHit)> found) {
    final sorted = [
      for (final f in found)
        if (f.$1) f.$2,
      for (final f in found)
        if (!f.$1) f.$2,
    ];
    return sorted.take(limit).toList();
  }

  final taskHits = <(bool, SearchHit)>[
    for (final t in tasks)
      if (t.deletedAt == null && (has(t.title) || has(t.notes)))
        (
          has(t.title),
          (
            kind: SearchKind.task,
            id: t.id,
            title: t.title,
            snippet: has(t.title) ? null : snippetAround(t.notes!, query),
            place: null,
          ),
        ),
  ];

  final pageHits = <(bool, SearchHit)>[];
  for (final (page, book) in pages) {
    if (page.deletedAt != null) continue;
    final inTitle = has(page.title);
    final body = inTitle ? null : pageText(page.content);
    if (!inTitle && !has(body)) continue;
    pageHits.add((
      inTitle,
      (
        kind: SearchKind.page,
        id: page.id,
        title: page.title,
        snippet: body == null ? null : snippetAround(body, query),
        place: book.title,
      ),
    ));
  }

  final cardHits = <(bool, SearchHit)>[
    for (final c in cards)
      if (c.deletedAt == null && (has(c.front) || has(c.back)))
        (
          has(c.front),
          (
            kind: SearchKind.card,
            id: c.id,
            title: c.front,
            snippet: has(c.front) ? null : snippetAround(c.back, query),
            place: deckNames[c.deckId],
          ),
        ),
  ];

  return [...rank(taskHits), ...rank(pageHits), ...rank(cardHits)];
}
