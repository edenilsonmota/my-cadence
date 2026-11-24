import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/staggered_entry.dart';

/// Catálogo dos componentes compartilhados (só em debug): tipografia, paleta,
/// ícones, botões, campos e estados, no tema claro ou escuro.
class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  Brightness? _brightness;

  @override
  Widget build(BuildContext context) {
    final brightness = _brightness ?? Theme.of(context).brightness;
    return Theme(
      data: buildTheme(brightness),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Componentes'),
            actions: [
              IconButton(
                tooltip: brightness == Brightness.dark
                    ? 'Tema claro'
                    : 'Tema escuro',
                icon: Icon(
                  brightness == Brightness.dark
                      ? AppIcons.today
                      : AppIcons.read,
                ),
                onPressed: () => setState(
                  () => _brightness = brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(context.space.page),
            children: const [
              _Section('Tipografia', child: _Typography()),
              _Section('Paleta', child: _Palette()),
              _Section('Ícones', child: _Icons()),
              _Section('Botões', child: _Buttons()),
              _Section('Campos e chips', child: _Fields()),
              _Section('Lista', child: _ListDemo()),
              _Section('Carregando', child: _Skeletons()),
              _Section('Vazio', child: _EmptyDemo()),
              _Section('Avisos', child: _Overlays()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.space.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: context.type.section),
        SizedBox(height: context.space.md),
        child,
      ],
    ),
  );
}

class _Typography extends StatelessWidget {
  const _Typography();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final type = context.type;
    final styles = <(String, TextStyle)>[
      ('Headline', t.headlineMedium!),
      ('Título grande', t.titleLarge!),
      ('Título', t.titleMedium!),
      ('Corpo', t.bodyLarge!),
      ('Apoio', t.bodySmall!),
      ('Rótulo', t.labelMedium!),
      ('SEÇÃO', type.section),
      ('Leitura: era uma vez um livro', type.reading),
      ('código()', type.code),
      ('1 h 05 min', type.metric),
      ('25:00', type.timer),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, style) in styles)
          Padding(
            padding: EdgeInsets.only(bottom: context.space.sm),
            child: Text(label, style: style),
          ),
      ],
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: context.space.sm,
      runSpacing: context.space.sm,
      children: [
        for (final key in PaletteKey.values)
          Container(
            width: 100,
            padding: EdgeInsets.all(context.space.sm),
            decoration: BoxDecoration(
              color: palette.of(key).tint,
              borderRadius: context.radius.mdAll,
              border: Border(
                left: BorderSide(color: palette.of(key).strong, width: 4),
              ),
            ),
            child: Text(
              key.label,
              style: context.text.labelMedium!.copyWith(
                color: palette.of(key).onTint,
              ),
            ),
          ),
      ],
    );
  }
}

class _Icons extends StatelessWidget {
  const _Icons();

