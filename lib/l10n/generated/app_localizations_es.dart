// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'My Cadence';

  @override
  String get navToday => 'Hoy';

  @override
  String get navTasks => 'Tareas';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navReview => 'Repasar';

  @override
  String get navBooks => 'Libros';

  @override
  String get navPomodoro => 'Pomodoro';

  @override
  String get navStats => 'Métricas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navComponents => 'Componentes';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionCreate => 'Crear';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionSearch => 'Buscar';

  @override
  String get actionComplete => 'Completar';

  @override
  String get actionReopen => 'Reabrir';

  @override
  String get actionDismiss => 'Descartar';

  @override
  String get actionChange => 'Cambiar';

  @override
  String get actionDownload => 'Descargar';

  @override
  String get actionMoreOptions => 'Más opciones';

  @override
  String get actionDecrease => 'Disminuir';

  @override
  String get actionIncrease => 'Aumentar';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeAutomatic => 'Automático';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsColor => 'Color';

  @override
  String get accentBlue => 'Azul hielo';

  @override
  String get accentYellow => 'Dorado';

  @override
  String get accentPink => 'Rosa';

  @override
  String get accentViolet => 'Lavanda';

  @override
  String get accentOrange => 'Coral';

  @override
  String get accentGreen => 'Menta';

  @override
  String get settingsLightsOut => 'Lights out (alto contraste)';

  @override
  String get settingsLightsOutHintDark =>
      'Negro puro (OLED) y texto en alto contraste en modo oscuro';

  @override
  String get settingsLightsOutHintLight =>
      'Se usa en modo oscuro o automático (negro puro y alto contraste)';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageAutomatic => 'Automático (dispositivo)';

  @override
  String get settingsNavBar => 'Barra de navegación';

  @override
  String get navBarPreview => 'Vista previa';

  @override
  String navBarPreviewDetail(int count, int max) {
    return '$count de $max pestañas';
  }

  @override
  String get navBarHelper =>
      'La primera pestaña se abre con la app. Las pantallas fuera de la barra siguen en el menú lateral.';

  @override
  String get navBarInBar => 'En la barra';

  @override
  String get navBarDragToOrder => 'Arrastra para ordenar';

  @override
  String get navBarInDrawer => 'En el menú lateral';

  @override
  String get navBarInitialTab => 'Pestaña inicial';

  @override
  String navBarInitialTabMin(int min) {
    return 'Pestaña inicial · mínimo $min pestañas';
  }

  @override
  String navBarMinLimit(int min) {
    return 'Mínimo $min pestañas en la barra';
  }

  @override
  String navBarMaxLimit(int max) {
    return 'Máximo de $max pestañas alcanzado';
  }

  @override
  String get navBarDrawerHint => 'Accesible desde el menú lateral';

  @override
  String get navBarRestoreDefault => 'Restaurar predeterminado';

  @override
  String navBarDragSemantics(String label) {
    return 'Arrastrar $label';
  }

  @override
  String get settingsFlashcards => 'Tarjetas';

  @override
  String get settingsNewCardsPerDay => 'Tarjetas nuevas por día';

  @override
  String get settingsDesiredRetention => 'Retención deseada';

  @override
  String settingsDesiredRetentionHint(int percent) {
    return '$percent%: más alta = repasos más frecuentes';
  }

  @override
  String get settingsDesiredRetentionSemantics =>
      'Porcentaje de retención deseada';

  @override
  String get settingsPomodoro => 'Pomodoro';

  @override
  String get settingsFocusMinutes => 'Enfoque (min)';

  @override
  String get settingsShortBreakMinutes => 'Pausa corta (min)';

  @override
  String get settingsLongBreakMinutes => 'Pausa larga (min)';

  @override
  String get settingsLongBreakEvery => 'Pausa larga cada';

  @override
  String settingsLongBreakEveryDetail(int count) {
    return '$count enfoques';
  }

  @override
  String get settingsLongBreakEverySemantics => 'Enfoques hasta la pausa larga';

  @override
  String get settingsAutoStartBreaks => 'Iniciar pausas automáticamente';

  @override
  String get settingsAutoStartBreaksHint =>
      'Al terminar el enfoque, la pausa comienza sola';

  @override
  String get settingsSoundOnEnd => 'Sonido al terminar';

  @override
  String get settingsVibrateOnEnd => 'Vibrar al terminar';

  @override
  String get settingsKeepScreenOn => 'Mantener la pantalla encendida';

  @override
  String get settingsKeepScreenOnHint =>
      'Mientras la pantalla de pomodoro esté abierta';

  @override
  String get settingsTasks => 'Tareas';

  @override
  String get settingsAllDayReminder => 'Recordatorio de todo el día';

  @override
  String settingsAllDayReminderHint(int hour) {
    return 'Tareas sin hora avisan a las $hour:00 (menos la antelación elegida)';
  }

  @override
  String get settingsAllDayReminderSemantics =>
      'Hora del recordatorio de todo el día';

  @override
  String get settingsBackup => 'Respaldo';

  @override
  String get settingsExportJson => 'Exportar JSON';

  @override
  String get settingsExportJsonHint => 'Todos los datos en un archivo';

  @override
  String get settingsImportJson => 'Importar JSON';

  @override
  String get settingsImportJsonHint =>
      'Combinar o reemplazar con datos de un respaldo';

  @override
  String get settingsUpdates => 'Actualizaciones';

  @override
  String updateVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get updateIdle => 'Toca para buscar una nueva versión';

  @override
  String get updateChecking => 'Buscando…';

  @override
  String get updateUpToDate => 'Tienes la versión más reciente';

  @override
  String updateAvailable(String version) {
    return 'Versión $version disponible';
  }

  @override
  String get updateError => 'No se pudo verificar. Inténtalo de nuevo.';

  @override
  String get todayEmpty => 'Nada para hoy todavía.';

  @override
  String get todayOverdue => 'Atrasadas';

  @override
  String get todayUndated => 'Sin fecha';

  @override
  String get tasksLoadError => 'No se pudieron cargar las tareas.';

  @override
  String get tasksNew => 'Nueva tarea';

  @override
  String get tasksCreate => 'Crear tarea';

  @override
  String get tasksNewSubtask => 'Nueva subtarea';

  @override
  String get tasksEdit => 'Editar tarea';

  @override
  String get tasksAdd => 'Añadir tarea';

  @override
  String get tasksSearchHint => 'Buscar por título';

  @override
  String get tasksCloseSearch => 'Cerrar búsqueda';

  @override
  String get tasksFilterAndSort => 'Filtrar y ordenar';

  @override
  String get tasksEmpty => 'Ninguna tarea todavía.';

  @override
  String get tasksNoMatches => 'Ninguna tarea coincide con estos filtros.';

  @override
  String get tasksClearFilters => 'Limpiar filtros';

  @override
  String tasksCreated(String title) {
    return 'Creada: $title';
  }

  @override
  String get taskKindSimple => 'Simple';

  @override
  String get taskKindStudy => 'Estudio';

  @override
  String get taskKindRoutine => 'Rutina';

  @override
  String get taskKindEvent => 'Evento';

  @override
  String get taskStatusTodo => 'Por hacer';

  @override
  String get taskStatusDoing => 'En curso';

  @override
  String get taskStatusDone => 'Hecha';

  @override
  String get priorityNone => 'Ninguna';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get reminderModeNotification => 'Notificación';

  @override
  String get reminderModeAlarm => 'Alarma';

  @override
  String get reminderModeNotificationHint =>
      'Aviso discreto en la barra de notificaciones.';

  @override
  String get reminderModeAlarmHint =>
      'Suena como despertador (incluso en silencio) hasta que interactúes.';

  @override
  String get reminderFullScreenBanner =>
      'Para mostrarse en la pantalla bloqueada, permite notificaciones en pantalla completa en los ajustes de Android.';

  @override
  String get reminderAllowFullScreen => 'Permitir pantalla completa';

  @override
  String get fieldTitle => 'Título';

  @override
  String get fieldNotes => 'Notas';

  @override
  String get fieldType => 'Tipo';

  @override
  String get fieldPriority => 'Prioridad';

  @override
  String get fieldDates => 'Fechas';

  @override
  String get fieldAllDay => 'Todo el día';

  @override
  String get fieldStart => 'Inicio';

  @override
  String get fieldDue => 'Plazo';

  @override
  String get fieldNoDate => 'Sin fecha';

  @override
  String get fieldDate => 'Fecha';

  @override
  String get fieldRepeat => 'Repetir';

  @override
  String get repeatNo => 'No';

  @override
  String get repeatDaily => 'Diaria';

  @override
  String get repeatWeekly => 'Semanal';

  @override
  String get repeatEvery => 'Cada';

  @override
  String get repeatUntil => 'Hasta';

  @override
  String get repeatNoEnd => 'Sin fin';

  @override
  String get fieldAlarm => 'Alarma';

  @override
  String get fieldReminder => 'Recordatorio';

  @override
  String get alarmNeedDue => 'Define un plazo para usar alarma.';

  @override
  String get reminderNone => 'Ninguno';

  @override
  String get reminderAtTime => 'A la hora';

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
  String get reminder1Day => '1 día antes';

  @override
  String get fieldEstimatedPomodoros => 'Pomodoros estimados';

  @override
  String get fieldTags => 'Etiquetas';

  @override
  String get tagNew => 'Nueva etiqueta';

  @override
  String get fieldIconAndColor => 'Ícono y color';

  @override
  String get appearanceCustom => 'Personalizado';

  @override
  String get appearanceDefault => 'Predeterminado';

  @override
  String get appearanceTapToChange => 'Toca para cambiar';

  @override
  String get appearanceInherited =>
      'Hereda de la tarea padre, la etiqueta o la repetición';

  @override
  String get quickDateToday => 'Hoy';

  @override
  String get quickDateTomorrow => 'Mañana';

  @override
  String get quickDateNextWeek => 'En una semana';

  @override
  String get pomodoroFocus => 'Enfoque';

  @override
  String get pomodoroShortBreak => 'Pausa corta';

  @override
  String get pomodoroLongBreak => 'Pausa larga';

  @override
  String get pomodoroStart => 'Iniciar';

  @override
  String get pomodoroPause => 'Pausar';

  @override
  String get pomodoroResume => 'Reanudar';

  @override
  String get pomodoroStop => 'Detener';

  @override
  String get pomodoroNoTask => 'Sin tarea';

  @override
  String get pomodoroLinkedTask => 'Tarea vinculada';

  @override
  String get pomodoroPickTask => 'Tarea de enfoque';

  @override
  String get pomodoroPausedSuffix => 'pausado';

  @override
  String get pomodoroFocusDone => '¡Enfoque completado!';

  @override
  String get pomodoroFocusDoneShort => 'Enfoque completado';

  @override
  String pomodoroBreakDone(String kind) {
    return '$kind terminada';
  }

  @override
  String pomodoroNextRunning(String kind) {
    return '$kind en curso';
  }

  @override
  String pomodoroNextLabel(String kind) {
    return 'Siguiente: $kind';
  }

  @override
  String pomodoroStartNext(String kind) {
    return 'Iniciar $kind';
  }

  @override
  String pomodoroCompleteTask(String title) {
    return 'Completar \"$title\"';
  }

  @override
  String get pomodoroCycleProgress => 'Progreso del ciclo';

  @override
  String get agendaGoToday => 'Ir a hoy';

  @override
  String get agendaGoToDate => 'Ir a la fecha';

  @override
  String get agendaView => 'Vista';

  @override
  String get agendaDay => 'Día';

  @override
  String get agendaWeek => 'Semana';

  @override
  String get agenda3Days => '3 días';

  @override
  String get agendaMonth => 'Mes';

  @override
  String get agendaCompletedPomodoros => 'Pomodoros realizados';

  @override
  String get reviewNewDeck => 'Nuevo mazo';

  @override
  String get reviewImportCsv => 'Importar CSV';

  @override
  String get reviewNewCard => 'Nueva tarjeta';

  @override
  String get reviewLoadError => 'No se pudieron cargar las tarjetas.';

  @override
  String get reviewEmpty =>
      'Ninguna tarjeta todavía.\nCrea una en + o importa un CSV.';

  @override
  String get reviewNow => 'Repasar ahora';

  @override
  String get reviewAllCards => 'Todas las tarjetas';

  @override
  String get reviewDecks => 'Mazos';

  @override
  String get reviewNameLabel => 'Nombre';

  @override
  String get booksImportMarkdown => 'Importar Markdown';

  @override
  String get booksNew => 'Nuevo libro';

  @override
  String get booksLoadError => 'No se pudieron cargar los libros.';

  @override
  String get booksEmpty =>
      'Ningún libro todavía.\nCrea uno en + o importa archivos .md.';

  @override
  String get statsFocusTime => 'Tiempo de enfoque';

  @override
  String get statsThisWeek => 'Esta semana';

  @override
  String get statsThisMonth => 'Este mes';

  @override
  String get statsDays => 'Días';

  @override
  String get statsWeeks => 'Semanas';

  @override
  String get statsMonths => 'Meses';

  @override
  String get statsNoFocusInPeriod =>
      'Ningún enfoque registrado en estos períodos.';

  @override
  String get statsStartFocus => 'Iniciar enfoque';

  @override
  String get statsFocusBy => 'Enfoque por';

  @override
  String get statsGroupTask => 'Tarea';

  @override
  String get statsGroupTag => 'Etiqueta';

  @override
  String get statsGroupType => 'Tipo';

  @override
  String get statsNoFocusGroup => 'Ningún enfoque en el período.';

  @override
  String get statsEstimatedVsDone => 'Pomodoros: estimado × realizado';

  @override
  String get statsNoEstimated => 'Ninguna tarea con pomodoros estimados.';

  @override
  String get statsReviews => 'Repasos';

  @override
  String get statsAccuracy30Days => 'Acierto (30 días)';

  @override
  String get statsStreakDay => 'Día seguido';

  @override
  String get statsStreakDays => 'Días seguidos';

  @override
  String get statsReviewsPerDay => 'Repasos por día';

  @override
  String get statsNoReviews14Days => 'Ningún repaso en los últimos 14 días.';

  @override
  String get statsDueNext7Days => 'Tarjetas a vencer en los próximos 7 días';

  @override
  String get statsNoDueThisWeek => 'Ninguna tarjeta por vencer esta semana.';

  @override
  String get statsRoutinesDone => 'Rutinas completadas';

  @override
  String get statsLess => 'menos';

  @override
  String get statsMore => 'más';

  @override
  String get accountTooltip => 'Cuenta y sincronización';

  @override
  String get accountSyncing => 'Sincronizando';

  @override
  String get accountOffline => 'Sin conexión: sincroniza luego';

  @override
  String get accountPending => 'Cambios por sincronizar';

  @override
  String get accountError => 'Error de sincronización';

  @override
  String get accountSynced => 'Sincronizado';

  @override
  String get actionClear => 'Limpiar';

  @override
  String get actionBack => 'Volver';

  @override
  String get actionAdd => 'Añadir';

  @override
  String get actionRename => 'Renombrar';

  @override
  String get actionDrag => 'Arrastrar';

  @override
  String get tasksEmptyCreated => 'Ninguna tarea creada.';

  @override
  String get tasksExpandSubtasks => 'Mostrar subtareas';

  @override
  String get tasksCollapseSubtasks => 'Ocultar subtareas';

  @override
  String get tasksSortBy => 'Ordenar por';

  @override
  String get tasksSortManual => 'Manual';

  @override
  String get tasksSortDue => 'Fecha límite';

  @override
  String get tasksSortPriority => 'Prioridad';

  @override
  String get tasksSortNewest => 'Más recientes';

  @override
  String get tasksSortTitle => 'Título';

  @override
  String get fieldStatus => 'Estado';

  @override
  String get taskTagSingle => 'Etiqueta';

  @override
  String taskTagCount(int count) {
    return '$count etiquetas';
  }

  @override
  String get taskLoadOneError => 'No se pudo cargar la tarea.';

  @override
  String get taskNotFound => 'Tarea no encontrada.';

  @override
  String get taskSingular => 'Tarea';

  @override
  String get subtaskSingular => 'Subtarea';

  @override
  String subtaskOf(String title) {
    return 'Subtarea de $title';
  }

  @override
  String get taskChangeStatus => 'Cambiar estado';

  @override
  String taskPriorityBadge(String label) {
    return 'Prioridad $label';
  }

  @override
  String get fieldRecurrence => 'Repetición';

  @override
  String get subtasksSection => 'Subtareas';

  @override
  String get subtasksAddHint => 'Añadir subtarea';

  @override
  String get routineHistory => 'Historial';

  @override
  String get routineNoStreak => 'Sin racha activa';

  @override
  String get routineNotCompletedYet => 'Aún no completada';

  @override
  String routineTotalCompletions(int count, String unit) {
    return '$count $unit en total';
  }

  @override
  String routineStreakDays(int count, String unit) {
    return '$count $unit';
  }

  @override
  String get routineDaySingular => 'día seguido';

  @override
  String get routineDayPlural => 'días seguidos';

  @override
  String get routineTimeSingular => 'vez seguida';

  @override
  String get routineTimePlural => 'veces seguidas';

  @override
  String get routineEnded => 'Rutina finalizada: era la última ocurrencia.';

  @override
  String routineNext(String when) {
    return 'Rutina completada. Próxima: $when.';
  }

  @override
  String taskDeleted(String title) {
    return '\"$title\" eliminada';
  }

  @override
  String taskDeletedWithSubtasks(String title, int count) {
    return '\"$title\" y $count subtarea(s) eliminadas';
  }

  @override
  String get repeatIntervalSemantics => 'Intervalo de repetición';

  @override
  String get unitDay => 'día';

  @override
  String get unitDays => 'días';

  @override
  String get unitWeek => 'semana';

  @override
  String get unitWeeks => 'semanas';

  @override
  String fieldClearLabel(String label) {
    return 'Limpiar $label';
  }

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes min antes';
  }

  @override
  String get hubAdd => 'AÑADIR';

  @override
  String get hubFlashcard => 'Flashcard';

  @override
  String get hubPage => 'Página';

  @override
  String get hubPages => 'Páginas';

  @override
  String get hubNewPage => 'Nueva página';

  @override
  String get hubNoCardsYet => 'Ninguna tarjeta aún';

  @override
  String get hubReviewTask => 'Repasar esta tarea';

  @override
  String get hubCard => 'Tarjeta';

  @override
  String hubFocusTimeValue(String duration) {
    return 'Tiempo de enfoque: $duration';
  }

  @override
  String get hubNoSessionsYet => 'Ninguna sesión aún';

  @override
  String hubFocusSessions(int count, String unit) {
    return '$count $unit de enfoque (incluye subtareas)';
  }

  @override
  String get unitSession => 'sesión';

  @override
  String get unitSessions => 'sesiones';

  @override
  String get hubNoPagesYet => 'Ninguna página aún';

  @override
  String get hubUnlink => 'Desvincular';

  @override
  String get hubOpenNotebook => 'Abrir cuaderno';

  @override
  String get hubLinkExistingPage => 'Vincular página existente';

  @override
  String get hubLinkPage => 'Vincular página';

  @override
  String get hubNoBookPages => 'Aún no hay páginas en Books.';

  @override
  String get hubNoBookPagesHint =>
      'Crea páginas en la pestaña Books para vincularlas.';

  @override
  String hubEstimatedVsDone(int done, int estimated) {
    return 'Estimado × realizado: $done de $estimated';
  }

  @override
  String agendaNextTaskIn(String wait) {
    return 'Próxima tarea en $wait';
  }

  @override
  String get agendaSearchTask => 'Buscar tarea';

  @override
  String get agendaNoDatedTasks => 'No se encontraron tareas con fecha.';

  @override
  String get agendaAllDayShort => 'todo\nel día';

  @override
  String get agendaExpandAllDay => 'Expandir todo el día';

  @override
  String get agendaCollapseAllDay => 'Contraer todo el día';

  @override
  String get agendaRoutineRescheduled =>
      'Rutina reprogramada (todas las ocurrencias).';

  @override
  String get reviewEmptyAction => 'Crear mazo';

  @override
  String get reviewEmptyAlt =>
      'Ninguna tarjeta aún.\nCrea una con + o importa un CSV.';

  @override
  String get reviewNothingDue => 'Nada para repasar ahora';

  @override
  String reviewDueNow(int count) {
    return '$count para repasar ahora';
  }

  @override
  String reviewNextIn(int minutes) {
    return 'Próxima tarjeta en $minutes min.';
  }

  @override
  String get reviewAll => 'Repasar todo';

  @override
  String reviewDeckDueSuffix(int count) {
    return '$count por repasar';
  }

  @override
  String get reviewSessionTitle => 'Repaso';

  @override
  String get reviewUndoLast => 'Deshacer última calificación';

  @override
  String get reviewProgressSemantics => 'Progreso de la sesión';

  @override
  String get reviewShowAnswer => 'Mostrar respuesta';

  @override
  String get reviewCardNew => 'nueva';

  @override
  String get reviewGradeAgain => 'Otra vez';

  @override
  String get reviewGradeHard => 'Difícil';

  @override
  String get reviewGradeGood => 'Bien';

  @override
  String get reviewGradeEasy => 'Fácil';

  @override
  String reviewNextCardSoon(int minutes) {
    return 'Próxima tarjeta en $minutes min.\nAparecerá aquí automáticamente.';
  }

  @override
  String get reviewNothingDueDot => 'Nada para repasar ahora.';

  @override
  String reviewAllDone(int count, String unit) {
    return '¡Todo repasado por ahora! $count $unit en esta sesión.';
  }

  @override
  String get unitCard => 'tarjeta';

  @override
  String get unitCards => 'tarjetas';

  @override
  String get reviewRemainingSingular => 'tarjeta restante';

  @override
  String get reviewRemainingPlural => 'tarjetas restantes';

  @override
  String get booksOptions => 'Opciones del book';

  @override
  String get booksExportZip => 'Exportar (.zip)';

  @override
  String booksDeleteTitle(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get booksDeleteMessage => 'Se eliminarán todas las páginas del book.';

  @override
  String statsSameAs(String period) {
    return 'igual que $period';
  }

  @override
  String statsVs(String delta, String period) {
    return '$delta vs $period';
  }

  @override
  String get statsYesterday => 'ayer';

  @override
  String get statsPrevious => 'anterior';

  @override
  String statsFocusHoursPer(String unit) {
    return 'Horas de enfoque por $unit';
  }

  @override
  String get statsUnitDay => 'día';

  @override
  String get statsUnitWeek => 'semana';

  @override
  String get statsUnitMonth => 'mes';

  @override
  String get statsFocusChartSemantics => 'Gráfico de horas de enfoque';

  @override
  String get statsDeletedTask => 'Tarea eliminada';

  @override
  String get statsNoTag => 'Sin etiqueta';

  @override
  String get statsDeletedTag => 'Etiqueta eliminada';

  @override
  String statsOf(int done, int total) {
    return '$done de $total';
  }

  @override
  String get statsReviewsChartSemantics => 'Gráfico de repasos por día';

  @override
  String get statsDueChartSemantics => 'Gráfico de tarjetas por vencer';

  @override
  String get statsTodayLower => 'hoy';

  @override
  String get statsTodayWithOverdue => 'Hoy (con vencidas)';

  @override
  String get statsUnitReview => 'repaso';

  @override
  String get statsUnitReviews => 'repasos';

  @override
  String statsRoutineTotal(int count, String unit, int weeks) {
    return '$count $unit en las últimas $weeks semanas';
  }

  @override
  String get unitCompletion => 'vez';

  @override
  String get unitCompletions => 'veces';

  @override
  String statsWeekOf(String date) {
    return 'Semana del $date';
  }

  @override
  String get settingsAlarmDiagnostics => 'Diagnóstico de alarmas';

  @override
  String get settingsAlarmDiagnosticsOk => 'Todo listo para sonar';

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
  String get diagnosticsRefresh => 'Verificar de nuevo';

  @override
  String get diagnosticsOpenSettings => 'Abrir ajustes';

  @override
  String get diagnosticsStatusOk => 'Activo';

  @override
  String get diagnosticsStatusIssue => 'Atención';

  @override
  String get diagnosticsSummaryOk =>
      'Tu dispositivo está listo para entregar tus recordatorios y alarmas a tiempo.';

  @override
  String get diagnosticsSummaryIssues =>
      'Algunos ajustes de Android pueden bloquear o retrasar tus recordatorios.';

  @override
  String get diagNotificationsTitle => 'Notificaciones de la app';

  @override
  String get diagNotificationsOk => 'Permitidas por Android.';

  @override
  String get diagNotificationsOff =>
      'Desactivadas: no aparecerá ningún recordatorio ni alarma.';

  @override
  String get diagRemindersChannelTitle => 'Canal de recordatorios';

  @override
  String get diagRemindersChannelOk => 'Sonido y avisos habilitados.';

  @override
  String get diagRemindersChannelMuted =>
      'El canal está silenciado: las notificaciones normales no sonarán.';

  @override
  String get diagAlarmsChannelTitle => 'Canal de alarmas';

  @override
  String get diagAlarmsChannelOk => 'Canal de alarma habilitado.';

  @override
  String get diagAlarmsChannelMuted =>
      'El canal está silenciado: las tareas en modo Alarma no sonarán.';

  @override
  String get diagExactAlarmsTitle => 'Alarmas exactas';

  @override
  String get diagExactAlarmsOk => 'La app puede programar al minuto exacto.';

  @override
  String get diagExactAlarmsDenied =>
      'Denegado: los recordatorios pueden retrasarse o fallar.';

  @override
  String get diagFullScreenTitle => 'Alarmas en pantalla completa';

  @override
  String get diagFullScreenOk => 'Puede mostrarse sobre la pantalla bloqueada.';

  @override
  String get diagFullScreenDenied =>
      'Sin permiso: la alarma puede no abrirse en la pantalla bloqueada.';

  @override
  String get diagBatteryTitle => 'Optimización de batería';

  @override
  String get diagBatteryOk => 'Sin restricciones en segundo plano.';

  @override
  String get diagBatteryRestricted =>
      'Con restricción: dispositivos (ej. apps en suspensión de Samsung) pueden retrasar alarmas.';

  @override
  String get formDiagnosticsWarning =>
      'Este recordatorio podría no sonar: revisa los permisos de notificación y alarma.';

  @override
  String get formDiagnosticsAction => 'Ver diagnóstico';

  @override
  String get actionSnooze => 'Posponer';

  @override
  String get snooze10Min => '10 min';

  @override
  String get snooze1Hour => '1 h';

  @override
  String snoozeTomorrowMorning(String time) {
    return 'Mañana temprano ($time)';
  }

  @override
  String snoozedUntil(String when) {
    return 'Recordatorio pospuesto para $when.';
  }

  @override
  String get settingsDailyReminders => 'Avisos diarios';

  @override
  String get settingsDailySummary => 'Resumen diario de tareas';

  @override
  String settingsDailySummaryHint(int hour) {
    return 'Avisa sobre tareas de hoy y atrasadas a las $hour:00';
  }

  @override
  String get settingsDailySummaryOffHint =>
      'Recibe un resumen diario de tareas pendientes';

  @override
  String get settingsDailySummaryHourSemantics =>
      'Hora del resumen diario de tareas';

  @override
  String get settingsDailyReview => 'Aviso diario de tarjetas';

  @override
  String settingsDailyReviewHint(int hour) {
    return 'Recuerda a las $hour:00 cuando haya tarjetas por repasar';
  }

  @override
  String get settingsDailyReviewOffHint =>
      'Avisa cuando haya tarjetas vencidas (no avisa si hay cero)';

  @override
  String get settingsDailyReviewHourSemantics =>
      'Hora del aviso diario de tarjetas';

  @override
  String get settingsHourLabel => 'Hora (h)';

  @override
  String get fieldReminders => 'Recordatorios';

  @override
  String get remindersHelperMultiple =>
      'Elige uno o más horarios para recordar.';

  @override
  String get fieldNagIfOverdue => 'Insistir si se atrasa';

  @override
  String get nagOff => 'No';

  @override
  String nagEveryMinutes(int minutes) {
    return 'Cada $minutes min';
  }

  @override
  String nagHint(int max) {
    return 'Se repite hasta $max× tras la hora hasta completarla.';
  }

  @override
  String nagHubDetail(int minutes, int max) {
    return 'Cada $minutes min (hasta $max×)';
  }

  @override
  String get booksRename => 'Renombrar book';

  @override
  String booksExported(int count) {
    return 'Book exportado ($count páginas).';
  }

  @override
  String get booksNoMarkdown => 'No se encontró ningún archivo .md.';

  @override
  String get booksImportedDefault => 'Importado';

  @override
  String get booksImportAsBook => 'Importar como book';

  @override
  String get booksBookTitle => 'Título del book';

  @override
  String get actionImport => 'Importar';

  @override
  String booksPagesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas importadas.',
      one: '1 página importada.',
    );
    return '$_temp0';
  }

  @override
  String get pageNew => 'Nueva página';

  @override
  String get pageNewSub => 'Nueva subpágina';

  @override
  String get pageRename => 'Renombrar página';

  @override
  String pageDeleteTitle(String title) {
    return '¿Eliminar \"$title\"?';
  }

  @override
  String get pageDeleteMessage => 'Las subpáginas también se eliminarán.';

  @override
  String get pageExported => 'Página exportada.';

  @override
  String get bookFallbackTitle => 'Book';

  @override
  String get bookOptions => 'Opciones del book';

  @override
  String get bookImportPages => 'Importar páginas (.md)';

  @override
  String get bookExportZip => 'Exportar (.zip)';

  @override
  String get pagesLoadError => 'No se pudieron cargar las páginas.';

  @override
  String bookTaskNotebook(String title) {
    return 'Cuaderno de la tarea $title';
  }

  @override
  String get pagesEmpty => 'Aún no hay páginas.';

  @override
  String get pageCreate => 'Crear página';

  @override
  String get pageOptions => 'Opciones de la página';

  @override
  String get actionMoveUp => 'Subir';

  @override
  String get actionMoveDown => 'Bajar';

  @override
  String get pageExportMd => 'Exportar (.md)';

  @override
  String get pageSelectTextFirst => 'Primero selecciona un fragmento de texto.';

  @override
  String get pageUseAsFront => 'Usar como anverso';

  @override
  String get pageUseAsBack => 'Usar como reverso';

  @override
  String get pageFlashcardCreated => 'Flashcard creada.';

  @override
  String get pageLinkTask => 'Vincular a tarea';

  @override
  String get pageWriteHere => 'Escribe aquí…';

  @override
  String get pageNotFound => 'Página no encontrada.';

  @override
  String get pageReadMode => 'Modo lectura';

  @override
  String get pageCreateCardFromSelection => 'Crear flashcard de la selección';

  @override
  String get pageIcon => 'Icono';

  @override
  String get pageDelete => 'Eliminar página';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionCut => 'Cortar';

  @override
  String get actionPaste => 'Pegar';

  @override
  String get pageCreateCard => 'Crear flashcard';

  @override
  String get pageIconTooltip => 'Icono de la página';

  @override
  String get editorImageByLink => 'Imagen por enlace';

  @override
  String get editorImageUrl => 'Dirección de la imagen (https://…)';

  @override
  String get actionInsert => 'Insertar';

  @override
  String get cardDeleted => 'Tarjeta eliminada';

  @override
  String get cardsNoneInFile => 'No se encontraron tarjetas en el archivo.';

  @override
  String cardsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas importadas.',
      one: '1 tarjeta importada.',
    );
    return '$_temp0';
  }

  @override
  String get cardsImportTitle => 'Importar tarjetas';

  @override
  String cardsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas encontradas.',
      one: '1 tarjeta encontrada.',
    );
    return '$_temp0';
  }

  @override
  String cardsSkippedLines(String lines) {
    return 'Líneas ignoradas (sin anverso o reverso): $lines';
  }

  @override
  String get fieldDeck => 'Mazo';

  @override
  String get deckNone => 'Sin mazo';

  @override
  String get cardEdit => 'Editar tarjeta';

  @override
  String get cardFront => 'Anverso';

  @override
  String get cardBack => 'Reverso';

  @override
  String get cardMarkdownHint =>
      'Admite **negrita**, *cursiva*, `código` y - listas';

  @override
  String get cardSave => 'Guardar tarjeta';

  @override
  String get deckRename => 'Renombrar mazo';

  @override
  String deckDeleteTitle(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get deckDeleteMessage => 'Las tarjetas se conservan, sin mazo.';

  @override
  String get deckOptions => 'Opciones del mazo';

  @override
  String get deckDelete => 'Eliminar mazo';

  @override
  String get cardsEmptyHere => 'Aún no hay tarjetas aquí.';

  @override
  String get cardCreate => 'Crear tarjeta';

  @override
  String cardsReviewCount(int count) {
    return 'Repasar $count ahora';
  }

  @override
  String get cardSuspended => 'Suspendida';

  @override
  String get cardNew => 'Nueva';

  @override
  String cardNextReview(String when) {
    return 'Repaso: $when';
  }

  @override
  String get cardOptions => 'Opciones de la tarjeta';

  @override
  String get cardReactivate => 'Reactivar';

  @override
  String get cardSuspend => 'Suspender';

  @override
  String get syncCloudHasData => 'Ya hay datos en la nube';

  @override
  String get syncCloudHasDataOtherAccount =>
      'La nueva cuenta tiene un Google Drive diferente con datos de My Cadence. ¿Qué hacer con los datos de este dispositivo?';

  @override
  String get syncCloudHasDataThisAccount =>
      'Esta cuenta ya tiene datos de My Cadence. ¿Qué hacer con los datos de este dispositivo?';

  @override
  String get syncUseCloudOnly => 'Usar solo los de la nube';

  @override
  String get syncMerge => 'Combinar';

  @override
  String get syncCloudLoaded =>
      'Datos de la nube cargados. Se guardó una copia de los anteriores.';

  @override
  String get backupManual => 'Copia manual';

  @override
  String get backupRestoreCopy => 'Restaurar copia';

  @override
  String get backupDailyCopyHint => 'La app guarda una copia por día';

  @override
  String get syncWithDrive => 'Sincroniza con Google Drive';

  @override
  String get syncDriveExplain =>
      'Tus datos quedan en una carpeta privada de la app en tu Google Drive, usando tu espacio. Solo esta app ve esa carpeta.';

  @override
  String get syncConnectGoogle => 'Conectar con Google';

  @override
  String get syncNotConfigured =>
      'El inicio de sesión con Google aún no está configurado en esta app.';

  @override
  String get syncStatusSyncing => 'Sincronizando…';

  @override
  String get syncStatusOffline => 'Sin conexión. Se sincroniza al volver.';

  @override
  String get syncStatusPending => 'Cambios por sincronizar';

  @override
  String get syncStatusError => 'Error al sincronizar';

  @override
  String syncStatusSyncedAgo(String ago) {
    return 'Sincronizado $ago';
  }

  @override
  String get syncStatusNever => 'Aún no sincronizado';

  @override
  String get syncAgoNow => 'hace un momento';

  @override
  String syncAgoMinutes(int count) {
    return 'hace $count min';
  }

  @override
  String syncAgoHours(int count) {
    return 'hace $count h';
  }

  @override
  String syncAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get syncSignInAgain => 'Iniciar sesión de nuevo';

  @override
  String get syncUseCloudData => 'Usar los datos de la nube';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncAuto => 'Sincronización automática';

  @override
  String get syncAutoHint => 'Al abrir, al volver a la app y tras cambios';

  @override
  String get syncSwitchAccount => 'Cambiar cuenta';

  @override
  String get syncDisconnect => 'Desconectar';

  @override
  String get syncDisconnected =>
      'Desconectado. Los datos siguen en este dispositivo.';

  @override
  String get syncDeviceName => 'Nombre de este dispositivo';

  @override
  String get syncThisDevice => 'Este dispositivo';

  @override
  String get syncLog => 'Registro de sync';

  @override
  String get syncLogEmpty => 'Aún no hay sincronizaciones.';

  @override
  String get backupExported => 'Copia exportada.';

  @override
  String get backupNoCopies => 'Aún no hay copias guardadas.';

  @override
  String get backupReplaceAllQuestion => '¿Reemplazar todo?';

  @override
  String get backupReplaceWarning =>
      'Los datos de este dispositivo se reemplazarán por los del archivo. Antes se guarda una copia de los datos actuales en la app.';

  @override
  String get backupReplace => 'Reemplazar';

  @override
  String get backupReplaced =>
      'Datos reemplazados. Se guardó una copia de los anteriores.';

  @override
  String get backupNothingNew => 'Nada nuevo en el archivo.';

  @override
  String backupMerged(int inserted, int updated, int deleted) {
    return 'Copia combinada: $inserted nuevos, $updated actualizados, $deleted eliminados.';
  }

  @override
  String get backupImportTitle => 'Importar copia';

  @override
  String backupFrom(String when) {
    return 'De $when';
  }

  @override
  String countTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '1 tarea',
    );
    return '$_temp0';
  }

  @override
  String countCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas',
      one: '1 tarjeta',
    );
    return '$_temp0';
  }

  @override
  String countBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String countPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
    );
    return '$_temp0';
  }

  @override
  String get backupMerge => 'Combinar';

  @override
  String get backupMergeHint =>
      'Combina con los datos de este dispositivo. No se borra nada.';

  @override
  String get backupReplaceAll => 'Reemplazar todo';

  @override
  String get backupReplaceAllHint =>
      'Reemplaza los datos de este dispositivo por los del archivo.';

  @override
  String get pickerIcon => 'Icono';

  @override
  String get pickerColor => 'Color';

  @override
  String get pickerUseDefault => 'Usar predeterminado';

  @override
  String get pickerColorSection => 'COLOR';

  @override
  String get pickerSearchIcon => 'Buscar icono';

  @override
  String get actionApply => 'Aplicar';

  @override
  String timelineFocus(String range) {
    return 'Enfoque $range';
  }

  @override
  String get fieldWhen => 'Cuándo';

  @override
  String get fieldDetails => 'Detalles';

  @override
  String get fieldStudy => 'Estudio vinculado';

  @override
  String get repeatStarts => 'Empieza';

  @override
  String get repeatEnds => 'Termina';

  @override
  String get repeatNever => 'Nunca';

  @override
  String get fieldTimeRange => 'Horario';

  @override
  String get timeRangeFrom => 'Inicio';

  @override
  String get timeRangeTo => 'Fin';

  @override
  String get repeatDatesHint =>
      '“Empieza” es la primera vez y “Termina”, la última repetición.';

  @override
  String get datesHint =>
      'Inicio es cuando empiezas; plazo es cuando debe estar lista.';

  @override
  String get remindersNeedDate =>
      'Define una fecha para recibir recordatorios.';

  @override
  String reminderOnTheDay(int hour) {
    return 'El día, a las ${hour}h';
  }

  @override
  String reminderDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días antes',
      one: '1 día antes',
    );
    return '$_temp0';
  }

  @override
  String reminderWeeksBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas antes',
      one: '1 semana antes',
    );
    return '$_temp0';
  }

  @override
  String get remindersBaseStart => 'Contados desde el inicio.';

  @override
  String get remindersBaseDue => 'Contados desde el plazo.';

  @override
  String remindersBaseAllDay(int hour) {
    return 'Todo el día recuerda a las ${hour}h (cámbialo en Ajustes).';
  }

  @override
  String get remindersEachRepeat => 'Valen para cada repetición.';

  @override
  String remindersPreview(String when) {
    return 'Avisará: $when';
  }

  @override
  String remindersPreviewFirst(String when) {
    return 'Primera vez: $when';
  }

  @override
  String get fieldBooks => 'Books';

  @override
  String get fieldDecks => 'Mazos';

  @override
  String get studyHint =>
      'Vincula books y mazos a esta tarea para seguirlos en el hub y las métricas.';

  @override
  String get linkBook => 'Vincular book';

  @override
  String get linkDeck => 'Vincular mazo';

  @override
  String get newBook => 'Nuevo book';

  @override
  String get newDeck => 'Nuevo mazo';

  @override
  String get linkBooksTitle => 'Vincular books';

  @override
  String get linkDecksTitle => 'Vincular mazos';

  @override
  String get noBooksYet => 'Aún no hay books.';

  @override
  String get noDecksYet => 'Aún no hay mazos.';

  @override
  String unlinkItem(String name) {
    return 'Desvincular $name';
  }

  @override
  String get hubLinkedBooks => 'Books vinculados';

  @override
  String get hubLinkedDecks => 'Mazos vinculados';

  @override
  String get deleteTaskTitle => '¿Eliminar tarea?';

  @override
  String get deleteTaskAlsoHint => 'Eliminar también lo vinculado a ella:';

  @override
  String deleteAlsoBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books (con sus páginas)',
      one: '1 book (con sus páginas)',
    );
    return '$_temp0';
  }

  @override
  String deleteAlsoPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas vinculadas',
      one: '1 página vinculada',
    );
    return '$_temp0';
  }

  @override
  String deleteAlsoDecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mazos (las tarjetas quedan sin mazo)',
      one: '1 mazo (las tarjetas quedan sin mazo)',
    );
    return '$_temp0';
  }

  @override
  String get deleteAlsoNoUndo =>
      'Lo que marques aquí no vuelve con \"Deshacer\".';

  @override
  String get repeatTimeHint => 'El horario vale para todas las repeticiones.';

  @override
  String get formInfoTooltip => 'Cómo funciona';

  @override
  String get formInfoDatesTitle => 'Inicio y plazo';

  @override
  String get formInfoRepeatTitle => 'Repetición';

  @override
  String get formInfoRemindersTitle => 'Recordatorios';

  @override
  String get formInfoReminders =>
      'Con hora, cuentan desde el inicio (o desde el plazo si no hay inicio). En todo el día, suenan a la hora definida en Ajustes, el mismo día o días antes. En una rutina, valen para cada repetición.';

  @override
  String get formInfoModesTitle => 'Notificación o alarma';

  @override
  String get formInfoNagTitle => 'Insistir si se atrasa';

  @override
  String get formInfoStudyTitle => 'Estudio vinculado';

  @override
  String get deckSpeech => 'Lectura en voz alta';

  @override
  String get deckSpeechHint =>
      'Usa la voz del propio teléfono (texto a voz). Elige el idioma de cada lado de la tarjeta.';

  @override
  String get deckSpeechFront => 'Frente';

  @override
  String get deckSpeechBack => 'Reverso';

  @override
  String get deckSpeechOff => 'No leer';

  @override
  String get deckSpeechAuto => 'Leer automáticamente al repasar';

  @override
  String get deckSpeechNoVoices =>
      'No se encontraron voces. Instálalas en Ajustes de Android → Texto a voz.';

  @override
  String get speakFront => 'Escuchar frente';

  @override
  String get speakFrontSlow => 'Escuchar frente despacio';

  @override
  String get speakBack => 'Escuchar reverso';

  @override
  String get speakBackSlow => 'Escuchar reverso despacio';

  @override
  String get speechDefault => 'Voz predeterminada';

  @override
  String get speechDefaultHint =>
      'Vale para todos los mazos sin ajuste propio.';

  @override
  String get speechUseDefault => 'Usar la voz predeterminada';

  @override
  String get speechDeckTooltip => 'Voz del mazo';

  @override
  String get manualTimeLog => 'Registrar tiempo';

  @override
  String get manualTimeTitle => 'Registrar tiempo dedicado';

  @override
  String get manualTimeHint =>
      'Para cuando trabajaste sin el pomodoro. Cuenta en el tiempo de foco y en las métricas, pero no como pomodoro completado.';

  @override
  String get manualTimeHours => 'Horas';

  @override
  String get manualTimeMinutes => 'Minutos';

  @override
  String get manualTimeDay => 'Día';

  @override
  String get manualTimeStart => 'Empezó a las';

  @override
  String manualTimeSaved(String duration) {
    return '$duration registrados.';
  }

  @override
  String get manualTimeEntries => 'Registros manuales';

  @override
  String get manualTimeDelete => 'Eliminar registro';

  @override
  String get statsTagHint =>
      'Una tarea con varias etiquetas cuenta su tiempo en cada una; las subtareas heredan las etiquetas de la madre.';

  @override
  String get taskStatusPaused => 'Pausada';

  @override
  String get rescheduleAction => 'Reprogramar';

  @override
  String get rescheduleChoose => 'Elegir fecha';

  @override
  String rescheduledTo(String date) {
    return 'Reprogramada para $date.';
  }

  @override
  String get rescheduleResumesHint =>
      'Reprogramar también reanuda la tarea pausada.';

  @override
  String get pausedBanner =>
      'Pausada: no aparece en Hoy, atrasadas ni recordatorios hasta reanudarla.';

  @override
  String get actionPause => 'Pausar';

  @override
  String get actionResume => 'Reanudar';

  @override
  String get fieldEstimatedTime => 'Tiempo estimado';

  @override
  String get estimateHours => 'Horas';

  @override
  String get estimateHint =>
      'Comparado con el tiempo de foco hecho (pomodoros y tiempo registrado).';

  @override
  String hubEstimatedTime(String done, String estimated) {
    return 'Estimado × hecho: $done de $estimated';
  }

  @override
  String statsOfTime(String done, String total) {
    return '$done de $total';
  }

  @override
  String get statsEstimatedVsDoneTime => 'Tiempo: estimado × hecho';

  @override
  String get statsNoEstimatedTime => 'Ninguna tarea con tiempo estimado.';

  @override
  String get quickAddHint => 'Nueva tarea (#etiqueta para marcar)';

  @override
  String get searchAllTooltip => 'Buscar en todo';

  @override
  String get searchHint => 'Buscar tareas, páginas y tarjetas';

  @override
  String get searchIntro =>
      'Escribe al menos 2 letras. La búsqueda mira títulos, notas, el texto de las páginas y ambos lados de las tarjetas.';

  @override
  String get searchNoResults => 'No se encontró nada.';

  @override
  String get searchClear => 'Limpiar';

  @override
  String get weekReviewTitle => 'Revisión semanal';

  @override
  String get weekPrevious => 'Semana anterior';

  @override
  String get weekNext => 'Semana siguiente';

  @override
  String get weekCompleted => 'Completadas';

  @override
  String get weekRoutines => 'Rutinas cumplidas';

  @override
  String get weekFocus => 'Foco';

  @override
  String get weekByTag => 'Tiempo por etiqueta';

  @override
  String get weekNoFocus => 'Sin tiempo de foco esta semana.';

  @override
  String get weekOverdue => 'Quedó atrás';

  @override
  String get weekNoOverdue => 'Nada atrasado. ¡Bien!';

  @override
  String get weekAllToToday => 'Todas para hoy';

  @override
  String weekMovedToToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas movidas a hoy.',
      one: '1 tarea movida a hoy.',
    );
    return '$_temp0';
  }

  @override
  String get weekNoCompleted => 'Ninguna tarea completada esta semana.';

  @override
  String get templateSave => 'Guardar como plantilla';

  @override
  String get templateName => 'Nombre de la plantilla';

  @override
  String templateSaved(String name) {
    return 'Plantilla \"$name\" guardada.';
  }

  @override
  String get templateUse => 'Plantilla';

  @override
  String get templatePickTitle => 'Crear desde una plantilla';

  @override
  String get templatePickHint =>
      'La tarea se crea con etiquetas, apariencia, estimación, recordatorios, subtareas, books y mazos de la plantilla; luego elige las fechas.';

  @override
  String get templateDelete => 'Eliminar plantilla';

  @override
  String templateSubtasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subtareas',
      one: '1 subtarea',
      zero: 'sin subtareas',
    );
    return '$_temp0';
  }

  @override
  String get weekReviewShort => 'Semana';

  @override
  String get cardsImportFromFile => 'Cargar archivo';

  @override
  String get cardsImportTextLabel => 'Tarjetas (frente;reverso)';

  @override
  String get cardsImportTextHint => 'apple;manzana\nbook;libro';

  @override
  String get cardsImportTextHelper =>
      'Una tarjeta por línea, separada por punto y coma (;)';

  @override
  String get cardsSkipDuplicates => 'Omitir frentes que ya existen en el mazo';

  @override
  String cardsDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicadas omitidas.',
      one: '1 duplicada omitida.',
    );
    return '$_temp0';
  }

  @override
  String cardsAllDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Todas las $count tarjetas ya existen en este mazo.',
      one: 'Esta tarjeta ya existe en este mazo.',
    );
    return '$_temp0';
  }

  @override
  String get cardsNoneInText => 'No se encontraron tarjetas válidas.';

  @override
  String cardsImportActionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count tarjetas',
      one: 'Importar 1 tarjeta',
    );
    return '$_temp0';
  }

  @override
  String get navTags => 'Etiquetas';

  @override
  String get tagEdit => 'Editar etiqueta';

  @override
  String get tagChangeColor => 'Cambiar color';

  @override
  String get tagOptions => 'Opciones de la etiqueta';

  @override
  String get tagDuplicateError => 'Ya existe una etiqueta con ese nombre.';

  @override
  String get tagsEmpty => 'Aún no hay etiquetas creadas.';

  @override
  String get tagsLoadError => 'No se pudieron cargar las etiquetas.';

  @override
  String tagTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '1 tarea',
      zero: 'Ninguna tarea',
    );
    return '$_temp0';
  }

  @override
  String tagDeleteTitle(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get tagDeleteUnusedMessage => 'Ninguna tarea usa esta etiqueta.';

  @override
  String tagDeleteUsedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Esta etiqueta está en $count tareas; perderán la etiqueta.',
      one: 'Esta etiqueta está en 1 tarea; perderá la etiqueta.',
    );
    return '$_temp0';
  }

  @override
  String tagDeleted(String name) {
    return 'Etiqueta \"$name\" eliminada.';
  }

  @override
  String get tagViewTasks => 'Ver tareas';

  @override
  String get cardsSearchHint => 'Buscar tarjetas';

  @override
  String get cardsFilterAll => 'Todas';

  @override
  String get cardsFilterDue => 'Pendientes';

  @override
  String get cardsFilterNew => 'Nuevas';

  @override
  String get cardsFilterSuspended => 'Suspendidas';

  @override
  String get cardsExportCsv => 'Exportar CSV';

  @override
  String cardsExportSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas listas en formato frente;reverso.',
      one: '1 tarjeta lista en formato frente;reverso.',
    );
    return '$_temp0';
  }

  @override
  String get cardsExportCopy => 'Copiar CSV';

  @override
  String get cardsExportSaveFile => 'Guardar archivo';

  @override
  String get cardsCsvCopied => 'CSV copiado.';

  @override
  String get cardsCsvSaved => 'Archivo CSV guardado.';

  @override
  String get navTrash => 'Papelera';

  @override
  String get trashHint =>
      'Los elementos eliminados quedan aquí para restaurarlos.';

  @override
  String get trashEmpty => 'La papelera está vacía.';

  @override
  String get trashFilterAll => 'Todo';

  @override
  String get trashFilterCards => 'Tarjetas';

  @override
  String get trashKindTask => 'Tarea';

  @override
  String get trashKindTag => 'Etiqueta';

  @override
  String get trashKindDeck => 'Mazo';

  @override
  String get trashKindCard => 'Tarjeta';

  @override
  String get trashKindBook => 'Book';

  @override
  String get trashKindPage => 'Página';

  @override
  String get trashRestore => 'Restaurar';

  @override
  String trashRestored(String title) {
    return '\"$title\" restaurado.';
  }
}
