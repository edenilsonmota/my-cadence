import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/notifications.dart';
import 'core/time_zone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initTimeZone();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: CadenceApp()));
}
