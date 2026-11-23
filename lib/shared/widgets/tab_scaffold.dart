import 'package:flutter/material.dart';

import 'app_drawer.dart';

/// Scaffold padrão das abas principais: AppBar com título e o menu lateral.
class TabScaffold extends StatelessWidget {
  const TabScaffold({
    required this.title,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
