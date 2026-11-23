import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: const EmptyState(
        icon: Icons.settings_outlined,
        message: 'Os ajustes aparecerão aqui.',
      ),
    );
  }
}
