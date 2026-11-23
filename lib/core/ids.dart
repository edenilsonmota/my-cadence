import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Novo identificador UUID v7: gerado no aparelho, sem colisão no sync e
/// ordenável pelo momento de criação.
String newId() => _uuid.v7();
