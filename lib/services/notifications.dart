import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/store.dart';
import '../util/dates.dart';

/// Lembretes diários locais (sem servidor).
///
/// Em vez de uma notificação repetida com sempre o mesmo texto, agendamos os
/// próximos [_daysAhead] dias individualmente, cada um com uma frase diferente.
/// O agendamento é refeito sempre que o app abre ou algo muda — e o lembrete de
/// hoje é pulado se a pessoa já fez aquilo.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _daysAhead = 30;
  static const _testId = 1;
  static const _scheduledTestId = 2;
  static bool _ready = false;

  /// Status atual, exibido em Ajustes (atualizado a cada reagendamento).
  static final notificationsAllowed = ValueNotifier<bool>(true);
  static final exactAllowed = ValueNotifier<bool>(true);

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Incrementa a cada reagendamento; uma execução antiga para se outra começou.
  static int _generation = 0;

  /// Notificações só existem no Android por enquanto (na web o app roda sem elas).
  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'bonum_daily',
      'Lembretes diários',
      channelDescription: 'Lembretes da boa ação e das 3 coisas boas',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_bonum',
      color: Color(0xFF4F7F5F),
    ),
  );

  static const _actionMessages = [
    ('🌱 Sua boa ação de hoje', 'Já viu o que o dia de hoje te propõe?'),
    ('🌱 Um pequeno bem', 'Uma ação simples está esperando por você hoje.'),
    ('🌱 Bom dia!', 'Que tal começar o dia fazendo o bem para alguém?'),
    ('🌱 Faça o bem', 'Sua sugestão de hoje leva poucos minutos.'),
    ('🌱 Hoje é um bom dia', 'Para fazer algo bom — inclusive por você.'),
  ];

  static const _momentsMessages = [
    ('☀️ O que houve de bom hoje?', 'Guarde 3 coisas boas antes de dormir.'),
    ('☀️ Perceba o bem', 'Três coisas boas. Trinta segundos.'),
    ('☀️ Antes que o dia acabe', 'Não deixe as coisas boas de hoje se perderem.'),
    ('☀️ Um minuto para você', 'Qual foi o melhor momento do seu dia?'),
    ('☀️ Ajudou alguém hoje?', 'Ou alguém te ajudou? Anote no Bonum.'),
    ('☀️ Hoje valeu', 'Registre as pequenas coisas que fizeram seu dia.'),
  ];

  /// Nunca lança: se algo falhar, o app abre normalmente, só que sem lembretes.
  static Future<void> init() async {
    if (!supported) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      }
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_bonum')),
      );
      _ready = true;
      await _refreshStatus();
    } catch (e) {
      debugPrint('Bonum: falha ao iniciar notificações: $e');
    }
  }

  /// Pede permissão de notificações (Android 13+). Retorna true se concedida.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final granted = await _android?.requestNotificationsPermission() ?? false;
      await _refreshStatus();
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Abre a tela do sistema para liberar "Alarmes e lembretes" (horário exato).
  /// Necessário no Android 14+, onde vem desligado por padrão.
  static Future<void> requestExactPermission() async {
    if (!_ready) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
    await _refreshStatus();
  }

  static Future<void> _refreshStatus() async {
    final android = _android;
    if (android == null) return;
    try {
      notificationsAllowed.value = await android.areNotificationsEnabled() ?? true;
      exactAllowed.value = await android.canScheduleExactNotifications() ?? false;
    } catch (_) {}
  }

  /// Exato quando permitido (chega no minuto certo, mesmo com o celular parado);
  /// senão inexato (o Android pode atrasar alguns minutos para poupar bateria).
  static AndroidScheduleMode get _mode =>
      exactAllowed.value ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

  static Future<void> showTest() async {
    if (!_ready) return;
    await _plugin.show(
      id: _testId,
      title: '☀️ Tudo certo!',
      body: 'É assim que o Bonum vai te lembrar das coisas boas.',
      notificationDetails: _details,
    );
  }

  /// Agenda um lembrete para daqui a 1 minuto — testa o agendamento de verdade.
  static Future<void> scheduleTest() async {
    if (!_ready) return;
    await _refreshStatus();
    await _plugin.zonedSchedule(
      id: _scheduledTestId,
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
      notificationDetails: _details,
      androidScheduleMode: _mode,
      title: '⏰ Lembrete agendado funcionando',
      body: 'Os lembretes diários do Bonum vão chegar assim.',
    );
  }

  static Future<void> reschedule(AppState state) async {
    if (!_ready) return;
    final gen = ++_generation;
    try {
      await _refreshStatus();
      // Cancela só os lembretes diários (não mexe no teste nem nas notificações já exibidas).
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= 1000) await _plugin.cancel(id: p.id);
      }
      if (gen != _generation) return;

      final s = state.settings;
      if (!s.remindersOn || !s.onboarded) return;

      final now = tz.TZDateTime.now(tz.local);
      final todayEntry = state.existing(dayKey(today()));
      final rnd = Random(now.day + now.month * 31);

      for (var i = 0; i < _daysAhead; i++) {
        if (gen != _generation) return;
        final date = now.add(Duration(days: i));

        if (s.actionReminder && !(i == 0 && (todayEntry?.didGood ?? false))) {
          final msg = _actionMessages[rnd.nextInt(_actionMessages.length)];
          await _schedule(1000 + i, date, s.actionMinutes, msg, now);
        }
        if (s.momentsReminder && !(i == 0 && (todayEntry?.momentsComplete ?? false))) {
          final msg = _momentsMessages[rnd.nextInt(_momentsMessages.length)];
          await _schedule(2000 + i, date, s.momentsMinutes, msg, now);
        }
      }
    } catch (e) {
      debugPrint('Bonum: falha ao agendar lembretes: $e');
    }
  }

  static Future<void> _schedule(
    int id,
    tz.TZDateTime date,
    int minutes,
    (String, String) msg,
    tz.TZDateTime now,
  ) async {
    final when = tz.TZDateTime(tz.local, date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
    if (!when.isAfter(now)) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      notificationDetails: _details,
      androidScheduleMode: _mode,
      title: msg.$1,
      body: msg.$2,
    );
  }
}
