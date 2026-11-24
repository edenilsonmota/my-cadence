import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Entrada em cascata (fade + leve subida) para itens de lista. Só anima na
/// primeira vez que o item aparece e só os 8 primeiros; o resto entra pronto.
class StaggeredEntry extends StatefulWidget {
  const StaggeredEntry({required this.index, required this.child, super.key});

  static const maxAnimated = 8;

  final int index;
  final Widget child;

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = context.motion;
    if (motion.reduced || widget.index >= StaggeredEntry.maxAnimated) {
      _controller.value = 1;
      return;
    }
    _controller.duration = motion.slow;
    Future.delayed(motion.stagger * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: context.motion.enter,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}
