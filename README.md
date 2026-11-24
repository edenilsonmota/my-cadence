# My Cadence

App pessoal, offline-first, que junta num lugar só:

- **Tarefas** e subtarefas, com rotinas recorrentes e alarmes;
- **Flashcards** com repetição espaçada (algoritmo FSRS, o mesmo do Anki moderno);
- **Pomodoro** vinculado às tarefas;
- **Books**: cadernos de páginas estilo Notion;
- **Agenda** com visões de dia, semana e mês;
- **Métricas** de foco, revisões e rotinas.

A tarefa é o centro: cada uma vira um hub onde ficam os cards, o tempo de foco e as páginas dela.
Tudo funciona sem internet e fica no próprio aparelho. Para usar em mais de um aparelho, o app sincroniza pelo
Google Drive da própria pessoa (pasta privada do app, sem servidor próprio); também há backup manual em JSON.

> Em desenvolvimento. O plano completo, etapa por etapa, está em [docs/PLANO.md](docs/PLANO.md).

## Stack

| Tema | Pacote |
|---|---|
| Interface | Flutter (Material 3 com sistema de design próprio, tema claro e escuro, pt-BR) |
| Navegação | `go_router` (`StatefulShellRoute` com 5 abas) |
| Estado | Riverpod |
| Banco local | drift (SQLite) |
| Repetição espaçada | `fsrs` |
| Notificações | `flutter_local_notifications` + `timezone` |
| Editor de páginas | AppFlowy Editor ([fork](https://github.com/edenilsonmota/appflowy-editor/tree/cadence/file-picker-13) com suporte a file_picker 13) |
| Arquivos | `file_picker` (CSV, Markdown, zip, JSON) e `archive` |
| Sincronização | `google_sign_in` + `googleapis` (Drive, `appDataFolder`) |
| Gráficos | `fl_chart` |
| Ícones | Lucide (`lucide_icons_flutter`), família única |
| Fontes | Inter (interface), Literata (leitura) e JetBrains Mono (código), empacotadas, licença OFL |

Os pacotes entram no projeto conforme cada etapa precisa deles.

## Como rodar

Pré-requisitos: Flutter 3.47 ou mais novo (Dart 3.13) e Android SDK com a plataforma **37**
(exigida pelo `flutter_local_notifications`).

```bash
git clone https://github.com/edenilsonmota/my-cadence.git
cd my-cadence
flutter pub get
flutter run
```

Para a sincronização pelo Google Drive, siga [docs/google-cloud.md](docs/google-cloud.md) e rode com
`--dart-define-from-file=config/google.json`. Sem isso o app funciona normalmente, sem login.

Verificações usadas em toda etapa:

```bash
flutter analyze
flutter test
```

## Uso no dia a dia (Android)

Para usar de verdade, instale o build de **release** (mais rápido e sem as telas de desenvolvimento):

```bash
flutter build apk --release --split-per-abi
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

O release ainda é assinado com a chave de debug, então instala por cima do app de desenvolvimento sem perder
dados. Quando houver uma chave de release própria, a troca de assinatura exige desinstalar: antes, exporte um
backup JSON (ou sincronize pelo Drive) e importe depois.

## Design

Tudo que é visual sai de `lib/app/theme/`: espaçamentos, raios, movimento, paleta de 12 cores (guardadas por
chave, com contraste testado nos dois temas), tipografia e o mapa de ícones `AppIcons`. Tarefas, tags e books
têm cor e ícone escolhidos num seletor único, com herança (tarefa → mãe → tag → tipo). Em modo debug, o menu
lateral abre o catálogo de componentes.

## Screenshots

_As capturas de tela entram aqui conforme as telas forem ficando prontas._

## Licença

[MIT](LICENSE)
