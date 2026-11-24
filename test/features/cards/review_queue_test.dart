import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/cards/review_queue.dart';

final now = DateTime(2026, 11, 23, 10);

Flashcard card(
  String id, {
  required DateTime due,
  bool isNew = false,
  bool suspended = false,
}) => Flashcard(
  id: id,
  createdAt: now,
  updatedAt: now,
  dirty: true,
  front: id,
  back: '-',
  state: isNew ? CardState.learning : CardState.review,
  due: due,
  lastReview: isNew ? null : now.subtract(const Duration(days: 3)),
  suspended: suspended,
);

DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
DateTime inMin(int minutes) => now.add(Duration(minutes: minutes));

void main() {
  final cards = [
    card('novo-2', due: ago(5), isNew: true),
    card('revisao-recente', due: ago(1)),
    card('novo-1', due: ago(5), isNew: true),
    card('revisao-antiga', due: ago(600)),
    card('futuro', due: inMin(5)),
    card('suspenso', due: ago(60), suspended: true),
    card('novo-3', due: ago(5), isNew: true),
  ];

  test('estudados primeiro (mais atrasado antes), depois novos', () {
    final queue = buildQueue(cards, now, newPerDay: 20, newStudiedToday: 0);
    expect(queue.map((c) => c.id), [
      'revisao-antiga',
      'revisao-recente',
      'novo-1',
      'novo-2',
      'novo-3',
    ]);
  });

  test('limite de novos por dia desconta os já estudados hoje', () {
    final queue = buildQueue(cards, now, newPerDay: 3, newStudiedToday: 2);
    expect(queue.map((c) => c.id), [
      'revisao-antiga',
      'revisao-recente',
      'novo-1',
    ]);
    expect(
      buildQueue(cards, now, newPerDay: 3, newStudiedToday: 5).where(isNewCard),
      isEmpty,
    );
  });

  test('próximo card em breve: só os já estudados dentro da janela', () {
    expect(nextDueSoon(cards, now), inMin(5));
    expect(nextDueSoon([card('longe', due: inMin(30))], now), isNull);
    expect(nextDueSoon([card('n', due: inMin(2), isNew: true)], now), isNull);
  });

  test('ajustes: padrões e limites', () {
    expect(CardSettings.fromMap(const {}).newPerDay, 20);
    expect(CardSettings.fromMap(const {}).desiredRetention, 0.9);
    final s = CardSettings.fromMap({
      CardSettings.keyNewPerDay: '5',
      CardSettings.keyRetention: '95',
    });
    expect(s.newPerDay, 5);
    expect(s.desiredRetention, 0.95);
    expect(
      CardSettings.fromMap({CardSettings.keyRetention: '50'}).retentionPercent,
      90,
    );
  });
}
