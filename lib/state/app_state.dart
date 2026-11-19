import 'package:flutter/foundation.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';
import '../services/storage_service.dart';
import '../utils/formatadores.dart';

/// Estado global do aplicativo: veículo cadastrado e seus abastecimentos.
///
/// Toda alteração é gravada imediatamente no armazenamento local.
class AppState extends ChangeNotifier {
  AppState(this._storage);

  final StorageService _storage;

  Veiculo? _veiculo;
  List<Abastecimento> _abastecimentos = [];

  Veiculo? get veiculo => _veiculo;

  /// Abastecimentos do veículo atual em ordem cronológica.
  List<Abastecimento> get abastecimentos => List.unmodifiable(_abastecimentos);

  Future<void> carregar() async {
    _veiculo = await _storage.carregarVeiculo();
    final todos = await _storage.carregarAbastecimentos();
    _abastecimentos = _veiculo == null
        ? []
        : todos.where((a) => a.veiculoId == _veiculo!.id).toList();
    _ordenar();
    notifyListeners();
  }

  Future<void> cadastrarVeiculo(Veiculo veiculo) async {
    if (_veiculo != null) {
      throw StateError('Já existe um veículo cadastrado. Exclua-o primeiro.');
    }
    await _storage.salvarVeiculo(veiculo);
    _veiculo = veiculo;
    _abastecimentos = [];
    notifyListeners();
  }

  /// Exclui o veículo atual e todos os abastecimentos associados.
  Future<void> excluirVeiculo() async {
    await _storage.excluirVeiculoEAbastecimentos();
    _veiculo = null;
    _abastecimentos = [];
    notifyListeners();
  }

  /// Inclui um novo abastecimento ou atualiza um existente (mesmo id).
  Future<void> salvarAbastecimento(Abastecimento abastecimento) async {
    final indice = _abastecimentos.indexWhere((a) => a.id == abastecimento.id);
    if (indice >= 0) {
      _abastecimentos[indice] = abastecimento;
    } else {
      _abastecimentos.add(abastecimento);
    }
    _ordenar();
    await _storage.salvarAbastecimentos(_abastecimentos);
    notifyListeners();
  }

  Future<void> excluirAbastecimento(String id) async {
    _abastecimentos.removeWhere((a) => a.id == id);
    await _storage.salvarAbastecimentos(_abastecimentos);
    notifyListeners();
  }

  /// Garante que a quilometragem seja coerente com os abastecimentos
  /// anterior e posterior (pela data/hora). Retorna a mensagem de erro
  /// ou `null` quando o valor é válido.
  String? validarQuilometragem(
    double quilometragem,
    DateTime dataHora, {
    String? ignorarId,
  }) {
    Abastecimento? anterior;
    Abastecimento? posterior;
    for (final a in _abastecimentos) {
      if (a.id == ignorarId) continue;
      if (!a.dataHora.isAfter(dataHora)) {
        anterior = a; // lista está ordenada: fica com o mais recente <= data
      } else {
        posterior ??= a;
      }
    }

    if (anterior != null && quilometragem <= anterior.quilometragem) {
      return 'Deve ser maior que ${formatarNumero(anterior.quilometragem, casas: 0)} km '
          '(abastecimento de ${formatarDataHora(anterior.dataHora)})';
    }
    if (posterior != null && quilometragem >= posterior.quilometragem) {
      return 'Deve ser menor que ${formatarNumero(posterior.quilometragem, casas: 0)} km '
          '(abastecimento de ${formatarDataHora(posterior.dataHora)})';
    }
    return null;
  }

  void _ordenar() {
    _abastecimentos.sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }
}
