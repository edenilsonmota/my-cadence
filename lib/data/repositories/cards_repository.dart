import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/daos/cards_dao.dart';
import '../db/database.dart';
import '../db/enums.dart';

/// Decks, flashcards e histórico de revisões. A ponte com o FSRS (gravar o
/// novo agendamento após uma revisão) entra na Etapa 6.
class CardsRepository {
  CardsRepository(this._dao);

  final CardsDao _dao;

  // Decks

  Stream<List<Deck>> watchDecks() => _dao.watchDecks();

  Future<String> createDeck({required String name, String? description}) async {
    final id = newId();
    await _dao.insertDeck(
      DecksCompanion.insert(
        id: Value(id),
        name: name,
        description: Value(description),
      ),
    );
    return id;
  }

  Future<void> saveDeck(Deck deck) => _dao.updateDeck(
    deck.id,
    DecksCompanion(
      name: Value(deck.name),
      description: Value(deck.description),
    ),
  );

  /// Exclui o deck; os cards dele ficam sem deck.
  Future<void> deleteDeck(String id) => _dao.softDeleteDeck(id);

  // Cards

  Future<Flashcard?> getCard(String id) => _dao.getCard(id);

  Stream<List<Flashcard>> watchCards({String? deckId, String? taskId}) =>
      _dao.watchCards(deckId: deckId, taskId: taskId);

  Stream<List<Flashcard>> watchDue(
    DateTime now, {
    String? deckId,
    String? taskId,
  }) => _dao.watchDue(now, deckId: deckId, taskId: taskId);

  /// Cria um card novo (estado inicial do FSRS: aprendendo, passo 0, vence
  /// em [now]) e devolve o id.
  Future<String> createCard({
    required String front,
    required String back,
    required DateTime now,
    String? deckId,
    String? taskId,
    String? sourcePageId,
  }) async {
    final id = newId();
    await _dao.insertCard(
      FlashcardsCompanion.insert(
        id: Value(id),
        front: front,
        back: back,
        deckId: Value(deckId),
        taskId: Value(taskId),
        sourcePageId: Value(sourcePageId),
        state: const Value(CardState.learning),
        step: const Value(0),
        due: now,
      ),
    );
    return id;
  }

  /// Grava o conteúdo e os vínculos do card (não mexe no agendamento FSRS).
  Future<void> saveCard(Flashcard card) => _dao.updateCard(
    card.id,
    FlashcardsCompanion(
      front: Value(card.front),
      back: Value(card.back),
      deckId: Value(card.deckId),
      taskId: Value(card.taskId),
      sourcePageId: Value(card.sourcePageId),
      suspended: Value(card.suspended),
    ),
  );

  Future<void> deleteCard(String id) => _dao.softDeleteCard(id);

  // Revisões

  Future<List<ReviewLog>> getReviewLogs(String cardId) =>
      _dao.getReviewLogs(cardId);

  Future<String> addReviewLog({
    required String cardId,
    required int rating,
    required DateTime reviewedAt,
    int? durationMs,
  }) async {
    final id = newId();
    await _dao.insertReviewLog(
      ReviewLogsCompanion.insert(
        id: Value(id),
        cardId: cardId,
        rating: rating,
        reviewedAt: reviewedAt,
        durationMs: Value(durationMs),
      ),
    );
    return id;
  }

  Future<void> deleteReviewLog(String id) => _dao.softDeleteReviewLog(id);
}
