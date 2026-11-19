import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/opcao_fipe.dart';
import '../models/veiculo.dart';
import '../services/fipe_service.dart';
import '../state/app_state.dart';
import 'selecao_opcao_screen.dart';

/// Cadastro do veículo. Marca e modelo são consultados na BrasilAPI (FIPE);
/// a lista de modelos depende da marca escolhida.
class VeiculoFormScreen extends StatefulWidget {
  const VeiculoFormScreen({
    super.key,
    required this.appState,
    required this.fipeService,
  });

  final AppState appState;
  final FipeService fipeService;

  @override
  State<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends State<VeiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anoController = TextEditingController();
  final _cilindradaController = TextEditingController();

  TipoVeiculo _tipo = TipoVeiculo.carros;
  OpcaoFipe? _marca;
  OpcaoFipe? _modelo;
  bool _salvando = false;

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    _cilindradaController.dispose();
    super.dispose();
  }

  void _alterarTipo(TipoVeiculo tipo) {
    if (tipo == _tipo) return;
    setState(() {
      _tipo = tipo;
      _marca = null;
      _modelo = null;
      _marcaController.clear();
      _modeloController.clear();
    });
  }

  Future<void> _selecionarMarca() async {
    final escolhida = await Navigator.of(context).push<OpcaoFipe>(
      MaterialPageRoute(
        builder: (_) => SelecaoOpcaoScreen(
          titulo: 'Selecione a marca',
          selecionada: _marca,
          carregar: () => widget.fipeService.listarMarcas(_tipo),
        ),
      ),
    );
    if (escolhida == null || escolhida == _marca) return;
    setState(() {
      _marca = escolhida;
      _marcaController.text = escolhida.nome;
      // Modelo depende da marca: limpa ao trocar.
      _modelo = null;
      _modeloController.clear();
    });
  }

  Future<void> _selecionarModelo() async {
    final marca = _marca;
    if (marca == null) return;
    final escolhido = await Navigator.of(context).push<OpcaoFipe>(
      MaterialPageRoute(
        builder: (_) => SelecaoOpcaoScreen(
          titulo: 'Modelos – ${marca.nome}',
          selecionada: _modelo,
          carregar: () => widget.fipeService.listarModelos(_tipo, marca.codigo),
        ),
      ),
    );
    if (escolhido == null) return;
    setState(() {
      _modelo = escolhido;
      _modeloController.text = escolhido.nome;
    });
  }

  Future<void> _salvar() async {
    final formularioValido = _formKey.currentState!.validate();
    if (!formularioValido || _marca == null || _modelo == null) {
      if (_marca == null || _modelo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione a marca e o modelo do veículo.')),
        );
      }
      return;
    }
    setState(() => _salvando = true);

    final veiculo = Veiculo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      tipo: _tipo,
      codigoMarca: _marca!.codigo,
      marca: _marca!.nome,
      codigoModelo: _modelo!.codigo,
      modelo: _modelo!.nome,
      ano: int.parse(_anoController.text.trim()),
      cilindrada: int.parse(_cilindradaController.text.trim()),
    );

    try {
      await widget.appState.cadastrarVeiculo(veiculo);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Veículo cadastrado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final anoMaximo = DateTime.now().year + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tipo de veículo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TipoVeiculo>(
              segments: const [
                ButtonSegment(
                  value: TipoVeiculo.carros,
                  label: Text('Carro'),
                  icon: Icon(Icons.directions_car),
                ),
                ButtonSegment(
                  value: TipoVeiculo.motos,
                  label: Text('Moto'),
                  icon: Icon(Icons.two_wheeler),
                ),
                ButtonSegment(
                  value: TipoVeiculo.caminhoes,
                  label: Text('Caminhão'),
                  icon: Icon(Icons.local_shipping),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => _alterarTipo(s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _marcaController,
              readOnly: true,
              onTap: _selecionarMarca,
              decoration: const InputDecoration(
                labelText: 'Marca',
                hintText: 'Toque para escolher (BrasilAPI)',
                prefixIcon: Icon(Icons.factory_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              validator: (_) => _marca == null ? 'Selecione a marca' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modeloController,
              readOnly: true,
              enabled: _marca != null,
              onTap: _selecionarModelo,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Modelo',
                hintText: _marca == null
                    ? 'Escolha a marca primeiro'
                    : 'Toque para escolher (BrasilAPI)',
                prefixIcon: const Icon(Icons.directions_car_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
              validator: (_) => _modelo == null ? 'Selecione o modelo' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _anoController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Ano',
                hintText: 'Ex.: 2020',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (valor) {
                final ano = int.tryParse(valor?.trim() ?? '');
                if (ano == null) return 'Informe o ano';
                if (ano < 1950 || ano > anoMaximo) {
                  return 'Informe um ano entre 1950 e $anoMaximo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cilindradaController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: const InputDecoration(
                labelText: 'Cilindrada do motor',
                hintText: 'Ex.: 1600',
                suffixText: 'cm³',
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (valor) {
                final cc = int.tryParse(valor?.trim() ?? '');
                if (cc == null) return 'Informe a cilindrada';
                if (cc < 49 || cc > 20000) return 'Informe um valor entre 49 e 20000 cm³';
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Salvar veículo'),
            ),
          ],
        ),
      ),
    );
  }
}
