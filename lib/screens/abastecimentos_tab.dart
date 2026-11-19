import 'package:flutter/material.dart';

import '../models/abastecimento.dart';
import '../state/app_state.dart';
import '../utils/formatadores.dart';
import '../utils/indicadores.dart';
import 'abastecimento_form_screen.dart';

/// Lista de abastecimentos (mais recentes primeiro) com os indicadores
/// calculados para cada registro.
class AbastecimentosTab extends StatelessWidget {
  const AbastecimentosTab({super.key, required this.appState});

  final AppState appState;

  Future<void> _editar(BuildContext context, Abastecimento a) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AbastecimentoFormScreen(appState: appState, abastecimento: a),
      ),
    );
  }

  Future<void> _excluir(BuildContext context, Abastecimento a) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir abastecimento?'),
        content: Text(
          '${a.combustivel.rotulo} • ${formatarDataHora(a.dataHora)}\n'
          '${formatarMoeda(a.valorTotal)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou == true) {
      await appState.excluirAbastecimento(a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicadores = calcularIndicadores(appState.abastecimentos).reversed.toList();

    if (indicadores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_gas_station_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum abastecimento registrado.\n'
                'Toque em "Abastecer" para adicionar o primeiro.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: indicadores.length,
      itemBuilder: (context, i) => _CardAbastecimento(
        indicador: indicadores[i],
        onTap: () => _editar(context, indicadores[i].abastecimento),
        onExcluir: () => _excluir(context, indicadores[i].abastecimento),
      ),
    );
  }
}

class _CardAbastecimento extends StatelessWidget {
  const _CardAbastecimento({
    required this.indicador,
    required this.onTap,
    required this.onExcluir,
  });

  final IndicadorAbastecimento indicador;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  Color _corCombustivel(TipoCombustivel t) => switch (t) {
        TipoCombustivel.etanol => Colors.green.shade600,
        TipoCombustivel.gasolina => Colors.orange.shade700,
        TipoCombustivel.diesel => Colors.blueGrey.shade600,
      };

  @override
  Widget build(BuildContext context) {
    final a = indicador.abastecimento;
    final tema = Theme.of(context);
    final cor = _corCombustivel(a.combustivel);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cor.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      a.combustivel.rotulo,
                      style: TextStyle(color: cor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('#${indicador.ordem}', style: tema.textTheme.labelMedium),
                  const Spacer(),
                  Text(
                    formatarMoeda(a.valorTotal),
                    style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (op) {
                      if (op == 'editar') {
                        onTap();
                      } else {
                        onExcluir();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${formatarDataHora(a.dataHora)} • ${formatarNumero(a.quilometragem, casas: 0)} km',
                style: tema.textTheme.bodyMedium,
              ),
              Text(
                '${formatarNumero(a.litros)} L × ${formatarMoeda3(a.precoLitro)}/L',
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              if (indicador.possuiIndicadores)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _Chip(
                      icone: Icons.route,
                      texto: '${formatarNumero(indicador.distancia!, casas: 0)} km',
                    ),
                    _Chip(
                      icone: Icons.eco_outlined,
                      texto: '${formatarNumero(indicador.kmPorLitro!)} km/L',
                    ),
                    _Chip(
                      icone: Icons.payments_outlined,
                      texto: '${formatarMoeda3(indicador.custoPorKm!)}/km',
                    ),
                  ],
                )
              else
                Text(
                  indicador.ordem == 1
                      ? 'Primeiro abastecimento: referência inicial (sem km/L e R\$/km).'
                      : 'Indicadores indisponíveis para este registro.',
                  style: tema.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tema.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: tema.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(color: tema.colorScheme.onSecondaryContainer)),
        ],
      ),
    );
  }
}
