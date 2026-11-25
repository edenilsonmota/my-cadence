# My Cadence: sincronização (Google Drive + JSON manual)

Especificação da sincronização entre aparelhos. **Não existe backend próprio**: os dados vão para a pasta oculta do
app no Google Drive da pessoa (`appDataFolder`), usando o espaço da conta Google dela. A exportação e a importação
manual de JSON continuam existindo, como backup e como alternativa sem Google.

> **Como trabalhar (para o Claude Code)**
> - Leia também o `docs/PLANO.md` (colunas de sync, convenções) e o `docs/EVOLUCAO-VISUAL.md` (tokens, ícones, componentes).
> - Execute as fases da seção 9 **uma por vez**: `build_runner`, `flutter analyze`, `flutter test`, commit e parada para revisão.
> - Antes de usar `google_sign_in` e `googleapis`, **leia o README e o changelog da versão atual**. A API do
>   `google_sign_in` mudou bastante na 7.x (inicialização, autenticação e autorização de escopos separadas).
>   Não escreva código de memória.
> - O motor de mesclagem é o coração disto: lógica pura, sem Flutter, com testes cobrindo todos os casos da seção 4.

---

## 1. Visão geral

| Modo | Quando | Como |
|---|---|---|
| **Google Drive** | Automático, entre os aparelhos da mesma conta Google | Um snapshot JSON compactado na `appDataFolder`, mesclado linha a linha |
| **JSON manual** | Backup, migração, uso sem Google | Exportar/importar o mesmo formato de snapshot por arquivo |

Os dois modos usam **o mesmo formato e o mesmo motor de mesclagem**. Importar um JSON nunca apaga dados por padrão: mescla.

Fora de escopo: backend próprio, multiusuário, compartilhar books com outras pessoas, anexos/imagens (ver seção 10).

---

## 2. Arquitetura

```
lib/features/sync/
  domain/
    snapshot.dart          # modelo do snapshot + (de)serialização por tabela
    merge.dart             # motor de mesclagem (puro, testado)
    sync_transport.dart    # interface: fetch / push com controle de versão
  data/
    snapshot_repository.dart  # lê o banco local → snapshot; aplica o snapshot mesclado no banco
    drive_transport.dart      # implementação Google Drive (appDataFolder)
    file_transport.dart       # implementação arquivo (exportar/importar)
    google_account.dart       # login, troca de conta, foto, escopos
  application/
    sync_service.dart      # orquestra: quando sincronizar, tentativas, status
    sync_status.dart       # estado observável (Riverpod): idle, syncing, pending, error, offline, lastSyncAt
  presentation/
    account_avatar.dart    # avatar com anel de status (usado no cabeçalho)
    account_sheet.dart     # bottom sheet "Conta e sincronização"
    import_preview_sheet.dart
```

Interface do transporte:

```dart
abstract interface class SyncTransport {
  /// Snapshot remoto atual e a versão dele (null se ainda não existe).
  Future<({Snapshot? snapshot, String? version})> fetch();

  /// Grava o snapshot, mas só se a versão remota ainda for [expectedVersion].
  /// Lança VersionConflict se mudou nesse meio-tempo.
  Future<String> push(Snapshot snapshot, {String? expectedVersion});
}
```

---

## 3. Formato do snapshot

Um único documento JSON. No Drive vai compactado (`my-cadence-sync.json.gz`); na exportação manual, `.json` legível
(nome: `my-cadence-backup-AAAA-MM-DD-HHmm.json`).

```json
{
  "format": "my-cadence-sync",
  "formatVersion": 1,
  "schemaVersion": 7,
  "generatedAt": "2026-11-24T15:02:11.123Z",
  "generatedBy": { "deviceId": "0193…", "deviceName": "Pixel 8" },
  "devices": {
    "0193…": { "name": "Pixel 8", "lastSyncAt": "2026-11-24T15:02:11.123Z" }
  },
  "tables": {
    "tasks": [ { "id": "…", "updated_at": "…", "deleted_at": null, "title": "…" } ],
    "tags": [],
    "task_tags": [],
    "task_completions": [],
    "pomodoro_sessions": [],
    "decks": [],
    "flashcards": [],
    "review_logs": [],
    "notebooks": [],
    "note_pages": [],
    "task_page_links": [],
    "task_notebook_links": [],
    "task_deck_links": [],
    "app_settings": []
  }
}
```

