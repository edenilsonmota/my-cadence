import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

typedef _I = LucideIcons300;

/// Ícone escolhível para tarefas e books. A chave (kebab-case, igual ao nome
/// no Lucide) é o que vai para o banco, nunca o codePoint.
@immutable
class CatalogIcon {
  const CatalogIcon(this.key, this.icon, this.label);

  final String key;
  final IconData icon;

  /// Palavras para a busca, em português.
  final String label;
}

/// ~100 ícones curados, por categoria. Chave desconhecida cai no ícone do
/// tipo (quem chama decide o padrão).
abstract final class IconCatalog {
  static const categories = <String, List<CatalogIcon>>{
    'Estudo': [
      CatalogIcon('book-open', _I.bookOpen, 'livro leitura'),
      CatalogIcon(
        'graduation-cap',
        _I.graduationCap,
        'formatura curso faculdade',
      ),
      CatalogIcon('pencil', _I.pencil, 'lápis escrever'),
      CatalogIcon('notebook-pen', _I.notebookPen, 'caderno anotações'),
      CatalogIcon('library', _I.library, 'biblioteca'),
      CatalogIcon('brain', _I.brain, 'cérebro memória'),
      CatalogIcon('lightbulb', _I.lightbulb, 'ideia lâmpada'),
      CatalogIcon('calculator', _I.calculator, 'calculadora matemática'),
      CatalogIcon('languages', _I.languages, 'idiomas línguas'),
      CatalogIcon('microscope', _I.microscope, 'microscópio ciência'),
      CatalogIcon('flask-conical', _I.flaskConical, 'química laboratório'),
    ],
    'Trabalho': [
      CatalogIcon('briefcase', _I.briefcase, 'trabalho maleta'),
      CatalogIcon('laptop', _I.laptop, 'notebook computador'),
      CatalogIcon('presentation', _I.presentation, 'apresentação'),
      CatalogIcon('clipboard-list', _I.clipboardList, 'lista prancheta'),
      CatalogIcon('chart-line', _I.chartLine, 'gráfico resultados'),
      CatalogIcon('mail', _I.mail, 'email correio'),
      CatalogIcon('phone', _I.phone, 'telefone ligar'),
      CatalogIcon('users', _I.users, 'reunião equipe pessoas'),
      CatalogIcon('file-text', _I.fileText, 'documento arquivo'),
      CatalogIcon('target', _I.target, 'meta objetivo'),
    ],
    'Saúde': [
      CatalogIcon('heart', _I.heart, 'coração saúde'),
      CatalogIcon('activity', _I.activity, 'atividade batimentos'),
      CatalogIcon('dumbbell', _I.dumbbell, 'academia treino'),
      CatalogIcon('bike', _I.bike, 'bicicleta pedalar'),
      CatalogIcon('footprints', _I.footprints, 'caminhada correr'),
      CatalogIcon('apple', _I.apple, 'maçã fruta'),
      CatalogIcon('pill', _I.pill, 'remédio comprimido'),
      CatalogIcon('stethoscope', _I.stethoscope, 'médico consulta'),
      CatalogIcon('moon', _I.moon, 'lua noite'),
      CatalogIcon('bed', _I.bed, 'cama dormir sono'),
      CatalogIcon('droplet', _I.droplet, 'água beber'),
      CatalogIcon('salad', _I.salad, 'salada dieta'),
    ],
    'Casa': [
      CatalogIcon('house', _I.house, 'casa lar'),
      CatalogIcon('sofa', _I.sofa, 'sofá sala'),
      CatalogIcon('washing-machine', _I.washingMachine, 'lavar roupa'),
      CatalogIcon('shopping-cart', _I.shoppingCart, 'mercado compras'),
      CatalogIcon('utensils', _I.utensils, 'comida refeição'),
      CatalogIcon('chef-hat', _I.chefHat, 'cozinhar receita'),
      CatalogIcon('hammer', _I.hammer, 'martelo conserto'),
      CatalogIcon('wrench', _I.wrench, 'ferramenta manutenção'),
      CatalogIcon('leaf', _I.leaf, 'folha planta'),
      CatalogIcon('flower-2', _I.flower2, 'flor jardim'),
      CatalogIcon('dog', _I.dog, 'cachorro pet'),
      CatalogIcon('cat', _I.cat, 'gato pet'),
    ],
    'Finanças': [
      CatalogIcon('wallet', _I.wallet, 'carteira'),
      CatalogIcon('piggy-bank', _I.piggyBank, 'cofrinho poupança'),
      CatalogIcon('credit-card', _I.creditCard, 'cartão crédito'),
      CatalogIcon('receipt', _I.receipt, 'conta boleto recibo'),
      CatalogIcon('banknote', _I.banknote, 'dinheiro'),
      CatalogIcon('trending-up', _I.trendingUp, 'investimento alta'),
      CatalogIcon('coins', _I.coins, 'moedas'),
      CatalogIcon('landmark', _I.landmark, 'banco'),
    ],
    'Lazer': [
      CatalogIcon('gamepad-2', _I.gamepad2, 'jogo videogame'),
      CatalogIcon('music', _I.music, 'música'),
      CatalogIcon('film', _I.film, 'filme cinema'),
      CatalogIcon('tv', _I.tv, 'série televisão'),
      CatalogIcon('headphones', _I.headphones, 'fone podcast'),
      CatalogIcon('camera', _I.camera, 'foto câmera'),
      CatalogIcon('puzzle', _I.puzzle, 'quebra-cabeça'),
      CatalogIcon('party-popper', _I.partyPopper, 'festa comemorar'),
      CatalogIcon('coffee', _I.coffee, 'café pausa'),
    ],
    'Pessoas': [
      CatalogIcon('user', _I.user, 'pessoa eu'),
      CatalogIcon('baby', _I.baby, 'bebê filho'),
      CatalogIcon('gift', _I.gift, 'presente aniversário'),
      CatalogIcon('message-circle', _I.messageCircle, 'mensagem conversa'),
      CatalogIcon('handshake', _I.handshake, 'acordo parceria'),
      CatalogIcon('smile', _I.smile, 'sorriso humor'),
    ],
    'Viagem': [
      CatalogIcon('plane', _I.plane, 'avião voo'),
      CatalogIcon('car', _I.car, 'carro dirigir'),
      CatalogIcon('bus', _I.bus, 'ônibus'),
      CatalogIcon('train', _I.train, 'trem metrô'),
      CatalogIcon('map', _I.map, 'mapa'),
      CatalogIcon('map-pin', _I.mapPin, 'lugar local'),
      CatalogIcon('luggage', _I.luggage, 'mala bagagem'),
      CatalogIcon('globe', _I.globe, 'mundo internacional'),
      CatalogIcon('tent', _I.tent, 'acampar'),
      CatalogIcon('mountain', _I.mountain, 'montanha trilha'),
    ],
    'Criativo': [
      CatalogIcon('palette', _I.palette, 'pintura arte'),
      CatalogIcon('paintbrush', _I.paintbrush, 'pincel desenho'),
      CatalogIcon('pen-tool', _I.penTool, 'design'),
      CatalogIcon('scissors', _I.scissors, 'tesoura artesanato'),
      CatalogIcon('guitar', _I.guitar, 'violão instrumento'),
      CatalogIcon('feather', _I.feather, 'escrita poesia'),
      CatalogIcon('sparkles', _I.sparkles, 'brilho novidade'),
    ],
    'Tecnologia': [
      CatalogIcon('code', _I.code, 'programar código'),
      CatalogIcon('terminal', _I.terminal, 'terminal'),
      CatalogIcon('cpu', _I.cpu, 'processador hardware'),
      CatalogIcon('smartphone', _I.smartphone, 'celular app'),
      CatalogIcon('server', _I.server, 'servidor'),
      CatalogIcon('database', _I.database, 'banco de dados'),
      CatalogIcon('bug', _I.bug, 'erro bug'),
      CatalogIcon('git-branch', _I.gitBranch, 'git versão'),
      CatalogIcon('wifi', _I.wifi, 'internet rede'),
    ],
    'Espiritualidade': [
      CatalogIcon('church', _I.church, 'igreja culto'),
      CatalogIcon('sun', _I.sun, 'sol manhã'),
      CatalogIcon('sunrise', _I.sunrise, 'amanhecer'),
      CatalogIcon('flame', _I.flame, 'chama fogo'),
      CatalogIcon('book-heart', _I.bookHeart, 'bíblia devocional'),
      CatalogIcon('hand', _I.hand, 'mão oração'),
    ],
    'Diversos': [
      CatalogIcon('star', _I.star, 'estrela favorito'),
      CatalogIcon('flag', _I.flag, 'bandeira'),
      CatalogIcon('bell', _I.bell, 'sino lembrete'),
      CatalogIcon('clock', _I.clock, 'relógio hora'),
      CatalogIcon('calendar', _I.calendar, 'calendário data'),
      CatalogIcon('rocket', _I.rocket, 'foguete lançamento'),
      CatalogIcon('trophy', _I.trophy, 'troféu conquista'),
      CatalogIcon('award', _I.award, 'prêmio'),
      CatalogIcon('zap', _I.zap, 'energia rápido'),
      CatalogIcon('square-check', _I.squareCheck, 'tarefa check'),
      CatalogIcon('repeat', _I.repeat, 'rotina repetir'),
      CatalogIcon('calendar-clock', _I.calendarClock, 'evento compromisso'),
    ],
  };

  static final Map<String, CatalogIcon> _byKey = {
    for (final list in categories.values)
      for (final icon in list) icon.key: icon,
  };

  static Iterable<CatalogIcon> get all => _byKey.values;

  /// Ícone da chave, ou `null` se não existe no catálogo.
  static IconData? tryIcon(String? key) => _byKey[key]?.icon;

  static bool contains(String? key) => _byKey.containsKey(key);
}
