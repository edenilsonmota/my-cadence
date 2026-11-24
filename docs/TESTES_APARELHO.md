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

## Pendentes: Etapa 3 (recorrência e alarmes)

Preparação: criar pela aba Hoje uma rotina com **Dia inteiro desligado**, prazo hoje com hora
= agora + 3 min, **Repetir: Diária** e **Alarme: Na hora**. Fechar o app como descrito acima.

- [x] **3.1 Alarme com o app fechado.** (23/11/2026: disparou como notificação.) No horário, a notificação "Teste alarme / Prazo: Hoje, HH:MM"
  aparece com os botões **Concluir** e **Adiar 10 min**, com o processo do app morto.
- [ ] **3.2 Concluir pela notificação (app fechado).** Tocar em **Concluir**: a notificação some; ao abrir o
  app, a rotina está com prazo **amanhã** no mesmo horário, o histórico do hub mostra 1 conclusão e
  `dumpsys alarm` mostra o próximo alarme para amanhã.
- [ ] **3.3 Concluir pela notificação (app aberto em segundo plano).** Repetir 3.2 com o app aberto e
  minimizado. Ao voltar ao app, a lista já mostra a rotina avançada, sem precisar reiniciar
  (confirma o "recarregar ao voltar" e/ou o banco compartilhado entre isolates). Sem
  `database is locked` no logcat.
- [ ] **3.4 Adiar.** Tocar em **Adiar 10 min**: a notificação volta 10 min depois; a tarefa no app
  continua com o prazo original.
- [ ] **3.5 Adiar sobrevive à abertura do app.** Adiar, abrir o app antes dos 10 min, fechar: o
  lembrete adiado ainda dispara.
- [ ] **3.6 Toque na notificação com o app fechado.** Tocar no corpo da notificação: o app abre direto no
  hub da tarefa; o "voltar" leva para a aba Hoje.
- [ ] **3.7 Toque com o app aberto.** Mesmo teste com o app em primeiro plano/minimizado: abre o hub.
- [ ] **3.8 Editar reagenda.** Mudar a hora do prazo de uma tarefa com alarme: `dumpsys alarm` mostra
  o novo horário (e não o antigo).
- [ ] **3.9 Concluir/excluir cancela.** Concluir uma tarefa simples com alarme e excluir outra:
  nenhum alarme do app sobra para elas. Excluir e tocar em **Desfazer** recria o alarme.
- [ ] **3.10 Reboot.** Com um alarme para daqui a ~5 min, reiniciar o celular **sem abrir o app**:
  o alarme dispara (receiver de boot do plugin). Depois, abrir o app não duplica a notificação.
- [ ] **3.11 Permissão negada.** Em um aparelho/limpeza de dados com a permissão negada: o app não
  quebra ao salvar tarefa com alarme (só não notifica).
- [ ] **3.12 Lembrete de dia inteiro.** Tarefa de dia inteiro com "Na hora" dispara às 9h do dia;
  com "1 dia antes", às 9h do dia anterior.
- [ ] **3.13 Rotina semanal.** Rotina seg/qua/sex com alarme: concluir na segunda leva o prazo e o
  alarme para quarta.

## Pendentes: Etapa 4 (hub da tarefa)

- [ ] **4.1 Visual em 360 dp e tema claro.** Abrir o hub de uma tarefa de **estudo** com subtarefas, cards,
  sessões e páginas: as quatro seções cabem sem cortes; os botões "Revisar desta tarefa" e "+ Card"
  quebram linha direito; conferir também com o celular em tema claro e com fonte grande do sistema.
- [ ] **4.2 Atalhos em tarefa simples.** Hub de tarefa simples mostra "Adicionar: Flashcard, Pomodoro,
  Página"; criar um card faz a seção Flashcards aparecer e o atalho sumir.
- [ ] **4.3 Painel de card com teclado.** No "+ Card", o painel sobe junto com o teclado e o botão
  "Salvar card" fica visível sem fechar o teclado.
- [ ] **4.4 Telas provisórias.** "Revisar desta tarefa", "Iniciar foco" e tocar numa página abrem as telas
  "em construção" e o voltar retorna ao hub.

## Pendentes: Etapa 5 (pomodoro)

