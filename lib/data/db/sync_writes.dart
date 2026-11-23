import 'package:drift/drift.dart';

import 'sync_columns.dart';

/// Escritas que respeitam as regras de sincronização.
///
/// Toda inserção e atualização passa por aqui: grava `updatedAt = agora` e
/// `dirty = true`. Exclusão é sempre lógica (`deletedAt`). Os DAOs não devem
/// usar `into(...).insert`, `update(...)` ou `delete(...)` diretamente.
extension SyncWrites on DatabaseConnectionUser {
  Future<void> insertSynced<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    await into(table).insert(_Touched(row, DateTime.now()));
  }

  /// Atualiza a linha [id] (viva ou excluída) com as colunas de [patch].
  Future<int> updateSynced<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
    Insertable<D> patch,
  ) {
    return (update(
      table,
    )..where((t) => t.id.equals(id))).write(_Touched(patch, DateTime.now()));
  }

  Future<int> softDeleteSynced<T extends SyncColumns, D>(
    TableInfo<T, D> table,
    String id,
  ) {
    final now = DateTime.now();
    return (update(
      table,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
      _Touched(RawValuesInsertable<D>({'deleted_at': Variable(now)}), now),
    );
  }
}

/// Acrescenta `updated_at` e `dirty` às colunas de outra escrita.
class _Touched<D> implements Insertable<D> {
  const _Touched(this.inner, this.now);

  final Insertable<D> inner;
  final DateTime now;

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {
    ...inner.toColumns(nullToAbsent),
    'updated_at': Variable<DateTime>(now),
    'dirty': const Variable<bool>(true),
  };
}
