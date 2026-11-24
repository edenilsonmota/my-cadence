import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/clock.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/db/database.dart';
import '../../../data/db/enums.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../../cards/card_form_sheet.dart';
import 'hub_providers.dart';
import 'hub_stats.dart';

/// Quais ferramentas aparecem como seção. Tarefa de estudo mostra sempre as
/// três; nos outros tipos, só as que já têm conteúdo (as demais viram atalho).
({bool cards, bool pomodoro, bool pages}) visibleTools({
  required TaskKind kind,
  required bool hasCards,
  required bool hasPomodoro,
  required bool hasPages,
}) {
  final always = kind == TaskKind.estudo;
  return (
    cards: always || hasCards,
    pomodoro: always || hasPomodoro,
    pages: always || hasPages,
  );
}

enum HubToolsPart { shortcuts, sections }

/// Ferramentas do hub: Flashcards, Pomodoro e Páginas. [part] escolhe se
/// mostra os atalhos das ferramentas ocultas ou as seções visíveis.
class HubTools extends ConsumerWidget {
  const HubTools({required this.task, required this.part, super.key});

  final Task task;
  final HubToolsPart part;

  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    final card = await showCardForm(context, taskId: task.id);
    if (card == null) return;
    await ref
        .read(cardsRepositoryProvider)
        .createCard(
          front: card.front,
          back: card.back,
          now: ref.read(clockProvider)(),
          deckId: card.deckId,
          taskId: card.taskId,
        );
  }

  Future<void> _addPage(BuildContext context, WidgetRef ref, int order) async {
    final title = await showTextInputDialog(
      context,
      title: 'Nova página',
      label: 'Título',
    );
    if (title == null) return;
    final books = ref.read(booksRepositoryProvider);
    final notebookId = await books.taskNotebookId(task.id, title: task.title);
    await books.createPage(
      notebookId: notebookId,
      title: title,
      sortOrder: order,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final cards = ref.watch(taskCardsProvider(task.id)).value ?? const [];
    final sessions = ref.watch(taskSessionsProvider(task.id)).value ?? const [];
    final notebook = ref.watch(taskNotebookProvider(task.id)).value;
    final ownPages = notebook == null
        ? const <NotePage>[]
        : ref.watch(notebookPagesProvider(notebook.id)).value ?? const [];
    final linked = ref.watch(linkedPagesProvider(task.id)).value ?? const [];

    final visible = visibleTools(
      kind: task.kind,
      hasCards: cards.isNotEmpty,
      hasPomodoro: sessions.isNotEmpty || task.estimatedPomodoros != null,
      hasPages: ownPages.isNotEmpty || linked.isNotEmpty,
    );

    void addCard() => _addCard(context, ref);
    void startFocus() => context.push(Routes.pomodoro(taskId: task.id));
    void addPage() => _addPage(context, ref, ownPages.length);

    final shortcuts = [
      if (!visible.cards)
        ActionChip(
          avatar: const Icon(AppIcons.flashcard),
          label: const Text('Flashcard'),
          onPressed: addCard,
        ),
      if (!visible.pomodoro)
        ActionChip(
          avatar: const Icon(AppIcons.pomodoro),
          label: const Text('Pomodoro'),
          onPressed: startFocus,
        ),
      if (!visible.pages)
        ActionChip(
          avatar: const Icon(AppIcons.page),
          label: const Text('Página'),
          onPressed: addPage,
        ),
    ];

    if (part == HubToolsPart.shortcuts) {
      return shortcuts.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.fromLTRB(
                context.space.page,
                0,
                context.space.page,
                context.space.sm,
              ),
              child: Wrap(
                spacing: context.space.sm,
                runSpacing: context.space.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('ADICIONAR', style: context.type.section),
                  ...shortcuts,
                ],
              ),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.cards)
          _CardsSection(
            counts: countCards(cards, now),
            onAdd: addCard,
            onReview: () => context.push(Routes.reviewTask(task.id)),
          ),
        if (visible.pomodoro)
          _PomodoroSection(
            summary: summarizeFocus(sessions, now),
            estimated: task.estimatedPomodoros,
            onStart: startFocus,
          ),
        if (visible.pages)
          _PagesSection(
            taskId: task.id,
            notebookId: notebook?.id,
            ownPages: ownPages,
            linked: linked,
            onAdd: addPage,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;

  /// Mantido para quem chama; a seção usa só o rótulo (menos ruído).
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionHeader(title), ...children],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.space.page,
        context.space.xs,
        context.space.page,
        0,
      ),
      child: Wrap(
        spacing: context.space.sm,
        runSpacing: context.space.xs,
        children: children,
      ),
    );
  }
}

class _CardsSection extends StatelessWidget {
  const _CardsSection({
    required this.counts,
    required this.onAdd,
    required this.onReview,
  });

