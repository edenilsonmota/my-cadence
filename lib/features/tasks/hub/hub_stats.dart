/// Números das seções do hub da tarefa. Puro, sem Flutter.
library;

import '../../../data/db/database.dart';
import '../../../data/db/enums.dart';
import '../../pomodoro/pomodoro_logic.dart';

/// Ids de [rootId] e de todas as descendentes, a partir da lista de tarefas.
List<String> subtreeIds(Iterable<Task> tasks, String rootId) {
  final childrenOf = <String, List<String>>{};
  for (final task in tasks) {
    if (task.parentId case final parent?) {
      (childrenOf[parent] ??= []).add(task.id);
    }
  }
  final ids = [rootId];
  for (var i = 0; i < ids.length; i++) {
    ids.addAll(childrenOf[ids[i]] ?? const []);
  }
  return ids;
}

class FocusSummary {
  const FocusSummary({
    required this.sessions,
    required this.completed,
    required this.total,
  });

  /// Sessões de foco (inclui interrompidas e a em andamento).
  final int sessions;

  /// Sessões de foco que chegaram ao fim (o "realizado" do estimado); o
  /// tempo registrado à mão não conta como pomodoro.
  final int completed;

  /// Tempo efetivo de foco, sem as pausas.
  final Duration total;
}

FocusSummary summarizeFocus(Iterable<PomodoroSession> sessions, DateTime now) {
  var count = 0, completed = 0;
  var total = Duration.zero;
  for (final s in sessions) {
    if (s.kind != PomodoroKind.foco) continue;
    count++;
    if (s.completed && !s.manual) completed++;
    total += elapsed(s, now);
  }
  return FocusSummary(sessions: count, completed: completed, total: total);
}

/// "1 h 05 min", "25 min", "0 min".
String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours == 0) return '$minutes min';
  return '$hours h ${minutes.toString().padLeft(2, '0')} min';
}

class CardCounts {
  const CardCounts({required this.total, required this.due});

  final int total;

  /// Não suspensos com vencimento até agora.
  final int due;
}

CardCounts countCards(Iterable<Flashcard> cards, DateTime now) {
  var total = 0, due = 0;
  for (final card in cards) {
    total++;
    if (!card.suspended && !card.due.isAfter(now)) due++;
  }
  return CardCounts(total: total, due: due);
}
