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
  String get accentBlue => 'Azul';

  @override
  String get accentYellow => 'Amarillo';

  @override
  String get accentPink => 'Rosa';

  @override
  String get accentViolet => 'Violeta';

  @override
  String get accentOrange => 'Naranja';

  @override
  String get accentGreen => 'Verde';

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
  String get appearanceInherited => 'Hereda de la tarea padre, etiqueta o tipo';

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
}
