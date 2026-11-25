import 'dart:convert';

/// Id de notificação estável derivado de uma chave (o UUID da tarefa).
///
/// FNV-1a de 32 bits reduzido a 31 bits (o plugin exige int positivo de 32
/// bits). Nunca usar `String.hashCode`: ele muda entre execuções do app.
/// Id fixo da notificação de fim do pomodoro (só há uma sessão por vez).
final int pomodoroNotificationId = notificationIdFor('pomodoro');

/// Ids fixos dos avisos diários opcionais (revisão de cards e resumo do dia).
final int dailyReviewNotificationId = notificationIdFor('daily:review');
final int dailySummaryNotificationId = notificationIdFor('daily:summary');

/// Id estável para um lembrete de tarefa com antecedência [minutesBefore].
/// Quando [primary] é `true` (primeiro lembrete / compatibilidade), usa
/// `notificationIdFor(taskId)`; os demais derivam de `$taskId:r:$minutesBefore`.
int taskReminderNotificationId(
  String taskId,
  int minutesBefore, {
  bool primary = false,
}) => primary
    ? notificationIdFor(taskId)
    : notificationIdFor('$taskId:r:$minutesBefore');

/// Id estável para a repetição [step] (1..N) de "Insistir se atrasar".
int taskNagNotificationId(String taskId, int step) =>
    notificationIdFor('$taskId:nag:$step');

int notificationIdFor(String key) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(key)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}
