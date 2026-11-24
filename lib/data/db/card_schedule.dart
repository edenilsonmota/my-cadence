import 'database.dart';
import 'enums.dart';

/// Estado de agendamento de um card (as colunas FSRS de `Flashcards`).
class CardSchedule {
  const CardSchedule({
    required this.state,
    required this.due,
    this.step,
    this.stability,
    this.difficulty,
    this.lastReview,
  });

  factory CardSchedule.of(Flashcard card) => CardSchedule(
    state: card.state,
    step: card.step,
    stability: card.stability,
    difficulty: card.difficulty,
    due: card.due,
    lastReview: card.lastReview,
  );

  final CardState state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;

  @override
  bool operator ==(Object other) =>
      other is CardSchedule &&
      other.state == state &&
      other.step == step &&
      other.stability == stability &&
      other.difficulty == difficulty &&
      other.due == due &&
      other.lastReview == lastReview;

  @override
  int get hashCode =>
      Object.hash(state, step, stability, difficulty, due, lastReview);

  @override
  String toString() => 'CardSchedule($state, step $step, due $due)';
}
