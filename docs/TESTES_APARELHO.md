# Testes pendentes no aparelho

O que os testes automáticos (`flutter test`) **não** cobrem: comportamento real do Android/iOS
(alarmes do sistema, notificações, isolate de segundo plano, reboot). Rodar com o celular conectado
quando ele estiver disponível e marcar aqui o resultado.

Aparelho de referência: Galaxy S24 Ultra (SM-S928B), Android 16.

## Como preparar

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell date            # conferir a hora do celular antes de marcar alarmes
```

- Para "fechar o app" **sem apagar os alarmes**: botão Home e depois `adb shell am kill com.nextinfor.mycadence`
  (repetir até `adb shell pidof com.nextinfor.mycadence` não devolver nada). **Não** usar
  `am force-stop`: ele cancela todos os alarmes do app.
- Ver alarmes registrados: `adb shell dumpsys alarm | grep -A3 com.nextinfor.mycadence`
- Ver notificações na tela: `adb shell dumpsys notification --noredact | grep -A5 com.nextinfor.mycadence`
- Erros do app: `adb logcat -d --pid=$(adb shell pidof com.nextinfor.mycadence) | grep -iE "E/flutter|exception"`

## Já verificado

| Data | Etapa | O quê | Resultado |
|---|---|---|---|
| 23/11/2026 | 0 | App abre com as 5 abas, tema escuro, menu lateral | OK |
| 23/11/2026 | 2 | Criar tarefa pelo formulário, abrir hub, subtarefas inline | OK |
| 23/11/2026 | 3 | Permissão de notificação pedida ao salvar o 1º lembrete | OK |
| 23/11/2026 | 3 | Alarme exato registrado no Android (`RTC_WAKEUP`, `exactAllowReason=policy_permission`) e mantido após matar o processo | OK |
| 23/11/2026 | 3 | Alarme disparou com o app fechado, como notificação (verificado manualmente) | OK |

Achado no aparelho e já corrigido: ao fechar o seletor de data/hora, o foco voltava ao título e o
teclado cobria o formulário (corrigido, com teste de regressão).

## Bugs achados no aparelho (23/11) e corrigidos

Todos com teste automatizado de regressão, conferido falhando sem a correção.

1. **Revisão duplicada de cards:** depois de responder, o mesmo card voltava à tela (cópia
   desatualizada da consulta + a regra do "desfazer" prendendo o card) e era revisado de novo com
   dados velhos. Corrigido com `pickCurrentCard` (`review_queue.dart`).
2. **Intervalo do botão "envelhecia":** "Bom" mostrava "9 min" em vez de "10 min" porque o intervalo
   era medido contra o relógio que segue andando. Agora é medido a partir do instante da prévia.
3. **Abrir pela notificação deixava a tela como raiz:** sem abas e sem "voltar", e às vezes empilhada
   duas vezes. Agora `NotificationNavigator` espera o roteador ficar pronto e ignora repetições.
4. **Pausa começava sozinha ao reabrir o app muito depois** do fim do foco. Agora só começa se o fim
   foi percebido na hora (até 1 min).
5. **Cartão "Foco concluído" oferecia "Iniciar pausa curta" com a pausa já rodando** (iniciaria outra).
6. **Leitor de tela anunciava "Excluir" no chip de status** do hub (era o `deleteIcon` do Chip).
7. **Ícone de repetição duplicado** em rotinas na lista.
8. **Pomodoro sem entrada própria:** só abria pelo hub; agora está no menu lateral.
9. **Pomodoro aberto pela notificação esquecia a tarefa** da sessão que acabou (o próximo foco ia sem
   tarefa).

## Pendentes: Etapa 3 (recorrência e alarmes)

Preparação: criar pela aba Hoje uma rotina com **Dia inteiro desligado**, prazo hoje com hora
= agora + 3 min, **Repetir: Diária** e **Alarme: Na hora**. Fechar o app como descrito acima.

- [x] **3.1 Alarme com o app fechado.** (23/11/2026: disparou como notificação.) No horário, a notificação "Teste alarme / Prazo: Hoje, HH:MM"
  aparece com os botões **Concluir** e **Adiar 10 min**, com o processo do app morto.
- [x] **3.2  (23/11: ação "Concluir" com o app fechado avançou a rotina e gravou o histórico.)3.2 Concluir pela notificação (app fechado).** Tocar em **Concluir**: a notificação some; ao abrir o
  app, a rotina está com prazo **amanhã** no mesmo horário, o histórico do hub mostra 1 conclusão e
  `dumpsys alarm` mostra o próximo alarme para amanhã.
- [x] **3.3  (23/11: rotina avançou, histórico gravado, próximo alarme agendado; tela atualizada ao voltar; sem `database is locked`.)3.3 Concluir pela notificação (app aberto em segundo plano).** Repetir 3.2 com o app aberto e
  minimizado. Ao voltar ao app, a lista já mostra a rotina avançada, sem precisar reiniciar
  (confirma o "recarregar ao voltar" e/ou o banco compartilhado entre isolates). Sem
  `database is locked` no logcat.
- [x] **3.4  (23/11: alarme reagendado +10 min, prazo intacto.)3.4 Adiar.** Tocar em **Adiar 10 min**: a notificação volta 10 min depois; a tarefa no app
  continua com o prazo original.
- [x] **3.5  (23/11: sobreviveu à volta ao app, à reabertura do zero e a uma reinstalação.)3.5 Adiar sobrevive à abertura do app.** Adiar, abrir o app antes dos 10 min, fechar: o
  lembrete adiado ainda dispara.
- [x] **3.6  (23/11: abre o hub sobre as abas. Antes da correção abria a tela como raiz, sem abas nem "voltar".)3.6 Toque na notificação com o app fechado.** Tocar no corpo da notificação: o app abre direto no
  hub da tarefa; o "voltar" leva para a aba Hoje.
- [x] **3.7  (23/11: hub empilhado sobre a tela atual; voltar retorna a ela.)3.7 Toque com o app aberto.** Mesmo teste com o app em primeiro plano/minimizado: abre o hub.
- [x] **3.8  (23/11: alarme mudou de 17:45 para 22:05 e depois para a data nova, sem sobrar o antigo.)3.8 Editar reagenda.** Mudar a hora do prazo de uma tarefa com alarme: `dumpsys alarm` mostra
  o novo horário (e não o antigo).
- [x] **3.9  (23/11: 2→1 ao concluir, 1→0 ao excluir, 0→1 com Desfazer.)3.9 Concluir/excluir cancela.** Concluir uma tarefa simples com alarme e excluir outra:
  nenhum alarme do app sobra para elas. Excluir e tocar em **Desfazer** recria o alarme.
- [ ] **3.10 Reboot.** (Precisa de você: depois do reinício o Android só entrega o `BOOT_COMPLETED`
  ao app quando o celular é desbloqueado com o PIN.) Com um alarme para daqui a ~5 min, reiniciar o celular **sem abrir o app**:
  o alarme dispara (receiver de boot do plugin). Depois, abrir o app não duplica a notificação.
- [x] **3.11  (23/11: tarefa salva, app sem erro; permissão devolvida com `pm grant`.)3.11 Permissão negada.** Em um aparelho/limpeza de dados com a permissão negada: o app não
  quebra ao salvar tarefa com alarme (só não notifica).
- [x] **3.12  (23/11: "Na hora" e "1 dia antes" agendados para 9h do dia certo.)3.12 Lembrete de dia inteiro.** Tarefa de dia inteiro com "Na hora" dispara às 9h do dia;
  com "1 dia antes", às 9h do dia anterior.
- [x] **3.13  (23/11: concluir na segunda levou prazo e alarme para quarta.)3.13 Rotina semanal.** Rotina seg/qua/sex com alarme: concluir na segunda leva o prazo e o
  alarme para quarta.

## Pendentes: Etapa 4 (hub da tarefa)

- [x] **4.1  (23/11: tema escuro e claro, fonte do sistema em 130%: sem cortes.)4.1 Visual em 360 dp e tema claro.** Abrir o hub de uma tarefa de **estudo** com subtarefas, cards,
  sessões e páginas: as quatro seções cabem sem cortes; os botões "Revisar desta tarefa" e "+ Card"
  quebram linha direito; conferir também com o celular em tema claro e com fonte grande do sistema.
- [x] **4.2  (23/11: atalho "Flashcard" sumiu e a seção apareceu ao criar o card.)4.2 Atalhos em tarefa simples.** Hub de tarefa simples mostra "Adicionar: Flashcard, Pomodoro,
  Página"; criar um card faz a seção Flashcards aparecer e o atalho sumir.
- [x] **4.3  (23/11: painel acima do teclado, "Salvar card" visível.)4.3 Painel de card com teclado.** No "+ Card", o painel sobe junto com o teclado e o botão
  "Salvar card" fica visível sem fechar o teclado.
- [x] **4.4  (23/11: página provisória abre e volta ao hub; revisão e pomodoro já são telas reais.)4.4 Telas provisórias.** "Revisar desta tarefa", "Iniciar foco" e tocar numa página abrem as telas
  "em construção" e o voltar retorna ao hub.

## Pendentes: Etapa 5 (pomodoro)

Critério de pronto da etapa: **fechar e reabrir o app no meio de um foco mantém o tempo certo e a
notificação chega.** Para testar rápido, em Ajustes deixar Foco = 1 min e Pausa curta = 1 min.

- [x] **5.1  (23/11: mostrava 01:28 às 22:01:24 com fim 22:02:52.)5.1 Fechar no meio do foco.** Iniciar um foco de 2 min, anotar o tempo restante, fechar o app
  (Home + `am kill`), esperar 30 s e reabrir: o relógio mostra ~30 s a menos que o anotado (não
  recomeça, não congela). `dumpsys alarm` mostra o alarme do fim.
- [x] **5.2  (23/11: chegou no segundo exato; o toque abre o pomodoro com o cartão.)5.2 Notificação do fim com o app fechado.** Iniciar foco de 1 min e fechar o app: chega
  "Foco concluído / Hora de uma pausa." com som e vibração. Tocar abre a tela do pomodoro com o
  cartão "Foco concluído!" e "Próximo: Pausa curta".
- [x] **5.3  (23/11: sessão fechada no horário do fim; hub com 2 min de foco, não o tempo até reabrir.)5.3 Reabrir depois do fim sem tocar na notificação.** A sessão aparece como concluída (cartão
  e mini-player "Foco concluído"), e o tempo de foco no hub da tarefa é o planejado, não o tempo
  até reabrir.
- [x] **5.4  (23/11: pausa cancelou o alarme; retomar empurrou o fim em 54 s, o tempo pausado.)5.4 Pausar e retomar.** Pausar cancela o alarme (`dumpsys alarm` sem o do app); retomar
  agenda de novo, empurrado pelo tempo pausado.
- [x] **5.5  (23/11: tempo anda a cada segundo; pausar/retomar pelo mini-player.)5.5 Mini-player.** Com sessão rodando, a faixa aparece acima das abas em todas as abas, o tempo
  anda a cada segundo, o botão pausa/retoma e o toque abre a tela.
- [x] **5.6  (23/11: `mHoldScreenWindow` = app durante o foco; liberado na pausa.)5.6 Manter a tela ligada.** Com o ajuste ligado e um foco rodando, a tela do pomodoro não apaga
  sozinha; ao sair da tela ou pausar, volta a apagar normalmente.
- [x] **5.7  (23/11: canal `pomodoro_mv` com `mSound=null`.)5.7 Som e vibração.** Desligar "Som ao terminar" e confirmar que o próximo aviso vem sem som
  (canal "Pomodoro (sem som)"); idem para vibração.
- [x] **5.8  (23/11: pausa começou sozinha e avisou no fim.)5.8 Iniciar pausas sozinho.** Com o ajuste ligado, ao fim do foco a pausa começa sozinha e
  chega outra notificação no fim da pausa.
- [x] **5.9  (23/11: tarefa concluída pelo cartão.)5.9 Concluir tarefa ao fim do foco.** No cartão "Foco concluído!", "Concluir \"…\"" conclui a
  tarefa (rotina avança).
- [x] **5.10  (23/11: aviso mantido após reabrir do zero.)5.10 Notificação de pomodoro não some ao abrir o app.** Com um foco rodando e o app fechado,
  abrir o app (que reagenda os lembretes de tarefas): o aviso do fim continua agendado.

## Pendentes: Etapa 6 (flashcards FSRS)

- [x] **6.1  (23/11: troca de card abaixo de ~0,2 s; botões cabem em 360 dp e com fonte 130%.)6.1 Revisão fluida.** Com uns 20 cards, revisar em sequência: "Mostrar resposta" e os 4 botões
  respondem sem atraso perceptível; os botões cabem em 360 dp com os intervalos ("1 min", "10 min",
  "4 d"…) legíveis, em tema claro e escuro.
- [x] **6.2  (23/11: "Próximo card em 1 min" e o card voltou sozinho.)6.2 Passos de aprendizado.** Card novo → Errei: aparece "Próximo card em 1 min" e, passado 1 min
  com a tela aberta, o card volta sozinho.
- [x] **6.3  (23/11: badge 20 = "20 para revisar agora".)6.3 Badge.** O número na aba Revisar bate com "N para revisar agora" e atualiza ao revisar.
- [x] **6.4  (23/11: 20 cards de um CSV com BOM, CRLF, aspas, `;` e quebra de linha na célula, pelo seletor do sistema.)6.4 Importar CSV.** Importar um `.csv` real (salvo no Excel/Google Sheets como CSV com `;`,
  incluindo acentos, aspas e uma célula com quebra de linha): os cards entram certos no deck escolhido.
  Conferir também um arquivo `.txt`.
- [x] **6.5  (23/11: negrito e código renderizados.)6.5 Markdown no card.** Card com `**negrito**`, `*itálico*`, `` `código` `` e lista `- item` aparece
  formatado na revisão.
- [x] **6.6  (23/11: só os cards da tarefa.)6.6 Revisar desta tarefa.** No hub de uma tarefa com cards (inclusive de subtarefas), "Revisar desta
  tarefa" revisa só esses.
- [x] **6.7  (23/11: deck e tarefa no painel; tarefa já preenchida vindo do hub.)6.7 Painel do card com teclado.** Criar e editar card: o painel sobe com o teclado; deck e
  tarefa vinculada podem ser trocados.

## Pendentes: Etapa 7 (books com AppFlowy)

Editor vem do fork `edenilsonmota/appflowy-editor` (branch `cadence/file-picker-13`), fixado no commit
`82d3c27`. O APK compila; falta ver o editor no aparelho (o celular estava em uso).

- [ ] **7.1 Editar no celular.** Novo book → Nova página: o editor abre em modo edição com o teclado;
  a barra móvel (estilos, cores, blocos, link, divisor) aparece acima do teclado e funciona; títulos,
  listas e citação ficam certos no tema escuro e no claro (texto legível nos dois).
- [ ] **7.2 Seleção.** Selecionar um trecho mostra a barra flutuante com Copiar, Recortar, Colar e
  "Criar flashcard"; "Criar flashcard" abre o painel com o trecho na frente ou no verso.
- [ ] **7.3 Salvamento.** Escrever, esperar 1 s e matar o app (`am kill`): ao reabrir, o texto está lá.
  Escrever e sair logo pelo "voltar": também salvo.
- [ ] **7.4 Modo leitura.** O olho alterna para leitura: sem teclado, sem barras; o lápis volta a editar.
- [ ] **7.5 Exportar.** Exportar página (.md) e book (.zip) abre o "Salvar como" do sistema e o arquivo
  abre certo em outro app (ex.: um leitor de Markdown).
- [ ] **7.6 Importar.** Importar na aba Books o zip exportado (e também arquivos .md soltos de outra
  origem): mesma árvore e conteúdo.
- [ ] **7.7 Livro longo.** Página com umas 300 linhas: rolar e digitar continuam fluidos.

## Pendentes: logo do app

- [ ] **L.1 Ícone.** Na tela inicial e na gaveta de apps aparece o anel com check em fundo verde-azulado
  (sem o logo do Flutter), recortado certo no formato do launcher. Com "ícones temáticos" do Android 13+
  ligado, o ícone segue as cores do sistema.
- [ ] **L.2 Notificação.** Lembrete de tarefa e fim de pomodoro mostram o símbolo branco na barra de
  status (não um quadrado cinza) e o símbolo em verde-azulado na notificação aberta.
- [ ] **L.3 Splash e menu.** Ao abrir (Android 12+), o splash mostra o novo ícone; o menu lateral mostra o
  logo ao lado de "My Cadence".

## Limitações conhecidas (não são bugs)

- iOS: configuração feita, mas nada foi compilado nem testado (o ambiente é Linux).
- A hora do lembrete de tarefas de dia inteiro (9h) ainda é fixa (a tela de Ajustes já existe; falta
  esse item).
- Importação de `.apkg` (Anki) não foi feita: o formato atual do Anki guarda a coleção num SQLite
  comprimido com zstd dentro de um zip; ficou fora do escopo (o plano marcava como opcional).
