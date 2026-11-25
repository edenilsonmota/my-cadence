import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/card_schedule.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/tasks_repository.dart';

import 'test_db.dart';

final now = DateTime(2026, 11, 23, 12);

void main() {
  late AppDatabase db;
  late CardsRepository repo;
  late TasksRepository tasks;

  setUp(() {
    db = openTestDb();
    repo = CardsRepository(db.cardsDao);
    tasks = TasksRepository(db.tasksDao, db.tagsDao);
  });

  group('decks', () {
    test('CRUD', () async {
      final id = await repo.createDeck(name: 'Inglês', description: 'Verbos');
      var deck = (await repo.watchDecks().first).single;
      expect(deck.name, 'Inglês');
      expect(deck.description, 'Verbos');

      await repo.saveDeck(deck.copyWith(name: 'English'));
      deck = (await repo.watchDecks().first).single;
      expect(deck.name, 'English');

      await repo.deleteDeck(id);
      expect(await repo.watchDecks().first, isEmpty);
    });

    test('excluir o deck mantém os cards, sem deck', () async {
      final deck = await repo.createDeck(name: 'Inglês');
      final card = await repo.createCard(
        front: 'go',
        back: 'ir',
        now: now,
        deckId: deck,
      );

      await repo.deleteDeck(deck);

      final saved = (await repo.getCard(card))!;
      expect(saved.deckId, isNull);
    });
  });

  group('cards', () {
    test('card novo começa no estado inicial do FSRS', () async {
      final id = await repo.createCard(front: 'F', back: 'V', now: now);
      final card = (await repo.getCard(id))!;

      expect(card.state, CardState.learning);
      expect(card.step, 0);
      expect(card.stability, isNull);
      expect(card.difficulty, isNull);
      expect(card.due, now);
      expect(card.lastReview, isNull);
      expect(card.suspended, isFalse);
    });

    test('edita conteúdo, suspende e exclui', () async {
      final id = await repo.createCard(front: 'F', back: 'V', now: now);
      final card = (await repo.getCard(id))!;

      await repo.saveCard(card.copyWith(back: 'Verso', suspended: true));
      final saved = (await repo.getCard(id))!;
      expect(saved.back, 'Verso');
      expect(saved.suspended, isTrue);

      await repo.deleteCard(id);
      expect(await repo.getCard(id), isNull);
    });

    test(
      'fila de vencidos filtra por data, suspensão, deck e tarefa',
      () async {
        final deck = await repo.createDeck(name: 'D');
        final task = await tasks.createTask(title: 'T');
        Future<String> card(
          String front, {
          required DateTime due,
          String? deckId,
          String? taskId,
        }) => repo.createCard(
          front: front,
          back: '-',
          now: due,
          deckId: deckId,
          taskId: taskId,
        );

        await card('atrasado', due: now.subtract(const Duration(days: 2)));
        await card('agora', due: now, deckId: deck);
        await card('futuro', due: now.add(const Duration(minutes: 1)));
        await card(
          'da tarefa',
          due: now.subtract(const Duration(hours: 1)),
          taskId: task,
        );
        final suspended = await card(
          'suspenso',
          due: now.subtract(const Duration(days: 1)),
        );
        final s = (await repo.getCard(suspended))!;
        await repo.saveCard(s.copyWith(suspended: true));

        Future<List<String>> due({String? deckId, String? taskId}) async =>
            (await repo.watchDue(now, deckId: deckId, taskId: taskId).first)
                .map((c) => c.front)
                .toList();

        expect(await due(), ['atrasado', 'da tarefa', 'agora']);
        expect(await due(deckId: deck), ['agora']);
        expect(await due(taskId: task), ['da tarefa']);

        final all = await repo.watchCards().first;
        expect(all, hasLength(5));
      },
    );
  });

  group('revisões', () {
    test('aplicar grava agendamento e log; desfazer volta os dois', () async {
      final id = await repo.createCard(front: 'F', back: 'V', now: now);
      final before = CardSchedule.of((await repo.getCard(id))!);
      final next = CardSchedule(
        state: CardState.review,
        stability: 3.2,
        difficulty: 5.1,
        due: now.add(const Duration(days: 3)),
        lastReview: now,
      );

      final logId = await repo.applyReview(
        cardId: id,
        next: next,
        rating: 4,
        reviewedAt: now,
        durationMs: 2500,
      );
      expect(CardSchedule.of((await repo.getCard(id))!), next);
      expect((await repo.getReviewLogs(id)).single.rating, 4);

      await repo.undoReview(cardId: id, previous: before, logId: logId);
      expect(CardSchedule.of((await repo.getCard(id))!), before);
      expect(await repo.getReviewLogs(id), isEmpty);
    });

    test('revisões a partir de uma data, sem as desfeitas', () async {
      final id = await repo.createCard(front: 'a', back: '-', now: now);
      await repo.addReviewLog(
        cardId: id,
        rating: 3,
        reviewedAt: DateTime(2026, 11, 1),
      );
      final kept = DateTime(2026, 11, 20, 9);
      await repo.addReviewLog(cardId: id, rating: 2, reviewedAt: kept);
      final undone = await repo.addReviewLog(
        cardId: id,
        rating: 4,
        reviewedAt: DateTime(2026, 11, 21),
      );
      await repo.deleteReviewLog(undone);
      final logs = await repo
          .watchReviewLogsSince(DateTime(2026, 11, 15))
          .first;
      expect(logs.map((l) => (l.reviewedAt, l.rating)), [(kept, 2)]);
    });

    test('conta cards com a primeira revisão a partir de hoje', () async {
      final today = DateTime(2026, 11, 23);
      final old = await repo.createCard(front: 'a', back: '-', now: now);
      final fresh1 = await repo.createCard(front: 'b', back: '-', now: now);
      final fresh2 = await repo.createCard(front: 'c', back: '-', now: now);
      await repo.addReviewLog(
        cardId: old,
        rating: 3,
        reviewedAt: DateTime(2026, 11, 20),
      );
      await repo.addReviewLog(cardId: old, rating: 3, reviewedAt: now);
      await repo.addReviewLog(cardId: fresh1, rating: 3, reviewedAt: now);
      await repo.addReviewLog(cardId: fresh1, rating: 1, reviewedAt: now);
      final undone = await repo.addReviewLog(
        cardId: fresh2,
        rating: 3,
        reviewedAt: now,
      );

      expect(await repo.watchNewStudiedSince(today).first, 2);
      await repo.deleteReviewLog(undone); // desfazer devolve o "novo"
      expect(await repo.watchNewStudiedSince(today).first, 1);
    });

    test('registra, lista e desfaz', () async {
      final card = await repo.createCard(front: 'F', back: 'V', now: now);
      await repo.addReviewLog(
        cardId: card,
        rating: 3,
        reviewedAt: now,
        durationMs: 4200,
      );
      final last = await repo.addReviewLog(
        cardId: card,
        rating: 1,
        reviewedAt: now.add(const Duration(minutes: 10)),
      );

      var logs = await repo.getReviewLogs(card);
      expect(logs.map((l) => l.rating), [3, 1]);
      expect(logs.first.durationMs, 4200);

      await repo.deleteReviewLog(last);
      logs = await repo.getReviewLogs(card);
      expect(logs.map((l) => l.rating), [3]);
    });

    test('nota fora de 1..4 é rejeitada pelo banco', () async {
      final card = await repo.createCard(front: 'F', back: 'V', now: now);
      expect(
        () => repo.addReviewLog(cardId: card, rating: 5, reviewedAt: now),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('decks vinculados a tarefas', () {
    test('define o conjunto, desfaz, revive e esconde deck excluído', () async {
      final ingles = await repo.createDeck(name: 'Inglês');
      final fisica = await repo.createDeck(name: 'Física');
      final task = await tasks.createTask(title: 'Prova');

      await repo.setTaskDecks(task, {ingles, fisica});
      expect((await repo.watchLinkedDecks(task).first).map((d) => d.name), [
        'Física',
        'Inglês',
      ]);

      await repo.setTaskDecks(task, {ingles});
      expect((await repo.watchLinkedDecks(task).first).map((d) => d.id), [
        ingles,
      ]);

      await repo.setTaskDecks(task, {ingles, fisica});
      expect(await db.select(db.taskDeckLinks).get(), hasLength(2));

      await repo.unlinkDeck(task, fisica);
      await repo.deleteDeck(ingles);
      expect(await repo.watchLinkedDecks(task).first, isEmpty);
    });
  });
}
