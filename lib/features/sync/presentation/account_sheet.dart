import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/clock.dart';
import '../../../app/l10n/l10n.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/dates.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../application/account_controller.dart';
import '../application/sync_service.dart';
import '../application/sync_status.dart';
import '../data/google_account.dart';
import '../sync_providers.dart';
import 'account_avatar.dart';
import 'backup_actions.dart';

/// Folha "Conta e sincronização" (toque no avatar).
Future<void> showAccountSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AccountSheet(),
    );

void _snack(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Conecta (ou troca de conta) e, se houver dados dos dois lados, pergunta
/// se junta ou usa só os da nuvem.
Future<void> connectFlow(
  BuildContext context,
  WidgetRef ref, {
  bool switching = false,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  // O trecho da folha que chamou some ao conectar (vira o "conectado"):
  // depois dos awaits, use o container, não o `ref` do widget.
  final container = ProviderScope.containerOf(context, listen: false);
  final flag = container.read(awaitingFirstChoiceProvider.notifier);
  final account = container.read(accountProvider.notifier);
  flag.set(true);
  try {
    try {
      if (switching) {
        await account.switchAccount();
      } else {
        await account.connect();
      }
    } on AccountAuthException catch (e) {
      if (!e.canceled) _snack(messenger, e.message);
      return;
    }
    final engine = container.read(syncEngineProvider);
    final repo = container.read(snapshotRepositoryProvider);
    bool remote;
    try {
      remote = await engine.remoteExists();
    } on Object {
      remote = false; // offline: o sync automático junta depois
    }
    if (remote && await repo.hasUserData() && context.mounted) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.syncCloudHasData),
          content: Text(
            switching
                ? l10n.syncCloudHasDataOtherAccount
                : l10n.syncCloudHasDataThisAccount,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancelar'),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('nuvem'),
              child: Text(l10n.syncUseCloudOnly),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('juntar'),
              child: Text(l10n.syncMerge),
            ),
          ],
        ),
      );
      switch (choice) {
        case 'nuvem':
          await container
              .read(syncServiceProvider.notifier)
              .replaceWithRemote();
          _snack(messenger, l10n.syncCloudLoaded);
          return;
        case 'juntar':
          break;
        default:
          await account.disconnect();
          return;
      }
    }
  } finally {
    flag.set(false);
  }
  await container.read(syncServiceProvider.notifier).sync();
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = context.space;
    final account = ref.watch(accountProvider).value;
    final info = account?.account;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(space.page, 0, space.page, space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (info == null)
              _Disconnected(configured: account?.configured ?? false)
            else
              _Connected(info: info),
            SectionHeader(context.l10n.backupManual, padding: EdgeInsets.zero),
            SizedBox(height: space.xs),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.export),
              title: Text(context.l10n.settingsExportJson),
              onTap: () => exportJsonFlow(context, ref),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.import),
              title: Text(context.l10n.settingsImportJson),
              onTap: () => importJsonFlow(context, ref),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.history),
              title: Text(context.l10n.backupRestoreCopy),
              subtitle: Text(context.l10n.backupDailyCopyHint),
              onTap: () => restoreCopyFlow(context, ref),
            ),
            const _DeviceRow(),
          ],
        ),
      ),
    );
  }
}

class _Disconnected extends ConsumerWidget {
  const _Disconnected({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = context.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          AppIcons.cloud,
          size: AppIconSize.feature,
          color: context.colors.onSurfaceVariant,
        ),
        SizedBox(height: space.md),
        Text(
          context.l10n.syncWithDrive,
          textAlign: TextAlign.center,
          style: context.text.titleLarge,
        ),
        SizedBox(height: space.sm),
        Text(
          context.l10n.syncDriveExplain,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.lg),
        FilledButton.icon(
          icon: const Icon(AppIcons.account),
          label: Text(context.l10n.syncConnectGoogle),
          onPressed: configured ? () => connectFlow(context, ref) : null,
        ),
        if (!configured) ...[
          SizedBox(height: space.sm),
          Text(
            context.l10n.syncNotConfigured,
            textAlign: TextAlign.center,
            style: context.text.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: space.xl),
      ],
    );
  }
}

class _Connected extends ConsumerWidget {
  const _Connected({required this.info});

  final AccountInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = context.space;
    final status = ref.watch(syncServiceProvider);
    final service = ref.read(syncServiceProvider.notifier);
    final photo = ref.watch(accountProvider).value?.photo;
    final now = ref.watch(clockProvider)();
    final last = status.lastSyncAt;

