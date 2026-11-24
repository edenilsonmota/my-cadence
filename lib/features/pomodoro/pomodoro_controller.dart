import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/clock.dart';
import '../../core/dates.dart';
import '../../core/notification_id.dart';
import '../../core/notifications.dart';
import '../../data/db/database.dart';
import '../../data/db/enums.dart';
import '../../data/providers.dart';
import '../tasks/alarms.dart';
import 'pomodoro_logic.dart';

final pomodoroSettingsProvider = StreamProvider<PomodoroSettings>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchPrefix(PomodoroSettings.prefix)
      .map(PomodoroSettings.fromMap),
);

/// Liga ou desliga o "manter a tela ligada". Os testes trocam por um no-op.
final screenAwakeProvider = Provider<Future<void> Function(bool on)>(
  (ref) =>
      (on) => WakelockPlus.toggle(enable: on),
);

class PomodoroState {
  const PomodoroState({
    this.running,
    this.finished,
    this.suggestedNext = PomodoroKind.foco,
    this.loaded = false,
  });

  /// Sessão em andamento (ou pausada).
  final PomodoroSession? running;

  /// Última sessão que chegou ao fim e ainda não foi dispensada na tela.
  final PomodoroSession? finished;

  /// Próximo modo sugerido (pausa curta/longa depois do foco; foco depois
  /// da pausa).
  final PomodoroKind suggestedNext;

  /// Já leu o banco ao menos uma vez.
  final bool loaded;

  bool get isPaused => running?.pausedAt != null;

  PomodoroState copyWith({
    PomodoroSession? Function()? running,
    PomodoroSession? Function()? finished,
    PomodoroKind? suggestedNext,
    bool? loaded,
  }) => PomodoroState(
    running: running == null ? this.running : running(),
    finished: finished == null ? this.finished : finished(),
    suggestedNext: suggestedNext ?? this.suggestedNext,
    loaded: loaded ?? this.loaded,
  );
}

final pomodoroControllerProvider =
    NotifierProvider<PomodoroController, PomodoroState>(PomodoroController.new);

/// Liga a tela ao banco: inicia, pausa, retoma e para sessões, agenda a
/// notificação de fim e percebe quando o tempo acabou (inclusive com o app
/// reaberto depois do horário).
class PomodoroController extends Notifier<PomodoroState> {
  Timer? _timer;
  StreamSubscription<PomodoroSession?>? _subscription;
  bool _finishing = false;
  bool _restored = false;

  DateTime _now() => ref.read(clockProvider)();

  @override
  PomodoroState build() {
    _subscription = ref
        .watch(pomodoroRepositoryProvider)
        .watchRunning()
        .listen(_onRunning);
    // Mantém os ajustes ativos: no Riverpod 3 um provider só lido (sem
    // ninguém escutando) fica pausado e o `.future` nunca completaria.
    ref.listen(pomodoroSettingsProvider, (_, _) {});
    ref.onDispose(() {
      _subscription?.cancel();
      _timer?.cancel();
    });
    return const PomodoroState();
  }

  Future<PomodoroSettings> _settings() =>
      ref.read(pomodoroSettingsProvider.future);

  void _onRunning(PomodoroSession? session) {
    state = state.copyWith(running: () => session, loaded: true);
    _arm(session);
    if (!_restored) {
      _restored = true;
      // Sessão que sobreviveu ao fechamento do app: garante a notificação
      // (alguns aparelhos perdem alarmes no reboot).
      if (session != null &&
          session.pausedAt == null &&
          !isDue(session, _now())) {
        unawaited(_scheduleEnd(session));
      }
    }
  }

  void _arm(PomodoroSession? session) {
    _timer?.cancel();
    if (session == null || session.pausedAt != null) return;
    final left = endTime(session).difference(_now());
    if (left <= Duration.zero) {
      scheduleMicrotask(checkDue);
    } else {
      _timer = Timer(left, checkDue);
    }
  }

