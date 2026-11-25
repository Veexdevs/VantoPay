import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vantopay/auth_service.dart';

void main() {
  test('auth errors have actionable Portuguese messages', () {
    expect(
      friendlyAuthError(const AuthException('Invalid login', code: 'invalid_credentials')),
      contains('E-mail ou senha incorretos'),
    );
    expect(
      friendlyAuthError(const AuthException('Expired', code: 'otp_expired')),
      contains('Código inválido ou expirado'),
    );
    expect(
      friendlyAuthError(const AuthException('Limited', code: 'over_email_send_rate_limit')),
      contains('Aguarde alguns minutos'),
    );
    expect(
      friendlyAuthError(const AuthException('Disabled', code: 'provider_disabled')),
      contains('Google ainda precisa ser ativado'),
    );
  });

  test('unknown failures do not expose server details or tokens', () {
    const internal = 'PRIVATE_SERVER_DETAILS';
    expect(friendlyAuthError(const AuthException(internal)), isNot(contains(internal)));
    expect(friendlyAuthError(StateError(internal)), contains('Verifique sua internet'));
  });
}
