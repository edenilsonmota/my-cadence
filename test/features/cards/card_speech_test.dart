import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/features/cards/card_speech.dart';

void main() {
  group('DeckSpeech', () {
    test('ida e volta do formato guardado', () {
      const s = DeckSpeech(front: 'en-US', back: 'pt-BR', auto: true);
      expect(s.encode(), 'en-US|pt-BR|1');
      expect(DeckSpeech.parse(s.encode()), s);
    });

    test('lado desligado e valor ausente', () {
      expect(DeckSpeech.parse('-|pt-BR|0'), const DeckSpeech(back: 'pt-BR'));
      expect(DeckSpeech.parse(null), DeckSpeech.off);
      expect(DeckSpeech.off.enabled, isFalse);
    });

    test('chave por deck e para cards sem deck', () {
      expect(DeckSpeech.keyFor('d1'), 'cards.tts.d1');
      expect(DeckSpeech.keyFor(null), 'cards.tts.semDeck');
    });
  });

  test('texto falado sem marcas de Markdown', () {
    expect(
      speechText('# Título\n- **casa** é _house_\n1. `code`'),
      'Título. casa é house. code',
    );
    expect(speechText('snake_case fica'), 'snake_case fica');
  });

  test('idiomas: o do app primeiro, sem repetir', () {
    expect(
      sortVoiceLanguages(['pt_BR', 'en-US', 'pt-PT', 'en-US'], first: 'pt'),
      ['pt-BR', 'pt-PT', 'en-US'],
    );
  });
}
