import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../data/providers.dart';
import 'card_speech.dart';

/// Velocidades do `flutter_tts`: no Android e no iOS, `0.5` equivale a 1×.
const double normalSpeechRate = 0.5;
const double slowSpeechRate = 0.3;

/// Voz do celular para ler os cards. Trocada por um falso nos testes.
abstract class CardSpeaker {
  Future<void> speak(
    String text,
    String lang, {
    bool slow = false,
    String? engine,
    TtsVoice? voice,
  });
  Future<void> stop();

  /// Idiomas que o motor de texto para fala atual oferece.
  Future<List<String>> languages();

  /// Motores TTS instalados no aparelho (Android; vazio em outras plataformas).
  Future<List<String>> engines();

  /// Vozes específicas oferecidas pelo motor TTS atual.
  Future<List<TtsVoice>> voices();

  /// Troca o motor TTS ativo (`null` = volta ao padrão do aparelho).
  Future<void> setEngine(String? engine);
}

/// TTS do próprio aparelho (`flutter_tts`). Erros do motor (sem voz
/// instalada, plugin ausente) são engolidos: ler é um extra, nunca trava a
/// revisão.
class DeviceSpeaker implements CardSpeaker {
  FlutterTts? _tts;
  FlutterTts get _engine => _tts ??= FlutterTts();
  String? _activeEngine;
  bool _hasCustomVoice = false;

  @override
  Future<void> setEngine(String? engine) async {
    final target = (engine == null || engine.trim().isEmpty)
        ? null
        : engine.trim();
    if (target == _activeEngine) return;
    try {
      if (target == null) {
        final def = await _engine.getDefaultEngine;
        if (def is String && def.isNotEmpty) {
          await _engine.setEngine(def);
        }
      } else {
        await _engine.setEngine(target);
      }
      _activeEngine = target;
      _hasCustomVoice = false;
    } on Object {
      // Motor indisponível nesta plataforma ou desinstalado.
    }
  }

  @override
  Future<void> speak(
    String text,
    String lang, {
    bool slow = false,
    String? engine,
    TtsVoice? voice,
  }) async {
    final clean = speechText(text);
    if (clean.isEmpty) return;
    try {
      await setEngine(engine);
      await _engine.stop();
      await _engine.setLanguage(lang);
      if (voice != null) {
        await _engine.setVoice({'name': voice.name, 'locale': voice.locale});
        _hasCustomVoice = true;
      } else if (_hasCustomVoice) {
        try {
          await _engine.clearVoice();
        } on Object {
          // Alguns motores não implementam clearVoice.
        }
        _hasCustomVoice = false;
      }
      await _engine.setSpeechRate(slow ? slowSpeechRate : normalSpeechRate);
      await _engine.speak(clean);
    } on Object {
      // Sem motor ou sem a voz: fica em silêncio.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } on Object {
      // nada a parar
    }
  }

  @override
  Future<List<String>> languages() async {
    try {
      final raw = await _engine.getLanguages;
      if (raw is List) return [for (final l in raw) '$l'];
    } on Object {
      // sem motor
    }
    return const [];
  }

  @override
  Future<List<String>> engines() async {
    try {
      final raw = await _engine.getEngines;
      if (raw is List) {
        final list = {
          for (final e in raw)
            if ('$e'.trim().isNotEmpty) '$e'.trim(),
        }.toList()..sort();
        return list;
      }
    } on Object {
      // sem suporte a seleção de motor nesta plataforma
    }
    return const [];
  }

  @override
  Future<List<TtsVoice>> voices() async {
    try {
      final raw = await _engine.getVoices;
      if (raw is List) {
        final result = <TtsVoice>[];
        for (final item in raw) {
          if (item is Map) {
            final name = '${item['name'] ?? ''}'.trim();
            final locale = '${item['locale'] ?? ''}'.trim();
            if (name.isNotEmpty && locale.isNotEmpty) {
              result.add((name: name, locale: locale));
            }
          }
        }
        return result;
      }
    } on Object {
      // sem suporte a vozes específicas
    }
    return const [];
  }
}

final cardSpeakerProvider = Provider<CardSpeaker>((ref) {
  final speaker = DeviceSpeaker();
  ref.onDispose(speaker.stop);
  return speaker;
});

final _speechRawProvider = StreamProvider.autoDispose.family<String?, String>(
  (ref, key) => ref.watch(settingsRepositoryProvider).watchString(key),
);

/// Motor TTS escolhido neste aparelho (`null` = padrão do Android).
final deviceTtsEngineProvider = StreamProvider.autoDispose<String?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchString(ttsEngineSettingKey)
      .map((v) => v == null || v.isEmpty ? null : v),
);

