/// Tipos de veículo aceitos pela tabela FIPE da BrasilAPI.
enum TipoVeiculo {
  carros('carros', 'Carro'),
  motos('motos', 'Moto'),
  caminhoes('caminhoes', 'Caminhão');

  const TipoVeiculo(this.valorApi, this.rotulo);

  /// Valor usado na URL da API (ex.: /fipe/marcas/v1/carros).
  final String valorApi;

  /// Texto exibido para o usuário.
  final String rotulo;

  static TipoVeiculo deValorApi(String valor) => TipoVeiculo.values.firstWhere(
        (t) => t.valorApi == valor,
        orElse: () => TipoVeiculo.carros,
      );
}

/// Veículo cadastrado (apenas um por vez).
class Veiculo {
  const Veiculo({
    required this.id,
    required this.tipo,
    required this.codigoMarca,
    required this.marca,
    required this.codigoModelo,
    required this.modelo,
    required this.ano,
    required this.cilindrada,
  });

  final String id;
  final TipoVeiculo tipo;
  final String codigoMarca;
  final String marca;
  final String codigoModelo;
  final String modelo;
  final int ano;

  /// Cilindrada do motor em cm³ (cc).
  final int cilindrada;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.valorApi,
        'codigoMarca': codigoMarca,
        'marca': marca,
        'codigoModelo': codigoModelo,
        'modelo': modelo,
        'ano': ano,
        'cilindrada': cilindrada,
      };

  factory Veiculo.fromJson(Map<String, dynamic> json) => Veiculo(
        id: json['id'].toString(),
        tipo: TipoVeiculo.deValorApi(json['tipo']?.toString() ?? 'carros'),
        codigoMarca: json['codigoMarca'].toString(),
        marca: json['marca'].toString(),
        codigoModelo: json['codigoModelo'].toString(),
        modelo: json['modelo'].toString(),
        ano: (json['ano'] as num).toInt(),
        cilindrada: (json['cilindrada'] as num).toInt(),
      );
}
