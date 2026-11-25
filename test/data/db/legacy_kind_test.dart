import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/legacy_kind.dart';

LegacyTaskRow row(
  String id, {
  String? parent,
  String kind = 'simples',
  String? color,
  String? icon,
  bool repeats = false,
}) => (
  id: id,
  parentId: parent,
  kind: kind,
  colorKey: color,
  iconKey: icon,
  repeats: repeats,
);

void main() {
  test('tipo vira cor e ícone próprios só onde a aparência mudaria', () {
    final fixes = legacyKindFixes(
      [
        row('estudo', kind: 'estudo'),
        row('filho', parent: 'estudo'), // era azul/check (o tipo dele)
        row('simples'),
        row('rotina', kind: 'rotina', repeats: true), // já fica verde/repeat
        row('comTag', kind: 'evento'),
        row('cor', kind: 'estudo', color: 'rosa'),
      ],
      {'comTag': 'ambar'},
    );

    expect(fixes['estudo'], (colorKey: 'violeta', iconKey: 'graduation-cap'));
    // A mãe agora tem cor própria: o filho grava a dele para não herdar.
    expect(fixes['filho'], (colorKey: 'azul', iconKey: 'square-check'));
    expect(fixes.containsKey('simples'), isFalse);
    expect(fixes.containsKey('rotina'), isFalse);
    // Cor vinha da tag (continua); só o ícone do tipo é gravado.
    expect(fixes['comTag'], (colorKey: null, iconKey: 'calendar-clock'));
    expect(fixes['cor'], (colorKey: null, iconKey: 'graduation-cap'));
  });

  test('rotina sem repetição e tarefa simples que repete mantêm o visual', () {
    final fixes = legacyKindFixes([
      row('r', kind: 'rotina'),
      row('s', repeats: true),
    ], const {});
    expect(fixes['r'], (colorKey: 'verde', iconKey: 'repeat'));
    expect(fixes['s'], (colorKey: 'azul', iconKey: 'square-check'));
  });
}
