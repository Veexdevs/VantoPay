import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthService {
  bool get isSignedIn;
  String? get email;
  Stream<bool> get sessionChanges;
  Future<bool> signUp(String name, String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> verifyEmail(String email, String code);
  Future<void> resendCode(String email);
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this.client, {required this.url, required this.publicKey});
  final SupabaseClient client;
  final String url;
  final String publicKey;

  // Keep redirects on this deployment, never on localhost in production.
  String get redirectUrl => Uri.base.replace(path: '/', query: '', fragment: '').toString();

  @override
  bool get isSignedIn => client.auth.currentSession != null;
  @override
  String? get email => client.auth.currentUser?.email;
  @override
  Stream<bool> get sessionChanges => client.auth.onAuthStateChange
      .map((event) => event.session != null);

  @override
  Future<bool> signUp(String name, String email, String password) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
      emailRedirectTo: redirectUrl,
    );
    return response.session != null;
  }

  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    // Check the public provider settings before leaving the app. Otherwise a
    // disabled provider would redirect visitors to a raw Supabase error page.
    final response = await http.get(
      Uri.parse('$url/auth/v1/settings'),
      headers: {'apikey': publicKey},
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const AuthException('Unable to load authentication settings');
    }
    final settings = jsonDecode(response.body) as Map<String, dynamic>;
    if ((settings['external'] as Map<String, dynamic>?)?['google'] != true) {
      throw const AuthException('provider is not enabled', code: 'provider_disabled');
    }
    final opened = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
    if (!opened) {
      throw const AuthException('Não foi possível abrir o Google. Tente novamente.');
    }
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    await client.auth.verifyOTP(email: email, token: code, type: OtpType.signup);
  }

  @override
  Future<void> resendCode(String email) async {
    await client.auth.resend(type: OtpType.signup, email: email,
        emailRedirectTo: redirectUrl);
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}

String friendlyAuthError(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'E-mail ou senha incorretos. Confira seus dados.';
      case 'email_not_confirmed':
        return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
      case 'user_already_exists':
        return 'Já existe uma conta com este e-mail. Tente entrar.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'otp_expired':
        return 'Código inválido ou expirado. Confira ou solicite outro.';
      case 'weak_password':
        return 'Escolha uma senha mais forte, com pelo menos 8 caracteres.';
      case 'provider_disabled':
      case 'validation_failed':
        return 'Este método de acesso ainda não está disponível. Tente entrar com e-mail.';
      case 'email_address_invalid':
        return 'Informe um endereço de e-mail válido.';
      case 'email_address_not_authorized':
      case 'unexpected_failure':
        return 'Não foi possível enviar o e-mail. O envio precisa ser configurado pelo VantoPay.';
    }
    if (error.message.contains('provider is not enabled')) {
      return 'O acesso com Google ainda precisa ser ativado pelo VantoPay. Use seu e-mail por enquanto.';
    }
    return 'Não foi possível concluir. Confira seus dados e tente novamente.';
  }
  return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
}
