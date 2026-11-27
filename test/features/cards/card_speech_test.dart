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

    test('deck usa o próprio, senão o padrão, senão o idioma do app', () {
      expect(
        DeckSpeech.resolve(
          deckRaw: 'en-US|-|1',
          defaultRaw: 'es-ES|es-ES|0',
          appLang: 'pt',
        ),
        const DeckSpeech(front: 'en-US', auto: true),
      );
      expect(
        DeckSpeech.resolve(
          deckRaw: '',
          defaultRaw: 'es-ES|es-ES|0',
          appLang: 'pt',
        ),
        const DeckSpeech(front: 'es-ES', back: 'es-ES'),
      );
      expect(
        DeckSpeech.resolve(deckRaw: null, defaultRaw: null, appLang: 'pt'),
        const DeckSpeech(front: 'pt-BR', back: 'pt-BR'),
      );
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

  test('filtra vozes por idioma e formata nome de motores Android', () {
    const voices = <TtsVoice>[
      (name: 'en-us-neural-b', locale: 'en_US'),
      (name: 'en-us-neural-a', locale: 'en-US'),
      (name: 'en-gb-a', locale: 'en-GB'),
      (name: 'pt-br-a', locale: 'pt-BR'),
    ];
    expect(voicesForLanguage(voices, 'en-US').map((v) => v.name), [
      'en-us-neural-a',
      'en-us-neural-b',
    ]);
    // Sem exato, cai no prefixo do idioma.
    expect(voicesForLanguage(voices, 'en-AU').map((v) => v.name), [
      'en-gb-a',
      'en-us-neural-a',
      'en-us-neural-b',
    ]);
    expect(friendlyEngineName('com.google.android.tts'), 'Google TTS');
    expect(
      friendlyEngineName('es.codefactory.vocalizertts'),
      'Vocalizer (es.codefactory.vocalizertts)',
    );
  });
}
