import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/file_access.dart';
import 'card_form_sheet.dart';
import 'card_import.dart';
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

/// Exporta [cards] no formato `frente;verso`, permitindo copiar o texto ou
/// salvar como arquivo `.csv`.
Future<void> exportCsvFlow(
  BuildContext context,
  WidgetRef ref,
  List<Flashcard> cards, {
  required String deckName,
}) async {
  if (cards.isEmpty) return;
  final csv = exportCardsCsv([
    for (final c in cards) (front: c.front, back: c.back),
  ]);
  final saver = ref.read(fileSaverProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final slug = deckName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  final fileName = '${slug.isEmpty ? 'cards' : slug}.csv';

  await showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final space = sheetContext.space;
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(space.lg, 0, space.lg, space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.cardsExportCsv, style: sheetContext.text.titleMedium),
              SizedBox(height: space.xs),
              Text(
                l10n.cardsExportSubtitle(cards.length),
                style: sheetContext.text.bodySmall!.copyWith(
                  color: sheetContext.colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: space.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Container(
                  padding: EdgeInsets.all(space.md),
                  decoration: BoxDecoration(
                    color: sheetContext.colors.surfaceContainerHighest,
                    borderRadius: sheetContext.radius.mdAll,
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(csv, style: sheetContext.type.code),
                  ),
                ),
              ),
              SizedBox(height: space.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        AppIcons.export,
                        size: AppIconSize.standard,
                      ),
                      label: Text(l10n.cardsExportSaveFile),
                      onPressed: () async {
                        final saved = await saver(
                          fileName,
                          Uint8List.fromList(utf8.encode(csv)),
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        if (saved) {
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(l10n.cardsCsvSaved)),
                            );
                        }
                      },
                    ),
                  ),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(
                        AppIcons.copy,
                        size: AppIconSize.standard,
                      ),
                      label: Text(l10n.cardsExportCopy),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: csv));
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l10n.cardsCsvCopied)),
                          );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
