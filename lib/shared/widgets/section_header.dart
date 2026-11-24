import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Rótulo de seção: pequeno, caixa alta, espaçado ("HOJE · 3"), com uma
/// ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    this.detail,
    this.action,
    this.color,
    this.padding,
    super.key,
  });

  final String title;

  /// Complemento depois do título ("3", "2/5").
  final String? detail;
  final Widget? action;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Padding(
      padding:
          padding ??
          EdgeInsets.fromLTRB(space.page, space.xl, space.sm, space.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${title.toUpperCase()}${detail == null ? '' : ' · $detail'}',
              style: context.type.section.copyWith(color: color),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
