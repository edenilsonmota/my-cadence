import 'package:drift/drift.dart';

import '../database.dart';
import '../sync_writes.dart';
import '../tables/cards.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [Decks, Flashcards, ReviewLogs, TaskDeckLinks])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.attachedDatabase);

  // Decks

  Future<void> insertDeck(DecksCompanion row) => insertSynced(decks, row);

  Future<void> updateDeck(String id, DecksCompanion patch) =>
      updateSynced(decks, id, patch);

  /// Exclui o deck. Os cards continuam existindo, sem deck.
  Future<void> softDeleteDeck(String id) => transaction(() async {
    final cards = await (select(
      flashcards,
    )..where((c) => c.deckId.equals(id) & c.deletedAt.isNull())).get();
    for (final card in cards) {
      await updateSynced(
        flashcards,
        card.id,
        const FlashcardsCompanion(deckId: Value(null)),
      );
    }
    await softDeleteSynced(decks, id);
  });

  Stream<List<Deck>> watchDecks() =>
      (select(decks)
            ..where((d) => d.deletedAt.isNull())
            ..orderBy([(d) => OrderingTerm.asc(d.name)]))
          .watch();

  // Vínculos deck ↔ tarefa

  /// Deixa a tarefa vinculada exatamente aos decks em [deckIds]: revive os
  /// vínculos excluídos, cria os novos e exclui os que saíram.
  Future<void> setTaskDecks(String taskId, Set<String> deckIds) =>
      transaction(() async {
        final existing = await (select(
          taskDeckLinks,
        )..where((l) => l.taskId.equals(taskId))).get();
        final byDeck = {for (final l in existing) l.deckId: l};
        for (final link in existing) {
          if (link.deletedAt == null && !deckIds.contains(link.deckId)) {
            await softDeleteSynced(taskDeckLinks, link.id);
          }
        }
        for (final deckId in deckIds) {
          final link = byDeck[deckId];
          if (link == null) {
            await insertSynced(
              taskDeckLinks,
              TaskDeckLinksCompanion.insert(taskId: taskId, deckId: deckId),
            );
          } else if (link.deletedAt != null) {
            await updateSynced(
              taskDeckLinks,
              link.id,
              const TaskDeckLinksCompanion(deletedAt: Value(null)),
            );
          }
        }
      });

  Future<void> unlinkDeck(String taskId, String deckId) =>
      transaction(() async {
        final existing =
            await (select(taskDeckLinks)..where(
                  (l) =>
                      l.taskId.equals(taskId) &
                      l.deckId.equals(deckId) &
                      l.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (existing != null) {
          await softDeleteSynced(taskDeckLinks, existing.id);
        }
      });

  /// Decks vinculados à tarefa (sem os excluídos), por nome.
  Stream<List<Deck>> watchLinkedDecks(String taskId) {
    final query =
        select(decks).join([
            innerJoin(taskDeckLinks, taskDeckLinks.deckId.equalsExp(decks.id)),
          ])
          ..where(
            taskDeckLinks.taskId.equals(taskId) &
                taskDeckLinks.deletedAt.isNull() &
                decks.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(decks.name)]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(decks)],
    );
  }

  // Flashcards

  Future<void> insertCard(FlashcardsCompanion row) =>
      insertSynced(flashcards, row);

  Future<void> updateCard(String id, FlashcardsCompanion patch) =>
      updateSynced(flashcards, id, patch);

  Future<void> softDeleteCard(String id) => softDeleteSynced(flashcards, id);

  Future<Flashcard?> getCard(String id) => (select(
    flashcards,
  )..where((c) => c.id.equals(id) & c.deletedAt.isNull())).getSingleOrNull();

  Expression<bool> _filter($FlashcardsTable c, String? deckId, String? taskId) {
    var where = c.deletedAt.isNull();
    if (deckId != null) where &= c.deckId.equals(deckId);
    if (taskId != null) where &= c.taskId.equals(taskId);
    return where;
  }

  /// Cards vivos, opcionalmente de um deck e/ou de uma tarefa.
  Stream<List<Flashcard>> watchCards({String? deckId, String? taskId}) =>
      (select(flashcards)
            ..where((c) => _filter(c, deckId, taskId))
            ..orderBy([(c) => OrderingTerm.asc(c.id)]))
          .watch();

  /// Cards vivos de um conjunto de tarefas (ex.: tarefa + subtarefas).
  Stream<List<Flashcard>> watchCardsOfTasks(List<String> taskIds) =>
      (select(flashcards)
            ..where((c) => c.taskId.isIn(taskIds) & c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.due)]))
          .watch();

  /// Fila de revisão: cards não suspensos com `due <= now`, do mais atrasado
  /// para o mais recente.
  Stream<List<Flashcard>> watchDue(
    DateTime now, {
    String? deckId,
    String? taskId,
  }) =>
      (select(flashcards)
            ..where(
              (c) =>
                  _filter(c, deckId, taskId) &
                  c.suspended.equals(false) &
                  c.due.isSmallerOrEqualValue(now),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.due)]))
          .watch();

  // Review logs

  Future<void> insertReviewLog(ReviewLogsCompanion row) =>
      insertSynced(reviewLogs, row);

  /// Quantos cards tiveram a primeira revisão em [since] ou depois (os
  /// "novos estudados hoje", para o limite diário).
  Stream<int> watchNewStudiedSince(DateTime since) {
    final first = reviewLogs.reviewedAt.min();
    final query = selectOnly(reviewLogs)
      ..addColumns([reviewLogs.cardId, first])
      ..where(reviewLogs.deletedAt.isNull())
      ..groupBy([reviewLogs.cardId], having: first.isBiggerOrEqualValue(since));
    return query.watch().map((rows) => rows.length);
  }

  /// Revisões feitas em [since] ou depois (métricas).
  Stream<List<ReviewLog>> watchReviewLogsSince(DateTime since) =>
      (select(reviewLogs)
            ..where(
              (l) =>
                  l.reviewedAt.isBiggerOrEqualValue(since) &
                  l.deletedAt.isNull(),
            )
            ..orderBy([(l) => OrderingTerm.asc(l.reviewedAt)]))
          .watch();

  /// Usado para desfazer a última avaliação.
  Future<void> softDeleteReviewLog(String id) =>
      softDeleteSynced(reviewLogs, id);

  Future<List<ReviewLog>> getReviewLogs(String cardId) =>
      (select(reviewLogs)
            ..where((l) => l.cardId.equals(cardId) & l.deletedAt.isNull())
            ..orderBy([(l) => OrderingTerm.asc(l.reviewedAt)]))
          .get();
}
