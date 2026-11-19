import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/opcao_fipe.dart';
import '../models/veiculo.dart';

class FipeException implements Exception {
  FipeException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Consulta marcas e modelos na tabela FIPE da BrasilAPI.
///
/// Endpoints utilizados (https://brasilapi.com.br/docs#tag/FIPE):
/// * GET /api/fipe/marcas/v1/{tipoVeiculo}
///   -> [{"nome": "VW - VolksWagen", "valor": "59"}, ...]
/// * GET /api/fipe/veiculos/v1/{tipoVeiculo}/{codigoMarca}
///   -> [{"modelo": "Gol 1.0 ...", "valor": "1234"}, ...]
class FipeService {
  FipeService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://brasilapi.com.br/api/fipe';
  static const Duration _timeout = Duration(seconds: 25);

  final http.Client _client;

  // Cache em memória para não repetir chamadas durante o uso do app.
  final Map<String, List<OpcaoFipe>> _cache = {};

  Future<List<OpcaoFipe>> listarMarcas(TipoVeiculo tipo) {
    return _buscarLista(
      '$_baseUrl/marcas/v1/${tipo.valorApi}',
      campoNome: 'nome',
    );
  }

  Future<List<OpcaoFipe>> listarModelos(TipoVeiculo tipo, String codigoMarca) {
    return _buscarLista(
      '$_baseUrl/veiculos/v1/${tipo.valorApi}/$codigoMarca',
      campoNome: 'modelo',
    );
  }

  Future<List<OpcaoFipe>> _buscarLista(String url, {required String campoNome}) async {
    final emCache = _cache[url];
    if (emCache != null) return emCache;

    final http.Response resposta;
    try {
      resposta = await _client.get(Uri.parse(url)).timeout(_timeout);
    } on TimeoutException {
      throw FipeException('A BrasilAPI demorou para responder. Tente novamente.');
    } catch (_) {
      throw FipeException('Não foi possível conectar à BrasilAPI. Verifique sua internet.');
    }

    if (resposta.statusCode != 200) {
      throw FipeException('Erro ao consultar a BrasilAPI (HTTP ${resposta.statusCode}).');
    }

    final dynamic corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (corpo is! List) {
      throw FipeException('Resposta inesperada da BrasilAPI.');
    }

    final vistos = <String>{};
    final opcoes = <OpcaoFipe>[];
    for (final item in corpo) {
      if (item is! Map) continue;
      final nome = item[campoNome]?.toString().trim() ?? '';
      final codigo = item['valor']?.toString() ?? '';
      if (nome.isEmpty || codigo.isEmpty) continue;
      if (vistos.add('$codigo|$nome')) {
        opcoes.add(OpcaoFipe(codigo: codigo, nome: nome));
      }
    }
    opcoes.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    _cache[url] = opcoes;
    return opcoes;
  }
}
