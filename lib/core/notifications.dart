import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Ponto único de acesso ao plugin de notificações locais.
///
/// Na Etapa 0 só inicializa o plugin. Agendar, cancelar, reagendar no boot e
/// tratar o toque (deep link) chegam na Etapa 3.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // Permissões no iOS são pedidas depois, quando o primeiro alarme for criado.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await plugin.initialize(settings: settings);
  }
}
