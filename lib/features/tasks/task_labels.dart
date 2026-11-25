import 'package:flutter/material.dart';

import '../../data/db/enums.dart';

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
    TaskStatus.aFazer => 'A fazer',
    TaskStatus.fazendo => 'Fazendo',
    TaskStatus.feita => 'Feita',
    TaskStatus.pausada => 'Pausada',
  };
}

extension ReminderModeLabel on ReminderMode {
  String get label => switch (this) {
    ReminderMode.notificacao => 'Notificação',
    ReminderMode.alarme => 'Alarme',
  };
}

const priorityLabels = ['Nenhuma', 'Baixa', 'Média', 'Alta'];

/// Cor da prioridade (nula para "nenhuma").
Color? priorityColor(int priority, ColorScheme colors) => switch (priority) {
  3 => colors.error,
  2 => colors.tertiary,
  1 => colors.primary,
  _ => null,
};
