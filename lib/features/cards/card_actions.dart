import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import 'card_form_sheet.dart';
import 'card_import.dart';

/// Abre o seletor de arquivos e devolve o texto do CSV (ou `null`). Os
/// testes trocam por um texto fixo.
final csvPickerProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
    );
    return file?.xFile.readAsString();
  },
);

Future<void> createCardFlow(
  BuildContext context,
  WidgetRef ref, {
  String? deckId,
  String? taskId,
}) async {
  final result = await showCardForm(context, deckId: deckId, taskId: taskId);
  if (result == null) return;
  await ref
      .read(cardsRepositoryProvider)
      .createCard(
        front: result.front,
        back: result.back,
        now: ref.read(clockProvider)(),
        deckId: result.deckId,
        taskId: result.taskId,
      );
}

Future<void> editCardFlow(
  BuildContext context,
  WidgetRef ref,
  Flashcard card,
) async {
  final result = await showCardForm(context, editing: card);
  if (result == null) return;
  await ref
      .read(cardsRepositoryProvider)
      .saveCard(
        card.copyWith(
          front: result.front,
          back: result.back,
          deckId: Value(result.deckId),
          taskId: Value(result.taskId),
        ),
      );
}

Future<void> deleteCardWithUndo(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  Flashcard card,
) async {
  final repo = ref.read(cardsRepositoryProvider);
  await repo.deleteCard(card.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Card excluído'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => repo.restoreCard(card.id),
        ),
      ),
    );
}

/// Escolhe um CSV (`frente;verso`), mostra quantos cards achou e importa
/// para o deck escolhido.
Future<void> importCsvFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final text = await ref.read(csvPickerProvider)();
  if (text == null || !context.mounted) return;
  final parsed = parseCardsCsv(text);
  if (parsed.cards.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nenhum card encontrado no arquivo.')),
    );
    return;
  }
  final deckId = await showDialog<({String? deckId})>(
    context: context,
    builder: (_) => _ImportDialog(parsed: parsed),
  );
  if (deckId == null) return;
  final count = await ref
      .read(cardsRepositoryProvider)
      .importCards(
        parsed.cards,
        now: ref.read(clockProvider)(),
        deckId: deckId.deckId,
      );
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        '$count ${count == 1 ? 'card importado' : 'cards importados'}.',
      ),
    ),
  );
}

class _ImportDialog extends ConsumerStatefulWidget {
  const _ImportDialog({required this.parsed});

  final CsvImport parsed;

  @override
  ConsumerState<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<_ImportDialog> {
  String? _deckId;

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final found = widget.parsed.cards.length;
    final skipped = widget.parsed.skippedLines;
    return AlertDialog(
      title: const Text('Importar cards'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$found ${found == 1 ? 'card encontrado' : 'cards encontrados'}.',
          ),
          if (skipped.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Linhas ignoradas (sem frente ou verso): ${skipped.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _deckId,
            decoration: const InputDecoration(labelText: 'Deck'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sem deck')),
              for (final d in decks)
                DropdownMenuItem(value: d.id, child: Text(d.name)),
            ],
            onChanged: (v) => setState(() => _deckId = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((deckId: _deckId)),
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
