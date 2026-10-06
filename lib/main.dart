import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'data/store.dart';
import 'services/notifications.dart';
import 'ui/home_shell.dart';
import 'ui/pages/welcome_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final state = await AppState.load();
  await NotificationService.init();

  // Mantém os lembretes em dia com o que a pessoa já fez (pula o de hoje se já fez).
  state.addListener(() => unawaited(NotificationService.reschedule(state)));
  unawaited(NotificationService.reschedule(state));

  runApp(BonumApp(state: state));
}

class BonumApp extends StatefulWidget {
  const BonumApp({super.key, required this.state});

  final AppState state;

  @override
  State<BonumApp> createState() => _BonumAppState();
}

class _BonumAppState extends State<BonumApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Ao voltar para o app (ex.: virou o dia com ele aberto), redesenha e reagenda.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) widget.state.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Bonum',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ListenableBuilder(
          listenable: widget.state,
          builder: (context, _) => widget.state.settings.onboarded ? const HomeShell() : const WelcomePage(),
        ),
      ),
    );
  }
}
