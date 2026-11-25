import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
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
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final file = await ref.read(manualBackupProvider).export();
  final saved = await ref.read(fileSaverProvider)(
    file.name,
    BackupFile.encode(file.snapshot),
  );
  if (saved) _snack(messenger, l10n.backupExported);
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
    _snack(ScaffoldMessenger.of(context), context.l10n.backupNoCopies);
    return;
  }
  final picked = await showDialog<BackupCopy>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(context.l10n.backupRestoreCopy),
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
  final l10n = context.l10n;
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
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => _ImportPreviewSheet(preview: preview),
  );
  if (choice == null || !context.mounted) return;
  if (choice == _ImportChoice.replace) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupReplaceAllQuestion),
        content: Text(l10n.backupReplaceWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupReplace),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await backup.importReplace(preview);
    _snack(messenger, l10n.backupReplaced);
    return;
  }
  final counts = await backup.importMerge(preview);
  final changed = counts.inserted + counts.updated + counts.deleted;
  _snack(
    messenger,
    changed == 0
        ? l10n.backupNothingNew
        : l10n.backupMerged(counts.inserted, counts.updated, counts.deleted),
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
    final when =
        '${formatDate(local, DateTime.now(), lang: context.lang)}, ${formatTime(local)}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(space.page, 0, space.page, space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.backupImportTitle,
              style: context.text.titleLarge,
            ),
            SizedBox(height: space.xs),
            Text(
              context.l10n.backupFrom(
                '$when${p.deviceName.isEmpty ? '' : ' · ${p.deviceName}'}',
              ),
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
                  label: Text(context.l10n.countTasks(p.tasks)),
                ),
                Chip(
                  avatar: const Icon(AppIcons.flashcard),
                  label: Text(context.l10n.countCards(p.cards)),
                ),
                Chip(
                  avatar: const Icon(AppIcons.book),
                  label: Text(context.l10n.countBooks(p.books)),
                ),
                Chip(
                  avatar: const Icon(AppIcons.page),
                  label: Text(context.l10n.countPages(p.pages)),
                ),
              ],
            ),
            SizedBox(height: space.lg),
            RadioGroup<_ImportChoice>(
              groupValue: _choice,
              onChanged: (v) => setState(() => _choice = v!),
              child: Column(
                children: [
                  RadioListTile(
                    value: _ImportChoice.merge,
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.backupMerge),
                    subtitle: Text(context.l10n.backupMergeHint),
                  ),
                  RadioListTile(
                    value: _ImportChoice.replace,
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.backupReplaceAll),
                    subtitle: Text(context.l10n.backupReplaceAllHint),
                  ),
                ],
              ),
            ),
            SizedBox(height: space.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_choice),
              child: Text(context.l10n.actionImport),
            ),
          ],
        ),
      ),
    );
  }
}