    final line = switch (status.phase) {
      SyncPhase.syncing => context.l10n.syncStatusSyncing,
      SyncPhase.offline => context.l10n.syncStatusOffline,
      SyncPhase.pending => context.l10n.syncStatusPending,
      SyncPhase.error => status.message ?? context.l10n.syncStatusError,
      _ when last != null => context.l10n.syncStatusSyncedAgo(
        _ago(context.l10n, last, now),
      ),
      _ => context.l10n.syncStatusNever,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AccountFace(account: info, photo: photo, size: 64),
        ),
        SizedBox(height: space.md),
        if (info.name case final name?)
          Text(
            name,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
        Text(
          info.email,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.lg),
        Text(
          line,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium!.copyWith(
            color: status.phase == SyncPhase.error
                ? context.palette.danger.strong
                : context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.sm),
        if (status.needsSignIn)
          FilledButton.icon(
            icon: const Icon(AppIcons.account),
            label: Text(context.l10n.syncSignInAgain),
            onPressed: () => connectFlow(context, ref),
          )
        else if (status.needsReplace)
          FilledButton.icon(
            icon: const Icon(AppIcons.cloud),
            label: Text(context.l10n.syncUseCloudData),
            onPressed: service.replaceWithRemote,
          )
        else
          FilledButton.icon(
            icon: const Icon(AppIcons.sync),
            label: Text(context.l10n.syncNow),
            onPressed: status.phase == SyncPhase.syncing ? null : service.sync,
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.syncAuto),
          subtitle: Text(context.l10n.syncAutoHint),
          value: status.autoSync,
          onChanged: service.setAutoSync,
        ),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(AppIcons.switchAccount),
                label: Text(context.l10n.syncSwitchAccount),
                onPressed: () => connectFlow(context, ref, switching: true),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(AppIcons.signOut),
                label: Text(context.l10n.syncDisconnect),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = context.l10n;
                  await ref.read(accountProvider.notifier).disconnect();
                  _snack(messenger, l10n.syncDisconnected);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: space.lg),
      ],
    );
  }
}

/// Nome deste aparelho (editável) e o log de sync.
class _DeviceRow extends ConsumerStatefulWidget {
  const _DeviceRow();

  @override
  ConsumerState<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends ConsumerState<_DeviceRow> {
  String? _name;

  @override
  void initState() {
    super.initState();
    ref
        .read(snapshotRepositoryProvider)
        .customDeviceName()
        .then((n) => mounted ? setState(() => _name = n) : null);
  }

  Future<void> _rename() async {
    final name = await showTextInputDialog(
      context,
      title: context.l10n.syncDeviceName,
      label: context.l10n.reviewNameLabel,
      confirmLabel: context.l10n.actionSave,
      initialValue: _name ?? '',
    );
    if (name == null) return;
    await ref.read(snapshotRepositoryProvider).setDeviceName(name);
    if (mounted) setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton.icon(
          icon: const Icon(AppIcons.device),
          label: Text(_name ?? context.l10n.syncThisDevice),
          onPressed: _rename,
        ),
        TextButton.icon(
          icon: const Icon(AppIcons.history),
          label: Text(context.l10n.syncLog),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const _SyncLogDialog(),
          ),
        ),
      ],
    );
  }
}

class _SyncLogDialog extends ConsumerWidget {
  const _SyncLogDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(syncLogProvider).value ?? const [];
    final today = DateTime.now();
    return AlertDialog(
      title: Text(context.l10n.syncLog),
      content: SizedBox(
        width: double.maxFinite,
        child: entries.isEmpty
            ? Text(context.l10n.syncLogEmpty)
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final e in entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${formatRelative(e.at, today, withTime: true, lang: context.lang)} · '
                        '${e.result} · ${e.millis} ms',
                      ),
                      subtitle: e.detail == null ? null : Text(e.detail!),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionClose),
        ),
      ],
    );
  }
}

/// "agora há pouco", "há 5 min", "há 2 h", "há 3 dias" no idioma do app.
String _ago(AppLocalizations l10n, DateTime last, DateTime now) {
  final d = now.difference(last);
  if (d.inMinutes < 1) return l10n.syncAgoNow;
  if (d.inHours < 1) return l10n.syncAgoMinutes(d.inMinutes);
  if (d.inDays < 1) return l10n.syncAgoHours(d.inHours);
  return l10n.syncAgoDays(d.inDays);
}