Regras:
- Serialização **explícita por tabela** (nomes de coluna em snake_case, iguais aos do SQLite). Nada de depender da ordem das colunas.
- Datas em **ISO 8601 UTC com milissegundos**. Enums pelo nome (já são `textEnum`).
- **Todas as linhas vão, inclusive as com `deletedAt`** (tombstones), para a exclusão chegar aos outros aparelhos.
- `dirty` e `serverVersion` **não** entram no snapshot (são estado local). `serverVersion` fica reservado/sem uso.
- **Configurações locais do aparelho não sincronizam**: `deviceId`, nome do aparelho, conta conectada, último sync,
  preferências de tela. Marcar em `AppSettings` quais chaves são sincronizáveis (ex.: prefixo `sync.` ou coluna `scope`).
  Durações do pomodoro, retenção do FSRS etc. sincronizam.
- `deviceId` é um UUID gerado na primeira abertura e guardado localmente.

---

## 4. Motor de mesclagem (`merge.dart`)

Função pura: `MergeResult merge(Snapshot local, Snapshot remote)`.

Para cada tabela, une as linhas por `id`:

| Situação | Resultado |
|---|---|
| Só existe no local | Mantém (vai subir) |
| Só existe no remoto | Insere no local |
| Nos dois, `updatedAt` diferente | **Vence o `updatedAt` mais recente** (linha inteira) |
| Nos dois, mesmo `updatedAt` e conteúdo diferente | Desempate determinístico: vence a linha cujo JSON canônico (chaves ordenadas) for lexicograficamente maior. Garante que todos os aparelhos convergem para o mesmo resultado |
| Excluída de um lado, editada do outro | Vence o `updatedAt` mais recente (excluir também atualiza `updatedAt`) |

Requisitos:
- Toda escrita local já atualiza `updatedAt` e marca `dirty` (regra do PLANO). **Conferir** que concluir tarefa, revisar card,
  reordenar páginas e encerrar pomodoro também fazem isso.
- `MergeResult` informa: o snapshot mesclado, as linhas a gravar no local, se o remoto precisa ser atualizado e contadores
  (inseridas, atualizadas, excluídas, conflitos) para o log.
- **Aplicação no banco** numa única transação com `PRAGMA defer_foreign_keys = ON` (há autorreferência em `tasks.parentId`
  e `note_pages.parentPageId`; a ordem de inserção não pode importar).
- Depois de aplicar: reagendar alarmes das tarefas alteradas e invalidar os providers afetados.
- **Limpar `dirty`** só nas linhas cujo `updatedAt` local ainda é igual ao que foi enviado (uma edição feita durante o sync
  continua `dirty`).
- **Tombstones**: guardados por 180 dias e depois removidos do snapshot e do banco local. Um aparelho cujo `lastSyncAt`
  (em `devices`) tenha mais de 180 dias **não mescla**: o app pergunta se quer substituir os dados locais pelos da nuvem
  (com backup local automático antes), para não ressuscitar coisas apagadas.
- **Relógio**: `updatedAt` vem do relógio do aparelho (sincronizado por NTP no celular). Aceitável para uso pessoal.
  Se um `updatedAt` vier mais de 24 h no futuro, registrar no log de sync.

### Compatibilidade de schema
- Remoto com `schemaVersion` **maior** que o do app: não mesclar; avisar "Atualize o app neste aparelho para sincronizar".
- Remoto com `schemaVersion` **menor**: atualizar as linhas para o schema atual com funções de upgrade por versão
  (`upgraders[from] → to`), preenchendo padrões das colunas novas. Testar cada upgrader.
- `formatVersion` desconhecido: recusar com mensagem clara.

---

## 5. Google Drive

### Configuração no Google Cloud (eu faço; documente no README em `docs/google-cloud.md`)
1. Criar projeto "My Cadence" no Google Cloud Console e ativar a **Google Drive API**.
2. **Tela de consentimento OAuth**: tipo Externo, nome "My Cadence", e-mail de suporte, escopos
   `drive.appdata`, `openid`, `email`, `profile`. **Publicar como "Em produção"** (em modo Teste o login expira a cada 7 dias;
   como os escopos são não sensíveis, não há revisão demorada).
