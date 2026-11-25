import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Indicador leve: número grande com algarismos tabulares, rótulo pequeno e
/// uma variação discreta opcional ("+15 min").
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.value,
    required this.label,
    this.delta,
    this.deltaUp,
    super.key,
  });

  final String value;
  final String label;

  /// Variação em relação ao período anterior.
  final String? delta;

  /// `true` subiu, `false` caiu, `null` igual (cor neutra).
  final bool? deltaUp;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.colors;
    final deltaColor = switch (deltaUp) {
      true => context.palette.success.strong,
      false => colors.onSurfaceVariant,
      null => colors.onSurfaceVariant,
    };
    return Container(
      padding: EdgeInsets.symmetric(vertical: space.md, horizontal: space.md),
      decoration: BoxDecoration(
        gradient: context.glass.card,
        borderRadius: context.radius.lgAll,
        border: Border.all(color: context.glass.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.type.metric, maxLines: 1),
          ),
          SizedBox(height: space.xxs),
          Text(
            label,
            maxLines: 2,
            style: context.text.labelSmall!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (delta != null) ...[
            SizedBox(height: space.xxs),
            Text(
              delta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.micro.tabular.copyWith(color: deltaColor),
            ),
          ],
        ],
      ),
    );
  }
}
