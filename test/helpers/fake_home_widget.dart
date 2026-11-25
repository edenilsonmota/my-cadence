import 'package:my_cadence/features/widgets/home_widget_bridge.dart';

/// Implementação em memória da ponte de widgets para testes.
class FakeHomeWidgetBridge implements HomeWidgetBridge {
  final List<String> snapshots = [];
  String? launchUri;
  void Function(String uri)? _listener;

  @override
  Future<void> pushSnapshot(String jsonPayload) async {
    snapshots.add(jsonPayload);
  }

  @override
  Future<String?> consumeLaunchUri() async {
    final uri = launchUri;
    launchUri = null;
    return uri;
  }

  @override
  void setUriListener(void Function(String uri)? onUri) {
    _listener = onUri;
  }

  void emitUri(String uri) => _listener?.call(uri);
}
