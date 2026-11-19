import 'package:flutter/material.dart';

import '../models/opcao_fipe.dart';

/// Tela de seleção com busca, usada para escolher marca e modelo vindos
/// da BrasilAPI. Retorna a [OpcaoFipe] escolhida via Navigator.pop.
class SelecaoOpcaoScreen extends StatefulWidget {
  const SelecaoOpcaoScreen({
    super.key,
    required this.titulo,
    required this.carregar,
    this.selecionada,
  });

  final String titulo;
  final Future<List<OpcaoFipe>> Function() carregar;
  final OpcaoFipe? selecionada;

  @override
  State<SelecaoOpcaoScreen> createState() => _SelecaoOpcaoScreenState();
}

class _SelecaoOpcaoScreenState extends State<SelecaoOpcaoScreen> {
  late Future<List<OpcaoFipe>> _futuro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _futuro = widget.carregar();
  }

  void _tentarNovamente() {
    setState(() => _futuro = widget.carregar());
  }

  static String _normalizar(String texto) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final buffer = StringBuffer();
    for (final char in texto.split('')) {
      final i = comAcento.indexOf(char);
      buffer.write(i >= 0 ? semAcento[i] : char);
    }
    return buffer.toString().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Pesquisar...',
              ),
              onChanged: (texto) => setState(() => _filtro = _normalizar(texto.trim())),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OpcaoFipe>>(
              future: _futuro,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Consultando a BrasilAPI...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 56),
                          const SizedBox(height: 16),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _tentarNovamente,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final todas = snapshot.data ?? const <OpcaoFipe>[];
                final opcoes = _filtro.isEmpty
                    ? todas
                    : todas.where((o) => _normalizar(o.nome).contains(_filtro)).toList();

                if (opcoes.isEmpty) {
                  return const Center(child: Text('Nenhum resultado encontrado.'));
                }

                return ListView.separated(
                  itemCount: opcoes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final opcao = opcoes[i];
                    final selecionada = opcao == widget.selecionada;
                    return ListTile(
                      title: Text(opcao.nome),
                      selected: selecionada,
                      trailing: selecionada ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(context).pop(opcao),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