  static const _all = <(String, IconData)>[
    ('hoje', AppIcons.today),
    ('tarefas', AppIcons.tasks),
    ('agenda', AppIcons.agenda),
    ('revisar', AppIcons.review),
    ('books', AppIcons.books),
    ('métricas', AppIcons.stats),
    ('ajustes', AppIcons.settings),
    ('adicionar', AppIcons.add),
    ('editar', AppIcons.edit),
    ('excluir', AppIcons.delete),
    ('desfazer', AppIcons.undo),
    ('buscar', AppIcons.search),
    ('filtrar', AppIcons.filter),
    ('concluir', AppIcons.done),
    ('data', AppIcons.date),
    ('hora', AppIcons.time),
    ('repetir', AppIcons.repeat),
    ('alarme', AppIcons.alarm),
    ('prioridade', AppIcons.priority),
    ('tag', AppIcons.tag),
    ('subtarefa', AppIcons.subtask),
    ('pomodoro', AppIcons.pomodoro),
    ('pausa', AppIcons.breakTime),
    ('flashcard', AppIcons.flashcard),
    ('deck', AppIcons.deck),
    ('página', AppIcons.page),
    ('book', AppIcons.book),
    ('importar', AppIcons.import),
    ('exportar', AppIcons.export),
    ('vínculo', AppIcons.link),
    ('mais', AppIcons.more),
    ('sequência', AppIcons.streak),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.space.xs,
    runSpacing: context.space.md,
    children: [
      for (final (name, icon) in _all)
        SizedBox(
          width: 72,
          child: Column(
            children: [
              Icon(icon, size: AppIconSize.action),
              SizedBox(height: context.space.xs),
              Text(name, style: context.text.labelSmall),
            ],
          ),
        ),
    ],
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.space.sm,
    runSpacing: context.space.sm,
    children: [
      FilledButton(onPressed: () {}, child: const Text('Principal')),
      FilledButton.tonal(onPressed: () {}, child: const Text('Secundário')),
      TextButton(onPressed: () {}, child: const Text('Terciário')),
      OutlinedButton(onPressed: () {}, child: const Text('Contorno')),
      FilledButton.icon(
        onPressed: () {},
        icon: const Icon(AppIcons.play),
        label: const Text('Iniciar'),
      ),
      IconButton(
        tooltip: 'Editar',
        onPressed: () {},
        icon: const Icon(AppIcons.edit),
      ),
      FloatingActionButton(
        heroTag: null,
        tooltip: 'Adicionar',
        onPressed: () {},
        child: const Icon(AppIcons.add),
      ),
    ],
  );
}

class _Fields extends StatelessWidget {
  const _Fields();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const TextField(
        decoration: InputDecoration(
          labelText: 'Título',
          hintText: 'O que precisa ser feito?',
        ),
      ),
      SizedBox(height: context.space.md),
      Wrap(
        spacing: context.space.sm,
        children: [
          const Chip(avatar: Icon(AppIcons.tag), label: Text('Faculdade')),
          FilterChip(
            selected: true,
            onSelected: (_) {},
            label: const Text('Selecionado'),
          ),
          ActionChip(
            avatar: const Icon(AppIcons.date),
            onPressed: () {},
            label: const Text('Amanhã'),
          ),
        ],
      ),
      SizedBox(height: context.space.md),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Dia')),
          ButtonSegment(value: 1, label: Text('Semana')),
          ButtonSegment(value: 2, label: Text('Mês')),
        ],
        selected: const {1},
        onSelectionChanged: (_) {},
      ),
    ],
  );
}

class _ListDemo extends StatelessWidget {
  const _ListDemo();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, title) in ['Estudar FSRS', 'Correr', 'Reunião'].indexed)
        StaggeredEntry(
          index: i,
          child: Pressable(
            child: ListTile(
              leading: const Icon(AppIcons.task),
              title: Text(title),
              subtitle: const Text('Hoje, 14:00'),
              trailing: const Icon(AppIcons.more),
              onTap: () {},
            ),
          ),
        ),
    ],
  );
}

class _Skeletons extends StatelessWidget {
  const _Skeletons();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 180, child: SkeletonList(items: 3));
}

class _EmptyDemo extends StatelessWidget {
  const _EmptyDemo();

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: AppIcons.today,
    message: 'Nenhuma tarefa para hoje.',
    action: FilledButton.tonal(onPressed: () {}, child: const Text('Criar')),
  );
}

class _Overlays extends StatelessWidget {
  const _Overlays();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.space.sm,
    children: [
      OutlinedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarefa excluída.'),
            action: SnackBarAction(label: 'Desfazer', onPressed: () {}),
          ),
        ),
        child: const Text('SnackBar'),
      ),
      OutlinedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excluir tarefa?'),
            content: const Text('As subtarefas também serão excluídas.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ),
        child: const Text('Diálogo'),
      ),
      OutlinedButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (context) => Padding(
            padding: EdgeInsets.all(context.space.xl),
            child: const Text('Folha inferior com alça.'),
          ),
        ),
        child: const Text('Folha'),
      ),
    ],
  );
}
