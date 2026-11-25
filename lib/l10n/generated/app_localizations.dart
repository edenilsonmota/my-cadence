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
  /// **'Azul'**
  String get accentBlue;

  /// No description provided for @accentYellow.
  ///
  /// In pt, this message translates to:
  /// **'Amarelo'**
  String get accentYellow;

  /// No description provided for @accentPink.
  ///
  /// In pt, this message translates to:
  /// **'Rosa'**
  String get accentPink;

  /// No description provided for @accentViolet.
  ///
  /// In pt, this message translates to:
  /// **'Violeta'**
  String get accentViolet;

  /// No description provided for @accentOrange.
  ///
  /// In pt, this message translates to:
  /// **'Laranja'**
  String get accentOrange;

  /// No description provided for @accentGreen.
  ///
  /// In pt, this message translates to:
  /// **'Verde'**
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
  /// **'Herda da tarefa mãe, da tag ou do tipo'**
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