  /// Fecha a sessão se o tempo acabou. Chamado pelo timer, pela tela a cada
  /// segundo e quando o app volta ao primeiro plano.
  Future<void> checkDue() async {
    final session = state.running;
    if (session == null || _finishing || !isDue(session, _now())) return;
    _finishing = true;
    try {
      final end = endTime(session);
      await ref
          .read(pomodoroRepositoryProvider)
          .finishSession(session.id, endedAt: end, completed: true);
      final finished = session.copyWith(endedAt: Value(end), completed: true);
      final next = await _suggestNext(finished);
      state = state.copyWith(
        running: () => null,
        finished: () => finished,
        suggestedNext: next,
      );
      final settings = await _settings();
      if (session.kind == PomodoroKind.foco && settings.autoStartBreaks) {
        await start(next, taskId: session.taskId, keepFinished: true);
      }
    } finally {
      _finishing = false;
    }
  }

  Future<PomodoroKind> _suggestNext(PomodoroSession finished) async {
    final settings = await _settings();
    final today = startOfDay(_now());
    final sessions = await ref
        .read(pomodoroRepositoryProvider)
        .watchSessionsBetween(today, addDays(today, 1))
        .first;
    return nextKind(
      finished.kind,
      focusesSinceLong: focusesSinceLongBreak(sessions),
      longBreakEvery: settings.longBreakEvery,
    );
  }

  /// Inicia uma sessão. Se já houver outra, ela é interrompida.
  Future<void> start(
    PomodoroKind kind, {
    String? taskId,
    bool keepFinished = false,
  }) async {
    if (state.running != null) await stop();
    final settings = await _settings();
    final now = _now();
    final repo = ref.read(pomodoroRepositoryProvider);
    final id = await repo.startSession(
      kind: kind,
      plannedMinutes: settings.minutesFor(kind),
      startedAt: now,
      taskId: taskId,
    );
    if (!keepFinished) state = state.copyWith(finished: () => null);
    final session = (await repo.getRunning())!;
    assert(session.id == id);
    await _scheduleEnd(session, settings: settings);
  }

  Future<void> pause() async {
    final session = state.running;
    if (session == null || session.pausedAt != null) return;
    _timer?.cancel();
    await ref
        .read(pomodoroRepositoryProvider)
        .pauseSession(session.id, at: _now());
    await ref.read(alarmSchedulerProvider).cancel(pomodoroNotificationId);
  }

  Future<void> resume() async {
    final session = state.running;
    if (session == null || session.pausedAt == null) return;
    final repo = ref.read(pomodoroRepositoryProvider);
    await repo.resumeSession(session, at: _now());
    final resumed = await repo.getRunning();
    if (resumed != null) await _scheduleEnd(resumed);
  }

  /// Para a sessão antes do fim (fica registrada como interrompida).
  Future<void> stop() async {
    final session = state.running;
    if (session == null) return;
    _timer?.cancel();
    await ref
        .read(pomodoroRepositoryProvider)
        .finishSession(session.id, endedAt: _now(), completed: false);
    await ref.read(alarmSchedulerProvider).cancel(pomodoroNotificationId);
  }

  /// Troca a tarefa da sessão em andamento.
  Future<void> setTask(String? taskId) async {
    final session = state.running;
    if (session == null) return;
    await ref
        .read(pomodoroRepositoryProvider)
        .setSessionTask(session.id, taskId);
  }

  /// Esconde o aviso de "sessão concluída".
  void dismissFinished() => state = state.copyWith(finished: () => null);

  Future<void> _scheduleEnd(
    PomodoroSession session, {
    PomodoroSettings? settings,
  }) async {
    final s = settings ?? await _settings();
    final focus = session.kind == PomodoroKind.foco;
    await ref
        .read(alarmSchedulerProvider)
        .schedule(
          AlarmSpec(
            id: pomodoroNotificationId,
            time: endTime(session),
            title: focus ? 'Foco concluído' : '${session.kind.label} concluída',
            body: focus ? 'Hora de uma pausa.' : 'Hora de voltar ao foco.',
            payload: pomodoroPayload,
            kind: AlarmKind.pomodoro,
            sound: s.sound,
            vibrate: s.vibrate,
          ),
        );
  }
}
