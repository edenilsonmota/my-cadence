# Plano do projeto: My Cadence (Flutter, offline-first)

**My Cadence** é um app pessoal, com repositório público, que junta **gerenciador de tarefas**, **flashcards estilo Anki (FSRS)**, **pomodoro**,
**books em Markdown estilo Notion (AppFlowy Editor)** e **calendário**. Primeiro 100% mobile e local;
a sincronização com backend Go vem por último.

> **Como trabalhar com este plano (para o Claude Code)**
> - Execute **uma etapa por vez**, na ordem. Ao terminar uma etapa: rode `dart run build_runner build -d`
>   (se mexeu em tabelas ou providers), `flutter analyze` e `flutter test`, corrija tudo, faça commit
>   e **pare** para eu revisar antes da próxima.
> - **Cada pacote entra só na etapa que o usa** (nada de instalar tudo na Etapa 0).
> - Antes de adicionar qualquer pacote, confira no pub.dev a versão estável atual e a compatibilidade
>   com o Flutter instalado. Não invente APIs: leia a documentação ou o código-fonte do pacote.
> - Na dúvida entre algo simples e algo "arquiteturalmente bonito", escolha o simples.
> - Se alguma decisão deste plano se mostrar ruim na prática, pare e explique antes de mudar.

---

## 1. O fluxo central (o que dá sentido ao app)

1. Crio uma **tarefa** (ou subtarefa) e separo por **tags** (o "tipo" saiu na Etapa 16).
2. A tela da tarefa vira um **hub** com ferramentas que posso ligar:
   - **Flashcards** da tarefa (criar e revisar só os dela);
   - **Pomodoro** vinculado (métricas e tempo gasto, somando as subtarefas);
   - **Páginas**: um caderno próprio da tarefa com uma ou mais páginas, e/ou links para páginas de books existentes.
3. Tarefas do tipo **estudo** já abrem com as três ferramentas visíveis; nos outros tipos elas
   aparecem como atalhos ("+ Flashcard", "+ Pomodoro", "+ Página") e a seção só surge quando tem conteúdo.
4. Tudo aparece também no **calendário** (dia, semana e mês) e nas **métricas**.

---

## 2. Stack e decisões de arquitetura

| Tema | Escolha | Motivo |
|---|---|---|
| Banco local | **drift** + `drift_flutter` (SQLite) | Tipado, queries reativas (`watch`), migrações testáveis |
| Estado | **Riverpod** (`flutter_riverpod` + `riverpod_annotation`/`riverpod_generator`) | Padrão do ecossistema, testável, sem boilerplate de BLoC |
| Navegação | **go_router** com `StatefulShellRoute` | Abas com pilha própria e deep links das notificações |
| Editor | **appflowy_editor** (`MobileToolbarV2` + `MobileFloatingToolbar`), decidido na Etapa 7 | Editor de blocos estilo Notion, nativo em Flutter. A versão 6.2.0 do pub.dev não compila no Flutter 3.44+; ver Etapa 7 |
| Repetição espaçada | **fsrs** (Dart) | Mesmo algoritmo do Anki moderno |
| Alarmes | **flutter_local_notifications** + `timezone` + `flutter_timezone` | Locais, offline, funcionam com o app fechado |
| IDs | **uuid** v7 | Gerados no celular, sem colisão no sync, ordenáveis por tempo |
| Datas | `intl` (pt_BR) | |
| Arquivos | `file_picker` + `share_plus` | Importar e exportar `.md` e backups |
| Pomodoro | `wakelock_plus` (opcional, tela ligada durante o foco) | |

**Não usar:** Syncfusion (licença), Hive/Isar (já temos drift), GetX.

### Estrutura de pastas (feature-first, sem camadas a mais)

```
lib/
  main.dart                 # init: notificações, timezone, ProviderScope
  app/                      # MaterialApp.router, tema, rotas (go_router), shell das abas
  core/                     # utilitários puros: ids, datas, recurrence, notifications, format
  data/
    db/                     # AppDatabase, tables/, daos/, migrations/
    repositories/           # um por domínio; a UI nunca fala com o DAO direto
  features/
    tasks/                  # lista Hoje, lista Tarefas, formulário, hub da tarefa
    calendar/
    pomodoro/
    cards/                  # decks, CRUD, revisão
    books/                  # cadernos, páginas, editor
    stats/
    settings/
    sync/                   # (última etapa)
  shared/widgets/           # componentes reutilizáveis
test/                       # espelha lib/
```

