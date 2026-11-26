import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/cards/card_import.dart';

void main() {
  test('linhas simples, cabeçalho e linhas vazias', () {
    final r = parseCardsCsv('frente;verso\nCapital;Brasília\n\nH2O;Água\r\n');
    expect(r.cards, [
      (front: 'Capital', back: 'Brasília'),
      (front: 'H2O', back: 'Água'),
    ]);
    expect(r.skippedLines, isEmpty);
  });

  test('aspas com ponto e vírgula, quebra de linha e aspas escapadas', () {
    final r = parseCardsCsv(
      '"a;b";"linha 1\nlinha 2"\n"diz ""oi""";x\nsó frente;\n;só verso\nok;ok;extra',
    );
    expect(r.cards, [
      (front: 'a;b', back: 'linha 1\nlinha 2'),
      (front: 'diz "oi"', back: 'x'),
      (front: 'ok', back: 'ok'),
    ]);
    expect(r.skippedLines, [4, 5]);
  });

  test('BOM do Excel e última linha sem quebra', () {
    final r = parseCardsCsv('\uFEFFum;dois');
    expect(r.cards, [(front: 'um', back: 'dois')]);
  });

  test('ignora cabeçalho em inglês, espanhol e após linhas em branco', () {
    final en = parseCardsCsv('\n\nFront;Back\napple;maçã');
    expect(en.cards, [(front: 'apple', back: 'maçã')]);
    expect(en.skippedLines, isEmpty);

    final es = parseCardsCsv('FRENTE;REVERSO\ncasa;house');
    expect(es.cards, [(front: 'casa', back: 'house')]);
    expect(es.skippedLines, isEmpty);
  });

  test('filtra duplicados contra o deck existente e dentro do lote', () {
    final result = filterDuplicateCards(
      const [
        (front: 'Apple', back: 'maçã'),
        (front: '  new   word ', back: 'palavra nova'),
        (front: 'new word', back: 'outra tradução'),
        (front: 'book', back: 'livro'),
      ],
      existingFronts: const ['apple', '  BOOK  '],
    );
    expect(result.unique, [(front: '  new   word ', back: 'palavra nova')]);
    expect(result.duplicateCount, 3);
  });
}
