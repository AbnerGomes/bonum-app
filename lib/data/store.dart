import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/dates.dart';
import 'actions_catalog.dart';
import 'models.dart';

/// Estado do app + persistência local (tudo fica no aparelho).
///
/// O volume é pequeno (1 registro por dia), então guardamos tudo como JSON
/// no shared_preferences — funciona igual no Android e na web.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.settings, this._days);

  static const _daysKey = 'bonum.days.v1';
  static const _settingsKey = 'bonum.settings.v1';
  static const maxRerolls = 3;

  final SharedPreferences _prefs;
  AppSettings settings;
  final Map<String, DayEntry> _days;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = dayKey(today());

    final rawSettings = prefs.getString(_settingsKey);
    final settings = rawSettings == null
        ? AppSettings(firstDay: todayKey)
        : AppSettings.fromJson(jsonDecode(rawSettings) as Map<String, dynamic>, todayKey);

    final days = <String, DayEntry>{};
    final rawDays = prefs.getString(_daysKey);
    if (rawDays != null) {
      final map = jsonDecode(rawDays) as Map<String, dynamic>;
      map.forEach((k, v) => days[k] = DayEntry.fromJson(k, Map<String, dynamic>.from(v as Map)));
    }
    return AppState._(prefs, settings, days);
  }

  // ---------------------------------------------------------------- leitura

  /// Dias com algum registro, do mais antigo para o mais novo.
  List<DayEntry> get days {
    final list = _days.values.toList()..sort((a, b) => a.day.compareTo(b.day));
    return list;
  }

  DayEntry? existing(String day) => _days[day];

  /// Retorna o registro do dia, sorteando a boa ação se ainda não houver.
  DayEntry entry(String day) {
    final e = _days.putIfAbsent(day, () => DayEntry(day: day));
    if (e.actionId == null || !actionsById.containsKey(e.actionId)) {
      e.actionId = _pickAction(day, salt: e.rerolls, exclude: {}).id;
      _persistDays();
    }
    return e;
  }

  GoodAction actionOf(DayEntry e) => actionsById[e.actionId] ?? actionsCatalog.first;

  /// Dias seguidos com algum registro, terminando hoje (ou ontem, se hoje ainda está vazio).
  int get currentStreak {
    var d = today();
    if (!(_days[dayKey(d)]?.hasAnything ?? false)) d = addDays(d, -1);
    var count = 0;
    while (_days[dayKey(d)]?.hasAnything ?? false) {
      count++;
      d = addDays(d, -1);
    }
    return count;
  }

  /// Um bom momento de pelo menos 7 dias atrás, para relembrar na tela inicial.
  /// Muda uma vez por dia.
  ({String day, Moment moment})? memoryOfTheDay() {
    final limit = dayKey(addDays(today(), -7));
    final pool = <({String day, Moment moment})>[
      for (final e in days)
        if (e.day.compareTo(limit) <= 0)
          for (final m in e.moments) (day: e.day, moment: m),
    ];
    if (pool.isEmpty) return null;
    // Favoritos têm o dobro de chance.
    final weighted = [...pool, ...pool.where((p) => p.moment.favorite)];
    return weighted[Random(_stableHash(dayKey(today()))).nextInt(weighted.length)];
  }

  // ---------------------------------------------------------------- escrita

  bool canReroll(DayEntry e) => !e.actionDone && e.rerolls < maxRerolls;

  void reroll(String day) {
    final e = entry(day);
    if (!canReroll(e)) return;
    e.rerolls++;
    e.actionId = _pickAction(day, salt: e.rerolls, exclude: {e.actionId!}).id;
    _save();
  }

  void completeAction(String day, {String? note}) {
    final e = entry(day);
    e.actionDone = true;
    e.actionNote = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    _save();
  }

  void undoAction(String day) {
    final e = entry(day);
    e.actionDone = false;
    e.actionNote = null;
    _save();
  }

  /// Salva a boa ação própria na posição [index] (ou adiciona, se index == length).
  void saveOwnAction(String day, int index, OwnAction a) {
    final e = entry(day);
    if (index < e.ownActions.length) {
      e.ownActions[index] = a;
    } else {
      e.ownActions.add(a);
    }
    _save();
  }

  void deleteOwnAction(String day, int index) {
    final e = entry(day);
    if (index < e.ownActions.length) e.ownActions.removeAt(index);
    _save();
  }

  /// Salva o momento na posição [index] (ou adiciona, se index == length).
  void saveMoment(String day, int index, Moment m) {
    final e = entry(day);
    if (index < e.moments.length) {
      e.moments[index] = m;
    } else if (e.moments.length < DayEntry.maxMoments) {
      e.moments.add(m);
    }
    _save();
  }

  void deleteMoment(String day, int index) {
    final e = entry(day);
    if (index < e.moments.length) e.moments.removeAt(index);
    _save();
  }

  void toggleFavorite(String day, int index) {
    final e = entry(day);
    final m = e.moments[index];
    e.moments[index] = m.copyWith(favorite: !m.favorite);
    _save();
  }

  void updateSettings(void Function(AppSettings s) change) {
    change(settings);
    _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  /// Força redesenho (ex.: o dia virou com o app aberto).
  void refresh() => notifyListeners();

  // ---------------------------------------------------------------- backup

  String exportJson() => const JsonEncoder.withIndent(' ').convert({
        'app': 'bonum',
        'version': 1,
        'settings': settings.toJson(),
        'days': {for (final e in days) e.day: e.toJson()},
      });

  /// Junta os dados do backup com os atuais (nada é apagado) e retorna quantos
  /// momentos e boas ações foram adicionados. Lança FormatException se inválido.
  ///
  /// - Dia que não existe aqui: entra inteiro.
  /// - Dia que já existe: entram os momentos/ações que ainda não estão lá
  ///   (mesmo texto = repetido), respeitando o limite de 3 momentos.
  /// - Lembretes e preferências deste aparelho são mantidos; o "primeiro dia"
  ///   recua até o dia mais antigo do backup, para ele aparecer nas Memórias.
  ({int moments, int actions}) importJson(String raw) {
    final dynamic data;
    try {
      data = jsonDecode(raw.trim());
    } on FormatException {
      throw const FormatException('Este texto não parece um backup do Bonum.');
    }
    if (data is! Map || data['app'] != 'bonum') {
      throw const FormatException('Este texto não parece um backup do Bonum.');
    }

    String norm(String t) => t.trim().toLowerCase();
    var addedMoments = 0, addedActions = 0;
    final daysMap = Map<String, dynamic>.from(data['days'] as Map? ?? {});
    for (final key in daysMap.keys) {
      DateTime.parse(key); // valida a data (lança FormatException se inválida)
      final incoming = DayEntry.fromJson(key, Map<String, dynamic>.from(daysMap[key] as Map));
      final local = _days[key];
      if (local == null) {
        _days[key] = incoming;
        addedMoments += incoming.moments.length;
        addedActions += incoming.goodCount;
        continue;
      }
      if (!local.actionDone && incoming.actionDone) {
        local
          ..actionId = incoming.actionId ?? local.actionId
          ..actionDone = true
          ..actionNote = incoming.actionNote;
        addedActions++;
      }
      for (final a in incoming.ownActions) {
        if (!local.ownActions.any((x) => norm(x.text) == norm(a.text))) {
          local.ownActions.add(a);
          addedActions++;
        }
      }
      for (final m in incoming.moments) {
        if (local.moments.length >= DayEntry.maxMoments) break;
        if (!local.moments.any((x) => norm(x.text) == norm(m.text))) {
          local.moments.add(m);
          addedMoments++;
        }
      }
    }

    // Primeiro dia: o mais antigo entre o atual, o do backup e os dias importados.
    final candidates = [
      settings.firstDay,
      ...daysMap.keys,
      if (data['settings'] is Map && (data['settings'] as Map)['firstDay'] is String)
        (data['settings'] as Map)['firstDay'] as String,
    ]..sort();
    settings.firstDay = candidates.first;
    if (settings.name.isEmpty && data['settings'] is Map) {
      settings.name = ((data['settings'] as Map)['name'] as String?) ?? '';
    }
    settings.onboarded = true;
    _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

    _save();
    return (moments: addedMoments, actions: addedActions);
  }

  // ---------------------------------------------------------------- interno

  void _save() {
    _persistDays();
    notifyListeners();
  }

  void _persistDays() {
    final map = <String, dynamic>{
      for (final e in _days.values)
        if (e.hasAnything || e.actionId != null) e.day: e.toJson(),
    };
    _prefs.setString(_daysKey, jsonEncode(map));
  }

  /// Sorteio determinístico por dia (mesma sugestão se o app for reaberto),
  /// evitando repetir ações dos últimos 45 dias.
  GoodAction _pickAction(String day, {required int salt, required Set<String> exclude}) {
    final start = dayKey(addDays(parseDay(day), -45));
    final recent = {
      for (final e in _days.values)
        if (e.day != day && e.day.compareTo(start) >= 0 && e.day.compareTo(day) < 0 && e.actionId != null)
          e.actionId!,
    };
    var pool = actionsCatalog.where((a) => !recent.contains(a.id) && !exclude.contains(a.id)).toList();
    if (pool.isEmpty) pool = actionsCatalog.where((a) => !exclude.contains(a.id)).toList();
    final rnd = Random(_stableHash(day) + salt * 7919);
    return pool[rnd.nextInt(pool.length)];
  }

  static int _stableHash(String s) => s.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x3fffffff);
}

/// Disponibiliza o AppState para a árvore de widgets.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
