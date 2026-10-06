import 'package:flutter/material.dart';

import '../theme.dart';

/// Cartão base: cantos bem arredondados, borda suave, sem sombra pesada.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.color, this.padding = const EdgeInsets.all(20), this.onTap});

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: color ?? p.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color == null ? p.line : Colors.transparent),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Rótulo pequeno em caixa alta acima das seções ("FAZER O BEM").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
          color: color ?? context.palette.muted,
        ),
      );
}

/// Marca do app: folha dentro de um quadrado arredondado.
class BonumMark extends StatelessWidget {
  const BonumMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: p.sageSoft, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(Icons.eco_rounded, color: p.sage, size: size * 0.55),
    );
  }
}

/// Barra horizontal com rótulo e valor (usada nas retrospectivas).
class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.label, required this.value, required this.max, required this.color});

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.text.bodyMedium)),
              Text('$value', style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 8,
              backgroundColor: p.line,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes (web/tablet), mantendo o visual de celular.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32)});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: padding, children: children),
        ),
      );
}
