import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../data/providers.dart';
import 'card_speech.dart';

/// Voz do celular para ler os cards. Trocada por um falso nos testes.
abstract class CardSpeaker {
  Future<void> speak(String text, String lang);
  Future<void> stop();

  /// Idiomas que o motor de texto para fala do aparelho oferece.
  Future<List<String>> languages();
}

/// TTS do próprio aparelho (`flutter_tts`). Erros do motor (sem voz
/// instalada, plugin ausente) são engolidos: ler é um extra, nunca trava a
/// revisão.
class DeviceSpeaker implements CardSpeaker {
  FlutterTts? _tts;
  FlutterTts get _engine => _tts ??= FlutterTts();

  @override
  Future<void> speak(String text, String lang) async {
    final clean = speechText(text);
    if (clean.isEmpty) return;
    try {
      await _engine.stop();
      await _engine.setLanguage(lang);
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
}

final cardSpeakerProvider = Provider<CardSpeaker>((ref) {
  final speaker = DeviceSpeaker();
  ref.onDispose(speaker.stop);
  return speaker;
});

final _speechRawProvider = StreamProvider.autoDispose.family<String?, String>(
  (ref, key) => ref.watch(settingsRepositoryProvider).watchString(key),
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

final _voiceLanguagesProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.watch(cardSpeakerProvider).languages(),
);

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
    final languages = ref.watch(_voiceLanguagesProvider);
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

    final codes = sortVoiceLanguages([
      ...?languages.value,
      // O já escolhido aparece mesmo se o aparelho não listar.
      ?s.front,
      ?s.back,
    ], first: context.lang);

    Future<void> save(DeckSpeech next) =>
        ref.read(settingsRepositoryProvider).setString(key, next.encode());

    Widget picker(String label, String? value, ValueChanged<String?> onPick) =>
        Padding(
          padding: EdgeInsets.only(top: space.md),
          child: DropdownButtonFormField<String?>(
            key: ValueKey('$label:$value:$editable'),
            initialValue: value,
            decoration: InputDecoration(labelText: label),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.deckSpeechOff)),
              for (final c in codes) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: editable ? onPick : null,
          ),
        );

    return SafeArea(
      child: Padding(
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
              picker(
                l10n.deckSpeechFront,
                s.front,
                (v) => save(s.copyWith(front: () => v)),
              ),
              picker(
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

/// Botão de alto-falante que lê [text] no idioma [lang].
class SpeakButton extends ConsumerWidget {
  const SpeakButton({
    required this.text,
    required this.lang,
    required this.tooltip,
    super.key,
  });

  final String text;
  final String lang;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: tooltip,
    icon: const Icon(AppIcons.speak),
    onPressed: () => ref.read(cardSpeakerProvider).speak(text, lang),
  );
}
