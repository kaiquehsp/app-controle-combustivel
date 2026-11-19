/// Item genérico retornado pela tabela FIPE (marca ou modelo).
class OpcaoFipe {
  const OpcaoFipe({required this.codigo, required this.nome});

  final String codigo;
  final String nome;

  @override
  bool operator ==(Object other) =>
      other is OpcaoFipe && other.codigo == codigo && other.nome == nome;

  @override
  int get hashCode => Object.hash(codigo, nome);

  @override
  String toString() => nome;
}
