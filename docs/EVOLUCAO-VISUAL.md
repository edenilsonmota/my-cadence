# My Cadence: cores, ícones e acabamento visual

Especificação da próxima evolução do app. O objetivo é sair do visual padrão do Flutter e ter um app **elegante e
harmônico**: mesma família de ícones, cores que conversam entre si, tipografia com hierarquia clara e o mesmo
"jeito" em tarefas, calendário, pomodoro, flashcards, métricas e books.

> **Como trabalhar (para o Claude Code)**
> - Comece pela **Fase 0 (auditoria)** e **pare** para eu aprovar antes de mudar qualquer coisa.
> - Depois, uma fase por vez: `build_runner`, `flutter analyze`, `flutter test`, commit e parada para revisão.
> - Em cada fase com mudança visível, gere **screenshots antes e depois** (emulador, tema claro e escuro) e me mostre.
> - Siga o `docs/PLANO.md` e o `CLAUDE.md`. Se algo aqui conflitar com eles, pare e pergunte.
> - Confira no pub.dev a versão e a licença de qualquer pacote novo antes de adicionar.

---

## Fase 0: Auditoria (só relatório, sem mudar código)

Responda com uma lista curta e objetiva:

1. **Cores e ícones no banco**
   - `Tags` já tem cor? Em que formato (ARGB, chave)? A UI deixa escolher?
   - `Tasks` tem `color`? E ícone? `Notebooks` tem ícone/cor?
   - O que já existe e o que falta para o que está descrito nas Fases 2 e 3.
2. **Tema atual**: o que está customizado no `ThemeData` e o que é padrão do Material.
3. **Valores soltos**: quantos usos de `Colors.`, `Color(0x`, `Icons.`, `EdgeInsets` com número, `BorderRadius.circular(` com número,
   `fontSize:` e `Duration(milliseconds:` existem fora do tema. Liste os arquivos com mais ocorrências.
4. **Ícones**: quais pacotes/famílias estão em uso e onde a mesma ação usa ícones diferentes.
5. **Inventário de telas**: para cada tela, até 3 problemas visuais (caixa dentro de caixa, hierarquia fraca, excesso de bordas,
   espaçamento irregular, "Carregando..." em texto, estado vazio sem ação etc.).
6. **Proposta** de família de ícones e fontes (ver Fase 1), com prós e contras.

---

## Fase 1: Sistema de design (tokens e tema)

Tudo que é visual sai de **um lugar só**: `lib/app/theme/`.

### 1.1 Tokens como `ThemeExtension`
- `AppSpacing`: escala de 4 (4, 8, 12, 16, 24, 32, 48).
- `AppRadius`: sm 8, md 12, lg 16, xl 24, pill.
- `AppMotion`: rápido 150 ms, base 200 ms, lento 300 ms; curvas `Easing.emphasizedDecelerate` (entrada),
  `Easing.emphasizedAccelerate` (saída), `Easing.standard`.
- `AppPalette` (ver 1.3) e cores semânticas: sucesso, alerta, perigo, informação, e as 4 cores das notas do flashcard
  (Errei, Difícil, Bom, Fácil).
- Acesso por extensão: `context.space.md`, `context.radius.lg`, `context.palette.of(key)`, `context.motion.base`.
- **Regra:** fora de `lib/app/theme/`, nenhum `Colors.*`, `Color(0x..)`, `Icons.*`, `fontSize:` ou duração numérica.
  Criar um teste/script de lint simples (grep no CI ou teste que varre `lib/`) que falha se isso aparecer.

### 1.2 Tipografia
- Fontes **empacotadas como assets** (o app é offline; nada de baixar fonte em runtime). Licença OFL.
  - Interface: **Inter** (ou alternativa equivalente que você justificar).
  - Leitura dos books: uma serifada confortável, como **Literata** ou **Source Serif 4**.
  - Código: **JetBrains Mono**.
- `TextTheme` completo e coerente: poucos tamanhos, pesos distintos para hierarquia (título forte, apoio discreto),
  rótulos pequenos em caixa alta com espaçamento de letras para seções ("HOJE", "FLASHCARDS").
- Números de métricas e do timer com **algarismos tabulares** (`FontFeature.tabularFigures()`), para não "dançarem".

### 1.3 Paleta curada (cores de tags, tarefas e books)
- **Nada de seletor de cor livre.** Uma paleta de **12 cores** harmônicas, guardadas por **chave** (`azul`, `indigo`, `violeta`,
  `rosa`, `vermelho`, `laranja`, `ambar`, `lima`, `verde`, `teal`, `ciano`, `ardosia`), não por ARGB.
- Para cada chave, gerar os tons com `material_color_utilities` (HCT, já vem com o Flutter), nos temas claro e escuro:
  - `tint`: fundo suave (blocos do calendário, ícone da tarefa, chips);
  - `strong`: barra lateral, ponto da tag, anel do pomodoro, linha do gráfico;
  - `onTint`: texto e ícone sobre o `tint`.
