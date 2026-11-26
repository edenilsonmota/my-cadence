/// Fila de revisão e ajustes dos flashcards. Puro, sem Flutter.
library;

import '../../data/db/card_schedule.dart';
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

/// Escolhe o card da tela de revisão.
///
/// - [justAnswered]: cards respondidos agora há pouco, com o agendamento de
///   ANTES da resposta. Enquanto a consulta ainda trouxer essa cópia velha
///   (o banco responde um instante depois), o card é ignorado; sem isso ele
///   reaparecia e era revisado duas vezes (achado no aparelho).
/// - [undoneId]: card cuja revisão foi desfeita; volta à tela mesmo que não
///   esteja vencido.
/// - [currentId]: card já na tela; continua nela enquanto estiver na fila.
Flashcard? pickCurrentCard({
  required List<Flashcard> queue,
  required List<Flashcard> scopeCards,
  String? currentId,
  String? undoneId,
  Map<String, CardSchedule> justAnswered = const {},
}) {
  bool stale(Flashcard c) => justAnswered[c.id] == CardSchedule.of(c);
  if (undoneId != null) {
    final undone =
        queue.where((c) => c.id == undoneId).firstOrNull ??
        scopeCards.where((c) => c.id == undoneId).firstOrNull;
    if (undone != null) return undone;
  }
  final fresh = queue.where((c) => !stale(c));
  if (currentId != null) {
    final current = fresh.where((c) => c.id == currentId).firstOrNull;
    if (current != null) return current;
  }
  return fresh.firstOrNull;
}

/// Filtro rápido da lista de cards de um deck.
enum CardListFilter { all, due, newCards, suspended }

String _fold(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  return [
    for (final ch in s.toLowerCase().split(''))
      from.contains(ch) ? to[from.indexOf(ch)] : ch,
  ].join();
}

/// Filtra [cards] por estado ([filter]) e busca ([query] na frente ou verso,
/// sem diferenciar maiúsculas nem acentos).
List<Flashcard> filterDeckCards(
  Iterable<Flashcard> cards, {
  required DateTime now,
  String query = '',
  CardListFilter filter = CardListFilter.all,
}) {
  final q = _fold(query.trim());
  return [
    for (final c in cards)
      if (_matchesFilter(c, filter, now) &&
          (q.isEmpty ||
              _fold(c.front).contains(q) ||
              _fold(c.back).contains(q)))
        c,
  ];
}

bool _matchesFilter(Flashcard card, CardListFilter filter, DateTime now) =>
    switch (filter) {
      CardListFilter.all => true,
      CardListFilter.due => !card.suspended && !card.due.isAfter(now),
      CardListFilter.newCards => !card.suspended && isNewCard(card),
      CardListFilter.suspended => card.suspended,
    };
