/// Fila de revisão e ajustes dos flashcards. Puro, sem Flutter.
library;

import '../../data/db/database.dart';

class CardSettings {
  const CardSettings({this.newPerDay = 20, this.retentionPercent = 90});

  factory CardSettings.fromMap(Map<String, String> map) {
    const d = CardSettings();
    final perDay = int.tryParse(map[keyNewPerDay] ?? '');
    final retention = int.tryParse(map[keyRetention] ?? '');
    return CardSettings(
      newPerDay: perDay == null || perDay < 0 ? d.newPerDay : perDay,
      retentionPercent: retention == null || retention < 70 || retention > 99
          ? d.retentionPercent
          : retention,
    );
  }

  static const prefix = 'cards.';
  static const keyNewPerDay = 'cards.novosPorDia';
  static const keyRetention = 'cards.retencaoPct';

  /// Quantos cards novos (nunca revisados) entram por dia.
  final int newPerDay;

  /// Retenção desejada do FSRS, em % (70 a 99).
  final int retentionPercent;

  double get desiredRetention => retentionPercent / 100;
}

/// Card nunca revisado.
bool isNewCard(Flashcard card) => card.lastReview == null;

/// Cards a revisar agora: primeiro os já estudados (aprendendo, reaprendendo
/// e revisão), do mais atrasado ao mais recente; depois os novos, na ordem
/// de criação, até o limite do dia.
List<Flashcard> buildQueue(
  Iterable<Flashcard> cards,
  DateTime now, {
  required int newPerDay,
  required int newStudiedToday,
}) {
  final due = cards.where((c) => !c.suspended && !c.due.isAfter(now));
  final studied = due.where((c) => !isNewCard(c)).toList()
    ..sort((a, b) => a.due.compareTo(b.due));
  final remainingNew = newPerDay - newStudiedToday;
  final fresh = remainingNew <= 0
      ? <Flashcard>[]
      : (due.where(isNewCard).toList()..sort((a, b) => a.id.compareTo(b.id)))
            .take(remainingNew)
            .toList();
  return [...studied, ...fresh];
}

/// Com a fila vazia: quando vence o próximo card já estudado, se for dentro
/// de [window] (passos curtos de aprendizado, ex.: 1 e 10 min).
DateTime? nextDueSoon(
  Iterable<Flashcard> cards,
  DateTime now, {
  Duration window = const Duration(minutes: 20),
}) {
  DateTime? next;
  for (final c in cards) {
    if (c.suspended || isNewCard(c) || !c.due.isAfter(now)) continue;
    if (c.due.isAfter(now.add(window))) continue;
    if (next == null || c.due.isBefore(next)) next = c.due;
  }
  return next;
}
