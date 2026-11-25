import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/search/search_logic.dart';

import '../tasks/fixtures.dart';

final t0 = DateTime(2026, 11, 25);

NotePage page(String id, String title, String text) => NotePage(
  id: id,
  createdAt: t0,
  updatedAt: t0,
  dirty: true,
  notebookId: 'b',
  title: title,
  content:
      '{"document":{"type":"page","children":[{"type":"paragraph",'
      '"data":{"delta":[{"insert":"$text"}]}}]}}',
  sortOrder: 0,
);

final book = Notebook(
  id: 'b',
  createdAt: t0,
  updatedAt: t0,
  dirty: true,
  title: 'Física',
);

Flashcard card(String id, String front, String back) => Flashcard(
  id: id,
  createdAt: t0,
  updatedAt: t0,
  dirty: true,
  deckId: 'd',
  front: front,
  back: back,
  state: CardState.learning,
  due: t0,
  suspended: false,
);

void main() {
  test('texto da página sai do JSON do editor', () {
    expect(
      pageText(page('p', 'x', 'Leis de Newton').content),
      'Leis de Newton',
    );
    expect(pageText('lixo'), '');
  });

  test('trecho em volta do termo, sem acento', () {
    expect(
      snippetAround(
        'A segunda lei da dinâmica diz algo',
        'dinamica',
        radius: 5,
      ),
      '…lei da dinâmica diz…',
    );
  });

  test('busca nos três, título primeiro, mínimo de 2 letras', () {
    final hits = searchAll(
      'newton',
      tasks: [
        makeTask('t1', title: 'Revisar Newton'),
        makeTask('t2', title: 'Outra'),
      ],
      pages: [(page('p1', 'Mecânica', 'Leis de Newton'), book)],
      cards: [card('c1', 'Quem formulou a gravitação?', 'Isaac Newton')],
      deckNames: {'d': 'Física'},
    );
    expect(hits.map((h) => (h.kind, h.id)), [
      (SearchKind.task, 't1'),
      (SearchKind.page, 'p1'),
      (SearchKind.card, 'c1'),
    ]);
    expect(hits[1].place, 'Física');
    expect(hits[1].snippet, 'Leis de Newton');
    expect(
      searchAll(
        'n',
        tasks: [makeTask('a', title: 'n')],
        pages: const [],
        cards: const [],
      ),
      isEmpty,
    );
  });
}
