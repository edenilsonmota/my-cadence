/// Onde o snapshot compartilhado mora (Google Drive, ou um falso nos
/// testes). Puro, sem Flutter.
library;

import 'snapshot.dart';

/// A versão remota mudou entre ler e gravar: outro aparelho sincronizou no
/// meio. Quem chama repete o ciclo.
class VersionConflict implements Exception {
  const VersionConflict();
}

/// Sem conexão (ou o servidor não respondeu). Não é erro "barulhento":
/// tenta de novo depois.
class SyncOfflineException implements Exception {
  const SyncOfflineException([this.cause]);

  final Object? cause;

  @override
  String toString() => 'Sem conexão com a internet.';
}

abstract interface class SyncTransport {
  /// Só a versão remota atual (barato), ou `null` se ainda não existe.
  Future<String?> version();

  /// Snapshot remoto atual e a versão dele (`null` se ainda não existe).
  Future<({Snapshot? snapshot, String? version})> fetch();

  /// Grava o snapshot, mas só se a versão remota ainda for
  /// [expectedVersion]. Lança [VersionConflict] se mudou. Devolve a nova
  /// versão.
  Future<String> push(Snapshot snapshot, {String? expectedVersion});
}
