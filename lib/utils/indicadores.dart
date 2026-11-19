import '../models/abastecimento.dart';

/// Indicadores calculados para um abastecimento.
///
/// O primeiro abastecimento é apenas a referência inicial, por isso
/// [distancia], [kmPorLitro] e [custoPorKm] ficam nulos para ele.
class IndicadorAbastecimento {
  const IndicadorAbastecimento({
    required this.abastecimento,
    required this.ordem,
    this.distancia,
    this.kmPorLitro,
    this.custoPorKm,
  });

  final Abastecimento abastecimento;

  /// Posição do abastecimento em ordem cronológica (1, 2, 3...).
  final int ordem;

  /// Quilometragem atual − quilometragem do abastecimento anterior.
  final double? distancia;

  /// Distância percorrida ÷ litros do abastecimento atual.
  final double? kmPorLitro;

  /// Valor total do abastecimento atual ÷ distância percorrida.
  final double? custoPorKm;

  bool get possuiIndicadores => kmPorLitro != null && custoPorKm != null;
}

/// Ordena os abastecimentos por data/hora e calcula os indicadores
/// considerando que todos os registros são de tanque cheio.
List<IndicadorAbastecimento> calcularIndicadores(List<Abastecimento> abastecimentos) {
  final ordenados = [...abastecimentos]
    ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

  final resultado = <IndicadorAbastecimento>[];
  for (var i = 0; i < ordenados.length; i++) {
    final atual = ordenados[i];
    if (i == 0) {
      resultado.add(IndicadorAbastecimento(abastecimento: atual, ordem: 1));
      continue;
    }

    final distancia = atual.quilometragem - ordenados[i - 1].quilometragem;
    if (distancia <= 0 || atual.litros <= 0) {
      // Dados inconsistentes: não calcula para evitar divisões inválidas.
      resultado.add(IndicadorAbastecimento(abastecimento: atual, ordem: i + 1));
      continue;
    }

    resultado.add(IndicadorAbastecimento(
      abastecimento: atual,
      ordem: i + 1,
      distancia: distancia,
      kmPorLitro: distancia / atual.litros,
      custoPorKm: atual.valorTotal / distancia,
    ));
  }
  return resultado;
}

/// Totais e médias exibidos no topo do dashboard.
class ResumoConsumo {
  const ResumoConsumo({
    required this.quantidade,
    required this.totalGasto,
    required this.totalLitros,
    required this.distanciaTotal,
    this.mediaKmPorLitro,
    this.mediaCustoPorKm,
  });

  final int quantidade;
  final double totalGasto;
  final double totalLitros;
  final double distanciaTotal;

  /// Média ponderada: soma das distâncias ÷ soma dos litros (sem o 1º).
  final double? mediaKmPorLitro;

  /// Média ponderada: soma dos valores ÷ soma das distâncias (sem o 1º).
  final double? mediaCustoPorKm;

  factory ResumoConsumo.de(List<IndicadorAbastecimento> indicadores) {
    var totalGasto = 0.0;
    var totalLitros = 0.0;
    var distancia = 0.0;
    var litrosComIndicador = 0.0;
    var valorComIndicador = 0.0;

    for (final ind in indicadores) {
      totalGasto += ind.abastecimento.valorTotal;
      totalLitros += ind.abastecimento.litros;
      if (ind.possuiIndicadores) {
        distancia += ind.distancia!;
        litrosComIndicador += ind.abastecimento.litros;
        valorComIndicador += ind.abastecimento.valorTotal;
      }
    }

    return ResumoConsumo(
      quantidade: indicadores.length,
      totalGasto: totalGasto,
      totalLitros: totalLitros,
      distanciaTotal: distancia,
      mediaKmPorLitro: distancia > 0 ? distancia / litrosComIndicador : null,
      mediaCustoPorKm: distancia > 0 ? valorComIndicador / distancia : null,
    );
  }
}
