import 'package:flutter/material.dart';

import '../services/fipe_service.dart';
import '../state/app_state.dart';
import 'abastecimento_form_screen.dart';
import 'abastecimentos_tab.dart';
import 'dashboard_tab.dart';
import 'veiculo_form_screen.dart';
import 'veiculo_tab.dart';

/// Tela principal: controla a navegação entre Veículo, Abastecimentos e
/// Dashboard. Sem veículo cadastrado, mostra a tela de boas-vindas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.appState, required this.fipeService});

  final AppState appState;
  final FipeService fipeService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaAtual = 0;

  static const _titulos = ['Meu veículo', 'Abastecimentos', 'Dashboard'];

  Future<void> _abrirCadastroVeiculo() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VeiculoFormScreen(
          appState: widget.appState,
          fipeService: widget.fipeService,
        ),
      ),
    );
  }

  Future<void> _abrirNovoAbastecimento() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AbastecimentoFormScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final veiculo = widget.appState.veiculo;
        if (veiculo == null) {
          return _SemVeiculo(onCadastrar: _abrirCadastroVeiculo);
        }

        final Widget corpo;
        switch (_abaAtual) {
          case 1:
            corpo = AbastecimentosTab(appState: widget.appState);
          case 2:
            corpo = DashboardTab(appState: widget.appState);
          default:
            corpo = VeiculoTab(
              appState: widget.appState,
              onVeiculoExcluido: () => setState(() => _abaAtual = 0),
              onIrParaAbastecimentos: () => setState(() => _abaAtual = 1),
            );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_titulos[_abaAtual])),
          body: corpo,
          floatingActionButton: _abaAtual == 1
              ? FloatingActionButton.extended(
                  onPressed: _abrirNovoAbastecimento,
                  icon: const Icon(Icons.local_gas_station),
                  label: const Text('Abastecer'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _abaAtual,
            onDestinationSelected: (i) => setState(() => _abaAtual = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.directions_car_outlined),
                selectedIcon: Icon(Icons.directions_car),
                label: 'Veículo',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_gas_station_outlined),
                selectedIcon: Icon(Icons.local_gas_station),
                label: 'Abastecimentos',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Dashboard',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SemVeiculo extends StatelessWidget {
  const _SemVeiculo({required this.onCadastrar});

  final VoidCallback onCadastrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Combustível')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_gas_station, size: 96, color: tema.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Nenhum veículo cadastrado',
                style: tema.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Cadastre seu veículo para registrar abastecimentos e '
                'acompanhar gastos e consumo.',
                style: tema.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onCadastrar,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar veículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
