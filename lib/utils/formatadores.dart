import 'package:intl/intl.dart';

final NumberFormat _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final NumberFormat _moeda3 =
    NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 3);
final DateFormat _dataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
final DateFormat _data = DateFormat('dd/MM/yyyy', 'pt_BR');
final DateFormat _dataCurta = DateFormat('dd/MM', 'pt_BR');
final DateFormat _hora = DateFormat('HH:mm', 'pt_BR');

String formatarMoeda(double valor) => _moeda.format(valor);

/// Moeda com 3 casas (útil para preço por litro e R$/km).
String formatarMoeda3(double valor) => _moeda3.format(valor);

String formatarNumero(double valor, {int casas = 2}) {
  final padrao = casas <= 0 ? '#,##0' : '#,##0.${'0' * casas}';
  return NumberFormat(padrao, 'pt_BR').format(valor);
}

String formatarDataHora(DateTime data) => _dataHora.format(data);
String formatarData(DateTime data) => _data.format(data);
String formatarDataCurta(DateTime data) => _dataCurta.format(data);
String formatarHora(DateTime data) => _hora.format(data);

/// Converte texto digitado (aceita "5,89", "5.89" ou "1.234,5") para double.
double? lerDecimal(String? texto) {
  if (texto == null) return null;
  var t = texto.trim().replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(t);
}
