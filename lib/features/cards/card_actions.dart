import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import 'card_form_sheet.dart';
import 'card_import_sheet.dart';

export 'card_import_sheet.dart' show csvPickerProvider;

Future<void> createCardFlow(
  BuildContext context,
  WidgetRef ref, {
  String? deckId,
  String? taskId,
}) async {
  // Lidos antes do await: quem chamou pode sair da árvore enquanto o teclado
  // está aberto.
  final cards = ref.read(cardsRepositoryProvider);
  final clock = ref.read(clockProvider);
  final result = await showCardForm(context, deckId: deckId, taskId: taskId);
  if (result == null) return;
  await cards.createCard(
    front: result.front,
    back: result.back,
    now: clock(),
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

/// Abre a importação CSV (texto colado/editado ou arquivo `.csv`/`.txt`) e
/// acrescenta os cards no deck escolhido (com [deckId] pré-selecionado, se
/// informado).
Future<void> importCsvFlow(
  BuildContext context,
  WidgetRef ref, {
  String? deckId,
}) async {
  // Lidos antes do await: o teclado pode desmontar quem chamou.
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final cards = ref.read(cardsRepositoryProvider);
  final clock = ref.read(clockProvider);
  final result = await showCardImportSheet(context, initialDeckId: deckId);
  if (result == null || result.cards.isEmpty) return;
  final count = await cards.importCards(
    result.cards,
    now: clock(),
    deckId: result.deckId,
  );
  final message = result.skippedDuplicates > 0
      ? '${l10n.cardsImported(count)} '
            '${l10n.cardsDuplicatesSkipped(result.skippedDuplicates)}'
      : l10n.cardsImported(count);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
