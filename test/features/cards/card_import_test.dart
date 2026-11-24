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
    final r = parseCardsCsv('﻿um;dois');
    expect(r.cards, [(front: 'um', back: 'dois')]);
  });
}
