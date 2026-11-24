import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_icons.dart';
import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/text_input_dialog.dart';
import '../tasks/task_providers.dart';
import 'card_actions.dart';
import 'card_form_sheet.dart';
import 'cards_providers.dart';
import 'review_queue.dart';

/// Cards de um deck ([deckId]) ou todos, com editar, suspender e excluir.
class CardsListPage extends ConsumerWidget {
  const CardsListPage({this.deckId, super.key});

  final String? deckId;

  Future<void> _renameDeck(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
  ) async {
    final name = await showTextInputDialog(
      context,
      title: 'Renomear deck',
      label: 'Nome',
      confirmLabel: 'Salvar',
      initialValue: deck.name,
    );
    if (name != null) {
      await ref
          .read(cardsRepositoryProvider)
          .saveDeck(deck.copyWith(name: name));
    }
  }

  Future<void> _deleteDeck(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir "${deck.name}"?'),
        content: const Text('Os cards continuam existindo, sem deck.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).pop();
    await ref.read(cardsRepositoryProvider).deleteDeck(deck.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    final scope = (deckId: deckId, taskId: null);
    final cards = ref.watch(scopeCardsProvider(scope));
    final due = ref.watch(reviewQueueProvider(scope)).value?.length ?? 0;
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(deck?.name ?? 'Todos os cards'),
        actions: [
          if (deck != null)
            PopupMenuButton<String>(
              tooltip: 'Opções do deck',
              onSelected: (v) => v == 'renomear'
                  ? _renameDeck(context, ref, deck)
                  : _deleteDeck(context, ref, deck),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'renomear', child: Text('Renomear')),
                PopupMenuItem(value: 'excluir', child: Text('Excluir deck')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo card',
        onPressed: () => createCardFlow(context, ref, deckId: deckId),
        child: const Icon(AppIcons.add),
      ),
      body: cards.when(
        loading: () => const SkeletonList(),
        error: (_, _) => const EmptyState(
          icon: AppIcons.error,
          message: 'Não foi possível carregar os cards.',
        ),
        data: (cards) => cards.isEmpty
            ? const EmptyState(
                icon: AppIcons.flashcard,
                message: 'Nenhum card aqui ainda.',
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  if (due > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: FilledButton.tonalIcon(
                        icon: const Icon(AppIcons.play),
                        label: Text('Revisar $due agora'),
                        onPressed: () =>
                            context.push(Routes.reviewSession(deckId: deckId)),
                      ),
                    ),
                  for (final card in cards) _CardTile(card: card, today: today),
                ],
              ),
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
        ? 'Suspenso'
        : isNewCard(card)
        ? 'Novo'
        : 'Revisão: ${formatRelative(card.due, today, withTime: card.due.difference(today).inDays < 2)}';
    return ListTile(
      title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        status,
        style: TextStyle(color: card.suspended ? colors.outline : null),
      ),
      onTap: () => editCardFlow(context, ref, card),
      trailing: PopupMenuButton<String>(
        tooltip: 'Opções do card',
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
          const PopupMenuItem(value: 'editar', child: Text('Editar')),
          PopupMenuItem(
            value: 'suspender',
            child: Text(card.suspended ? 'Reativar' : 'Suspender'),
          ),
          const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
        ],
      ),
    );
  }
}
