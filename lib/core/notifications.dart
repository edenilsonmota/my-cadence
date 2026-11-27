import 'dart:io' show Platform;
import 'dart:typed_data' show Int32List;
import 'dart:ui' show Color;

import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../features/tasks/alarm_diagnostics.dart';

/// Ações dos lembretes de tarefa (Android aceita até 3).
abstract final class AlarmActions {
  static const complete = 'concluir';
  static const snooze = 'adiar';
  static const snooze1h = 'adiar_1h';
}

/// Payloads reservados para deep links de notificações do sistema.
const pomodoroPayload = 'pomodoro';
const dailyReviewPayload = 'daily:review';
const dailySummaryPayload = 'daily:summary';

enum AlarmKind {
  /// Lembrete de tarefa como notificação comum, com "Concluir", "10 min" e "1 h".
  task,

  /// Lembrete de tarefa em modo alarme: som de alarme insistente (toca no
  /// silencioso) e tela cheia até a pessoa interagir.
  taskAlarm,

  /// Fim de um ciclo do pomodoro, sem ações.
  pomodoro,

  /// Aviso diário opcional (cards para revisar ou resumo do dia).
  dailyDigest,
}

/// Uma notificação a agendar. Em lembrete de tarefa, [payload] é o id da
/// tarefa (deep link); no pomodoro, [pomodoroPayload].
class AlarmSpec {
  const AlarmSpec({
    required this.id,
    required this.time,
    required this.title,
    required this.body,
    required this.payload,
    this.kind = AlarmKind.task,
    this.sound = true,
    this.vibrate = true,
    this.lang = 'pt',
    this.canSnooze = false,
  });

  final int id;
  final DateTime time;
  final String title;
  final String body;
  final String payload;
  final AlarmKind kind;
  final bool sound;
  final bool vibrate;

  /// Idioma dos botões da notificação (`pt`, `en`, `es`).
  final String lang;

  /// Exibe os botões "Adiar 10 min" e "Adiar 1 h" na notificação (apenas em
  /// alarmes de tarefas com hora definida).
  final bool canSnooze;

  AlarmSpec copyWith({DateTime? time}) => AlarmSpec(
    id: id,
    time: time ?? this.time,
    title: title,
    body: body,
    payload: payload,
    kind: kind,
    sound: sound,
    vibrate: vibrate,
    lang: lang,
    canSnooze: canSnooze,
  );

  @override
  bool operator ==(Object other) =>
      other is AlarmSpec &&
      other.id == id &&
      other.time == time &&
      other.title == title &&
      other.body == body &&
      other.payload == payload &&
      other.kind == kind &&
      other.sound == sound &&
      other.vibrate == vibrate &&
      other.lang == lang &&
      other.canSnooze == canSnooze;

  @override
  int get hashCode => Object.hash(
    id,
    time,
    title,
    body,
    payload,
    kind,
    sound,
    vibrate,
    lang,
    canSnooze,
  );

  @override
  String toString() => 'AlarmSpec($id, $time, $title, $kind)';
}

/// O que o app precisa do sistema de notificações. Nos testes, uma versão
/// falsa substitui o plugin.
abstract interface class AlarmScheduler {
  Future<void> schedule(AlarmSpec alarm);
  Future<void> cancel(int id);

  /// Ids dos lembretes agendados que ainda não dispararam.
  Future<Set<int>> pendingIds();

  /// Pede permissão de notificação (Android 13+ e iOS). Devolve se foi dada.
  Future<bool> requestPermission();

  /// No Android 14+, informa se o app pode abrir alarmes em tela cheia
  /// (`USE_FULL_SCREEN_INTENT`). Nas outras plataformas/versões devolve `true`.
  Future<bool> canUseFullScreenIntent();

  /// Abre a tela do Android 14+ para conceder `USE_FULL_SCREEN_INTENT` (se
  /// ainda não foi dada) e devolve o estado ao voltar.
  Future<bool> requestFullScreenIntentPermission();

  /// Diagnóstico de notificações, canais, alarmes exatos e bateria no aparelho.
  Future<AlarmDiagnostics> getDiagnostics();

  /// Abre a tela do sistema correspondente ao item [action] do diagnóstico.
  Future<void> openDiagnosticSettings(AlarmDiagnosticAction action);
}

typedef NotificationTapCallback = void Function(String payload);

