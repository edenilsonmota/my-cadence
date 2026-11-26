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
        // Os novos saem na ordem do id (UUID v7, por milissegundo): no mesmo
        // milissegundo a ordem dependeria do sufixo aleatório.
        await Future<void>.delayed(const Duration(milliseconds: 3));
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

  testWidgets('intervalos dos botões não "envelhecem" com o relógio andando', (
    tester,
  ) async {
    // Cada leitura do relógio avança 200 ms, como no aparelho.
    var t = now;
    await pumpApp(
      tester,
      clock: () => t = t.add(const Duration(milliseconds: 200)),
      seed: (db) => cardsOf(db).createCard(front: 'Q', back: 'R', now: now),
    );
    await goToReviewTab(tester);
    await tester.tap(find.text('Revisar tudo'));
    await settle(tester);
    await tester.tap(find.text('Mostrar resposta'));
    await settle(tester);

    expect(find.text('10 min'), findsOneWidget); // passo de aprendizado
    expect(find.text('9 min'), findsNothing);
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

  testWidgets('importa CSV de arquivo para um deck e permite editar antes', (
    tester,
  ) async {
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

    await tester.tap(find.text('Carregar arquivo'));
    await settle(tester);
    expect(find.text('2 cards encontrados.'), findsOneWidget);
    expect(find.textContaining('Linhas ignoradas'), findsOneWidget);

    await tester.tap(find.text('Sem deck'));
    await settle(tester);
    await tester.tap(find.text('Química').last);
    await settle(tester);
    await tester.tap(find.text('Importar 2 cards'));
    await settle(tester);

    expect(find.text('2 cards importados.'), findsOneWidget);
    final cards = (await tester.runAsync(
      () => cardsOf(db).watchCards().first,
    ))!;
    expect(cards.map((c) => c.front), unorderedEquals(['H2O', 'NaCl']));
    expect(cards.every((c) => c.deckId != null), isTrue);
  });

  testWidgets(
    'cola CSV sem arquivo dentro do deck e acrescenta em lotes ignorando duplicados',
    (tester) async {
      final db = await pumpApp(
        tester,
        seed: (db) => cardsOf(db).createDeck(name: 'Inglês'),
      );
      await goToReviewTab(tester);

      // Entra no deck Inglês e importa colando texto direto (sem arquivo).
      await tester.tap(find.text('Inglês'));
      await settle(tester);
      await tester.tap(find.text('Importar CSV'));
      await settle(tester);

      // O deck atual já vem selecionado.
      expect(
        find.descendant(
          of: find.byType(DropdownButtonFormField<String?>),
          matching: find.text('Inglês'),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Cards (frente;verso)'),
        'apple;maçã\nbook;livro',
      );
      await settle(tester);
      expect(find.text('2 cards encontrados.'), findsOneWidget);
      await tester.tap(find.text('Importar 2 cards'));
      await settle(tester);

      expect(find.text('2 cards importados.'), findsOneWidget);
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('book'), findsOneWidget);

      // Segundo lote no mesmo deck: ignora duplicado (APPLE e repetido no lote).
      await tester.tap(find.byTooltip('Importar CSV'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Cards (frente;verso)'),
        'APPLE;maçã\nhouse;casa\nhouse;moradia',
      );
      await settle(tester);
      expect(
        find.text('1 card encontrado. 2 duplicados ignorados.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Importar 1 card'));
      await settle(tester);

      expect(
        find.text('1 card importado. 2 duplicados ignorados.'),
        findsOneWidget,
      );
      final cards = (await tester.runAsync(
        () => cardsOf(db).watchCards().first,
      ))!;
      expect(
        cards.map((c) => c.front),
        unorderedEquals(['apple', 'book', 'house']),
      );
      expect(cards.map((c) => c.deckId).toSet(), hasLength(1));
    },
  );

  testWidgets('cria deck novo dentro da importação CSV e importa nele', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await goToReviewTab(tester);

    await tester.tap(find.text('Importar CSV'));
    await settle(tester);

    await tester.tap(find.byTooltip('Novo deck'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Espanhol');
    await settle(tester);
    await tester.tap(find.text('Criar'));
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Cards (frente;verso)'),
      'hola;olá\ngracias;obrigado',
    );
    await settle(tester);
    await tester.tap(find.text('Importar 2 cards'));
    await settle(tester);

    final decks = (await tester.runAsync(
      () => cardsOf(db).watchDecks().first,
    ))!;
    expect(decks.map((d) => d.name), ['Espanhol']);
    final cards = (await tester.runAsync(
      () => cardsOf(db).watchCards().first,
    ))!;
    expect(cards.map((c) => c.front), unorderedEquals(['hola', 'gracias']));
    expect(cards.every((c) => c.deckId == decks.single.id), isTrue);
  });
}
