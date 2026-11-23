import 'package:flutter/material.dart';

import '../../data/db/enums.dart';

extension TaskKindLabel on TaskKind {
  String get label => switch (this) {
    TaskKind.simples => 'Simples',
    TaskKind.estudo => 'Estudo',
    TaskKind.rotina => 'Rotina',
    TaskKind.evento => 'Evento',
  };

  IconData get icon => switch (this) {
    TaskKind.simples => Icons.check_box_outlined,
    TaskKind.estudo => Icons.school_outlined,
    TaskKind.rotina => Icons.repeat,
    TaskKind.evento => Icons.event_outlined,
  };
}

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
    TaskStatus.aFazer => 'A fazer',
    TaskStatus.fazendo => 'Fazendo',
    TaskStatus.feita => 'Feita',
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

/// Paleta das tags (ARGB), escolhida para funcionar nos temas claro e escuro.
const tagPalette = [
  0xFF1E88E5,
  0xFF43A047,
  0xFFF4511E,
  0xFF8E24AA,
  0xFFFDD835,
  0xFF00ACC1,
  0xFFD81B60,
  0xFF6D4C41,
];
