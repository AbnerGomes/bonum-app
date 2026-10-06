import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../services/notifications.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Primeira abertura: apresenta a ideia em 10 segundos e pede só o nome (opcional).
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final state = AppScope.read(context);
    await NotificationService.requestPermission();
    state.updateSettings((s) {
      s.name = _name.text.trim();
      s.onboarded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
          children: [
            const Center(child: BonumMark(size: 84)),
            const SizedBox(height: 20),
            Text('Bonum',
                textAlign: TextAlign.center,
                style: context.text.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: p.sage)),
            const SizedBox(height: 4),
            Text('Faça o bem. Perceba o bem.',
                textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(color: p.muted)),
            const SizedBox(height: 36),
            _Pillar(
              emoji: '🌱',
              color: p.sageSoft,
              title: 'Uma boa ação por dia',
              text: 'Uma sugestão pequena e concreta — para alguém ou para você mesmo.',
            ),
            const SizedBox(height: 12),
            _Pillar(
              emoji: '☀️',
              color: p.sunSoft,
              title: 'Três coisas boas',
              text: 'No fim do dia, anote três coisas boas que aconteceram. Leva 30 segundos.',
            ),
            const SizedBox(height: 12),
            _Pillar(
              emoji: '✨',
              color: p.card,
              title: 'Retrospectivas',
              text: 'Semana, mês, trimestre, semestre e ano: tudo de bom que você teria esquecido.',
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _start(),
              decoration: const InputDecoration(hintText: 'Como podemos te chamar? (opcional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _start, child: const Text('Começar')),
          ],
        ),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.emoji, required this.color, required this.title, required this.text});

  final String emoji;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => SoftCard(
        color: color,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(text, style: context.text.bodyMedium?.copyWith(color: context.palette.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}
