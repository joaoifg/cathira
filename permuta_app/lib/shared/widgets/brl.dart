import 'package:intl/intl.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
final _brlDec = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

String brl(num? v, {bool decimals = false}) {
  if (v == null) return '—';
  return decimals ? _brlDec.format(v) : _brl.format(v);
}
