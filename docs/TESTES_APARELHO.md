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

Achado no aparelho e já corrigido: ao fechar o seletor de data/hora, o foco voltava ao título e o
teclado cobria o formulário (corrigido, com teste de regressão).

## Pendentes: Etapa 3 (recorrência e alarmes)

Preparação: criar pela aba Hoje uma rotina com **Dia inteiro desligado**, prazo hoje com hora
= agora + 3 min, **Repetir: Diária** e **Alarme: Na hora**. Fechar o app como descrito acima.

- [ ] **3.1 Alarme com o app fechado.** No horário, a notificação "Teste alarme / Prazo: Hoje, HH:MM"
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

## Limitações conhecidas (não são bugs)

- iOS: configuração feita, mas nada foi compilado nem testado (o ambiente é Linux).
- A hora do lembrete de tarefas de dia inteiro (9h) ainda é fixa; vira ajuste quando a tela de
  Ajustes existir.
