import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'appearance_badge.dart';

/// Escolha do seletor. `null` em uma chave = "usar padrão" (herança).
typedef AppearanceChoice = ({String? colorKey, String? iconKey});

/// Folha com prévia ao vivo, as 12 cores, busca e grade de ícones por
/// categoria. Devolve `null` se fechar sem confirmar.
///
/// [inheritedColor]/[inheritedIcon] são o que vale quando a chave é nula
/// (mostrados na prévia e ao tocar "Usar padrão").
Future<AppearanceChoice?> showAppearancePicker(
  BuildContext context, {
  required String? colorKey,
  required String? iconKey,
  required String inheritedColor,
  required IconData inheritedIcon,
  bool withIcon = true,
  bool withColor = true,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<AppearanceChoice>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AppearancePicker(
      colorKey: colorKey,
      iconKey: iconKey,
      inheritedColor: inheritedColor,
      inheritedIcon: inheritedIcon,
      withIcon: withIcon,
      withColor: withColor,
    ),
  );
}

class _AppearancePicker extends StatefulWidget {
  const _AppearancePicker({
    required this.colorKey,
    required this.iconKey,
    required this.inheritedColor,
    required this.inheritedIcon,
    required this.withIcon,
    this.withColor = true,
  });

  final String? colorKey;
  final String? iconKey;
  final String inheritedColor;
  final IconData inheritedIcon;
  final bool withIcon;
  final bool withColor;

  @override
  State<_AppearancePicker> createState() => _AppearancePickerState();
}

class _AppearancePickerState extends State<_AppearancePicker> {
  late String? _color = widget.colorKey;
  late String? _icon = widget.iconKey;
  String _query = '';

  static String _fold(String s) {
    const from = 'áàâãéêíóôõúç';
    const to = 'aaaaeeiooouc';
    return [
      for (final ch in s.toLowerCase().split(''))
        from.contains(ch) ? to[from.indexOf(ch)] : ch,
    ].join();
  }

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final palette = context.palette;
    final q = _fold(_query.trim());
    final icon = IconCatalog.tryIcon(_icon) ?? widget.inheritedIcon;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.withIcon ? 0.85 : 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(space.page, 0, space.page, space.xl),
        children: [
          // Prévia ao vivo.
          Row(
            children: [
              AppearanceBadge(
                colorKey: _color ?? widget.inheritedColor,
                icon: icon,
                size: AppIconSize.feature,
              ),
              SizedBox(width: space.lg),
              Expanded(
                child: Text(
                  !widget.withColor
                      ? 'Ícone'
                      : widget.withIcon
                      ? 'Ícone e cor'
                      : 'Cor',
                  style: context.text.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _color = null;
                  _icon = null;
                }),
                child: const Text('Usar padrão'),
              ),
            ],
          ),
          if (widget.withColor) ...[
            SizedBox(height: space.lg),
            Text('COR', style: context.type.section),
            SizedBox(height: space.sm),
            Wrap(
              spacing: space.sm,
              runSpacing: space.sm,
              children: [
                for (final key in PaletteKey.values)
                  Semantics(
                    button: true,
                    selected: _color == key.name,
                    label: key.label,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = key.name),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.of(key).strong,
                          shape: BoxShape.circle,
                          border: _color == key.name
                              ? Border.all(
                                  color: context.colors.onSurface,
                                  width: 2.5,
                                )
                              : null,
                        ),
                        child: _color == key.name
                            ? Icon(
                                AppIcons.check,
                                size: AppIconSize.standard,
                                color: context.colors.surface,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (widget.withIcon) ...[
            SizedBox(height: space.xl),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar ícone',
                prefixIcon: Icon(AppIcons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            for (final MapEntry(key: category, value: icons)
                in IconCatalog.categories.entries)
              if (icons
                      .where(
                        (i) =>
                            q.isEmpty ||
                            _fold(i.label).contains(q) ||
                            _fold(category).contains(q),
                      )
                      .toList()
                  case final shown when shown.isNotEmpty) ...[
                SizedBox(height: space.lg),
                Text(category.toUpperCase(), style: context.type.section),
                SizedBox(height: space.sm),
                Wrap(
                  spacing: space.xs,
                  runSpacing: space.xs,
                  children: [
                    for (final i in shown)
                      Tooltip(
                        message: i.label.split(' ').first,
                        child: InkWell(
                          borderRadius: context.radius.mdAll,
                          onTap: () => setState(() => _icon = i.key),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _icon == i.key
                                  ? palette
                                        .byName(_color ?? widget.inheritedColor)
                                        .tint
                                  : null,
                              borderRadius: context.radius.mdAll,
                            ),
                            child: Icon(
                              i.icon,
                              size: AppIconSize.action,
                              color: _icon == i.key
                                  ? palette
                                        .byName(_color ?? widget.inheritedColor)
                                        .onTint
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
          ],
          SizedBox(height: space.xl),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop((colorKey: _color, iconKey: _icon)),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
