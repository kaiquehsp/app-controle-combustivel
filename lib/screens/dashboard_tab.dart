import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/formatadores.dart';
import '../utils/indicadores.dart';
import '../widgets/graficos.dart';

/// Dashboard com resumo e gráficos (fl_chart):
/// * valor de cada abastecimento (barras);
/// * consumo em km/L entre abastecimentos (linha);
/// * custo em R$/km entre abastecimentos (linha).
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final indicadores = calcularIndicadores(appState.abastecimentos);
    final tema = Theme.of(context);

    if (indicadores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Registre abastecimentos para visualizar o dashboard.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final resumo = ResumoConsumo.de(indicadores);
    final comIndicadores = indicadores.where((i) => i.possuiIndicadores).toList();

    final pontosValor = indicadores
        .map((i) => PontoGrafico(
              x: i.ordem,
              y: i.abastecimento.valorTotal,
              rotulo: formatarMoeda(i.abastecimento.valorTotal),
            ))
        .toList();
    final pontosKmL = comIndicadores
        .map((i) => PontoGrafico(
              x: i.ordem,
              y: i.kmPorLitro!,
              rotulo: '${formatarNumero(i.kmPorLitro!)} km/L',
            ))
        .toList();
    final pontosCusto = comIndicadores
        .map((i) => PontoGrafico(
              x: i.ordem,
              y: i.custoPorKm!,
              rotulo: '${formatarMoeda3(i.custoPorKm!)}/km',
            ))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [
            _CardResumo(
              icone: Icons.payments,
              titulo: 'Total gasto',
              valor: formatarMoeda(resumo.totalGasto),
            ),
            _CardResumo(
              icone: Icons.local_gas_station,
              titulo: 'Abastecimentos',
              valor: '${resumo.quantidade} • ${formatarNumero(resumo.totalLitros, casas: 1)} L',
            ),
            _CardResumo(
              icone: Icons.eco,
              titulo: 'Consumo médio',
              valor: resumo.mediaKmPorLitro == null
                  ? '--'
                  : '${formatarNumero(resumo.mediaKmPorLitro!)} km/L',
            ),
            _CardResumo(
              icone: Icons.route,
              titulo: 'Custo médio',
              valor: resumo.mediaCustoPorKm == null
                  ? '--'
                  : '${formatarMoeda3(resumo.mediaCustoPorKm!)}/km',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _CardGrafico(
          titulo: 'Valor de cada abastecimento',
          subtitulo: 'R\$ por abastecimento (#ordem cronológica)',
          child: GraficoBarras(
            pontos: pontosValor,
            cor: tema.colorScheme.primary,
            formatarY: (v) => formatarNumero(v, casas: 0),
          ),
        ),
        _CardGrafico(
          titulo: 'Consumo (km/L)',
          subtitulo: 'Distância percorrida ÷ litros do abastecimento atual',
          child: pontosKmL.isEmpty
              ? const _SemDados()
              : GraficoLinha(
                  pontos: pontosKmL,
                  cor: Colors.green.shade600,
                  formatarY: (v) => formatarNumero(v, casas: 1),
                ),
        ),
        _CardGrafico(
          titulo: 'Custo por quilômetro (R\$/km)',
          subtitulo: 'Valor do abastecimento atual ÷ distância percorrida',
          child: pontosCusto.isEmpty
              ? const _SemDados()
              : GraficoLinha(
                  pontos: pontosCusto,
                  cor: Colors.deepOrange,
                  formatarY: (v) => formatarNumero(v, casas: 2),
                ),
        ),
        _CardGrafico(
          titulo: 'Indicadores por abastecimento',
          subtitulo: 'O 1º abastecimento é a referência inicial',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Data')),
                DataColumn(label: Text('Valor'), numeric: true),
                DataColumn(label: Text('Dist.'), numeric: true),
                DataColumn(label: Text('km/L'), numeric: true),
                DataColumn(label: Text('R\$/km'), numeric: true),
              ],
              rows: indicadores
                  .map(
                    (i) => DataRow(cells: [
                      DataCell(Text('${i.ordem}')),
                      DataCell(Text(formatarDataCurta(i.abastecimento.dataHora))),
                      DataCell(Text(formatarMoeda(i.abastecimento.valorTotal))),
                      DataCell(Text(i.distancia == null
                          ? '—'
                          : '${formatarNumero(i.distancia!, casas: 0)} km')),
                      DataCell(Text(i.kmPorLitro == null ? '—' : formatarNumero(i.kmPorLitro!))),
                      DataCell(Text(i.custoPorKm == null ? '—' : formatarMoeda3(i.custoPorKm!))),
                    ]),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CardResumo extends StatelessWidget {
  const _CardResumo({required this.icone, required this.titulo, required this.valor});

  final IconData icone;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: tema.colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    titulo,
                    style: tema.textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valor,
                style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardGrafico extends StatelessWidget {
  const _CardGrafico({required this.titulo, required this.subtitulo, required this.child});

  final String titulo;
  final String subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: tema.textTheme.titleMedium),
            Text(
              subtitulo,
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SemDados extends StatelessWidget {
  const _SemDados();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Registre ao menos dois abastecimentos\npara calcular este indicador.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
