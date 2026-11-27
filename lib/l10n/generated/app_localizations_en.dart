// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Cadence';

  @override
  String get navToday => 'Today';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navReview => 'Review';

  @override
  String get navBooks => 'Books';

  @override
  String get navPomodoro => 'Pomodoro';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get navComponents => 'Components';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionComplete => 'Complete';

  @override
  String get actionReopen => 'Reopen';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get actionChange => 'Change';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionMoreOptions => 'More options';

  @override
  String get actionDecrease => 'Decrease';

  @override
  String get actionIncrease => 'Increase';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeAutomatic => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsColor => 'Color';

  @override
  String get accentBlue => 'Ice blue';

  @override
  String get accentYellow => 'Gold';

  @override
  String get accentPink => 'Pink';

  @override
  String get accentViolet => 'Lavender';

  @override
  String get accentOrange => 'Coral';

  @override
  String get accentGreen => 'Mint';

  @override
  String get settingsLightsOut => 'Lights out (high contrast)';

  @override
  String get settingsLightsOutHintDark =>
      'Pure black (OLED) and high-contrast text in dark mode';

  @override
  String get settingsLightsOutHintLight =>
      'Used in dark or automatic mode (pure black and high contrast)';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageAutomatic => 'Automatic (device)';

  @override
  String get settingsNavBar => 'Navigation bar';

  @override
  String get navBarPreview => 'Preview';

  @override
  String navBarPreviewDetail(int count, int max) {
    return '$count of $max tabs';
  }

  @override
  String get navBarHelper =>
      'The first tab opens with the app. Screens outside the bar stay available in the side menu.';

  @override
  String get navBarInBar => 'In bar';

  @override
  String get navBarDragToOrder => 'Drag to reorder';

  @override
  String get navBarInDrawer => 'In side menu';

  @override
  String get navBarInitialTab => 'Start tab';

  @override
  String navBarInitialTabMin(int min) {
    return 'Start tab · minimum $min tabs';
  }

  @override
  String navBarMinLimit(int min) {
    return 'Minimum $min tabs in bar';
  }

  @override
  String navBarMaxLimit(int max) {
    return 'Maximum of $max tabs reached';
  }

  @override
  String get navBarDrawerHint => 'Accessible from the side menu';

  @override
  String get navBarRestoreDefault => 'Restore default';

  @override
  String navBarDragSemantics(String label) {
    return 'Drag $label';
  }

  @override
  String get settingsFlashcards => 'Flashcards';

  @override
  String get settingsNewCardsPerDay => 'New cards per day';

  @override
  String get settingsDesiredRetention => 'Desired retention';

  @override
  String settingsDesiredRetentionHint(int percent) {
    return '$percent%: higher = more frequent reviews';
  }

  @override
  String get settingsDesiredRetentionSemantics =>
      'Desired retention percentage';

  @override
  String get settingsPomodoro => 'Pomodoro';

  @override
  String get settingsFocusMinutes => 'Focus (min)';

  @override
  String get settingsShortBreakMinutes => 'Short break (min)';

  @override
  String get settingsLongBreakMinutes => 'Long break (min)';

  @override
  String get settingsLongBreakEvery => 'Long break every';

  @override
  String settingsLongBreakEveryDetail(int count) {
    return '$count focus cycles';
  }

  @override
  String get settingsLongBreakEverySemantics => 'Focus cycles until long break';

  @override
  String get settingsAutoStartBreaks => 'Auto-start breaks';

  @override
  String get settingsAutoStartBreaksHint =>
      'Automatically start the break when focus ends';

  @override
  String get settingsSoundOnEnd => 'Sound on finish';

  @override
  String get settingsVibrateOnEnd => 'Vibrate on finish';

  @override
  String get settingsKeepScreenOn => 'Keep screen awake';

  @override
  String get settingsKeepScreenOnHint => 'While the pomodoro screen is open';

  @override
  String get settingsTasks => 'Tasks';

  @override
  String get settingsAllDayReminder => 'All-day reminder';

  @override
  String settingsAllDayReminderHint(int hour) {
    return 'All-day tasks remind at $hour:00 (minus chosen lead time)';
  }

  @override
  String get settingsAllDayReminderSemantics => 'All-day reminder hour';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsExportJson => 'Export JSON';

  @override
  String get settingsExportJsonHint => 'All data in a single file';

  @override
  String get settingsImportJson => 'Import JSON';

  @override
  String get settingsImportJsonHint =>
      'Merge or replace with data from a backup';

  @override
  String get settingsUpdates => 'Updates';

  @override
  String updateVersion(String version) {
    return 'Version $version';
  }

  @override
  String get updateIdle => 'Tap to check for a new version';

  @override
  String get updateChecking => 'Checking…';

  @override
  String get updateUpToDate => 'You are on the latest version';

  @override
  String updateAvailable(String version) {
    return 'Version $version available';
  }

  @override
  String get updateError => 'Could not check. Try again.';

  @override
  String get todayEmpty => 'Nothing for today yet.';

  @override
  String get todayOverdue => 'Overdue';

  @override
  String get todayUndated => 'No date';

  @override
  String get tasksLoadError => 'Could not load tasks.';

  @override
  String get tasksNew => 'New task';

  @override
  String get tasksCreate => 'Create task';

  @override
  String get tasksNewSubtask => 'New subtask';

  @override
  String get tasksEdit => 'Edit task';

  @override
  String get tasksAdd => 'Add task';

  @override
  String get tasksSearchHint => 'Search by title';

  @override
  String get tasksCloseSearch => 'Close search';

  @override
  String get tasksFilterAndSort => 'Filter and sort';

  @override
  String get tasksEmpty => 'No tasks yet.';

  @override
  String get tasksNoMatches => 'No tasks match these filters.';

  @override
  String get tasksClearFilters => 'Clear filters';

  @override
  String tasksCreated(String title) {
    return 'Created: $title';
  }

  @override
  String get taskKindSimple => 'Simple';

  @override
  String get taskKindStudy => 'Study';

  @override
  String get taskKindRoutine => 'Routine';

  @override
  String get taskKindEvent => 'Event';

  @override
  String get taskStatusTodo => 'To do';

  @override
  String get taskStatusDoing => 'In progress';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get priorityNone => 'None';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get reminderModeNotification => 'Notification';

  @override
  String get reminderModeAlarm => 'Alarm';

  @override
  String get reminderModeNotificationHint =>
      'Quiet notification in the status bar.';

  @override
  String get reminderModeAlarmHint =>
      'Rings like an alarm clock (even on silent) until you respond.';

  @override
  String get reminderFullScreenBanner =>
      'To appear on the lock screen, allow full-screen notifications in Android settings.';

  @override
  String get reminderAllowFullScreen => 'Allow full screen';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldPriority => 'Priority';

  @override
  String get fieldDates => 'Dates';

  @override
  String get fieldAllDay => 'All day';

  @override
  String get fieldStart => 'Start';

  @override
  String get fieldDue => 'Due';

  @override
  String get fieldNoDate => 'No date';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldRepeat => 'Repeat';

  @override
  String get repeatNo => 'No';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatEvery => 'Every';

  @override
  String get repeatUntil => 'Until';

  @override
  String get repeatNoEnd => 'No end';

  @override
  String get fieldAlarm => 'Alarm';

  @override
  String get fieldReminder => 'Reminder';

  @override
  String get alarmNeedDue => 'Set a due date to use an alarm.';

  @override
  String get reminderNone => 'None';

  @override
  String get reminderAtTime => 'At time';

  @override
  String get reminder5Min => '5 min before';

  @override
  String get reminder10Min => '10 min before';

  @override
  String get reminder15Min => '15 min before';

  @override
  String get reminder30Min => '30 min before';

  @override
  String get reminder1Hour => '1 hour before';

  @override
  String get reminder1Day => '1 day before';

  @override
  String get fieldEstimatedPomodoros => 'Estimated pomodoros';

  @override
  String get fieldTags => 'Tags';

  @override
  String get tagNew => 'New tag';

  @override
  String get fieldIconAndColor => 'Icon and color';

  @override
  String get appearanceCustom => 'Custom';

  @override
  String get appearanceDefault => 'Default';

  @override
  String get appearanceTapToChange => 'Tap to change';

  @override
  String get appearanceInherited =>
      'Inherits from parent task, tag, or repetition';

  @override
  String get quickDateToday => 'Today';

  @override
  String get quickDateTomorrow => 'Tomorrow';

  @override
  String get quickDateNextWeek => 'In a week';

  @override
  String get pomodoroFocus => 'Focus';

  @override
  String get pomodoroShortBreak => 'Short break';

  @override
  String get pomodoroLongBreak => 'Long break';

  @override
  String get pomodoroStart => 'Start';

  @override
  String get pomodoroPause => 'Pause';

  @override
  String get pomodoroResume => 'Resume';

  @override
  String get pomodoroStop => 'Stop';

  @override
  String get pomodoroNoTask => 'No task';

  @override
  String get pomodoroLinkedTask => 'Linked task';

  @override
  String get pomodoroPickTask => 'Focus task';

  @override
  String get pomodoroPausedSuffix => 'paused';

  @override
  String get pomodoroFocusDone => 'Focus complete!';

  @override
  String get pomodoroFocusDoneShort => 'Focus complete';

  @override
  String pomodoroBreakDone(String kind) {
    return '$kind finished';
  }

  @override
  String pomodoroNextRunning(String kind) {
    return '$kind running';
  }

  @override
  String pomodoroNextLabel(String kind) {
    return 'Next: $kind';
  }

  @override
  String pomodoroStartNext(String kind) {
    return 'Start $kind';
  }

  @override
  String pomodoroCompleteTask(String title) {
    return 'Complete \"$title\"';
  }

  @override
  String get pomodoroCycleProgress => 'Cycle progress';

  @override
  String get agendaGoToday => 'Go to today';

  @override
  String get agendaGoToDate => 'Go to date';

  @override
  String get agendaView => 'View';

  @override
  String get agendaDay => 'Day';

  @override
  String get agendaWeek => 'Week';

  @override
  String get agenda3Days => '3 days';

  @override
  String get agendaMonth => 'Month';

  @override
  String get agendaCompletedPomodoros => 'Completed pomodoros';

  @override
  String get reviewNewDeck => 'New deck';

  @override
  String get reviewImportCsv => 'Import CSV';

  @override
  String get reviewNewCard => 'New card';

  @override
  String get reviewLoadError => 'Could not load cards.';

  @override
  String get reviewEmpty =>
      'No cards yet.\nTap + to create one or import a CSV.';

  @override
  String get reviewNow => 'Review now';

  @override
  String get reviewAllCards => 'All cards';

  @override
  String get reviewDecks => 'Decks';

  @override
  String get reviewNameLabel => 'Name';

  @override
  String get booksImportMarkdown => 'Import Markdown';

  @override
  String get booksNew => 'New book';

  @override
  String get booksLoadError => 'Could not load books.';

  @override
  String get booksEmpty =>
      'No books yet.\nTap + to create one or import .md files.';

  @override
  String get statsFocusTime => 'Focus time';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsDays => 'Days';

  @override
  String get statsWeeks => 'Weeks';

  @override
  String get statsMonths => 'Months';

  @override
  String get statsNoFocusInPeriod =>
      'No focus sessions recorded in these periods.';

  @override
  String get statsStartFocus => 'Start focus';

  @override
  String get statsFocusBy => 'Focus by';

  @override
  String get statsGroupTask => 'Task';

  @override
  String get statsGroupTag => 'Tag';

  @override
  String get statsGroupType => 'Type';

  @override
  String get statsNoFocusGroup => 'No focus in this period.';

  @override
  String get statsEstimatedVsDone => 'Pomodoros: estimated × completed';

  @override
  String get statsNoEstimated => 'No tasks with estimated pomodoros.';

  @override
  String get statsReviews => 'Reviews';

  @override
  String get statsAccuracy30Days => 'Accuracy (30 days)';

  @override
  String get statsStreakDay => 'Day streak';

  @override
  String get statsStreakDays => 'Day streak';

  @override
  String get statsReviewsPerDay => 'Reviews per day';

  @override
  String get statsNoReviews14Days => 'No reviews in the last 14 days.';

  @override
  String get statsDueNext7Days => 'Cards due in the next 7 days';

  @override
  String get statsNoDueThisWeek => 'No cards due this week.';

  @override
  String get statsRoutinesDone => 'Completed routines';

  @override
  String get statsLess => 'less';

  @override
  String get statsMore => 'more';

  @override
  String get accountTooltip => 'Account and sync';

  @override
  String get accountSyncing => 'Syncing';

  @override
  String get accountOffline => 'Offline: will sync later';

  @override
  String get accountPending => 'Changes pending sync';

  @override
  String get accountError => 'Sync error';

  @override
  String get accountSynced => 'Synced';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionBack => 'Back';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionDrag => 'Drag';

  @override
  String get tasksEmptyCreated => 'No tasks created yet.';

  @override
  String get tasksExpandSubtasks => 'Show subtasks';

  @override
  String get tasksCollapseSubtasks => 'Collapse subtasks';

  @override
  String get tasksSortBy => 'Sort by';

  @override
  String get tasksSortManual => 'Manual';

  @override
  String get tasksSortDue => 'Due date';

  @override
  String get tasksSortPriority => 'Priority';

  @override
  String get tasksSortNewest => 'Newest';

  @override
  String get tasksSortTitle => 'Title';

  @override
  String get fieldStatus => 'Status';

  @override
  String get taskTagSingle => 'Tag';

  @override
  String taskTagCount(int count) {
    return '$count tags';
  }

  @override
  String get taskLoadOneError => 'Could not load task.';

  @override
  String get taskNotFound => 'Task not found.';

  @override
  String get taskSingular => 'Task';

  @override
  String get subtaskSingular => 'Subtask';

  @override
  String subtaskOf(String title) {
    return 'Subtask of $title';
  }

  @override
  String get taskChangeStatus => 'Change status';

  @override
  String taskPriorityBadge(String label) {
    return '$label priority';
  }

  @override
  String get fieldRecurrence => 'Repeat';

  @override
  String get subtasksSection => 'Subtasks';

  @override
  String get subtasksAddHint => 'Add subtask';

  @override
  String get routineHistory => 'History';

  @override
  String get routineNoStreak => 'No active streak';

  @override
  String get routineNotCompletedYet => 'Not completed yet';

  @override
  String routineTotalCompletions(int count, String unit) {
    return '$count $unit total';
  }

  @override
  String routineStreakDays(int count, String unit) {
    return '$count $unit';
  }

  @override
  String get routineDaySingular => 'day in a row';

  @override
  String get routineDayPlural => 'days in a row';

  @override
  String get routineTimeSingular => 'time in a row';

  @override
  String get routineTimePlural => 'times in a row';

  @override
  String get routineEnded => 'Routine ended: that was the last occurrence.';

  @override
  String routineNext(String when) {
    return 'Routine completed. Next: $when.';
  }

  @override
  String taskDeleted(String title) {
    return '\"$title\" deleted';
  }

  @override
  String taskDeletedWithSubtasks(String title, int count) {
    return '\"$title\" and $count subtask(s) deleted';
  }

  @override
  String get repeatIntervalSemantics => 'Repeat interval';

  @override
  String get unitDay => 'day';

  @override
  String get unitDays => 'days';

  @override
  String get unitWeek => 'week';

  @override
  String get unitWeeks => 'weeks';

  @override
  String fieldClearLabel(String label) {
    return 'Clear $label';
  }

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes min before';
  }

  @override
  String get hubAdd => 'ADD';

  @override
  String get hubFlashcard => 'Flashcard';

  @override
  String get hubPage => 'Page';

  @override
  String get hubPages => 'Pages';

  @override
  String get hubNewPage => 'New page';

  @override
  String get hubNoCardsYet => 'No cards yet';

  @override
  String get hubReviewTask => 'Review this task';

  @override
  String get hubCard => 'Card';

  @override
  String hubFocusTimeValue(String duration) {
    return 'Focus time: $duration';
  }

  @override
  String get hubNoSessionsYet => 'No sessions yet';

  @override
  String hubFocusSessions(int count, String unit) {
    return '$count focus $unit (includes subtasks)';
  }

  @override
  String get unitSession => 'session';

  @override
  String get unitSessions => 'sessions';

  @override
  String get hubNoPagesYet => 'No pages yet';

  @override
  String get hubUnlink => 'Unlink';

  @override
  String get hubOpenNotebook => 'Open notebook';

  @override
  String get hubLinkExistingPage => 'Link existing page';

  @override
  String get hubLinkPage => 'Link page';

  @override
  String get hubNoBookPages => 'No pages in Books yet.';

  @override
  String get hubNoBookPagesHint =>
      'Create pages in the Books tab to link them.';

  @override
  String hubEstimatedVsDone(int done, int estimated) {
    return 'Estimated × completed: $done of $estimated';
  }

  @override
  String agendaNextTaskIn(String wait) {
    return 'Next task in $wait';
  }

  @override
  String get agendaSearchTask => 'Search task';

  @override
  String get agendaNoDatedTasks => 'No dated tasks found.';

  @override
  String get agendaAllDayShort => 'all\nday';

  @override
  String get agendaExpandAllDay => 'Expand all-day';

  @override
  String get agendaCollapseAllDay => 'Collapse all-day';

  @override
  String get agendaRoutineRescheduled =>
      'Routine rescheduled (all occurrences).';

  @override
  String get reviewEmptyAction => 'Create deck';

  @override
  String get reviewEmptyAlt =>
      'No cards yet.\nCreate one with + or import a CSV.';

  @override
  String get reviewNothingDue => 'Nothing to review right now';

  @override
  String reviewDueNow(int count) {
    return '$count due right now';
  }

  @override
  String reviewNextIn(int minutes) {
    return 'Next card in $minutes min.';
  }

  @override
  String get reviewAll => 'Review all';

  @override
  String reviewDeckDueSuffix(int count) {
    return '$count due';
  }

  @override
  String get reviewSessionTitle => 'Review';

  @override
  String get reviewUndoLast => 'Undo last rating';

  @override
  String get reviewProgressSemantics => 'Session progress';

  @override
  String get reviewShowAnswer => 'Show answer';

  @override
  String get reviewCardNew => 'new';

  @override
  String get reviewGradeAgain => 'Again';

  @override
  String get reviewGradeHard => 'Hard';

  @override
  String get reviewGradeGood => 'Good';

  @override
  String get reviewGradeEasy => 'Easy';

  @override
  String reviewNextCardSoon(int minutes) {
    return 'Next card in $minutes min.\nIt will appear here automatically.';
  }

  @override
  String get reviewNothingDueDot => 'Nothing to review right now.';

  @override
  String reviewAllDone(int count, String unit) {
    return 'All caught up! $count $unit in this session.';
  }

  @override
  String get unitCard => 'card';

  @override
  String get unitCards => 'cards';

  @override
  String get reviewRemainingSingular => 'card left';

  @override
  String get reviewRemainingPlural => 'cards left';

  @override
  String get booksOptions => 'Book options';

  @override
  String get booksExportZip => 'Export (.zip)';

  @override
  String booksDeleteTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get booksDeleteMessage => 'All pages in this book will be deleted.';

  @override
  String statsSameAs(String period) {
    return 'same as $period';
  }

  @override
  String statsVs(String delta, String period) {
    return '$delta vs $period';
  }

  @override
  String get statsYesterday => 'yesterday';

  @override
  String get statsPrevious => 'previous';

  @override
  String statsFocusHoursPer(String unit) {
    return 'Focus hours per $unit';
  }

  @override
  String get statsUnitDay => 'day';

  @override
  String get statsUnitWeek => 'week';

  @override
  String get statsUnitMonth => 'month';

  @override
  String get statsFocusChartSemantics => 'Focus hours chart';

  @override
  String get statsDeletedTask => 'Deleted task';

  @override
  String get statsNoTag => 'No tag';

  @override
  String get statsDeletedTag => 'Deleted tag';

  @override
  String statsOf(int done, int total) {
    return '$done of $total';
  }

  @override
  String get statsReviewsChartSemantics => 'Reviews per day chart';

  @override
  String get statsDueChartSemantics => 'Upcoming due cards chart';

  @override
  String get statsTodayLower => 'today';

  @override
  String get statsTodayWithOverdue => 'Today (with overdue)';

  @override
  String get statsUnitReview => 'review';

  @override
  String get statsUnitReviews => 'reviews';

  @override
  String statsRoutineTotal(int count, String unit, int weeks) {
    return '$count $unit in the last $weeks weeks';
  }

  @override
  String get unitCompletion => 'completion';

  @override
  String get unitCompletions => 'completions';

  @override
  String statsWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get settingsAlarmDiagnostics => 'Alarm diagnostics';

  @override
  String get settingsAlarmDiagnosticsOk => 'All set to ring';

  @override
  String settingsAlarmDiagnosticsIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settings need attention',
      one: '1 setting needs attention',
    );
    return '$_temp0';
  }

  @override
  String get diagnosticsRefresh => 'Check again';

  @override
  String get diagnosticsOpenSettings => 'Open settings';

  @override
  String get diagnosticsStatusOk => 'OK';

  @override
  String get diagnosticsStatusIssue => 'Attention';

  @override
  String get diagnosticsSummaryOk =>
      'Your device is ready to deliver reminders and alarms on time.';

  @override
  String get diagnosticsSummaryIssues =>
      'Some Android settings may block or delay your reminders.';

  @override
  String get diagNotificationsTitle => 'App notifications';

  @override
  String get diagNotificationsOk => 'Allowed by Android.';

  @override
  String get diagNotificationsOff =>
      'Turned off — no reminders or alarms will show up.';

  @override
  String get diagRemindersChannelTitle => 'Reminders channel';

  @override
  String get diagRemindersChannelOk => 'Sound and alerts enabled.';

  @override
  String get diagRemindersChannelMuted =>
      'This channel is muted — standard reminders will not alert.';

  @override
  String get diagAlarmsChannelTitle => 'Alarms channel';

  @override
  String get diagAlarmsChannelOk => 'Alarm channel enabled.';

  @override
  String get diagAlarmsChannelMuted =>
      'This channel is muted — tasks in Alarm mode will not ring.';

  @override
  String get diagExactAlarmsTitle => 'Exact alarms';

  @override
  String get diagExactAlarmsOk => 'The app can schedule to the exact minute.';

  @override
  String get diagExactAlarmsDenied =>
      'Denied — reminders may be delayed or missed.';

  @override
  String get diagFullScreenTitle => 'Full-screen alarms';

  @override
  String get diagFullScreenOk => 'Can appear over the lock screen.';

  @override
  String get diagFullScreenDenied =>
      'Not allowed — alarms may not show over the lock screen.';

  @override
  String get diagBatteryTitle => 'Battery optimization';

  @override
  String get diagBatteryOk => 'Unrestricted in the background.';

  @override
  String get diagBatteryRestricted =>
      'Restricted — devices (e.g., Samsung sleeping apps) may delay alarms.';

  @override
  String get formDiagnosticsWarning =>
      'This reminder may not ring: check notification and alarm permissions.';

  @override
  String get formDiagnosticsAction => 'View diagnostics';

  @override
  String get actionSnooze => 'Snooze';

  @override
  String get snooze10Min => '10 min';

  @override
  String get snooze1Hour => '1 h';

  @override
  String snoozeTomorrowMorning(String time) {
    return 'Tomorrow morning ($time)';
  }

  @override
  String snoozedUntil(String when) {
    return 'Reminder snoozed until $when.';
  }

  @override
  String get settingsDailyReminders => 'Daily reminders';

  @override
  String get settingsDailySummary => 'Daily task summary';

  @override
  String settingsDailySummaryHint(int hour) {
    return 'Notifies about today\'s and overdue tasks at $hour:00';
  }

  @override
  String get settingsDailySummaryOffHint =>
      'Get a daily summary of pending tasks';

  @override
  String get settingsDailySummaryHourSemantics => 'Daily task summary hour';

  @override
  String get settingsDailyReview => 'Daily flashcards reminder';

  @override
  String settingsDailyReviewHint(int hour) {
    return 'Reminds at $hour:00 when cards are due';
  }

  @override
  String get settingsDailyReviewOffHint =>
      'Notifies when cards are due (silent if none)';

  @override
  String get settingsDailyReviewHourSemantics =>
      'Daily flashcards reminder hour';

  @override
  String get settingsHourLabel => 'Hour (h)';

  @override
  String get fieldReminders => 'Reminders';

  @override
  String get remindersHelperMultiple =>
      'Pick one or more times to be reminded.';

  @override
  String get fieldNagIfOverdue => 'Keep reminding if overdue';

  @override
  String get nagOff => 'Off';

  @override
  String nagEveryMinutes(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String nagHint(int max) {
    return 'Repeats up to $max× after the scheduled time until completed.';
  }

  @override
  String nagHubDetail(int minutes, int max) {
    return 'Every $minutes min (up to $max×)';
  }

  @override
  String get booksRename => 'Rename book';

  @override
  String booksExported(int count) {
    return 'Book exported ($count pages).';
  }

  @override
  String get booksNoMarkdown => 'No .md file found.';

  @override
  String get booksImportedDefault => 'Imported';

  @override
  String get booksImportAsBook => 'Import as book';

  @override
  String get booksBookTitle => 'Book title';

  @override
  String get actionImport => 'Import';

  @override
  String booksPagesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages imported.',
      one: '1 page imported.',
    );
    return '$_temp0';
  }

  @override
  String get pageNew => 'New page';

  @override
  String get pageNewSub => 'New subpage';

  @override
  String get pageRename => 'Rename page';

  @override
  String pageDeleteTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get pageDeleteMessage => 'Subpages will be deleted too.';

  @override
  String get pageExported => 'Page exported.';

  @override
  String get bookFallbackTitle => 'Book';

  @override
  String get bookOptions => 'Book options';

  @override
  String get bookImportPages => 'Import pages (.md)';

  @override
  String get bookExportZip => 'Export (.zip)';

  @override
  String get pagesLoadError => 'Could not load the pages.';

  @override
  String bookTaskNotebook(String title) {
    return 'Notebook of task $title';
  }

  @override
  String get pagesEmpty => 'No pages yet.';

  @override
  String get pageCreate => 'Create page';

  @override
  String get pageOptions => 'Page options';

  @override
  String get actionMoveUp => 'Move up';

  @override
  String get actionMoveDown => 'Move down';

  @override
  String get pageExportMd => 'Export (.md)';

  @override
  String get pageSelectTextFirst => 'Select some text first.';

  @override
  String get pageUseAsFront => 'Use as front';

  @override
  String get pageUseAsBack => 'Use as back';

  @override
  String get pageFlashcardCreated => 'Flashcard created.';

  @override
  String get pageLinkTask => 'Link to task';

  @override
  String get pageWriteHere => 'Write here…';

  @override
  String get pageNotFound => 'Page not found.';

  @override
  String get pageReadMode => 'Reading mode';

  @override
  String get pageCreateCardFromSelection => 'Create flashcard from selection';

  @override
  String get pageIcon => 'Icon';

  @override
  String get pageDelete => 'Delete page';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCut => 'Cut';

  @override
  String get actionPaste => 'Paste';

  @override
  String get pageCreateCard => 'Create flashcard';

  @override
  String get pageIconTooltip => 'Page icon';

  @override
  String get editorImageByLink => 'Image from link';

  @override
  String get editorImageUrl => 'Image address (https://…)';

  @override
  String get actionInsert => 'Insert';

  @override
  String get cardDeleted => 'Card deleted';

  @override
  String get cardsNoneInFile => 'No cards found in the file.';

  @override
  String cardsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards imported.',
      one: '1 card imported.',
    );
    return '$_temp0';
  }

  @override
  String get cardsImportTitle => 'Import cards';

  @override
  String cardsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards found.',
      one: '1 card found.',
    );
    return '$_temp0';
  }

  @override
  String cardsSkippedLines(String lines) {
    return 'Skipped lines (no front or back): $lines';
  }

  @override
  String get fieldDeck => 'Deck';

  @override
  String get deckNone => 'No deck';

  @override
  String get cardEdit => 'Edit card';

  @override
  String get cardFront => 'Front';

  @override
  String get cardBack => 'Back';

  @override
  String get cardMarkdownHint =>
      'Supports **bold**, *italic*, `code` and - lists';

  @override
  String get cardSave => 'Save card';

  @override
  String get deckRename => 'Rename deck';

  @override
  String deckDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deckDeleteMessage => 'The cards are kept, without a deck.';

  @override
  String get deckOptions => 'Deck options';

  @override
  String get deckDelete => 'Delete deck';

  @override
  String get cardsEmptyHere => 'No cards here yet.';

  @override
  String get cardCreate => 'Create card';

  @override
  String cardsReviewCount(int count) {
    return 'Review $count now';
  }

  @override
  String get cardSuspended => 'Suspended';

  @override
  String get cardNew => 'New';

  @override
  String cardNextReview(String when) {
    return 'Review: $when';
  }

  @override
  String get cardOptions => 'Card options';

  @override
  String get cardReactivate => 'Reactivate';

  @override
  String get cardSuspend => 'Suspend';

  @override
  String get syncCloudHasData => 'There is already data in the cloud';

  @override
  String get syncCloudHasDataOtherAccount =>
      'The new account has a different Google Drive with My Cadence data. What should happen to the data on this device?';

  @override
  String get syncCloudHasDataThisAccount =>
      'This account already has My Cadence data. What should happen to the data on this device?';

  @override
  String get syncUseCloudOnly => 'Use only the cloud data';

  @override
  String get syncMerge => 'Merge';

  @override
  String get syncCloudLoaded =>
      'Cloud data loaded. A copy of the previous data was saved.';

  @override
  String get backupManual => 'Manual backup';

  @override
  String get backupRestoreCopy => 'Restore copy';

  @override
  String get backupDailyCopyHint => 'The app keeps one copy per day';

  @override
  String get syncWithDrive => 'Sync with Google Drive';

  @override
  String get syncDriveExplain =>
      'Your data stays in a private app folder in your Google Drive, using your own storage. Only this app can see that folder.';

  @override
  String get syncConnectGoogle => 'Connect with Google';

  @override
  String get syncNotConfigured =>
      'Google sign-in is not configured in this app yet.';

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusOffline => 'Offline. Will sync when back online.';

  @override
  String get syncStatusPending => 'Changes to sync';

  @override
  String get syncStatusError => 'Sync error';

  @override
  String syncStatusSyncedAgo(String ago) {
    return 'Synced $ago';
  }

  @override
  String get syncStatusNever => 'Not synced yet';

  @override
  String get syncAgoNow => 'just now';

  @override
  String syncAgoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String syncAgoHours(int count) {
    return '$count h ago';
  }

  @override
  String syncAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get syncSignInAgain => 'Sign in again';

  @override
  String get syncUseCloudData => 'Use the cloud data';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncAuto => 'Automatic sync';

  @override
  String get syncAutoHint =>
      'On open, when returning to the app and after changes';

  @override
  String get syncSwitchAccount => 'Switch account';

  @override
  String get syncDisconnect => 'Disconnect';

  @override
  String get syncDisconnected =>
      'Disconnected. Your data stays on this device.';

  @override
  String get syncDeviceName => 'Name of this device';

  @override
  String get syncThisDevice => 'This device';

  @override
  String get syncLog => 'Sync log';

  @override
  String get syncLogEmpty => 'No syncs yet.';

  @override
  String get backupExported => 'Backup exported.';

  @override
  String get backupNoCopies => 'No saved copies yet.';

  @override
  String get backupReplaceAllQuestion => 'Replace everything?';

  @override
  String get backupReplaceWarning =>
      'The data on this device will be replaced by the file. A copy of the current data is saved in the app first.';

  @override
  String get backupReplace => 'Replace';

  @override
  String get backupReplaced =>
      'Data replaced. A copy of the previous data was saved.';

  @override
  String get backupNothingNew => 'Nothing new in the file.';

  @override
  String backupMerged(int inserted, int updated, int deleted) {
    return 'Backup merged: $inserted new, $updated updated, $deleted deleted.';
  }

  @override
  String get backupImportTitle => 'Import backup';

  @override
  String backupFrom(String when) {
    return 'From $when';
  }

  @override
  String countTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String countCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
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
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get backupMerge => 'Merge';

  @override
  String get backupMergeHint =>
      'Combines with the data on this device. Nothing is deleted.';

  @override
  String get backupReplaceAll => 'Replace everything';

  @override
  String get backupReplaceAllHint =>
      'Replaces the data on this device with the file.';

  @override
  String get pickerIcon => 'Icon';

  @override
  String get pickerColor => 'Color';

  @override
  String get pickerUseDefault => 'Use default';

  @override
  String get pickerColorSection => 'COLOR';

  @override
  String get pickerSearchIcon => 'Search icon';

  @override
  String get actionApply => 'Apply';

  @override
  String timelineFocus(String range) {
    return 'Focus $range';
  }

  @override
  String get fieldWhen => 'When';

  @override
  String get fieldDetails => 'Details';

  @override
  String get fieldStudy => 'Linked study';

  @override
  String get repeatStarts => 'Starts';

  @override
  String get repeatEnds => 'Ends';

  @override
  String get repeatNever => 'Never';

  @override
  String get fieldTimeRange => 'Time';

  @override
  String get timeRangeFrom => 'Start';

  @override
  String get timeRangeTo => 'End';

  @override
  String get repeatDatesHint =>
      '“Starts” is the first time and “Ends” the last repetition.';

  @override
  String get datesHint =>
      'Start is when you begin; due is when it must be done.';

  @override
  String get remindersNeedDate => 'Set a date to get reminders.';

  @override
  String reminderOnTheDay(int hour) {
    return 'On the day, at $hour:00';
  }

  @override
  String reminderDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String reminderWeeksBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks before',
      one: '1 week before',
    );
    return '$_temp0';
  }

  @override
  String get remindersBaseStart => 'Counted from the start time.';

  @override
  String get remindersBaseDue => 'Counted from the due time.';

  @override
  String remindersBaseAllDay(int hour) {
    return 'All-day tasks remind at $hour:00 (change it in Settings).';
  }

  @override
  String get remindersEachRepeat => 'They apply to every repetition.';

  @override
  String remindersPreview(String when) {
    return 'Will remind: $when';
  }

  @override
  String remindersPreviewFirst(String when) {
    return 'First time: $when';
  }

  @override
  String get fieldBooks => 'Books';

  @override
  String get fieldDecks => 'Decks';

  @override
  String get studyHint =>
      'Link books and decks to this task to follow them in the hub and stats.';

  @override
  String get linkBook => 'Link book';

  @override
  String get linkDeck => 'Link deck';

  @override
  String get newBook => 'New book';

  @override
  String get newDeck => 'New deck';

  @override
  String get linkBooksTitle => 'Link books';

  @override
  String get linkDecksTitle => 'Link decks';

  @override
  String get noBooksYet => 'No books yet.';

  @override
  String get noDecksYet => 'No decks yet.';

  @override
  String unlinkItem(String name) {
    return 'Unlink $name';
  }

  @override
  String get hubLinkedBooks => 'Linked books';

  @override
  String get hubLinkedDecks => 'Linked decks';

  @override
  String get deleteTaskTitle => 'Delete task?';

  @override
  String get deleteTaskAlsoHint => 'Also delete what is linked to it:';

  @override
  String deleteAlsoBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books (with their pages)',
      one: '1 book (with its pages)',
    );
    return '$_temp0';
  }

  @override
  String deleteAlsoPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linked pages',
      one: '1 linked page',
    );
    return '$_temp0';
  }

  @override
  String deleteAlsoDecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decks (cards stay, without a deck)',
      one: '1 deck (cards stay, without a deck)',
    );
    return '$_temp0';
  }

  @override
  String get deleteAlsoNoUndo =>
      'What you check here is not restored by \"Undo\".';

  @override
  String get repeatTimeHint => 'The time applies to every repetition.';

  @override
  String get formInfoTooltip => 'How it works';

  @override
  String get formInfoDatesTitle => 'Start and due';

  @override
  String get formInfoRepeatTitle => 'Repetition';

  @override
  String get formInfoRemindersTitle => 'Reminders';

  @override
  String get formInfoReminders =>
      'With a time, they count from the start (or from the due time if there is no start). For all-day tasks, they ring at the hour set in Settings, on the day or days before. In a routine, they apply to every repetition.';

  @override
  String get formInfoModesTitle => 'Notification or alarm';

  @override
  String get formInfoNagTitle => 'Nag if overdue';

  @override
  String get formInfoStudyTitle => 'Linked study';

  @override
  String get deckSpeech => 'Read aloud';

  @override
  String get deckSpeechHint =>
      'Uses the phone\'s own voice (text-to-speech). Pick the language for each side of the card.';

  @override
  String get deckSpeechFront => 'Front';

  @override
  String get deckSpeechBack => 'Back';

  @override
  String get deckSpeechOff => 'Don\'t read';

  @override
  String get deckSpeechAuto => 'Read automatically while reviewing';

  @override
  String get deckSpeechNoVoices =>
      'No voices found. Install voices in Android Settings → Text-to-speech.';

  @override
  String get speakFront => 'Listen to front';

  @override
  String get speakFrontSlow => 'Listen to front slowly';

  @override
  String get speakBack => 'Listen to back';

  @override
  String get speakBackSlow => 'Listen to back slowly';

  @override
  String get speechDefault => 'Default voice';

  @override
  String get speechDefaultHint =>
      'Applies to every deck without its own setting.';

  @override
  String get speechUseDefault => 'Use the default voice';

  @override
  String get speechDeckTooltip => 'Deck voice';

  @override
  String get manualTimeLog => 'Log time';

  @override
  String get manualTimeTitle => 'Log time spent';

  @override
  String get manualTimeHint =>
      'For when you worked without the pomodoro. It counts toward focus time and stats, but not as a completed pomodoro.';

  @override
  String get manualTimeHours => 'Hours';

  @override
  String get manualTimeMinutes => 'Minutes';

  @override
  String get manualTimeDay => 'Day';

  @override
  String get manualTimeStart => 'Started at';

  @override
  String manualTimeSaved(String duration) {
    return '$duration logged.';
  }

  @override
  String get manualTimeEntries => 'Manual entries';

  @override
  String get manualTimeDelete => 'Delete entry';

  @override
  String get statsTagHint =>
      'A task with several tags counts its time in each; subtasks inherit the parent\'s tags.';

  @override
  String get taskStatusPaused => 'Paused';

  @override
  String get rescheduleAction => 'Reschedule';

  @override
  String get rescheduleChoose => 'Pick a date';

  @override
  String rescheduledTo(String date) {
    return 'Rescheduled to $date.';
  }

  @override
  String get rescheduleResumesHint =>
      'Rescheduling also resumes the paused task.';

  @override
  String get pausedBanner =>
      'Paused: it won\'t show in Today, overdue or reminders until resumed.';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get fieldEstimatedTime => 'Estimated time';

  @override
  String get estimateHours => 'Hours';

  @override
  String get estimateHint =>
      'Compared with the focus time done (pomodoros and logged time).';

  @override
  String hubEstimatedTime(String done, String estimated) {
    return 'Estimated × done: $done of $estimated';
  }

  @override
  String statsOfTime(String done, String total) {
    return '$done of $total';
  }

  @override
  String get statsEstimatedVsDoneTime => 'Time: estimated × done';

  @override
  String get statsNoEstimatedTime => 'No task with an estimated time.';

  @override
  String get quickAddHint => 'New task (#tag to label)';

  @override
  String get searchAllTooltip => 'Search everything';

  @override
  String get searchHint => 'Search tasks, pages and cards';

  @override
  String get searchIntro =>
      'Type at least 2 letters. Search looks at titles, notes, page text and both sides of cards.';

  @override
  String get searchNoResults => 'Nothing found.';

  @override
  String get searchClear => 'Clear';

  @override
  String get weekReviewTitle => 'Weekly review';

  @override
  String get weekPrevious => 'Previous week';

  @override
  String get weekNext => 'Next week';

  @override
  String get weekCompleted => 'Completed';

  @override
  String get weekRoutines => 'Routines done';

  @override
  String get weekFocus => 'Focus';

  @override
  String get weekByTag => 'Time by tag';

  @override
  String get weekNoFocus => 'No focus time this week.';

  @override
  String get weekOverdue => 'Left behind';

  @override
  String get weekNoOverdue => 'Nothing overdue. Nice!';

  @override
  String get weekAllToToday => 'All to today';

  @override
  String weekMovedToToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks moved to today.',
      one: '1 task moved to today.',
    );
    return '$_temp0';
  }

  @override
  String get weekNoCompleted => 'No task completed this week.';

  @override
  String get templateSave => 'Save as template';

  @override
  String get templateName => 'Template name';

  @override
  String templateSaved(String name) {
    return 'Template \"$name\" saved.';
  }

  @override
  String get templateUse => 'Template';

  @override
  String get templatePickTitle => 'Create from a template';

  @override
  String get templatePickHint =>
      'The task gets the template\'s tags, look, estimate, reminders, subtasks, books and decks; then pick the dates.';

  @override
  String get templateDelete => 'Delete template';

  @override
  String templateSubtasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subtasks',
      one: '1 subtask',
      zero: 'no subtasks',
    );
    return '$_temp0';
  }

  @override
  String get weekReviewShort => 'Week';

  @override
  String get cardsImportFromFile => 'Load file';

  @override
  String get cardsImportTextLabel => 'Cards (front;back)';

  @override
  String get cardsImportTextHint => 'apple;manzana\nbook;libro';

  @override
  String get cardsImportTextHelper =>
      'One card per line, separated by a semicolon (;)';

  @override
  String get cardsSkipDuplicates => 'Skip fronts already in this deck';

  @override
  String cardsDuplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicates skipped.',
      one: '1 duplicate skipped.',
    );
    return '$_temp0';
  }

  @override
  String cardsAllDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count cards are already in this deck.',
      one: 'This card is already in this deck.',
    );
    return '$_temp0';
  }

  @override
  String get cardsNoneInText => 'No valid cards found.';

  @override
  String cardsImportActionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count cards',
      one: 'Import 1 card',
    );
    return '$_temp0';
  }

  @override
  String get navTags => 'Tags';

  @override
  String get tagEdit => 'Edit tag';

  @override
  String get tagChangeColor => 'Change color';

  @override
  String get tagOptions => 'Tag options';

  @override
  String get tagDuplicateError => 'A tag with this name already exists.';

  @override
  String get tagsEmpty => 'No tags created yet.';

  @override
  String get tagsLoadError => 'Couldn\'t load tags.';

  @override
  String tagTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String tagDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get tagDeleteUnusedMessage => 'No tasks use this tag.';

  @override
  String tagDeleteUsedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This tag is on $count tasks; they will lose the tag.',
      one: 'This tag is on 1 task; it will lose the tag.',
    );
    return '$_temp0';
  }

  @override
  String tagDeleted(String name) {
    return 'Tag \"$name\" deleted.';
  }

  @override
  String get tagViewTasks => 'View tasks';

  @override
  String get cardsSearchHint => 'Search cards';

  @override
  String get cardsFilterAll => 'All';

  @override
  String get cardsFilterDue => 'Due';

  @override
  String get cardsFilterNew => 'New';

  @override
  String get cardsFilterSuspended => 'Suspended';

  @override
  String get cardsExportCsv => 'Export CSV';

  @override
  String cardsExportSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards ready in front;back format.',
      one: '1 card ready in front;back format.',
    );
    return '$_temp0';
  }

  @override
  String get cardsExportCopy => 'Copy CSV';

  @override
  String get cardsExportSaveFile => 'Save file';

  @override
  String get cardsCsvCopied => 'CSV copied.';

  @override
  String get cardsCsvSaved => 'CSV file saved.';

  @override
  String get navTrash => 'Trash';

  @override
  String get trashHint => 'Deleted items stay here so you can restore them.';

  @override
  String get trashEmpty => 'Trash is empty.';

  @override
  String get trashFilterAll => 'All';

  @override
  String get trashFilterCards => 'Cards';

  @override
  String get trashKindTask => 'Task';

  @override
  String get trashKindTag => 'Tag';

  @override
  String get trashKindDeck => 'Deck';

  @override
  String get trashKindCard => 'Card';

  @override
  String get trashKindBook => 'Book';

  @override
  String get trashKindPage => 'Page';

  @override
  String get trashRestore => 'Restore';

  @override
  String trashRestored(String title) {
    return '\"$title\" restored.';
  }

  @override
  String get speechEngineLabel => 'Speech engine (this device)';

  @override
  String get speechEngineDefault => 'Device default';

  @override
  String get speechEngineHint =>
      'Lists TTS engines installed on Android (e.g. Google, SherpaTTS, Vocalizer).';

  @override
  String get speechVoiceSpecific => 'Specific voice';

  @override
  String get speechVoiceDefault => 'Language default';

  @override
  String get speechTestVoice => 'Test voice';

  @override
  String get speechTestSample => 'Hello! This is the selected voice.';

  @override
  String get repeatSkipMissed => 'Don\'t pile up missed days';

  @override
  String get repeatSkipMissedHint =>
      'If missed, marks it as not completed and moves to the next occurrence.';

  @override
  String get repeatSkipMissedInfo =>
      'By default, routines don\'t pile up: if a day passes without completing it, that occurrence is logged as not completed in the calendar and metrics, and the routine moves on. Turn it off to keep it in Overdue.';

  @override
  String routineMissedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missed',
      one: '1 missed',
    );
    return '$_temp0';
  }

  @override
  String get routineMarkAsDone => 'Mark as completed';

  @override
  String get routineMissedDialogTitle => 'Missed occurrence';

  @override
  String routineMissedDialogBody(String title) {
    return '\"$title\" wasn\'t completed on this day. You can mark it as completed or open the task.';
  }

  @override
  String get routineOpenTask => 'Open task';

  @override
  String statsRoutineSummary(int done, int missed, int rate, int weeks) {
    return '$done completed · $missed missed ($rate%) in the last $weeks weeks';
  }
}