- **Contraste**: teste automatizado que garante 4,5:1 de `onTint` sobre `tint` (e de `strong` sobre a superfície para elementos
  gráficos, 3:1), nos dois temas, para todas as 12 cores.
- A ordem da paleta é também a **ordem das séries nos gráficos**.

### 1.4 Família única de ícones
- Escolher **uma** família com traço consistente e catálogo grande: **Phosphor** (`phosphor_flutter`, preferida: pesos regular,
  bold e fill) ou **Lucide**. Não misturar com `Icons.*` do Material.
- Tamanhos fixos: 16 (meta), 20 (padrão), 24 (navegação/ação), 32 (ícone de destaque no hub).
- Peso regular na interface, **fill** só para estado ativo (aba selecionada, favorito).
- **Mapa central de ícones por ação/conceito** (`AppIcons`): editar, excluir, concluir, data, hora, repetir, alarme, tag, prioridade,
  pomodoro, flashcard, página, book, subtarefa, busca, filtro, ordenar, mais opções etc. Mesma ação = mesmo ícone em todo o app.
- Ação só com ícone sempre com `tooltip` e `semanticLabel`.

### 1.5 Temas dos componentes
Customizar o `ThemeData` para não parecer Material padrão:
- AppBar plana, sem sombra, título com a tipografia do tema; ao rolar, só uma linha fina ou leve mudança de superfície.
- NavigationBar com indicador discreto e ícones regular/fill.
- Campos "filled" sem sublinhado, cantos `md`, rótulo acima.
- Chips, botões (principal sólido, secundário tonal, terciário texto), FAB, SnackBar, Dialog e BottomSheet (com alça) com os raios e
  espaçamentos dos tokens.
- Divisores finos e usados com moderação.

### 1.6 Movimento
- Transições de página com fade + leve deslocamento (`AppMotion`), iguais em todo o go_router.
- Listas: entrada em cascata só no primeiro carregamento (30–50 ms entre itens, no máximo 8 animados).
- Pressionar: escala 0,98. Concluir tarefa: check animado + risco no título + leve haptic.
- **Esqueletos** no formato do conteúdo em vez de spinner ou "Carregando...".
- Respeitar `MediaQuery.disableAnimations`: tudo vira instantâneo ou só fade.
- Nada acima de 400 ms, só `transform`/`opacity`, nada animando a cada rebuild.

### 1.7 Catálogo de componentes
Tela de catálogo só em debug (`/dev/componentes`) mostrando cada componente compartilhado nos dois temas.
Todo componente que se repete vai para `lib/shared/widgets/`, nunca dentro da tela.

---

## Fase 2: Cores e ícones nos dados

### Regras
- **Tags**: só **cor** (chave da paleta). Aparecem como chip com ponto colorido. Sem ícone, para não poluir.
- **Tarefas**: **cor** e **ícone** opcionais.
- **Books**: **cor** e **ícone** opcionais (capa do book na lista). Páginas herdam do book.
- **Tipo da tarefa** (simples, estudo, rotina, evento): cor e ícone padrão definidos no tema.
- **Herança** (resolver numa função pura, testada): cor da tarefa → cor da tarefa mãe → cor da primeira tag → cor do tipo.
  Ícone: ícone da tarefa → ícone da mãe → ícone do tipo.

### Armazenamento
- Cor: `TextColumn colorKey?` (chave da paleta). Ícone: `TextColumn iconKey?` (chave do catálogo, ex.: `book-open`).
- **Nunca** guardar `codePoint` ou ARGB: muda entre versões do pacote, quebra o tree-shaking de ícones e não se adapta ao tema escuro.
- Catálogo de ícones selecionáveis: mapa `chave → IconData const` com **~100 ícones curados** por categoria
  (estudo, trabalho, saúde, casa, finanças, lazer, pessoas, viagem, criativo, tecnologia, espiritualidade, diversos).
  Chave desconhecida cai no ícone do tipo.
- Migração do drift com teste de migração. Se `Tags` já tiver cor em ARGB, converter para a chave mais próxima.
- `colorKey`/`iconKey` entram no sync como colunas normais.

### Seletor de ícone e cor
- Um único bottom sheet: **prévia ao vivo** no topo (ícone no quadrado arredondado com o `tint`), linha com as 12 cores,
  busca e grade de ícones por categoria. Opção "Usar padrão" (volta à herança).
- Usado no formulário de tarefa, no hub e no book.

---

## Fase 3: Telas

Princípios para todas: **menos caixas, mais espaço** (sem cartão dentro de cartão, separar por espaço em vez de bordas);
**um título forte por bloco**; **uma ação principal por bloco**; **consistência** (mesma ação, mesmo ícone, mesmo lugar);
**ruído zero** (nada de contadores ou textos técnicos sem uso).

