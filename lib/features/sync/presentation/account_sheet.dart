import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/clock.dart';
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
          title: const Text('Já existem dados na nuvem'),
          content: Text(
            switching
                ? 'A nova conta tem um Google Drive diferente, com dados do '
                      'My Cadence. O que fazer com os dados deste aparelho?'
                : 'Esta conta já tem dados do My Cadence. O que fazer com os '
                      'dados deste aparelho?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancelar'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('nuvem'),
              child: const Text('Usar só os da nuvem'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('juntar'),
              child: const Text('Juntar'),
            ),
          ],
        ),
      );
      switch (choice) {
        case 'nuvem':
          await container
              .read(syncServiceProvider.notifier)
              .replaceWithRemote();
          _snack(
            messenger,
            'Dados da nuvem carregados. Uma cópia dos anteriores foi guardada.',
          );
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
            const SectionHeader('Backup manual', padding: EdgeInsets.zero),
            SizedBox(height: space.xs),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.export),
              title: const Text('Exportar JSON'),
              onTap: () => exportJsonFlow(context, ref),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.import),
              title: const Text('Importar JSON'),
              onTap: () => importJsonFlow(context, ref),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(AppIcons.history),
              title: const Text('Restaurar cópia'),
              subtitle: const Text('O app guarda uma cópia por dia'),
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
          'Sincronize com o Google Drive',
          textAlign: TextAlign.center,
          style: context.text.titleLarge,
        ),
        SizedBox(height: space.sm),
        Text(
          'Seus dados ficam numa pasta privada do app no seu Google Drive, '
          'usando o seu espaço. Só este app enxerga essa pasta.',
          textAlign: TextAlign.center,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.lg),
        FilledButton.icon(
          icon: const Icon(AppIcons.account),
          label: const Text('Conectar com Google'),
          onPressed: configured ? () => connectFlow(context, ref) : null,
        ),
        if (!configured) ...[
          SizedBox(height: space.sm),
          Text(
            'Login com Google ainda não configurado neste app.',
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
      SyncPhase.syncing => 'Sincronizando…',
      SyncPhase.offline => 'Sem conexão. Sincroniza quando voltar.',
      SyncPhase.pending => 'Alterações a sincronizar',
      SyncPhase.error => status.message ?? 'Erro ao sincronizar',
      _ when last != null => 'Sincronizado ${syncedAgo(last, now)}',
      _ => 'Ainda não sincronizado',
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
            label: const Text('Entrar novamente'),
            onPressed: () => connectFlow(context, ref),
          )
        else if (status.needsReplace)
          FilledButton.icon(
            icon: const Icon(AppIcons.cloud),
            label: const Text('Usar os dados da nuvem'),
            onPressed: service.replaceWithRemote,
          )
        else
          FilledButton.icon(
            icon: const Icon(AppIcons.sync),
            label: const Text('Sincronizar agora'),
            onPressed: status.phase == SyncPhase.syncing ? null : service.sync,
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sincronização automática'),
          subtitle: const Text('Ao abrir, ao voltar ao app e após alterações'),
          value: status.autoSync,
          onChanged: service.setAutoSync,
        ),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(AppIcons.switchAccount),
                label: const Text('Trocar conta'),
                onPressed: () => connectFlow(context, ref, switching: true),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(AppIcons.signOut),
                label: const Text('Desconectar'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(accountProvider.notifier).disconnect();
                  _snack(
                    messenger,
                    'Desconectado. Os dados continuam neste aparelho.',
                  );
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
        .deviceName()
        .then((n) => mounted ? setState(() => _name = n) : null);
  }

  Future<void> _rename() async {
    final name = await showTextInputDialog(
      context,
      title: 'Nome deste aparelho',
      label: 'Nome',
      confirmLabel: 'Salvar',
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
          label: Text(_name ?? 'Este aparelho'),
          onPressed: _rename,
        ),
        TextButton.icon(
          icon: const Icon(AppIcons.history),
          label: const Text('Log de sync'),
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
      title: const Text('Log de sync'),
      content: SizedBox(
        width: double.maxFinite,
        child: entries.isEmpty
            ? const Text('Nenhuma sincronização ainda.')
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final e in entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${formatRelative(e.at, today, withTime: true)} · '
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
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
