import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métricas')),
      body: const EmptyState(
        icon: Icons.insights_outlined,
        message: 'As métricas aparecerão aqui.',
      ),
    );
  }
}
