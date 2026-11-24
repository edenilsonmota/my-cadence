import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/card_schedule.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/features/cards/card_actions.dart';
import 'package:my_cadence/features/cards/review_queue.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 23, 12); // relógio padrão do pumpApp

CardsRepository cardsOf(AppDatabase db) => CardsRepository(db.cardsDao);

Future<void> goToReviewTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Revisar'),
    ),
  );
  await settle(tester);
}

/// Um card já estudado, vencido há um dia.
Future<String> seedReviewCard(AppDatabase db, String front) async {
  final repo = cardsOf(db);
  final id = await repo.createCard(front: front, back: 'resposta', now: now);
  await repo.applyReview(
    cardId: id,
    next: CardSchedule(
      state: CardState.review,
      stability: 5,
      difficulty: 5,
      due: now.subtract(const Duration(days: 1)),
      lastReview: now.subtract(const Duration(days: 6)),
    ),
    rating: 3,
    reviewedAt: now.subtract(const Duration(days: 6)),
  );
  return id;
}

void main() {
  testWidgets('badge, revisar tudo, prévia dos intervalos e desfazer', (
    tester,
  ) async {
    final db = await pumpApp(
      tester,
      seed: (db) async {
        await seedReviewCard(db, 'Antigo');
        await cardsOf(db).createCard(front: 'Novo A', back: 'a', now: now);
        await cardsOf(db).createCard(front: 'Novo B', back: 'b', now: now);
      },
    );

    // Badge na aba.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('3')),
      findsOneWidget,
    );
    await goToReviewTab(tester);
    expect(find.text('3 para revisar agora'), findsOneWidget);

    await tester.tap(find.text('Revisar tudo'));
    await settle(tester);

    // Estudados primeiro, depois os novos.
    expect(find.text('Antigo'), findsOneWidget);
    expect(find.text('3 cards restantes'), findsOneWidget);
    await tester.tap(find.text('Mostrar resposta'));
    await settle(tester);
    expect(find.text('resposta'), findsOneWidget);
    for (final label in ['Errei', 'Difícil', 'Bom', 'Fácil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('10 min'), findsOneWidget); // Errei → reaprender

    await tester.tap(find.text('Bom'));
    await settle(tester);
    expect(find.text('Novo A'), findsOneWidget);
    expect(find.text('2 cards restantes · novo'), findsOneWidget);

    // Desfazer volta o card anterior e apaga o log.
    await tester.tap(find.byTooltip('Desfazer última avaliação'));
    await settle(tester);
    expect(find.text('Antigo'), findsOneWidget);
    final logsAfterUndo = await tester.runAsync(
      () => db.select(db.reviewLogs).get(),
    );
    expect(
      logsAfterUndo!.where((l) => l.deletedAt == null),
      hasLength(1), // só o do seed
    );

    // Responde os três: Fácil tira todos da fila de hoje.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Mostrar resposta'));
      await settle(tester);
      await tester.tap(find.text('Fácil'));
      await settle(tester);
    }
    expect(find.textContaining('Tudo revisado por agora!'), findsOneWidget);

    final logs = (await tester.runAsync(() => db.select(db.reviewLogs).get()))!
        .where((l) => l.deletedAt == null && l.reviewedAt == now)
        .toList();
    expect(logs, hasLength(3));
    expect(logs.every((l) => l.rating == 4), isTrue);
    expect(logs.every((l) => l.durationMs != null), isTrue);
  });

  testWidgets('Errei num card novo mostra "Próximo card em 1 min"', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (db) => cardsOf(db).createCard(front: 'Q', back: 'R', now: now),
    );
    await goToReviewTab(tester);
    await tester.tap(find.text('Revisar tudo'));
    await settle(tester);
    await tester.tap(find.text('Mostrar resposta'));
    await settle(tester);
    expect(find.text('1 min'), findsOneWidget); // Errei

    await tester.tap(find.text('Errei'));
    await settle(tester);
    expect(find.textContaining('Próximo card em 1 min'), findsOneWidget);
  });

  testWidgets('limite de novos por dia', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async {
        await SettingsRepository(db.settingsDao)
            .setString(CardSettings.keyNewPerDay, '2');
        for (final f in ['a', 'b', 'c', 'd']) {
          await cardsOf(db).createCard(front: f, back: '-', now: now);
        }
      },
    );
    await goToReviewTab(tester);
    expect(find.text('2 para revisar agora'), findsOneWidget);
  });

  testWidgets('cria deck e card, suspende, exclui e desfaz', (tester) async {
    final db = await pumpApp(tester);
    await goToReviewTab(tester);

    await tester.tap(find.byTooltip('Mais opções'));
    await settle(tester);
    await tester.tap(find.text('Novo deck'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Inglês');
    await settle(tester);
    await tester.tap(find.text('Criar'));
    await settle(tester);
    expect(find.text('Inglês'), findsOneWidget);

    await tester.tap(find.text('Inglês'));
    await settle(tester);
    await tester.tap(find.byTooltip('Novo card'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Frente'), 'go');
    await tester.enterText(find.widgetWithText(TextField, 'Verso'), 'ir');
    await settle(tester);
    await tester.tap(find.text('Salvar card'));
    await settle(tester);
    expect(find.text('go'), findsOneWidget);
    expect(find.text('Novo'), findsOneWidget);
    expect(find.text('Revisar 1 agora'), findsOneWidget);

    await tester.tap(find.byTooltip('Opções do card'));
    await settle(tester);
    await tester.tap(find.text('Suspender'));
    await settle(tester);
    expect(find.text('Suspenso'), findsOneWidget);
    expect(find.text('Revisar 1 agora'), findsNothing);

    await tester.tap(find.byTooltip('Opções do card'));
    await settle(tester);
    await tester.tap(find.text('Excluir'));
    await settle(tester);
    expect(find.text('go'), findsNothing);
    await tester.tap(find.text('Desfazer'));
    await settle(tester);
    expect(find.text('go'), findsOneWidget);

    final card = (await tester.runAsync(() => cardsOf(db).watchCards().first))!
        .single;
    expect(card.deckId, isNotNull);
    expect(card.suspended, isTrue);
  });

  testWidgets('importa CSV para um deck', (tester) async {
    final db = await pumpApp(
      tester,
      seed: (db) => cardsOf(db).createDeck(name: 'Química'),
      overrides: [
        csvPickerProvider.overrideWithValue(
          () async => 'frente;verso\nH2O;Água\nNaCl;Sal\nsem verso;\n',
        ),
      ],
    );
    await goToReviewTab(tester);

    await tester.tap(find.byTooltip('Mais opções'));
    await settle(tester);
    await tester.tap(find.text('Importar CSV'));
    await settle(tester);
    expect(find.text('2 cards encontrados.'), findsOneWidget);
    expect(find.textContaining('Linhas ignoradas'), findsOneWidget);

    await tester.tap(find.text('Sem deck'));
    await settle(tester);
    await tester.tap(find.text('Química').last);
    await settle(tester);
    await tester.tap(find.text('Importar'));
    await settle(tester);

    expect(find.text('2 cards importados.'), findsOneWidget);
    final cards = (await tester.runAsync(
      () => cardsOf(db).watchCards().first,
    ))!;
    expect(cards.map((c) => c.front), unorderedEquals(['H2O', 'NaCl']));
    expect(cards.every((c) => c.deckId != null), isTrue);
  });
}
