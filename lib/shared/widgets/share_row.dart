import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Linha de proporção: rótulo, valor e barra (foco por tarefa/tag, estimado ×
/// feito, revisão da semana).
class ShareRow extends StatelessWidget {
  const ShareRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.color,
  });

  final String label;
  final String value;
  final double fraction;

  /// Cor da barra (da tarefa ou da tag); padrão, a do tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              SizedBox(width: context.space.sm),
              Text(value, style: theme.textTheme.labelLarge!.tabular),
            ],
          ),
          SizedBox(height: context.space.xs),
          LinearProgressIndicator(
            value: fraction.clamp(0, 1).toDouble(),
            minHeight: 6,
            color: color,
          ),
        ],
      ),
    );
  }
}