Regras:
- **UI → provider → repository → DAO.** Widgets só leem providers.
- Lógica pura (recorrência, expansão de ocorrências, layout do calendário, ponte FSRS, agregações de métricas)
  fica em funções/classes **sem Flutter**, com testes unitários.
- Enums guardados como **`textEnum`** (o nome do valor), legível no banco e no backend Go, sem armadilha de ordem.
  Renomear um valor de enum exige migração.
- Textos da UI em português do Brasil. Tema claro e escuro (Material 3, `colorSchemeSeed`).

### Colunas de sincronização (em TODAS as tabelas desde o início)

```dart
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(newId)();          // UUID v7
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();     // soft delete (tombstone)
  BoolColumn get dirty => boolean().withDefault(const Constant(true))(); // mudou e não subiu
  IntColumn get serverVersion => integer().nullable()();       // versão recebida do servidor
  @override Set<Column> get primaryKey => {id};
}
```
Toda escrita atualiza `updatedAt` e marca `dirty = true` (centralizar isso num helper dos repositórios).
Nenhuma exclusão física: sempre `deletedAt`.

---

## 3. Modelo de dados

```
Tasks ─┬─< Tasks (subtarefas, parentId)
       ├─< TaskCompletions (histórico de rotinas)
       ├─< TaskTags >── Tags
       ├─< PomodoroSessions
       ├─< Flashcards ──< ReviewLogs
       ├─< Notebooks (caderno próprio da tarefa, taskId)
       └─< TaskPageLinks >── NotePages (link para páginas de outros books)

Decks ──< Flashcards
Notebooks ──< NotePages (parentPageId para subpáginas)
AppSettings (chave/valor)
```

**Tasks**: `parentId?`, `title`, `notes?`, `kind` (simples, estudo, rotina, evento), `status` (aFazer, fazendo, feita),
`priority` (0..3), `startAt?`, `dueAt?`, `hasTime` (false = dia inteiro), `recurrenceRule?` (RRULE),
`reminderMinutesBefore?`, `estimatedPomodoros?`, `sortOrder`, `completedAt?`, `color?`.

**TaskCompletions**: `taskId`, `occurrence` (data da ocorrência concluída).

**Tags**: `name`, `color`. **TaskTags**: `taskId`, `tagId`.

**PomodoroSessions**: `taskId?`, `kind` (foco, pausaCurta, pausaLonga), `startedAt`, `endedAt?`, `plannedMinutes`,
`pausedAt?`, `pausedTotalMs` (padrão 0), `completed` (chegou ao fim ou foi interrompida), `manual` (v7: tempo
registrado à mão, sem cronômetro).

**Decks**: `name`, `description?`. **Flashcards**: `deckId?`, `taskId?`, `sourcePageId?` (card criado de uma página),
`front`, `back`, estado FSRS (`state`, `step?`, `stability?`, `difficulty?`, `due`, `lastReview?`), `suspended`.
**ReviewLogs**: `cardId`, `rating` (1..4), `reviewedAt`, `durationMs?`.

**Notebooks**: `title`, `taskId?` (preenchido = caderno da tarefa), `icon?`.
**NotePages**: `notebookId`, `parentPageId?`, `title`, `content` (JSON do AppFlowy), `sortOrder`.
**TaskPageLinks**: `taskId`, `pageId`.
**TaskNotebookLinks** (v6): `taskId`, `notebookId` — book inteiro vinculado à tarefa.
**TaskDeckLinks** (v6): `taskId`, `deckId` — deck vinculado à tarefa (hub e métricas).

**AppSettings**: `key`, `value` (durações do pomodoro, retenção desejada, limite de cards novos/dia,
alarme padrão, modo do calendário etc.).

Índices: `Tasks(parentId)`, `Tasks(dueAt)`, `Flashcards(due)`, `Flashcards(taskId)`, `PomodoroSessions(taskId, startedAt)`,
`NotePages(notebookId, sortOrder)`.

### Decisões importantes
- **Fonte da verdade das páginas = JSON do AppFlowy** (sem perdas). Markdown é formato de
  **importação e exportação** (`markdownToDocument` / `documentToMarkdown`).
- **Recorrência** guardada em **RRULE** (subconjunto: `FREQ=DAILY|WEEKLY`, `INTERVAL`, `BYDAY`, `UNTIL`),
  implementada em `core/recurrence.dart` com `parse`, `toRule`, `next(from)` e `describe()` em português.
  Assim o backend Go pode ler com `rrule-go` depois.
