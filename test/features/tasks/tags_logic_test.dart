import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/tasks/tags_logic.dart';

void main() {
  test('conta apenas tarefas vivas por tag', () {
    final counts = countTasksPerTag(
      liveTaskIds: const ['t1', 't2'],
      tagIdsByTask: const {
        't1': {'a', 'b'},
        't2': {'a'},
        'excluida': {'a', 'c'},
      },
    );
    expect(counts, {'a': 2, 'b': 1});
  });

  test(
    'detecta nome duplicado ignorando maiúsculas, espaços e a própria tag',
    () {
      const existing = [(id: '1', name: 'Trabalho'), (id: '2', name: 'Estudo')];
      expect(isDuplicateTagName('  trabalho ', existing), isTrue);
      expect(isDuplicateTagName('trabalho', existing, ignoreId: '1'), isFalse);
      expect(isDuplicateTagName('Estudo', existing, ignoreId: '1'), isTrue);
      expect(isDuplicateTagName('Pessoal', existing), isFalse);
      expect(isDuplicateTagName('   ', existing), isFalse);
    },
  );
}
