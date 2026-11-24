import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../application/account_controller.dart';
import '../application/sync_service.dart';
import '../application/sync_status.dart';
import '../data/google_account.dart';
import 'account_sheet.dart';

/// Avatar da conta no cabeçalho: foto (ou iniciais), nuvem quando
/// desconectado, e o status do sync discreto (anel girando, ponto neutro ou
/// ponto de perigo). Toque abre "Conta e sincronização".
class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider).value;
    final status = ref.watch(syncServiceProvider);
    final info = account?.account;
    const size = 30.0;

    final face = info == null
        ? Icon(
            AppIcons.cloud,
            size: AppIconSize.action,
            color: context.colors.onSurfaceVariant,
          )
        : AccountFace(account: info, photo: account?.photo, size: size);

    final Color? dot = switch (status.phase) {
      SyncPhase.error => context.palette.danger.strong,
      SyncPhase.pending || SyncPhase.offline => context.colors.outline,
      _ => null,
    };

    return IconButton(
      tooltip: switch (status.phase) {
        SyncPhase.disconnected => 'Conta e sincronização',
        SyncPhase.syncing => 'Sincronizando',
        SyncPhase.offline => 'Sem conexão: sincroniza depois',
        SyncPhase.pending => 'Alterações a sincronizar',
        SyncPhase.error => 'Erro na sincronização',
        SyncPhase.idle => 'Sincronizado',
      },
      onPressed: () => showAccountSheet(context),
      icon: SizedBox.square(
        dimension: size + 6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            face,
            if (status.phase == SyncPhase.syncing)
              SizedBox.square(
                dimension: size + 6,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.primary,
                ),
              ),
            if (dot != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Foto da conta em círculo; sem foto, as iniciais sobre o tom suave de uma
/// cor da paleta (sempre a mesma para o mesmo e-mail).
class AccountFace extends StatelessWidget {
  const AccountFace({
    required this.account,
    required this.photo,
    required this.size,
    super.key,
  });

  final AccountInfo account;
  final Uint8List? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (photo != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(photo),
      );
    }
    final key =
        PaletteKey.values[account.email.codeUnits.fold(0, (a, b) => a + b) %
            PaletteKey.values.length];
    final tones = context.palette.of(key);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: tones.tint,
      child: Text(
        account.initials,
        style: context.text.labelLarge!.copyWith(
          color: tones.onTint,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
        textScaler: TextScaler.linear(size / 30),
      ),
    );
  }
}