### Item de tarefa (componente central, usado em Hoje, Tarefas, hub e busca)
- À esquerda, checkbox circular na cor da tarefa; ícone da tarefa num quadrado arredondado com o `tint`.
- Título com uma linha de metadados abaixo, com ícones de 16: data/hora, repetir, alarme, nº de subtarefas (2/5),
  cards vencidos e tempo de foco. Mostrar só o que existe.
- Prioridade como bandeira discreta, não como cor de fundo.
- Atrasada: só a data em cor de perigo, sem pintar o item todo.

### Criar tarefa
- **Adição rápida** em bottom sheet: campo de título grande e, abaixo, uma fileira de "pílulas" (data, tag, prioridade,
  ícone/cor, mais). Enter salva e já abre para a próxima.
- Formulário completo em seções com título e espaço, não um mar de campos. Recorrência com chips de dias e frase-resumo
  em português ("Toda semana: seg, qua, sex").

### Hub da tarefa
- Cabeçalho com ícone grande (32) no `tint`, título forte, linha de metadados e tags.
- Seções (Subtarefas, Flashcards, Pomodoro, Páginas) com rótulo pequeno em caixa alta e uma ação à direita.
- Indicadores leves: "3 cards para revisar", "2h 15min de foco · estimado 6 pomodoros".

### Agenda
- Blocos usam `tint` + barra `strong` + título `onTint` da cor resolvida da tarefa; ícone de 16 no bloco quando couber.
- Linha da hora atual na cor de destaque do tema.

### Pomodoro
- Anel de progresso na cor da tarefa, tempo grande com algarismos tabulares, ícone e título da tarefa acima.
- Tela limpa: só tempo, tarefa, ação principal (pausar/retomar) e ação secundária (parar).

### Flashcards
- Card centralizado com respiro, frente em tipografia de destaque, verso com Markdown renderizado na tipografia de leitura.
- Botões de nota com as 4 cores semânticas e o intervalo previsto em texto menor.
- Barra de progresso fina da sessão; tela de fim de sessão com resumo.

### Métricas
- Cartões de indicador leves: número grande tabular + rótulo pequeno + variação discreta.
- Gráficos (fl_chart) com um estilo comum: eixos e grade sutis, sem bordas, rótulos na tipografia do tema,
  séries na ordem da paleta, cor por tag/tarefa vinda da paleta; legenda só quando há mais de uma série.
- Heatmap de rotinas com tons de uma única cor (do claro ao `strong`).
- Estados sem dados com frase e ação, nunca gráfico vazio.

### Books (leitura e edição)
- Lista de books como capas: ícone + cor do book, título e "12 páginas · editado há 2 dias".
- **Tema do AppFlowy alinhado ao app** (`EditorStyle` e `blockComponentBuilders`):
  - corpo na serifada, 17–18 pt, entrelinha ~1,6, largura de leitura limitada (~680 px em tablet);
  - escala de títulos H1–H3 coerente com o `TextTheme`;
  - citação com barra lateral na cor do book; callout com `tint`;
  - bloco de código em JetBrains Mono com fundo sutil e cantos `md`;
  - listas, checkboxes, tabelas e divisores com o mesmo espaçamento;
  - seleção e cursor na cor de destaque.
- Modo leitura sem toolbar, com ícones da toolbar do editor da mesma família quando o pacote permitir customizar.

### Estados gerais
- Estados vazios com ícone (da família), uma frase e a ação ("Nenhuma tarefa para hoje · Criar tarefa").
- Esqueletos no carregamento; SnackBar com "Desfazer" nas ações destrutivas.

---

## Fase 4: Conferência

- Screenshots de todas as telas em tema claro e escuro, em 360 dp e num tablet, e com escala de texto 1,3.
- Teste de contraste da paleta passando; lint de valores soltos sem ocorrências.
- Golden tests dos componentes principais do catálogo (item de tarefa, seletor de ícone/cor, chip de tag, cartão de indicador),
  com as fontes carregadas nos testes.
- Atualizar o README com os novos screenshots e registrar no `CLAUDE.md` a regra:
  **"toda tela nova usa os tokens, o `AppIcons`, a paleta e o catálogo; componente que falta entra no catálogo, nunca dentro da tela".**

## Ordem sugerida de commits
1. Fase 0 (relatório) → aprovação.
2. Tokens + tipografia + paleta + testes de contraste.
3. Família de ícones + `AppIcons` + temas dos componentes + movimento.
4. Dados: `colorKey`/`iconKey`, herança, migração, seletor de ícone e cor.
5. Item de tarefa + criar tarefa + hub.
6. Agenda + pomodoro + flashcards.
7. Métricas.
8. Books e tema do editor.
9. Conferência, goldens, README e `CLAUDE.md`.
