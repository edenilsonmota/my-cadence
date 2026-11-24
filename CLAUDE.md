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
- Sync (Etapa 11, `docs/SINCRONIZACAO.md`): Google Drive (`appDataFolder`) + JSON manual, sem backend.
  Snapshot em `features/sync/domain/snapshot.dart` (snake_case, datas ISO UTC, sem `dirty`/`serverVersion`, sem
  ajustes do aparelho: prefixos `sync.`, `device.`, `calendar.`). Mesclagem pura em `merge.dart` (vence o
  `updated_at` mais recente; empate pelo JSON canônico; vínculos e ajustes pela chave natural; tombstones de
  180 dias). `SnapshotRepository` lê o banco pelos metadados das tabelas e aplica em transação com
  `defer_foreign_keys`; `markClean` só limpa `dirty` se o `updated_at` ainda é o enviado.
- Cópia local automática diária (`autoBackupIfDue`, 7 últimas em `backups/auto`) e as de antes de substituir
  (5 últimas); "Restaurar cópia" na folha da conta usa a mesma prévia da importação.
- Ao mudar o esquema, acrescentar o upgrader do snapshot em `sync/domain/upgraders.dart` (e o teste).
- Orquestração: `SyncEngine` (um ciclo: versão → fetch → merge/apply → push condicional, até 3 tentativas;
  `markClean` do que foi enviado) e `SyncService` (Riverpod: ao abrir, ao voltar após 2 min, 30 s após
  alteração **pendente**, ao sair, botão; lock; backoff; offline silencioso; log em `sync.log`).
  `DriveTransport` usa `appDataFolder`, `version` do arquivo e cópia `.prev`; pede um cliente novo a cada
  operação (token do Google vale 1 h), limita cada requisição a 30 s e, em 401, descarta o token e tenta
  uma vez. Não há "restaurar sessão" ao abrir: a autorização do Drive vai pelo e-mail guardado. Conta: `GoogleAccountApi`
  (`google_sign_in` 7), configurada por `--dart-define-from-file=config/google.json` (`docs/google-cloud.md`).
- Testes de sync: `FakeSyncTransport`/`FakeAccountApi` (`test/helpers/fake_sync.dart`); `pumpApp` aceita
  `accountApi:` e `syncTransport:` (não sobrescrever esses providers por `overrides:`).
- Callbacks de UI que trocam de conta: depois de `await`, usar `ProviderScope.containerOf(context)`, não o
  `ref` do widget (o trecho da tela que chamou pode ter sumido).

## Cores e ícones (dados)

- `Tags.colorKey`, `Tasks.colorKey`/`iconKey`, `Notebooks.colorKey`/`iconKey`: **chaves** (paleta `PaletteKey`,
  catálogo `IconCatalog`), nunca ARGB nem codePoint. Chave desconhecida cai na herança.
- Herança em `features/tasks/task_appearance.dart` (puro, testado): cor da tarefa → mãe → 1ª tag (alfabética)
  → tipo; ícone da tarefa → mãe → tipo. Na UI, `appearanceResolverProvider`.
- Seletor único `showAppearancePicker` (`shared/widgets/appearance_picker.dart`); `AppearanceBadge` e `TagChip`.

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
- A antecedência do lembrete conta do **início** quando ele tem hora (bloco da agenda avisa ao começar);
  senão, do prazo. Tarefa de dia inteiro lembra na hora do ajuste `tasks.allDayReminderHour`
  (padrão 9h; `AlarmSync.setAllDayHour`; o isolate das ações lê o mesmo ajuste) menos a antecedência.
- Ações "Concluir"/"Adiar" rodam em isolate de segundo plano (`notification_actions.dart`, top-level com
  `@pragma('vm:entry-point')`), abrem o próprio banco e reagendam ali mesmo. O banco usa
  `shareAcrossIsolates`, WAL e `busy_timeout`; ao voltar ao app, as consultas são forçadas a reler.
- Nos testes, `alarmSchedulerProvider` é trocado por `FakeScheduler` (`test/helpers/fake_scheduler.dart`).
- Testar alarme no aparelho: fechar com `adb shell am kill` (o `force-stop` apaga os alarmes do app).

## Pomodoro

