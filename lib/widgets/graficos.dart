import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Ponto genérico usado pelos gráficos: [x] é o número do abastecimento.
class PontoGrafico {
  const PontoGrafico({required this.x, required this.y, required this.rotulo});

  final int x;
  final double y;

  /// Texto exibido no tooltip ao tocar no ponto/barra.
  final String rotulo;
}

double _maxY(List<PontoGrafico> pontos) {
  final maior = pontos.fold<double>(0, (m, p) => math.max(m, p.y));
  return maior <= 0 ? 1 : maior * 1.25;
}

double _intervaloX(int quantidade) => math.max(1, (quantidade / 6).ceil()).toDouble();

Widget _tituloInferior(double valor, TitleMeta meta) {
  if (valor != valor.roundToDouble()) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text('#${valor.toInt()}', style: const TextStyle(fontSize: 11)),
  );
}

FlTitlesData _titulos({
  required int quantidade,
  required String Function(double) formatarY,
}) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 26,
        interval: _intervaloX(quantidade),
        getTitlesWidget: _tituloInferior,
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 52,
        getTitlesWidget: (valor, meta) {
          // Evita rótulo sobreposto no topo do eixo.
          if (valor == meta.max) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              formatarY(valor),
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        },
      ),
    ),
  );
}

/// Gráfico de linha com a evolução de um indicador (km/L ou R$/km).
class GraficoLinha extends StatelessWidget {
  const GraficoLinha({
    super.key,
    required this.pontos,
    required this.cor,
    required this.formatarY,
  });

  final List<PontoGrafico> pontos;
  final Color cor;
  final String Function(double) formatarY;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final minX = pontos.first.x.toDouble() - 0.5;
    final maxX = pontos.last.x.toDouble() + 0.5;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 12),
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: 0,
            maxY: _maxY(pontos),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: _titulos(quantidade: pontos.length, formatarY: formatarY),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                getTooltipItems: (spots) => spots.map((s) {
                  final ponto = pontos.firstWhere((p) => p.x == s.x.toInt());
                  return LineTooltipItem(
                    '#${ponto.x}\n${ponto.rotulo}',
                    TextStyle(
                      color: tema.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: pontos.map((p) => FlSpot(p.x.toDouble(), p.y)).toList(),
                isCurved: true,
                preventCurveOverShooting: true,
                color: cor,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: cor.withAlpha(40)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gráfico de barras com o valor (R$) de cada abastecimento.
class GraficoBarras extends StatelessWidget {
  const GraficoBarras({
    super.key,
    required this.pontos,
    required this.cor,
    required this.formatarY,
  });

  final List<PontoGrafico> pontos;
  final Color cor;
  final String Function(double) formatarY;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final larguraBarra = pontos.length > 12 ? 8.0 : 18.0;

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 12),
        child: BarChart(
          BarChartData(
            maxY: _maxY(pontos),
            minY: 0,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: _titulos(quantidade: pontos.length, formatarY: formatarY),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                getTooltipItem: (grupo, indiceGrupo, barra, indiceBarra) {
                  final ponto = pontos[indiceGrupo];
                  return BarTooltipItem(
                    '#${ponto.x}\n${ponto.rotulo}',
                    TextStyle(
                      color: tema.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            barGroups: pontos
                .map(
                  (p) => BarChartGroupData(
                    x: p.x,
                    barRods: [
                      BarChartRodData(
                        toY: p.y,
                        color: cor,
                        width: larguraBarra,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
