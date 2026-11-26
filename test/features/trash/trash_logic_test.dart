import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/trash/trash_logic.dart';

void main() {
  test('ordena itens da lixeira do mais recente para o mais antigo', () {
    final items = [
      TrashItem(
        kind: TrashKind.task,
        id: '1',
        title: 'Antiga',
        deletedAt: DateTime(2026, 11, 20),
      ),
      TrashItem(
        kind: TrashKind.card,
        id: '2',
        title: 'Recente',
        deletedAt: DateTime(2026, 11, 25),
      ),
      TrashItem(
        kind: TrashKind.tag,
        id: '3',
        title: 'Meio',
        deletedAt: DateTime(2026, 11, 22),
      ),
    ];
    expect(sortTrashItems(items).map((i) => i.id), ['2', '3', '1']);
  });

  test('filtra por categoria agrupando decks+cards e books+páginas', () {
    final at = DateTime(2026, 11, 25);
    final items = [
      TrashItem(kind: TrashKind.task, id: 't', title: 'T', deletedAt: at),
      TrashItem(kind: TrashKind.deck, id: 'd', title: 'D', deletedAt: at),
      TrashItem(kind: TrashKind.card, id: 'c', title: 'C', deletedAt: at),
      TrashItem(kind: TrashKind.book, id: 'b', title: 'B', deletedAt: at),
      TrashItem(kind: TrashKind.page, id: 'p', title: 'P', deletedAt: at),
      TrashItem(kind: TrashKind.tag, id: 'g', title: 'G', deletedAt: at),
    ];

    expect(filterTrashItems(items, TrashFilter.cards).map((i) => i.id), [
      'd',
      'c',
    ]);
    expect(filterTrashItems(items, TrashFilter.books).map((i) => i.id), [
      'b',
      'p',
    ]);
    expect(filterTrashItems(items, TrashFilter.tasks).map((i) => i.id), ['t']);
    expect(filterTrashItems(items, TrashFilter.tags).map((i) => i.id), ['g']);
  });
}
