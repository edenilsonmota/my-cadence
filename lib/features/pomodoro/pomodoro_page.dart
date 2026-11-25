import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/l10n/l10n.dart';
import '../../app/nav_tabs.dart';
import '../../app/shell.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../../shared/widgets/appearance_badge.dart';
import '../../shared/widgets/tab_scaffold.dart';
import '../tasks/task_providers.dart';
import '../tasks/widgets/task_picker.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_logic.dart';

class PomodoroPage extends ConsumerStatefulWidget {
  const PomodoroPage({this.taskId, super.key});

  /// Tarefa pré-selecionada (vindo do hub).
  final String? taskId;

  @override
  ConsumerState<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends ConsumerState<PomodoroPage> {
  PomodoroKind? _kind;
  late String? _taskId = widget.taskId;

  /// O usuário já escolheu a tarefa nesta tela (então não herda a da sessão
  /// que acabou).
  bool _taskChosen = false;
  bool _screenAwake = false;

  // Guardado no início: no `dispose` o `ref` já não pode ser usado.
  late final Future<void> Function(bool on) _setScreenAwake;

  @override
  void initState() {
    super.initState();
    _setScreenAwake = ref.read(screenAwakeProvider);
  }

  @override
  void dispose() {
    if (_screenAwake) _setScreenAwake(false);
    super.dispose();
  }

  /// Mantém a tela ligada durante uma sessão rodando, se o ajuste pedir.
  void _syncScreenAwake(bool want) {
    if (!mounted || want == _screenAwake) return;
    _screenAwake = want;
    _setScreenAwake(want);
  }

  Future<void> _pickTask(
    String? current,
    ValueChanged<String?> onPicked,
  ) async {
    final picked = await pickTask(
      context,
      current: current,
      title: context.l10n.pomodoroPickTask,
    );
    if (picked != null) onPicked(picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroControllerProvider);
    final controller = ref.read(pomodoroControllerProvider.notifier);
    final settings =
        ref.watch(pomodoroSettingsProvider).value ?? const PomodoroSettings();
    final running = state.running;

    // A cada segundo: redesenha e confere se o tempo acabou (só enquanto esta
    // tela está visível: como aba ativa ou aberta por cima do shell).
    final activeTab = AppShell.activeTabOf(context);
    final visible = activeTab == null || activeTab == NavTab.pomodoro;
    if (visible) {
      ref.listen(tickerProvider, (_, _) => controller.checkDue());
    }
    final now = visible
        ? (ref.watch(tickerProvider).value ?? ref.read(clockProvider)())
        : ref.read(clockProvider)();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncScreenAwake(
        visible && settings.keepScreenOn && running != null && !state.isPaused,
      ),
    );

    final kind = running?.kind ?? _kind ?? state.suggestedNext;
    // Parado: a tarefa escolhida, ou a do ciclo que acabou de terminar (para o
    // próximo foco continuar na mesma tarefa).
    final idleTaskId = _taskChosen || _taskId != null
        ? _taskId
        : state.finished?.taskId;
    final taskId = running != null ? running.taskId : idleTaskId;
    final duration = running == null
        ? Duration(minutes: settings.minutesFor(kind))
        : remaining(running, now);
    final ringValue = running == null ? 0.0 : progress(running, now);
    final colors = context.colors;
    final space = context.space;
    final task = taskId == null ? null : ref.watch(taskProvider(taskId)).value;
    final resolver = ref.watch(appearanceResolverProvider);
    // Anel na cor da tarefa; sem tarefa, a cor do app.
    final ringColor = task == null
        ? colors.primary
        : context.palette.byName(resolver.colorKeyOf(task)).strong;
    final ringTrack = task == null
        ? colors.surfaceContainerHighest
        : context.palette.byName(resolver.colorKeyOf(task)).tint;

    final l10n = context.l10n;
    return TabScaffold(
      title: l10n.navPomodoro,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          space.page,
          space.sm,
          space.page,
          space.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (state.finished case final finished?)
            _FinishedCard(
              finished: finished,
              next: state.suggestedNext,
              // Com a próxima sessão já rodando (pausa iniciada sozinha),
              // "Iniciar" interromperia a que está em andamento.
              nextAlreadyRunning: running != null,
              onStartNext: () => controller.start(
                state.suggestedNext,
                taskId: finished.taskId,
              ),
              onDismiss: controller.dismissFinished,
            ),
          if (running == null)
            SegmentedButton<PomodoroKind>(
              showSelectedIcon: false,
              segments: [
                for (final k in PomodoroKind.values)
                  ButtonSegment(value: k, label: Text(k.labelFor(l10n))),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setState(() => _kind = s.single),
            ),
          SizedBox(height: space.lg),
          _TaskRow(
            task: task,
            onChange: () => _pickTask(
              taskId,
              (id) => running != null
                  ? controller.setTask(id)
                  : setState(() {
                      _taskId = id;
                      _taskChosen = true;
                    }),
            ),
          ),
          SizedBox(height: space.xl),
          Center(
            child: SizedBox.square(
              dimension: 248,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    color: ringTrack,
                  ),
                  // Arco com degradê: da cor do ciclo até um tom mais claro.
                  ShaderMask(
                    shaderCallback: (rect) => SweepGradient(
                      startAngle: -1.5708,
                      endAngle: 4.7124,
                      colors: [
                        ringColor,
                        Color.lerp(ringColor, colors.onSurface, 0.45)!,
                      ],
                      transform: const GradientRotation(-1.5708),
                    ).createShader(rect),
                    child: CircularProgressIndicator(
                      value: ringValue,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: colors.onSurface,
                      semanticsLabel: l10n.pomodoroCycleProgress,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatClock(duration), style: context.type.timer),
                        SizedBox(height: space.xs),
                        Text(
                          state.isPaused
                              ? '${kind.labelFor(l10n)} · ${l10n.pomodoroPausedSuffix}'
                              : kind.labelFor(l10n),
                          style: context.text.titleMedium!.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: space.xxl),
          _Controls(
            running: running != null,
            paused: state.isPaused,
            onStart: () => controller.start(kind, taskId: idleTaskId),
            onPause: controller.pause,
            onResume: controller.resume,
            onStop: controller.stop,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.running,
    required this.paused,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final bool running;
  final bool paused;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!running) {
      return FilledButton.icon(
        icon: const Icon(AppIcons.play),
        label: Text(l10n.pomodoroStart),
        onPressed: onStart,
      );
    }
    return Row(
      children: [
        Expanded(
          child: paused
              ? FilledButton.icon(
                  icon: const Icon(AppIcons.play),
                  label: Text(l10n.pomodoroResume),
                  onPressed: onResume,
                )
              : FilledButton.tonalIcon(
                  icon: const Icon(AppIcons.pause),
                  label: Text(l10n.pomodoroPause),
                  onPressed: onPause,
                ),
        ),
        SizedBox(width: context.space.md),
        Expanded(
          child: TextButton.icon(
            icon: const Icon(AppIcons.stop),
            label: Text(l10n.pomodoroStop),
            onPressed: onStop,
          ),
        ),
      ],
    );
  }
}

/// Tarefa do ciclo: ícone e título, com "Trocar".
class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.onChange});

  final Task? task;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final task = this.task;
    final resolver = ref.watch(appearanceResolverProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: task == null
          ? const AppearanceBadge(colorKey: null, icon: AppIcons.task)
          : AppearanceBadge(
              colorKey: resolver.colorKeyOf(task),
              icon: AppIcons.of(
                resolver.iconKeyOf(task),
                fallback: AppIcons.kind(task.kind),
              ),
            ),
      title: Text(
        task?.title ?? l10n.pomodoroNoTask,
        style: context.text.titleMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(l10n.pomodoroLinkedTask),
      trailing: TextButton(onPressed: onChange, child: Text(l10n.actionChange)),
    );
  }
}

class _FinishedCard extends ConsumerWidget {
  const _FinishedCard({
    required this.finished,
    required this.next,
    required this.nextAlreadyRunning,
    required this.onStartNext,
    required this.onDismiss,
  });

