import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
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
  final l10n = messenger.context.l10n;
  await repo.deleteCard(card.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.cardDeleted),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => repo.restoreCard(card.id),
        ),
      ),
    );
}

/// Escolhe um CSV (`frente;verso`), mostra quantos cards achou e importa
/// para o deck escolhido.
Future<void> importCsvFlow(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final text = await ref.read(csvPickerProvider)();
  if (text == null || !context.mounted) return;
  final parsed = parseCardsCsv(text);
  if (parsed.cards.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.cardsNoneInFile)));
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
  messenger.showSnackBar(SnackBar(content: Text(l10n.cardsImported(count))));
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
      title: Text(context.l10n.cardsImportTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.cardsFound(found)),
          if (skipped.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.cardsSkippedLines(skipped.join(', ')),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _deckId,
            decoration: InputDecoration(labelText: context.l10n.fieldDeck),
            items: [
              DropdownMenuItem(value: null, child: Text(context.l10n.deckNone)),
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
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((deckId: _deckId)),
          child: Text(context.l10n.actionImport),
        ),
      ],
    );
  }
}
