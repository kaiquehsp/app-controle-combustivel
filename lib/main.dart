import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'screens/home_screen.dart';
import 'services/fipe_service.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final appState = AppState(StorageService());
  await appState.carregar();

  runApp(ControleCombustivelApp(appState: appState, fipeService: FipeService()));
}

class ControleCombustivelApp extends StatelessWidget {
  const ControleCombustivelApp({
    super.key,
    required this.appState,
    required this.fipeService,
  });

  final AppState appState;
  final FipeService fipeService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Combustível',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeScreen(appState: appState, fipeService: fipeService),
    );
  }
}
