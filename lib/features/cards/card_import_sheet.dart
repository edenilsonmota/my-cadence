import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/text_input_dialog.dart';
import 'card_form_sheet.dart';
import 'card_import.dart';
import 'cards_providers.dart';

typedef CardImportResult = ({
  List<ImportedCard> cards,
  String? deckId,
  int skippedDuplicates,
});

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

/// Folha para importar cards em lote colando/editando `frente;verso` ou
/// carregando um arquivo `.csv`/`.txt`, com destino pré-selecionado opcional.
Future<CardImportResult?> showCardImportSheet(
  BuildContext context, {
  String? initialDeckId,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<CardImportResult>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CardImportSheet(initialDeckId: initialDeckId),
  );
}

class _CardImportSheet extends ConsumerStatefulWidget {
  const _CardImportSheet({this.initialDeckId});

  final String? initialDeckId;

  @override
  ConsumerState<_CardImportSheet> createState() => _CardImportSheetState();
}

class _CardImportSheetState extends ConsumerState<_CardImportSheet> {
  final _text = TextEditingController();
  late String? _deckId = widget.initialDeckId;
  bool _skipDuplicates = true;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _loadFromFile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picker = ref.read(csvPickerProvider);
    final content = await picker();
    if (content == null || !mounted) return;
    setState(() {
      _text.text = content;
      _text.selection = TextSelection.collapsed(offset: content.length);
    });
  }

  Future<void> _createDeck() async {
    FocusManager.instance.primaryFocus?.unfocus();
    // Lido antes do await: o teclado pode desmontar a árvore chamadora.
    final repo = ref.read(cardsRepositoryProvider);
    final name = await showTextInputDialog(
      context,
      title: context.l10n.reviewNewDeck,
      label: context.l10n.reviewNameLabel,
    );
    if (name == null) return;
    final id = await repo.createDeck(name: name);
    if (mounted) setState(() => _deckId = id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = context.space;
    final colors = context.colors;
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final allCards = ref.watch(allCardsProvider).value ?? const <Flashcard>[];
    final selectedDeckId = decks.any((d) => d.id == _deckId) ? _deckId : null;

    final rawText = _text.text;
    final hasText = rawText.trim().isNotEmpty;
    final parsed = parseCardsCsv(rawText);
    final existingFronts = [
      for (final c in allCards)
        if (c.deckId == selectedDeckId) c.front,
    ];
    final filtered = _skipDuplicates
        ? filterDuplicateCards(parsed.cards, existingFronts: existingFronts)
        : (unique: parsed.cards, duplicateCount: 0);
    final effectiveCards = filtered.unique;
    final skippedDuplicates = filtered.duplicateCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        space.lg,
        0,
        space.lg,
        space.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.cardsImportTitle,
                    style: context.text.titleMedium,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(AppIcons.import, size: AppIconSize.standard),
                  label: Text(l10n.cardsImportFromFile),
                  onPressed: _loadFromFile,
                ),
              ],
            ),
            SizedBox(height: space.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(selectedDeckId),
                    initialValue: selectedDeckId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.fieldDeck),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          l10n.deckNone,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      for (final d in decks)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _deckId = v),
                  ),
                ),
                SizedBox(width: space.sm),
                Padding(
                  padding: EdgeInsets.only(top: space.xs),
                  child: IconButton.filledTonal(
                    tooltip: l10n.reviewNewDeck,
                    icon: const Icon(AppIcons.newDeck),
                    onPressed: _createDeck,
                  ),
                ),
              ],
            ),
            SizedBox(height: space.md),
            TextField(
              controller: _text,
              minLines: 5,
              maxLines: 10,
              keyboardType: TextInputType.multiline,
              style: context.type.code,
              decoration: InputDecoration(
                labelText: l10n.cardsImportTextLabel,
                hintText: l10n.cardsImportTextHint,
                helperText: l10n.cardsImportTextHelper,
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (hasText) ...[
              SizedBox(height: space.sm),
              if (effectiveCards.isNotEmpty)
                Text(
                  skippedDuplicates > 0
                      ? '${l10n.cardsFound(effectiveCards.length)} '
                            '${l10n.cardsDuplicatesSkipped(skippedDuplicates)}'
                      : l10n.cardsFound(effectiveCards.length),
                  style: context.text.bodySmall!.copyWith(
                    color: colors.primary,
                  ),
                )
              else if (parsed.cards.isNotEmpty && skippedDuplicates > 0)
                Text(
                  l10n.cardsAllDuplicates(skippedDuplicates),
                  style: context.text.bodySmall!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  l10n.cardsNoneInText,
                  style: context.text.bodySmall!.copyWith(color: colors.error),
                ),
              if (parsed.skippedLines.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: space.xs),
                  child: Text(
                    l10n.cardsSkippedLines(parsed.skippedLines.join(', ')),
                    style: context.text.bodySmall!.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
            ],
            SizedBox(height: space.xs),
            CheckboxListTile(
              value: _skipDuplicates,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text(l10n.cardsSkipDuplicates),
              onChanged: (v) => setState(() => _skipDuplicates = v ?? true),
            ),
            SizedBox(height: space.sm),
            FilledButton(
              onPressed: effectiveCards.isEmpty
                  ? null
                  : () => Navigator.of(context).pop((
                      cards: effectiveCards,
                      deckId: selectedDeckId,
                      skippedDuplicates: skippedDuplicates,
                    )),
              child: Text(
                effectiveCards.isEmpty
                    ? l10n.actionImport
                    : l10n.cardsImportActionCount(effectiveCards.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
