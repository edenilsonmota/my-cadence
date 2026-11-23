import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

/// Pomodoro. Provisório: o timer chega na Etapa 5.
class PomodoroPage extends StatelessWidget {
  const PomodoroPage({this.taskId, super.key});

  /// Tarefa vinculada ao foco.
  final String? taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: const EmptyState(
        icon: Icons.construction_outlined,
        message: 'O pomodoro está em construção.',
      ),
    );
  }
}