  final CardCounts counts;
  final VoidCallback onAdd;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final total = counts.total;
    return _Section(
      title: 'Flashcards',
      icon: AppIcons.flashcard,
      children: [
        ListTile(
          title: Text(
            total == 0
                ? 'Nenhum card ainda'
                : '$total ${total == 1 ? 'card' : 'cards'}',
          ),
          subtitle: total == 0
              ? null
              : Text(
                  counts.due == 0
                      ? 'Nada para revisar agora'
                      : '${counts.due} para revisar agora',
                ),
        ),
        _Actions([
          if (total > 0)
            FilledButton.tonalIcon(
              icon: const Icon(AppIcons.play),
              label: const Text('Revisar desta tarefa'),
              onPressed: onReview,
            ),
          OutlinedButton.icon(
            icon: const Icon(AppIcons.add),
            label: const Text('Card'),
            onPressed: onAdd,
          ),
        ]),
      ],
    );
  }
}

class _PomodoroSection extends StatelessWidget {
  const _PomodoroSection({
    required this.summary,
    required this.estimated,
    required this.onStart,
  });

  final FocusSummary summary;
  final int? estimated;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final sessions = summary.sessions;
    return _Section(
      title: 'Pomodoro',
      icon: AppIcons.pomodoro,
      children: [
        ListTile(
          title: Text('Tempo de foco: ${formatDuration(summary.total)}'),
          subtitle: Text(
            sessions == 0
                ? 'Nenhuma sessão ainda'
                : '$sessions ${sessions == 1 ? 'sessão' : 'sessões'} de foco '
                      '(inclui subtarefas)',
          ),
        ),
        if (estimated case final est?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estimado × realizado: ${summary.completed} de $est'),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: est == 0 ? 0 : (summary.completed / est).clamp(0, 1),
                  semanticsLabel: 'Pomodoros realizados',
                ),
              ],
            ),
          ),
        _Actions([
          FilledButton.tonalIcon(
            icon: const Icon(AppIcons.play),
            label: const Text('Iniciar foco'),
            onPressed: onStart,
          ),
        ]),
      ],
    );
  }
}

class _PagesSection extends ConsumerWidget {
  const _PagesSection({
    required this.taskId,
    required this.notebookId,
    required this.ownPages,
    required this.linked,
    required this.onAdd,
  });

  final String taskId;
  final String? notebookId;
  final List<NotePage> ownPages;
  final List<NotePage> linked;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.read(booksRepositoryProvider);
    Widget pageTile(NotePage page, {Widget? trailing}) => ListTile(
      leading: const Icon(AppIcons.page),
      title: Text(page.title),
      trailing: trailing,
      onTap: () => context.push(Routes.page(page.id)),
    );

    return _Section(
      title: 'Páginas',
      icon: AppIcons.page,
      children: [
        if (ownPages.isEmpty && linked.isEmpty)
          const ListTile(title: Text('Nenhuma página ainda')),
        for (final page in ownPages) pageTile(page),
        for (final page in linked)
          pageTile(
            page,
            trailing: IconButton(
              tooltip: 'Desvincular',
              icon: const Icon(AppIcons.unlink),
              onPressed: () => books.unlinkPage(taskId, page.id),
            ),
          ),
        _Actions([
          OutlinedButton.icon(
            icon: const Icon(AppIcons.add),
            label: const Text('Página'),
            onPressed: onAdd,
          ),
          if (notebookId case final id?)
            OutlinedButton.icon(
              icon: const Icon(AppIcons.book),
              label: const Text('Abrir caderno'),
              onPressed: () => context.push(Routes.book(id)),
            ),
          OutlinedButton.icon(
            icon: const Icon(AppIcons.link),
            label: const Text('Vincular página existente'),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _LinkPageSheet(taskId: taskId),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Lista as páginas dos books para vincular ou desvincular da tarefa.
class _LinkPageSheet extends ConsumerWidget {
  const _LinkPageSheet({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(bookPagesProvider).value ?? const [];
    final linkedIds = {
      for (final p
          in ref.watch(linkedPagesProvider(taskId)).value ?? const <NotePage>[])
        p.id,
    };
    final books = ref.read(booksRepositoryProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Vincular página',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (pages.isEmpty)
            const ListTile(
              leading: Icon(AppIcons.book),
              title: Text('Nenhuma página em books ainda.'),
              subtitle: Text('Crie páginas na aba Books para vinculá-las.'),
            ),
          for (final (page, book) in pages)
            CheckboxListTile(
              value: linkedIds.contains(page.id),
              title: Text(page.title),
              subtitle: Text(book.title),
              onChanged: (on) => on == true
                  ? books.linkPage(taskId, page.id)
                  : books.unlinkPage(taskId, page.id),
            ),
        ],
      ),
    );
  }
}
