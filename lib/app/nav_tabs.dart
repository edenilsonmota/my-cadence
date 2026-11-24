/// Configuração da barra de navegação: telas disponíveis, validação,
/// normalização e montagem do menu lateral. Puro, sem Flutter.
library;

/// Chave em `AppSettings` (prefixo `device.` → não sincroniza entre aparelhos).
const navTabsSettingKey = 'device.navTabs';

/// Regra do Material: a barra de navegação tem entre 3 e 5 abas.
const minNavTabs = 3;
const maxNavTabs = 5;

/// Telas que podem ficar na barra de navegação ou no menu lateral.
///
/// A ordem deste enum define também os índices das branches no shell e a ordem
/// canônica dos itens no menu lateral.
enum NavTab {
  today(label: 'Hoje', tabRoute: '/hoje', overlayRoute: '/tela/hoje'),
  tasks(label: 'Tarefas', tabRoute: '/tarefas', overlayRoute: '/tela/tarefas'),
  agenda(label: 'Agenda', tabRoute: '/agenda', overlayRoute: '/tela/agenda'),
  review(label: 'Revisar', tabRoute: '/revisar', overlayRoute: '/tela/revisar'),
  books(label: 'Books', tabRoute: '/books', overlayRoute: '/tela/books'),
  pomodoro(
    label: 'Pomodoro',
    tabRoute: '/aba/pomodoro',
    overlayRoute: '/pomodoro',
  ),
  stats(
    label: 'Métricas',
    tabRoute: '/aba/metricas',
    overlayRoute: '/metricas',
  );

  const NavTab({
    required this.label,
    required this.tabRoute,
    required this.overlayRoute,
  });

  final String label;

  /// Rota da tela quando ela está como aba dentro do shell.
  final String tabRoute;

  /// Rota da tela quando ela abre por cima do shell (a partir do menu lateral).
  final String overlayRoute;
}

/// Ordem padrão da barra de navegação.
const defaultNavTabs = <NavTab>[
  NavTab.today,
  NavTab.tasks,
  NavTab.agenda,
  NavTab.review,
  NavTab.books,
];

final _tabsByName = NavTab.values.asNameMap();

/// `true` se [tabs] tem entre [minNavTabs] e [maxNavTabs] itens sem repetição.
bool isValidNavTabs(List<NavTab> tabs) =>
    tabs.length >= minNavTabs &&
    tabs.length <= maxNavTabs &&
    tabs.toSet().length == tabs.length;

/// Normaliza uma sequência de chaves vindas dos ajustes:
/// - ignora chaves desconhecidas ou vazias;
/// - remove duplicadas (mantendo a primeira ocorrência);
/// - limita ao máximo de [maxNavTabs];
/// - se sobrar menos que [minNavTabs], volta para [defaultNavTabs].
List<NavTab> normalizeNavTabs(Iterable<String> keys) {
  final result = <NavTab>[];
  final seen = <NavTab>{};
  for (final raw in keys) {
    final tab = _tabsByName[raw.trim()];
    if (tab == null || !seen.add(tab)) continue;
    result.add(tab);
    if (result.length == maxNavTabs) break;
  }
  if (result.length < minNavTabs) {
    return List<NavTab>.unmodifiable(defaultNavTabs);
  }
  return List<NavTab>.unmodifiable(result);
}

/// Interpreta o valor salvo em [navTabsSettingKey] (chaves separadas por `,`).
List<NavTab> parseNavTabs(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return List<NavTab>.unmodifiable(defaultNavTabs);
  }
  return normalizeNavTabs(raw.split(','));
}

/// Serializa a lista normalizada para gravar em [navTabsSettingKey].
String encodeNavTabs(List<NavTab> tabs) =>
    normalizeNavTabs(tabs.map((t) => t.name)).map((t) => t.name).join(',');

/// Telas que ficaram fora da barra e devem aparecer no menu lateral, na ordem
/// canônica de [NavTab.values].
List<NavTab> drawerNavTabs(List<NavTab> barTabs) {
  final inBar = barTabs.toSet();
  return List<NavTab>.unmodifiable([
    for (final tab in NavTab.values)
      if (!inBar.contains(tab)) tab,
  ]);
}

/// `true` se [tab] pode ser ligada ou desligada sem violar o mínimo/máximo.
bool canToggleNavTab(List<NavTab> current, NavTab tab) => current.contains(tab)
    ? current.length > minNavTabs
    : current.length < maxNavTabs;

/// Liga ou desliga [tab] na barra; respeita os limites de [minNavTabs] e
/// [maxNavTabs].
List<NavTab> toggleNavTab(List<NavTab> current, NavTab tab) {
  if (!canToggleNavTab(current, tab)) return current;
  if (current.contains(tab)) {
    return List<NavTab>.unmodifiable([
      for (final item in current)
        if (item != tab) item,
    ]);
  }
  return List<NavTab>.unmodifiable([...current, tab]);
}

/// Reordena as abas da barra (índices já ajustados como em `onReorderItem`).
List<NavTab> reorderNavTabs(List<NavTab> current, int from, int to) {
  if (from < 0 ||
      from >= current.length ||
      to < 0 ||
      to >= current.length ||
      from == to) {
    return current;
  }
  final list = [...current];
  final moved = list.removeAt(from);
  list.insert(to, moved);
  return List<NavTab>.unmodifiable(list);
}

/// `true` se [current] é idêntica a [defaultNavTabs] na mesma ordem.
bool isDefaultNavTabs(List<NavTab> current) {
  if (current.length != defaultNavTabs.length) return false;
  for (var i = 0; i < current.length; i++) {
    if (current[i] != defaultNavTabs[i]) return false;
  }
  return true;
}
