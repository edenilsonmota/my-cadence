import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/repositories/cards_repository.dart';
import 'package:my_cadence/data/repositories/settings_repository.dart';
import 'package:my_cadence/features/cards/card_speaker.dart';
import 'package:my_cadence/features/cards/card_speech.dart';

import '../../helpers/pump_app.dart';

final now = DateTime(2026, 11, 23, 12);

class FakeSpeaker implements CardSpeaker {
  final spoken = <(String, String)>[];

  @override
  Future<void> speak(String text, String lang) async =>
      spoken.add((text, lang));

  @override
  Future<void> stop() async {}

  @override
  Future<List<String>> languages() async => ['en-US', 'pt-BR'];
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

    expect(speaker.spoken, [('**house**', 'en-US')]);
    await tester.tap(find.text('Mostrar resposta'));
    await settle(tester);
    expect(speaker.spoken.last, ('casa', 'pt-BR'));

    await tester.tap(find.byTooltip('Ouvir frente'));
    await settle(tester);
    expect(speaker.spoken.last, ('**house**', 'en-US'));
  });

  testWidgets('ajuste do deck grava idiomas pelo menu', (tester) async {
    final speaker = FakeSpeaker();
    final db = await pumpApp(
      tester,
      overrides: [cardSpeakerProvider.overrideWithValue(speaker)],
      seed: (db) => CardsRepository(db.cardsDao).createDeck(name: 'Inglês'),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Revisar'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Inglês'));
    await settle(tester);
    await tester.tap(find.byTooltip('Opções do deck'));
    await settle(tester);
    await tester.tap(find.text('Leitura em voz alta'));
    await settle(tester);

    await tester.tap(find.text('Não ler').first);
    await settle(tester);
    await tester.tap(find.text('en-US').last);
    await settle(tester);

    final deck = (await tester.runAsync(
      () => CardsRepository(db.cardsDao).watchDecks().first,
    ))!.single;
    final raw = await tester.runAsync(
      () =>
          SettingsRepository(db.settingsDao)
              .getString(DeckSpeech.keyFor(deck.id)),
    );
    expect(DeckSpeech.parse(raw).front, 'en-US');
  });
}