  final PomodoroSession finished;
  final PomodoroKind next;
  final bool nextAlreadyRunning;
  final VoidCallback onStartNext;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final focus = finished.kind == PomodoroKind.foco;
    final task = finished.taskId == null
        ? null
        : ref.watch(taskProvider(finished.taskId!)).value;
    final canComplete =
        focus && task != null && task.status != TaskStatus.feita;
    final colors = Theme.of(context).colorScheme;
    final nextLabel = next.labelFor(l10n);

    return Card.filled(
      color: colors.secondaryContainer,
      margin: EdgeInsets.only(bottom: context.space.lg),
      child: Padding(
        padding: EdgeInsets.all(context.space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              focus
                  ? l10n.pomodoroFocusDone
                  : l10n.pomodoroBreakDone(finished.kind.labelFor(l10n)),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: context.space.xs),
            Text(
              nextAlreadyRunning
                  ? l10n.pomodoroNextRunning(nextLabel)
                  : l10n.pomodoroNextLabel(nextLabel),
            ),
            SizedBox(height: context.space.md),
            Wrap(
              spacing: context.space.sm,
              runSpacing: context.space.xs,
              children: [
                if (!nextAlreadyRunning)
                  FilledButton(
                    onPressed: onStartNext,
                    child: Text(
                      l10n.pomodoroStartNext(nextLabel.toLowerCase()),
                    ),
                  ),
                if (canComplete)
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(tasksRepositoryProvider)
                          .completeTask(task.id);
                    },
                    child: Text(l10n.pomodoroCompleteTask(task.title)),
                  ),
                TextButton(
                  onPressed: onDismiss,
                  child: Text(l10n.actionDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