- **Tarefa recorrente = uma linha só.** Ao concluir: grava `TaskCompletions`, avança `dueAt`/`startAt` para a próxima
  ocorrência (pulando as que ficaram no passado), reabre as subtarefas (checklist da rotina) e reagenda o alarme.
  Passou do `UNTIL`: marca como feita.
- **No calendário**, ocorrências futuras de rotinas são **virtuais** (calculadas, não gravadas).
- **FSRS trabalha em UTC**: converter na ponte (`toUtc()` ao montar o `fsrs.Card`, `toLocal()` ao salvar).
  Importar o pacote com prefixo (`import 'package:fsrs/fsrs.dart' as fsrs;`), porque `Card` e `State` colidem com o Flutter.
- **Pomodoro** nunca conta com `Timer` acumulando segundos. `PomodoroSessions` tem também `pausedAt?` e
  `pausedTotalMs` (padrão 0). Tempo decorrido = `(pausedAt ?? agora) - startedAt - pausedTotalMs`;
  restante = `plannedMinutes - decorrido`. Pausar grava `pausedAt` e **cancela** a notificação de fim;
  retomar soma `agora - pausedAt` em `pausedTotalMs`, limpa `pausedAt` e **reagenda** a notificação. A sessão em andamento fica no banco (`endedAt == null`), então matar o app
  não perde nada. O fim do ciclo é uma **notificação agendada**.
- **Alarmes**: id da notificação derivado do UUID com hash explícito e estável entre execuções
  (FNV-1a reduzido a 31 bits). **Nunca** usar `String.hashCode`, que muda entre execuções. Todo create/update/complete/delete de tarefa
  reagenda ou cancela. Na inicialização do app, reagendar tudo (alarmes se perdem após reboot em alguns aparelhos).

---

## 4. Etapas

### Etapa 0: Fundação
- **Identidade do projeto:**
  - repositório e pasta: `my-cadence`; pacote Dart: `my_cadence`;
  - criar com `flutter create --org com.nextinfor --project-name my_cadence --platforms android,ios .`
    e depois ajustar o ID para **`com.nextinfor.mycadence` nos dois sistemas** (`applicationId`/`namespace` no Gradle,
    `PRODUCT_BUNDLE_IDENTIFIER` no Xcode), porque o iOS não aceita `_`;
  - nome exibido no ícone do celular: **Cadence** (`android:label` no `AndroidManifest.xml` e
    `CFBundleDisplayName` no `Info.plist`); título interno do app e README: **My Cadence**.
- **Repositório público:** licença **MIT** (arquivo `LICENSE`), `.gitignore` cobrindo keystore e segredos
  (`*.jks`, `*.keystore`, `android/key.properties`, `.env*`, `google-services.json`, `GoogleService-Info.plist`),
  e `README.md` com descrição, stack, como rodar e uma seção de screenshots que será atualizada a cada etapa.
- `analysis_options` com `flutter_lints` mais regras estritas
  (`prefer_const_constructors`, `always_declare_return_types`, `avoid_dynamic_calls`).
- Estrutura de pastas da seção 2, `go_router` com shell de 5 abas: **Hoje, Tarefas, Agenda, Revisar, Books**
  (métricas e ajustes ficam num menu ou drawer).
- Tema M3 claro/escuro, localização pt_BR (`flutter_localizations`). O delegate do AppFlowy entra na Etapa 7.
- Configuração Android das notificações: core library desugaring no Gradle, permissões
  `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`,
  receivers do plugin no `AndroidManifest`. Configuração iOS do plugin. Siga o README da versão instalada.
- Criar `CLAUDE.md` na raiz com as convenções deste plano.
- **Pronto quando:** app abre com as 5 abas vazias, analyze e test limpos.

### Etapa 1: Camada de dados
- Todas as tabelas da seção 3 com o mixin `SyncColumns`, DAOs por domínio e repositórios.
- Helper que aplica `updatedAt = now` e `dirty = true` em toda escrita; soft delete em cascata (tarefa → subtarefas).
- `PRAGMA foreign_keys = ON` no `beforeOpen`. Migrações versionadas com `drift_dev schema dump` e teste de migração.
- `core/recurrence.dart` completo, com testes (diário, intervalo, semanal com vários dias, semanal a cada 2 semanas,
  UNTIL, virada de mês/ano).
