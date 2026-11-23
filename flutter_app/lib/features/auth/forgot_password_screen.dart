import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/supabase_service.dart';
import '../../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Informe o e-mail.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await AuthService.instance.forgotPassword(email);
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Não foi possível enviar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.lock_reset_outlined,
                  size: 48,
                  color: isDark ? VantoPayTheme.paper : VantoPayTheme.ink),
              const SizedBox(height: 16),
              const Text('Recuperar senha',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Informe o e-mail cadastrado. Enviaremos um link para '
                  'redefinir a senha.',
                  style: TextStyle(
                      color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
              const SizedBox(height: 24),
              VPButton(
                label: _sent ? 'Link enviado' : 'Enviar link',
                icon: Icons.send,
                loading: _loading,
                onPressed: _sent ? null : _submit,
              ),
              if (_sent) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Voltar ao login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
