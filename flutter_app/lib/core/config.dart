/// Central runtime configuration for the VantoPay app.
///
/// Real credentials are NEVER committed. At build time they are injected with
/// `--dart-define` (GitHub Secrets / Vercel env) or by editing the fallback
/// constants locally. See `.env.example` at the repository root.
class AppConfig {
  AppConfig._();

  static const String appName = 'VantoPay';
  static const String tagline = 'SEU DINHEIRO, SEU RITMO';

  /// Supabase project URL and anon key (OAuth + Auth).
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Backend REST API base URL.
  static const String apiBaseUrl =
      String.fromEnvironment('VANTOPAY_API_URL',
          defaultValue: 'http://localhost:8000');

  /// Google OAuth client id (managed by Supabase OAuth).
  static const String googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

  /// Official VantoPay logo assets.
  static const String logoAsset = 'assets/logos/official_1.png';
  static const List<String> logoAssets = [
    'assets/logos/official_1.png',
    'assets/logos/official_2.png',
    'assets/logos/official_3.png',
    'assets/logos/official_4.png',
    'assets/logos/official_5.png',
  ];

  /// Whether credentials are present. When false the app shows a clear
  /// setup notice instead of faking any data.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
