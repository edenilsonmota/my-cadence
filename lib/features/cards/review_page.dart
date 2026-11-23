import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tab_scaffold.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      title: 'Revisar',
      body: EmptyState(
        icon: Icons.style_outlined,
        message: 'Nenhum card para revisar.',
      ),
    );
  }
}
