import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tab_scaffold.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      title: 'Hoje',
      body: EmptyState(
        icon: Icons.today_outlined,
        message: 'Nada para hoje ainda.',
      ),
    );
  }
}
