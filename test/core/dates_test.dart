import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/core/dates.dart';

final now = DateTime(2026, 11, 23, 10); // segunda-feira

void main() {
  test('formatDate omite o ano corrente', () {
    expect(formatDate(DateTime(2026, 11, 24), now), 'ter, 24 nov');
    expect(formatDate(DateTime(2027, 1, 3), now), 'dom, 3 jan 2027');
  });

  test('formatRelative usa hoje, amanhã e ontem', () {
    expect(formatRelative(DateTime(2026, 11, 23, 23, 59), now), 'Hoje');
    expect(formatRelative(DateTime(2026, 11, 24), now), 'Amanhã');
    expect(formatRelative(DateTime(2026, 11, 22), now), 'Ontem');
    expect(formatRelative(DateTime(2026, 11, 20), now), 'sex, 20 nov');
    expect(
      formatRelative(DateTime(2026, 11, 23, 14, 5), now, withTime: true),
      'Hoje, 14:05',
    );
  });

  test('addDays vira mês e ano mantendo a hora', () {
    expect(addDays(DateTime(2026, 12, 31, 8), 1), DateTime(2027, 1, 1, 8));
    expect(addDays(DateTime(2026, 3, 1, 8), -1), DateTime(2026, 2, 28, 8));
  });
}
