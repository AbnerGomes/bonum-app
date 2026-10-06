import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/store.dart';
import '../../data/tags.dart';
import '../../util/dates.dart';
import '../theme.dart';
import 'common.dart';

// ============================================================ Fazer o bem

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.day});

  final String day;

  bool get _isToday => day == dayKey(today());

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final e = state.entry(day);
    final action = state.actionOf(e);
    final p = context.palette;

    return SoftCard(
      color: p.sageSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionLabel('🌱  Fazer o bem', color: p.sage),
              const Spacer(),
              _TargetChip(target: action.target),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            action.text,
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: e.actionDone ? _done(context, state, e) : _pending(context, state, e),
          ),
          if (e.ownActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < e.ownActions.length; i++) ...[
              _OwnActionTile(action: e.ownActions[i], onTap: () => _editOwn(context, state, i, e.ownActions[i])),
              const SizedBox(height: 8),
            ],
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _editOwn(context, state, e.ownActions.length, null),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(e.ownActions.isEmpty && !e.actionDone ? 'Fiz outra boa ação' : 'Registrar outra boa ação'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editOwn(BuildContext context, AppState state, int index, OwnAction? current) async {
    final result = await showModalBottomSheet<_OwnActionResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OwnActionSheet(initial: current),
    );
    if (result == null) return;
    if (result.delete) {
      state.deleteOwnAction(day, index);
    } else if (result.action != null) {
      state.saveOwnAction(day, index, result.action!);
    }
  }

  Widget _pending(BuildContext context, AppState state, DayEntry e) {
    final p = context.palette;
    final isPast = day.compareTo(dayKey(today())) < 0;
    return Column(
      key: const ValueKey('pending'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPast && !e.didGood)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Não marcada como feita.', style: context.text.bodySmall?.copyWith(color: p.muted)),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _markDone(context, state, e),
                icon: const Icon(Icons.check_rounded),
                label: Text(_isToday ? 'Fiz hoje' : 'Fiz neste dia'),
              ),
            ),
            if (_isToday && state.canReroll(e)) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => state.reroll(day),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text('Outra (${AppState.maxRerolls - e.rerolls})'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _done(BuildContext context, AppState state, DayEntry e) {
    final p = context.palette;
    return Column(
      key: const ValueKey('done'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: p.sage),
            const SizedBox(width: 8),
            Text('Feito! Obrigado por isso.',
                style: context.text.titleSmall?.copyWith(color: p.sage, fontWeight: FontWeight.w700)),
          ],
        ),
        if (e.actionNote != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.card.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16)),
            child: Text('“${e.actionNote}”', style: context.text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          ),
        ],
        const SizedBox(height: 4),
        Wrap(
          children: [
            TextButton(
              onPressed: () => _markDone(context, state, e),
              child: Text(e.actionNote == null ? 'Contar como foi' : 'Editar nota'),
            ),
            TextButton(
              onPressed: () => state.undoAction(day),
              style: TextButton.styleFrom(foregroundColor: p.muted),
              child: const Text('Desfazer'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _markDone(BuildContext context, AppState state, DayEntry e) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NoteSheet(initial: e.actionNote ?? ''),
    );
    if (note != null) state.completeAction(day, note: note);
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.target});

  final ActionTarget target;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: context.palette.card, borderRadius: BorderRadius.circular(20)),
        child: Text('${target.emoji} ${target.label}', style: context.text.labelSmall),
      );
}

class _OwnActionTile extends StatelessWidget {
  const _OwnActionTile({required this.action, required this.onTap});