- Testes de DAO com banco em memória (`NativeDatabase.memory()`).
- **Pronto quando:** testes cobrem CRUD de cada domínio e a recorrência.

### Etapa 2: Tarefas
- **Hoje**: atrasadas (destaque), de hoje (com e sem hora) e "sem data" recolhível. Concluir com checkbox e animação.
- **Tarefas**: árvore (raiz + subtarefas expansíveis), filtros por tipo, tag, status e prioridade, busca por título, ordenação.
- **Formulário** (tela cheia): título, notas, tipo (SegmentedButton), prioridade, início e prazo (data, opcional hora,
  switch "dia inteiro"), recorrência (nenhuma, diária, semanal com chips de dias, a cada N, até data),
  alarme (nenhum, na hora, 5/10/15/30/60 min, 1 dia antes), pomodoros estimados, tags (chips + criar tag).
  Recorrência sem data define o prazo como hoje.
- Subtarefa rápida: campo de texto inline no hub; subtarefa abre o mesmo hub (pode ter cards, pomodoro e páginas).
- Arrastar para reordenar subtarefas; deslizar para concluir ou excluir (com desfazer no SnackBar).
- **Pronto quando:** consigo criar, editar, concluir, excluir e filtrar tarefas e subtarefas.

### Etapa 3: Recorrência e alarmes
- Concluir rotina conforme a seção 3. Histórico de conclusões visível no hub ("sequência" de dias seguidos).
- Serviço de notificações: agendar, cancelar, reagendar tudo no boot do app; tocar na notificação abre o hub da tarefa (deep link via go_router).
- Ações na notificação: "Concluir" e "Adiar 10 min".
- **Pronto quando:** alarme dispara com o app fechado e a rotina avança corretamente.

### Etapa 4: Hub da tarefa
- Cabeçalho: título, tipo, status, datas, recorrência descrita, tags, notas, botão concluir.
- Seções: **Subtarefas**, **Flashcards** (quantidade, vencidos, "Revisar desta tarefa", "+ Card"),
  **Pomodoro** (tempo total da tarefa + subtarefas, nº de sessões, estimado × realizado, "Iniciar foco"),
  **Páginas** (caderno da tarefa + páginas de books vinculadas; "+ Página", "Vincular página existente").
- Comportamento por tipo descrito na seção 1.
- **Pronto quando:** o hub mostra e cria tudo; as ações de cards, pomodoro e páginas podem abrir telas provisórias
  até as próximas etapas.

### Etapa 5: Pomodoro
- Tela com anel de progresso, tarefa vinculada (trocar tarefa), modos foco, pausa curta e pausa longa,
  iniciar, pausar, retomar, parar. Pausa longa a cada 4 focos (configurável).
- Retomar sessão em andamento ao abrir o app; notificação agendada para o fim; opção de manter a tela ligada.
- Mini-player persistente no shell quando há sessão rodando (tempo + tarefa, toque abre a tela).
- Ao terminar: sugerir o próximo ciclo e perguntar se conclui a tarefa.
- Ajustes: durações, auto-iniciar pausas, som/vibração.
- **Pronto quando:** fechar e reabrir o app no meio de um foco mantém o tempo certo e a notificação chega.

### Etapa 6: Flashcards (FSRS)
- Decks; cards com frente e verso (texto com Markdown simples renderizado), vínculo opcional a tarefa e deck; suspender.
- **Revisão**: fila de vencidos (geral, por deck ou por tarefa), mostrar resposta, 4 botões (Errei, Difícil, Bom, Fácil)
  exibindo o intervalo previsto de cada um, desfazer última avaliação, tempo de resposta registrado.
  Passos de aprendizado curtos (1 e 10 min): quando a fila esvaziar mas houver card vencendo em até 20 min, mostrar
  "Próximo card em X min".
- Limite diário de cards novos e retenção desejada nos ajustes.
- Badge na aba Revisar com o número de vencidos.
- Importação de CSV (frente;verso) e, se viável, de `.apkg` simples (avaliar; não é obrigatório).
- **Pronto quando:** a revisão funciona fluida e os intervalos batem com o FSRS.

