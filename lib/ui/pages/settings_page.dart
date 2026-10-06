import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../services/notifications.dart';
import '../../util/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/install_tip.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.settings;
    final p = context.palette;
    final canNotify = NotificationService.supported;

    return SafeArea(
      child: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Ajustes', style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          const SectionLabel('Você'),
          const SizedBox(height: 8),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Como podemos te chamar?'),
              subtitle: Text(s.name.isEmpty ? 'Toque para definir' : s.name),
              onTap: () => _editName(context, state),
            ),
          ),
          const SizedBox(height: 24),

          const SectionLabel('Lembretes'),
          const SizedBox(height: 8),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: s.remindersOn,
                  onChanged: (v) async {
                    if (v) await NotificationService.requestPermission();
                    state.updateSettings((s) => s.remindersOn = v);
                  },
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Lembretes diários'),
                  subtitle: canNotify ? null : const Text('Disponível no app Android'),
                ),
                if (s.remindersOn) ...[
                  const Divider(indent: 16, endIndent: 16),
                  _ReminderTile(
                    emoji: '🌱',
                    title: 'Boa ação do dia',
                    enabled: s.actionReminder,
                    minutes: s.actionMinutes,
                    onToggle: (v) => state.updateSettings((s) => s.actionReminder = v),
                    onTime: (m) => state.updateSettings((s) => s.actionMinutes = m),
                  ),
                  _ReminderTile(
                    emoji: '☀️',
                    title: '3 coisas boas',
                    enabled: s.momentsReminder,
                    minutes: s.momentsMinutes,
                    onToggle: (v) => state.updateSettings((s) => s.momentsReminder = v),
                    onTime: (m) => state.updateSettings((s) => s.momentsMinutes = m),
                  ),
                  if (canNotify) ...[
                    const _PermissionStatus(),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.send_outlined),
                      title: const Text('Testar: notificação agora'),
                      onTap: () async {
                        await NotificationService.requestPermission();
                        await NotificationService.showTest();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Testar: lembrete agendado'),
                      subtitle: const Text('Chega em 1 minuto (pode fechar o app)'),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await NotificationService.requestPermission();
                        try {
                          await NotificationService.scheduleTest();
                          messenger.showSnackBar(const SnackBar(content: Text('Agendado! Aguarde 1 minuto. ⏰')));
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text('Não foi possível agendar: $e')));
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              'Se você já tiver feito aquilo no dia, o lembrete daquele dia não aparece.',
              style: context.text.bodySmall?.copyWith(color: p.muted),
            ),
          ),
          const SizedBox(height: 24),

          const SectionLabel('Seus dados'),
          const SizedBox(height: 8),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                if (shouldOfferInstall)
                  ListTile(
                    leading: const Icon(Icons.install_mobile_rounded),
                    title: const Text('Adicionar à tela inicial'),
                    subtitle: const Text('Abre como app e protege seus dados'),
                    onTap: () => showInstallGuide(context),
                  ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Copiar backup'),
                  subtitle: const Text('Copia tudo como texto para você guardar onde quiser'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: state.exportJson()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Backup copiado para a área de transferência.')));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore_rounded),
                  title: const Text('Restaurar backup'),
                  subtitle: const Text('Cole o texto de um backup (junta com os dados atuais)'),
                  onTap: () => _restore(context, state),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              kIsWeb
                  ? 'Tudo fica só neste navegador, neste aparelho. Nada é enviado para servidores.'
                  : 'Tudo fica só no seu aparelho. Nada é enviado para servidores.',
              style: context.text.bodySmall?.copyWith(color: p.muted),
            ),
          ),
          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                const BonumMark(size: 48),
                const SizedBox(height: 10),
                Text('Bonum', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: p.sage)),
                Text('Do latim: o bem.', style: context.text.bodySmall?.copyWith(color: p.muted)),
                Text('Faça o bem. Perceba o bem.', style: context.text.bodySmall?.copyWith(color: p.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final ctrl = TextEditingController(text: state.settings.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seu nome'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Como prefere ser chamado'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (name != null) state.updateSettings((s) => s.name = name);
  }

  Future<void> _restore(BuildContext context, AppState state) async {
    final ctrl = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Os dados do backup são juntados aos atuais. Nada é apagado e repetidos são ignorados.'),
            const SizedBox(height: 12),
            TextField(controller: ctrl, minLines: 4, maxLines: 8, decoration: const InputDecoration(hintText: 'Cole aqui')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Restaurar')),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = state.importJson(raw);
      messenger.showSnackBar(SnackBar(
          content: Text('Importado: ${r.moments} ${r.moments == 1 ? 'momento' : 'momentos'} e '
              '${r.actions} ${r.actions == 1 ? 'boa ação' : 'boas ações'}. 🌱')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is FormatException ? e.message : 'Backup inválido.')));
    }
  }
}

/// Avisa (e ajuda a corrigir) quando o Android está bloqueando os lembretes.
class _PermissionStatus extends StatelessWidget {
  const _PermissionStatus();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final warn = Theme.of(context).colorScheme.error;
    return ListenableBuilder(
      listenable: Listenable.merge([NotificationService.notificationsAllowed, NotificationService.exactAllowed]),
      builder: (context, _) {
        final allowed = NotificationService.notificationsAllowed.value;
        final exact = NotificationService.exactAllowed.value;
        if (allowed && exact) {
          return ListTile(
            leading: Icon(Icons.verified_outlined, color: p.sage),
            title: const Text('Lembretes ativos'),
            subtitle: const Text('Vão chegar no horário exato'),
          );
        }
        return Column(
          children: [
            if (!allowed)
              ListTile(
                leading: Icon(Icons.notifications_off_outlined, color: warn),
                title: const Text('Notificações bloqueadas'),
                subtitle: const Text(
                    'Toque para permitir. Se nada acontecer, libere em Configurações do Android › Apps › Bonum › Notificações.'),
                onTap: NotificationService.requestPermission,
              ),
            if (!exact)
              ListTile(
                leading: Icon(Icons.alarm_outlined, color: p.sun),
                title: const Text('Permitir horário exato'),
                subtitle: const Text(
                    'Sem isso, o Android pode atrasar os lembretes. Toque e ative "Alarmes e lembretes" para o Bonum.'),
                onTap: NotificationService.requestExactPermission,
              ),
          ],
        );
      },
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.emoji,
    required this.title,
    required this.enabled,
    required this.minutes,
    required this.onToggle,
    required this.onTime,
  });

  final String emoji;
  final String title;
  final bool enabled;
  final int minutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onTime;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(width: 24, child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
      title: Text(title),
      subtitle: Text(enabled ? 'Todos os dias às ${formatMinutes(minutes)}' : 'Desligado'),
      onTap: enabled
          ? () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
              );
              if (t != null) onTime(t.hour * 60 + t.minute);
            }
          : null,
      trailing: Switch(value: enabled, onChanged: onToggle),
    );
  }
}
