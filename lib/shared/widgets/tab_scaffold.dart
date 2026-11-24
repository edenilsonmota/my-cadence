import 'package:flutter/material.dart';

import '../../app/shell.dart';
import '../../features/sync/presentation/account_avatar.dart';
import 'app_drawer.dart';

/// Scaffold padrão das telas principais: quando está como aba no shell, mostra
/// o menu lateral e o avatar da conta; quando abre por cima do shell, mostra o
/// botão de voltar.
class TabScaffold extends StatelessWidget {
  const TabScaffold({
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final isTab = AppShell.isTab(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [...?actions, if (isTab) const AccountAvatar()],
      ),
      drawer: isTab ? const AppDrawer() : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
