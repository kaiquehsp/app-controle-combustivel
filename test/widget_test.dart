import 'package:controle_combustivel/main.dart';
import 'package:controle_combustivel/services/fipe_service.dart';
import 'package:controle_combustivel/services/storage_service.dart';
import 'package:controle_combustivel/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sem veículo cadastrado mostra a tela inicial', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    final appState = AppState(StorageService());
    await appState.carregar();

    await tester.pumpWidget(
      ControleCombustivelApp(appState: appState, fipeService: FipeService()),
    );

    expect(find.text('Nenhum veículo cadastrado'), findsOneWidget);
    expect(find.text('Cadastrar veículo'), findsOneWidget);
  });
}