/// Implementação com o `flutter_local_notifications`.
class NotificationService implements AlarmScheduler {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static const _permissionsChannel = MethodChannel(
    'com.nextinfor.mycadence/alarm_permissions',
  );

  /// Cor do ícone nas notificações (a semente do tema).
  static const brandColor = Color(0xFF00796B);

  static const _channelId = 'lembretes';
  static const _alarmChannelId = 'alarmes_tarefas';
  static const _dailyChannelId = 'resumos_diarios';
  static const _iosCategory = 'lembrete_tarefa';

  /// `Notification.FLAG_INSISTENT` do Android: repete o toque até a pessoa
  /// tocar na notificação, numa ação ou dispensar.
  static const _flagInsistent = 4;

  /// Som padrão de alarme do sistema (`Settings.System.DEFAULT_ALARM_ALERT_URI`).
  static const _systemAlarmSound = UriAndroidNotificationSound(
    'content://settings/system/alarm_alert',
  );

  /// Inicializa no isolate principal. [onTap] recebe o payload de um toque na
  /// notificação (ou numa ação com interface); [onBackgroundAction] precisa
  /// ser uma função top-level com `@pragma('vm:entry-point')`.
  Future<void> init({
    required NotificationTapCallback onTap,
    required DidReceiveBackgroundNotificationResponseCallback
    onBackgroundAction,
  }) async {
    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@drawable/ic_notification'),
      // A permissão no iOS é pedida quando o primeiro alarme for criado.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            _iosCategory,
            actions: [
              DarwinNotificationAction.plain(AlarmActions.complete, 'Concluir'),
              DarwinNotificationAction.plain(
                AlarmActions.snooze,
                'Adiar 10 min',
              ),
              DarwinNotificationAction.plain(
                AlarmActions.snooze1h,
                'Adiar 1 h',
              ),
            ],
          ),
        ],
      ),
    );
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && response.actionId == null) onTap(payload);
      },
      onDidReceiveBackgroundNotificationResponse: onBackgroundAction,
    );
  }

  /// Payload da notificação que abriu o app, se foi um toque (não uma ação).
  Future<String?> launchPayload() async {
    final details = await plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || response == null) {
      return null;
    }
    return response.actionId == null ? response.payload : null;
  }

  /// Botões dos lembretes de tarefa no idioma do app. Os botões de adiar
  /// aparecem apenas quando [withSnooze] é verdadeiro (alarme com hora).
  static List<AndroidNotificationAction> _taskActions(
    String lang, {
    required bool withSnooze,
  }) {
    final (complete, snooze, snooze1h) = switch (lang) {
      'en' => ('Complete', 'Snooze 10 min', 'Snooze 1 h'),
      'es' => ('Completar', 'Posponer 10 min', 'Posponer 1 h'),
      _ => ('Concluir', 'Adiar 10 min', 'Adiar 1 h'),
    };
    return [
      AndroidNotificationAction(
        AlarmActions.complete,
        complete,
        cancelNotification: true,
      ),
      if (withSnooze) ...[
        AndroidNotificationAction(
          AlarmActions.snooze,
          snooze,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          AlarmActions.snooze1h,
          snooze1h,
          cancelNotification: true,
        ),
      ],
    ];
  }

  static NotificationDetails _details(String lang) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Lembretes de tarefas',
      channelDescription: 'Notificações das tarefas com prazo',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      // Ícone explícito: no isolate das ações o plugin não é inicializado.
      icon: '@drawable/ic_notification',
      color: brandColor,
      actions: _taskActions(lang, withSnooze: false),
    ),
    iOS: const DarwinNotificationDetails(categoryIdentifier: _iosCategory),
  );

  /// Alarme insistente de tarefa: canal próprio com áudio de alarme (toca no
  /// silencioso), som de alarme do sistema em repetição e tela cheia.
  static NotificationDetails _alarmDetails(
    String lang, {
    required bool withSnooze,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      _alarmChannelId,
      'Alarmes de tarefas',
      channelDescription: 'Alarmes insistentes que tocam até você interagir',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: _systemAlarmSound,
      fullScreenIntent: true,
      additionalFlags: Int32List.fromList([_flagInsistent]),
      icon: '@drawable/ic_notification',
      color: brandColor,
      actions: _taskActions(lang, withSnooze: withSnooze),
    ),
    iOS: const DarwinNotificationDetails(
      categoryIdentifier: _iosCategory,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  /// Fim do pomodoro. No Android, som e vibração pertencem ao canal (fixos
  /// depois de criado), então cada combinação tem o seu canal.
  static NotificationDetails _pomodoroDetails(AlarmSpec alarm) {
    final variant = '${alarm.sound ? 's' : 'm'}${alarm.vibrate ? 'v' : 'n'}';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'pomodoro_$variant',
        'Pomodoro${alarm.sound ? '' : ' (sem som)'}'
            '${alarm.vibrate ? '' : ' (sem vibração)'}',
        channelDescription: 'Aviso de fim de foco ou de pausa',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        icon: '@drawable/ic_notification',
        color: brandColor,
        playSound: alarm.sound,
        enableVibration: alarm.vibrate,
      ),
      iOS: DarwinNotificationDetails(presentSound: alarm.sound),
    );
  }

  static const _dailyDigestDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _dailyChannelId,
      'Avisos diários',
      channelDescription: 'Resumo diário de tarefas e lembrete de flashcards',
      importance: Importance.high,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
      icon: '@drawable/ic_notification',
      color: brandColor,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> schedule(AlarmSpec alarm) => plugin.zonedSchedule(
    id: alarm.id,
    scheduledDate: tz.TZDateTime.from(alarm.time, tz.local),
    notificationDetails: switch (alarm.kind) {
      AlarmKind.task => _details(alarm.lang),
      AlarmKind.taskAlarm => _alarmDetails(
        alarm.lang,
        withSnooze: alarm.canSnooze,
      ),
      AlarmKind.pomodoro => _pomodoroDetails(alarm),
      AlarmKind.dailyDigest => _dailyDigestDetails,
    },
    androidScheduleMode: alarm.kind == AlarmKind.taskAlarm
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.exactAllowWhileIdle,
    title: alarm.title,
    body: alarm.body,
    payload: alarm.payload,
  );

  @override
  Future<void> cancel(int id) => plugin.cancel(id: id);

  @override
  Future<Set<int>> pendingIds() async => {
    for (final request in await plugin.pendingNotificationRequests())
      request.id,
  };

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final ios = plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _permissionsChannel.invokeMethod<bool>(
            'canUseFullScreenIntent',
          ) ??
          true;
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<bool> requestFullScreenIntentPermission() async {
    if (!Platform.isAndroid) return true;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestFullScreenIntentPermission() ?? true;
  }

  @override
  Future<AlarmDiagnostics> getDiagnostics() async {
    if (!Platform.isAndroid) return AlarmDiagnostics.allGood;
    try {
      final map = await _permissionsChannel.invokeMapMethod<Object?, Object?>(
        'getAlarmDiagnostics',
      );
      return map == null
          ? AlarmDiagnostics.allGood
          : AlarmDiagnostics.fromMap(map);
    } on MissingPluginException {
      return AlarmDiagnostics.allGood;
    }
  }

  @override
  Future<void> openDiagnosticSettings(AlarmDiagnosticAction action) async {
    if (!Platform.isAndroid) return;
    if (action == AlarmDiagnosticAction.fullScreenIntent) {
      await requestFullScreenIntentPermission();
      return;
    }
    try {
      switch (action) {
        case AlarmDiagnosticAction.notifications:
          await _permissionsChannel.invokeMethod<void>(
            'openNotificationSettings',
          );
        case AlarmDiagnosticAction.remindersChannel:
          await _permissionsChannel.invokeMethod<void>('openChannelSettings', {
            'channelId': _channelId,
          });
        case AlarmDiagnosticAction.alarmsChannel:
          await _permissionsChannel.invokeMethod<void>('openChannelSettings', {
            'channelId': _alarmChannelId,
          });
        case AlarmDiagnosticAction.exactAlarms:
          await _permissionsChannel.invokeMethod<void>(
            'openExactAlarmSettings',
          );
        case AlarmDiagnosticAction.batteryOptimization:
          await _permissionsChannel.invokeMethod<void>(
            'openBatteryOptimizationSettings',
          );
        case AlarmDiagnosticAction.fullScreenIntent:
          break;
      }
    } on MissingPluginException {
      // Ambiente sem plugin nativo (ex.: teste).
    }
  }
}
