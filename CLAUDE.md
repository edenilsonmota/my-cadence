# My Cadence

App Flutter pessoal, offline-first: tarefas, flashcards FSRS, pomodoro, books e agenda.
A especificação completa e as etapas estão em [docs/PLANO.md](docs/PLANO.md). Leia antes de começar uma etapa.

## Como trabalhar

- **Uma etapa por vez, na ordem do plano.** Ao terminar: `dart run build_runner build` (se mexeu em tabelas
  ou providers gerados; a flag `-d` não existe mais no build_runner 2.17), `flutter analyze` e `flutter test`
  limpos, commit com mensagem descritiva e **parar para revisão**.
- Os arquivos gerados (`*.g.dart`) são versionados, para o projeto rodar logo após o clone.
- **Cada pacote entra só na etapa que o usa.** Antes de adicionar, conferir no pub.dev a versão estável e a
  compatibilidade com o Flutter instalado. Não inventar APIs: ler a documentação ou o código em `~/.pub-cache`.
- Declarar a versão mínima esperada de cada pacote (`^x.y.z`) para o resolvedor falhar alto, em vez de cair
  silenciosamente numa versão antiga.
- Na dúvida entre simples e "arquiteturalmente bonito", escolher o simples.
- Se uma decisão do plano se mostrar ruim na prática, parar e explicar antes de mudar.
- O que só dá para validar no celular (alarmes, notificações, reboot, gestos reais) vai como checklist em
  [docs/TESTES_APARELHO.md](docs/TESTES_APARELHO.md); rodar e marcar quando o aparelho estiver disponível.
- Repositório público: nunca commitar chaves, keystores, `.env`, `google-services.json` ou dados pessoais.

## Identidade

- Pacote Dart `my_cadence`; ID do app `com.nextinfor.mycadence` (Android e iOS, sem `_` porque o iOS não aceita).
- Nome no ícone: **Cadence**. Título interno e README: **My Cadence**.

## Arquitetura

- Fluxo de dados: **UI → provider (Riverpod) → repository → DAO (drift)**. Widgets só leem providers; a UI
  nunca fala com o DAO.
- Pastas (feature-first): `app/` (MaterialApp, tema, rotas, shell), `core/` (utilitários puros),
  `data/db` + `data/repositories`, `features/<domínio>/`, `shared/widgets/`. `test/` espelha `lib/`.
- Lógica pura (recorrência, ocorrências, layout do calendário, ponte FSRS, métricas) fica **sem Flutter** e tem
  teste unitário.
- Rotas centralizadas em `lib/app/router.dart` (`Routes`). Abas: Hoje, Tarefas, Agenda, Revisar, Books.
  Métricas e Ajustes abrem pelo menu lateral, por cima do shell.

## Banco e sync

- Toda tabela usa o mixin `SyncColumns` (id UUID v7, `createdAt`, `updatedAt`, `deletedAt`, `dirty`, `serverVersion`).
- Toda escrita nos DAOs passa por `SyncWrites` (`lib/data/db/sync_writes.dart`: `insertSynced`, `updateSynced`,
  `softDeleteSynced`), que aplica `updatedAt = now` e `dirty = true`. Nunca usar `into().insert`, `update()` ou
  `delete()` direto.
- **Nunca exclusão física**: sempre `deletedAt`. Cascatas: tarefa → subtarefas, tag → vínculos,
  caderno → páginas, página → subpáginas. Excluir deck desvincula os cards.
- Toda leitura filtra `deletedAt.isNull()`.
- Tabelas de vínculo (`TaskTags`, `TaskPageLinks`) e `AppSettings` têm chave única: re-vincular **revive** a
  linha excluída em vez de inserir outra.
- Repositórios criam com parâmetros nomeados (a UI não monta Companions) e `saveX(objeto)` grava só os campos
  editáveis, nunca as colunas de sync.
- DateTime fica no formato padrão do drift (inteiro, **segundos** desde a época, comparável sem depender de fuso).
  Não há milissegundos no banco.
- Enums como **`textEnum`** (o nome do valor). Renomear um valor exige migração.
- `PRAGMA foreign_keys = ON` no `beforeOpen`.
- **Migrações:** ao mudar o esquema, incrementar `schemaVersion`, rodar `dart run drift_dev make-migrations`
  (gera o dump em `drift_schemas/` e os helpers de teste), escrever o passo em `onUpgrade` e um teste de
  integridade de dados em `test/data/db/migrations/`. O teste de migração percorre todas as versões salvas.
- Testes de dados usam `openTestDb()` (`test/data/test_db.dart`, banco em memória).
- Sync (Etapa 11): ao confirmar o push, só marcar `dirty = false` se o `updatedAt` local ainda for o enviado.

