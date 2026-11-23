import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../shared/widgets/empty_state.dart';

final _pageProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(booksRepositoryProvider).getPage(id),
);

/// Página de um caderno. Provisória: o editor chega na Etapa 7.
class NotePagePage extends ConsumerWidget {
  const NotePagePage({required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(_pageProvider(pageId)).value;
    return Scaffold(
      appBar: AppBar(title: Text(page?.title ?? 'Página')),
      body: const EmptyState(
        icon: Icons.construction_outlined,
        message: 'O editor de páginas está em construção.',
      ),
    );
  }
}
