import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../data/services/supabase_service.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'Não foi possível iniciar com Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Informe e-mail e senha.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await AuthService.instance.signInWithEmail(email, pass);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = 'E-mail ou senha inválidos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? VantoPayTheme.ink : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Logo(size: 72),
                const SizedBox(height: 20),
                const Text(
                  AppConfig.appName,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConfig.tagline,
                  style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 3,
                      color: isDark
                          ? VantoPayTheme.ghost
                          : const Color(0xFF6B6B70)),
                ),
                const SizedBox(height: 40),
                if (!AppConfig.isConfigured)
                  const IntegrationNotice(
                    title: 'Autenticação não configurada',
                    detail:
                        'Defina SUPABASE_URL e SUPABASE_ANON_KEY (via --dart-define, GitHub Secrets ou variáveis do Vercel) para ativar o login.',
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Continuar com Google'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? VantoPayTheme.line : VantoPayTheme.paperLine)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ENTRAR COM E-MAIL',
                          style: TextStyle(fontSize: 11, letterSpacing: 2)),
                    ),
                    Expanded(child: Divider(color: isDark ? VantoPayTheme.line : VantoPayTheme.paperLine)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null) ...[const SizedBox(height: 12), ErrorBanner(message: _error!)],
                const SizedBox(height: 20),
                VPButton(
                  label: 'Entrar',
                  icon: Icons.login,
                  loading: _loading,
                  onPressed: _signInWithEmail,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/forgot'),
                      child: const Text('Esqueci a senha'),
                    ),
                    const Text(' · '),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
