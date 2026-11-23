import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Carrega a base de fusos e define o fuso local do aparelho.
///
/// Necessário para agendar notificações com `zonedSchedule`. Se o fuso do
/// aparelho não for reconhecido, mantém UTC em vez de derrubar o app.
Future<void> initTimeZone() async {
  tz_data.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } on Object catch (e) {
    debugPrint('Fuso local não reconhecido, usando UTC: $e');
  }
}