## Regras de domínio que não podem escorregar

- **Datas FSRS em UTC** na ponte (`toUtc()` ao montar, `toLocal()` ao salvar); importar
  `package:fsrs/fsrs.dart` com prefixo `fsrs` (`Card` e `State` colidem com o Flutter).
- **Pomodoro sem `Timer` acumulando**: decorrido = `(pausedAt ?? agora) - startedAt - pausedTotalMs`.
  Pausar cancela a notificação de fim; retomar soma a pausa e reagenda.
- **ID de notificação** = FNV-1a do UUID reduzido a 31 bits. **Nunca `String.hashCode`** (muda entre execuções).
- Recorrência em RRULE (subconjunto DAILY/WEEKLY, INTERVAL, BYDAY, UNTIL); rotina é uma linha só; ocorrências
  futuras no calendário são virtuais.
- Páginas: a fonte da verdade é o JSON do editor; Markdown só para importar e exportar.

## Rotinas e alarmes

- Concluir sempre por `TasksRepository.completeTask` (nunca `setStatus(feita)` direto): rotina grava o
  histórico, avança prazo/início (`core/routine.dart`), reabre subtarefas e, depois do UNTIL, fica feita.
- Lembretes são **derivados das tarefas**: `AlarmSync` (`features/tasks/alarms.dart`) observa todas as
  tarefas e agenda/cancela o que mudou; na abertura reagenda tudo. Não agendar notificação de tarefa
  em outro lugar.
- Tarefa de dia inteiro lembra às `allDayReminderHour` (9h) menos a antecedência.
- Ações "Concluir"/"Adiar" rodam em isolate de segundo plano (`notification_actions.dart`, top-level com
  `@pragma('vm:entry-point')`), abrem o próprio banco e reagendam ali mesmo. O banco usa
  `shareAcrossIsolates`, WAL e `busy_timeout`; ao voltar ao app, as consultas são forçadas a reler.
- Nos testes, `alarmSchedulerProvider` é trocado por `FakeScheduler` (`test/helpers/fake_scheduler.dart`).
- Testar alarme no aparelho: fechar com `adb shell am kill` (o `force-stop` apaga os alarmes do app).

## UI e testes

- Telas leem providers (`features/<domínio>/*_providers.dart`); ações chamam o repositório via
  `ref.read(xRepositoryProvider)`. O "hoje" vem de `todayProvider` (vira sozinho à meia-noite), nunca
  de `DateTime.now()` espalhado.
- Lógica de tela que dá para testar sem Flutter fica em arquivo puro (ex.: `task_lists.dart`, `task_draft.dart`).
- Rotas de tarefa: `Routes.task(id)` (hub, alvo dos deep links), `Routes.editTask(id)`, `Routes.newTask(...)`.
  Abrem no navegador raiz, por cima das abas.
- Antes de abrir seletor de data/hora ou diálogo a partir de um formulário, tirar o foco do campo de
  texto (senão o foco volta ao campo ao fechar e o teclado sobe).
- FABs das abas usam `heroTag: null` (as abas ficam vivas no `IndexedStack` e os Heroes colidiriam).
- Testes de widget: `pumpApp(tester, seed: ..., today: ...)` de `test/helpers/pump_app.dart` (banco em
  memória, 360 dp, hoje fixo) e **`settle(tester)` no lugar de `pumpAndSettle`**, porque o banco só
  responde em tempo real. Ler o banco no teste com `tester.runAsync`.
  Depois de `enterText`, chamar `settle` antes de tocar em botões que dependem do texto (senão o botão
  ainda está desabilitado). Antes de tocar em algo que pode estar fora da tela, `tester.ensureVisible`.
- O relógio vem de `clockProvider` (hub: "vencidos agora", sessão em andamento); `pumpApp` fixa ao
  meio-dia do "hoje" do teste.

## Estilo

- Textos da UI em **português do Brasil**; nenhuma string em inglês.
- Material 3 com `colorSchemeSeed`, tema claro e escuro; testar em 360 dp de largura.
- Lints estritos em `analysis_options.yaml` (inclui `prefer_const_constructors`, `always_declare_return_types`,
  `avoid_dynamic_calls`, `require_trailing_commas`). Rodar `dart format` antes do commit.

## Ambiente

- Flutter 3.47 / Dart 3.13. `flutter_local_notifications` 23 exige `compileSdk = 37` e AGP ≥ 9.1.1.
- No Linux não dá para compilar iOS: a configuração iOS é feita seguindo o README dos plugins, mas sem build.
