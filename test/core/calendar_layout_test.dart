import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/calendar_layout.dart';

Span at(int h1, int m1, int h2, int m2) => (
  start: DateTime(2026, 11, 24, h1, m1),
  end: DateTime(2026, 11, 24, h2, m2),
);

void main() {
  group('layoutOverlaps', () {
    test('sem sobreposição: cada bloco ocupa a largura toda', () {
      expect(layoutOverlaps([at(9, 0, 10, 0), at(10, 0, 11, 0)]), [
        (column: 0, columns: 1),
        (column: 0, columns: 1),
      ]);
    });

    test('dois sobrepostos ficam lado a lado', () {
      expect(layoutOverlaps([at(9, 0, 10, 0), at(9, 30, 10, 30)]), [
        (column: 0, columns: 2),
        (column: 1, columns: 2),
      ]);
    });

    test('coluna liberada é reaproveitada dentro do grupo', () {
      // A 9-12 longo; B 9-10; C 10-11 cabe na coluna de B.
      final r = layoutOverlaps([
        at(9, 0, 12, 0),
        at(9, 0, 10, 0),
        at(10, 0, 11, 0),
      ]);
      expect(r, [
        (column: 0, columns: 2),
        (column: 1, columns: 2),
        (column: 1, columns: 2),
      ]);
    });

    test('grupos separados não dividem colunas', () {
      final r = layoutOverlaps([
        at(9, 0, 10, 0),
        at(9, 0, 10, 0),
        at(9, 0, 10, 0),
        at(14, 0, 15, 0),
      ]);
      expect(r.map((s) => s.columns), [3, 3, 3, 1]);
      expect(r.map((s) => s.column).take(3).toSet(), {0, 1, 2});
    });

    test('cadeia: A toca B, B toca C, A não toca C, todos no mesmo grupo', () {
      final r = layoutOverlaps([
        at(9, 0, 10, 0),
        at(9, 30, 11, 0),
        at(10, 30, 12, 0),
      ]);
      expect(r, [
        (column: 0, columns: 2),
        (column: 1, columns: 2),
        (column: 0, columns: 2),
      ]);
    });

    test('resultado segue a ordem de entrada, não a de início', () {
      final r = layoutOverlaps([at(9, 30, 10, 30), at(9, 0, 10, 0)]);
      expect(r, [(column: 1, columns: 2), (column: 0, columns: 2)]);
    });

    test('bloco de duração zero conta como 15 min', () {
      final r = layoutOverlaps([at(9, 0, 9, 0), at(9, 10, 9, 40)]);
      expect(r.map((s) => s.columns), [2, 2]);
      final apart = layoutOverlaps([at(9, 0, 9, 0), at(9, 15, 9, 40)]);
      expect(apart.map((s) => s.columns), [1, 1]);
    });

    test('lista vazia', () => expect(layoutOverlaps([]), isEmpty));
  });

  test('arredondamento em 15 min', () {
    expect(floorToStep(14 * 60 + 14), 14 * 60);
    expect(floorToStep(14 * 60 + 15), 14 * 60 + 15);
    expect(roundToStep(7.4), 0);
    expect(roundToStep(7.5), 15);
    expect(roundToStep(-8), -15);
  });

  test('semana começa na segunda', () {
    expect(weekStart(DateTime(2026, 11, 24, 15)), DateTime(2026, 11, 23));
    expect(weekStart(DateTime(2026, 11, 29)), DateTime(2026, 11, 23));
    expect(weekStart(DateTime(2026, 11, 23)), DateTime(2026, 11, 23));
  });

  test('grade do mês cobre semanas inteiras', () {
    final days = monthGridDays(DateTime(2026, 11, 10));
    // Novembro/2026: 1º é domingo, 30 é segunda.
    expect(days.first, DateTime(2026, 10, 26));
    expect(days.last, DateTime(2026, 12, 6));
    expect(days, hasLength(42));
    final feb = monthGridDays(DateTime(2027, 2)); // 1º/02/2027 é segunda
    expect(feb.first, DateTime(2027, 2));
    expect(feb, hasLength(28));
  });
}
