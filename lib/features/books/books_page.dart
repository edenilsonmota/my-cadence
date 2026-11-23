import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/tab_scaffold.dart';

class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabScaffold(
      title: 'Books',
      body: EmptyState(
        icon: Icons.menu_book_outlined,
        message: 'Nenhum book criado.',
      ),
    );
  }
}
