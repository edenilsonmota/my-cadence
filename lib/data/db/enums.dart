// Enums persistidos com `textEnum` (o banco guarda o nome do valor).
// Renomear um valor exige migração; reordenar ou acrescentar é seguro.

/// Legado (até a v1.3): a interface não usa mais o tipo; tarefas novas ficam
/// `simples`. A coluna continua para não quebrar dados e sync antigos.
enum TaskKind { simples, estudo, rotina, evento }

/// [pausada] = em espera: some do Hoje, dos atrasados e dos lembretes até
/// voltar para "a fazer".
enum TaskStatus {
  aFazer,
  fazendo,
  feita,
  pausada;

  /// Conta no Hoje, nos atrasados, nos lembretes e nos widgets.
  bool get isActive => this == aFazer || this == fazendo;
}

enum PomodoroKind { foco, pausaCurta, pausaLonga }

/// Espelha `fsrs.State` (pacote fsrs 2.x). Card novo começa em [learning].
enum CardState { learning, review, relearning }

/// Como o lembrete da tarefa avisa: notificação comum ou alarme insistente.
enum ReminderMode { notificacao, alarme }
