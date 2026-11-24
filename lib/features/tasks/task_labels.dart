import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../data/db/enums.dart';

extension TaskKindLabel on TaskKind {
  String get label => switch (this) {
    TaskKind.simples => 'Simples',
    TaskKind.estudo => 'Estudo',
    TaskKind.rotina => 'Rotina',
    TaskKind.evento => 'Evento',
  };

  IconData get icon => AppIcons.kind(this);
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
