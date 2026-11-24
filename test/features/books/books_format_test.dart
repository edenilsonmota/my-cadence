import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/books/books_format.dart';

void main() {
  final today = DateTime(2026, 11, 24);
  test('editado há quanto tempo', () {
    expect(editedLabel(DateTime(2026, 11, 24, 9), today), 'editado hoje');
    expect(editedLabel(DateTime(2026, 11, 23, 23), today), 'editado ontem');
    expect(editedLabel(DateTime(2026, 11, 21), today), 'editado há 3 dias');
    expect(editedLabel(DateTime(2026, 11, 2), today), 'editado em 2 nov');
  });

  test('contagem de páginas', () {
    expect(pagesLabel(1), '1 página');
    expect(pagesLabel(12), '12 páginas');
  });
}
