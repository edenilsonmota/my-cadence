import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/dates.dart';
import '../../../shared/file_access.dart';
import '../application/manual_backup.dart';
import '../data/file_transport.dart';
import '../domain/snapshot.dart';
import '../sync_providers.dart';

void _snack(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Exporta todos os dados num JSON (o "Salvar como" do sistema).
Future<void> exportJsonFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final file = await ref.read(manualBackupProvider).export();
  final saved = await ref.read(fileSaverProvider)(
    file.name,
    BackupFile.encode(file.snapshot),
  );
  if (saved) _snack(messenger, 'Backup exportado.');
}

/// Escolhe um JSON, mostra a prévia e mescla ou substitui.
Future<void> importJsonFlow(BuildContext context, WidgetRef ref) async {
  final files = await ref.read(importFilesPickerProvider)();
  if (files.isEmpty || !context.mounted) return;
  await importBytesFlow(context, ref, files.first.bytes);
}

/// Restaura uma das cópias guardadas no app (automáticas ou feitas antes de
/// substituir), com a mesma prévia da importação.
Future<void> restoreCopyFlow(BuildContext context, WidgetRef ref) async {
  final copies = await ref.read(backupCopiesProvider)();
  if (!context.mounted) return;
  if (copies.isEmpty) {
    _snack(ScaffoldMessenger.of(context), 'Nenhuma cópia guardada ainda.');
    return;
  }
  final picked = await showDialog<BackupCopy>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Restaurar cópia'),
      children: [
        for (final c in copies)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(c),
            child: Text(c.label),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  final bytes = await picked.read();
  if (!context.mounted) return;
  await importBytesFlow(context, ref, bytes);
}

/// Prévia e importação (mesclar ou substituir) de um backup já lido.
Future<void> importBytesFlow(
  BuildContext context,
  WidgetRef ref,
  Uint8List bytes,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final backup = ref.read(manualBackupProvider);
  final ImportPreview preview;
  try {
    preview = backup.preview(bytes);
  } on SnapshotFormatException catch (e) {
    _snack(messenger, e.message);
    return;
  }
  final choice = await showModalBottomSheet<_ImportChoice>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ImportPreviewSheet(preview: preview),
  );
  if (choice == null || !context.mounted) return;
  if (choice == _ImportChoice.replace) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Substituir tudo?'),
        content: const Text(
          'Os dados deste aparelho serão trocados pelos do arquivo. '
          'Antes, uma cópia dos dados atuais fica guardada no app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Substituir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await backup.importReplace(preview);
    _snack(
      messenger,
      'Dados substituídos. Uma cópia dos anteriores foi guardada.',
    );
    return;
  }
  final counts = await backup.importMerge(preview);
  final changed = counts.inserted + counts.updated + counts.deleted;
  _snack(
    messenger,
    changed == 0
        ? 'Nada novo no arquivo.'
        : 'Backup mesclado: ${counts.inserted} novos, '
              '${counts.updated} atualizados, ${counts.deleted} excluídos.',
  );
}

enum _ImportChoice { merge, replace }

class _ImportPreviewSheet extends StatefulWidget {
  const _ImportPreviewSheet({required this.preview});

  final ImportPreview preview;

  @override
  State<_ImportPreviewSheet> createState() => _ImportPreviewSheetState();
}

class _ImportPreviewSheetState extends State<_ImportPreviewSheet> {
  _ImportChoice _choice = _ImportChoice.merge;

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;
    final space = context.space;
    final local = p.generatedAt.toLocal();
    final when = '${formatDate(local, DateTime.now())}, ${formatTime(local)}';
    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(space.page, 0, space.page, space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Importar backup', style: context.text.titleLarge),
            SizedBox(height: space.xs),
            Text(
              'De $when${p.deviceName.isEmpty ? '' : ' · ${p.deviceName}'}',
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: space.lg),
            Wrap(
              spacing: space.sm,
              runSpacing: space.sm,
              children: [
                Chip(
                  avatar: const Icon(AppIcons.task),
                  label: Text(count(p.tasks, 'tarefa', 'tarefas')),
                ),
                Chip(
                  avatar: const Icon(AppIcons.flashcard),
                  label: Text(count(p.cards, 'card', 'cards')),
                ),
                Chip(
                  avatar: const Icon(AppIcons.book),
                  label: Text(count(p.books, 'book', 'books')),
                ),
                Chip(
                  avatar: const Icon(AppIcons.page),
                  label: Text(count(p.pages, 'página', 'páginas')),
                ),
              ],
            ),
            SizedBox(height: space.lg),
            RadioGroup<_ImportChoice>(
              groupValue: _choice,
              onChanged: (v) => setState(() => _choice = v!),
              child: const Column(
                children: [
                  RadioListTile(
                    value: _ImportChoice.merge,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Mesclar'),
                    subtitle: Text(
                      'Junta com os dados deste aparelho. Nada é apagado.',
                    ),
                  ),
                  RadioListTile(
                    value: _ImportChoice.replace,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Substituir tudo'),
                    subtitle: Text(
                      'Troca os dados deste aparelho pelos do arquivo.',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: space.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_choice),
              child: const Text('Importar'),
            ),
          ],
        ),
      ),
    );
  }
}
