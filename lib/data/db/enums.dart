// Enums persistidos com `textEnum` (o banco guarda o nome do valor).
// Renomear um valor exige migração; reordenar ou acrescentar é seguro.

enum TaskKind { simples, estudo, rotina, evento }

enum TaskStatus { aFazer, fazendo, feita }

enum PomodoroKind { foco, pausaCurta, pausaLonga }

/// Espelha `fsrs.State` (pacote fsrs 2.x). Card novo começa em [learning].
enum CardState { learning, review, relearning }
