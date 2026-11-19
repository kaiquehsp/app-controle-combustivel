enum TipoCombustivel {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  const TipoCombustivel(this.rotulo);

  final String rotulo;

  static TipoCombustivel deNome(String nome) => TipoCombustivel.values.firstWhere(
        (t) => t.name == nome,
        orElse: () => TipoCombustivel.gasolina,
      );
}

/// Registro de um abastecimento (considerado sempre "tanque cheio").
class Abastecimento {
  const Abastecimento({
    required this.id,
    required this.veiculoId,
    required this.combustivel,
    required this.precoLitro,
    required this.quilometragem,
    required this.litros,
    required this.dataHora,
  });

  final String id;

  /// Veículo ao qual o abastecimento pertence.
  final String veiculoId;
  final TipoCombustivel combustivel;

  /// Preço por litro em reais.
  final double precoLitro;

  /// Quilometragem (hodômetro) no momento do abastecimento.
  final double quilometragem;

  /// Quantidade de litros abastecidos.
  final double litros;
  final DateTime dataHora;

  /// Valor total = preço por litro × quantidade de litros.
  double get valorTotal => precoLitro * litros;

  Map<String, dynamic> toJson() => {
        'id': id,
        'veiculoId': veiculoId,
        'combustivel': combustivel.name,
        'precoLitro': precoLitro,
        'quilometragem': quilometragem,
        'litros': litros,
        'dataHora': dataHora.toIso8601String(),
      };

  factory Abastecimento.fromJson(Map<String, dynamic> json) => Abastecimento(
        id: json['id'].toString(),
        veiculoId: json['veiculoId'].toString(),
        combustivel: TipoCombustivel.deNome(json['combustivel'].toString()),
        precoLitro: (json['precoLitro'] as num).toDouble(),
        quilometragem: (json['quilometragem'] as num).toDouble(),
        litros: (json['litros'] as num).toDouble(),
        dataHora: DateTime.parse(json['dataHora'].toString()),
      );
}