3. **Credenciais OAuth**:
   - Android: pacote `com.nextinfor.mycadence` + SHA-1 da chave **debug** (`cd android && ./gradlew signingReport`).
     Repetir com o SHA-1 da chave de release quando existir.
   - iOS: bundle `com.nextinfor.mycadence`.
   - Web: se a versão atual do `google_sign_in` exigir `serverClientId` no Android, criar e usar este ID.
4. Os IDs de cliente OAuth não são segredos, mas ficam num arquivo de configuração (`--dart-define` ou `lib/app/config/`),
   com instruções no `docs/google-cloud.md`. Nenhuma chave de assinatura no repositório.

### Pacotes
- `google_sign_in` (login, conta, foto, autorização de escopos), `googleapis` (Drive v3) e um cliente HTTP autenticado
  com o token de acesso (pelo pacote de extensão oficial ou um `BaseClient` que injeta o header). Confira versões e licenças.
- **Pedir só `drive.appdata`** (mais `email`/`profile` para nome e foto). Nunca `drive` nem `drive.file`.

### Arquivo no Drive
- Um arquivo `my-cadence-sync.json.gz` em `spaces=appDataFolder`, localizado por nome na primeira vez e com o `fileId`
  guardado localmente.
- **Controle de concorrência**: o Drive não tem gravação condicional atômica. Usar o campo `version` do arquivo:
  1. ler metadados (`id`, `version`) e baixar;
  2. mesclar e aplicar localmente;
  3. reler os metadados; se `version` mudou, repetir do passo 1 (até 3 vezes);
  4. enviar o snapshot mesclado e guardar a nova `version` como "última versão conhecida".
  A janela de corrida que sobra é de segundos e, no pior caso, se corrige no próximo sync (a mesclagem é idempotente).
- Se nada mudou (nenhuma linha `dirty` e `version` remota igual à última conhecida), **não baixar nem enviar**.
- Gravar antes um backup do snapshot remoto anterior como `my-cadence-sync.prev.json.gz` (uma geração só), para recuperação.

---

## 6. Orquestração (`sync_service.dart`)

Quando sincronizar (com o Google conectado e sincronização automática ligada):
- ao abrir o app;
- ao voltar do segundo plano, se o último sync foi há mais de 2 minutos;
- 30 s depois da última alteração local, com o app em primeiro plano (debounce);
- ao ir para o segundo plano (melhor esforço, sem bloquear);
- pelo botão "Sincronizar agora".

Regras:
- Um sync por vez (lock); pedidos durante um sync marcam "rodar de novo ao terminar".
- Sem internet: estado `offline`, sem erro barulhento; tenta de novo quando a conexão voltar.
- Falhas com backoff exponencial (30 s, 1, 2, 5 min…), e erro visível só depois de algumas tentativas.
- Token expirado ou acesso revogado: estado `error` com ação "Entrar novamente".
- **Log de sync** local (últimas 50 execuções: horário, duração, contadores, erro) visível na tela de conta.
- Sync periódico em segundo plano (`workmanager`) fica como melhoria opcional, não no MVP.

---

## 7. Interface

Usar os tokens, `AppIcons` e componentes do `EVOLUCAO-VISUAL.md`.

### Avatar da conta (cabeçalho)
- No canto superior direito das telas principais (componente compartilhado no shell).
- **Conectado**: foto de perfil do Google, em círculo. Guardar a foto em cache local para aparecer offline;
  sem foto, iniciais sobre o `tint` de uma cor da paleta.
- **Desconectado**: ícone de nuvem (da família de ícones) com tom neutro.
- **Status no avatar**, discreto:
  - sincronizado: nada;
  - sincronizando: anel girando fino em volta;
  - alterações pendentes ou offline: pontinho neutro;
  - erro: pontinho na cor de perigo.

### Bottom sheet "Conta e sincronização" (toque no avatar)
- Topo: foto grande, nome, e-mail.
- "Sincronizado há 3 min" (ou o estado atual) e o botão principal **Sincronizar agora**.
- Interruptor **Sincronização automática**.
- **Trocar conta** e **Desconectar** (ações secundárias).
- Seção **Backup manual**: **Exportar JSON** e **Importar JSON**.
- Linha discreta: nome deste aparelho (editável) e link para o log de sync.
- Desconectado: explicação curta ("Seus dados ficam numa pasta privada do app no seu Google Drive, usando o seu espaço")
  e o botão **Conectar com Google**. O backup manual continua disponível.

