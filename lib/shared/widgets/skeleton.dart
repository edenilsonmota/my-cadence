import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Bloco cinza no formato do conteúdo que ainda vai chegar, pulsando de leve
/// (parado se o sistema pede menos animação).
class Skeleton extends StatefulWidget {
  const Skeleton({this.width, this.height = 14, this.radius, super.key});

  final double? width;
  final double height;
  final double? radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    lowerBound: 0.55,
    upperBound: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    if (motion.reduced) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.duration = motion.slow * 3;
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _pulse,
    child: Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.radius ?? context.radius.xs),
      ),
    ),
  );
}

/// Lista no formato de itens (ícone, título e linha de apoio).
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.items = 6, super.key});

  final int items;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: space.sm),
      itemCount: items,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: space.page,
          vertical: space.md,
        ),
        child: Row(
          children: [
            Skeleton(
              width: AppIconSize.action,
              height: AppIconSize.action,
              radius: context.radius.sm,
            ),
            SizedBox(width: space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Larguras variadas para não parecer uma grade.
                  FractionallySizedBox(
                    widthFactor: const [0.7, 0.5, 0.85, 0.6][i % 4],
                    child: const Skeleton(),
                  ),
                  SizedBox(height: space.sm),
                  const FractionallySizedBox(
                    widthFactor: 0.3,
                    child: Skeleton(height: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página de detalhe: título e alguns parágrafos.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Padding(
      padding: EdgeInsets.all(space.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FractionallySizedBox(
            widthFactor: 0.6,
            child: Skeleton(height: 24),
          ),
          SizedBox(height: space.xl),
          for (final w in const [1.0, 0.9, 0.95, 0.7]) ...[
            FractionallySizedBox(widthFactor: w, child: const Skeleton()),
            SizedBox(height: space.md),
          ],
        ],
      ),
    );
  }
}