### Etapa 7: Books (AppFlowy)
- **Primeiro, resolver a dependência do editor** (a 6.2.0 do pub.dev não implementa `TextInputClient.onFocusReceived`,
  obrigatório desde o Flutter 3.44, e prende `file_picker ^10`/`device_info_plus ^11`, conflitando com o `win32` 6).
  Ordem de preferência:
  1. dependência git do **repositório oficial** `AppFlowy-IO/appflowy-editor`, fixada num commit do `main` que já tem
     o `onFocusReceived`, com `dependency_overrides` só no que for preciso para o `win32` 6;
  2. se isso não bastar, **fork na minha conta do GitHub** (eu crio), fixado num commit, com as correções mínimas.
     Arquivos modificados do editor seguem MPL-2.0;
  3. se o editor não ficar estável no mobile, trocar por `super_editor` e me apresentar o que se perde.
  Sempre declarar a versão mínima esperada para o resolvedor **falhar alto** em vez de cair numa versão antiga (ex.: 0.1.12).
  Mostrar o resultado (compila, roda no Android, o que foi sobrescrito) e esperar meu ok antes de seguir.
- Lista de books; cada book com páginas e subpáginas (árvore), reordenação, renomear, ícone.
- Editor: `AppFlowyEditor` com `MobileToolbarV2` e `MobileFloatingToolbar` (seguir o `example/lib/pages/mobile_editor.dart`
  do pacote), título editável, **autosave com debounce** (~800 ms) ouvindo `editorState.transactionStream`
  e salvando também ao sair da tela.
- Modo leitura (sem teclado) e modo edição.
- **Importar** `.md` (um arquivo vira página; vários arquivos ou pasta viram book) e **exportar** página ou book
  inteiro em `.md` (book = zip com um `.md` por página, mantendo a ordem no nome do arquivo).
- **Integração com cards**: selecionar texto no editor → "Criar flashcard" (seleção vira frente ou verso, guarda `sourcePageId`).
- Vincular página a tarefa e ver, na página, as tarefas vinculadas.
- **Pronto quando:** consigo escrever um book com várias páginas, exportar em Markdown e reimportar sem perder o essencial.

### Etapa 8: Agenda (calendário)
- Modos **Dia**, **Semana** (7 dias, ou 3 em tela estreita) e **Mês**, com o modo lembrado nos ajustes.
- **Dia/Semana**: cabeçalho com mês (dropdown de mês/ano), busca e botão "hoje"; faixa **dia inteiro** recolhível;
  linha do tempo com coluna de horas; blocos com fundo claro, barra vertical colorida à esquerda e título na cor da barra
  (cor = primeira tag, senão por tipo); tarefas sobrepostas lado a lado (algoritmo de colunas); concluídas esmaecidas e riscadas;
  ícone de repetição; **linha da hora atual** atualizada a cada minuto; rolagem inicial perto de agora;
  bottom sheet "Próxima tarefa em X min" + FAB.
- **Mês**: grade 7×N com até 3 chips por dia e "+N"; tocar abre o dia.
- Dados: `watchTasksInRange(from, to)` + função pura `expandOccurrences(tasks, from, to)` (ocorrências virtuais das rotinas),
  com testes, além de testes do layout de sobreposição.
- Interações: toque abre o hub; toque longo em horário vazio cria tarefa naquele horário (arredondado em 15 min);
  arrastar reagenda mantendo a duração; arrastar a borda muda a duração; pinça ajusta o zoom.
  Rotina: no MVP, reagendar afeta "todas".
- Camada opcional "Pomodoros realizados": sessões de foco como blocos hachurados estreitos ao lado das tarefas.
- Avaliar `calendar_view` e `kalender` (licenças MIT/BSD); se não entregarem esse visual sem gambiarra,
  implementar a linha do tempo com `Stack` + `Positioned`. Explique a escolha antes.
- **Pronto quando:** as três visões refletem o banco em tempo real e arrastar reagenda.

### Etapa 9: Métricas
- Tempo de foco por dia, semana e mês; por tarefa, tag e tipo; estimado × realizado.
- Revisões por dia, taxa de acerto, cards vencidos previstos para os próximos 7 dias, sequência de dias estudando.
- Conclusão de rotinas (heatmap estilo GitHub).
- Gráficos com `fl_chart`. Agregações em funções puras testadas.

### Etapa 10: Backup e polimento
- Exportar e importar **backup completo** (JSON de todas as tabelas, com versão do schema) via share/arquivo.
  Isso é a rede de segurança até existir sync.
- Estados vazios, onboarding curto, haptics, acessibilidade (tamanhos de fonte), performance (listas grandes, editor longo).
- Ícone e splash.

