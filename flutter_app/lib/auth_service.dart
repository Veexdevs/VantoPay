import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthService {
  bool get isSignedIn;
  String? get email;
  bool get needsVerification;
  Stream<bool> get sessionChanges;
  Future<bool> signUp(String name, String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> verifyEmail(String email, String code);
  Future<void> resendCode(String email);
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this.client, {required this.url, required this.publicKey,
    http.Client? transport, Uri? apiUri,
  }) : _transport = transport ?? http.Client(),
       _apiUri = apiUri ?? Uri.base.resolve('/api/auth') {
    _authSubscription = client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        unawaited(_exchangeOAuth(event.session!));
      }
    });
    _ready = _restore();
  }
  final SupabaseClient client;
  final String url;
  final String publicKey;
  final http.Client _transport;
  final Uri _apiUri;
  late final Future<void> _ready;
  late final StreamSubscription<AuthState> _authSubscription;
  int _requestVersion = 0;

  Future<void> dispose() async {
    await _authSubscription.cancel();
    await _changes.close();
    _transport.close();
  }
  final _changes = StreamController<bool>.broadcast();
  bool _signedIn = false;
  bool _pending = false;
  bool _exchanging = false;
  String? _email;

  String get redirectUrl => Uri.base.replace(path: '/', query: '', fragment: '').toString();
  @override
  bool get isSignedIn => _signedIn;
  @override
  bool get needsVerification => _pending;
  @override
  String? get email => _email;
  @override
  Stream<bool> get sessionChanges => _changes.stream;

  Future<void> _request(String action, [Map<String, dynamic> values = const {}]) async {
    final version = ++_requestVersion;
    final response = await _transport.post(_apiUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': action, ...values}),
    ).timeout(const Duration(seconds: 40));
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const AuthException('Invalid authentication server response', code: 'service_unavailable');
    }
    // A late bootstrap response must never overwrite a completed login/OAuth exchange.
    if (action == 'status' && version != _requestVersion) { return; }
    if (response.statusCode != 200) {
      if (data['pending'] == true) {
        _pending = true;
        _signedIn = false;
        _email = data['email'] as String?;
        _changes.add(false);
      }
      throw AuthException('Server authentication failed', code: data['code'] as String?);
    }
    _signedIn = data['verified'] == true;
    _pending = data['pending'] == true;
    _email = data['email'] as String?;
    _changes.add(_signedIn);
  }

  Future<void> _restore() async {
    try {
      if (client.auth.currentSession != null) {
        await _exchangeOAuth(client.auth.currentSession!);
      } else {
        await _request('status');
      }
    } catch (_) {
      // A failed restore must never grant access. An explicit login can retry.
    }
  }

  Future<void> _exchangeOAuth(Session session) async {
    if (_exchanging) { return; }
    _exchanging = true;
    try {
      await _request('oauth', {'access_token': session.accessToken, 'refresh_token': session.refreshToken});
      // Tokens live only in encrypted HttpOnly server cookies after exchange.
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (error) {
      _signedIn = false;
      _changes.addError(error);
    } finally {
      _exchanging = false;
    }
  }

  @override
  Future<bool> signUp(String name, String email, String password) async {
    await _ready;
    await _request('signup', {'display_name': name, 'email': email, 'password': password});
    return isSignedIn;
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _ready;
    await _request('login', {'email': email, 'password': password});
  }

  @override
  Future<void> signInWithGoogle() async {
    await _ready;
    // Check the public provider settings before leaving the app. Otherwise a
    // disabled provider would redirect visitors to a raw Supabase error page.
    final response = await _transport.get(
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
  Future<void> verifyEmail(String email, String code) => _request('verify', {'code': code});

  @override
  Future<void> resendCode(String email) => _request('resend');

  @override
  Future<void> signOut() async {
    await _request('logout');
    await client.auth.signOut(scope: SignOutScope.local);
  }

}

String friendlyAuthError(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'E-mail ou senha incorretos. Confira seus dados.';
      case 'email_not_confirmed':
        return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
      case 'signup_unavailable':
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
        return 'O acesso com Google ainda precisa ser ativado pelo VantoPay. Use seu e-mail por enquanto.';
      case 'server_configuration':
      case 'service_unavailable':
        return 'O serviço de acesso está temporariamente indisponível. Tente novamente em instantes.';
      case 'validation_failed':
        return 'Este método de acesso ainda não está disponível. Tente entrar com e-mail.';
      case 'email_address_invalid':
        return 'Informe um endereço de e-mail válido.';
      case 'email_address_not_authorized':
      case 'email_delivery_failed':
        return 'Não foi possível enviar seu código agora. Aguarde e toque em reenviar.';
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
