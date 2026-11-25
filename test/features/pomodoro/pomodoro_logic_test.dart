import 'package:flutter_test/flutter_test.dart';
import 'package:my_cadence/data/db/database.dart';
import 'package:my_cadence/data/db/enums.dart';
import 'package:my_cadence/features/pomodoro/pomodoro_logic.dart';

final start = DateTime(2026, 11, 23, 9);

PomodoroSession session({
  PomodoroKind kind = PomodoroKind.foco,
  DateTime? startedAt,
  int minutes = 25,
  DateTime? pausedAt,
  int pausedMs = 0,
  DateTime? endedAt,
  bool completed = false,
}) => PomodoroSession(
  id: 'x',
  createdAt: start,
  updatedAt: start,
  dirty: true,
  kind: kind,
  startedAt: startedAt ?? start,
  plannedMinutes: minutes,
  pausedAt: pausedAt,
  pausedTotalMs: pausedMs,
  endedAt: endedAt,
  completed: completed,
  manual: false,
);

DateTime at(int minute, [int second = 0]) =>
    start.add(Duration(minutes: minute, seconds: second));

void main() {
  group('ajustes', () {
    test('padrões quando não há nada gravado', () {
      final s = PomodoroSettings.fromMap(const {});
      expect(s.focusMinutes, 25);
      expect(s.shortBreakMinutes, 5);
      expect(s.longBreakMinutes, 15);
      expect(s.longBreakEvery, 4);
      expect(s.autoStartBreaks, isFalse);
      expect(s.sound, isTrue);
    });

    test('lê valores e ignora inválidos', () {
      final s = PomodoroSettings.fromMap({
        PomodoroSettings.keyFocus: '50',
        PomodoroSettings.keyShortBreak: 'abc',
        PomodoroSettings.keyLongBreak: '0',
        PomodoroSettings.keyAutoBreaks: 'true',
        PomodoroSettings.keySound: 'false',
      });
      expect(s.focusMinutes, 50);
      expect(s.shortBreakMinutes, 5);
      expect(s.longBreakMinutes, 15);
      expect(s.autoStartBreaks, isTrue);
      expect(s.sound, isFalse);
      expect(s.minutesFor(PomodoroKind.foco), 50);
    });
  });

  group('tempo', () {
    test('em andamento: decorrido, restante, fim e progresso', () {
      final s = session();
      expect(elapsed(s, at(10)), const Duration(minutes: 10));
      expect(remaining(s, at(10)), const Duration(minutes: 15));
      expect(endTime(s), at(25));
      expect(progress(s, at(10)), closeTo(0.4, 1e-9));
      expect(isDue(s, at(24, 59)), isFalse);
      expect(isDue(s, at(25)), isTrue);
    });

    test('pausada: o tempo congela na pausa', () {
      final s = session(pausedAt: at(10));
      expect(remaining(s, at(40)), const Duration(minutes: 15));
      expect(isDue(s, at(60)), isFalse);
    });

    test('depois de retomar: pausas anteriores empurram o fim', () {
      final s = session(pausedMs: 5 * 60 * 1000); // ficou 5 min pausada
      expect(elapsed(s, at(20)), const Duration(minutes: 15));
      expect(endTime(s), at(30));
    });

    test('restante nunca fica negativo', () {
      expect(remaining(session(), at(90)), Duration.zero);
      expect(progress(session(), at(90)), 1);
    });

    test('formatClock arredonda para cima os segundos', () {
      expect(formatClock(const Duration(minutes: 25)), '25:00');
      expect(
        formatClock(const Duration(seconds: 59, milliseconds: 1)),
        '01:00',
      );
      expect(formatClock(const Duration(hours: 1, minutes: 5)), '1:05:00');
      expect(formatClock(Duration.zero), '00:00');
    });
  });

  group('ciclo', () {
    PomodoroSession done(PomodoroKind kind, int hour) => session(
      kind: kind,
      startedAt: DateTime(2026, 11, 23, hour),
      completed: true,
    );

    test('conta focos concluídos desde a última pausa longa', () {
      final sessions = [
        done(PomodoroKind.foco, 8),
        done(PomodoroKind.pausaLonga, 9),
        done(PomodoroKind.foco, 10),
        done(PomodoroKind.pausaCurta, 11),
        done(PomodoroKind.foco, 12),
        session(startedAt: DateTime(2026, 11, 23, 13)), // interrompido
      ];
      expect(focusesSinceLongBreak(sessions), 2);
    });

    test('pausa longa a cada N focos; depois de pausa vem foco', () {
      PomodoroKind afterFocus(int count) => nextKind(
        PomodoroKind.foco,
        focusesSinceLong: count,
        longBreakEvery: 4,
      );
      expect(afterFocus(1), PomodoroKind.pausaCurta);
      expect(afterFocus(3), PomodoroKind.pausaCurta);
      expect(afterFocus(4), PomodoroKind.pausaLonga);
      expect(
        nextKind(
          PomodoroKind.pausaLonga,
          focusesSinceLong: 0,
          longBreakEvery: 4,
        ),
        PomodoroKind.foco,
      );
    });
  });
}
