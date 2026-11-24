import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import 'update_providers.dart';

/// Linhas de "Atualizações" em Ajustes: versão instalada e verificação.
class UpdateTiles extends ConsumerWidget {
  const UpdateTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    final update = ref.watch(updateProvider);
    final release = update.release;
    final status = switch (update.phase) {
      UpdatePhase.idle => 'Toque para procurar uma versão nova',
      UpdatePhase.checking => 'Verificando…',
      UpdatePhase.upToDate => 'Você está na versão mais recente',
      UpdatePhase.available => 'Versão ${release!.version} disponível',
      UpdatePhase.error => 'Não foi possível verificar. Tente de novo.',
    };
    return Column(
      children: [
        ListTile(
          leading: const Icon(AppIcons.sync),
          title: Text('Versão ${version ?? '…'}'),
          subtitle: Text(status),
          onTap: update.phase == UpdatePhase.checking
              ? null
              : () => ref.read(updateProvider.notifier).check(),
          trailing: release == null
              ? null
              : FilledButton.tonal(
                  onPressed: () => openRelease(ref),
                  child: const Text('Baixar'),
                ),
        ),
        if (release?.notes case final notes?)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.space.lg,
              0,
              context.space.lg,
              context.space.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                notes,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}

/// Abre o APK da release (ou a página dela) no navegador.
Future<void> openRelease(WidgetRef ref) async {
  final release = ref.read(updateProvider).release;
  if (release == null) return;
  await ref.read(urlOpenerProvider)(release.apkUrl ?? release.pageUrl);
}

/// Verifica atualização ao abrir o app (no máximo uma vez por dia) e avisa
/// com uma SnackBar quando há versão nova.
class UpdateWatcher extends ConsumerStatefulWidget {
  const UpdateWatcher({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateWatcher> createState() => _UpdateWatcherState();
}

class _UpdateWatcherState extends ConsumerState<UpdateWatcher> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(updateProvider.notifier).check(auto: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateProvider, (previous, next) {
      if (previous?.phase != UpdatePhase.checking ||
          next.phase != UpdatePhase.available) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Versão ${next.release!.version} disponível'),
          action: SnackBarAction(
            label: 'Baixar',
            onPressed: () => openRelease(ref),
          ),
        ),
      );
    });
    return widget.child;
  }
}
