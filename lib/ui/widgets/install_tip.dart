import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../util/web_env.dart';
import '../theme.dart';
import 'common.dart';

/// Só faz sentido na web, fora do app instalado na tela inicial.
bool get shouldOfferInstall => kIsWeb && !webIsStandalone();

/// Cartão na tela Hoje: explica onde os dados ficam e sugere instalar.
class InstallTipCard extends StatelessWidget {
  const InstallTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!shouldOfferInstall || state.settings.installTipDismissed) return const SizedBox.shrink();
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.install_mobile_rounded, color: p.sage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guarde o Bonum na tela inicial',
                          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Seus registros ficam salvos neste navegador. Adicionando o Bonum à tela inicial, '
                        'ele abre como um app e seus dados ficam protegidos.',
                        style: context.text.bodySmall?.copyWith(color: p.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => state.updateSettings((s) => s.installTipDismissed = true),
                  style: TextButton.styleFrom(foregroundColor: p.muted),
                  child: const Text('Agora não'),
                ),
                TextButton(
                  onPressed: () => showInstallGuide(context),
                  child: const Text('Como fazer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Passo a passo de instalação, começando pelo aparelho da pessoa.
Future<void> showInstallGuide(BuildContext context) {
  final platform = webPlatform();
  final guides = <WebPlatform, (String, List<String>)>{
    WebPlatform.ios: (
      'iPhone ou iPad (Safari)',
      [
        'Abra o Bonum no Safari (no Chrome do iPhone também funciona).',
        'Toque no botão Compartilhar (o quadrado com a seta para cima).',
        'Role e toque em "Adicionar à Tela de Início".',
        'Toque em "Adicionar". Daqui pra frente, abra o Bonum sempre pelo ícone.',
      ],
    ),
    WebPlatform.android: (
      'Android (Chrome)',
      [
        'Toque no menu ⋮ no canto superior direito.',
        'Toque em "Instalar app" ou "Adicionar à tela inicial".',
        'Confirme. Daqui pra frente, abra o Bonum pelo ícone.',
      ],
    ),
    WebPlatform.desktop: (
      'Computador (Chrome ou Edge)',
      [
        'Clique no ícone de instalar, no canto direito da barra de endereço.',
        'Confirme em "Instalar".',
      ],
    ),
  };
  final ordered = [platform, ...WebPlatform.values.where((p) => p != platform)];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final p = context.palette;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adicionar à tela inicial',
                  style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Assim o Bonum abre como um app, sem barra do navegador, e o aparelho não apaga seus registros.',
                style: context.text.bodyMedium?.copyWith(color: p.muted),
              ),
              const SizedBox(height: 20),
              for (final (i, key) in ordered.indexed) ...[
                if (i == 1) ...[
                  const SizedBox(height: 8),
                  const SectionLabel('Outros aparelhos'),
                  const SizedBox(height: 12),
                ],
                _GuideBlock(title: guides[key]!.$1, steps: guides[key]!.$2, highlighted: i == 0),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.sunSoft, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  '💡 Os dados ficam só neste aparelho e neste navegador. Para não perder nada ao trocar de '
                  'celular, use Ajustes › Copiar backup de vez em quando.',
                  style: context.text.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _GuideBlock extends StatelessWidget {
  const _GuideBlock({required this.title, required this.steps, required this.highlighted});

  final String title;
  final List<String> steps;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SoftCard(
      color: highlighted ? p.sageSoft : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final (i, step) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.sage, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: context.text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step, style: context.text.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
