import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

/// Revisão de cards. Provisória: a revisão com FSRS chega na Etapa 6.
class ReviewSessionPage extends StatelessWidget {
  const ReviewSessionPage({this.taskId, super.key});

  /// Revisar só os cards desta tarefa (e subtarefas).
  final String? taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisão')),
      body: const EmptyState(
        icon: Icons.construction_outlined,
        message: 'A revisão dos cards está em construção.',
      ),
    );
  }
}
