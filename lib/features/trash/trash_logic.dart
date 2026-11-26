/// Lógica pura da Lixeira: modelo dos itens excluídos, filtro e ordenação.
/// Sem Flutter.
library;

enum TrashKind { task, tag, deck, card, book, page }

enum TrashFilter { all, tasks, cards, books, tags }

class TrashItem {
  const TrashItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.deletedAt,
    this.subtitle,
  });

  final TrashKind kind;
  final String id;
  final String title;
  final String? subtitle;
  final DateTime deletedAt;
}

/// Ordena os itens da lixeira do excluído mais recentemente para o mais antigo.
List<TrashItem> sortTrashItems(Iterable<TrashItem> items) =>
    items.toList()..sort((a, b) {
      final byDate = b.deletedAt.compareTo(a.deletedAt);
      if (byDate != 0) return byDate;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

/// Filtra [items] por categoria.
List<TrashItem> filterTrashItems(
  Iterable<TrashItem> items,
  TrashFilter filter,
) {
  if (filter == TrashFilter.all) return items.toList();
  return [
    for (final item in items)
      if (_matchesTrashFilter(item.kind, filter)) item,
  ];
}

bool _matchesTrashFilter(TrashKind kind, TrashFilter filter) =>
    switch (filter) {
      TrashFilter.all => true,
      TrashFilter.tasks => kind == TrashKind.task,
      TrashFilter.cards => kind == TrashKind.deck || kind == TrashKind.card,
      TrashFilter.books => kind == TrashKind.book || kind == TrashKind.page,
      TrashFilter.tags => kind == TrashKind.tag,
    };
