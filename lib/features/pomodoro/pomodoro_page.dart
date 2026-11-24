import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
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
      title: 'Tarefa do foco',
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

    // A cada segundo: redesenha e confere se o tempo acabou.
    ref.listen(tickerProvider, (_, _) => controller.checkDue());
    final now = ref.watch(tickerProvider).value ?? ref.read(clockProvider)();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncScreenAwake(
        settings.keepScreenOn && running != null && !state.isPaused,
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                  ButtonSegment(value: k, label: Text(k.label)),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setState(() => _kind = s.single),
            ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox.square(
              dimension: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: ringValue,
                    strokeWidth: 12,
                    backgroundColor: colors.surfaceContainerHighest,
                    semanticsLabel: 'Progresso do ciclo',
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatClock(duration),
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        Text(
                          state.isPaused
                              ? '${kind.label} · pausado'
                              : kind.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _TaskRow(
            taskId: taskId,
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
          const SizedBox(height: 16),
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
    if (!running) {
      return FilledButton.icon(
        icon: const Icon(AppIcons.play),
        label: const Text('Iniciar'),
        onPressed: onStart,
      );
    }
    return Row(
      children: [
        Expanded(
          child: paused
              ? FilledButton.icon(
                  icon: const Icon(AppIcons.play),
                  label: const Text('Retomar'),
                  onPressed: onResume,
                )
              : FilledButton.tonalIcon(
                  icon: const Icon(AppIcons.pause),
                  label: const Text('Pausar'),
                  onPressed: onPause,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(AppIcons.stop),
            label: const Text('Parar'),
            onPressed: onStop,
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.taskId, required this.onChange});

  final String? taskId;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = taskId == null ? null : ref.watch(taskProvider(taskId!)).value;
    return Card.outlined(
      child: ListTile(
        leading: const Icon(AppIcons.task),
        title: Text(task?.title ?? 'Sem tarefa'),
        subtitle: const Text('Tarefa vinculada'),
        trailing: TextButton(onPressed: onChange, child: const Text('Trocar')),
      ),
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
    final focus = finished.kind == PomodoroKind.foco;
    final task = finished.taskId == null
        ? null
        : ref.watch(taskProvider(finished.taskId!)).value;
    final canComplete =
        focus && task != null && task.status != TaskStatus.feita;
    final colors = Theme.of(context).colorScheme;

    return Card.filled(
      color: colors.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              focus ? 'Foco concluído!' : '${finished.kind.label} concluída',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              nextAlreadyRunning
                  ? '${next.label} em andamento'
                  : 'Próximo: ${next.label}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (!nextAlreadyRunning)
                  FilledButton(
                    onPressed: onStartNext,
                    child: Text('Iniciar ${next.label.toLowerCase()}'),
                  ),
                if (canComplete)
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(tasksRepositoryProvider)
                          .completeTask(task.id);
                    },
                    child: Text('Concluir "${task.title}"'),
                  ),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Dispensar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
