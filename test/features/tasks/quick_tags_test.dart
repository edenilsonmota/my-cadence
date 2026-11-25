import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/tasks/quick_tags.dart';

void main() {
  test('separa título e tags, sem repetir', () {
    final r = parseQuickTags('Estudar #inglês verbos #Estudos #ingles');
    expect(r.title, 'Estudar verbos');
    expect(r.tags, ['inglês', 'Estudos']);
  });

  test('# no meio da palavra não é tag', () {
    final r = parseQuickTags('Aula C# amanhã');
    expect(r.title, 'Aula C# amanhã');
    expect(r.tags, isEmpty);
  });

  test('casa com as existentes sem diferenciar acento e maiúscula', () {
    expect(
      matchQuickTags(['Ingles', 'novo'], {'Inglês': 't1', 'Estudos': 't2'}),
      {'Ingles': 't1', 'novo': null},
    );
  });
}