### Primeira conexão e troca de conta
- Conectar com dados locais **e** dados na nuvem: perguntar
  - **Juntar** (recomendado): mescla os dois;
  - **Usar só os da nuvem**: substitui os locais (backup local automático antes);
  - Cancelar.
- Trocar de conta: mesma pergunta, explicando que a nova conta tem um Drive diferente.
- Desconectar: mantém os dados no aparelho; apenas para de sincronizar e esquece o `fileId` e a versão.

### Importar JSON
- Escolher o arquivo → validar `format`, `formatVersion` e `schemaVersion` → **prévia**: data do backup, aparelho de origem,
  quantidade de tarefas, cards, books e páginas.
- Opções: **Mesclar** (padrão) ou **Substituir tudo** (confirmação explícita + backup local automático antes).
- Com o Google conectado, o resultado da importação sobe no próximo sync.

### Exportar JSON
- Gera o snapshot completo e abre o compartilhamento do sistema (`share_plus`), ou salva com `file_picker`.

---

## 8. Testes

**Motor de mesclagem (unitários):**
- linha só local, só remota, nos dois lados com `updatedAt` diferentes;
- empate de `updatedAt` → mesmo resultado nos dois sentidos (`merge(a, b) == merge(b, a)`);
- exclusão × edição, nos dois sentidos;
- idempotência: `merge(merge(a, b), b) == merge(a, b)`;
- subtarefa chegando antes da mãe e página filha antes da página mãe (FK adiada);
- tombstone com mais de 180 dias é removido; aparelho inativo por mais de 180 dias é bloqueado;
- upgrader de schema antigo → atual; schema futuro recusado;
- `AppSettings` locais não entram no snapshot.

**Serialização:** ida e volta (banco → snapshot → banco) sem perda para todas as tabelas, incluindo enums, datas e nulos.

**Transporte e serviço (com `FakeDriveTransport`):**
- primeiro sync com Drive vazio;
- outro "aparelho" grava no meio do sync → `version` muda → repetição → resultado correto;
- edição local durante o sync continua `dirty`;
- falha de rede → `offline` → sucesso depois;
- nada mudou → nenhuma chamada de download/upload.

**Checklist manual (dois emuladores ou celular + emulador, mesma conta):**
criar no A e ver no B; editar a mesma tarefa nos dois offline e reconectar; excluir no A e editar no B; concluir rotina nos dois;
revisar cards nos dois; editar a mesma página nos dois (vence a última, sem corromper); trocar de conta; importar backup antigo.

---

## 9. Fases (um commit e uma parada por fase)

1. **Snapshot e mesclagem**: modelo, serialização por tabela, motor de mesclagem, upgraders, marcação de `AppSettings` locais,
   aplicação no banco em transação e todos os testes da seção 8 (sem rede).
2. **JSON manual**: exportar, importar com prévia, mesclar/substituir, backup automático antes de substituir. Substitui o
   backup simples da Etapa 10, se ele já existir.
3. **Conta Google**: configuração documentada em `docs/google-cloud.md`, login, foto, trocar conta, desconectar,
   avatar com status e o bottom sheet (sem sincronizar ainda).
4. **Drive**: `DriveTransport` na `appDataFolder`, controle por `version`, backup `prev`, fluxo da primeira conexão.
5. **Orquestração**: gatilhos automáticos, lock, backoff, offline, log de sync, reagendamento de alarmes após aplicar.
6. **Conferência**: checklist manual com dois aparelhos, screenshots da tela de conta (tema claro e escuro), README atualizado.

---

## 10. Limites conhecidos e melhorias futuras

- **Snapshot único**: simples e suficiente para uso pessoal. Medir o tamanho; se passar de ~5 MB compactado, dividir em
  arquivos por tabela ou por book (`pages/<notebookId>.json.gz`), mantendo o mesmo motor.
- **Páginas editadas em dois aparelhos ao mesmo tempo**: vence a última versão inteira da página. Mesclagem fina
  (CRDT ou `appflowy_editor_sync_plugin`) só se isso virar problema real.
- **Anexos/imagens nos books**: arquivos separados na `appDataFolder` (`attachments/<id>`), referenciados pelo id.
- **Web ou backend próprio**: fora do plano atual. Se um dia for preciso, o formato do snapshot e as colunas de sync já
  servem de base.
