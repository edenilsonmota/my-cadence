import 'dart:convert';

/// Id de notificação estável derivado de uma chave (o UUID da tarefa).
///
/// FNV-1a de 32 bits reduzido a 31 bits (o plugin exige int positivo de 32
/// bits). Nunca usar `String.hashCode`: ele muda entre execuções do app.
/// Id fixo da notificação de fim do pomodoro (só há uma sessão por vez).
final int pomodoroNotificationId = notificationIdFor('pomodoro');

int notificationIdFor(String key) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(key)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}
