import 'package:flutter/material.dart';

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Diminuir',
          icon: const Icon(Icons.remove),
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
          tooltip: 'Aumentar',
          icon: const Icon(Icons.add),
          onPressed: max == null || value < max!
              ? () => onChanged(value + 1)
              : null,
        ),
      ],
    );
  }
}
