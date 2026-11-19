import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/abastecimento.dart';
import '../state/app_state.dart';
import '../utils/formatadores.dart';

/// Formulário para registrar (ou editar) um abastecimento.
class AbastecimentoFormScreen extends StatefulWidget {
  const AbastecimentoFormScreen({
    super.key,
    required this.appState,
    this.abastecimento,
  });

  final AppState appState;

  /// Quando informado, a tela funciona em modo de edição.
  final Abastecimento? abastecimento;

  @override
  State<AbastecimentoFormScreen> createState() => _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState extends State<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _precoController;
  late final TextEditingController _kmController;
  late final TextEditingController _litrosController;

  late TipoCombustivel _combustivel;
  late DateTime _dataHora;
  bool _salvando = false;

  bool get _editando => widget.abastecimento != null;

  // Aceita apenas dígitos, vírgula e ponto.
  static final _formatoDecimal = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  @override
  void initState() {
    super.initState();
    final a = widget.abastecimento;
    _combustivel = a?.combustivel ?? _ultimoCombustivel() ?? TipoCombustivel.gasolina;
    _dataHora = a?.dataHora ?? DateTime.now();
    _precoController = TextEditingController(
      text: a == null ? '' : formatarNumero(a.precoLitro, casas: 2).replaceAll('.', ''),
    );
    _kmController = TextEditingController(
      text: a == null ? '' : a.quilometragem.toStringAsFixed(0),
    );
    _litrosController = TextEditingController(
      text: a == null ? '' : formatarNumero(a.litros, casas: 2).replaceAll('.', ''),
    );
    // Recalcula o valor total enquanto o usuário digita.
    _precoController.addListener(_atualizar);
    _litrosController.addListener(_atualizar);
  }

  TipoCombustivel? _ultimoCombustivel() {
    final lista = widget.appState.abastecimentos;
    return lista.isEmpty ? null : lista.last.combustivel;
  }

  void _atualizar() => setState(() {});

  @override
  void dispose() {
    _precoController.dispose();
    _kmController.dispose();
    _litrosController.dispose();
    super.dispose();
  }

  double? get _valorTotal {
    final preco = lerDecimal(_precoController.text);
    final litros = lerDecimal(_litrosController.text);
    if (preco == null || litros == null) return null;
    return preco * litros;
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Data do abastecimento',
    );
    if (data == null) return;
    setState(() {
      _dataHora = DateTime(data.year, data.month, data.day, _dataHora.hour, _dataHora.minute);
    });
  }

  Future<void> _escolherHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
      helpText: 'Horário do abastecimento',
    );
    if (hora == null) return;
    setState(() {
      _dataHora = DateTime(_dataHora.year, _dataHora.month, _dataHora.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final abastecimento = Abastecimento(
      id: widget.abastecimento?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      veiculoId: widget.appState.veiculo!.id,
      combustivel: _combustivel,
      precoLitro: lerDecimal(_precoController.text)!,
      quilometragem: lerDecimal(_kmController.text)!,
      litros: lerDecimal(_litrosController.text)!,
      dataHora: _dataHora,
    );

    await widget.appState.salvarAbastecimento(abastecimento);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_editando
            ? 'Abastecimento atualizado.'
            : 'Abastecimento de ${formatarMoeda(abastecimento.valorTotal)} registrado.'),
      ),
    );
  }

  String? _validarPositivo(String? valor, String campo) {
    final numero = lerDecimal(valor);
    if (numero == null) return 'Informe $campo';
    if (numero <= 0) return 'Deve ser maior que zero';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final total = _valorTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar abastecimento' : 'Novo abastecimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Combustível', style: tema.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TipoCombustivel>(
              segments: TipoCombustivel.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.rotulo)))
                  .toList(),
              selected: {_combustivel},
              onSelectionChanged: (s) => setState(() => _combustivel = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _precoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_formatoDecimal],
              decoration: const InputDecoration(
                labelText: 'Preço por litro',
                prefixText: r'R$ ',
                hintText: '5,89',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) => _validarPositivo(v, 'o preço por litro'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _litrosController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_formatoDecimal],
              decoration: const InputDecoration(
                labelText: 'Quantidade de litros',
                suffixText: 'L',
                hintText: '40,5',
                prefixIcon: Icon(Icons.water_drop_outlined),
              ),
              validator: (v) => _validarPositivo(v, 'a quantidade de litros'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kmController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_formatoDecimal],
              decoration: const InputDecoration(
                labelText: 'Quilometragem do veículo',
                suffixText: 'km',
                hintText: '45230',
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (v) {
                final erro = _validarPositivo(v, 'a quilometragem');
                if (erro != null) return erro;
                return widget.appState.validarQuilometragem(
                  lerDecimal(v)!,
                  _dataHora,
                  ignorarId: widget.abastecimento?.id,
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.event),
                    label: Text(formatarData(_dataHora)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherHora,
                    icon: const Icon(Icons.schedule),
                    label: Text(formatarHora(_dataHora)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: tema.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: tema.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Valor total',
                        style: tema.textTheme.titleMedium
                            ?.copyWith(color: tema.colorScheme.onPrimaryContainer),
                      ),
                    ),
                    Text(
                      total == null ? r'R$ --' : formatarMoeda(total),
                      style: tema.textTheme.headlineSmall?.copyWith(
                        color: tema.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Considere sempre abastecimentos que completam o tanque.',
              style: tema.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.save),
              label: Text(_editando ? 'Salvar alterações' : 'Registrar abastecimento'),
            ),
          ],
        ),
      ),
    );
  }
}
