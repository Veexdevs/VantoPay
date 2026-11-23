import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import 'api_client.dart';

enum AuthState { unknown, unauthenticated, authenticated }

/// Supabase Auth integration: email/password, Google OAuth, password recovery,
/// email verification and secure session persistence.
///
/// Google OAuth is configured in the Supabase auth provider settings; the app
/// only triggers it. No credentials are stored in source code.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient? _client;
  AuthState _state = AuthState.unknown;
  String? _email;

  AuthState get state => _state;
  String? get email => _email;
  SupabaseClient? get client => _client;

  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> initialize() async {
    if (_client != null) return;
    if (!AppConfig.isConfigured) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return;
    }
    _client = Supabase.initialize(
      AppConfig.supabaseUrl,
      AppConfig.supabaseAnonKey,
      googleClientId: AppConfig.googleClientId.isNotEmpty
          ? AppConfig.googleClientId
          : null,
      autoRefreshToken: true,
      persistSession: true,
    );
    _client!.auth.stream.listen((event) {
      final session = _client!.auth.currentSession;
      if (session != null) {
        ApiClient.setToken(session.accessToken);
        _state = AuthState.authenticated;
        _email = session.user?.email;
      } else {
        ApiClient.setToken(null);
        _state = AuthState.unauthenticated;
        _email = null;
      }
      notifyListeners();
    });
  }

  Future<void> _refreshToken() async {
    final session = _client?.auth.currentSession;
    if (session != null) {
      ApiClient.setToken(session.accessToken);
    }
  }

  /// Continue with Google OAuth (provider configured in Supabase).
  Future<void> signInWithGoogle() async {
    _requireClient();
    // Supabase handles the in-app OAuth redirect; the provider is configured
    // in the Supabase auth settings.
    await _client!.auth.signInWithOAuth(const OAuthProvider.google);
  }

  Future<void> signInWithEmail(String email, String password) async {
    _requireClient();
    await _client!.auth.signInWithPassword(
        {'email': email, 'password': password});
    await _afterAuth();
  }

  Future<void> signUp(String email, String password) async {
    _requireClient();
    await _client!.auth.signUp({'email': email, 'password': password});
    // Supabase sends a confirmation email; the user must verify before login.
  }

  Future<void> resendConfirmation(String email) async {
    _requireClient();
    await _client!.auth.resendConfirmationEmail(email);
  }

  Future<void> forgotPassword(String email) async {
    _requireClient();
    await _client!.auth.resetPasswordForEmail(email);
  }

  Future<void> setNewPassword(String newPassword) async {
    _requireClient();
    await _client!.auth.updateUser({'password': newPassword});
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
    ApiClient.setToken(null);
    _state = AuthState.unauthenticated;
    _email = null;
    notifyListeners();
  }

  Future<void> _afterAuth() async {
    await _refreshToken();
    final session = _client?.auth.currentSession;
    if (session != null) {
      _state = AuthState.authenticated;
      _email = session.user?.email;
    }
    notifyListeners();
  }

  void _requireClient() {
    if (_client == null) {
      throw StateError(
          'Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY.');
    }
  }
}
