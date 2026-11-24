import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Encolhe de leve (0,98) enquanto pressionado. Não intercepta o toque: o
/// filho continua recebendo (use em volta de cartões e itens tocáveis).
class Pressable extends StatefulWidget {
  const Pressable({required this.child, super.key});

  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? motion.pressedScale : 1,
        duration: motion.fast,
        curve: motion.standard,
        child: widget.child,
      ),
    );
  }
}
