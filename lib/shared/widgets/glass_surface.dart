import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Superfície de vidro fosco: desfoca o que passa por trás, aplica a tinta e
/// o contorno do tema ([AppGlass]) e um reflexo suave no topo.
///
/// Usar só em elementos que flutuam sobre o conteúdo (barra, mini player,
/// folhas). Em listas, o desfoque por item pesa no Android.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.borderRadius,
    this.padding,
    super.key,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = borderRadius ?? context.radius.xlAll;
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: glass.border),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.alphaBlend(glass.highlight, glass.tint), glass.tint],
          stops: const [0, 0.6],
        ),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (glass.blur > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glass.blur, sigmaY: glass.blur),
        child: surface,
      );
    }
    return ClipRRect(borderRadius: radius, child: surface);
  }
}