  final OwnAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: p.sage, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.text, style: context.text.bodyLarge),
                    const SizedBox(height: 2),
                    Text('${action.target.emoji} ${action.target.label} · por conta própria',
                        style: context.text.bodySmall?.copyWith(color: p.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnActionResult {
  const _OwnActionResult({this.action, this.delete = false});

  final OwnAction? action;
  final bool delete;
}

class _OwnActionSheet extends StatefulWidget {
  const _OwnActionSheet({this.initial});

  final OwnAction? initial;

  @override
  State<_OwnActionSheet> createState() => _OwnActionSheetState();
}

class _OwnActionSheetState extends State<_OwnActionSheet> {
  late final _ctrl = TextEditingController(text: widget.initial?.text ?? '');
  late ActionTarget? _target = widget.initial?.target;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final editing = widget.initial != null;
    return _SheetFrame(
      title: editing ? 'Editar boa ação' : 'Uma boa ação sua 🌱',
      subtitle: 'Fez algo bom que não estava na sugestão? Isso também conta.',
      children: [
        TextField(
          controller: _ctrl,
          autofocus: !editing,
          minLines: 2,
          maxLines: 4,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: ajudei um vizinho a carregar as compras.'),
        ),
        Text('Para quem foi?', style: context.text.labelLarge?.copyWith(color: p.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in ActionTarget.values)
              ChoiceChip(
                label: Text('${t.emoji} ${t.label}'),
                selected: _target == t,
                showCheckmark: false,
                selectedColor: p.sageSoft,
                onSelected: (sel) => setState(() => _target = sel ? t : null),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) => FilledButton(
            onPressed: _ctrl.text.trim().isEmpty || _target == null
                ? null
                : () => Navigator.pop(
                      context,
                      _OwnActionResult(action: OwnAction(text: _ctrl.text.trim(), target: _target!)),
                    ),
            child: const Text('Guardar'),
          ),
        ),
        if (editing)
          TextButton(
            onPressed: () => Navigator.pop(context, const _OwnActionResult(delete: true)),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Excluir'),
          ),
      ],
    );
  }
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.initial});

  final String initial;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Como foi? 🌱',
      subtitle: 'Opcional. Uma frase já basta para lembrar disso depois.',
      children: [
        TextField(
          controller: _ctrl,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 280,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: liguei para minha avó e ela ficou muito feliz.'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// ============================================================ Perceber o bem

class MomentsCard extends StatelessWidget {
  const MomentsCard({super.key, required this.day});

  final String day;

  static const _prompts = [
    'O que te fez sorrir hoje?',
    'Alguém foi gentil com você?',
    'Uma pequena vitória?',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final e = state.entry(day);
    final p = context.palette;
    final isToday = day == dayKey(today());

    return SoftCard(
      color: p.sunSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionLabel('☀️  Perceber o bem', color: p.sun),
              const Spacer(),
              Text('${e.moments.length}/${DayEntry.maxMoments}',
                  style: context.text.labelMedium?.copyWith(color: p.sun, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isToday ? 'Três coisas boas de hoje' : 'Três coisas boas do dia',
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < DayEntry.maxMoments; i++) ...[
            if (i < e.moments.length)
              _MomentTile(
                moment: e.moments[i],
                onTap: () => _edit(context, state, i, e.moments[i]),
                onStar: () => state.toggleFavorite(day, i),
              )
            else
              _EmptySlot(
                text: _prompts[i],
                active: i == e.moments.length,
                onTap: i == e.moments.length ? () => _edit(context, state, i, null) : null,
              ),
            if (i < DayEntry.maxMoments - 1) const SizedBox(height: 8),
          ],
          if (e.momentsComplete) ...[
            const SizedBox(height: 14),
            Text('Guardado. Daqui a um tempo você vai gostar de reler isso. ✨',
                style: context.text.bodySmall?.copyWith(color: p.muted)),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, AppState state, int index, Moment? current) async {
    final result = await showModalBottomSheet<_MomentResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MomentSheet(initial: current),
    );
    if (result == null) return;
    if (result.delete) {
      state.deleteMoment(day, index);
    } else if (result.moment != null) {
      state.saveMoment(day, index, result.moment!);
    }
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.moment, required this.onTap, required this.onStar});

  final Moment moment;
  final VoidCallback onTap;
  final VoidCallback onStar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tag = effectiveTag(moment);
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              Text(tag?.emoji ?? '✨', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(moment.text, style: context.text.bodyLarge)),
              IconButton(
                onPressed: onStar,
                tooltip: moment.favorite ? 'Desmarcar momento especial' : 'Marcar como momento especial',
                icon: Icon(
                  moment.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: moment.favorite ? p.sun : p.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.text, required this.active, this.onTap});

  final String text;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Opacity(
      opacity: active ? 1 : 0.45,
      child: Material(
        color: p.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.add_rounded, color: p.sun),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: context.text.bodyLarge?.copyWith(color: p.muted))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MomentResult {
  const _MomentResult({this.moment, this.delete = false});

  final Moment? moment;
  final bool delete;
}

class _MomentSheet extends StatefulWidget {
  const _MomentSheet({this.initial});

  final Moment? initial;

  @override
  State<_MomentSheet> createState() => _MomentSheetState();
}

class _MomentSheetState extends State<_MomentSheet> {
  late final _ctrl = TextEditingController(text: widget.initial?.text ?? '');
  late MomentTag? _tag = widget.initial?.tag;
  late bool _favorite = widget.initial?.favorite ?? false;

  /// Enquanto a pessoa não escolhe um tema, sugerimos um pelo texto.
  late bool _tagTouched = widget.initial?.tag != null;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (!_tagTouched) setState(() => _tag = guessTag(_ctrl.text));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final editing = widget.initial != null;
    return _SheetFrame(
      title: editing ? 'Editar momento' : 'Uma coisa boa ☀️',
      subtitle: 'Pode ser bem pequena: um café, uma conversa, um pôr do sol.',
      children: [
        TextField(
          controller: _ctrl,
          autofocus: !editing,
          minLines: 2,
          maxLines: 4,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: tomei café com a Ana.'),
        ),
        Text('Tema (opcional)', style: context.text.labelLarge?.copyWith(color: p.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in MomentTag.values)
              ChoiceChip(
                label: Text('${t.emoji} ${t.label}'),
                selected: _tag == t,
                showCheckmark: false,
                selectedColor: p.sunSoft,
                onSelected: (sel) => setState(() {
                  _tagTouched = true;
                  _tag = sel ? t : null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _favorite,
          onChanged: (v) => setState(() => _favorite = v),
          title: const Text('Momento especial'),
          subtitle: const Text('Aparece em destaque nas retrospectivas'),
          secondary: Icon(_favorite ? Icons.star_rounded : Icons.star_outline_rounded, color: p.sun),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) => FilledButton(
            onPressed: _ctrl.text.trim().isEmpty
                ? null
                : () => Navigator.pop(
                      context,
                      _MomentResult(moment: Moment(text: _ctrl.text.trim(), tag: _tag, favorite: _favorite)),
                    ),
            child: const Text('Guardar'),
          ),
        ),
        if (editing)
          TextButton(
            onPressed: () => Navigator.pop(context, const _MomentResult(delete: true)),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Excluir'),
          ),
      ],
    );
  }
}

// ============================================================ moldura dos sheets

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, this.subtitle, required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: context.palette.muted)),
            ],
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}
