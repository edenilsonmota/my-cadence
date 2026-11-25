/// Regras do pomodoro. Puro, sem Flutter.
///
/// O tempo nunca é acumulado num Timer: tudo sai de `startedAt`, `pausedAt` e
/// `pausedTotalMs` gravados no banco, então fechar o app não perde nada.
library;

import '../../data/db/database.dart';
import '../../data/db/enums.dart';

// ─── Ajustes ─────────────────────────────────────────────────────────────────

class PomodoroSettings {
  const PomodoroSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakEvery = 4,
    this.autoStartBreaks = false,
    this.sound = true,
    this.vibrate = true,
    this.keepScreenOn = false,
  });

  /// Lê da tabela de ajustes (chave → texto); o que faltar ou vier inválido
  /// fica no padrão.
  factory PomodoroSettings.fromMap(Map<String, String> map) {
    const d = PomodoroSettings();
    int minutes(String key, int fallback) {
      final value = int.tryParse(map[key] ?? '');
      return value == null || value < 1 ? fallback : value;
    }

    bool flag(String key, bool fallback) => switch (map[key]) {
      'true' => true,
      'false' => false,
      _ => fallback,
    };

    return PomodoroSettings(
      focusMinutes: minutes(keyFocus, d.focusMinutes),
      shortBreakMinutes: minutes(keyShortBreak, d.shortBreakMinutes),
      longBreakMinutes: minutes(keyLongBreak, d.longBreakMinutes),
      longBreakEvery: minutes(keyLongEvery, d.longBreakEvery),
      autoStartBreaks: flag(keyAutoBreaks, d.autoStartBreaks),
      sound: flag(keySound, d.sound),
      vibrate: flag(keyVibrate, d.vibrate),
      keepScreenOn: flag(keyScreenOn, d.keepScreenOn),
    );
  }

  static const prefix = 'pomodoro.';
  static const keyFocus = 'pomodoro.focoMin';
  static const keyShortBreak = 'pomodoro.pausaCurtaMin';
  static const keyLongBreak = 'pomodoro.pausaLongaMin';
  static const keyLongEvery = 'pomodoro.pausaLongaACada';
  static const keyAutoBreaks = 'pomodoro.autoIniciarPausas';
  static const keySound = 'pomodoro.som';
  static const keyVibrate = 'pomodoro.vibrar';
  static const keyScreenOn = 'pomodoro.telaLigada';

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  /// Pausa longa depois de quantos focos concluídos.
  final int longBreakEvery;
  final bool autoStartBreaks;
  final bool sound;
  final bool vibrate;
  final bool keepScreenOn;

  int minutesFor(PomodoroKind kind) => switch (kind) {
    PomodoroKind.foco => focusMinutes,
    PomodoroKind.pausaCurta => shortBreakMinutes,
    PomodoroKind.pausaLonga => longBreakMinutes,
  };
}

// ─── Tempo de uma sessão ─────────────────────────────────────────────────────

/// Tempo corrido sem as pausas: até [now], ou até a pausa atual, ou até o fim.
Duration elapsed(PomodoroSession s, DateTime now) {
  final end = s.endedAt ?? s.pausedAt ?? now;
  final time =
      end.difference(s.startedAt) - Duration(milliseconds: s.pausedTotalMs);
  return time.isNegative ? Duration.zero : time;
}

Duration planned(PomodoroSession s) => Duration(minutes: s.plannedMinutes);

/// Quanto falta (nunca negativo).
Duration remaining(PomodoroSession s, DateTime now) {
  final left = planned(s) - elapsed(s, now);
  return left.isNegative ? Duration.zero : left;
}

/// Quando a sessão termina se não for pausada de novo.
DateTime endTime(PomodoroSession s) =>
    s.startedAt.add(planned(s)).add(Duration(milliseconds: s.pausedTotalMs));

/// Fração concluída, de 0 a 1.
double progress(PomodoroSession s, DateTime now) {
  final total = planned(s).inMilliseconds;
  if (total == 0) return 1;
  return (elapsed(s, now).inMilliseconds / total).clamp(0, 1).toDouble();
}

/// Em andamento (não pausada) e com o tempo esgotado.
bool isDue(PomodoroSession s, DateTime now) =>
    s.endedAt == null && s.pausedAt == null && !now.isBefore(endTime(s));

// ─── Ciclo ───────────────────────────────────────────────────────────────────

/// Focos concluídos desde a última pausa longa concluída (sessões em
/// qualquer ordem; normalmente as do dia).
int focusesSinceLongBreak(Iterable<PomodoroSession> sessions) {
  final done = sessions.where((s) => s.completed && !s.manual).toList()
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  var count = 0;
  for (final s in done) {
    if (s.kind == PomodoroKind.pausaLonga) count = 0;
    if (s.kind == PomodoroKind.foco) count++;
  }
  return count;
}

/// Próximo modo sugerido depois de concluir uma sessão de [finished].
PomodoroKind nextKind(
  PomodoroKind finished, {
  required int focusesSinceLong,
  required int longBreakEvery,
}) {
  if (finished != PomodoroKind.foco) return PomodoroKind.foco;
  return focusesSinceLong > 0 && focusesSinceLong % longBreakEvery == 0
      ? PomodoroKind.pausaLonga
      : PomodoroKind.pausaCurta;
}

/// "24:59" ou "1:05:00".
String formatClock(Duration d) {
  final seconds = (d.inMilliseconds / 1000).ceil();
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

extension PomodoroKindLabel on PomodoroKind {
  String get label => switch (this) {
    PomodoroKind.foco => 'Foco',
    PomodoroKind.pausaCurta => 'Pausa curta',
    PomodoroKind.pausaLonga => 'Pausa longa',
  };
}
