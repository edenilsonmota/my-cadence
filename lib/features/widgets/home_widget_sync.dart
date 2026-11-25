import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/locale_providers.dart';
import '../../app/l10n/locale_settings.dart';
import '../../app/theme/theme_providers.dart';
import '../../app/theme/theme_settings.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../tasks/task_providers.dart';
import 'home_widget_bridge.dart';
import 'home_widget_snapshot.dart';

/// Resolve o código de idioma (`pt`, `en`, `es`) sem precisar de `BuildContext`.
String resolveWidgetLang(AppLocale locale) {
  final code = switch (locale) {
    AppLocale.pt => 'pt',
    AppLocale.en => 'en',
    AppLocale.es => 'es',
    AppLocale.system => PlatformDispatcher.instance.locale.languageCode,
  };
  return switch (code) {
    'en' => 'en',
    'es' => 'es',
    _ => 'pt',
  };
}

/// Mantém os widgets da tela inicial atualizados sempre que tarefas, tags,
/// data, tema ou idioma mudam (deduplicando payloads idênticos).
class HomeWidgetSync {
  HomeWidgetSync(this._bridge);

  final HomeWidgetBridge _bridge;

  List<Task> _tasks = const [];
  List<Tag> _tags = const [];
  Map<String, Set<String>> _tagIdsByTask = const {};
  DateTime _today = DateTime.now();
  ThemeSettings _theme = const ThemeSettings();
  String _lang = 'pt';
  bool _hasTasks = false;
  String? _lastPayload;
  Future<void> _queue = Future.value();

  void reset() {
    _lastPayload = null;
    if (_hasTasks) unawaited(pushNow());
  }

  Future<void> update({
    List<Task>? tasks,
    List<Tag>? tags,
    Map<String, Set<String>>? tagIdsByTask,
    DateTime? today,
    ThemeSettings? theme,
    String? lang,
  }) {
    if (tasks != null) {
      _tasks = tasks;
      _hasTasks = true;
    }
    if (tags != null) _tags = tags;
    if (tagIdsByTask != null) _tagIdsByTask = tagIdsByTask;
    if (today != null) _today = today;
    if (theme != null) _theme = theme;
    if (lang != null) _lang = lang;
    if (!_hasTasks) return Future.value();
    return pushNow();
  }

  Future<void> pushNow() {
    return _queue = _queue.then((_) => _apply()).catchError((Object _) {});
  }

  Future<void> _apply() async {
    final payload = buildHomeWidgetSnapshot(
      tasks: _tasks,
      tags: _tags,
      tagIdsByTask: _tagIdsByTask,
      today: _today,
      theme: _theme,
      lang: _lang,
    ).encode();
    if (payload == _lastPayload) return;
    _lastPayload = payload;
    await _bridge.pushSnapshot(payload);
  }
}

final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>(
  (ref) => MethodChannelHomeWidgetBridge.instance,
);

/// Liga o [HomeWidgetSync] aos dados do app. Basta ler uma vez (em `main`).
final homeWidgetSyncProvider = Provider<HomeWidgetSync>((ref) {
  final sync = HomeWidgetSync(ref.watch(homeWidgetBridgeProvider));
  final repo = ref.watch(tasksRepositoryProvider);

  sync.update(
    today: ref.read(todayProvider),
    theme: ref.read(themeSettingsProvider),
    lang: resolveWidgetLang(ref.read(appLocaleProvider)),
  );

  final tasksSub = repo.watchAllTasks().listen((t) => sync.update(tasks: t));
  final tagsSub = repo.watchTags().listen((t) => sync.update(tags: t));
  final linksSub = repo.watchTagIdsByTask().listen(
    (m) => sync.update(tagIdsByTask: m),
  );

  ref.listen(todayProvider, (_, next) => sync.update(today: next));
  ref.listen(themeSettingsProvider, (_, next) => sync.update(theme: next));
  ref.listen(
    appLocaleProvider,
    (_, next) => sync.update(lang: resolveWidgetLang(next)),
  );

  ref.onDispose(() {
    tasksSub.cancel();
    tagsSub.cancel();
    linksSub.cancel();
  });
  return sync;
});