/// Nome da voz específica escolhida neste aparelho para [lang] (`null` = padrão).
final deviceTtsVoiceProvider = StreamProvider.autoDispose
    .family<String?, String>(
      (ref, lang) => ref
          .watch(settingsRepositoryProvider)
          .watchString(ttsVoiceSettingKey(lang))
          .map((v) => v == null || v.isEmpty ? null : v),
    );

/// Ajustes guardados de um deck (`null` = cards sem deck) e da voz padrão;
/// `null` enquanto carregam. Resolver com [DeckSpeech.resolve] e o idioma do
/// app (ver [effectiveSpeech]).
final deckSpeechProvider = Provider.autoDispose
    .family<({String? deck, String? fallback})?, String?>((ref, deckId) {
      final deck = ref.watch(_speechRawProvider(DeckSpeech.keyFor(deckId)));
      final def = ref.watch(_speechRawProvider(DeckSpeech.defaultKey));
      if (!deck.hasValue || !def.hasValue) return null;
      return (deck: deck.value, fallback: def.value);
    });

/// Leitura que vale para o deck agora (o dele, a padrão ou o idioma do app).
DeckSpeech? effectiveSpeech(WidgetRef ref, String? deckId, String appLang) {
  final raw = ref.watch(deckSpeechProvider(deckId));
  if (raw == null) return null;
  return DeckSpeech.resolve(
    deckRaw: raw.deck,
    defaultRaw: raw.fallback,
    appLang: appLang,
  );
}

final _ttsEnginesProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.watch(cardSpeakerProvider).engines(),
);

final _voiceLanguagesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final speaker = ref.watch(cardSpeakerProvider);
  final engine = ref.watch(deviceTtsEngineProvider).value;
  await speaker.setEngine(engine);
  return speaker.languages();
});

final _ttsVoicesProvider = FutureProvider.autoDispose<List<TtsVoice>>((
  ref,
) async {
  final speaker = ref.watch(cardSpeakerProvider);
  final engine = ref.watch(deviceTtsEngineProvider).value;
  await speaker.setEngine(engine);
  return speaker.voices();
});

/// Lê [text] em [lang] aplicando o motor TTS e a voz específica escolhidos
/// neste aparelho (quando houver).
Future<void> speakCardText(
  WidgetRef ref,
  String text,
  String lang, {
  bool slow = false,
}) async {
  final speaker = ref.read(cardSpeakerProvider);
  final settings = ref.read(settingsRepositoryProvider);
  final rawEngine =
      ref.read(deviceTtsEngineProvider).value ??
      await settings.getString(ttsEngineSettingKey);
  final engine = rawEngine == null || rawEngine.isEmpty ? null : rawEngine;
  final rawVoice =
      ref.read(deviceTtsVoiceProvider(lang)).value ??
      await settings.getString(ttsVoiceSettingKey(lang));
  final voiceName = rawVoice == null || rawVoice.isEmpty ? null : rawVoice;
  TtsVoice? voice;
  if (voiceName != null) {
    final loaded = ref.read(_ttsVoicesProvider).value;
    voice =
        loaded?.where((v) => v.name == voiceName).firstOrNull ??
        (name: voiceName, locale: lang);
  }
  await speaker.speak(text, lang, slow: slow, engine: engine, voice: voice);
}

/// Folha "Leitura em voz alta" de um deck ([deckId]; `null` = cards sem
/// deck).
Future<void> showDeckSpeechSheet(BuildContext context, String? deckId) =>
    _showSpeechSheet(context, deckId: deckId, isDefault: false);

/// Folha da voz padrão (vale para os decks sem ajuste próprio).
Future<void> showDefaultSpeechSheet(BuildContext context) =>
    _showSpeechSheet(context, deckId: null, isDefault: true);

