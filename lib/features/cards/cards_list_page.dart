import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/gradient_fab.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/text_input_dialog.dart';
import '../tasks/task_providers.dart';
import 'card_actions.dart';
import 'card_form_sheet.dart';
import 'card_speaker.dart';
import 'cards_providers.dart';
import 'review_queue.dart';

/// Cards de um deck ([deckId]) ou todos, com busca, filtro, importar/exportar,
/// editar, suspender e excluir.
class CardsListPage extends ConsumerStatefulWidget {
  const CardsListPage({this.deckId, super.key});

  final String? deckId;

  @override
  ConsumerState<CardsListPage> createState() => _CardsListPageState();
}

class _CardsListPageState extends ConsumerState<CardsListPage> {
  bool _searching = false;
  final _query = TextEditingController();
  CardListFilter _filter = CardListFilter.all;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _renameDeck(BuildContext context, Deck deck) async {
    final repo = ref.read(cardsRepositoryProvider);
    final name = await showTextInputDialog(
      context,
      title: context.l10n.deckRename,
      label: context.l10n.reviewNameLabel,
      confirmLabel: context.l10n.actionSave,
      initialValue: deck.name,
    );
    if (name != null) {
      await repo.saveDeck(deck.copyWith(name: name));
    }
  }

  Future<void> _deleteDeck(BuildContext context, Deck deck) async {
    // Lido antes: a tela sai da pilha antes de excluir.
    final cards = ref.read(cardsRepositoryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deckDeleteTitle(deck.name)),
        content: Text(context.l10n.deckDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    await cards.deleteDeck(deck.id);
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _query.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deckId = widget.deckId;
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    final title = deck?.name ?? l10n.reviewAllCards;
    final scope = (deckId: deckId, taskId: null);
    final cards = ref.watch(scopeCardsProvider(scope));
    final allInDeck = cards.value ?? const <Flashcard>[];
    final due = ref.watch(reviewQueueProvider(scope)).value?.length ?? 0;
    final today = ref.watch(todayProvider);
    final now = ref.watch(reviewNowProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.cardsSearchHint,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(title),
        actions: [
          if (_searching)
            IconButton(
              tooltip: l10n.searchClear,
              icon: const Icon(AppIcons.close),
              onPressed: _toggleSearch,
            )
          else ...[
            if (allInDeck.isNotEmpty)
              IconButton(
                tooltip: l10n.cardsSearchHint,
                icon: const Icon(AppIcons.search),
                onPressed: _toggleSearch,
              ),
            IconButton(
              tooltip: l10n.reviewImportCsv,
              icon: const Icon(AppIcons.import),
              onPressed: () => importCsvFlow(context, ref, deckId: deckId),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.deckOptions,
              onSelected: (v) => switch (v) {
                'csv' => importCsvFlow(context, ref, deckId: deckId),
                'export' => exportCsvFlow(
                  context,
                  ref,
                  allInDeck,
                  deckName: title,
                ),
                'voz' => showDeckSpeechSheet(context, deckId),
                'renomear' => _renameDeck(context, deck!),
                _ => _deleteDeck(context, deck!),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'csv', child: Text(l10n.reviewImportCsv)),
                if (allInDeck.isNotEmpty)
                  PopupMenuItem(
                    value: 'export',
                    child: Text(l10n.cardsExportCsv),
                  ),
                PopupMenuItem(value: 'voz', child: Text(l10n.deckSpeech)),
                if (deck != null) ...[
                  PopupMenuItem(
                    value: 'renomear',
                    child: Text(l10n.actionRename),
                  ),
                  PopupMenuItem(value: 'excluir', child: Text(l10n.deckDelete)),
                ],
              ],
            ),
          ],
        ],
      ),
      floatingActionButton: GradientFab(
        tooltip: l10n.reviewNewCard,
        onPressed: () => createCardFlow(context, ref, deckId: deckId),
        child: const Icon(AppIcons.add),
      ),
      body: cards.when(
        loading: () => const SkeletonList(),
        error: (_, _) =>
            EmptyState(icon: AppIcons.error, message: l10n.reviewLoadError),
        data: (cards) {
          if (cards.isEmpty) {
            return EmptyState(
              icon: AppIcons.flashcard,
              message: l10n.cardsEmptyHere,
              action: Wrap(
                spacing: context.space.sm,
                runSpacing: context.space.sm,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: () =>
                        createCardFlow(context, ref, deckId: deckId),
                    child: Text(l10n.cardCreate),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(
                      AppIcons.import,
                      size: AppIconSize.standard,
                    ),
                    label: Text(l10n.reviewImportCsv),
                    onPressed: () =>
                        importCsvFlow(context, ref, deckId: deckId),
                  ),
                ],
              ),
            );
          }

          final filtered = filterDeckCards(
            cards,
            now: now,
            query: _query.text,
            filter: _filter,
          );
          final space = context.space;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (due > 0 && !_searching && _filter == CardListFilter.all)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    space.lg,
                    space.md,
                    space.lg,
                    space.xs,
                  ),
                  child: FilledButton.tonalIcon(
                    icon: const Icon(AppIcons.play),
                    label: Text(l10n.cardsReviewCount(due)),
                    onPressed: () =>
                        context.push(Routes.reviewSession(deckId: deckId)),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: space.lg,
                  vertical: space.xs,
                ),
                child: Row(
                  children: [
                    for (final entry in [
                      (CardListFilter.all, l10n.cardsFilterAll),
                      (CardListFilter.due, l10n.cardsFilterDue),
                      (CardListFilter.newCards, l10n.cardsFilterNew),
                      (CardListFilter.suspended, l10n.cardsFilterSuspended),
                    ])
                      Padding(
                        padding: EdgeInsets.only(right: space.sm),
                        child: ChoiceChip(
                          label: Text(entry.$2),
                          selected: _filter == entry.$1,
                          onSelected: (_) => setState(() => _filter = entry.$1),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: AppIcons.searchEmpty,
                        message: l10n.searchNoResults,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _CardTile(card: filtered[index], today: today),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card, required this.today});

  final Flashcard card;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final status = card.suspended
        ? context.l10n.cardSuspended
        : isNewCard(card)
        ? context.l10n.cardNew
        : context.l10n.cardNextReview(
            formatRelative(
              card.due,
              today,
              withTime: card.due.difference(today).inDays < 2,
              lang: context.lang,
            ),
          );
    return ListTile(
      title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        status,
        style: TextStyle(color: card.suspended ? colors.outline : null),
      ),
      onTap: () => editCardFlow(context, ref, card),
      trailing: PopupMenuButton<String>(
        tooltip: context.l10n.cardOptions,
        onSelected: (v) => switch (v) {
          'editar' => editCardFlow(context, ref, card),
          'suspender' =>
            ref
                .read(cardsRepositoryProvider)
                .saveCard(card.copyWith(suspended: !card.suspended)),
          'excluir' => deleteCardWithUndo(
            ScaffoldMessenger.of(context),
            ref,
            card,
          ),
          _ => null,
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'editar', child: Text(context.l10n.actionEdit)),
          PopupMenuItem(
            value: 'suspender',
            child: Text(
              card.suspended
                  ? context.l10n.cardReactivate
                  : context.l10n.cardSuspend,
            ),
          ),
          PopupMenuItem(
            value: 'excluir',
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
  }
}