Critério de pronto da etapa: **fechar e reabrir o app no meio de um foco mantém o tempo certo e a
notificação chega.** Para testar rápido, em Ajustes deixar Foco = 1 min e Pausa curta = 1 min.

- [ ] **5.1 Fechar no meio do foco.** Iniciar um foco de 2 min, anotar o tempo restante, fechar o app
  (Home + `am kill`), esperar 30 s e reabrir: o relógio mostra ~30 s a menos que o anotado (não
  recomeça, não congela). `dumpsys alarm` mostra o alarme do fim.
- [ ] **5.2 Notificação do fim com o app fechado.** Iniciar foco de 1 min e fechar o app: chega
  "Foco concluído / Hora de uma pausa." com som e vibração. Tocar abre a tela do pomodoro com o
  cartão "Foco concluído!" e "Próximo: Pausa curta".
- [ ] **5.3 Reabrir depois do fim sem tocar na notificação.** A sessão aparece como concluída (cartão
  e mini-player "Foco concluído"), e o tempo de foco no hub da tarefa é o planejado, não o tempo
  até reabrir.
- [ ] **5.4 Pausar e retomar.** Pausar cancela o alarme (`dumpsys alarm` sem o do app); retomar
  agenda de novo, empurrado pelo tempo pausado.
- [ ] **5.5 Mini-player.** Com sessão rodando, a faixa aparece acima das abas em todas as abas, o tempo
  anda a cada segundo, o botão pausa/retoma e o toque abre a tela.
- [ ] **5.6 Manter a tela ligada.** Com o ajuste ligado e um foco rodando, a tela do pomodoro não apaga
  sozinha; ao sair da tela ou pausar, volta a apagar normalmente.
- [ ] **5.7 Som e vibração.** Desligar "Som ao terminar" e confirmar que o próximo aviso vem sem som
  (canal "Pomodoro (sem som)"); idem para vibração.
- [ ] **5.8 Iniciar pausas sozinho.** Com o ajuste ligado, ao fim do foco a pausa começa sozinha e
  chega outra notificação no fim da pausa.
- [ ] **5.9 Concluir tarefa ao fim do foco.** No cartão "Foco concluído!", "Concluir \"…\"" conclui a
  tarefa (rotina avança).
- [ ] **5.10 Notificação de pomodoro não some ao abrir o app.** Com um foco rodando e o app fechado,
  abrir o app (que reagenda os lembretes de tarefas): o aviso do fim continua agendado.

## Pendentes: Etapa 6 (flashcards FSRS)

- [ ] **6.1 Revisão fluida.** Com uns 20 cards, revisar em sequência: "Mostrar resposta" e os 4 botões
  respondem sem atraso perceptível; os botões cabem em 360 dp com os intervalos ("1 min", "10 min",
  "4 d"…) legíveis, em tema claro e escuro.
- [ ] **6.2 Passos de aprendizado.** Card novo → Errei: aparece "Próximo card em 1 min" e, passado 1 min
  com a tela aberta, o card volta sozinho.
- [ ] **6.3 Badge.** O número na aba Revisar bate com "N para revisar agora" e atualiza ao revisar.
- [ ] **6.4 Importar CSV.** Importar um `.csv` real (salvo no Excel/Google Sheets como CSV com `;`,
  incluindo acentos, aspas e uma célula com quebra de linha): os cards entram certos no deck escolhido.
  Conferir também um arquivo `.txt`.
- [ ] **6.5 Markdown no card.** Card com `**negrito**`, `*itálico*`, `` `código` `` e lista `- item` aparece
  formatado na revisão.
- [ ] **6.6 Revisar desta tarefa.** No hub de uma tarefa com cards (inclusive de subtarefas), "Revisar desta
  tarefa" revisa só esses.
- [ ] **6.7 Painel do card com teclado.** Criar e editar card: o painel sobe com o teclado; deck e
  tarefa vinculada podem ser trocados.

## Limitações conhecidas (não são bugs)

- iOS: configuração feita, mas nada foi compilado nem testado (o ambiente é Linux).
- A hora do lembrete de tarefas de dia inteiro (9h) ainda é fixa (a tela de Ajustes já existe; falta
  esse item).
- Importação de `.apkg` (Anki) não foi feita: o formato atual do Anki guarda a coleção num SQLite
  comprimido com zstd dentro de um zip; ficou fora do escopo (o plano marcava como opcional).
