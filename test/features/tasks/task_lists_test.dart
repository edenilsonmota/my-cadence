import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/tasks/task_lists.dart';

import 'fixtures.dart';

List<String> titles(List<TaskNode> nodes) => [
  for (final n in nodes) n.task.title,
];

void main() {
  group('sortToday', () {
    test('dia inteiro por prioridade, depois por hora, concluídas no fim', () {
      final day = DateTime(2026, 11, 23);
      final sorted = sortToday([
        makeTask('15h', dueAt: DateTime(2026, 11, 23, 15), hasTime: true),
        makeTask('feita', dueAt: day, status: TaskStatus.feita, priority: 3),
        makeTask('baixa', dueAt: day, priority: 1),
        makeTask('9h', dueAt: DateTime(2026, 11, 23, 9), hasTime: true),
        makeTask('alta', dueAt: day, priority: 3),
      ]);
      expect(sorted.map((t) => t.id), ['alta', 'baixa', '9h', '15h', 'feita']);
    });
  });

  group('TaskFilter', () {
    test('busca ignora maiúsculas e acentos', () {
      const filter = TaskFilter(query: 'revisao');
      expect(
        filter.matches(makeTask('a', title: 'Revisão de Cálculo'), {}),
        isTrue,
      );
      expect(filter.matches(makeTask('b', title: 'Outra'), {}), isFalse);
    });

    test('por padrão esconde as concluídas', () {
      const filter = TaskFilter();
      expect(
        filter.matches(makeTask('a', status: TaskStatus.feita), {}),
        isFalse,
      );
      expect(
        filter.matches(makeTask('b', status: TaskStatus.fazendo), {}),
        isTrue,
      );
      expect(filter.activeCount, 0);
    });

    test('prioridade e tag combinadas', () {
      const filter = TaskFilter(
        priorities: {2, 3},
        tagIds: {'t1'},
        statuses: {},
      );
      final task = makeTask('a', priority: 3);
      expect(filter.matches(task, {'t1', 't2'}), isTrue);
      expect(filter.matches(task, {'t2'}), isFalse);
      expect(filter.matches(makeTask('b', priority: 1), {'t1'}), isFalse);
      expect(filter.activeCount, 3);
    });
  });

  group('buildTaskTree', () {
    final tasks = [
      makeTask('Projeto', sortOrder: 1),
      makeTask('Parte B', parentId: 'Projeto', sortOrder: 2),
      makeTask('Parte A', parentId: 'Projeto', sortOrder: 1),
      makeTask('Detalhe', parentId: 'Parte A'),
      makeTask('Avulsa', sortOrder: 0),
      makeTask('Pronta', status: TaskStatus.feita, sortOrder: 2),
    ];

    test('monta raízes e subtarefas em ordem manual', () {
      final tree = buildTaskTree(tasks, const TaskFilter(), {});
      expect(titles(tree), ['Avulsa', 'Projeto']);
      expect(titles(tree[1].children), ['Parte A', 'Parte B']);
      expect(titles(tree[1].children[0].children), ['Detalhe']);
    });

    test('mantém os ancestrais de uma subtarefa encontrada', () {
      final tree = buildTaskTree(tasks, const TaskFilter(query: 'detalhe'), {});
      expect(titles(tree), ['Projeto']);
      expect(tree.single.matches, isFalse);
      expect(titles(tree.single.children), ['Parte A']);
      expect(tree.single.children.single.children.single.matches, isTrue);
    });

    test('filtro de status inclui concluídas quando pedido', () {
      final tree = buildTaskTree(
        tasks,
        const TaskFilter(statuses: {TaskStatus.feita}),
        {},
      );
      expect(titles(tree), ['Pronta']);
    });

    test('pai ausente vira raiz', () {
      final tree = buildTaskTree(
        [makeTask('Órfã', parentId: 'sumiu')],
        const TaskFilter(),
        {},
      );
      expect(titles(tree), ['Órfã']);
    });
  });

  group('sortTasks', () {
    final tasks = [
      makeTask(
        '0001',
        title: 'beta',
        priority: 1,
        dueAt: DateTime(2026, 12, 2),
      ),
      makeTask('0002', title: 'Álgebra', priority: 3),
      makeTask(
        '0003',
        title: 'gama',
        priority: 3,
        dueAt: DateTime(2026, 12, 1),
      ),
    ];
    List<String> sorted(TaskSort sort) =>
        sortTasks(tasks, sort).map((t) => t.title).toList();

    test('por prazo deixa as sem prazo no fim', () {
      expect(sorted(TaskSort.prazo), ['gama', 'beta', 'Álgebra']);
    });

    test('por prioridade desempata pelo prazo', () {
      expect(sorted(TaskSort.prioridade), ['gama', 'Álgebra', 'beta']);
    });

    test('por título ignora acentos', () {
      expect(sorted(TaskSort.titulo), ['Álgebra', 'beta', 'gama']);
    });

    test('mais recentes primeiro (UUID v7 ordenável)', () {
      expect(sorted(TaskSort.criacao), ['gama', 'Álgebra', 'beta']);
    });
  });
}
