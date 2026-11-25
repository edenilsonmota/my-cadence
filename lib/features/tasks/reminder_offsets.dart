/// Múltiplos lembretes por tarefa (antecedências em minutos) e insistência.
/// Puro, sem Flutter.
library;

import '../../data/db/database.dart';

/// Antecedências oferecidas para tarefa com hora (minutos antes do início
/// ou do prazo; 0 = na hora).
const timedReminderChoices = <int>[0, 5, 10, 15, 30, 60, 1440];

/// Antecedências oferecidas para tarefa de dia inteiro, que lembra na hora
/// do ajuste (`tasks.allDayReminderHour`): no dia, 1 e 2 dias antes, 1 semana.
const allDayReminderChoices = <int>[0, 1440, 2880, 10080];

/// Opções do formulário: as do modo atual mais as que já estão escolhidas
/// (lembretes antigos fora da lista continuam visíveis para desmarcar).
List<int> reminderChoicesFor({
  required bool allDay,
  Iterable<int> selected = const [],
}) {
  final base = allDay ? allDayReminderChoices : timedReminderChoices;
  return ({...base, ...selected}.toList()..sort());
}

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
