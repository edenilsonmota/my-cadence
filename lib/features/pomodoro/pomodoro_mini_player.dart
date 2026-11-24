import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/clock.dart';
import '../../app/router.dart';
import '../../app/theme/app_icons.dart';
import '../../data/db/enums.dart';
import '../tasks/task_providers.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_logic.dart';

/// Faixa acima das abas enquanto há sessão (ou uma recém-concluída). O toque
/// abre a tela do pomodoro.
class PomodoroMiniPlayer extends ConsumerWidget {
  const PomodoroMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroControllerProvider);
    final controller = ref.read(pomodoroControllerProvider.notifier);
    final running = state.running;
    final finished = state.finished;
    if (running == null && finished == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    void open() => context.push(Routes.pomodoro());

    if (running == null) {
      return Material(
        color: colors.secondaryContainer,
        child: ListTile(
          dense: true,
          leading: const Icon(AppIcons.done),
          title: Text(
            finished!.kind == PomodoroKind.foco
                ? 'Foco concluído'
                : '${finished.kind.label} concluída',
          ),
          subtitle: Text('Próximo: ${state.suggestedNext.label}'),
          trailing: IconButton(
            tooltip: 'Dispensar',
            icon: const Icon(AppIcons.close),
            onPressed: controller.dismissFinished,
          ),
          onTap: open,
        ),
      );
    }

    // Só bate o relógio enquanto corre (pausado, o tempo está parado).
    if (!state.isPaused) {
      ref.listen(tickerProvider, (_, _) => controller.checkDue());
    }
    final now = state.isPaused
        ? ref.read(clockProvider)()
        : ref.watch(tickerProvider).value ?? ref.read(clockProvider)();
    final task = running.taskId == null
        ? null
        : ref.watch(taskProvider(running.taskId!)).value;

    return Material(
      color: colors.surfaceContainerHigh,
      child: InkWell(
        onTap: open,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress(running, now),
              minHeight: 3,
              semanticsLabel: 'Progresso do ciclo',
            ),
            ListTile(
              dense: true,
              leading: Icon(
                running.kind == PomodoroKind.foco
                    ? AppIcons.pomodoro
                    : AppIcons.breakTime,
              ),
              title: Text(
                '${running.kind.label} · ${formatClock(remaining(running, now))}'
                '${state.isPaused ? ' · pausado' : ''}',
              ),
              subtitle: task == null
                  ? null
                  : Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: IconButton(
                tooltip: state.isPaused ? 'Retomar' : 'Pausar',
                icon: Icon(state.isPaused ? AppIcons.play : AppIcons.pause),
                onPressed: state.isPaused
                    ? controller.resume
                    : controller.pause,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