### Etapa 11: Sincronização via Google Drive + JSON manual
Especificação completa em **`docs/SINCRONIZACAO.md`** (seguir as fases da seção 9 de lá, uma por vez).
- **Sem backend próprio.** Os dados ficam num snapshot JSON compactado na `appDataFolder` do Google Drive da pessoa
  (escopo `drive.appdata`, não sensível, gratuito, usa o espaço da conta Google).
- Mesclagem linha a linha por `updatedAt` (vence o mais recente), com tombstones (`deletedAt`), desempate determinístico
  e aplicação em transação com chaves estrangeiras adiadas. Motor puro e testado.
- **Exportar/importar JSON** no mesmo formato, com prévia e opção mesclar (padrão) ou substituir (com backup automático antes).
- **Conta Google na interface**: avatar com a foto de perfil no cabeçalho, com o status do sync; bottom sheet com
  "Sincronizar agora", sincronização automática, trocar conta, desconectar e backup manual.
- Sincroniza ao abrir o app, ao voltar do segundo plano, após alterações (debounce) e manualmente; funciona offline e
  tenta de novo depois.
- A coluna `serverVersion` fica reservada, sem uso.

### Etapa 12: Barra de navegação ajustável
A barra de baixo deixa de ser fixa (Hoje, Tarefas, Agenda, Revisar, Books): cada pessoa escolhe quais telas ficam
nela e em que ordem.
- **Telas disponíveis:** Hoje, Tarefas, Agenda, Revisar, Books, **Pomodoro** e **Métricas**. Ajustes continua só no
  menu lateral.
- **De 3 a 6 abas** na barra (padrão 5; com 6 abas, ícones e rótulos ficam levemente compactos). O que não estiver na
  barra continua acessível pelo menu lateral, então nenhuma tela fica escondida.
- **Ajustes → Barra de navegação:** lista com um interruptor por tela e alça para arrastar a ordem, com prévia da barra;
  "Restaurar padrão". O interruptor de quem já está no limite (mínimo ou máximo) fica desabilitado com o motivo.
- Guardado como ajuste do aparelho (`device.navTabs`, lista de chaves em ordem; não sincroniza, porque celular e tablet
  podem querer barras diferentes). Chave desconhecida é ignorada; lista inválida volta ao padrão.
- Pomodoro e Métricas viram rotas de aba quando estão na barra (cada aba com a própria pilha, como hoje) e continuam
  abrindo por cima do shell quando não estão. Deep links de notificação (tarefa, pomodoro) funcionam nos dois casos.
- A aba inicial ao abrir o app é a primeira da barra. O selo de cards para revisar segue a aba Revisar onde ela estiver.
- Lógica pura e testada: validar e normalizar a lista (mínimo, máximo, duplicadas, chaves desconhecidas) e montar os
  itens do menu lateral com o que ficou fora da barra.

### Etapa 13: Notificações e alarmes completos
Base pronta (Etapa 3): alarme com o app fechado, "Concluir"/"Adiar 10 min" em segundo plano, deep link, reagendar
ao editar, rotinas e hora do lembrete de dia inteiro. Esta etapa transforma os lembretes na ferramenta principal de
organização. Fazer em fases, nesta ordem, cada uma com teste no aparelho:
1. **Modo alarme por tarefa.** No formulário, "Notificação" (atual) ou "Alarme". O alarme toca até a pessoa interagir:
   canal próprio com áudio de alarme (`AudioAttributesUsage.alarm`, toca no silencioso), som insistente,
   `category: alarm` e tela cheia (`fullScreenIntent`; no Android 14+ conferir se a permissão
   `USE_FULL_SCREEN_INTENT` precisa ser concedida e guiar até ela). Coluna nova (`textEnum`) com migração, teste e
   upgrader do snapshot.
2. **Diagnóstico em Ajustes.** Mostrar se as notificações estão desligadas, o canal silenciado, o alarme exato negado
   ou a otimização de bateria ligada ("apps em suspensão" da Samsung), cada um com botão que abre a tela do sistema.
   Avisar no formulário da tarefa quando o lembrete não vai tocar.
3. **Adiar com opções.** O Android aceita 3 ações: Concluir, "10 min" e "1 h". "Amanhã cedo" fica no hub da tarefa.
4. **Avisos diários opcionais**, com hora em Ajustes: "N cards para revisar" (não avisa com zero; abre Revisar) e
   resumo do dia (tarefas de hoje e atrasadas). Reagendados quando os dados mudam; cálculo puro e testado.
