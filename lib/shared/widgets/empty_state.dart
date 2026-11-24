import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Mensagem centralizada para telas e seções sem conteúdo: ícone num círculo
/// suave, uma frase e, se houver, a ação.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;

  /// Botão opcional abaixo da mensagem.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final space = context.space;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppIconSize.feature,
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: space.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[SizedBox(height: space.lg), action!],
          ],
        ),
      ),
    );
  }
}
