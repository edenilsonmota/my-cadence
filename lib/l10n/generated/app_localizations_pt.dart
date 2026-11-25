// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'My Cadence';

  @override
  String get navToday => 'Hoje';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navReview => 'Revisar';

  @override
  String get navBooks => 'Books';

  @override
  String get navPomodoro => 'Pomodoro';

  @override
  String get navStats => 'Métricas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navComponents => 'Componentes';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionCreate => 'Criar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionUndo => 'Desfazer';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionSearch => 'Buscar';

  @override
  String get actionComplete => 'Concluir';

  @override
  String get actionReopen => 'Reabrir';

  @override
  String get actionDismiss => 'Dispensar';

  @override
  String get actionChange => 'Trocar';

  @override
  String get actionDownload => 'Baixar';

  @override
  String get actionMoreOptions => 'Mais opções';

  @override
  String get actionDecrease => 'Diminuir';

  @override
  String get actionIncrease => 'Aumentar';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeAutomatic => 'Automático';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsColor => 'Cor';

  @override
  String get accentBlue => 'Azul';

  @override
  String get accentYellow => 'Amarelo';

  @override
  String get accentPink => 'Rosa';

  @override
  String get accentViolet => 'Violeta';

  @override
  String get accentOrange => 'Laranja';

  @override
  String get accentGreen => 'Verde';

  @override
  String get settingsLightsOut => 'Lights out (alto contraste)';

  @override
  String get settingsLightsOutHintDark =>
      'Preto puro (OLED) e texto em alto contraste no modo escuro';

  @override
  String get settingsLightsOutHintLight =>
      'Usado no modo escuro ou automático (preto puro e alto contraste)';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageAutomatic => 'Automático (celular)';

  @override
  String get settingsNavBar => 'Barra de navegação';

  @override
  String get navBarPreview => 'Prévia';

  @override
  String navBarPreviewDetail(int count, int max) {
    return '$count de $max abas';
  }

  @override
  String get navBarHelper =>
      'A primeira aba abre com o app. As telas fora da barra continuam no menu lateral.';

  @override
  String get navBarInBar => 'Na barra';

  @override
  String get navBarDragToOrder => 'Arraste para ordenar';

  @override
  String get navBarInDrawer => 'No menu lateral';

  @override
  String get navBarInitialTab => 'Aba inicial';

  @override
  String navBarInitialTabMin(int min) {
    return 'Aba inicial · mínimo de $min abas';
  }

  @override
  String navBarMinLimit(int min) {
    return 'Mínimo de $min abas na barra';
  }

  @override
  String navBarMaxLimit(int max) {
    return 'Máximo de $max abas atingido';
  }

  @override
  String get navBarDrawerHint => 'Acessível pelo menu lateral';

  @override
  String get navBarRestoreDefault => 'Restaurar padrão';

  @override
  String navBarDragSemantics(String label) {
    return 'Arrastar $label';
  }

  @override
  String get settingsFlashcards => 'Flashcards';

  @override
  String get settingsNewCardsPerDay => 'Cards novos por dia';

  @override
  String get settingsDesiredRetention => 'Retenção desejada';

  @override
  String settingsDesiredRetentionHint(int percent) {
    return '$percent%: mais alta = revisões mais frequentes';
  }

  @override
  String get settingsDesiredRetentionSemantics =>
      'Retenção desejada em porcentagem';

  @override
  String get settingsPomodoro => 'Pomodoro';

  @override
  String get settingsFocusMinutes => 'Foco (min)';

  @override
  String get settingsShortBreakMinutes => 'Pausa curta (min)';

  @override
  String get settingsLongBreakMinutes => 'Pausa longa (min)';

  @override
  String get settingsLongBreakEvery => 'Pausa longa a cada';

  @override
  String settingsLongBreakEveryDetail(int count) {
    return '$count focos';
  }

  @override
  String get settingsLongBreakEverySemantics => 'Focos até a pausa longa';

  @override
  String get settingsAutoStartBreaks => 'Iniciar pausas sozinho';

  @override
  String get settingsAutoStartBreaksHint =>
      'Ao fim do foco, a pausa começa automaticamente';

  @override
  String get settingsSoundOnEnd => 'Som ao terminar';

  @override
  String get settingsVibrateOnEnd => 'Vibrar ao terminar';

  @override
  String get settingsKeepScreenOn => 'Manter a tela ligada';

  @override
  String get settingsKeepScreenOnHint =>
      'Enquanto a tela do pomodoro estiver aberta';

  @override
  String get settingsTasks => 'Tarefas';

  @override
  String get settingsAllDayReminder => 'Lembrete de dia inteiro';

  @override
  String settingsAllDayReminderHint(int hour) {
    return 'Tarefas sem hora lembram às ${hour}h (menos a antecedência escolhida)';
  }

  @override
  String get settingsAllDayReminderSemantics =>
      'Hora do lembrete de dia inteiro';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsExportJson => 'Exportar JSON';

  @override
  String get settingsExportJsonHint => 'Todos os dados num arquivo';

  @override
  String get settingsImportJson => 'Importar JSON';

  @override
  String get settingsImportJsonHint =>
      'Mesclar ou substituir pelos dados de um backup';

  @override
  String get settingsUpdates => 'Atualizações';

  @override
  String updateVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get updateIdle => 'Toque para procurar uma versão nova';

  @override
  String get updateChecking => 'Verificando…';

  @override
  String get updateUpToDate => 'Você está na versão mais recente';

  @override
  String updateAvailable(String version) {
    return 'Versão $version disponível';
  }

  @override
  String get updateError => 'Não foi possível verificar. Tente de novo.';

  @override
  String get todayEmpty => 'Nada para hoje ainda.';

  @override
  String get todayOverdue => 'Atrasadas';

  @override
  String get todayUndated => 'Sem data';

  @override
  String get tasksLoadError => 'Não foi possível carregar as tarefas.';

  @override
  String get tasksNew => 'Nova tarefa';

  @override
  String get tasksCreate => 'Criar tarefa';

  @override
  String get tasksNewSubtask => 'Nova subtarefa';

  @override
  String get tasksEdit => 'Editar tarefa';

  @override
  String get tasksAdd => 'Adicionar tarefa';

  @override
  String get tasksSearchHint => 'Buscar pelo título';

  @override
  String get tasksCloseSearch => 'Fechar busca';

  @override
  String get tasksFilterAndSort => 'Filtrar e ordenar';

  @override
  String get tasksEmpty => 'Nenhuma tarefa ainda.';

  @override
  String get tasksNoMatches => 'Nenhuma tarefa com esses filtros.';

  @override
  String get tasksClearFilters => 'Limpar filtros';

  @override
  String tasksCreated(String title) {
    return 'Criada: $title';
  }

  @override
  String get taskKindSimple => 'Simples';

  @override
  String get taskKindStudy => 'Estudo';

  @override
  String get taskKindRoutine => 'Rotina';

  @override
  String get taskKindEvent => 'Evento';

  @override
  String get taskStatusTodo => 'A fazer';

  @override
  String get taskStatusDoing => 'Fazendo';

  @override
  String get taskStatusDone => 'Feita';

  @override
  String get priorityNone => 'Nenhuma';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get reminderModeNotification => 'Notificação';

  @override
  String get reminderModeAlarm => 'Alarme';

  @override
  String get reminderModeNotificationHint =>
      'Aviso discreto na barra de notificações.';

  @override
  String get reminderModeAlarmHint =>
      'Toca como despertador (mesmo no silencioso) até você interagir.';

  @override
  String get reminderFullScreenBanner =>
      'Para abrir na tela bloqueada, permita notificações em tela cheia nas configurações do Android.';

  @override
  String get reminderAllowFullScreen => 'Permitir tela cheia';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldNotes => 'Notas';

  @override
  String get fieldType => 'Tipo';

  @override
  String get fieldPriority => 'Prioridade';

  @override
  String get fieldDates => 'Datas';

  @override
  String get fieldAllDay => 'Dia inteiro';

  @override
  String get fieldStart => 'Início';

  @override
  String get fieldDue => 'Prazo';

  @override
  String get fieldNoDate => 'Sem data';

  @override
  String get fieldDate => 'Data';

  @override
  String get fieldRepeat => 'Repetir';

  @override
  String get repeatNo => 'Não';

  @override
  String get repeatDaily => 'Diária';

  @override
  String get repeatWeekly => 'Semanal';

  @override
  String get repeatEvery => 'A cada';

  @override
  String get repeatUntil => 'Até';

  @override
  String get repeatNoEnd => 'Sem fim';

  @override
  String get fieldAlarm => 'Alarme';

  @override
  String get fieldReminder => 'Lembrete';

  @override
  String get alarmNeedDue => 'Defina um prazo para usar alarme.';

  @override
  String get reminderNone => 'Nenhum';

  @override
  String get reminderAtTime => 'Na hora';

  @override
  String get reminder5Min => '5 min antes';

  @override
  String get reminder10Min => '10 min antes';

  @override
  String get reminder15Min => '15 min antes';

  @override
  String get reminder30Min => '30 min antes';

  @override
  String get reminder1Hour => '1 hora antes';

  @override
  String get reminder1Day => '1 dia antes';

  @override
  String get fieldEstimatedPomodoros => 'Pomodoros estimados';

  @override
  String get fieldTags => 'Tags';

  @override
  String get tagNew => 'Nova tag';

  @override
  String get fieldIconAndColor => 'Ícone e cor';

  @override
  String get appearanceCustom => 'Personalizado';

  @override
  String get appearanceDefault => 'Padrão';

  @override
  String get appearanceTapToChange => 'Toque para trocar';

  @override
  String get appearanceInherited => 'Herda da tarefa mãe, da tag ou do tipo';

  @override
  String get quickDateToday => 'Hoje';

  @override
  String get quickDateTomorrow => 'Amanhã';

  @override
  String get quickDateNextWeek => 'Daqui a uma semana';

  @override
  String get pomodoroFocus => 'Foco';

  @override
  String get pomodoroShortBreak => 'Pausa curta';

  @override
  String get pomodoroLongBreak => 'Pausa longa';

  @override
  String get pomodoroStart => 'Iniciar';

  @override
  String get pomodoroPause => 'Pausar';

  @override
  String get pomodoroResume => 'Retomar';

  @override
  String get pomodoroStop => 'Parar';

  @override
  String get pomodoroNoTask => 'Sem tarefa';

  @override
  String get pomodoroLinkedTask => 'Tarefa vinculada';

  @override
  String get pomodoroPickTask => 'Tarefa do foco';

  @override
  String get pomodoroPausedSuffix => 'pausado';

  @override
  String get pomodoroFocusDone => 'Foco concluído!';

  @override
  String get pomodoroFocusDoneShort => 'Foco concluído';

  @override
  String pomodoroBreakDone(String kind) {
    return '$kind concluída';
  }

  @override
  String pomodoroNextRunning(String kind) {
    return '$kind em andamento';
  }

  @override
  String pomodoroNextLabel(String kind) {
    return 'Próximo: $kind';
  }

  @override
  String pomodoroStartNext(String kind) {
    return 'Iniciar $kind';
  }

  @override
  String pomodoroCompleteTask(String title) {
    return 'Concluir \"$title\"';
  }

  @override
  String get pomodoroCycleProgress => 'Progresso do ciclo';

  @override
  String get agendaGoToday => 'Ir para hoje';

  @override
  String get agendaGoToDate => 'Ir para a data';

  @override
  String get agendaView => 'Visualização';

  @override
  String get agendaDay => 'Dia';

  @override
  String get agendaWeek => 'Semana';

  @override
  String get agenda3Days => '3 dias';

  @override
  String get agendaMonth => 'Mês';

  @override
  String get agendaCompletedPomodoros => 'Pomodoros realizados';

  @override
  String get reviewNewDeck => 'Novo deck';

  @override
  String get reviewImportCsv => 'Importar CSV';

  @override
  String get reviewNewCard => 'Novo card';

  @override
  String get reviewLoadError => 'Não foi possível carregar os cards.';

  @override
  String get reviewEmpty =>
      'Nenhum card criado.\nCrie um no + ou importe um CSV.';

  @override
  String get reviewNow => 'Revisar agora';

  @override
  String get reviewAllCards => 'Todos os cards';

  @override
  String get reviewDecks => 'Decks';

  @override
  String get reviewNameLabel => 'Nome';

  @override
  String get booksImportMarkdown => 'Importar Markdown';

  @override
  String get booksNew => 'Novo book';

  @override
  String get booksLoadError => 'Não foi possível carregar os books.';

  @override
  String get booksEmpty =>
      'Nenhum book criado.\nCrie um no + ou importe arquivos .md.';

  @override
  String get statsFocusTime => 'Tempo de foco';

  @override
  String get statsThisWeek => 'Esta semana';

  @override
  String get statsThisMonth => 'Este mês';

  @override
  String get statsDays => 'Dias';

  @override
  String get statsWeeks => 'Semanas';

  @override
  String get statsMonths => 'Meses';

  @override
  String get statsNoFocusInPeriod => 'Nenhum foco registrado nestes períodos.';

  @override
  String get statsStartFocus => 'Iniciar foco';

  @override
  String get statsFocusBy => 'Foco por';

  @override
  String get statsGroupTask => 'Tarefa';

  @override
  String get statsGroupTag => 'Tag';

  @override
  String get statsGroupType => 'Tipo';

  @override
  String get statsNoFocusGroup => 'Nenhum foco no período.';

  @override
  String get statsEstimatedVsDone => 'Pomodoros: estimado × realizado';

  @override
  String get statsNoEstimated => 'Nenhuma tarefa com pomodoros estimados.';

  @override
  String get statsReviews => 'Revisões';

  @override
  String get statsAccuracy30Days => 'Acerto (30 dias)';

  @override
  String get statsStreakDay => 'Dia seguido';

  @override
  String get statsStreakDays => 'Dias seguidos';

  @override
  String get statsReviewsPerDay => 'Revisões por dia';

  @override
  String get statsNoReviews14Days => 'Nenhuma revisão nos últimos 14 dias.';

  @override
  String get statsDueNext7Days => 'Cards a vencer nos próximos 7 dias';

  @override
  String get statsNoDueThisWeek => 'Nenhum card a vencer nesta semana.';

  @override
  String get statsRoutinesDone => 'Rotinas concluídas';

  @override
  String get statsLess => 'menos';

  @override
  String get statsMore => 'mais';

  @override
  String get accountTooltip => 'Conta e sincronização';

  @override
  String get accountSyncing => 'Sincronizando';

  @override
  String get accountOffline => 'Sem conexão: sincroniza depois';

  @override
  String get accountPending => 'Alterações a sincronizar';

  @override
  String get accountError => 'Erro na sincronização';

  @override
  String get accountSynced => 'Sincronizado';

  @override
  String get actionClear => 'Limpar';

  @override
  String get actionBack => 'Voltar';

  @override
  String get actionAdd => 'Adicionar';

  @override
  String get actionRename => 'Renomear';

  @override
  String get actionDrag => 'Arrastar';

  @override
  String get tasksEmptyCreated => 'Nenhuma tarefa criada.';

  @override
  String get tasksExpandSubtasks => 'Mostrar subtarefas';

  @override
  String get tasksCollapseSubtasks => 'Recolher subtarefas';

  @override
  String get tasksSortBy => 'Ordenar por';

  @override
  String get tasksSortManual => 'Manual';

  @override
  String get tasksSortDue => 'Prazo';

  @override
  String get tasksSortPriority => 'Prioridade';

  @override
  String get tasksSortNewest => 'Mais recentes';

  @override
  String get tasksSortTitle => 'Título';

  @override
  String get fieldStatus => 'Status';

  @override
  String get taskTagSingle => 'Tag';

  @override
  String taskTagCount(int count) {
    return '$count tags';
  }

  @override
  String get taskLoadOneError => 'Não foi possível carregar a tarefa.';

  @override
  String get taskNotFound => 'Tarefa não encontrada.';

  @override
  String get taskSingular => 'Tarefa';

  @override
  String get subtaskSingular => 'Subtarefa';

  @override
  String subtaskOf(String title) {
    return 'Subtarefa de $title';
  }

  @override
  String get taskChangeStatus => 'Mudar status';

  @override
  String taskPriorityBadge(String label) {
    return 'Prioridade $label';
  }

  @override
  String get fieldRecurrence => 'Repetição';

  @override
  String get subtasksSection => 'Subtarefas';

  @override
  String get subtasksAddHint => 'Adicionar subtarefa';

  @override
  String get routineHistory => 'Histórico';

  @override
  String get routineNoStreak => 'Nenhuma sequência em andamento';

  @override
  String get routineNotCompletedYet => 'Ainda não concluída';

  @override
  String routineTotalCompletions(int count, String unit) {
    return '$count $unit no total';
  }

  @override
  String routineStreakDays(int count, String unit) {
    return '$count $unit';
  }

  @override
  String get routineDaySingular => 'dia seguido';

  @override
  String get routineDayPlural => 'dias seguidos';

  @override
  String get routineTimeSingular => 'vez seguida';

  @override
  String get routineTimePlural => 'vezes seguidas';

  @override
  String get routineEnded => 'Rotina encerrada: era a última ocorrência.';

  @override
  String routineNext(String when) {
    return 'Rotina concluída. Próxima: $when.';
  }

  @override
  String taskDeleted(String title) {
    return '\"$title\" excluída';
  }

  @override
  String taskDeletedWithSubtasks(String title, int count) {
    return '\"$title\" e $count subtarefa(s) excluídas';
  }

  @override
  String get repeatIntervalSemantics => 'Intervalo da repetição';

  @override
  String get unitDay => 'dia';

  @override
  String get unitDays => 'dias';

  @override
  String get unitWeek => 'semana';

  @override
  String get unitWeeks => 'semanas';

  @override
  String fieldClearLabel(String label) {
    return 'Limpar $label';
  }

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes min antes';
  }

  @override
  String get hubAdd => 'ADICIONAR';

  @override
  String get hubFlashcard => 'Flashcard';

  @override
  String get hubPage => 'Página';

  @override
  String get hubPages => 'Páginas';

  @override
  String get hubNewPage => 'Nova página';

  @override
  String get hubNoCardsYet => 'Nenhum card ainda';

  @override
  String get hubReviewTask => 'Revisar desta tarefa';

  @override
  String get hubCard => 'Card';

  @override
  String hubFocusTimeValue(String duration) {
    return 'Tempo de foco: $duration';
  }

  @override
  String get hubNoSessionsYet => 'Nenhuma sessão ainda';

  @override
  String hubFocusSessions(int count, String unit) {
    return '$count $unit de foco (inclui subtarefas)';
  }

  @override
  String get unitSession => 'sessão';

  @override
  String get unitSessions => 'sessões';

  @override
  String get hubNoPagesYet => 'Nenhuma página ainda';

  @override
  String get hubUnlink => 'Desvincular';

  @override
  String get hubOpenNotebook => 'Abrir caderno';

  @override
  String get hubLinkExistingPage => 'Vincular página existente';

  @override
  String get hubLinkPage => 'Vincular página';

  @override
  String get hubNoBookPages => 'Nenhuma página em books ainda.';

  @override
  String get hubNoBookPagesHint =>
      'Crie páginas na aba Books para vinculá-las.';

  @override
  String hubEstimatedVsDone(int done, int estimated) {
    return 'Estimado × realizado: $done de $estimated';
  }

  @override
  String agendaNextTaskIn(String wait) {
    return 'Próxima tarefa em $wait';
  }

  @override
  String get agendaSearchTask => 'Buscar tarefa';

  @override
  String get agendaNoDatedTasks => 'Nenhuma tarefa com data encontrada.';

  @override
  String get agendaAllDayShort => 'dia\ninteiro';

  @override
  String get agendaExpandAllDay => 'Expandir dia inteiro';

  @override
  String get agendaCollapseAllDay => 'Recolher dia inteiro';

  @override
  String get agendaRoutineRescheduled =>
      'Rotina reagendada (todas as ocorrências).';

  @override
  String get reviewEmptyAction => 'Criar deck';

  @override
  String get reviewEmptyAlt =>
      'Nenhum card ainda.\nCrie um card no + ou importe um CSV.';

  @override
  String get reviewNothingDue => 'Nada para revisar agora';

  @override
  String reviewDueNow(int count) {
    return '$count para revisar agora';
  }

  @override
  String reviewNextIn(int minutes) {
    return 'Próximo card em $minutes min.';
  }

  @override
  String get reviewAll => 'Revisar tudo';

  @override
  String reviewDeckDueSuffix(int count) {
    return '$count para revisar';
  }

  @override
  String get reviewSessionTitle => 'Revisão';

  @override
  String get reviewUndoLast => 'Desfazer última avaliação';

  @override
  String get reviewProgressSemantics => 'Progresso da sessão';

  @override
  String get reviewShowAnswer => 'Mostrar resposta';

  @override
  String get reviewCardNew => 'novo';

  @override
  String get reviewGradeAgain => 'Errei';

  @override
  String get reviewGradeHard => 'Difícil';

  @override
  String get reviewGradeGood => 'Bom';

  @override
  String get reviewGradeEasy => 'Fácil';

  @override
  String reviewNextCardSoon(int minutes) {
    return 'Próximo card em $minutes min.\nEle aparece aqui sozinho.';
  }

  @override
  String get reviewNothingDueDot => 'Nada para revisar agora.';

  @override
  String reviewAllDone(int count, String unit) {
    return 'Tudo revisado por agora! $count $unit nesta sessão.';
  }

  @override
  String get unitCard => 'card';

  @override
  String get unitCards => 'cards';

  @override
  String get reviewRemainingSingular => 'card restante';

  @override
  String get reviewRemainingPlural => 'cards restantes';

  @override
  String get booksOptions => 'Opções do book';

  @override
  String get booksExportZip => 'Exportar (.zip)';

  @override
  String booksDeleteTitle(String title) {
    return 'Excluir \"$title\"?';
  }

  @override
  String get booksDeleteMessage => 'Todas as páginas do book serão excluídas.';

  @override
  String statsSameAs(String period) {
    return 'igual a $period';
  }

  @override
  String statsVs(String delta, String period) {
    return '$delta vs $period';
  }

  @override
  String get statsYesterday => 'ontem';

  @override
  String get statsPrevious => 'anterior';

  @override
  String statsFocusHoursPer(String unit) {
    return 'Horas de foco por $unit';
  }

  @override
  String get statsUnitDay => 'dia';

  @override
  String get statsUnitWeek => 'semana';

  @override
  String get statsUnitMonth => 'mês';

  @override
  String get statsFocusChartSemantics => 'Gráfico de horas de foco';

  @override
  String get statsDeletedTask => 'Tarefa excluída';

  @override
  String get statsNoTag => 'Sem tag';

  @override
  String get statsDeletedTag => 'Tag excluída';

  @override
  String statsOf(int done, int total) {
    return '$done de $total';
  }

  @override
  String get statsReviewsChartSemantics => 'Gráfico de revisões por dia';

  @override
  String get statsDueChartSemantics => 'Gráfico de cards a vencer';

  @override
  String get statsTodayLower => 'hoje';

  @override
  String get statsTodayWithOverdue => 'Hoje (com atrasados)';

  @override
  String get statsUnitReview => 'revisão';

  @override
  String get statsUnitReviews => 'revisões';

  @override
  String statsRoutineTotal(int count, String unit, int weeks) {
    return '$count $unit nas últimas $weeks semanas';
  }

  @override
  String get unitCompletion => 'conclusão';

  @override
  String get unitCompletions => 'conclusões';

  @override
  String statsWeekOf(String date) {
    return 'Semana de $date';
  }

  @override
  String get settingsAlarmDiagnostics => 'Diagnóstico de alarmes';

  @override
  String get settingsAlarmDiagnosticsOk => 'Tudo certo para tocar';

  @override
  String settingsAlarmDiagnosticsIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajustes recomendados',
      one: '1 ajuste recomendado',
    );
    return '$_temp0';
  }

  @override
  String get diagnosticsRefresh => 'Verificar novamente';

  @override
  String get diagnosticsOpenSettings => 'Abrir ajustes';

  @override
  String get diagnosticsStatusOk => 'Ativo';

  @override
  String get diagnosticsStatusIssue => 'Atenção';

  @override
  String get diagnosticsSummaryOk =>
      'O aparelho está configurado para entregar seus lembretes e alarmes no horário.';

  @override
  String get diagnosticsSummaryIssues =>
      'Alguns ajustes do Android podem impedir ou atrasar seus lembretes.';

  @override
  String get diagNotificationsTitle => 'Notificações do app';

  @override
  String get diagNotificationsOk => 'Permitidas pelo Android.';

  @override
  String get diagNotificationsOff =>
      'Estão desligadas — nenhum lembrete ou alarme vai aparecer.';

  @override
  String get diagRemindersChannelTitle => 'Canal de lembretes';

  @override
  String get diagRemindersChannelOk => 'Som e avisos habilitados.';

  @override
  String get diagRemindersChannelMuted =>
      'O canal está silenciado — notificações comuns não vão tocar.';

  @override
  String get diagAlarmsChannelTitle => 'Canal de alarmes';

  @override
  String get diagAlarmsChannelOk => 'Canal de despertador habilitado.';

  @override
  String get diagAlarmsChannelMuted =>
      'O canal está silenciado — tarefas em modo Alarme não vão tocar.';

  @override
  String get diagExactAlarmsTitle => 'Alarmes exatos';

  @override
  String get diagExactAlarmsOk => 'O app pode agendar no minuto exato.';

  @override
  String get diagExactAlarmsDenied =>
      'Negado — lembretes podem atrasar ou falhar.';

  @override
  String get diagFullScreenTitle => 'Alarmes em tela cheia';

  @override
  String get diagFullScreenOk => 'Pode abrir sobre a tela bloqueada.';

  @override
  String get diagFullScreenDenied =>
      'Sem permissão — o alarme pode não aparecer na tela bloqueada.';

  @override
  String get diagBatteryTitle => 'Otimização de bateria';

  @override
  String get diagBatteryOk => 'Sem restrições em segundo plano.';

  @override
  String get diagBatteryRestricted =>
      'Com restrição — aparelhos (ex.: \"apps em suspensão\" da Samsung) podem atrasar alarmes.';

  @override
  String get formDiagnosticsWarning =>
      'Este lembrete pode não tocar: confira as permissões de notificação e alarme.';

  @override
  String get formDiagnosticsAction => 'Ver diagnóstico';

  @override
  String get actionSnooze => 'Adiar';

  @override
  String get snooze10Min => '10 min';

  @override
  String get snooze1Hour => '1 h';

  @override
  String snoozeTomorrowMorning(String time) {
    return 'Amanhã cedo ($time)';
  }

  @override
  String snoozedUntil(String when) {
    return 'Lembrete adiado para $when.';
  }

  @override
  String get settingsDailyReminders => 'Avisos diários';

  @override
  String get settingsDailySummary => 'Resumo diário de tarefas';

  @override
  String settingsDailySummaryHint(int hour) {
    return 'Avisa sobre tarefas de hoje e atrasadas às ${hour}h';
  }

  @override
  String get settingsDailySummaryOffHint =>
      'Receba um resumo diário de tarefas pendentes';

  @override
  String get settingsDailySummaryHourSemantics =>
      'Hora do resumo diário de tarefas';

  @override
  String get settingsDailyReview => 'Aviso diário de flashcards';

  @override
  String settingsDailyReviewHint(int hour) {
    return 'Lembra às ${hour}h quando houver cards para revisar';
  }

  @override
  String get settingsDailyReviewOffHint =>
      'Avisa quando houver cards vencidos (não avisa com zero)';

  @override
  String get settingsDailyReviewHourSemantics =>
      'Hora do aviso diário de flashcards';

  @override
  String get settingsHourLabel => 'Horário (h)';

  @override
  String get fieldReminders => 'Lembretes';

  @override
  String get remindersHelperMultiple =>
      'Escolha um ou mais horários para lembrar.';

  @override
  String get fieldNagIfOverdue => 'Insistir se atrasar';

  @override
  String get nagOff => 'Não';

  @override
  String nagEveryMinutes(int minutes) {
    return 'A cada $minutes min';
  }

  @override
  String nagHint(int max) {
    return 'Repete até $max× após o horário enquanto a tarefa não for concluída.';
  }

  @override
  String nagHubDetail(int minutes, int max) {
    return 'A cada $minutes min (até $max×)';
  }
}