Future<void> _showSpeechSheet(
  BuildContext context, {
  required String? deckId,
  required bool isDefault,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _SpeechSheet(deckId: deckId, isDefault: isDefault),
);

class _SpeechSheet extends ConsumerWidget {
  const _SpeechSheet({required this.deckId, required this.isDefault});

  final String? deckId;
  final bool isDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final space = context.space;
    final key = isDefault ? DeckSpeech.defaultKey : DeckSpeech.keyFor(deckId);
    final own = ref.watch(_speechRawProvider(key));
    final defRaw = ref.watch(_speechRawProvider(DeckSpeech.defaultKey));
    final enginesAsync = ref.watch(_ttsEnginesProvider);
    final selectedEngine = ref.watch(deviceTtsEngineProvider).value;
    final languages = ref.watch(_voiceLanguagesProvider);
    final allVoices = ref.watch(_ttsVoicesProvider).value ?? const <TtsVoice>[];
    final loaded = own.hasValue && defRaw.hasValue;

    final def = DeckSpeech.resolve(
      deckRaw: null,
      defaultRaw: defRaw.value,
      appLang: context.lang,
    );
    final ownRaw = own.value;
    final usesDefault = !isDefault && (ownRaw == null || ownRaw.isEmpty);
    final s = isDefault || usesDefault ? def : DeckSpeech.parse(ownRaw);
    final editable = !usesDefault;

    final engineList = <String>{
      ...?enginesAsync.value,
      ?selectedEngine,
    }.toList()..sort();

    final codes = sortVoiceLanguages([
      ...?languages.value,
      // O já escolhido aparece mesmo se o aparelho não listar.
      ?s.front,
      ?s.back,
    ], first: context.lang);

    Future<void> save(DeckSpeech next) =>
        ref.read(settingsRepositoryProvider).setString(key, next.encode());

    Future<void> setEngine(String? engine) async {
      final settings = ref.read(settingsRepositoryProvider);
      await settings.setString(ttsEngineSettingKey, engine ?? '');
      ref.invalidate(_voiceLanguagesProvider);
      ref.invalidate(_ttsVoicesProvider);
    }

    Widget voicePickerFor(String lang) {
      final matches = voicesForLanguage(allVoices, lang);
      final savedName = ref.watch(deviceTtsVoiceProvider(lang)).value;
      if (matches.isEmpty && savedName == null) return const SizedBox.shrink();
      final names = [
        for (final v in matches) v.name,
        if (savedName != null && !matches.any((v) => v.name == savedName))
          savedName,
      ];
      return Padding(
        padding: EdgeInsets.only(top: space.sm),
        child: DropdownButtonFormField<String?>(
          key: ValueKey('voice:$lang:$savedName:${names.length}'),
          initialValue: savedName,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.speechVoiceSpecific),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                l10n.speechVoiceDefault,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            for (final name in names)
              DropdownMenuItem(
                value: name,
                child: Text(name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => ref
              .read(settingsRepositoryProvider)
              .setString(ttsVoiceSettingKey(lang), v ?? ''),
        ),
      );
    }

    Widget sidePicker(
      String label,
      String? value,
      ValueChanged<String?> onPick,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: space.md),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('$label:$value:$editable'),
                  initialValue: value,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: label),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.deckSpeechOff),
                    ),
                    for (final c in codes)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: editable ? onPick : null,
                ),
              ),
              if (value != null)
                IconButton(
                  tooltip: l10n.speechTestVoice,
                  icon: const Icon(AppIcons.speak),
                  onPressed: () =>
                      speakCardText(ref, l10n.speechTestSample, value),
                ),
            ],
          ),
        ),
        if (value != null) voicePickerFor(value),
      ],
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(space.page, 0, space.page, space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isDefault ? l10n.speechDefault : l10n.deckSpeech,
              style: context.text.titleMedium,
            ),
            SizedBox(height: space.xs),
            Text(
              isDefault
                  ? '${l10n.deckSpeechHint} ${l10n.speechDefaultHint}'
                  : l10n.deckSpeechHint,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (engineList.isNotEmpty) ...[
              SizedBox(height: space.md),
              DropdownButtonFormField<String?>(
                key: ValueKey('engine:$selectedEngine'),
                initialValue: selectedEngine,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.speechEngineLabel,
                  helperText: l10n.speechEngineHint,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      l10n.speechEngineDefault,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final e in engineList)
                    DropdownMenuItem(
                      value: e,
                      child: Text(
                        friendlyEngineName(e),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: setEngine,
              ),
            ],
            if (languages.hasValue && languages.value!.isEmpty) ...[
              SizedBox(height: space.sm),
              Text(
                l10n.deckSpeechNoVoices,
                style: context.text.bodySmall!.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            if (loaded) ...[
              if (!isDefault)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.speechUseDefault),
                  value: usesDefault,
                  onChanged: (on) => ref
                      .read(settingsRepositoryProvider)
                      .setString(key, on ? '' : def.encode()),
                ),
              sidePicker(
                l10n.deckSpeechFront,
                s.front,
                (v) => save(s.copyWith(front: () => v)),
              ),
              sidePicker(
                l10n.deckSpeechBack,
                s.back,
                (v) => save(s.copyWith(back: () => v)),
              ),
              SizedBox(height: space.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.deckSpeechAuto),
                value: s.auto,
                onChanged: editable && s.enabled
                    ? (v) => save(s.copyWith(auto: v))
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botões que leem [text] no idioma [lang]: normal (alto-falante) e devagar
/// (tartaruga).
class SpeakButton extends ConsumerWidget {
  const SpeakButton({
    required this.text,
    required this.lang,
    required this.tooltip,
    required this.slowTooltip,
    super.key,
  });

  final String text;
  final String lang;
  final String tooltip;
  final String slowTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: tooltip,
        icon: const Icon(AppIcons.speak),
        onPressed: () => speakCardText(ref, text, lang),
      ),
      IconButton(
        tooltip: slowTooltip,
        icon: const Icon(AppIcons.speakSlow),
        onPressed: () => speakCardText(ref, text, lang, slow: true),
      ),
    ],
  );
}
