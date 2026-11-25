import 'package:intl/intl.dart';

final _soles = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
final _fecha = DateFormat('d MMM yyyy', 'es_PE');
final _interes = NumberFormat('0.##', 'es_PE');

String soles(num valor) => _soles.format(valor);
String fechaCorta(DateTime valor) => _fecha.format(valor);
String porcentaje(num valor) => '${_interes.format(valor)} %';

DateTime hoyEnPeru() {
  final hora = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return DateTime(hora.year, hora.month, hora.day);
}

String importeEditable(double valor) =>
    valor.toStringAsFixed(2).replaceAll('.', ',');
