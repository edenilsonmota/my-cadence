import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Comunicação entre o Flutter e os widgets nativos da tela inicial.
abstract interface class HomeWidgetBridge {
  /// Grava o JSON do snapshot e solicita redesenho dos widgets na tela inicial.
  Future<void> pushSnapshot(String jsonPayload);

  /// Devolve a URI de deep link que abriu o app a partir de um widget (se
  /// houver) e limpa o valor pendente.
  Future<String?> consumeLaunchUri();

  /// Registra o callback chamado quando um widget abre o app já em execução.
  void setUriListener(void Function(String uri)? onUri);
}

/// Implementação via `MethodChannel` para os widgets Android (`SharedPreferences`
/// + `AppWidgetManager`). Nas demais plataformas é no-op silencioso.
class MethodChannelHomeWidgetBridge implements HomeWidgetBridge {
  MethodChannelHomeWidgetBridge._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetUri') {
        final uri = call.arguments as String?;
        if (uri != null && uri.isNotEmpty) _onUri?.call(uri);
      }
    });
  }

  static final MethodChannelHomeWidgetBridge instance =
      MethodChannelHomeWidgetBridge._();

  static const _channel = MethodChannel('com.nextinfor.mycadence/home_widgets');

  void Function(String uri)? _onUri;

  @override
  void setUriListener(void Function(String uri)? onUri) {
    _onUri = onUri;
  }

  @override
  Future<void> pushSnapshot(String jsonPayload) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('updateSnapshot', {
        'snapshot': jsonPayload,
      });
    } on MissingPluginException {
      // Ambiente sem plugin nativo (ex.: teste).
    }
  }

  @override
  Future<String?> consumeLaunchUri() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('consumeLaunchUri');
    } on MissingPluginException {
      return null;
    }
  }
}
