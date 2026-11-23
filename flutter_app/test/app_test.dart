import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vantopay/core/theme.dart';
import 'package:vantopay/core/utils.dart';

void main() {
  test('BRL formatting is correct', () {
    expect(AppFormat.brl(150.0), 'R$ 150,00');
    expect(AppFormat.brl(0), 'R$ 0,00');
    expect(AppFormat.brl(1234.5), 'R$ 1.234,50');
  });

  test('signed formatting distinguishes flow', () {
    expect(AppFormat.brl(150.0, sign: true), '+R$ 150,00');
    expect(AppFormat.brl(-150.0, sign: true), '-R$ 150,00');
  });

  test('idempotency keys are unique', () {
    final a = AppFormat.idempotencyKey('tr');
    final b = AppFormat.idempotencyKey('tr');
    expect(a, isNot(b));
    expect(a.startsWith('tr-'), isTrue);
  });

  test('initials are computed', () {
    expect(AppFormat.initials('João Silva'), 'JS');
    expect(AppFormat.initials('Maria'), 'MA');
  });

  test('dark theme is monochrome (black and white)', () {
    const theme = VantoPayTheme.dark();
    expect(theme.brightness, Brightness.dark);
    // No chromatic accent colours: primary is white.
    expect(theme.colorScheme.primary, Color(0xFFFFFFFF));
  });

  test('light theme is monochrome (black and white)', () {
    const theme = VantoPayTheme.light();
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, Color(0xFF0A0A0A));
  });
}
