import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// FAB com o degradê da cor de destaque ([AppGlass.accent]). Mesmos
/// parâmetros usados do [FloatingActionButton].
class GradientFab extends StatelessWidget {
  const GradientFab({
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.heroTag,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final radius = context.radius.lgAll;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: context.glass.accent,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        tooltip: tooltip,
        onPressed: onPressed,
        backgroundColor: context.colors.primary.withValues(alpha: 0),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        child: child,
      ),
    );
  }
}
