import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_icons.dart';
import '../../../data/db/database.dart';
import '../../../data/db/enums.dart';
import '../task_providers.dart';

/// Escolhe uma tarefa não concluída. Devolve `(id: null)` para "Sem tarefa"
/// e `null` se o painel for fechado sem escolha.
Future<({String? id})?> pickTask(
  BuildContext context, {
  required String? current,
  String title = 'Tarefa',
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<({String? id})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskPicker(current: current, title: title),
  );
}

class _TaskPicker extends ConsumerWidget {
  const _TaskPicker({required this.current, required this.title});

  final String? current;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks =
        (ref.watch(allTasksProvider).value ?? const <Task>[])
            .where((t) => t.status != TaskStatus.feita)
            .toList()
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );

    Widget option(String? id, String title) => ListTile(
      leading: Icon(id == current ? AppIcons.radioOn : AppIcons.radioOff),
      title: Text(title),
      selected: id == current,
      onTap: () => Navigator.of(context).pop((id: id)),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          option(null, 'Sem tarefa'),
          for (final task in tasks) option(task.id, task.title),
        ],
      ),
    );
  }
}