- Fonte da verdade é a linha em `PomodoroSessions`; tempo sempre por `pomodoro_logic.dart`
  (`elapsed`, `remaining`, `endTime`), nunca acumulado em Timer.
- `PomodoroController` (Riverpod) inicia/pausa/retoma/para, agenda o aviso de fim (id fixo
  `pomodoroNotificationId`, payload `pomodoro`) e fecha a sessão vencida em `checkDue()`, chamado pelo
  timer do fim, pela batida de 1 s da tela e ao voltar o app. Sessão vencida fecha com
  `endedAt = endTime`, não com a hora em que o app percebeu.
- Ajustes do pomodoro ficam em `AppSettings` com prefixo `pomodoro.` (`PomodoroSettings`).
- Riverpod 3: provider só lido com `ref.read(x.future)`, sem ninguém escutando, fica pausado e não
  completa. Quem precisa ler assim deve manter um `ref.listen` no provider.
- Nos testes, `tickerProvider` é um stream parado e `screenAwakeProvider` é falso (ver `pumpApp`);
  para simular o fim, avance o relógio do teste e `tester.pump(duração)`.

## Flashcards (FSRS)

- Ponte em `features/cards/fsrs_bridge.dart` (pacote com prefixo `fsrs`, datas em UTC na ida e
  local na volta). `CardSchedule` (colunas FSRS) mora em `data/db/card_schedule.dart`.
- A revisão calcula a prévia das 4 notas (`previewReview`) ao mostrar a resposta e grava **exatamente**
  o resultado do botão escolhido (o "fuzz" faz duas chamadas darem intervalos diferentes).
- Gravar revisão sempre por `CardsRepository.applyReview` (agendamento + log na mesma transação);
  desfazer por `undoReview`.
- Fila: `buildQueue` (estudados por vencimento, depois novos até o limite do dia, contado pela
  primeira revisão de cada card hoje). Ajustes com prefixo `cards.` (`CardSettings`).
- `clockProvider`/`tickerProvider` ficam em `lib/app/clock.dart`.

## Books (AppFlowy Editor)

- O editor vem do **fork** `edenilsonmota/appflowy-editor`, branch `cadence/file-picker-13`, fixado
  por commit no `pubspec.yaml` (o pub.dev 6.2.0 não compila no Flutter 3.44+ e prende file_picker 10).
  O fork só adapta o uso do file_picker 13 / device_info_plus 13; os arquivos do editor seguem MPL-2.0.
  Para atualizar: rebasear o branch no `main` oficial, rodar `flutter test` no fork, trocar o commit aqui.
- Plugins Android antigos compilam com `compileSdk 37` forçado em `android/build.gradle.kts`.
- Fonte da verdade da página: JSON do editor (`contentFromDocument`/`documentFromContent`).
  Markdown só em `book_markdown.dart`; exportar **sempre** com `lineBreak: '\n'` (sem linha em branco,
  dois parágrafos voltam como um).
- Zip do book: um `.md` por página, nome `01.02 - Título.md` (posição na árvore), que a importação
  usa para refazer a hierarquia.
- Editor salva com `DebouncedSaver` (800 ms) e no `dispose`; grava só título e conteúdo
  (`savePageContent`). Ao tocar no menu o editor perde a seleção: o último trecho fica guardado.
- Testes com o editor: `pumpApp` simula o canal `keyboardHeightEventChannel`; pegar o `EditorState`
  com `tester.widget<AppFlowyEditor>(...).editorState` e aplicar transações.

## Agenda (calendário)

- Linha do tempo própria (`Stack` + `Positioned`), sem pacote de calendário: `calendar_view` não arrasta
  blocos e `kalender` (0.x) traz controlador e layout próprios.
- Dados: `watchTasksInRange(from, to)` (o que toca o intervalo + todas as rotinas com prazo antes de `to`)
  e `expandOccurrences` (`features/calendar/calendar_entries.dart`, puro): o prazo atual da rotina é a
  ocorrência real, as seguintes são virtuais e o histórico (`TaskCompletions`) vira ocorrências feitas.
- Bloco de tarefa com hora: `startAt..dueAt`; só um dos dois (ou iguais) = 30 min. Dia inteiro vai na faixa
  de cima. Sobreposição em colunas por `layoutOverlaps` (`core/calendar_layout.dart`).