5. **Vários lembretes por tarefa** (ex.: 1 dia antes e na hora). Muda o esquema: propor antes o modelo (lista na
   coluna ou tabela própria) e o ID de notificação de cada lembrete (hoje é o FNV-1a do UUID da tarefa).
6. **Insistir se atrasar** (opcional por tarefa): repetir o aviso a cada X minutos até concluir, com um teto.

Pendentes de testes antigos, para conferir junto: alarme depois de reiniciar o celular (precisa desbloquear com o PIN),
lembrete no início de tarefa com início e prazo, e troca da hora do lembrete de dia inteiro.

### Etapa 14: Configurações adicionais(dentro de Ajustes)
1. Além de Português-BR adicionar opções de idioma: inglês, Espanhol
2. Adicionar opção de trocar manualmente o modo light e dark, além do modo automatico para seguir a configuração do celular
3. Opção de tema “lights out” (alto contraste)

### Etapa 15: Widgets de calendário na tela inicial (Android)
Três widgets nativos redimensionáveis na tela inicial (sem pacote externo: snapshot JSON leve gravado em
`SharedPreferences` via `MethodChannel` + `AppWidgetProvider`/`RemoteViews` em Kotlin), acompanhando o tema
escolhido (Claro, Escuro neutro, Lights out), a cor de destaque e o idioma (`pt`, `en`, `es`), com atualização
automática ao mudar tarefas/aparência e na virada da meia-noite. Fazer em fases:
1. **Feito.** **Base + Widget "Hoje" (`4 × 2`, redimensionável `2 × 2` a `5 × 5`).** Camada pura de snapshot (testada),
   ponte Android (`MethodChannel` + `SharedPreferences` + alarme de meia-noite), deep links (`cadence://today`,
   `cadence://task/<id>`, `cadence://new-task`, `cadence://agenda?date=...`) e widget **Hoje** com cabeçalho
   (data + contagem + botão `+`) e lista rolável de tarefas atrasadas e de hoje com barrinha colorida e horário.
2. **Widget "Semanal" (`4 × 3`, redimensionável `4 × 2` a `5 × 5`).** Grade de 7 dias da semana com o dia atual
   destacado na cor de destaque, tarefas coloridas por dia e toque abrindo o dia na Agenda.
3. **Widget "Mês" (`4 × 4`) — feito.** Grade 6 × 7 começando na segunda, com linhas, dia atual destacado na cor de
   destaque, até 3 chips por dia com o título da tarefa (cor da tarefa) e "+N", estilo agenda; toque abre o dia;
   navegação de mês (`‹ ›`) concluída na Etapa 16.7.
3b. **Widget "Mês + Hoje" (`4 × 5`) — feito.** A mesma grade (com pontinhos, por ser menor) e a lista de hoje embaixo.
4. **Concluir direto pelo widget *(opcional)*.** Ação rápida no widget **Hoje** para marcar tarefa concluída
   em segundo plano sem abrir o app.

### Etapa 16: Simplificar e completar o dia a dia
A 16.1 saiu sozinha (1.4.0); da 16.2 à 16.8 saíram juntas (1.5.0).
1. **Unificar os tipos de tarefa — feito (1.4.0).** Os tipos (simples, estudo, rotina, evento) só mudavam cor/ícone padrão, um
   filtro, um agrupamento das métricas e as ferramentas sempre visíveis no hub do estudo; uma "rotina" podia não
   repetir. Sai o tipo da interface (a coluna fica, sem uso): a repetição define o visual padrão (verde e ícone de
   repetição) e as tags fazem a separação. Migração v8 grava cor/ícone próprios só onde a aparência mudaria
   (`legacyKindFixes`). O esquema v8 já traz as colunas das fases seguintes (tempo estimado, modelos, pausada).
2. **Pausar e reagenda — feito (1.5.0).** Status "Pausada" (some do Hoje, dos atrasados, dos lembretes e dos widgets até ser
   retomada; aparece em Tarefas com selo). No hub, "Reagendar": hoje, amanhã, próxima semana ou escolher data,
   mantendo a hora e a distância do início.
3. **Tempo estimad — feito (1.5.0).** Estimativa em horas/minutos no lugar dos pomodoros estimados (convertidos × 25 min),
   comparada com o foco feito (pomodoros + tempo manual) no hub e nas métricas.
