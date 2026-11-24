import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Tag como chip com ponto colorido (sem ícone, para não poluir).
class TagChip extends StatelessWidget {
  const TagChip({
    required this.name,
    required this.colorKey,
    this.selected,
    this.onSelected,
    this.onPressed,
    super.key,
  });

  final String name;
  final String colorKey;

  /// Com [onSelected], vira um chip de filtro.
  final bool? selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: context.palette.byName(colorKey).strong,
        shape: BoxShape.circle,
      ),
    );
    final label = Text(name);
    if (onSelected != null) {
      return FilterChip(
        avatar: dot,
        showCheckmark: false,
        label: label,
        selected: selected ?? false,
        onSelected: onSelected,
      );
    }
    if (onPressed != null) {
      return ActionChip(avatar: dot, label: label, onPressed: onPressed);
    }
    return Chip(avatar: dot, label: label);
  }
}
