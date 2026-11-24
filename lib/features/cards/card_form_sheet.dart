import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../tasks/task_providers.dart';
import '../tasks/widgets/task_picker.dart';

typedef CardFormResult = ({
  String front,
  String back,
  String? deckId,
  String? taskId,
});

final decksProvider = StreamProvider.autoDispose<List<Deck>>(
  (ref) => ref.watch(cardsRepositoryProvider).watchDecks(),
);

/// Painel para criar ou editar um card. Devolve o que foi preenchido ou
/// `null` se fechado.
Future<CardFormResult?> showCardForm(
  BuildContext context, {
  Flashcard? editing,
  String? deckId,
  String? taskId,
  String? initialFront,
  String? initialBack,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<CardFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CardForm(
      editing: editing,
      deckId: editing?.deckId ?? deckId,
      taskId: editing?.taskId ?? taskId,
      initialFront: initialFront,
      initialBack: initialBack,
    ),
  );
}

class _CardForm extends ConsumerStatefulWidget {
  const _CardForm({
    required this.editing,
    required this.deckId,
    required this.taskId,
    this.initialFront,
    this.initialBack,
  });

  final Flashcard? editing;
  final String? deckId;
  final String? taskId;
  final String? initialFront;
  final String? initialBack;

  @override
  ConsumerState<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<_CardForm> {
  late final _front = TextEditingController(
    text: widget.editing?.front ?? widget.initialFront,
  );
  late final _back = TextEditingController(
    text: widget.editing?.back ?? widget.initialBack,
  );
  late String? _deckId = widget.deckId;
  late String? _taskId = widget.taskId;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  bool get _valid =>
      _front.text.trim().isNotEmpty && _back.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(decksProvider).value ?? const <Deck>[];
    final task = _taskId == null
        ? null
        : ref.watch(taskProvider(_taskId!)).value;
    return Padding(
      // Sobe junto com o teclado.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.editing == null ? 'Novo card' : 'Editar card',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _front,
              autofocus: widget.editing == null,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Frente'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _back,
              minLines: 1,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Verso',
                helperText:
                    'Aceita **negrito**, *itálico*, `código` e - listas',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: decks.any((d) => d.id == _deckId) ? _deckId : null,
              decoration: const InputDecoration(labelText: 'Deck'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sem deck')),
                for (final d in decks)
                  DropdownMenuItem(value: d.id, child: Text(d.name)),
              ],
              onChanged: (v) => setState(() => _deckId = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.task),
              title: Text(task?.title ?? 'Sem tarefa'),
              subtitle: const Text('Tarefa vinculada'),
              trailing: TextButton(
                child: const Text('Trocar'),
                onPressed: () async {
                  final picked = await pickTask(context, current: _taskId);
                  if (picked != null) setState(() => _taskId = picked.id);
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _valid
                  ? () => Navigator.of(context).pop((
                      front: _front.text.trim(),
                      back: _back.text.trim(),
                      deckId: _deckId,
                      taskId: _taskId,
                    ))
                  : null,
              child: const Text('Salvar card'),
            ),
          ],
        ),
      ),
    );
  }
}
