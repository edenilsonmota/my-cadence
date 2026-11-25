/// Leitura em voz alta dos cards (TTS do próprio celular): ajuste por deck e
/// limpeza do texto. Puro, sem Flutter.
library;

/// Ajuste de leitura de um deck: idioma da voz da frente e do verso
/// (`null` = não ler aquele lado) e se lê sozinho na revisão.
class DeckSpeech {
  const DeckSpeech({this.front, this.back, this.auto = false});

  static const off = DeckSpeech();

  /// Código do idioma da voz (ex.: `en-US`), como o celular informa.
  final String? front;
  final String? back;

  /// Lê a frente ao mostrar o card e o verso ao mostrar a resposta.
  final bool auto;

  bool get enabled => front != null || back != null;

  /// Chave em `AppSettings` (prefixo `cards.`, sincroniza). Cards sem deck
  /// usam uma chave própria.
  static String keyFor(String? deckId) => 'cards.tts.${deckId ?? 'semDeck'}';

  /// Voz padrão, usada pelos decks sem ajuste próprio.
  static const defaultKey = 'cards.tts.padrao';

  /// Sem nada configurado: lê os dois lados no idioma do app, só pelo botão.
  static DeckSpeech fallback(String appLang) {
    final voice = switch (appLang) {
      'en' => 'en-US',
      'es' => 'es-ES',
      _ => 'pt-BR',
    };
    return DeckSpeech(front: voice, back: voice);
  }

  /// O que vale para um deck: o ajuste dele, senão a voz padrão, senão
  /// [fallback]. Valor vazio ou ausente = "não definido" (usa o seguinte).
  static DeckSpeech resolve({
    required String? deckRaw,
    required String? defaultRaw,
    required String appLang,
  }) {
    if (deckRaw != null && deckRaw.isNotEmpty) return parse(deckRaw);
    if (defaultRaw != null && defaultRaw.isNotEmpty) return parse(defaultRaw);
    return fallback(appLang);
  }

  /// Formato guardado: `frente|verso|auto` (`-` = lado desligado).
  String encode() => '${front ?? '-'}|${back ?? '-'}|${auto ? 1 : 0}';

  static DeckSpeech parse(String? raw) {
    if (raw == null || raw.isEmpty) return off;
    final parts = raw.split('|');
    String? lang(int i) {
      if (parts.length <= i) return null;
      final v = parts[i].trim();
      return v.isEmpty || v == '-' ? null : v;
    }

    return DeckSpeech(
      front: lang(0),
      back: lang(1),
      auto: parts.length > 2 && parts[2].trim() == '1',
    );
  }

  DeckSpeech copyWith({
    String? Function()? front,
    String? Function()? back,
    bool? auto,
  }) => DeckSpeech(
    front: front == null ? this.front : front(),
    back: back == null ? this.back : back(),
    auto: auto ?? this.auto,
  );

  @override
  bool operator ==(Object other) =>
      other is DeckSpeech &&
      other.front == front &&
      other.back == back &&
      other.auto == auto;

  @override
  int get hashCode => Object.hash(front, back, auto);
}

/// Texto do card sem as marcas de Markdown (negrito, itálico, código,
/// títulos, listas), para a voz não ler "asterisco".
String speechText(String markdown) {
  final lines = [
    for (final raw in markdown.split('\n'))
      raw
          .trim()
          .replaceFirst(RegExp(r'^#{1,6}\s+'), '')
          .replaceFirst(RegExp(r'^([-*+]|\d+[.)])\s+'), '')
          .replaceFirst(RegExp(r'^>\s?'), ''),
  ];
  return lines
      .where((l) => l.isNotEmpty)
      .join('. ')
      .replaceAll(RegExp(r'\*\*|__|`'), '')
      .replaceAllMapped(
        RegExp(r'(^|[\s(])[*_]([^*_]+)[*_](?=$|[\s.,;:!?)])'),
        (m) => '${m[1]}${m[2]}',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Rótulo legível de um código de idioma ("en-US" → "en-US"): o nome vem do
/// próprio código; a lista só ordena com o idioma do app primeiro.
List<String> sortVoiceLanguages(Iterable<String> codes, {String? first}) {
  final unique = {for (final c in codes) c.replaceAll('_', '-')}.toList()
    ..sort();
  if (first == null) return unique;
  final prefix = first.toLowerCase();
  final preferred = [
    for (final c in unique)
      if (c.toLowerCase().startsWith(prefix)) c,
  ];
  return [
    ...preferred,
    for (final c in unique)
      if (!preferred.contains(c)) c,
  ];
}
