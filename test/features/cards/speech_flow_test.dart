import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/features/cards/card_speaker.dart';
import 'package:my_cadence/features/cards/card_speech.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 23, 12);

class FakeSpeaker implements CardSpeaker {
  final spoken = <({String text, String lang, bool slow})>[];

  @override
  Future<void> speak(String text, String lang, {bool slow = false}) async =>
      spoken.add((text: text, lang: lang, slow: slow));

  @override
  Future<void> stop() async {}

  @override
  Future<List<String>> languages() async => ['en-US', 'pt-BR'];
}

Future<void> goToReview(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Revisar'),
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets('lê a frente sozinho, o verso ao revelar e pelo botão', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    await pumpApp(
      tester,
      overrides: [cardSpeakerProvider.overrideWithValue(speaker)],
      seed: (db) async {
        final cards = CardsRepository(db.cardsDao);
        final deck = await cards.createDeck(name: 'Inglês');
        await cards.createCard(
          front: '**house**',
          back: 'casa',
          now: now,
          deckId: deck,
        );
        await SettingsRepository(db.settingsDao).setString(
          DeckSpeech.keyFor(deck),
          const DeckSpeech(front: 'en-US', back: 'pt-BR', auto: true).encode(),
        );
      },
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Revisar'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Revisar tudo'));
    await settle(tester);

    expect(speaker.spoken, [(text: '**house**', lang: 'en-US', slow: false)]);
    await tester.tap(find.text('Mostrar resposta'));
    await settle(tester);
    expect(speaker.spoken.last, (text: 'casa', lang: 'pt-BR', slow: false));

    await tester.tap(find.byTooltip('Ouvir frente devagar'));
    await settle(tester);
    expect(speaker.spoken.last, (text: '**house**', lang: 'en-US', slow: true));

    await tester.tap(find.byTooltip('Ouvir verso devagar'));
    await settle(tester);
    expect(speaker.spoken.last, (text: 'casa', lang: 'pt-BR', slow: true));

    await tester.tap(find.byTooltip('Ouvir frente'));
    await settle(tester);
    expect(speaker.spoken.last, (
      text: '**house**',
      lang: 'en-US',
      slow: false,
    ));
  });

  testWidgets('sem configurar nada, o botão lê no idioma do app', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    await pumpApp(
      tester,
      overrides: [cardSpeakerProvider.overrideWithValue(speaker)],
      seed: (db) => CardsRepository(
        db.cardsDao,
      ).createCard(front: 'mesa', back: 'table', now: now),
    );
    await goToReview(tester);
    await tester.tap(find.text('Revisar tudo'));
    await settle(tester);

    expect(speaker.spoken, isEmpty); // sem leitura automática
    await tester.tap(find.byTooltip('Ouvir frente'));
    await settle(tester);
    expect(speaker.spoken, [(text: 'mesa', lang: 'pt-BR', slow: false)]);
  });

  testWidgets('deck sai da voz padrão e escolhe o idioma pela aba Revisar', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    final db = await pumpApp(
      tester,
      overrides: [cardSpeakerProvider.overrideWithValue(speaker)],
      seed: (db) => CardsRepository(db.cardsDao).createDeck(name: 'Inglês'),
    );
    await goToReview(tester);
    await tester.tap(find.byTooltip('Voz do deck'));
    await settle(tester);

    await tester.tap(find.text('Usar a voz padrão'));
    await settle(tester);
    await tester.tap(find.text('pt-BR').first);
    await settle(tester);
    await tester.tap(find.text('en-US').last);
    await settle(tester);

    final deck = (await tester.runAsync(
      () => CardsRepository(db.cardsDao).watchDecks().first,
    ))!.single;
    final raw = await tester.runAsync(
      () => SettingsRepository(
        db.settingsDao,
      ).getString(DeckSpeech.keyFor(deck.id)),
    );
    expect(
      DeckSpeech.parse(raw),
      const DeckSpeech(front: 'en-US', back: 'pt-BR'),
    );
  });
}
