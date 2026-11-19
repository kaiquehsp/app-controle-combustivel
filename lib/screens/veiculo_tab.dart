import 'package:flutter/material.dart';

import '../models/veiculo.dart';
import '../state/app_state.dart';
import '../utils/formatadores.dart';

/// Exibe os dados do veículo cadastrado e permite excluí-lo.
class VeiculoTab extends StatelessWidget {
  const VeiculoTab({
    super.key,
    required this.appState,
    required this.onVeiculoExcluido,
    required this.onIrParaAbastecimentos,
  });

  final AppState appState;
  final VoidCallback onVeiculoExcluido;
  final VoidCallback onIrParaAbastecimentos;

  IconData _icone(TipoVeiculo tipo) => switch (tipo) {
        TipoVeiculo.carros => Icons.directions_car,
        TipoVeiculo.motos => Icons.two_wheeler,
        TipoVeiculo.caminhoes => Icons.local_shipping,
      };

  Future<void> _confirmarExclusao(BuildContext context) async {
    final qtd = appState.abastecimentos.length;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Excluir veículo?'),
        content: Text(
          qtd == 0
              ? 'O veículo será removido. Esta ação não pode ser desfeita.'
              : 'O veículo e ${qtd == 1 ? 'o abastecimento registrado' : 'os $qtd abastecimentos registrados'} '
                  'serão removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true || !context.mounted) return;
    // O messenger raiz continua existindo depois que esta aba é desmontada.
    final messenger = ScaffoldMessenger.of(context);
    await appState.excluirVeiculo();
    onVeiculoExcluido();
    messenger.showSnackBar(
      const SnackBar(content: Text('Veículo e abastecimentos excluídos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final veiculo = appState.veiculo!;
    final tema = Theme.of(context);
    final abastecimentos = appState.abastecimentos;
    final totalGasto =
        abastecimentos.fold<double>(0, (soma, a) => soma + a.valorTotal);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: tema.colorScheme.primaryContainer,
                      child: Icon(
                        _icone(veiculo.tipo),
                        size: 30,
                        color: tema.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(veiculo.marca, style: tema.textTheme.titleMedium),
                          Text(
                            veiculo.modelo,
                            style: tema.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _Linha(rotulo: 'Tipo', valor: veiculo.tipo.rotulo),
                _Linha(rotulo: 'Marca', valor: veiculo.marca),
                _Linha(rotulo: 'Modelo', valor: veiculo.modelo),
                _Linha(rotulo: 'Ano', valor: veiculo.ano.toString()),
                _Linha(
                  rotulo: 'Cilindrada',
                  valor: '${formatarNumero(veiculo.cilindrada.toDouble(), casas: 0)} cm³',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_gas_station),
            title: Text(
              '${abastecimentos.length} abastecimento${abastecimentos.length == 1 ? '' : 's'}',
            ),
            subtitle: Text('Total gasto: ${formatarMoeda(totalGasto)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onIrParaAbastecimentos,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: tema.colorScheme.error,
            side: BorderSide(color: tema.colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _confirmarExclusao(context),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir veículo'),
        ),
        const SizedBox(height: 8),
        Text(
          'Para cadastrar outro veículo, exclua o atual. '
          'Os abastecimentos dele também serão removidos.',
          style: tema.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              rotulo,
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(valor, style: tema.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
