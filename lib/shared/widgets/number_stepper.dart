import 'package:flutter/material.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/app_theme.dart';

/// Número com botões de diminuir e aumentar.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.onChanged,
    required this.semanticLabel,
    this.max,
  });

  final int value;
  final int min;
  final int? max;
  final ValueChanged<int> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: l10n.actionDecrease,
          icon: const Icon(AppIcons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            semanticsLabel: '$semanticLabel: $value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.outlined(
          tooltip: l10n.actionIncrease,
          icon: const Icon(AppIcons.add),
          onPressed: max == null || value < max!
              ? () => onChanged(value + 1)
              : null,
        ),
      ],
    );
  }
}
