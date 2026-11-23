import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tab_scaffold.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      title: 'Agenda',
      body: EmptyState(
        icon: Icons.calendar_month_outlined,
        message: 'Sua agenda aparecerá aqui.',
      ),
    );
  }
}
