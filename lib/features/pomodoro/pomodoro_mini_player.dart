import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../app/nav_tabs.dart';
import '../../app/nav_tabs_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/enums.dart';
import '../../shared/widgets/glass_surface.dart';
import '../tasks/task_providers.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_logic.dart';

/// Faixa acima das abas enquanto há sessão (ou uma recém-concluída). O toque
/// abre a tela do pomodoro.
class PomodoroMiniPlayer extends ConsumerWidget {
  const PomodoroMiniPlayer({this.floating = false, super.key});

  /// Sobre a barra flutuante do shell: painel de vidro próprio.
  final bool floating;

  Widget _wrap(BuildContext context, Widget child) => !floating
      ? child
      : Padding(
          padding: EdgeInsets.only(bottom: context.space.sm),
          child: GlassSurface(borderRadius: context.radius.xlAll, child: child),
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroControllerProvider);
    final controller = ref.read(pomodoroControllerProvider.notifier);
    final running = state.running;
    final finished = state.finished;
    if (running == null && finished == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    void open() =>
        openNavTab(context, ref.read(navTabsProvider), NavTab.pomodoro);

    if (running == null) {
      return _wrap(
        context,
        Material(
          color: floating
              ? colors.secondaryContainer.withValues(alpha: 0.35)
              : colors.secondaryContainer,
          child: ListTile(
            dense: true,
            leading: const Icon(AppIcons.done),
            title: Text(
              finished!.kind == PomodoroKind.foco
                  ? l10n.pomodoroFocusDoneShort
                  : l10n.pomodoroBreakDone(finished.kind.labelFor(l10n)),
            ),
            subtitle: Text(
              l10n.pomodoroNextLabel(state.suggestedNext.labelFor(l10n)),
            ),
            trailing: IconButton(
              tooltip: l10n.actionDismiss,
              icon: const Icon(AppIcons.close),
              onPressed: controller.dismissFinished,
            ),
            onTap: open,
          ),
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

    return _wrap(
      context,
      Material(
        type: floating ? MaterialType.transparency : MaterialType.canvas,
        color: floating ? null : colors.surfaceContainerHigh,
        child: InkWell(
          onTap: open,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress(running, now),
                minHeight: 3,
                semanticsLabel: l10n.pomodoroCycleProgress,
              ),
              ListTile(
                dense: true,
                leading: Icon(
                  running.kind == PomodoroKind.foco
                      ? AppIcons.pomodoro
                      : AppIcons.breakTime,
                ),
                title: Text(
                  '${running.kind.labelFor(l10n)} · ${formatClock(remaining(running, now))}'
                  '${state.isPaused ? ' · ${l10n.pomodoroPausedSuffix}' : ''}',
                ),
                subtitle: task == null
                    ? null
                    : Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: IconButton(
                  tooltip: state.isPaused
                      ? l10n.pomodoroResume
                      : l10n.pomodoroPause,
                  icon: Icon(state.isPaused ? AppIcons.play : AppIcons.pause),
                  onPressed: state.isPaused
                      ? controller.resume
                      : controller.pause,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
