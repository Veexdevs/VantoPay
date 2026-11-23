import 'dart:math';

import 'package:intl/intl.dart';

/// Formatting and helper utilities.
class AppFormat {
  AppFormat._();

  static String brl(double value, {bool sign = false}) {
    final formatter = NumberFormat.currency(
        locale: 'pt_BR', symbol: 'R$', decimalDigits: 2);
    final text = formatter.format(value);
    if (sign && value != 0) {
      return '${value > 0 ? '+' : '-'}$text';
    }
    return text;
  }

  static String brlDecimal(Object value, {bool sign = false}) {
    final double v = double.tryParse(value.toString()) ?? 0;
    return brl(v, sign: sign);
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  static String date(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  /// Generates a client-side idempotency key so repeated submissions are not
  /// double-charged.
  static String idempotencyKey(String prefix) {
    final rand = Random().nextInt(0xFFFFFFFF).toRadixString(16);
    return '$prefix-$rand';
  }

  /// Title-case a raw institution/payer label for display.
  static String title(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return (parts.take(2).map((p) => p[0]).join()).toUpperCase();
  }
}
