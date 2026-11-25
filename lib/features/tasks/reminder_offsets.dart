/// Múltiplos lembretes por tarefa (antecedências em minutos) e insistência.
/// Puro, sem Flutter.
library;

import '../../data/db/database.dart';

/// Opções de antecedência disponíveis no formulário (minutos antes; 0 = na hora).
const reminderOffsetChoices = <int>[0, 5, 10, 15, 30, 60, 1440];

/// Opções de intervalo para "Insistir se atrasar" (minutos; `null` = desligado).
const nagIntervalChoices = <int?>[null, 5, 10, 15, 30];

/// Quantas repetições no máximo o modo "Insistir se atrasar" agenda após o
/// horário da tarefa.
const maxNagRepeats = 5;

/// Interpreta a lista serializada (`"0,15,1440"`), ordenando em ordem crescente
/// e descartando inválidos/negativos/duplicados.
List<int> parseReminderOffsets(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final set = <int>{};
  for (final part in raw.split(',')) {
    final value = int.tryParse(part.trim());
    if (value != null && value >= 0) set.add(value);
  }
  final sorted = set.toList()..sort();
  return List<int>.unmodifiable(sorted);
}

/// Serializa uma lista de antecedências; devolve `null` se vazia.
String? encodeReminderOffsets(Iterable<int> offsets) {
  final set = {
    for (final v in offsets)
      if (v >= 0) v,
  };
  if (set.isEmpty) return null;
  final sorted = set.toList()..sort();
  return sorted.join(',');
}

/// Lista efetiva de antecedências de uma [Task], combinando a coluna nova
/// (`reminderOffsets`) com o legado (`reminderMinutesBefore`).
List<int> effectiveReminderOffsets(Task task) {
  final fromList = parseReminderOffsets(task.reminderOffsets);
  if (fromList.isNotEmpty) return fromList;
  final single = task.reminderMinutesBefore;
  if (single != null && single >= 0) return [single];
  return const [];
}

/// Normaliza o intervalo de insistência; `null` ou <= 0 desliga.
int? normalizeNagInterval(int? minutes) =>
    minutes == null || minutes <= 0 ? null : minutes;
