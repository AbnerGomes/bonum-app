import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../data/tags.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/day_cards.dart';
import '../widgets/install_tip.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Boa noite';
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final key = dayKey(today());
    final e = state.entry(key);
    final name = state.settings.name.trim();
    final streak = state.currentStreak;
    final memory = state.memoryOfTheDay();

    return SafeArea(
      child: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              const BonumMark(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? '${_greeting()}!' : '${_greeting()}, $name!',
                        style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(longDate(today()), style: context.text.bodyMedium?.copyWith(color: p.muted)),
                  ],
                ),
              ),
              if (streak > 1)
                Tooltip(
                  message: '$streak dias seguidos com algum registro',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: p.sageSoft, borderRadius: BorderRadius.circular(20)),
                    child: Text('🌿 $streak',
                        style: context.text.labelLarge?.copyWith(color: p.sage, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const InstallTipCard(),
          ActionCard(day: key),
          const SizedBox(height: 16),
          MomentsCard(day: key),
          if (e.didGood && e.momentsComplete) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Dia completo.\nFez o bem, percebeu o bem. ✨',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(color: p.sage, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (memory != null) ...[
            const SizedBox(height: 24),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('💭  Lembra disso?'),
                  const SizedBox(height: 10),
                  Text(
                    '${effectiveTag(memory.moment)?.emoji ?? '✨'}  ${memory.moment.text}',
                    style: context.text.bodyLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(longDate(parseDay(memory.day)), style: context.text.bodySmall?.copyWith(color: p.muted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
