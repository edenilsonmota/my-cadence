/// Cores ARGB das 12 chaves de `PaletteKey` para os widgets nativos da tela
/// inicial (puro, sem Flutter).
library;

const widgetPaletteArgb = <String, int>{
  'azul': 0xFF3B82F6,
  'verde': 0xFF10B981,
  'laranja': 0xFFF97316,
  'violeta': 0xFF8B5CF6,
  'ambar': 0xFFF59E0B,
  'ciano': 0xFF06B6D4,
  'rosa': 0xFFEC4899,
  'ardosia': 0xFF64748B,
  'vermelho': 0xFFEF4444,
  'teal': 0xFF14B8A6,
  'indigo': 0xFF6366F1,
  'lima': 0xFF84CC16,
};

int argbForWidgetColorKey(String key) =>
    widgetPaletteArgb[key] ?? widgetPaletteArgb['azul']!;
