import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:lucide_icons_flutter/lucide_icons_500.dart';

import '../../data/db/enums.dart';
import '../../features/tasks/task_appearance.dart';
import 'icon_catalog.dart';

typedef _I = LucideIcons300;

/// Todos os ícones do app, por conceito. Família única (Lucide, traço 300);
/// a versão mais encorpada (500) marca estado ativo, já que o Lucide não tem
/// ícones preenchidos. Mesma ação, mesmo ícone em todo lugar.
abstract final class AppIcons {
  // ─── Navegação ──────────────────────────────────────────────────────────
  static const today = _I.sun;
  static const todayActive = LucideIcons500.sun;
  static const tasks = _I.listChecks;
  static const tasksActive = LucideIcons500.listChecks;
  static const agenda = _I.calendar;
  static const agendaActive = LucideIcons500.calendar;
  static const review = _I.layers;
  static const reviewActive = LucideIcons500.layers;
  static const books = _I.bookOpen;
  static const booksActive = LucideIcons500.bookOpen;
  static const stats = _I.chartColumn;
  static const statsActive = LucideIcons500.chartColumn;
  static const settings = _I.settings;
  static const navBar = _I.panelBottom;
  static const language = _I.languages;
  static const chevronRight = _I.chevronRight;
  static const menu = _I.menu;
  static const back = _I.arrowLeft;
  static const close = _I.x;
  static const more = _I.ellipsisVertical;
  static const expand = _I.chevronDown;
  static const collapse = _I.chevronUp;
  static const dropdown = _I.chevronDown;

  // ─── Ações ──────────────────────────────────────────────────────────────
  static const add = _I.plus;
  static const remove = _I.minus;
  static const edit = _I.pencil;
  static const delete = _I.trash2;
  static const undo = _I.undo2;
  static const send = _I.sendHorizontal;
  static const search = _I.search;
  static const searchEmpty = _I.searchX;
  static const filter = _I.listFilter;
  static const filterOff = _I.funnelX;
  static const dragHandle = _I.gripHorizontal;
  static const import = _I.upload;
  static const export = _I.download;
  static const link = _I.link;
  static const unlink = _I.unlink;
  static const table = _I.table2;
  static const image = _I.imagePlus;
  static const read = _I.eye;
  static const check = _I.check;
  static const done = _I.circleCheck;
  static const goToday = _I.calendarCheck2;

  // ─── Conceitos ──────────────────────────────────────────────────────────
  static const task = _I.circleCheckBig;
  static const subtask = _I.cornerDownRight;
  static const date = _I.calendar;
  static const start = _I.play;
  static const time = _I.clock;
  static const repeat = _I.repeat;
  static const alarm = _I.alarmClock;
  static const notification = _I.bell;
  static const diagnostics = _I.shieldAlert;
  static const snooze = _I.clockArrowUp;
  static const priority = _I.flag;
  static const tag = _I.tag;
  static const color = _I.palette;
  static const error = _I.circleAlert;
  static const celebrate = _I.partyPopper;
  static const streak = _I.flame;
  static const radioOff = _I.circle;
  static const radioOn = _I.circleDot;

  // ─── Pomodoro ───────────────────────────────────────────────────────────
  static const pomodoro = _I.timer;
  static const pomodoroActive = LucideIcons500.timer;
  static const play = _I.play;
  static const pause = _I.pause;
  static const stop = _I.square;
  static const breakTime = _I.coffee;

  // ─── Flashcards ─────────────────────────────────────────────────────────
  static const flashcard = _I.layers;
  static const deck = _I.folder;
  static const newDeck = _I.folderPlus;
  static const cardFront = _I.panelTop;
  static const cardBack = _I.rotateCcw;

  // ─── Books ──────────────────────────────────────────────────────────────
  static const book = _I.bookOpen;
  static const page = _I.fileText;
  static const newPage = _I.filePlus;

  // ─── Conta e sincronização ──────────────────────────────────────────────
  static const cloud = _I.cloud;
  static const cloudOff = _I.cloudOff;
  static const synced = _I.cloudCheck;
  static const sync = _I.refreshCw;
  static const signOut = _I.logOut;
  static const switchAccount = _I.arrowLeftRight;
  static const history = _I.history;
  static const device = _I.smartphone;
  static const account = _I.userRound;

  // ─── Agenda ─────────────────────────────────────────────────────────────
  static const viewDay = _I.rows3;
  static const viewWeek = _I.columns3;
  static const viewMonth = _I.layoutGrid;
  static const viewList = _I.list;

  /// Ícone padrão de cada tipo de tarefa.
  static IconData kind(TaskKind kind) =>
      IconCatalog.tryIcon(kindIconKey(kind))!;

  /// Ícone de uma chave do catálogo; desconhecida cai em [fallback].
  static IconData of(String? key, {IconData fallback = _I.squareCheck}) =>
      IconCatalog.tryIcon(key) ?? fallback;
}

/// Tamanhos fixos de ícone.
abstract final class AppIconSize {
  /// Metadados (linha abaixo do título).
  static const double meta = 16;

  /// Padrão da interface.
  static const double standard = 20;

  /// Navegação e ações.
  static const double action = 24;

  /// Destaque (cabeçalho do hub).
  static const double feature = 32;
}
