import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tab_scaffold.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      title: 'Tarefas',
      body: EmptyState(
        icon: Icons.checklist_outlined,
        message: 'Nenhuma tarefa criada.',
      ),
    );
  }
}
