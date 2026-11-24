import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Ícone num quadrado arredondado com o fundo suave da cor (tarefa, book).
class AppearanceBadge extends StatelessWidget {
  const AppearanceBadge({
    required this.colorKey,
    required this.icon,
    this.size = AppIconSize.action,
    super.key,
  });

  final String? colorKey;
  final IconData icon;

  /// Tamanho do ícone; o quadrado tem 1,75× isso.
  final double size;

  @override
  Widget build(BuildContext context) {
    final tones = context.palette.byName(colorKey);
    final box = size * 1.75;
    return Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        color: tones.tint,
        borderRadius: BorderRadius.circular(box * 0.3),
      ),
      child: Icon(icon, size: size, color: tones.onTint),
    );
  }
}
