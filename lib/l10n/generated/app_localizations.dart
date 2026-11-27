import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'My Cadence'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get navToday;

  /// No description provided for @navTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get navTasks;

  /// No description provided for @navAgenda.
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navReview.
  ///
  /// In pt, this message translates to:
  /// **'Revisar'**
  String get navReview;

  /// No description provided for @navBooks.
  ///
  /// In pt, this message translates to:
  /// **'Books'**
  String get navBooks;

  /// No description provided for @navPomodoro.
  ///
  /// In pt, this message translates to:
  /// **'Pomodoro'**
  String get navPomodoro;

  /// No description provided for @navStats.
  ///
  /// In pt, this message translates to:
  /// **'Métricas'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @navComponents.
  ///
  /// In pt, this message translates to:
  /// **'Componentes'**
  String get navComponents;

  /// No description provided for @actionSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get actionCreate;

  /// No description provided for @actionEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get actionDelete;

  /// No description provided for @actionUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get actionUndo;

  /// No description provided for @actionClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get actionClose;

  /// No description provided for @actionSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get actionSearch;

  /// No description provided for @actionComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get actionComplete;

  /// No description provided for @actionReopen.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir'**
  String get actionReopen;

  /// No description provided for @actionDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Dispensar'**
  String get actionDismiss;

  /// No description provided for @actionChange.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get actionChange;

  /// No description provided for @actionDownload.
  ///
  /// In pt, this message translates to:
  /// **'Baixar'**
  String get actionDownload;

  /// No description provided for @actionMoreOptions.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get actionMoreOptions;

  /// No description provided for @actionDecrease.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir'**
  String get actionDecrease;

  /// No description provided for @actionIncrease.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar'**
  String get actionIncrease;

  /// No description provided for @settingsAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @themeAutomatic.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get themeAutomatic;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @settingsColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get settingsColor;

  /// No description provided for @accentBlue.
  ///
  /// In pt, this message translates to:
  /// **'Azul gelo'**
  String get accentBlue;

  /// No description provided for @accentYellow.
  ///
  /// In pt, this message translates to:
  /// **'Dourado'**
  String get accentYellow;

  /// No description provided for @accentPink.
  ///
  /// In pt, this message translates to:
  /// **'Rosa'**
  String get accentPink;

  /// No description provided for @accentViolet.
  ///
  /// In pt, this message translates to:
  /// **'Lavanda'**
  String get accentViolet;

  /// No description provided for @accentOrange.
  ///
  /// In pt, this message translates to:
  /// **'Coral'**
  String get accentOrange;

  /// No description provided for @accentGreen.
  ///
  /// In pt, this message translates to:
  /// **'Menta'**
  String get accentGreen;

  /// No description provided for @settingsLightsOut.
  ///
  /// In pt, this message translates to:
  /// **'Lights out (alto contraste)'**
  String get settingsLightsOut;

  /// No description provided for @settingsLightsOutHintDark.
  ///
  /// In pt, this message translates to:
  /// **'Preto puro (OLED) e texto em alto contraste no modo escuro'**
  String get settingsLightsOutHintDark;

  /// No description provided for @settingsLightsOutHintLight.
  ///
  /// In pt, this message translates to:
  /// **'Usado no modo escuro ou automático (preto puro e alto contraste)'**
  String get settingsLightsOutHintLight;

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @languageAutomatic.
  ///
  /// In pt, this message translates to:
  /// **'Automático (celular)'**
  String get languageAutomatic;

  /// No description provided for @settingsNavBar.
  ///
  /// In pt, this message translates to:
  /// **'Barra de navegação'**
  String get settingsNavBar;

  /// No description provided for @navBarPreview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia'**
  String get navBarPreview;

  /// No description provided for @navBarPreviewDetail.
  ///
  /// In pt, this message translates to:
  /// **'{count} de {max} abas'**
  String navBarPreviewDetail(int count, int max);

  /// No description provided for @navBarHelper.
  ///
  /// In pt, this message translates to:
  /// **'A primeira aba abre com o app. As telas fora da barra continuam no menu lateral.'**
  String get navBarHelper;

  /// No description provided for @navBarInBar.
  ///
  /// In pt, this message translates to:
  /// **'Na barra'**
  String get navBarInBar;

  /// No description provided for @navBarDragToOrder.
  ///
  /// In pt, this message translates to:
  /// **'Arraste para ordenar'**
  String get navBarDragToOrder;

  /// No description provided for @navBarInDrawer.
  ///
  /// In pt, this message translates to:
  /// **'No menu lateral'**
  String get navBarInDrawer;

  /// No description provided for @navBarInitialTab.
  ///
  /// In pt, this message translates to:
  /// **'Aba inicial'**
  String get navBarInitialTab;

  /// No description provided for @navBarInitialTabMin.
  ///
  /// In pt, this message translates to:
  /// **'Aba inicial · mínimo de {min} abas'**
  String navBarInitialTabMin(int min);

  /// No description provided for @navBarMinLimit.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de {min} abas na barra'**
  String navBarMinLimit(int min);

  /// No description provided for @navBarMaxLimit.
  ///
  /// In pt, this message translates to:
  /// **'Máximo de {max} abas atingido'**
  String navBarMaxLimit(int max);

  /// No description provided for @navBarDrawerHint.
  ///
  /// In pt, this message translates to:
  /// **'Acessível pelo menu lateral'**
  String get navBarDrawerHint;

  /// No description provided for @navBarRestoreDefault.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão'**
  String get navBarRestoreDefault;

  /// No description provided for @navBarDragSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Arrastar {label}'**
  String navBarDragSemantics(String label);

  /// No description provided for @settingsFlashcards.
  ///
  /// In pt, this message translates to:
  /// **'Flashcards'**
  String get settingsFlashcards;

  /// No description provided for @settingsNewCardsPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Cards novos por dia'**
  String get settingsNewCardsPerDay;

  /// No description provided for @settingsDesiredRetention.
  ///
  /// In pt, this message translates to:
  /// **'Retenção desejada'**
  String get settingsDesiredRetention;

  /// No description provided for @settingsDesiredRetentionHint.
  ///
  /// In pt, this message translates to:
  /// **'{percent}%: mais alta = revisões mais frequentes'**
  String settingsDesiredRetentionHint(int percent);

  /// No description provided for @settingsDesiredRetentionSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Retenção desejada em porcentagem'**
  String get settingsDesiredRetentionSemantics;

  /// No description provided for @settingsPomodoro.
  ///
  /// In pt, this message translates to:
  /// **'Pomodoro'**
  String get settingsPomodoro;

  /// No description provided for @settingsFocusMinutes.
  ///
  /// In pt, this message translates to:
  /// **'Foco (min)'**
  String get settingsFocusMinutes;

  /// No description provided for @settingsShortBreakMinutes.
  ///
  /// In pt, this message translates to:
  /// **'Pausa curta (min)'**
  String get settingsShortBreakMinutes;

  /// No description provided for @settingsLongBreakMinutes.
  ///
  /// In pt, this message translates to:
  /// **'Pausa longa (min)'**
  String get settingsLongBreakMinutes;

  /// No description provided for @settingsLongBreakEvery.
  ///
  /// In pt, this message translates to:
  /// **'Pausa longa a cada'**
  String get settingsLongBreakEvery;

  /// No description provided for @settingsLongBreakEveryDetail.
  ///
  /// In pt, this message translates to:
  /// **'{count} focos'**
  String settingsLongBreakEveryDetail(int count);

  /// No description provided for @settingsLongBreakEverySemantics.
  ///
  /// In pt, this message translates to:
  /// **'Focos até a pausa longa'**
  String get settingsLongBreakEverySemantics;

  /// No description provided for @settingsAutoStartBreaks.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar pausas sozinho'**
  String get settingsAutoStartBreaks;

  /// No description provided for @settingsAutoStartBreaksHint.
  ///
  /// In pt, this message translates to:
  /// **'Ao fim do foco, a pausa começa automaticamente'**
  String get settingsAutoStartBreaksHint;

  /// No description provided for @settingsSoundOnEnd.
  ///
  /// In pt, this message translates to:
  /// **'Som ao terminar'**
  String get settingsSoundOnEnd;

  /// No description provided for @settingsVibrateOnEnd.
  ///
  /// In pt, this message translates to:
  /// **'Vibrar ao terminar'**
  String get settingsVibrateOnEnd;

  /// No description provided for @settingsKeepScreenOn.
  ///
  /// In pt, this message translates to:
  /// **'Manter a tela ligada'**
  String get settingsKeepScreenOn;

  /// No description provided for @settingsKeepScreenOnHint.
  ///
  /// In pt, this message translates to:
  /// **'Enquanto a tela do pomodoro estiver aberta'**
  String get settingsKeepScreenOnHint;

  /// No description provided for @settingsTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get settingsTasks;

  /// No description provided for @settingsAllDayReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete de dia inteiro'**
  String get settingsAllDayReminder;

  /// No description provided for @settingsAllDayReminderHint.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas sem hora lembram às {hour}h (menos a antecedência escolhida)'**
  String settingsAllDayReminderHint(int hour);

  /// No description provided for @settingsAllDayReminderSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Hora do lembrete de dia inteiro'**
  String get settingsAllDayReminderSemantics;

  /// No description provided for @settingsBackup.
  ///
  /// In pt, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// No description provided for @settingsExportJson.
  ///
  /// In pt, this message translates to:
  /// **'Exportar JSON'**
  String get settingsExportJson;

  /// No description provided for @settingsExportJsonHint.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados num arquivo'**
  String get settingsExportJsonHint;

  /// No description provided for @settingsImportJson.
  ///
  /// In pt, this message translates to:
  /// **'Importar JSON'**
  String get settingsImportJson;

  /// No description provided for @settingsImportJsonHint.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar ou substituir pelos dados de um backup'**
  String get settingsImportJsonHint;

  /// No description provided for @settingsUpdates.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações'**
  String get settingsUpdates;

  /// No description provided for @updateVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String updateVersion(String version);

  /// No description provided for @updateIdle.
  ///
  /// In pt, this message translates to:
  /// **'Toque para procurar uma versão nova'**
  String get updateIdle;

  /// No description provided for @updateChecking.
  ///
  /// In pt, this message translates to:
  /// **'Verificando…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In pt, this message translates to:
  /// **'Você está na versão mais recente'**
  String get updateUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version} disponível'**
  String updateAvailable(String version);

  /// No description provided for @updateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar. Tente de novo.'**
  String get updateError;

  /// No description provided for @todayEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada para hoje ainda.'**
  String get todayEmpty;

  /// No description provided for @todayOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get todayOverdue;

  /// No description provided for @todayUndated.
  ///
  /// In pt, this message translates to:
  /// **'Sem data'**
  String get todayUndated;

  /// No description provided for @tasksLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as tarefas.'**
  String get tasksLoadError;

  /// No description provided for @tasksNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa'**
  String get tasksNew;

  /// No description provided for @tasksCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar tarefa'**
  String get tasksCreate;

  /// No description provided for @tasksNewSubtask.
  ///
  /// In pt, this message translates to:
  /// **'Nova subtarefa'**
  String get tasksNewSubtask;

  /// No description provided for @tasksEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar tarefa'**
  String get tasksEdit;

  /// No description provided for @tasksAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa'**
  String get tasksAdd;

  /// No description provided for @tasksSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar pelo título'**
  String get tasksSearchHint;

  /// No description provided for @tasksCloseSearch.
  ///
  /// In pt, this message translates to:
  /// **'Fechar busca'**
  String get tasksCloseSearch;

  /// No description provided for @tasksFilterAndSort.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar e ordenar'**
  String get tasksFilterAndSort;

  /// No description provided for @tasksEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa ainda.'**
  String get tasksEmpty;

  /// No description provided for @tasksNoMatches.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa com esses filtros.'**
  String get tasksNoMatches;

  /// No description provided for @tasksClearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get tasksClearFilters;

  /// No description provided for @tasksCreated.
  ///
  /// In pt, this message translates to:
  /// **'Criada: {title}'**
  String tasksCreated(String title);

  /// No description provided for @taskKindSimple.
  ///
  /// In pt, this message translates to:
  /// **'Simples'**
  String get taskKindSimple;

  /// No description provided for @taskKindStudy.
  ///
  /// In pt, this message translates to:
  /// **'Estudo'**
  String get taskKindStudy;

  /// No description provided for @taskKindRoutine.
  ///
  /// In pt, this message translates to:
  /// **'Rotina'**
  String get taskKindRoutine;

  /// No description provided for @taskKindEvent.
  ///
  /// In pt, this message translates to:
  /// **'Evento'**
  String get taskKindEvent;

  /// No description provided for @taskStatusTodo.
  ///
  /// In pt, this message translates to:
  /// **'A fazer'**
  String get taskStatusTodo;

  /// No description provided for @taskStatusDoing.
  ///
  /// In pt, this message translates to:
  /// **'Fazendo'**
  String get taskStatusDoing;

  /// No description provided for @taskStatusDone.
  ///
  /// In pt, this message translates to:
  /// **'Feita'**
  String get taskStatusDone;

  /// No description provided for @priorityNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get priorityNone;

  /// No description provided for @priorityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get priorityHigh;

  /// No description provided for @reminderModeNotification.
  ///
  /// In pt, this message translates to:
  /// **'Notificação'**
  String get reminderModeNotification;

  /// No description provided for @reminderModeAlarm.
  ///
  /// In pt, this message translates to:
  /// **'Alarme'**
  String get reminderModeAlarm;

  /// No description provided for @reminderModeNotificationHint.
  ///
  /// In pt, this message translates to:
  /// **'Aviso discreto na barra de notificações.'**
  String get reminderModeNotificationHint;

  /// No description provided for @reminderModeAlarmHint.
  ///
  /// In pt, this message translates to:
  /// **'Toca como despertador (mesmo no silencioso) até você interagir.'**
  String get reminderModeAlarmHint;

  /// No description provided for @reminderFullScreenBanner.
  ///
  /// In pt, this message translates to:
  /// **'Para abrir na tela bloqueada, permita notificações em tela cheia nas configurações do Android.'**
  String get reminderFullScreenBanner;

  /// No description provided for @reminderAllowFullScreen.
  ///
  /// In pt, this message translates to:
  /// **'Permitir tela cheia'**
  String get reminderAllowFullScreen;

  /// No description provided for @fieldTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get fieldTitle;

  /// No description provided for @fieldNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get fieldNotes;

  /// No description provided for @fieldType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get fieldType;

  /// No description provided for @fieldPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get fieldPriority;

  /// No description provided for @fieldDates.
  ///
  /// In pt, this message translates to:
  /// **'Datas'**
  String get fieldDates;

  /// No description provided for @fieldAllDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia inteiro'**
  String get fieldAllDay;

  /// No description provided for @fieldStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get fieldStart;

  /// No description provided for @fieldDue.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get fieldDue;

  /// No description provided for @fieldNoDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem data'**
  String get fieldNoDate;

  /// No description provided for @fieldDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get fieldDate;

  /// No description provided for @fieldRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Repetir'**
  String get fieldRepeat;

  /// No description provided for @repeatNo.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get repeatNo;

  /// No description provided for @repeatDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diária'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get repeatWeekly;

  /// No description provided for @repeatEvery.
  ///
  /// In pt, this message translates to:
  /// **'A cada'**
  String get repeatEvery;

  /// No description provided for @repeatUntil.
  ///
  /// In pt, this message translates to:
  /// **'Até'**
  String get repeatUntil;

  /// No description provided for @repeatNoEnd.
  ///
  /// In pt, this message translates to:
  /// **'Sem fim'**
  String get repeatNoEnd;

  /// No description provided for @fieldAlarm.
  ///
  /// In pt, this message translates to:
  /// **'Alarme'**
  String get fieldAlarm;

  /// No description provided for @fieldReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get fieldReminder;

  /// No description provided for @alarmNeedDue.
  ///
  /// In pt, this message translates to:
  /// **'Defina um prazo para usar alarme.'**
  String get alarmNeedDue;

  /// No description provided for @reminderNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get reminderNone;

  /// No description provided for @reminderAtTime.
  ///
  /// In pt, this message translates to:
  /// **'Na hora'**
  String get reminderAtTime;

  /// No description provided for @reminder5Min.
  ///
  /// In pt, this message translates to:
  /// **'5 min antes'**
  String get reminder5Min;

  /// No description provided for @reminder10Min.
  ///
  /// In pt, this message translates to:
  /// **'10 min antes'**
  String get reminder10Min;

  /// No description provided for @reminder15Min.
  ///
  /// In pt, this message translates to:
  /// **'15 min antes'**
  String get reminder15Min;

  /// No description provided for @reminder30Min.
  ///
  /// In pt, this message translates to:
  /// **'30 min antes'**
  String get reminder30Min;

  /// No description provided for @reminder1Hour.
  ///
  /// In pt, this message translates to:
  /// **'1 hora antes'**
  String get reminder1Hour;

  /// No description provided for @reminder1Day.
  ///
  /// In pt, this message translates to:
  /// **'1 dia antes'**
  String get reminder1Day;

  /// No description provided for @fieldEstimatedPomodoros.
  ///
  /// In pt, this message translates to:
  /// **'Pomodoros estimados'**
  String get fieldEstimatedPomodoros;

  /// No description provided for @fieldTags.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get fieldTags;

  /// No description provided for @tagNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova tag'**
  String get tagNew;

  /// No description provided for @fieldIconAndColor.
  ///
  /// In pt, this message translates to:
  /// **'Ícone e cor'**
  String get fieldIconAndColor;

  /// No description provided for @appearanceCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get appearanceCustom;

  /// No description provided for @appearanceDefault.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get appearanceDefault;

  /// No description provided for @appearanceTapToChange.
  ///
  /// In pt, this message translates to:
  /// **'Toque para trocar'**
  String get appearanceTapToChange;

  /// No description provided for @appearanceInherited.
  ///
  /// In pt, this message translates to:
  /// **'Herda da tarefa mãe, da tag ou da repetição'**
  String get appearanceInherited;

  /// No description provided for @quickDateToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get quickDateToday;

  /// No description provided for @quickDateTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get quickDateTomorrow;

  /// No description provided for @quickDateNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Daqui a uma semana'**
  String get quickDateNextWeek;

  /// No description provided for @pomodoroFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco'**
  String get pomodoroFocus;

  /// No description provided for @pomodoroShortBreak.
  ///
  /// In pt, this message translates to:
  /// **'Pausa curta'**
  String get pomodoroShortBreak;

  /// No description provided for @pomodoroLongBreak.
  ///
  /// In pt, this message translates to:
  /// **'Pausa longa'**
  String get pomodoroLongBreak;

  /// No description provided for @pomodoroStart.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar'**
  String get pomodoroStart;

  /// No description provided for @pomodoroPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get pomodoroPause;

  /// No description provided for @pomodoroResume.
  ///
  /// In pt, this message translates to:
  /// **'Retomar'**
  String get pomodoroResume;

  /// No description provided for @pomodoroStop.
  ///
  /// In pt, this message translates to:
  /// **'Parar'**
  String get pomodoroStop;

  /// No description provided for @pomodoroNoTask.
  ///
  /// In pt, this message translates to:
  /// **'Sem tarefa'**
  String get pomodoroNoTask;

  /// No description provided for @pomodoroLinkedTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa vinculada'**
  String get pomodoroLinkedTask;

  /// No description provided for @pomodoroPickTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa do foco'**
  String get pomodoroPickTask;

  /// No description provided for @pomodoroPausedSuffix.
  ///
  /// In pt, this message translates to:
  /// **'pausado'**
  String get pomodoroPausedSuffix;

  /// No description provided for @pomodoroFocusDone.
  ///
  /// In pt, this message translates to:
  /// **'Foco concluído!'**
  String get pomodoroFocusDone;

  /// No description provided for @pomodoroFocusDoneShort.
  ///
  /// In pt, this message translates to:
  /// **'Foco concluído'**
  String get pomodoroFocusDoneShort;

  /// No description provided for @pomodoroBreakDone.
  ///
  /// In pt, this message translates to:
  /// **'{kind} concluída'**
  String pomodoroBreakDone(String kind);

  /// No description provided for @pomodoroNextRunning.
  ///
  /// In pt, this message translates to:
  /// **'{kind} em andamento'**
  String pomodoroNextRunning(String kind);

  /// No description provided for @pomodoroNextLabel.
  ///
  /// In pt, this message translates to:
  /// **'Próximo: {kind}'**
  String pomodoroNextLabel(String kind);

  /// No description provided for @pomodoroStartNext.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar {kind}'**
  String pomodoroStartNext(String kind);

  /// No description provided for @pomodoroCompleteTask.
  ///
  /// In pt, this message translates to:
  /// **'Concluir \"{title}\"'**
  String pomodoroCompleteTask(String title);

  /// No description provided for @pomodoroCycleProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso do ciclo'**
  String get pomodoroCycleProgress;

  /// No description provided for @agendaGoToday.
  ///
  /// In pt, this message translates to:
  /// **'Ir para hoje'**
  String get agendaGoToday;

  /// No description provided for @agendaGoToDate.
  ///
  /// In pt, this message translates to:
  /// **'Ir para a data'**
  String get agendaGoToDate;

  /// No description provided for @agendaView.
  ///
  /// In pt, this message translates to:
  /// **'Visualização'**
  String get agendaView;

  /// No description provided for @agendaDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get agendaDay;

  /// No description provided for @agendaWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get agendaWeek;

  /// No description provided for @agenda3Days.
  ///
  /// In pt, this message translates to:
  /// **'3 dias'**
  String get agenda3Days;

  /// No description provided for @agendaMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get agendaMonth;

  /// No description provided for @agendaCompletedPomodoros.
  ///
  /// In pt, this message translates to:
  /// **'Pomodoros realizados'**
  String get agendaCompletedPomodoros;

  /// No description provided for @reviewNewDeck.
  ///
  /// In pt, this message translates to:
  /// **'Novo deck'**
  String get reviewNewDeck;

  /// No description provided for @reviewImportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Importar CSV'**
  String get reviewImportCsv;

  /// No description provided for @reviewNewCard.
  ///
  /// In pt, this message translates to:
  /// **'Novo card'**
  String get reviewNewCard;

  /// No description provided for @reviewLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os cards.'**
  String get reviewLoadError;

  /// No description provided for @reviewEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card criado.\nCrie um no + ou importe um CSV.'**
  String get reviewEmpty;

  /// No description provided for @reviewNow.
  ///
  /// In pt, this message translates to:
  /// **'Revisar agora'**
  String get reviewNow;

  /// No description provided for @reviewAllCards.
  ///
  /// In pt, this message translates to:
  /// **'Todos os cards'**
  String get reviewAllCards;

  /// No description provided for @reviewDecks.
  ///
  /// In pt, this message translates to:
  /// **'Decks'**
  String get reviewDecks;

  /// No description provided for @reviewNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get reviewNameLabel;

  /// No description provided for @booksImportMarkdown.
  ///
  /// In pt, this message translates to:
  /// **'Importar Markdown'**
  String get booksImportMarkdown;

  /// No description provided for @booksNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo book'**
  String get booksNew;

  /// No description provided for @booksLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os books.'**
  String get booksLoadError;

  /// No description provided for @booksEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum book criado.\nCrie um no + ou importe arquivos .md.'**
  String get booksEmpty;

  /// No description provided for @statsFocusTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de foco'**
  String get statsFocusTime;

  /// No description provided for @statsThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get statsThisMonth;

  /// No description provided for @statsDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias'**
  String get statsDays;

  /// No description provided for @statsWeeks.
  ///
  /// In pt, this message translates to:
  /// **'Semanas'**
  String get statsWeeks;

  /// No description provided for @statsMonths.
  ///
  /// In pt, this message translates to:
  /// **'Meses'**
  String get statsMonths;

  /// No description provided for @statsNoFocusInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum foco registrado nestes períodos.'**
  String get statsNoFocusInPeriod;

  /// No description provided for @statsStartFocus.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar foco'**
  String get statsStartFocus;

  /// No description provided for @statsFocusBy.
  ///
  /// In pt, this message translates to:
  /// **'Foco por'**
  String get statsFocusBy;

  /// No description provided for @statsGroupTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get statsGroupTask;

  /// No description provided for @statsGroupTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get statsGroupTag;

  /// No description provided for @statsGroupType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get statsGroupType;

  /// No description provided for @statsNoFocusGroup.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum foco no período.'**
  String get statsNoFocusGroup;

  /// No description provided for @statsEstimatedVsDone.
  ///
  /// In pt, this message translates to:
  /// **'Pomodoros: estimado × realizado'**
  String get statsEstimatedVsDone;

  /// No description provided for @statsNoEstimated.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa com pomodoros estimados.'**
  String get statsNoEstimated;

  /// No description provided for @statsReviews.
  ///
  /// In pt, this message translates to:
  /// **'Revisões'**
  String get statsReviews;

  /// No description provided for @statsAccuracy30Days.
  ///
  /// In pt, this message translates to:
  /// **'Acerto (30 dias)'**
  String get statsAccuracy30Days;

  /// No description provided for @statsStreakDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia seguido'**
  String get statsStreakDay;

  /// No description provided for @statsStreakDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias seguidos'**
  String get statsStreakDays;

  /// No description provided for @statsReviewsPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Revisões por dia'**
  String get statsReviewsPerDay;

  /// No description provided for @statsNoReviews14Days.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma revisão nos últimos 14 dias.'**
  String get statsNoReviews14Days;

  /// No description provided for @statsDueNext7Days.
  ///
  /// In pt, this message translates to:
  /// **'Cards a vencer nos próximos 7 dias'**
  String get statsDueNext7Days;

  /// No description provided for @statsNoDueThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card a vencer nesta semana.'**
  String get statsNoDueThisWeek;

  /// No description provided for @statsRoutinesDone.
  ///
  /// In pt, this message translates to:
  /// **'Rotinas concluídas'**
  String get statsRoutinesDone;

  /// No description provided for @statsLess.
  ///
  /// In pt, this message translates to:
  /// **'menos'**
  String get statsLess;

  /// No description provided for @statsMore.
  ///
  /// In pt, this message translates to:
  /// **'mais'**
  String get statsMore;

  /// No description provided for @accountTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Conta e sincronização'**
  String get accountTooltip;

  /// No description provided for @accountSyncing.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando'**
  String get accountSyncing;

  /// No description provided for @accountOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão: sincroniza depois'**
  String get accountOffline;

  /// No description provided for @accountPending.
  ///
  /// In pt, this message translates to:
  /// **'Alterações a sincronizar'**
  String get accountPending;

  /// No description provided for @accountError.
  ///
  /// In pt, this message translates to:
  /// **'Erro na sincronização'**
  String get accountError;

  /// No description provided for @accountSynced.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizado'**
  String get accountSynced;

  /// No description provided for @actionClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get actionClear;

  /// No description provided for @actionBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get actionBack;

  /// No description provided for @actionAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get actionAdd;

  /// No description provided for @actionRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get actionRename;

  /// No description provided for @actionDrag.
  ///
  /// In pt, this message translates to:
  /// **'Arrastar'**
  String get actionDrag;

  /// No description provided for @tasksEmptyCreated.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa criada.'**
  String get tasksEmptyCreated;

  /// No description provided for @tasksExpandSubtasks.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar subtarefas'**
  String get tasksExpandSubtasks;

  /// No description provided for @tasksCollapseSubtasks.
  ///
  /// In pt, this message translates to:
  /// **'Recolher subtarefas'**
  String get tasksCollapseSubtasks;

  /// No description provided for @tasksSortBy.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get tasksSortBy;

  /// No description provided for @tasksSortManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get tasksSortManual;

  /// No description provided for @tasksSortDue.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get tasksSortDue;

  /// No description provided for @tasksSortPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get tasksSortPriority;

  /// No description provided for @tasksSortNewest.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes'**
  String get tasksSortNewest;

  /// No description provided for @tasksSortTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get tasksSortTitle;

  /// No description provided for @fieldStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get fieldStatus;

  /// No description provided for @taskTagSingle.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get taskTagSingle;

  /// No description provided for @taskTagCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} tags'**
  String taskTagCount(int count);

  /// No description provided for @taskLoadOneError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a tarefa.'**
  String get taskLoadOneError;

  /// No description provided for @taskNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa não encontrada.'**
  String get taskNotFound;

  /// No description provided for @taskSingular.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get taskSingular;

  /// No description provided for @subtaskSingular.
  ///
  /// In pt, this message translates to:
  /// **'Subtarefa'**
  String get subtaskSingular;

  /// No description provided for @subtaskOf.
  ///
  /// In pt, this message translates to:
  /// **'Subtarefa de {title}'**
  String subtaskOf(String title);

  /// No description provided for @taskChangeStatus.
  ///
  /// In pt, this message translates to:
  /// **'Mudar status'**
  String get taskChangeStatus;

  /// No description provided for @taskPriorityBadge.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade {label}'**
  String taskPriorityBadge(String label);

  /// No description provided for @fieldRecurrence.
  ///
  /// In pt, this message translates to:
  /// **'Repetição'**
  String get fieldRecurrence;

  /// No description provided for @subtasksSection.
  ///
  /// In pt, this message translates to:
  /// **'Subtarefas'**
  String get subtasksSection;

  /// No description provided for @subtasksAddHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar subtarefa'**
  String get subtasksAddHint;

  /// No description provided for @routineHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get routineHistory;

  /// No description provided for @routineNoStreak.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sequência em andamento'**
  String get routineNoStreak;

  /// No description provided for @routineNotCompletedYet.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não concluída'**
  String get routineNotCompletedYet;

  /// No description provided for @routineTotalCompletions.
  ///
  /// In pt, this message translates to:
  /// **'{count} {unit} no total'**
  String routineTotalCompletions(int count, String unit);

  /// No description provided for @routineStreakDays.
  ///
  /// In pt, this message translates to:
  /// **'{count} {unit}'**
  String routineStreakDays(int count, String unit);

  /// No description provided for @routineDaySingular.
  ///
  /// In pt, this message translates to:
  /// **'dia seguido'**
  String get routineDaySingular;

  /// No description provided for @routineDayPlural.
  ///
  /// In pt, this message translates to:
  /// **'dias seguidos'**
  String get routineDayPlural;

  /// No description provided for @routineTimeSingular.
  ///
  /// In pt, this message translates to:
  /// **'vez seguida'**
  String get routineTimeSingular;

  /// No description provided for @routineTimePlural.
  ///
  /// In pt, this message translates to:
  /// **'vezes seguidas'**
  String get routineTimePlural;

  /// No description provided for @routineEnded.
  ///
  /// In pt, this message translates to:
  /// **'Rotina encerrada: era a última ocorrência.'**
  String get routineEnded;

  /// No description provided for @routineNext.
  ///
  /// In pt, this message translates to:
  /// **'Rotina concluída. Próxima: {when}.'**
  String routineNext(String when);

  /// No description provided for @taskDeleted.
  ///
  /// In pt, this message translates to:
  /// **'\"{title}\" excluída'**
  String taskDeleted(String title);

  /// No description provided for @taskDeletedWithSubtasks.
  ///
  /// In pt, this message translates to:
  /// **'\"{title}\" e {count} subtarefa(s) excluídas'**
  String taskDeletedWithSubtasks(String title, int count);

  /// No description provided for @repeatIntervalSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo da repetição'**
  String get repeatIntervalSemantics;

  /// No description provided for @unitDay.
  ///
  /// In pt, this message translates to:
  /// **'dia'**
  String get unitDay;

  /// No description provided for @unitDays.
  ///
  /// In pt, this message translates to:
  /// **'dias'**
  String get unitDays;

  /// No description provided for @unitWeek.
  ///
  /// In pt, this message translates to:
  /// **'semana'**
  String get unitWeek;

  /// No description provided for @unitWeeks.
  ///
  /// In pt, this message translates to:
  /// **'semanas'**
  String get unitWeeks;

  /// No description provided for @fieldClearLabel.
  ///
  /// In pt, this message translates to:
  /// **'Limpar {label}'**
  String fieldClearLabel(String label);

  /// No description provided for @reminderMinutesBefore.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min antes'**
  String reminderMinutesBefore(int minutes);

  /// No description provided for @hubAdd.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR'**
  String get hubAdd;

  /// No description provided for @hubFlashcard.
  ///
  /// In pt, this message translates to:
  /// **'Flashcard'**
  String get hubFlashcard;

  /// No description provided for @hubPage.
  ///
  /// In pt, this message translates to:
  /// **'Página'**
  String get hubPage;

  /// No description provided for @hubPages.
  ///
  /// In pt, this message translates to:
  /// **'Páginas'**
  String get hubPages;

  /// No description provided for @hubNewPage.
  ///
  /// In pt, this message translates to:
  /// **'Nova página'**
  String get hubNewPage;

  /// No description provided for @hubNoCardsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card ainda'**
  String get hubNoCardsYet;

  /// No description provided for @hubReviewTask.
  ///
  /// In pt, this message translates to:
  /// **'Revisar desta tarefa'**
  String get hubReviewTask;

  /// No description provided for @hubCard.
  ///
  /// In pt, this message translates to:
  /// **'Card'**
  String get hubCard;

  /// No description provided for @hubFocusTimeValue.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de foco: {duration}'**
  String hubFocusTimeValue(String duration);

  /// No description provided for @hubNoSessionsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sessão ainda'**
  String get hubNoSessionsYet;

  /// No description provided for @hubFocusSessions.
  ///
  /// In pt, this message translates to:
  /// **'{count} {unit} de foco (inclui subtarefas)'**
  String hubFocusSessions(int count, String unit);

  /// No description provided for @unitSession.
  ///
  /// In pt, this message translates to:
  /// **'sessão'**
  String get unitSession;

  /// No description provided for @unitSessions.
  ///
  /// In pt, this message translates to:
  /// **'sessões'**
  String get unitSessions;

  /// No description provided for @hubNoPagesYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma página ainda'**
  String get hubNoPagesYet;

  /// No description provided for @hubUnlink.
  ///
  /// In pt, this message translates to:
  /// **'Desvincular'**
  String get hubUnlink;

  /// No description provided for @hubOpenNotebook.
  ///
  /// In pt, this message translates to:
  /// **'Abrir caderno'**
  String get hubOpenNotebook;

  /// No description provided for @hubLinkExistingPage.
  ///
  /// In pt, this message translates to:
  /// **'Vincular página existente'**
  String get hubLinkExistingPage;

  /// No description provided for @hubLinkPage.
  ///
  /// In pt, this message translates to:
  /// **'Vincular página'**
  String get hubLinkPage;

  /// No description provided for @hubNoBookPages.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma página em books ainda.'**
  String get hubNoBookPages;

  /// No description provided for @hubNoBookPagesHint.
  ///
  /// In pt, this message translates to:
  /// **'Crie páginas na aba Books para vinculá-las.'**
  String get hubNoBookPagesHint;

  /// No description provided for @hubEstimatedVsDone.
  ///
  /// In pt, this message translates to:
  /// **'Estimado × realizado: {done} de {estimated}'**
  String hubEstimatedVsDone(int done, int estimated);

  /// No description provided for @agendaNextTaskIn.
  ///
  /// In pt, this message translates to:
  /// **'Próxima tarefa em {wait}'**
  String agendaNextTaskIn(String wait);

  /// No description provided for @agendaSearchTask.
  ///
  /// In pt, this message translates to:
  /// **'Buscar tarefa'**
  String get agendaSearchTask;

  /// No description provided for @agendaNoDatedTasks.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa com data encontrada.'**
  String get agendaNoDatedTasks;

  /// No description provided for @agendaAllDayShort.
  ///
  /// In pt, this message translates to:
  /// **'dia\ninteiro'**
  String get agendaAllDayShort;

  /// No description provided for @agendaExpandAllDay.
  ///
  /// In pt, this message translates to:
  /// **'Expandir dia inteiro'**
  String get agendaExpandAllDay;

  /// No description provided for @agendaCollapseAllDay.
  ///
  /// In pt, this message translates to:
  /// **'Recolher dia inteiro'**
  String get agendaCollapseAllDay;

  /// No description provided for @agendaRoutineRescheduled.
  ///
  /// In pt, this message translates to:
  /// **'Rotina reagendada (todas as ocorrências).'**
  String get agendaRoutineRescheduled;

  /// No description provided for @reviewEmptyAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar deck'**
  String get reviewEmptyAction;

  /// No description provided for @reviewEmptyAlt.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card ainda.\nCrie um card no + ou importe um CSV.'**
  String get reviewEmptyAlt;

  /// No description provided for @reviewNothingDue.
  ///
  /// In pt, this message translates to:
  /// **'Nada para revisar agora'**
  String get reviewNothingDue;

  /// No description provided for @reviewDueNow.
  ///
  /// In pt, this message translates to:
  /// **'{count} para revisar agora'**
  String reviewDueNow(int count);

  /// No description provided for @reviewNextIn.
  ///
  /// In pt, this message translates to:
  /// **'Próximo card em {minutes} min.'**
  String reviewNextIn(int minutes);

  /// No description provided for @reviewAll.
  ///
  /// In pt, this message translates to:
  /// **'Revisar tudo'**
  String get reviewAll;

  /// No description provided for @reviewDeckDueSuffix.
  ///
  /// In pt, this message translates to:
  /// **'{count} para revisar'**
  String reviewDeckDueSuffix(int count);

  /// No description provided for @reviewSessionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Revisão'**
  String get reviewSessionTitle;

  /// No description provided for @reviewUndoLast.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer última avaliação'**
  String get reviewUndoLast;

  /// No description provided for @reviewProgressSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Progresso da sessão'**
  String get reviewProgressSemantics;

  /// No description provided for @reviewShowAnswer.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar resposta'**
  String get reviewShowAnswer;

  /// No description provided for @reviewCardNew.
  ///
  /// In pt, this message translates to:
  /// **'novo'**
  String get reviewCardNew;

  /// No description provided for @reviewGradeAgain.
  ///
  /// In pt, this message translates to:
  /// **'Errei'**
  String get reviewGradeAgain;

  /// No description provided for @reviewGradeHard.
  ///
  /// In pt, this message translates to:
  /// **'Difícil'**
  String get reviewGradeHard;

  /// No description provided for @reviewGradeGood.
  ///
  /// In pt, this message translates to:
  /// **'Bom'**
  String get reviewGradeGood;

  /// No description provided for @reviewGradeEasy.
  ///
  /// In pt, this message translates to:
  /// **'Fácil'**
  String get reviewGradeEasy;

  /// No description provided for @reviewNextCardSoon.
  ///
  /// In pt, this message translates to:
  /// **'Próximo card em {minutes} min.\nEle aparece aqui sozinho.'**
  String reviewNextCardSoon(int minutes);

  /// No description provided for @reviewNothingDueDot.
  ///
  /// In pt, this message translates to:
  /// **'Nada para revisar agora.'**
  String get reviewNothingDueDot;

  /// No description provided for @reviewAllDone.
  ///
  /// In pt, this message translates to:
  /// **'Tudo revisado por agora! {count} {unit} nesta sessão.'**
  String reviewAllDone(int count, String unit);

  /// No description provided for @unitCard.
  ///
  /// In pt, this message translates to:
  /// **'card'**
  String get unitCard;

  /// No description provided for @unitCards.
  ///
  /// In pt, this message translates to:
  /// **'cards'**
  String get unitCards;

  /// No description provided for @reviewRemainingSingular.
  ///
  /// In pt, this message translates to:
  /// **'card restante'**
  String get reviewRemainingSingular;

  /// No description provided for @reviewRemainingPlural.
  ///
  /// In pt, this message translates to:
  /// **'cards restantes'**
  String get reviewRemainingPlural;

  /// No description provided for @booksOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções do book'**
  String get booksOptions;

  /// No description provided for @booksExportZip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar (.zip)'**
  String get booksExportZip;

  /// No description provided for @booksDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir \"{title}\"?'**
  String booksDeleteTitle(String title);

  /// No description provided for @booksDeleteMessage.
  ///
  /// In pt, this message translates to:
  /// **'Todas as páginas do book serão excluídas.'**
  String get booksDeleteMessage;

  /// No description provided for @statsSameAs.
  ///
  /// In pt, this message translates to:
  /// **'igual a {period}'**
  String statsSameAs(String period);

  /// No description provided for @statsVs.
  ///
  /// In pt, this message translates to:
  /// **'{delta} vs {period}'**
  String statsVs(String delta, String period);

  /// No description provided for @statsYesterday.
  ///
  /// In pt, this message translates to:
  /// **'ontem'**
  String get statsYesterday;

  /// No description provided for @statsPrevious.
  ///
  /// In pt, this message translates to:
  /// **'anterior'**
  String get statsPrevious;

  /// No description provided for @statsFocusHoursPer.
  ///
  /// In pt, this message translates to:
  /// **'Horas de foco por {unit}'**
  String statsFocusHoursPer(String unit);

  /// No description provided for @statsUnitDay.
  ///
  /// In pt, this message translates to:
  /// **'dia'**
  String get statsUnitDay;

  /// No description provided for @statsUnitWeek.
  ///
  /// In pt, this message translates to:
  /// **'semana'**
  String get statsUnitWeek;

  /// No description provided for @statsUnitMonth.
  ///
  /// In pt, this message translates to:
  /// **'mês'**
  String get statsUnitMonth;

  /// No description provided for @statsFocusChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de horas de foco'**
  String get statsFocusChartSemantics;

  /// No description provided for @statsDeletedTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa excluída'**
  String get statsDeletedTask;

  /// No description provided for @statsNoTag.
  ///
  /// In pt, this message translates to:
  /// **'Sem tag'**
  String get statsNoTag;

  /// No description provided for @statsDeletedTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag excluída'**
  String get statsDeletedTag;

  /// No description provided for @statsOf.
  ///
  /// In pt, this message translates to:
  /// **'{done} de {total}'**
  String statsOf(int done, int total);

  /// No description provided for @statsReviewsChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de revisões por dia'**
  String get statsReviewsChartSemantics;

  /// No description provided for @statsDueChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de cards a vencer'**
  String get statsDueChartSemantics;

  /// No description provided for @statsTodayLower.
  ///
  /// In pt, this message translates to:
  /// **'hoje'**
  String get statsTodayLower;

  /// No description provided for @statsTodayWithOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Hoje (com atrasados)'**
  String get statsTodayWithOverdue;

  /// No description provided for @statsUnitReview.
  ///
  /// In pt, this message translates to:
  /// **'revisão'**
  String get statsUnitReview;

  /// No description provided for @statsUnitReviews.
  ///
  /// In pt, this message translates to:
  /// **'revisões'**
  String get statsUnitReviews;

  /// No description provided for @statsRoutineTotal.
  ///
  /// In pt, this message translates to:
  /// **'{count} {unit} nas últimas {weeks} semanas'**
  String statsRoutineTotal(int count, String unit, int weeks);

  /// No description provided for @unitCompletion.
  ///
  /// In pt, this message translates to:
  /// **'conclusão'**
  String get unitCompletion;

  /// No description provided for @unitCompletions.
  ///
  /// In pt, this message translates to:
  /// **'conclusões'**
  String get unitCompletions;

  /// No description provided for @statsWeekOf.
  ///
  /// In pt, this message translates to:
  /// **'Semana de {date}'**
  String statsWeekOf(String date);

  /// No description provided for @settingsAlarmDiagnostics.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico de alarmes'**
  String get settingsAlarmDiagnostics;

  /// No description provided for @settingsAlarmDiagnosticsOk.
  ///
  /// In pt, this message translates to:
  /// **'Tudo certo para tocar'**
  String get settingsAlarmDiagnosticsOk;

  /// No description provided for @settingsAlarmDiagnosticsIssues.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 ajuste recomendado} other{{count} ajustes recomendados}}'**
  String settingsAlarmDiagnosticsIssues(int count);

  /// No description provided for @diagnosticsRefresh.
  ///
  /// In pt, this message translates to:
  /// **'Verificar novamente'**
  String get diagnosticsRefresh;

  /// No description provided for @diagnosticsOpenSettings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir ajustes'**
  String get diagnosticsOpenSettings;

  /// No description provided for @diagnosticsStatusOk.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get diagnosticsStatusOk;

  /// No description provided for @diagnosticsStatusIssue.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get diagnosticsStatusIssue;

  /// No description provided for @diagnosticsSummaryOk.
  ///
  /// In pt, this message translates to:
  /// **'O aparelho está configurado para entregar seus lembretes e alarmes no horário.'**
  String get diagnosticsSummaryOk;

  /// No description provided for @diagnosticsSummaryIssues.
  ///
  /// In pt, this message translates to:
  /// **'Alguns ajustes do Android podem impedir ou atrasar seus lembretes.'**
  String get diagnosticsSummaryIssues;

  /// No description provided for @diagNotificationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações do app'**
  String get diagNotificationsTitle;

  /// No description provided for @diagNotificationsOk.
  ///
  /// In pt, this message translates to:
  /// **'Permitidas pelo Android.'**
  String get diagNotificationsOk;

  /// No description provided for @diagNotificationsOff.
  ///
  /// In pt, this message translates to:
  /// **'Estão desligadas — nenhum lembrete ou alarme vai aparecer.'**
  String get diagNotificationsOff;

  /// No description provided for @diagRemindersChannelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Canal de lembretes'**
  String get diagRemindersChannelTitle;

  /// No description provided for @diagRemindersChannelOk.
  ///
  /// In pt, this message translates to:
  /// **'Som e avisos habilitados.'**
  String get diagRemindersChannelOk;

  /// No description provided for @diagRemindersChannelMuted.
  ///
  /// In pt, this message translates to:
  /// **'O canal está silenciado — notificações comuns não vão tocar.'**
  String get diagRemindersChannelMuted;

  /// No description provided for @diagAlarmsChannelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Canal de alarmes'**
  String get diagAlarmsChannelTitle;

  /// No description provided for @diagAlarmsChannelOk.
  ///
  /// In pt, this message translates to:
  /// **'Canal de despertador habilitado.'**
  String get diagAlarmsChannelOk;

  /// No description provided for @diagAlarmsChannelMuted.
  ///
  /// In pt, this message translates to:
  /// **'O canal está silenciado — tarefas em modo Alarme não vão tocar.'**
  String get diagAlarmsChannelMuted;

  /// No description provided for @diagExactAlarmsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alarmes exatos'**
  String get diagExactAlarmsTitle;

  /// No description provided for @diagExactAlarmsOk.
  ///
  /// In pt, this message translates to:
  /// **'O app pode agendar no minuto exato.'**
  String get diagExactAlarmsOk;

  /// No description provided for @diagExactAlarmsDenied.
  ///
  /// In pt, this message translates to:
  /// **'Negado — lembretes podem atrasar ou falhar.'**
  String get diagExactAlarmsDenied;

  /// No description provided for @diagFullScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alarmes em tela cheia'**
  String get diagFullScreenTitle;

  /// No description provided for @diagFullScreenOk.
  ///
  /// In pt, this message translates to:
  /// **'Pode abrir sobre a tela bloqueada.'**
  String get diagFullScreenOk;

  /// No description provided for @diagFullScreenDenied.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão — o alarme pode não aparecer na tela bloqueada.'**
  String get diagFullScreenDenied;

  /// No description provided for @diagBatteryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Otimização de bateria'**
  String get diagBatteryTitle;

  /// No description provided for @diagBatteryOk.
  ///
  /// In pt, this message translates to:
  /// **'Sem restrições em segundo plano.'**
  String get diagBatteryOk;

  /// No description provided for @diagBatteryRestricted.
  ///
  /// In pt, this message translates to:
  /// **'Com restrição — aparelhos (ex.: \"apps em suspensão\" da Samsung) podem atrasar alarmes.'**
  String get diagBatteryRestricted;

  /// No description provided for @formDiagnosticsWarning.
  ///
  /// In pt, this message translates to:
  /// **'Este lembrete pode não tocar: confira as permissões de notificação e alarme.'**
  String get formDiagnosticsWarning;

  /// No description provided for @formDiagnosticsAction.
  ///
  /// In pt, this message translates to:
  /// **'Ver diagnóstico'**
  String get formDiagnosticsAction;

  /// No description provided for @actionSnooze.
  ///
  /// In pt, this message translates to:
  /// **'Adiar'**
  String get actionSnooze;

  /// No description provided for @snooze10Min.
  ///
  /// In pt, this message translates to:
  /// **'10 min'**
  String get snooze10Min;

  /// No description provided for @snooze1Hour.
  ///
  /// In pt, this message translates to:
  /// **'1 h'**
  String get snooze1Hour;

  /// No description provided for @snoozeTomorrowMorning.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã cedo ({time})'**
  String snoozeTomorrowMorning(String time);

  /// No description provided for @snoozedUntil.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete adiado para {when}.'**
  String snoozedUntil(String when);

  /// No description provided for @settingsDailyReminders.
  ///
  /// In pt, this message translates to:
  /// **'Avisos diários'**
  String get settingsDailyReminders;

  /// No description provided for @settingsDailySummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo diário de tarefas'**
  String get settingsDailySummary;

  /// No description provided for @settingsDailySummaryHint.
  ///
  /// In pt, this message translates to:
  /// **'Avisa sobre tarefas de hoje e atrasadas às {hour}h'**
  String settingsDailySummaryHint(int hour);

  /// No description provided for @settingsDailySummaryOffHint.
  ///
  /// In pt, this message translates to:
  /// **'Receba um resumo diário de tarefas pendentes'**
  String get settingsDailySummaryOffHint;

  /// No description provided for @settingsDailySummaryHourSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Hora do resumo diário de tarefas'**
  String get settingsDailySummaryHourSemantics;

  /// No description provided for @settingsDailyReview.
  ///
  /// In pt, this message translates to:
  /// **'Aviso diário de flashcards'**
  String get settingsDailyReview;

  /// No description provided for @settingsDailyReviewHint.
  ///
  /// In pt, this message translates to:
  /// **'Lembra às {hour}h quando houver cards para revisar'**
  String settingsDailyReviewHint(int hour);

  /// No description provided for @settingsDailyReviewOffHint.
  ///
  /// In pt, this message translates to:
  /// **'Avisa quando houver cards vencidos (não avisa com zero)'**
  String get settingsDailyReviewOffHint;

  /// No description provided for @settingsDailyReviewHourSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Hora do aviso diário de flashcards'**
  String get settingsDailyReviewHourSemantics;

  /// No description provided for @settingsHourLabel.
  ///
  /// In pt, this message translates to:
  /// **'Horário (h)'**
  String get settingsHourLabel;

  /// No description provided for @fieldReminders.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes'**
  String get fieldReminders;

  /// No description provided for @remindersHelperMultiple.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um ou mais horários para lembrar.'**
  String get remindersHelperMultiple;

  /// No description provided for @fieldNagIfOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Insistir se atrasar'**
  String get fieldNagIfOverdue;

  /// No description provided for @nagOff.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get nagOff;

  /// No description provided for @nagEveryMinutes.
  ///
  /// In pt, this message translates to:
  /// **'A cada {minutes} min'**
  String nagEveryMinutes(int minutes);

  /// No description provided for @nagHint.
  ///
  /// In pt, this message translates to:
  /// **'Repete até {max}× após o horário enquanto a tarefa não for concluída.'**
  String nagHint(int max);

  /// No description provided for @nagHubDetail.
  ///
  /// In pt, this message translates to:
  /// **'A cada {minutes} min (até {max}×)'**
  String nagHubDetail(int minutes, int max);

  /// No description provided for @booksRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear book'**
  String get booksRename;

  /// No description provided for @booksExported.
  ///
  /// In pt, this message translates to:
  /// **'Book exportado ({count} páginas).'**
  String booksExported(int count);

  /// No description provided for @booksNoMarkdown.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum arquivo .md encontrado.'**
  String get booksNoMarkdown;

  /// No description provided for @booksImportedDefault.
  ///
  /// In pt, this message translates to:
  /// **'Importado'**
  String get booksImportedDefault;

  /// No description provided for @booksImportAsBook.
  ///
  /// In pt, this message translates to:
  /// **'Importar como book'**
  String get booksImportAsBook;

  /// No description provided for @booksBookTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título do book'**
  String get booksBookTitle;

  /// No description provided for @actionImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar'**
  String get actionImport;

  /// No description provided for @booksPagesImported.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 página importada.} other{{count} páginas importadas.}}'**
  String booksPagesImported(int count);

  /// No description provided for @pageNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova página'**
  String get pageNew;

  /// No description provided for @pageNewSub.
  ///
  /// In pt, this message translates to:
  /// **'Nova subpágina'**
  String get pageNewSub;

  /// No description provided for @pageRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear página'**
  String get pageRename;

  /// No description provided for @pageDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir \"{title}\"?'**
  String pageDeleteTitle(String title);

  /// No description provided for @pageDeleteMessage.
  ///
  /// In pt, this message translates to:
  /// **'As subpáginas também serão excluídas.'**
  String get pageDeleteMessage;

  /// No description provided for @pageExported.
  ///
  /// In pt, this message translates to:
  /// **'Página exportada.'**
  String get pageExported;

  /// No description provided for @bookFallbackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Book'**
  String get bookFallbackTitle;

  /// No description provided for @bookOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções do book'**
  String get bookOptions;

  /// No description provided for @bookImportPages.
  ///
  /// In pt, this message translates to:
  /// **'Importar páginas (.md)'**
  String get bookImportPages;

  /// No description provided for @bookExportZip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar (.zip)'**
  String get bookExportZip;

  /// No description provided for @pagesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as páginas.'**
  String get pagesLoadError;

  /// No description provided for @bookTaskNotebook.
  ///
  /// In pt, this message translates to:
  /// **'Caderno da tarefa {title}'**
  String bookTaskNotebook(String title);

  /// No description provided for @pagesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma página ainda.'**
  String get pagesEmpty;

  /// No description provided for @pageCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar página'**
  String get pageCreate;

  /// No description provided for @pageOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções da página'**
  String get pageOptions;

  /// No description provided for @actionMoveUp.
  ///
  /// In pt, this message translates to:
  /// **'Mover para cima'**
  String get actionMoveUp;

  /// No description provided for @actionMoveDown.
  ///
  /// In pt, this message translates to:
  /// **'Mover para baixo'**
  String get actionMoveDown;

  /// No description provided for @pageExportMd.
  ///
  /// In pt, this message translates to:
  /// **'Exportar (.md)'**
  String get pageExportMd;

  /// No description provided for @pageSelectTextFirst.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um trecho do texto primeiro.'**
  String get pageSelectTextFirst;

  /// No description provided for @pageUseAsFront.
  ///
  /// In pt, this message translates to:
  /// **'Usar como frente'**
  String get pageUseAsFront;

  /// No description provided for @pageUseAsBack.
  ///
  /// In pt, this message translates to:
  /// **'Usar como verso'**
  String get pageUseAsBack;

  /// No description provided for @pageFlashcardCreated.
  ///
  /// In pt, this message translates to:
  /// **'Flashcard criado.'**
  String get pageFlashcardCreated;

  /// No description provided for @pageLinkTask.
  ///
  /// In pt, this message translates to:
  /// **'Vincular a tarefa'**
  String get pageLinkTask;

  /// No description provided for @pageWriteHere.
  ///
  /// In pt, this message translates to:
  /// **'Escreva aqui…'**
  String get pageWriteHere;

  /// No description provided for @pageNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Página não encontrada.'**
  String get pageNotFound;

  /// No description provided for @pageReadMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo leitura'**
  String get pageReadMode;

  /// No description provided for @pageCreateCardFromSelection.
  ///
  /// In pt, this message translates to:
  /// **'Criar flashcard da seleção'**
  String get pageCreateCardFromSelection;

  /// No description provided for @pageIcon.
  ///
  /// In pt, this message translates to:
  /// **'Ícone'**
  String get pageIcon;

  /// No description provided for @pageDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir página'**
  String get pageDelete;

  /// No description provided for @actionCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get actionCopy;

  /// No description provided for @actionCut.
  ///
  /// In pt, this message translates to:
  /// **'Recortar'**
  String get actionCut;

  /// No description provided for @actionPaste.
  ///
  /// In pt, this message translates to:
  /// **'Colar'**
  String get actionPaste;

  /// No description provided for @pageCreateCard.
  ///
  /// In pt, this message translates to:
  /// **'Criar flashcard'**
  String get pageCreateCard;

  /// No description provided for @pageIconTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ícone da página'**
  String get pageIconTooltip;

  /// No description provided for @editorImageByLink.
  ///
  /// In pt, this message translates to:
  /// **'Imagem por link'**
  String get editorImageByLink;

  /// No description provided for @editorImageUrl.
  ///
  /// In pt, this message translates to:
  /// **'Endereço da imagem (https://…)'**
  String get editorImageUrl;

  /// No description provided for @actionInsert.
  ///
  /// In pt, this message translates to:
  /// **'Inserir'**
  String get actionInsert;

  /// No description provided for @cardDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Card excluído'**
  String get cardDeleted;

  /// No description provided for @cardsNoneInFile.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card encontrado no arquivo.'**
  String get cardsNoneInFile;

  /// No description provided for @cardsImported.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 card importado.} other{{count} cards importados.}}'**
  String cardsImported(int count);

  /// No description provided for @cardsImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar cards'**
  String get cardsImportTitle;

  /// No description provided for @cardsFound.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 card encontrado.} other{{count} cards encontrados.}}'**
  String cardsFound(int count);

  /// No description provided for @cardsSkippedLines.
  ///
  /// In pt, this message translates to:
  /// **'Linhas ignoradas (sem frente ou verso): {lines}'**
  String cardsSkippedLines(String lines);

  /// No description provided for @fieldDeck.
  ///
  /// In pt, this message translates to:
  /// **'Deck'**
  String get fieldDeck;

  /// No description provided for @deckNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem deck'**
  String get deckNone;

  /// No description provided for @cardEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar card'**
  String get cardEdit;

  /// No description provided for @cardFront.
  ///
  /// In pt, this message translates to:
  /// **'Frente'**
  String get cardFront;

  /// No description provided for @cardBack.
  ///
  /// In pt, this message translates to:
  /// **'Verso'**
  String get cardBack;

  /// No description provided for @cardMarkdownHint.
  ///
  /// In pt, this message translates to:
  /// **'Aceita **negrito**, *itálico*, `código` e - listas'**
  String get cardMarkdownHint;

  /// No description provided for @cardSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar card'**
  String get cardSave;

  /// No description provided for @deckRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear deck'**
  String get deckRename;

  /// No description provided for @deckDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir \"{name}\"?'**
  String deckDeleteTitle(String name);

  /// No description provided for @deckDeleteMessage.
  ///
  /// In pt, this message translates to:
  /// **'Os cards continuam existindo, sem deck.'**
  String get deckDeleteMessage;

  /// No description provided for @deckOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções do deck'**
  String get deckOptions;

  /// No description provided for @deckDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir deck'**
  String get deckDelete;

  /// No description provided for @cardsEmptyHere.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card aqui ainda.'**
  String get cardsEmptyHere;

  /// No description provided for @cardCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar card'**
  String get cardCreate;

  /// No description provided for @cardsReviewCount.
  ///
  /// In pt, this message translates to:
  /// **'Revisar {count} agora'**
  String cardsReviewCount(int count);

  /// No description provided for @cardSuspended.
  ///
  /// In pt, this message translates to:
  /// **'Suspenso'**
  String get cardSuspended;

  /// No description provided for @cardNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get cardNew;

  /// No description provided for @cardNextReview.
  ///
  /// In pt, this message translates to:
  /// **'Revisão: {when}'**
  String cardNextReview(String when);

  /// No description provided for @cardOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções do card'**
  String get cardOptions;

  /// No description provided for @cardReactivate.
  ///
  /// In pt, this message translates to:
  /// **'Reativar'**
  String get cardReactivate;

  /// No description provided for @cardSuspend.
  ///
  /// In pt, this message translates to:
  /// **'Suspender'**
  String get cardSuspend;

  /// No description provided for @syncCloudHasData.
  ///
  /// In pt, this message translates to:
  /// **'Já existem dados na nuvem'**
  String get syncCloudHasData;

  /// No description provided for @syncCloudHasDataOtherAccount.
  ///
  /// In pt, this message translates to:
  /// **'A nova conta tem um Google Drive diferente, com dados do My Cadence. O que fazer com os dados deste aparelho?'**
  String get syncCloudHasDataOtherAccount;

  /// No description provided for @syncCloudHasDataThisAccount.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta já tem dados do My Cadence. O que fazer com os dados deste aparelho?'**
  String get syncCloudHasDataThisAccount;

  /// No description provided for @syncUseCloudOnly.
  ///
  /// In pt, this message translates to:
  /// **'Usar só os da nuvem'**
  String get syncUseCloudOnly;

  /// No description provided for @syncMerge.
  ///
  /// In pt, this message translates to:
  /// **'Juntar'**
  String get syncMerge;

  /// No description provided for @syncCloudLoaded.
  ///
  /// In pt, this message translates to:
  /// **'Dados da nuvem carregados. Uma cópia dos anteriores foi guardada.'**
  String get syncCloudLoaded;

  /// No description provided for @backupManual.
  ///
  /// In pt, this message translates to:
  /// **'Backup manual'**
  String get backupManual;

  /// No description provided for @backupRestoreCopy.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar cópia'**
  String get backupRestoreCopy;

  /// No description provided for @backupDailyCopyHint.
  ///
  /// In pt, this message translates to:
  /// **'O app guarda uma cópia por dia'**
  String get backupDailyCopyHint;

  /// No description provided for @syncWithDrive.
  ///
  /// In pt, this message translates to:
  /// **'Sincronize com o Google Drive'**
  String get syncWithDrive;

  /// No description provided for @syncDriveExplain.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados ficam numa pasta privada do app no seu Google Drive, usando o seu espaço. Só este app enxerga essa pasta.'**
  String get syncDriveExplain;

  /// No description provided for @syncConnectGoogle.
  ///
  /// In pt, this message translates to:
  /// **'Conectar com Google'**
  String get syncConnectGoogle;

  /// No description provided for @syncNotConfigured.
  ///
  /// In pt, this message translates to:
  /// **'Login com Google ainda não configurado neste app.'**
  String get syncNotConfigured;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Sincroniza quando voltar.'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Alterações a sincronizar'**
  String get syncStatusPending;

  /// No description provided for @syncStatusError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao sincronizar'**
  String get syncStatusError;

  /// No description provided for @syncStatusSyncedAgo.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizado {ago}'**
  String syncStatusSyncedAgo(String ago);

  /// No description provided for @syncStatusNever.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não sincronizado'**
  String get syncStatusNever;

  /// No description provided for @syncAgoNow.
  ///
  /// In pt, this message translates to:
  /// **'agora há pouco'**
  String get syncAgoNow;

  /// No description provided for @syncAgoMinutes.
  ///
  /// In pt, this message translates to:
  /// **'há {count} min'**
  String syncAgoMinutes(int count);

  /// No description provided for @syncAgoHours.
  ///
  /// In pt, this message translates to:
  /// **'há {count} h'**
  String syncAgoHours(int count);

  /// No description provided for @syncAgoDays.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{há 1 dia} other{há {count} dias}}'**
  String syncAgoDays(int count);

  /// No description provided for @syncSignInAgain.
  ///
  /// In pt, this message translates to:
  /// **'Entrar novamente'**
  String get syncSignInAgain;

  /// No description provided for @syncUseCloudData.
  ///
  /// In pt, this message translates to:
  /// **'Usar os dados da nuvem'**
  String get syncUseCloudData;

  /// No description provided for @syncNow.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar agora'**
  String get syncNow;

  /// No description provided for @syncAuto.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização automática'**
  String get syncAuto;

  /// No description provided for @syncAutoHint.
  ///
  /// In pt, this message translates to:
  /// **'Ao abrir, ao voltar ao app e após alterações'**
  String get syncAutoHint;

  /// No description provided for @syncSwitchAccount.
  ///
  /// In pt, this message translates to:
  /// **'Trocar conta'**
  String get syncSwitchAccount;

  /// No description provided for @syncDisconnect.
  ///
  /// In pt, this message translates to:
  /// **'Desconectar'**
  String get syncDisconnect;

  /// No description provided for @syncDisconnected.
  ///
  /// In pt, this message translates to:
  /// **'Desconectado. Os dados continuam neste aparelho.'**
  String get syncDisconnected;

  /// No description provided for @syncDeviceName.
  ///
  /// In pt, this message translates to:
  /// **'Nome deste aparelho'**
  String get syncDeviceName;

  /// No description provided for @syncThisDevice.
  ///
  /// In pt, this message translates to:
  /// **'Este aparelho'**
  String get syncThisDevice;

  /// No description provided for @syncLog.
  ///
  /// In pt, this message translates to:
  /// **'Log de sync'**
  String get syncLog;

  /// No description provided for @syncLogEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sincronização ainda.'**
  String get syncLogEmpty;

  /// No description provided for @backupExported.
  ///
  /// In pt, this message translates to:
  /// **'Backup exportado.'**
  String get backupExported;

  /// No description provided for @backupNoCopies.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cópia guardada ainda.'**
  String get backupNoCopies;

  /// No description provided for @backupReplaceAllQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Substituir tudo?'**
  String get backupReplaceAllQuestion;

  /// No description provided for @backupReplaceWarning.
  ///
  /// In pt, this message translates to:
  /// **'Os dados deste aparelho serão trocados pelos do arquivo. Antes, uma cópia dos dados atuais fica guardada no app.'**
  String get backupReplaceWarning;

  /// No description provided for @backupReplace.
  ///
  /// In pt, this message translates to:
  /// **'Substituir'**
  String get backupReplace;

  /// No description provided for @backupReplaced.
  ///
  /// In pt, this message translates to:
  /// **'Dados substituídos. Uma cópia dos anteriores foi guardada.'**
  String get backupReplaced;

  /// No description provided for @backupNothingNew.
  ///
  /// In pt, this message translates to:
  /// **'Nada novo no arquivo.'**
  String get backupNothingNew;

  /// No description provided for @backupMerged.
  ///
  /// In pt, this message translates to:
  /// **'Backup mesclado: {inserted} novos, {updated} atualizados, {deleted} excluídos.'**
  String backupMerged(int inserted, int updated, int deleted);

  /// No description provided for @backupImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Importar backup'**
  String get backupImportTitle;

  /// No description provided for @backupFrom.
  ///
  /// In pt, this message translates to:
  /// **'De {when}'**
  String backupFrom(String when);

  /// No description provided for @countTasks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 tarefa} other{{count} tarefas}}'**
  String countTasks(int count);

  /// No description provided for @countCards.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 card} other{{count} cards}}'**
  String countCards(int count);

  /// No description provided for @countBooks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}}'**
  String countBooks(int count);

  /// No description provided for @countPages.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 página} other{{count} páginas}}'**
  String countPages(int count);

  /// No description provided for @backupMerge.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar'**
  String get backupMerge;

  /// No description provided for @backupMergeHint.
  ///
  /// In pt, this message translates to:
  /// **'Junta com os dados deste aparelho. Nada é apagado.'**
  String get backupMergeHint;

  /// No description provided for @backupReplaceAll.
  ///
  /// In pt, this message translates to:
  /// **'Substituir tudo'**
  String get backupReplaceAll;

  /// No description provided for @backupReplaceAllHint.
  ///
  /// In pt, this message translates to:
  /// **'Troca os dados deste aparelho pelos do arquivo.'**
  String get backupReplaceAllHint;

  /// No description provided for @pickerIcon.
  ///
  /// In pt, this message translates to:
  /// **'Ícone'**
  String get pickerIcon;

  /// No description provided for @pickerColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get pickerColor;

  /// No description provided for @pickerUseDefault.
  ///
  /// In pt, this message translates to:
  /// **'Usar padrão'**
  String get pickerUseDefault;

  /// No description provided for @pickerColorSection.
  ///
  /// In pt, this message translates to:
  /// **'COR'**
  String get pickerColorSection;

  /// No description provided for @pickerSearchIcon.
  ///
  /// In pt, this message translates to:
  /// **'Buscar ícone'**
  String get pickerSearchIcon;

  /// No description provided for @actionApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get actionApply;

  /// No description provided for @timelineFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco {range}'**
  String timelineFocus(String range);

  /// No description provided for @fieldWhen.
  ///
  /// In pt, this message translates to:
  /// **'Quando'**
  String get fieldWhen;

  /// No description provided for @fieldDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get fieldDetails;

  /// No description provided for @fieldStudy.
  ///
  /// In pt, this message translates to:
  /// **'Estudo vinculado'**
  String get fieldStudy;

  /// No description provided for @repeatStarts.
  ///
  /// In pt, this message translates to:
  /// **'Começa'**
  String get repeatStarts;

  /// No description provided for @repeatEnds.
  ///
  /// In pt, this message translates to:
  /// **'Termina'**
  String get repeatEnds;

  /// No description provided for @repeatNever.
  ///
  /// In pt, this message translates to:
  /// **'Nunca'**
  String get repeatNever;

  /// No description provided for @fieldTimeRange.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get fieldTimeRange;

  /// No description provided for @timeRangeFrom.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get timeRangeFrom;

  /// No description provided for @timeRangeTo.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get timeRangeTo;

  /// No description provided for @repeatDatesHint.
  ///
  /// In pt, this message translates to:
  /// **'“Começa” é a primeira vez e “Termina”, a última repetição.'**
  String get repeatDatesHint;

  /// No description provided for @datesHint.
  ///
  /// In pt, this message translates to:
  /// **'Início é quando você começa; prazo é quando precisa estar pronta.'**
  String get datesHint;

  /// No description provided for @remindersNeedDate.
  ///
  /// In pt, this message translates to:
  /// **'Defina uma data para receber lembretes.'**
  String get remindersNeedDate;

  /// No description provided for @reminderOnTheDay.
  ///
  /// In pt, this message translates to:
  /// **'No dia, às {hour}h'**
  String reminderOnTheDay(int hour);

  /// No description provided for @reminderDaysBefore.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 dia antes} other{{count} dias antes}}'**
  String reminderDaysBefore(int count);

  /// No description provided for @reminderWeeksBefore.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 semana antes} other{{count} semanas antes}}'**
  String reminderWeeksBefore(int count);

  /// No description provided for @remindersBaseStart.
  ///
  /// In pt, this message translates to:
  /// **'Contados a partir do início.'**
  String get remindersBaseStart;

  /// No description provided for @remindersBaseDue.
  ///
  /// In pt, this message translates to:
  /// **'Contados a partir do prazo.'**
  String get remindersBaseDue;

  /// No description provided for @remindersBaseAllDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia inteiro lembra às {hour}h (muda em Ajustes).'**
  String remindersBaseAllDay(int hour);

  /// No description provided for @remindersEachRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Valem para cada repetição.'**
  String get remindersEachRepeat;

  /// No description provided for @remindersPreview.
  ///
  /// In pt, this message translates to:
  /// **'Vai avisar: {when}'**
  String remindersPreview(String when);

  /// No description provided for @remindersPreviewFirst.
  ///
  /// In pt, this message translates to:
  /// **'Primeira vez: {when}'**
  String remindersPreviewFirst(String when);

  /// No description provided for @fieldBooks.
  ///
  /// In pt, this message translates to:
  /// **'Books'**
  String get fieldBooks;

  /// No description provided for @fieldDecks.
  ///
  /// In pt, this message translates to:
  /// **'Decks'**
  String get fieldDecks;

  /// No description provided for @studyHint.
  ///
  /// In pt, this message translates to:
  /// **'Ligue books e decks a esta tarefa para acompanhar no hub e nas métricas.'**
  String get studyHint;

  /// No description provided for @linkBook.
  ///
  /// In pt, this message translates to:
  /// **'Vincular book'**
  String get linkBook;

  /// No description provided for @linkDeck.
  ///
  /// In pt, this message translates to:
  /// **'Vincular deck'**
  String get linkDeck;

  /// No description provided for @newBook.
  ///
  /// In pt, this message translates to:
  /// **'Novo book'**
  String get newBook;

  /// No description provided for @newDeck.
  ///
  /// In pt, this message translates to:
  /// **'Novo deck'**
  String get newDeck;

  /// No description provided for @linkBooksTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vincular books'**
  String get linkBooksTitle;

  /// No description provided for @linkDecksTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vincular decks'**
  String get linkDecksTitle;

  /// No description provided for @noBooksYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum book criado ainda.'**
  String get noBooksYet;

  /// No description provided for @noDecksYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum deck criado ainda.'**
  String get noDecksYet;

  /// No description provided for @unlinkItem.
  ///
  /// In pt, this message translates to:
  /// **'Desvincular {name}'**
  String unlinkItem(String name);

  /// No description provided for @hubLinkedBooks.
  ///
  /// In pt, this message translates to:
  /// **'Books vinculados'**
  String get hubLinkedBooks;

  /// No description provided for @hubLinkedDecks.
  ///
  /// In pt, this message translates to:
  /// **'Decks vinculados'**
  String get hubLinkedDecks;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tarefa?'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskAlsoHint.
  ///
  /// In pt, this message translates to:
  /// **'Excluir também o que está vinculado a ela:'**
  String get deleteTaskAlsoHint;

  /// No description provided for @deleteAlsoBooks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 book (com as páginas)} other{{count} books (com as páginas)}}'**
  String deleteAlsoBooks(int count);

  /// No description provided for @deleteAlsoPages.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 página vinculada} other{{count} páginas vinculadas}}'**
  String deleteAlsoPages(int count);

  /// No description provided for @deleteAlsoDecks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 deck (os cards ficam sem deck)} other{{count} decks (os cards ficam sem deck)}}'**
  String deleteAlsoDecks(int count);

  /// No description provided for @deleteAlsoNoUndo.
  ///
  /// In pt, this message translates to:
  /// **'O que você marcar aqui não volta com \"Desfazer\".'**
  String get deleteAlsoNoUndo;

  /// No description provided for @repeatTimeHint.
  ///
  /// In pt, this message translates to:
  /// **'O horário vale para todas as repetições.'**
  String get repeatTimeHint;

  /// No description provided for @formInfoTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Como funciona'**
  String get formInfoTooltip;

  /// No description provided for @formInfoDatesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Início e prazo'**
  String get formInfoDatesTitle;

  /// No description provided for @formInfoRepeatTitle.
  ///
  /// In pt, this message translates to:
  /// **'Repetição'**
  String get formInfoRepeatTitle;

  /// No description provided for @formInfoRemindersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes'**
  String get formInfoRemindersTitle;

  /// No description provided for @formInfoReminders.
  ///
  /// In pt, this message translates to:
  /// **'Com hora, contam a partir do início (ou do prazo, se não houver início). Em dia inteiro, tocam na hora definida em Ajustes, no próprio dia ou dias antes. Numa rotina, valem para cada repetição.'**
  String get formInfoReminders;

  /// No description provided for @formInfoModesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificação ou alarme'**
  String get formInfoModesTitle;

  /// No description provided for @formInfoNagTitle.
  ///
  /// In pt, this message translates to:
  /// **'Insistir se atrasar'**
  String get formInfoNagTitle;

  /// No description provided for @formInfoStudyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estudo vinculado'**
  String get formInfoStudyTitle;

  /// No description provided for @deckSpeech.
  ///
  /// In pt, this message translates to:
  /// **'Leitura em voz alta'**
  String get deckSpeech;

  /// No description provided for @deckSpeechHint.
  ///
  /// In pt, this message translates to:
  /// **'Usa a voz do próprio celular (texto para fala). Escolha o idioma de cada lado do card.'**
  String get deckSpeechHint;

  /// No description provided for @deckSpeechFront.
  ///
  /// In pt, this message translates to:
  /// **'Frente'**
  String get deckSpeechFront;

  /// No description provided for @deckSpeechBack.
  ///
  /// In pt, this message translates to:
  /// **'Verso'**
  String get deckSpeechBack;

  /// No description provided for @deckSpeechOff.
  ///
  /// In pt, this message translates to:
  /// **'Não ler'**
  String get deckSpeechOff;

  /// No description provided for @deckSpeechAuto.
  ///
  /// In pt, this message translates to:
  /// **'Ler automaticamente na revisão'**
  String get deckSpeechAuto;

  /// No description provided for @deckSpeechNoVoices.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma voz encontrada. Instale vozes em Ajustes do Android → Texto para fala.'**
  String get deckSpeechNoVoices;

  /// No description provided for @speakFront.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir frente'**
  String get speakFront;

  /// No description provided for @speakFrontSlow.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir frente devagar'**
  String get speakFrontSlow;

  /// No description provided for @speakBack.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir verso'**
  String get speakBack;

  /// No description provided for @speakBackSlow.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir verso devagar'**
  String get speakBackSlow;

  /// No description provided for @speechDefault.
  ///
  /// In pt, this message translates to:
  /// **'Voz padrão'**
  String get speechDefault;

  /// No description provided for @speechDefaultHint.
  ///
  /// In pt, this message translates to:
  /// **'Vale para todos os decks que não têm ajuste próprio.'**
  String get speechDefaultHint;

  /// No description provided for @speechUseDefault.
  ///
  /// In pt, this message translates to:
  /// **'Usar a voz padrão'**
  String get speechUseDefault;

  /// No description provided for @speechDeckTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Voz do deck'**
  String get speechDeckTooltip;

  /// No description provided for @manualTimeLog.
  ///
  /// In pt, this message translates to:
  /// **'Registrar tempo'**
  String get manualTimeLog;

  /// No description provided for @manualTimeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar tempo feito'**
  String get manualTimeTitle;

  /// No description provided for @manualTimeHint.
  ///
  /// In pt, this message translates to:
  /// **'Para quando você trabalhou sem o pomodoro. Conta no tempo de foco e nas métricas, mas não como pomodoro concluído.'**
  String get manualTimeHint;

  /// No description provided for @manualTimeHours.
  ///
  /// In pt, this message translates to:
  /// **'Horas'**
  String get manualTimeHours;

  /// No description provided for @manualTimeMinutes.
  ///
  /// In pt, this message translates to:
  /// **'Minutos'**
  String get manualTimeMinutes;

  /// No description provided for @manualTimeDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get manualTimeDay;

  /// No description provided for @manualTimeStart.
  ///
  /// In pt, this message translates to:
  /// **'Começou às'**
  String get manualTimeStart;

  /// No description provided for @manualTimeSaved.
  ///
  /// In pt, this message translates to:
  /// **'{duration} registrados.'**
  String manualTimeSaved(String duration);

  /// No description provided for @manualTimeEntries.
  ///
  /// In pt, this message translates to:
  /// **'Registros manuais'**
  String get manualTimeEntries;

  /// No description provided for @manualTimeDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir registro'**
  String get manualTimeDelete;

  /// No description provided for @statsTagHint.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa com várias tags conta o tempo em cada uma; subtarefa herda as tags da mãe.'**
  String get statsTagHint;

  /// No description provided for @taskStatusPaused.
  ///
  /// In pt, this message translates to:
  /// **'Pausada'**
  String get taskStatusPaused;

  /// No description provided for @rescheduleAction.
  ///
  /// In pt, this message translates to:
  /// **'Reagendar'**
  String get rescheduleAction;

  /// No description provided for @rescheduleChoose.
  ///
  /// In pt, this message translates to:
  /// **'Escolher data'**
  String get rescheduleChoose;

  /// No description provided for @rescheduledTo.
  ///
  /// In pt, this message translates to:
  /// **'Reagendada para {date}.'**
  String rescheduledTo(String date);

  /// No description provided for @rescheduleResumesHint.
  ///
  /// In pt, this message translates to:
  /// **'Reagendar também retoma a tarefa pausada.'**
  String get rescheduleResumesHint;

  /// No description provided for @pausedBanner.
  ///
  /// In pt, this message translates to:
  /// **'Pausada: não aparece no Hoje, nos atrasados nem nos lembretes até ser retomada.'**
  String get pausedBanner;

  /// No description provided for @actionPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In pt, this message translates to:
  /// **'Retomar'**
  String get actionResume;

  /// No description provided for @fieldEstimatedTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo estimado'**
  String get fieldEstimatedTime;

  /// No description provided for @estimateHours.
  ///
  /// In pt, this message translates to:
  /// **'Horas'**
  String get estimateHours;

  /// No description provided for @estimateHint.
  ///
  /// In pt, this message translates to:
  /// **'Comparado com o tempo de foco feito (pomodoros e tempo registrado).'**
  String get estimateHint;

  /// No description provided for @hubEstimatedTime.
  ///
  /// In pt, this message translates to:
  /// **'Estimado × feito: {done} de {estimated}'**
  String hubEstimatedTime(String done, String estimated);

  /// No description provided for @statsOfTime.
  ///
  /// In pt, this message translates to:
  /// **'{done} de {total}'**
  String statsOfTime(String done, String total);

  /// No description provided for @statsEstimatedVsDoneTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo: estimado × feito'**
  String get statsEstimatedVsDoneTime;

  /// No description provided for @statsNoEstimatedTime.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa com tempo estimado.'**
  String get statsNoEstimatedTime;

  /// No description provided for @quickAddHint.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa (#tag para marcar)'**
  String get quickAddHint;

  /// No description provided for @searchAllTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Buscar em tudo'**
  String get searchAllTooltip;

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar tarefas, páginas e cards'**
  String get searchHint;

  /// No description provided for @searchIntro.
  ///
  /// In pt, this message translates to:
  /// **'Digite ao menos 2 letras. A busca olha títulos, notas, o texto das páginas e os dois lados dos cards.'**
  String get searchIntro;

  /// No description provided for @searchNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nada encontrado.'**
  String get searchNoResults;

  /// No description provided for @searchClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get searchClear;

  /// No description provided for @weekReviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Revisão da semana'**
  String get weekReviewTitle;

  /// No description provided for @weekPrevious.
  ///
  /// In pt, this message translates to:
  /// **'Semana anterior'**
  String get weekPrevious;

  /// No description provided for @weekNext.
  ///
  /// In pt, this message translates to:
  /// **'Próxima semana'**
  String get weekNext;

  /// No description provided for @weekCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas'**
  String get weekCompleted;

  /// No description provided for @weekRoutines.
  ///
  /// In pt, this message translates to:
  /// **'Rotinas cumpridas'**
  String get weekRoutines;

  /// No description provided for @weekFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco'**
  String get weekFocus;

  /// No description provided for @weekByTag.
  ///
  /// In pt, this message translates to:
  /// **'Tempo por tag'**
  String get weekByTag;

  /// No description provided for @weekNoFocus.
  ///
  /// In pt, this message translates to:
  /// **'Sem tempo de foco nesta semana.'**
  String get weekNoFocus;

  /// No description provided for @weekOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Ficou para trás'**
  String get weekOverdue;

  /// No description provided for @weekNoOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Nada atrasado. Boa!'**
  String get weekNoOverdue;

  /// No description provided for @weekAllToToday.
  ///
  /// In pt, this message translates to:
  /// **'Todas para hoje'**
  String get weekAllToToday;

  /// No description provided for @weekMovedToToday.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 tarefa movida para hoje.} other{{count} tarefas movidas para hoje.}}'**
  String weekMovedToToday(int count);

  /// No description provided for @weekNoCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa concluída nesta semana.'**
  String get weekNoCompleted;

  /// No description provided for @templateSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como modelo'**
  String get templateSave;

  /// No description provided for @templateName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do modelo'**
  String get templateName;

  /// No description provided for @templateSaved.
  ///
  /// In pt, this message translates to:
  /// **'Modelo \"{name}\" salvo.'**
  String templateSaved(String name);

  /// No description provided for @templateUse.
  ///
  /// In pt, this message translates to:
  /// **'Modelo'**
  String get templateUse;

  /// No description provided for @templatePickTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar a partir de um modelo'**
  String get templatePickTitle;

  /// No description provided for @templatePickHint.
  ///
  /// In pt, this message translates to:
  /// **'A tarefa é criada com tags, aparência, estimativa, lembretes, subtarefas, books e decks do modelo; depois escolha as datas.'**
  String get templatePickHint;

  /// No description provided for @templateDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir modelo'**
  String get templateDelete;

  /// No description provided for @templateSubtasks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{sem subtarefas} =1{1 subtarefa} other{{count} subtarefas}}'**
  String templateSubtasks(int count);

  /// No description provided for @weekReviewShort.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get weekReviewShort;

  /// No description provided for @cardsImportFromFile.
  ///
  /// In pt, this message translates to:
  /// **'Carregar arquivo'**
  String get cardsImportFromFile;

  /// No description provided for @cardsImportTextLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cards (frente;verso)'**
  String get cardsImportTextLabel;

  /// No description provided for @cardsImportTextHint.
  ///
  /// In pt, this message translates to:
  /// **'apple;maçã\nbook;livro'**
  String get cardsImportTextHint;

  /// No description provided for @cardsImportTextHelper.
  ///
  /// In pt, this message translates to:
  /// **'Um card por linha, separado por ponto e vírgula (;)'**
  String get cardsImportTextHelper;

  /// No description provided for @cardsSkipDuplicates.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar frentes já existentes no deck'**
  String get cardsSkipDuplicates;

  /// No description provided for @cardsDuplicatesSkipped.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 duplicado ignorado.} other{{count} duplicados ignorados.}}'**
  String cardsDuplicatesSkipped(int count);

  /// No description provided for @cardsAllDuplicates.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Este card já existe neste deck.} other{Todos os {count} cards já existem neste deck.}}'**
  String cardsAllDuplicates(int count);

  /// No description provided for @cardsNoneInText.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum card válido encontrado.'**
  String get cardsNoneInText;

  /// No description provided for @cardsImportActionCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Importar 1 card} other{Importar {count} cards}}'**
  String cardsImportActionCount(int count);

  /// No description provided for @navTags.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get navTags;

  /// No description provided for @tagEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar tag'**
  String get tagEdit;

  /// No description provided for @tagChangeColor.
  ///
  /// In pt, this message translates to:
  /// **'Trocar cor'**
  String get tagChangeColor;

  /// No description provided for @tagOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções da tag'**
  String get tagOptions;

  /// No description provided for @tagDuplicateError.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma tag com esse nome.'**
  String get tagDuplicateError;

  /// No description provided for @tagsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tag criada ainda.'**
  String get tagsEmpty;

  /// No description provided for @tagsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as tags.'**
  String get tagsLoadError;

  /// No description provided for @tagTaskCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma tarefa} =1{1 tarefa} other{{count} tarefas}}'**
  String tagTaskCount(int count);

  /// No description provided for @tagDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir \"{name}\"?'**
  String tagDeleteTitle(String name);

  /// No description provided for @tagDeleteUnusedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa usa esta tag.'**
  String get tagDeleteUnusedMessage;

  /// No description provided for @tagDeleteUsedMessage.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Esta tag está em 1 tarefa; ela perde a tag.} other{Esta tag está em {count} tarefas; elas perdem a tag.}}'**
  String tagDeleteUsedMessage(int count);

  /// No description provided for @tagDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Tag \"{name}\" excluída.'**
  String tagDeleted(String name);

  /// No description provided for @tagViewTasks.
  ///
  /// In pt, this message translates to:
  /// **'Ver tarefas'**
  String get tagViewTasks;

  /// No description provided for @cardsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar cards'**
  String get cardsSearchHint;

  /// No description provided for @cardsFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get cardsFilterAll;

  /// No description provided for @cardsFilterDue.
  ///
  /// In pt, this message translates to:
  /// **'Vencidos'**
  String get cardsFilterDue;

  /// No description provided for @cardsFilterNew.
  ///
  /// In pt, this message translates to:
  /// **'Novos'**
  String get cardsFilterNew;

  /// No description provided for @cardsFilterSuspended.
  ///
  /// In pt, this message translates to:
  /// **'Suspensos'**
  String get cardsFilterSuspended;

  /// No description provided for @cardsExportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get cardsExportCsv;

  /// No description provided for @cardsExportSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 card pronto no formato frente;verso.} other{{count} cards prontos no formato frente;verso.}}'**
  String cardsExportSubtitle(int count);

  /// No description provided for @cardsExportCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar CSV'**
  String get cardsExportCopy;

  /// No description provided for @cardsExportSaveFile.
  ///
  /// In pt, this message translates to:
  /// **'Salvar arquivo'**
  String get cardsExportSaveFile;

  /// No description provided for @cardsCsvCopied.
  ///
  /// In pt, this message translates to:
  /// **'CSV copiado.'**
  String get cardsCsvCopied;

  /// No description provided for @cardsCsvSaved.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo CSV salvo.'**
  String get cardsCsvSaved;

  /// No description provided for @navTrash.
  ///
  /// In pt, this message translates to:
  /// **'Lixeira'**
  String get navTrash;

  /// No description provided for @trashHint.
  ///
  /// In pt, this message translates to:
  /// **'Itens excluídos ficam disponíveis aqui para restaurar.'**
  String get trashHint;

  /// No description provided for @trashEmpty.
  ///
  /// In pt, this message translates to:
  /// **'A lixeira está vazia.'**
  String get trashEmpty;

  /// No description provided for @trashFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Tudo'**
  String get trashFilterAll;

  /// No description provided for @trashFilterCards.
  ///
  /// In pt, this message translates to:
  /// **'Cards'**
  String get trashFilterCards;

  /// No description provided for @trashKindTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get trashKindTask;

  /// No description provided for @trashKindTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get trashKindTag;

  /// No description provided for @trashKindDeck.
  ///
  /// In pt, this message translates to:
  /// **'Deck'**
  String get trashKindDeck;

  /// No description provided for @trashKindCard.
  ///
  /// In pt, this message translates to:
  /// **'Card'**
  String get trashKindCard;

  /// No description provided for @trashKindBook.
  ///
  /// In pt, this message translates to:
  /// **'Book'**
  String get trashKindBook;

  /// No description provided for @trashKindPage.
  ///
  /// In pt, this message translates to:
  /// **'Página'**
  String get trashKindPage;

  /// No description provided for @trashRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get trashRestore;

  /// No description provided for @trashRestored.
  ///
  /// In pt, this message translates to:
  /// **'\"{title}\" restaurado.'**
  String trashRestored(String title);

  /// No description provided for @repeatSkipMissed.
  ///
  /// In pt, this message translates to:
  /// **'Não acumular atrasos'**
  String get repeatSkipMissed;

  /// No description provided for @repeatSkipMissedHint.
  ///
  /// In pt, this message translates to:
  /// **'Se não concluir no dia, registra como não concluída e avança para a próxima.'**
  String get repeatSkipMissedHint;

  /// No description provided for @repeatSkipMissedInfo.
  ///
  /// In pt, this message translates to:
  /// **'Por padrão, rotinas não acumulam atrasos: se um dia passar sem concluir, a ocorrência fica marcada como não concluída no calendário e nas métricas, e a rotina avança para a próxima data. Desative para mantê-la em Atrasadas.'**
  String get repeatSkipMissedInfo;

  /// No description provided for @routineMissedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 não concluída} other{{count} não concluídas}}'**
  String routineMissedCount(int count);

  /// No description provided for @routineMarkAsDone.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como concluída'**
  String get routineMarkAsDone;

  /// No description provided for @routineMissedDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ocorrência não concluída'**
  String get routineMissedDialogTitle;

  /// No description provided for @routineMissedDialogBody.
  ///
  /// In pt, this message translates to:
  /// **'\"{title}\" não foi concluída neste dia. Você pode marcá-la como concluída ou abrir a tarefa.'**
  String routineMissedDialogBody(String title);

  /// No description provided for @routineOpenTask.
  ///
  /// In pt, this message translates to:
  /// **'Abrir tarefa'**
  String get routineOpenTask;

  /// No description provided for @statsRoutineSummary.
  ///
  /// In pt, this message translates to:
  /// **'{done} concluídas · {missed} não concluídas ({rate}%) nas últimas {weeks} semanas'**
  String statsRoutineSummary(int done, int missed, int rate, int weeks);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
