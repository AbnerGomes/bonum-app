import 'dart:math';

import 'package:intl/intl.dart';

import '../data/actions_catalog.dart';
import '../data/models.dart';
import '../data/tags.dart';
import '../util/dates.dart';

enum PeriodKind {
  semana('Semana'),
  mes('Mês'),
  trimestre('Trimestre'),
  semestre('Semestre'),
  ano('Ano');

  const PeriodKind(this.label);
  final String label;
}

class Period {
  Period._(this.kind, this.start, this.end);

  final PeriodKind kind;
  final DateTime start;

  /// Inclusivo.
  final DateTime end;

  factory Period.containing(PeriodKind kind, DateTime d) {
    switch (kind) {
      case PeriodKind.semana:
        final s = addDays(dateOnly(d), -(d.weekday - 1)); // segunda-feira
        return Period._(kind, s, addDays(s, 6));
      case PeriodKind.mes:
        return Period._(kind, DateTime(d.year, d.month), DateTime(d.year, d.month + 1, 0));
      case PeriodKind.trimestre:
        final m = ((d.month - 1) ~/ 3) * 3 + 1;
        return Period._(kind, DateTime(d.year, m), DateTime(d.year, m + 3, 0));
      case PeriodKind.semestre:
        final m = d.month <= 6 ? 1 : 7;
        return Period._(kind, DateTime(d.year, m), DateTime(d.year, m + 6, 0));
      case PeriodKind.ano:
        return Period._(kind, DateTime(d.year), DateTime(d.year, 12, 31));
    }
  }

  Period get previous => Period.containing(kind, addDays(start, -1));
  Period get next => Period.containing(kind, addDays(end, 1));
  bool get isCurrent => !today().isBefore(start) && !today().isAfter(end);
  bool get isFuture => start.isAfter(today());

  String get title {
    switch (kind) {
      case PeriodKind.semana:
        return '${shortDate(start)} – ${shortDate(end)}';
      case PeriodKind.mes:
        return capitalize(DateFormat("MMMM 'de' y", 'pt_BR').format(start));
      case PeriodKind.trimestre:
        return '${(start.month - 1) ~/ 3 + 1}º trimestre de ${start.year}';
      case PeriodKind.semestre:
        return '${start.month == 1 ? 1 : 2}º semestre de ${start.year}';
      case PeriodKind.ano:
        return '${start.year}';
    }
  }

  /// "esta semana", "este mês"... usado nos textos do resumo.
  String get thisLabel {
    if (!isCurrent) return 'neste período';
    switch (kind) {
      case PeriodKind.semana:
        return 'esta semana';
      case PeriodKind.mes:
        return 'este mês';
      case PeriodKind.trimestre:
        return 'neste trimestre';
      case PeriodKind.semestre:
        return 'neste semestre';
      case PeriodKind.ano:
        return 'este ano';
    }
  }
}

typedef DatedMoment = ({String day, Moment moment});

class RetroSummary {
  RetroSummary({
    required this.period,
    required this.elapsedDays,
    required this.daysWithRecord,
    required this.moments,
    required this.actionsDone,
    required this.actionsMissed,
    required this.tagCounts,
    required this.targetCounts,
    required this.bestStreak,
    required this.highlights,
    required this.actionNotes,
  });

  final Period period;

  /// Dias do período já vividos com o app (desde o primeiro uso até hoje).
  final int elapsedDays;
  final int daysWithRecord;
  final int moments;
  final int actionsDone;
  final int actionsMissed;
  final Map<MomentTag, int> tagCounts;
  final Map<ActionTarget, int> targetCounts;
  final int bestStreak;
  final List<DatedMoment> highlights;
  /// Relatos do bem feito: notas das sugestões e as ações próprias.
  final List<({String day, String quote, String caption})> actionNotes;

  bool get isEmpty => moments == 0 && actionsDone == 0;

  static RetroSummary build(Period p, List<DayEntry> allDays, String firstDay) {
    final startKey = dayKey(p.start);
    final endKey = dayKey(p.end);
    final todayKey = dayKey(today());
    final inPeriod = allDays.where((e) => e.day.compareTo(startKey) >= 0 && e.day.compareTo(endKey) <= 0).toList();
    final byDay = {for (final e in inPeriod) e.day: e};

    // Dias "vividos": de max(início, primeiro uso) até min(fim, hoje).
    var from = p.start;
    final first = parseDay(firstDay);
    if (first.isAfter(from)) from = first;
    var to = p.end;
    if (today().isBefore(to)) to = today();
    var elapsed = 0, missed = 0, streak = 0, best = 0;
    for (var d = from; !d.isAfter(to); d = addDays(d, 1)) {
      elapsed++;
      final e = byDay[dayKey(d)];
      // Hoje ainda não acabou: não conta como ação não feita.
      if (!(e?.didGood ?? false) && dayKey(d) != todayKey) missed++;
      if (e?.hasAnything ?? false) {
        streak++;
        best = max(best, streak);
      } else {
        streak = 0;
      }
    }

    final tagCounts = <MomentTag, int>{};
    final targetCounts = <ActionTarget, int>{};
    final all = <DatedMoment>[];
    final notes = <({String day, String quote, String caption})>[];
    var done = 0;
    for (final e in inPeriod) {
      for (final m in e.moments) {
        all.add((day: e.day, moment: m));
        final t = effectiveTag(m);
        if (t != null) tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
      if (e.actionDone) {
        done++;
        final a = actionsById[e.actionId];
        if (a != null) {
          targetCounts[a.target] = (targetCounts[a.target] ?? 0) + 1;
          if (e.actionNote != null) notes.add((day: e.day, quote: e.actionNote!, caption: a.text));
        }
      }
      for (final own in e.ownActions) {
        done++;
        targetCounts[own.target] = (targetCounts[own.target] ?? 0) + 1;
        notes.add((day: e.day, quote: own.text, caption: '${own.target.emoji} ${own.target.label} · por conta própria'));
      }
    }

    return RetroSummary(
      period: p,
      elapsedDays: elapsed,
      daysWithRecord: inPeriod.where((e) => e.hasAnything).length,
      moments: all.length,
      actionsDone: done,
      actionsMissed: missed,
      tagCounts: _sorted(tagCounts),
      targetCounts: _sorted(targetCounts),
      bestStreak: best,
      highlights: _highlights(all, p),
      actionNotes: notes.reversed.take(5).toList(),
    );
  }

  /// Favoritos primeiro; completa com momentos sorteados (sorteio fixo por período).
  static List<DatedMoment> _highlights(List<DatedMoment> all, Period p) {
    final count = p.kind == PeriodKind.semana ? 3 : (p.kind == PeriodKind.ano ? 8 : 5);
    final favs = all.where((m) => m.moment.favorite).toList()..shuffle(Random(p.start.millisecondsSinceEpoch));
    final others = all.where((m) => !m.moment.favorite).toList()..shuffle(Random(p.start.millisecondsSinceEpoch));
    final picked = [...favs, ...others].take(count).toList()..sort((a, b) => a.day.compareTo(b.day));
    return picked;
  }

  static Map<K, int> _sorted<K>(Map<K, int> m) =>
      Map.fromEntries(m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
}