- Arrastar (toque longo) chama `moveEntry`/`resizeEntry` e grava por `TasksRepository.rescheduleTask`
  (só início, prazo e `hasTime`). Rotina: mover qualquer ocorrência move a série. Os 16 dp de baixo do
  bloco redimensionam. Toque longo no vazio abre `Routes.newTask(at:)` arredondado em 15 min.
- Ajustes com prefixo `calendar.` (`CalendarSettings`: modo e camada de pomodoros). Zoom (pinça) fica só
  em memória (`hourHeightProvider`). Semana mostra 3 dias abaixo de 600 dp.

## Métricas

- Agregações puras em `features/stats/stats_logic.dart` (foco por dia/semana/mês, por tarefa/tag/tipo,
  estimado × realizado somando subtarefas, revisões por dia, acerto, previsão de vencidos, sequência,
  heatmap de rotinas), com testes. Foco conta só sessões `foco`, pelo início, sem as pausas (`elapsed`).
- Gráficos com `fl_chart` (`_Bars` em `stats_page.dart`). Nos testes há duas áreas roláveis (o heatmap
  rola de lado): use `scrollable: find.byType(Scrollable).first`.

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
- O relógio vem de `clockProvider` (`lib/app/clock.dart`); `pumpApp` fixa ao meio-dia do "hoje" do
  teste, ou usa o `clock:` passado. Para trocar outros providers no teste, `overrides:`.

## Estilo

- Textos da UI em **português do Brasil**; nenhuma string em inglês.
- Sistema de design em `lib/app/theme/` (ver `docs/EVOLUCAO-VISUAL.md`): tokens `context.space`,
  `context.radius`, `context.motion` (já respeita "remover animações"), `context.palette` (12 cores por chave,
  tons `tint`/`strong`/`onTint` gerados em HCT, contraste testado) e `context.type` (seção, leitura, código,
  métrica, timer). Fontes empacotadas: Inter (interface), Literata (leitura), JetBrains Mono (código), OFL.
- Ícones só pelo `AppIcons` (`lib/app/theme/app_icons.dart`, Lucide traço 300; o 500 marca estado ativo).
  Mesma ação, mesmo ícone. Tamanhos em `AppIconSize` (16 meta, 20 padrão, 24 ação, 32 destaque).
- Temas dos componentes em `lib/app/theme/components.dart` (AppBar plana, campos preenchidos, botões, chips,
  diálogos, folhas com alça, SnackBar flutuante, transição fade + leve subida). Carregando = `SkeletonList`/
  `SkeletonPage`; `Pressable` (escala 0,98) e `StaggeredEntry` (cascata só na 1ª vez) em `shared/widgets/`.
  Catálogo em `/dev/componentes` (só debug, pelo menu). Componente que se repete vai para o catálogo.
- Nada de `Colors.*`, `Color(0x..)`, `Icons.*`, `fontSize:` ou duração literal fora do tema:
  `test/app/theme/visual_debt_test.dart` é uma catraca por arquivo (só pode baixar; arquivo novo começa em 0).
- Tema claro e escuro; testar em 360 dp de largura.
- Lints estritos em `analysis_options.yaml` (inclui `prefer_const_constructors`, `always_declare_return_types`,
  `avoid_dynamic_calls`, `require_trailing_commas`). Rodar `dart format` antes do commit.

## Regra do design

- **Toda tela nova usa os tokens, o `AppIcons`, a paleta e o catálogo; componente que falta entra no catálogo,
  nunca dentro da tela.** A catraca (`visual_debt_test.dart`) está zerada: qualquer valor visual solto falha.
- Goldens dos componentes em `test/golden/` (fontes reais via `test/helpers/golden_fonts.dart`).
  Atualizar com `flutter test --update-goldens test/golden` e conferir a imagem antes do commit.

## Ambiente

- Flutter 3.47 / Dart 3.13. `flutter_local_notifications` 23 exige `compileSdk = 37` e AGP ≥ 9.1.1.
- No Linux não dá para compilar iOS: a configuração iOS é feita seguindo o README dos plugins, mas sem build.
