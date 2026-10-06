import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../data/store.dart';
import '../../data/tags.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/day_cards.dart';

/// Memórias: calendário do mês (cada dia colorido pela intensidade) + lista dos dias.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _month = DateTime(today().year, today().month);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final first = parseDay(state.settings.firstDay);
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final isCurrentMonth = _month.year == today().year && _month.month == today().month;
    final canGoBack = _month.isAfter(DateTime(first.year, first.month));

    // Dias do mês já vividos com o app, do mais recente para o mais antigo.
    final visibleDays = <DateTime>[
      for (var d = lastDay; !d.isBefore(_month); d = addDays(d, -1))
        if (!d.isAfter(today()) && !d.isBefore(first)) d,
    ];

    return SafeArea(
      child: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Memórias', style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: canGoBack ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        capitalize(DateFormat("MMMM 'de' y", 'pt_BR').format(_month)),
                        textAlign: TextAlign.center,
                        style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: isCurrentMonth ? null : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _MonthGrid(month: _month, state: state, first: first),
                const SizedBox(height: 12),
                _Legend(palette: p),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (visibleDays.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Nenhum dia por aqui ainda.',
                  textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: p.muted)),
            ),
          for (final d in visibleDays) ...[
            _DayTile(date: d, entry: state.existing(dayKey(d))),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

void openDay(BuildContext context, DateTime d) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DayPage(day: dayKey(d))));
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.state, required this.first});

  final DateTime month;
  final AppState state;
  final DateTime first;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = month.weekday - 1; // semana começa na segunda
    const weekdays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Column(
      children: [
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(child: Text(w, style: context.text.labelSmall?.copyWith(color: p.muted))),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < offset; i++) const SizedBox(),
            for (var day = 1; day <= daysInMonth; day++) _cell(context, DateTime(month.year, month.month, day)),
          ],
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, DateTime d) {
    final p = context.palette;
    final e = state.existing(dayKey(d));
    final usable = !d.isAfter(today()) && !d.isBefore(first);
    final level = e?.intensity ?? 0;
    final isToday = d == today();
    final bg = level == 0 ? Colors.transparent : Color.lerp(p.sageSoft, p.sage, (level / 4) * 0.85)!;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: usable ? () => openDay(context, d) : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: p.sun, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${d.day}',
          style: context.text.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: !usable ? p.muted.withValues(alpha: 0.4) : (level >= 3 ? Colors.white : p.ink),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.palette});

  final BonumPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('menos', style: context.text.labelSmall?.copyWith(color: palette.muted)),
        const SizedBox(width: 6),
        for (var l = 0; l <= 4; l++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: l == 0 ? palette.line : Color.lerp(palette.sageSoft, palette.sage, (l / 4) * 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        const SizedBox(width: 6),
        Text('mais', style: context.text.labelSmall?.copyWith(color: palette.muted)),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.date, required this.entry});

  final DateTime date;
  final DayEntry? entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final e = entry;
    final state = AppScope.read(context);
    final isToday = date == today();

    return SoftCard(
      padding: const EdgeInsets.all(16),
      onTap: () => openDay(context, date),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isToday ? 'Hoje' : longDate(date), style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (e == null || !e.hasAnything)
            Text(isToday ? 'Ainda dá tempo. 🌱' : 'Dia sem registro.',
                style: context.text.bodyMedium?.copyWith(color: p.muted))
          else ...[
            if (e.actionDone) _line(context, '🌱', state.actionOf(e).text, p.sage),
            for (final own in e.ownActions) _line(context, '🌱', own.text, p.sage),
            if (!e.didGood && !isToday) _line(context, '○', 'Boa ação não realizada', p.muted),
            for (final m in e.moments) _line(context, effectiveTag(m)?.emoji ?? '✨', m.text, null, star: m.favorite),
          ],
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String emoji, String text, Color? color, {bool star = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 26, child: Text(emoji)),
            Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: color))),
            if (star) Icon(Icons.star_rounded, size: 16, color: context.palette.sun),
          ],
        ),
      );
}

/// Um dia específico, editável (esqueceu de anotar ontem? dá para completar).
class DayPage extends StatelessWidget {
  const DayPage({super.key, required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(day == dayKey(today()) ? 'Hoje' : longDate(parseDay(day)))),
      body: PageBody(
        children: [
          ActionCard(day: day),
          const SizedBox(height: 16),
          MomentsCard(day: day),
        ],
      ),
    );
  }
}
