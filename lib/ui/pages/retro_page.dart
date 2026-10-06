import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../data/tags.dart';
import '../../logic/retrospective.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RetroPage extends StatefulWidget {
  const RetroPage({super.key});

  @override
  State<RetroPage> createState() => _RetroPageState();
}

class _RetroPageState extends State<RetroPage> {
  Period _period = Period.containing(PeriodKind.semana, today());

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final first = parseDay(state.settings.firstDay);
    final s = RetroSummary.build(_period, state.days, state.settings.firstDay);
    final canGoBack = !_period.previous.end.isBefore(first);
    final canGoForward = !_period.next.isFuture;

    return SafeArea(
      child: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Retrospectiva', style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final k in PeriodKind.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(k.label),
                      selected: _period.kind == k,
                      showCheckmark: false,
                      selectedColor: p.sageSoft,
                      onSelected: (_) => setState(() => _period = Period.containing(k, today())),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: canGoBack ? () => setState(() => _period = _period.previous) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(_period.title,
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: canGoForward ? () => setState(() => _period = _period.next) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (s.isEmpty) _empty(context) else ..._content(context, s),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => SoftCard(
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('Ainda não há registros neste período.',
                textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Cada coisa boa que você guarda hoje vira uma lembrança aqui depois.',
                textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.palette.muted)),
          ],
        ),
      );

  List<Widget> _content(BuildContext context, RetroSummary s) {
    final p = context.palette;
    final isYear = s.period.kind == PeriodKind.ano;
    final maxTag = s.tagCounts.values.fold(0, (a, b) => a > b ? a : b);
    final maxTarget = s.targetCounts.values.fold(0, (a, b) => a > b ? a : b);

    return [
      // ------------------------------------------------ destaque
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.sage, Color.lerp(p.sage, p.sun, 0.55)!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isYear)
              Text('Seu ${s.period.start.year}',
                  style: context.text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            Text(
              '${s.moments}',
              style: context.text.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            Text(
              isYear
                  ? (s.moments == 1
                      ? 'coisa boa que você provavelmente teria esquecido.'
                      : 'coisas boas que você provavelmente teria esquecido.')
                  : '${s.moments == 1 ? 'coisa boa registrada' : 'coisas boas registradas'} ${s.period.thisLabel}.',
              style: context.text.titleMedium?.copyWith(color: Colors.white, height: 1.3),
            ),
            const SizedBox(height: 16),
            Text(
              '🌱 E você fez ${s.actionsDone} ${s.actionsDone == 1 ? 'boa ação' : 'boas ações'}.',
              style: context.text.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ------------------------------------------------ números
      Row(
        children: [
          Expanded(child: _Tile(value: '${s.daysWithRecord}', label: 'de ${s.elapsedDays} dias\ncom registro')),
          const SizedBox(width: 10),
          Expanded(child: _Tile(value: '${s.bestStreak}', label: 'dias seguidos,\nmelhor sequência')),
          const SizedBox(width: 10),
          Expanded(child: _Tile(value: '${s.actionsDone}', label: 'boas ações\nrealizadas')),
        ],
      ),
      if (s.actionsMissed > 0) ...[
        const SizedBox(height: 8),
        Text(
          '${s.actionsMissed} ${s.actionsMissed == 1 ? 'dia ficou' : 'dias ficaram'} sem boa ação marcada — tudo bem, todo dia tem uma nova.',
          style: context.text.bodySmall?.copyWith(color: p.muted),
        ),
      ],

      // ------------------------------------------------ melhores momentos
      if (s.highlights.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionLabel('Alguns dos seus melhores momentos'),
        const SizedBox(height: 10),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            children: [
              for (final h in s.highlights)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(effectiveTag(h.moment)?.emoji ?? '✨', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.moment.text, style: context.text.bodyLarge),
                            Text(shortDate(parseDay(h.day)), style: context.text.bodySmall?.copyWith(color: p.muted)),
                          ],
                        ),
                      ),
                      if (h.moment.favorite) Icon(Icons.star_rounded, color: p.sun, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],

      // ------------------------------------------------ temas dos momentos
      if (s.tagCounts.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionLabel('Do que foram feitos seus bons momentos'),
        const SizedBox(height: 10),
        SoftCard(
          child: Column(
            children: [
              for (final t in s.tagCounts.entries.take(6))
                StatBar(label: '${t.key.emoji}  ${t.key.label}', value: t.value, max: maxTag, color: p.sun),
            ],
          ),
        ),
      ],

      // ------------------------------------------------ para quem foram as ações
      if (s.targetCounts.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionLabel('Para quem foram suas boas ações'),
        const SizedBox(height: 10),
        SoftCard(
          child: Column(
            children: [
              for (final t in s.targetCounts.entries)
                StatBar(label: '${t.key.emoji}  ${t.key.label}', value: t.value, max: maxTarget, color: p.sage),
            ],
          ),
        ),
      ],

      // ------------------------------------------------ notas das ações
      if (s.actionNotes.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionLabel('O que você contou sobre o bem que fez'),
        const SizedBox(height: 10),
        for (final n in s.actionNotes) ...[
          SoftCard(
            color: p.sageSoft,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('“${n.quote}”', style: context.text.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Text('${shortDate(parseDay(n.day))} · ${n.caption}',
                    style: context.text.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: context.text.labelSmall?.copyWith(color: context.palette.muted, height: 1.25)),
          ],
        ),
      );
}
