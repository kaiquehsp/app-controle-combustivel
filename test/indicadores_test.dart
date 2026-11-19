import 'package:controle_combustivel/models/abastecimento.dart';
import 'package:controle_combustivel/models/veiculo.dart';
import 'package:controle_combustivel/utils/formatadores.dart';
import 'package:controle_combustivel/utils/indicadores.dart';
import 'package:flutter_test/flutter_test.dart';

Abastecimento _abast(String id, double km, double litros, double preco, DateTime data) =>
    Abastecimento(
      id: id,
      veiculoId: 'v1',
      combustivel: TipoCombustivel.gasolina,
      precoLitro: preco,
      quilometragem: km,
      litros: litros,
      dataHora: data,
    );

void main() {
  group('Abastecimento', () {
    test('valor total = preço por litro × litros', () {
      final a = _abast('1', 1000, 40, 5.5, DateTime(2026, 1, 1));
      expect(a.valorTotal, closeTo(220, 0.0001));
    });

    test('serialização JSON mantém os dados', () {
      final a = _abast('1', 1234.5, 30.25, 5.89, DateTime(2026, 3, 4, 10, 30));
      final b = Abastecimento.fromJson(a.toJson());
      expect(b.id, a.id);
      expect(b.quilometragem, a.quilometragem);
      expect(b.litros, a.litros);
      expect(b.precoLitro, a.precoLitro);
      expect(b.dataHora, a.dataHora);
      expect(b.combustivel, a.combustivel);
    });
  });

  test('Veiculo: serialização JSON', () {
    const v = Veiculo(
      id: 'v1',
      tipo: TipoVeiculo.motos,
      codigoMarca: '80',
      marca: 'HONDA',
      codigoModelo: '1234',
      modelo: 'CG 160 FAN',
      ano: 2022,
      cilindrada: 160,
    );
    final copia = Veiculo.fromJson(v.toJson());
    expect(copia.tipo, TipoVeiculo.motos);
    expect(copia.modelo, 'CG 160 FAN');
    expect(copia.cilindrada, 160);
  });

  group('calcularIndicadores', () {
    test('primeiro abastecimento não possui km/L nem R\$/km', () {
      final r = calcularIndicadores([_abast('1', 1000, 40, 5, DateTime(2026, 1, 1))]);
      expect(r.single.possuiIndicadores, isFalse);
      expect(r.single.kmPorLitro, isNull);
      expect(r.single.custoPorKm, isNull);
    });

    test('calcula distância, km/L e R\$/km a partir do segundo', () {
      final r = calcularIndicadores([
        // fora de ordem de propósito: deve ordenar por data
        _abast('2', 1400, 32, 6, DateTime(2026, 1, 10)),
        _abast('1', 1000, 40, 5, DateTime(2026, 1, 1)),
      ]);
      expect(r[0].abastecimento.id, '1');
      expect(r[1].ordem, 2);
      expect(r[1].distancia, 400);
      expect(r[1].kmPorLitro, closeTo(12.5, 0.0001)); // 400 / 32
      expect(r[1].custoPorKm, closeTo(0.48, 0.0001)); // (32*6) / 400
    });

    test('resumo usa médias ponderadas', () {
      final r = calcularIndicadores([
        _abast('1', 1000, 40, 5, DateTime(2026, 1, 1)),
        _abast('2', 1400, 32, 6, DateTime(2026, 1, 10)),
        _abast('3', 1900, 50, 5, DateTime(2026, 1, 20)),
      ]);
      final resumo = ResumoConsumo.de(r);
      expect(resumo.quantidade, 3);
      expect(resumo.totalGasto, closeTo(200 + 192 + 250, 0.0001));
      expect(resumo.mediaKmPorLitro, closeTo(900 / 82, 0.0001));
      expect(resumo.mediaCustoPorKm, closeTo(442 / 900, 0.0001));
    });
  });

  test('lerDecimal aceita vírgula e ponto', () {
    expect(lerDecimal('5,89'), 5.89);
    expect(lerDecimal('5.89'), 5.89);
    expect(lerDecimal('1.234,5'), 1234.5);
    expect(lerDecimal(''), isNull);
  });
}
