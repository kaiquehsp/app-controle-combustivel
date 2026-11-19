import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';

/// Persistência local usando shared_preferences (dados salvos em JSON).
///
/// Os dados permanecem no dispositivo após fechar e abrir o aplicativo.
class StorageService {
  static const String _chaveVeiculo = 'veiculo';
  static const String _chaveAbastecimentos = 'abastecimentos';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Veiculo?> carregarVeiculo() async {
    final prefs = await _prefs;
    final texto = prefs.getString(_chaveVeiculo);
    if (texto == null) return null;
    return Veiculo.fromJson(jsonDecode(texto) as Map<String, dynamic>);
  }

  Future<void> salvarVeiculo(Veiculo veiculo) async {
    final prefs = await _prefs;
    await prefs.setString(_chaveVeiculo, jsonEncode(veiculo.toJson()));
  }

  Future<List<Abastecimento>> carregarAbastecimentos() async {
    final prefs = await _prefs;
    final texto = prefs.getString(_chaveAbastecimentos);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((e) => Abastecimento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvarAbastecimentos(List<Abastecimento> abastecimentos) async {
    final prefs = await _prefs;
    await prefs.setString(
      _chaveAbastecimentos,
      jsonEncode(abastecimentos.map((a) => a.toJson()).toList()),
    );
  }

  /// Remove o veículo e todos os abastecimentos associados a ele.
  Future<void> excluirVeiculoEAbastecimentos() async {
    final prefs = await _prefs;
    await prefs.remove(_chaveAbastecimentos);
    await prefs.remove(_chaveVeiculo);
  }
}
