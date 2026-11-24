import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../app/clock.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/simple_markdown.dart';
import '../../shared/widgets/skeleton.dart';
import 'cards_providers.dart';
import 'fsrs_bridge.dart';
import 'review_queue.dart';

/// Uma revisão feita nesta sessão, para poder desfazer.
typedef _Answered = ({String cardId, CardSchedule previous, String logId});

/// Sessão de revisão de um escopo: tudo, um deck ([deckId]) ou uma tarefa
/// com as subtarefas ([taskId]).
class ReviewSessionPage extends ConsumerStatefulWidget {
  const ReviewSessionPage({this.deckId, this.taskId, super.key});

  final String? deckId;
  final String? taskId;

  @override
  ConsumerState<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends ConsumerState<ReviewSessionPage> {
  late final ReviewScope _scope = (
    deckId: widget.deckId,
    taskId: widget.taskId,
  );

  /// Card na tela (fica fixo até ser respondido, mesmo que a fila mude).
  String? _currentId;
  DateTime? _shownAt;
  Map<Grade, CardSchedule>? _preview;

  /// Momento em que a prévia foi calculada: os intervalos dos botões são
  /// medidos a partir dele (e não do relógio que segue andando, senão
  /// "10 min" vira "9 min" um instante depois).
  DateTime? _previewAt;
  final List<_Answered> _history = [];

  /// Respondidos agora há pouco → agendamento de antes da resposta (para
  /// ignorar a cópia velha até o banco devolver a nova).
  final Map<String, CardSchedule> _justAnswered = {};

  /// Card cuja revisão foi desfeita (volta à tela fora da fila).
  String? _undoneId;
  bool _busy = false;

  fsrs.Scheduler? _scheduler;
  double? _schedulerRetention;

  fsrs.Scheduler _schedulerFor(double retention) {
    if (_scheduler == null || _schedulerRetention != retention) {
      _scheduler = buildScheduler(desiredRetention: retention);
      _schedulerRetention = retention;
    }
    return _scheduler!;
  }

  DateTime _now() => ref.read(clockProvider)();

  void _reveal(Flashcard card) {
    final settings =
        ref.read(cardSettingsProvider).value ?? const CardSettings();
    final at = _now();
    setState(() {
      _previewAt = at;
      _preview = previewReview(
        _schedulerFor(settings.desiredRetention),
        CardSchedule.of(card),
        at,
      );
    });
  }

  Future<void> _answer(Flashcard card, Grade grade) async {
    if (_busy) return;
    final next = _preview![grade]!;
    // A revisão vale no instante da prévia (o resultado escolhido foi
    // calculado para ele).
    final now = _previewAt ?? _now();
    setState(() => _busy = true);
    final logId = await ref
        .read(cardsRepositoryProvider)
        .applyReview(
          cardId: card.id,
          next: next,
          rating: grade.value,
          reviewedAt: now,
          // Tempo de resposta: de quando o card apareceu até o toque.
          durationMs: _shownAt == null
              ? null
              : _now().difference(_shownAt!).inMilliseconds,
        );
    if (!mounted) return;
    setState(() {
      _history.add((
        cardId: card.id,
        previous: CardSchedule.of(card),
        logId: logId,
      ));
      _justAnswered[card.id] = CardSchedule.of(card);
      if (_undoneId == card.id) _undoneId = null;
      _currentId = null;
      _preview = null;
      _busy = false;
    });
  }

  Future<void> _undo() async {
    if (_history.isEmpty || _busy) return;
    final last = _history.removeLast();
    setState(() => _busy = true);
    await ref
        .read(cardsRepositoryProvider)
        .undoReview(
          cardId: last.cardId,
          previous: last.previous,
          logId: last.logId,
        );
    if (!mounted) return;
    setState(() {
      // O agendamento restaurado é igual ao "de antes": não é cópia velha.
      _justAnswered.remove(last.cardId);
      _undoneId = last.cardId;
      _currentId = last.cardId;
      _shownAt = _now();
      _preview = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(reviewQueueProvider(_scope));
    final scopeCards = ref.watch(scopeCardsProvider(_scope)).value ?? const [];
    final now = ref.watch(reviewNowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisão'),
        actions: [
          IconButton(
            tooltip: 'Desfazer última avaliação',
            icon: const Icon(AppIcons.undo),
            onPressed: _history.isEmpty || _busy ? null : _undo,
          ),
        ],
      ),
      body: queue.when(
        loading: () => const SkeletonList(),
        error: (_, _) => const EmptyState(
          icon: AppIcons.error,
          message: 'Não foi possível carregar os cards.',
        ),
        data: (queue) {
          // Esquece as cópias velhas assim que o banco devolve a nova.
          _justAnswered.removeWhere(
            (id, before) => scopeCards.any(
              (c) => c.id == id && CardSchedule.of(c) != before,
            ),
          );
          final card = pickCurrentCard(
            queue: queue,
            scopeCards: scopeCards,
            currentId: _currentId,
            undoneId: _undoneId,
            justAnswered: _justAnswered,
          );
          if (card == null) {
            return _Done(
              reviewed: _history.length,
              nextSoon: nextDueSoon(scopeCards, now),
              now: now,
            );
          }
          if (card.id != _currentId) {
            _currentId = card.id;
            _shownAt = _now();
            _preview = null;
          }
          final remaining =
              queue
                  .where(
                    (c) => c.id != card.id && !_justAnswered.containsKey(c.id),
                  )
                  .length +
              1;
          return _CardView(
            card: card,
            reviewed: _history.length,
            remaining: remaining,
            preview: _preview,
            previewAt: _previewAt ?? now,
            busy: _busy,
            onReveal: () => _reveal(card),
            onAnswer: (grade) => _answer(card, grade),
          );
        },
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({
    required this.card,
    required this.reviewed,
    required this.remaining,
    required this.preview,
    required this.previewAt,
    required this.busy,
    required this.onReveal,
    required this.onAnswer,
  });

  final Flashcard card;

  /// Avaliados nesta sessão (para a barra de progresso).
  final int reviewed;
  final int remaining;
  final Map<Grade, CardSchedule>? preview;
  final DateTime previewAt;
  final bool busy;
  final VoidCallback onReveal;
  final ValueChanged<Grade> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.space;
    final revealed = preview != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progresso da sessão, fino.
        LinearProgressIndicator(
          value: reviewed / (reviewed + remaining),
          minHeight: 3,
          semanticsLabel: 'Progresso da sessão',
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(space.page, space.md, space.page, 0),
          child: Text(
            '$remaining ${remaining == 1 ? 'card restante' : 'cards restantes'}'
            '${isNewCard(card) ? ' · novo' : ''}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(space.xl),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: space.xl,
                  vertical: space.xxl,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: context.radius.xlAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SimpleMarkdown(
                      card.front,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    if (revealed) ...[
                      Divider(height: space.xxxl),
                      SimpleMarkdown(
                        card.back,
                        style: context.type.reading,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(space.md, 0, space.md, space.md),
            child: revealed
                ? Row(
                    children: [
                      for (final grade in Grade.values)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: space.xxs,
                            ),
                            child: _GradeButton(
                              grade: grade,
                              interval: preview![grade]!.due.difference(
                                previewAt,
                              ),
                              onPressed: busy ? null : () => onAnswer(grade),
                            ),
                          ),
                        ),
                    ],
                  )
                : FilledButton(
                    onPressed: onReveal,
                    child: const Text('Mostrar resposta'),
                  ),
          ),
        ),
      ],
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.grade,
    required this.interval,
    required this.onPressed,
  });

  final Grade grade;
  final Duration interval;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // As 4 cores semânticas das notas (Errei, Difícil, Bom, Fácil).
    final tones = context.palette.grade(grade.value);
    final (bg, fg) = (tones.tint, tones.onTint);
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: EdgeInsets.symmetric(
          vertical: context.space.sm,
          horizontal: context.space.xs,
        ),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(grade.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            formatInterval(interval),
            style: context.text.labelSmall!.tabular.copyWith(
              color: fg.withValues(alpha: 0.8),
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.reviewed,
    required this.nextSoon,
    required this.now,
  });

  final int reviewed;
  final DateTime? nextSoon;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final soon = nextSoon;
    if (soon != null) {
      final minutes = (soon.difference(now).inSeconds / 60).ceil();
      return EmptyState(
        icon: AppIcons.breakTime,
        message:
            'Próximo card em ${minutes <= 1 ? '1 min' : '$minutes min'}.\n'
            'Ele aparece aqui sozinho.',
      );
    }
    return EmptyState(
      icon: AppIcons.celebrate,
      message: reviewed == 0
          ? 'Nada para revisar agora.'
          : 'Tudo revisado por agora! '
                '$reviewed ${reviewed == 1 ? 'card' : 'cards'} nesta sessão.',
    );
  }
}
