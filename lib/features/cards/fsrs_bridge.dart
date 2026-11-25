/// Ponte entre os cards do banco e o pacote `fsrs`. Puro, sem Flutter.
///
/// O FSRS trabalha em UTC: converte com `toUtc()` ao montar o `fsrs.Card` e
/// com `toLocal()` ao voltar. O pacote é importado com prefixo porque `Card`
/// e `State` colidem com nomes do Flutter.
library;

import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/db/card_schedule.dart';
import '../../data/db/enums.dart';

export '../../data/db/card_schedule.dart';

/// Nota da revisão: 1 Errei, 2 Difícil, 3 Bom, 4 Fácil (igual ao FSRS/Anki).
enum Grade {
  errei(1, 'Errei'),
  dificil(2, 'Difícil'),
  bom(3, 'Bom'),
  facil(4, 'Fácil');

  const Grade(this.value, this.label);

  /// Valor gravado em `ReviewLogs.rating`.
  final int value;
  final String label;

  fsrs.Rating get _rating =>
      fsrs.Rating.values.firstWhere((r) => r.value == value);
}

fsrs.State _toFsrsState(CardState s) => switch (s) {
  CardState.learning => fsrs.State.learning,
  CardState.review => fsrs.State.review,
  CardState.relearning => fsrs.State.relearning,
};

CardState _fromFsrsState(fsrs.State s) => switch (s) {
  fsrs.State.learning => CardState.learning,
  fsrs.State.review => CardState.review,
  fsrs.State.relearning => CardState.relearning,
};

fsrs.Card toFsrsCard(CardSchedule s) => fsrs.Card(
  cardId: 0, // o FSRS só usa o id nos logs dele; o nosso é o UUID
  state: _toFsrsState(s.state),
  step: s.step,
  stability: s.stability,
  difficulty: s.difficulty,
  due: s.due.toUtc(),
  lastReview: s.lastReview?.toUtc(),
);

CardSchedule fromFsrsCard(fsrs.Card c) => CardSchedule(
  state: _fromFsrsState(c.state),
  step: c.step,
  stability: c.stability,
  difficulty: c.difficulty,
  due: c.due.toLocal(),
  lastReview: c.lastReview?.toLocal(),
);

/// Agendador com a retenção desejada (passos de aprendizado 1 e 10 min e
/// reaprendizado 10 min, os padrões do FSRS).
fsrs.Scheduler buildScheduler({double desiredRetention = 0.9}) =>
    fsrs.Scheduler(desiredRetention: desiredRetention);

/// Resultado de cada nota, calculado antes de responder. A tela mostra o
/// intervalo de cada botão e grava exatamente o resultado escolhido, então
/// o que aparece no botão é o que acontece (mesmo com o "fuzz").
Map<Grade, CardSchedule> previewReview(
  fsrs.Scheduler scheduler,
  CardSchedule current,
  DateTime now,
) {
  final card = toFsrsCard(current);
  return {
    for (final grade in Grade.values)
      grade: fromFsrsCard(
        scheduler
            .reviewCard(card, grade._rating, reviewDateTime: now.toUtc())
            .card,
      ),
  };
}

/// "1 min", "10 min", "3 h", "4 d", "2 meses", "1,5 anos" (ou em `en`/`es`).
String formatInterval(Duration d, {String lang = 'pt'}) {
  final minutes = d.inMinutes;
  if (minutes < 60) return '${minutes < 1 ? 1 : minutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  final days = d.inDays;
  if (days < 30) return '$days d';
  if (days < 365) {
    final months = (days / 30).round();
    return switch (lang) {
      'en' => months == 1 ? '1 mo' : '$months mo',
      'es' => months == 1 ? '1 mes' : '$months meses',
      _ => months == 1 ? '1 mês' : '$months meses',
    };
  }
  final years = days / 365;
  final raw = years.toStringAsFixed(1);
  if (lang == 'en') {
    return raw == '1.0' ? '1 yr' : '${raw.replaceAll('.0', '')} yr';
  }
  final text = raw.replaceAll('.', ',');
  return switch (lang) {
    'es' => text == '1,0' ? '1 año' : '${text.replaceAll(',0', '')} años',
    _ => text == '1,0' ? '1 ano' : '${text.replaceAll(',0', '')} anos',
  };
}
