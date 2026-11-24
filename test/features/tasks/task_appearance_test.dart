import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/tasks/task_appearance.dart';

import 'fixtures.dart';

void main() {
  final colors = {'azul', 'verde', 'rosa', 'violeta', 'laranja'};
  final icons = {'brain', 'book-open', 'square-check', 'graduation-cap'};

  AppearanceResolver resolver(List<Task> tasks, [Map<String, String>? tags]) =>
      AppearanceResolver(
        tasks: tasks,
        firstTagColor: tags ?? const {},
        validColors: colors,
        validIcons: icons,
      );

  test('cor: própria → mãe → 1ª tag → tipo', () {
    final root = makeTask('r').copyWith(colorKey: const Value('rosa'));
    final child = makeTask('c', parentId: 'r');
    final grandchild = makeTask('g', parentId: 'c');
    final own = makeTask(
      'o',
      parentId: 'r',
    ).copyWith(colorKey: const Value('verde'));
    final tagged = makeTask('t', kind: TaskKind.estudo);
    final plain = makeTask('p', kind: TaskKind.estudo);
    final r = resolver(
      [root, child, grandchild, own, tagged, plain],
      {'t': 'azul', 'g': 'azul'},
    );
    expect(r.colorKeyOf(own), 'verde');
    expect(r.colorKeyOf(child), 'rosa');
    expect(r.colorKeyOf(grandchild), 'rosa'); // a mãe vem antes da tag
    expect(r.colorKeyOf(tagged), 'azul');
    expect(r.colorKeyOf(plain), 'violeta'); // padrão do tipo estudo
  });

  test('ícone: próprio → mãe → tipo (tag não tem ícone)', () {
    final root = makeTask('r').copyWith(iconKey: const Value('brain'));
    final child = makeTask('c', parentId: 'r');
    final plain = makeTask('p', kind: TaskKind.estudo);
    final r = resolver([root, child, plain]);
    expect(r.iconKeyOf(child), 'brain');
    expect(r.iconKeyOf(plain), 'graduation-cap');
  });

  test('chave desconhecida é ignorada e a herança continua', () {
    final root = makeTask('r').copyWith(colorKey: const Value('rosa'));
    final child = makeTask('c', parentId: 'r').copyWith(
      colorKey: const Value('magenta'),
      iconKey: const Value('foguete-antigo'),
    );
    final r = resolver([root, child]);
    expect(r.of(child), (colorKey: 'rosa', iconKey: 'square-check'));
  });

  test('ciclo de mães não trava', () {
    final a = makeTask('a', parentId: 'b');
    final b = makeTask('b', parentId: 'a');
    expect(resolver([a, b]).colorKeyOf(a), 'azul');
  });
}
