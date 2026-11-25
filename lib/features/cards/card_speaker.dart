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

/// Ajuste de leitura do deck (`null` = cards sem deck).
final deckSpeechProvider = StreamProvider.autoDispose
    .family<DeckSpeech, String?>(
      (ref, deckId) => ref
          .watch(settingsRepositoryProvider)
          .watchString(DeckSpeech.keyFor(deckId))
          .map(DeckSpeech.parse),
    );

final _voiceLanguagesProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.watch(cardSpeakerProvider).languages(),
);

/// Folha "Leitura em voz alta" do deck: idioma da frente, do verso e
/// leitura automática.
Future<void> showDeckSpeechSheet(BuildContext context, String? deckId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DeckSpeechSheet(deckId: deckId),
    );

class _DeckSpeechSheet extends ConsumerWidget {
  const _DeckSpeechSheet({required this.deckId});

  final String? deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final space = context.space;
    final speech = ref.watch(deckSpeechProvider(deckId)).value;
    final languages = ref.watch(_voiceLanguagesProvider);
    final codes = sortVoiceLanguages([
      ...?languages.value,
      // O já escolhido aparece mesmo se o aparelho não listar.
      ?speech?.front,
      ?speech?.back,
    ], first: context.lang);

    Future<void> save(DeckSpeech next) => ref
        .read(settingsRepositoryProvider)
        .setString(DeckSpeech.keyFor(deckId), next.encode());

    Widget picker(String label, String? value, ValueChanged<String?> onPick) =>
        Padding(
          padding: EdgeInsets.only(top: space.md),
          child: DropdownButtonFormField<String?>(
            initialValue: value,
            decoration: InputDecoration(labelText: label),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.deckSpeechOff)),
              for (final c in codes) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: onPick,
          ),
        );

    final s = speech ?? DeckSpeech.off;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(space.page, 0, space.page, space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deckSpeech, style: context.text.titleMedium),
            SizedBox(height: space.xs),
            Text(
              l10n.deckSpeechHint,
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
            if (speech != null) ...[
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
                onChanged: s.enabled ? (v) => save(s.copyWith(auto: v)) : null,
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
