# My Cadence

App pessoal, offline-first, que junta num lugar só:

- **Tarefas** e subtarefas, com rotinas recorrentes e alarmes;
- **Flashcards** com repetição espaçada (algoritmo FSRS, o mesmo do Anki moderno);
- **Pomodoro** vinculado às tarefas;
- **Books**: cadernos de páginas estilo Notion;
- **Agenda** com visões de dia, semana e mês;
- **Métricas** de foco, revisões e rotinas.

A tarefa é o centro: cada uma vira um hub onde ficam os cards, o tempo de foco e as páginas dela.
Tudo funciona sem internet e fica no próprio aparelho. A sincronização com um backend próprio vem no fim.

> Em desenvolvimento. O plano completo, etapa por etapa, está em [docs/PLANO.md](docs/PLANO.md).

## Stack

| Tema | Pacote |
|---|---|
| Interface | Flutter (Material 3, tema claro e escuro, pt-BR) |
| Navegação | `go_router` (`StatefulShellRoute` com 5 abas) |
| Estado | Riverpod |
| Banco local | drift (SQLite) |
| Repetição espaçada | `fsrs` |
| Notificações | `flutter_local_notifications` + `timezone` |
| Editor de páginas | AppFlowy Editor ([fork](https://github.com/edenilsonmota/appflowy-editor/tree/cadence/file-picker-13) com suporte a file_picker 13) |
| Arquivos | `file_picker` (CSV, Markdown, zip) e `archive` |
| Gráficos | `fl_chart` |

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

Verificações usadas em toda etapa:

```bash
flutter analyze
flutter test
```

## Screenshots

_As capturas de tela entram aqui conforme as telas forem ficando prontas._

## Licença

[MIT](LICENSE)
