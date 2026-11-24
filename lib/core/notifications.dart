import 'dart:io' show Platform;
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Ações dos lembretes de tarefa.
abstract final class AlarmActions {
  static const complete = 'concluir';
  static const snooze = 'adiar';
}

/// Payload da notificação de fim do pomodoro (abre a tela do pomodoro).
const pomodoroPayload = 'pomodoro';

enum AlarmKind {
  /// Lembrete de tarefa, com as ações "Concluir" e "Adiar".
  task,

  /// Fim de um ciclo do pomodoro, sem ações.
  pomodoro,
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
  });

  final int id;
  final DateTime time;
  final String title;
  final String body;
  final String payload;
  final AlarmKind kind;
  final bool sound;
  final bool vibrate;

  AlarmSpec copyWith({DateTime? time}) => AlarmSpec(
    id: id,
    time: time ?? this.time,
    title: title,
    body: body,
    payload: payload,
    kind: kind,
    sound: sound,
    vibrate: vibrate,
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
      other.vibrate == vibrate;

  @override
  int get hashCode =>
      Object.hash(id, time, title, body, payload, kind, sound, vibrate);

  @override
  String toString() => 'AlarmSpec($id, $time, $title)';
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
}

typedef NotificationTapCallback = void Function(String payload);

/// Implementação com o `flutter_local_notifications`.
class NotificationService implements AlarmScheduler {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  /// Cor do ícone nas notificações (a semente do tema).
  static const brandColor = Color(0xFF00796B);

  static const _channelId = 'lembretes';
  static const _iosCategory = 'lembrete_tarefa';

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

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Lembretes de tarefas',
      channelDescription: 'Alarmes das tarefas com prazo',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      // Ícone explícito: no isolate das ações o plugin não é inicializado.
      icon: '@drawable/ic_notification',
      color: brandColor,
      actions: [
        AndroidNotificationAction(
          AlarmActions.complete,
          'Concluir',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          AlarmActions.snooze,
          'Adiar 10 min',
          cancelNotification: true,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(categoryIdentifier: _iosCategory),
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

  @override
  Future<void> schedule(AlarmSpec alarm) => plugin.zonedSchedule(
    id: alarm.id,
    scheduledDate: tz.TZDateTime.from(alarm.time, tz.local),
    notificationDetails: alarm.kind == AlarmKind.pomodoro
        ? _pomodoroDetails(alarm)
        : _details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
}
