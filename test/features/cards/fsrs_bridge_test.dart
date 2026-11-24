import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/cards/fsrs_bridge.dart';

final now = DateTime(2026, 11, 23, 10);

/// Card novo, como o repositório cria.
final fresh = CardSchedule(state: CardState.learning, step: 0, due: now);

void main() {
  test('ida e volta pelo fsrs.Card preserva os valores e o fuso', () {
    final s = CardSchedule(
      state: CardState.review,
      step: null,
      stability: 12.5,
      difficulty: 4.2,
      due: DateTime(2026, 12, 5, 10),
      lastReview: DateTime(2026, 11, 23, 10),
    );
    final card = toFsrsCard(s);
    expect(card.due.isUtc, isTrue);
    expect(card.lastReview!.isUtc, isTrue);
    expect(card.state, fsrs.State.review);

    final back = fromFsrsCard(card);
    expect(back, s);
    expect(back.due.isUtc, isFalse);
  });

  test('card novo: Errei 1 min, Difícil ~6 min, Bom 10 min, Fácil em dias', () {
    final preview = previewReview(buildScheduler(), fresh, now);

    expect(
      preview[Grade.errei]!.due.difference(now),
      const Duration(minutes: 1),
    );
    expect(
      preview[Grade.bom]!.due.difference(now),
      const Duration(minutes: 10),
    );
    expect(preview[Grade.bom]!.state, CardState.learning);
    expect(preview[Grade.bom]!.step, 1);
    final hard = preview[Grade.dificil]!.due.difference(now);
    expect(hard, greaterThan(const Duration(minutes: 1)));
    expect(hard, lessThan(const Duration(minutes: 10)));
    expect(preview[Grade.facil]!.state, CardState.review);
    expect(
      preview[Grade.facil]!.due.difference(now).inDays,
      greaterThanOrEqualTo(1),
    );
    for (final s in preview.values) {
      expect(s.lastReview, now);
    }
  });

  test('a prévia bate com o fsrs.Scheduler chamado direto', () {
    // Card em revisão (com fuzz): mesma semente nos dois lados.
    final reviewCard = CardSchedule(
      state: CardState.review,
      stability: 20,
      difficulty: 5,
      due: now,
      lastReview: now.subtract(const Duration(days: 20)),
    );
    // A prévia calcula as 4 notas em ordem com o mesmo agendador (o fuzz
    // consome o gerador nessa ordem); o pacote, chamado igual, dá o mesmo.
    final ours = previewReview(
      fsrs.Scheduler.customRandom(math.Random(42), desiredRetention: 0.9),
      reviewCard,
      now,
    );
    final theirsScheduler = fsrs.Scheduler.customRandom(
      math.Random(42),
      desiredRetention: 0.9,
    );
    for (final grade in Grade.values) {
      final rating = fsrs.Rating.values.firstWhere(
        (r) => r.value == grade.value,
      );
      final theirs = theirsScheduler
          .reviewCard(
            toFsrsCard(reviewCard),
            rating,
            reviewDateTime: now.toUtc(),
          )
          .card;
      expect(ours[grade]!.due, theirs.due.toLocal(), reason: grade.label);
      expect(ours[grade]!.stability, theirs.stability, reason: grade.label);
      expect(ours[grade]!.difficulty, theirs.difficulty, reason: grade.label);
      expect(ours[grade]!.state.name, theirs.state.name, reason: grade.label);
    }
  });

  test('retenção maior encurta o intervalo', () {
    final reviewCard = CardSchedule(
      state: CardState.review,
      stability: 30,
      difficulty: 5,
      due: now,
      lastReview: now.subtract(const Duration(days: 30)),
    );
    Duration goodInterval(double r) {
      final s = fsrs.Scheduler(desiredRetention: r, enableFuzzing: false);
      return previewReview(s, reviewCard, now)[Grade.bom]!.due.difference(now);
    }

    expect(goodInterval(0.95), lessThan(goodInterval(0.85)));
  });

  test('formatInterval', () {
    expect(formatInterval(const Duration(seconds: 30)), '1 min');
    expect(formatInterval(const Duration(minutes: 10)), '10 min');
    expect(formatInterval(const Duration(hours: 5)), '5 h');
    expect(formatInterval(const Duration(days: 4)), '4 d');
    expect(formatInterval(const Duration(days: 31)), '1 mês');
    expect(formatInterval(const Duration(days: 75)), '3 meses');
    expect(formatInterval(const Duration(days: 365)), '1 ano');
    expect(formatInterval(const Duration(days: 550)), '1,5 anos');
    expect(formatInterval(const Duration(days: 730)), '2 anos');
  });
}