4. **Tags na adição rápid — feito (1.5.0).** `#tag` no texto vincula a tag (cria se não existir), sem diferenciar acentos e
   maiúsculas.
5. **Busca gera — feito (1.5.0).** Tarefas (título e notas), páginas dos books (título e texto) e cards (frente e verso).
6. **Revisão da seman — feito (1.5.0).** Concluídas, tempo por tag, rotinas cumpridas e o que ficou atrasado, com reagendar
   em um toque.
7. **Pendência — feito (1.5.0).** Navegação de mês (`‹ ›`) no widget "Mês"; concluir pelo widget "Hoje"; "Registrar tempo"
   também na tela do Pomodoro.
8. **Modelos de taref — feito (1.5.0).** Salvar uma tarefa como modelo (título, notas, tags, aparência, estimativa, lembretes,
   subtarefas, books e decks) e criar a partir dele.


### Etapa 17: Gerenciar tags (feito)
- Menu **Tags** (menu lateral): lista com cor e quantas tarefas usam cada uma; criar, **renomear**, trocar a cor,
  **ver tarefas** filtradas por aquela tag e **excluir**. Ao excluir, avisar quantas tarefas estão vinculadas
  ("Esta tag está em N tarefas; elas perdem a tag") antes de confirmar. Exclusão continua sendo `softDeleteTag`
  (tag → vínculos).

### Etapa 18: Qualidade de vida no dia a dia (feito)
- **TTS devagar e motores externos nos flashcards:** botão com ícone de tartaruga ao lado do alto-falante
  (frente e verso) para ouvir em ~60% da velocidade (`setSpeechRate`); seletor de motor TTS instalado no
  Android (Google, SherpaTTS, Vocalizer etc.) e voz específica por idioma, com botão de testar voz.
- **Rotinas não acumulativas (esquema v9):** opção por rotina *"Não acumular atrasos"* (ligada por padrão,
  documentada no "i" do formulário). Na virada do dia, ocorrências passadas não concluídas ganham status
  `naoConcluida` no histórico e a rotina avança sem poluir Atrasadas — refletindo no calendário (com toque para
  corrigir retroativamente), no hub da tarefa, nas métricas e na revisão da semana.
- **Editar e suspender card durante a revisão:** menu `⋮` no topo da sessão de revisão para corrigir ou suspender
  o card atual sem sair da fila (com desfazer ao suspender).
- **Busca e filtro dentro do deck:** busca por frente/verso e filtros rápidos (*Todos*, *Vencidos*, *Novos*,
  *Suspensos*).
- **Exportar deck em CSV (`frente;verso`):** copiar o texto pronto ou salvar em arquivo `.csv`.
- **Lixeira (menu lateral):** listar itens excluídos (tarefas, decks, cards, books, páginas e tags) e restaurar
  em um toque.

### Etapa 19: Próximas evoluções e arrumação de casa (a fazer)
- **Compartilhar de outros apps no Android (`ACTION_SEND`):** receber texto/link de outros apps (navegador,
  WhatsApp, leitor) para criar rapidamente uma **tarefa**, um **flashcard** ou uma **nota num book**.
- **Modo "Praticar livre / Invertido" nos flashcards:** revisar um deck sem alterar o agendamento FSRS (ex.:
  antes de uma aula/prova) e com opção de inverter *verso → frente* para idiomas.
- **Meta diária de foco (ou revisões):** meta configurável com progresso discreto em Hoje e nas Métricas.
- **Widget "Semanal" e de pomodoro *(opcional)*:** retomar a Etapa 15.2 caso faça falta além de Hoje, Mês e Mês + Hoje.
- **Arrumação de casa:** atualizar [README.md](../README.md) e `docs/screenshots/` com os recursos recentes
  (widgets, TTS, revisão semanal, modelos, tags, Lixeira, idiomas e Lights out) e conferir no celular as
  pendências de testes de alarme anotadas na Etapa 13 (após reboot, lembrete no início e hora de dia inteiro).

---

## 5. Definição de pronto (vale para todas as etapas)
- `flutter analyze` sem avisos; `flutter test` passando; lógica nova com teste.
- Nenhuma string de UI em inglês.
- Funciona em tema claro e escuro e em tela pequena (360 dp de largura).
- Commit por etapa com mensagem descritiva; resumo no final do que foi feito e do que ficou pendente.
- Repositório é público: nunca commitar chaves, keystores ou dados pessoais; atualizar o README quando a etapa
  mudar algo visível.
