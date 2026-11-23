import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/supabase_service.dart';
import '../../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || name.isEmpty || pass.length < 6) {
      setState(() => _error = 'Preencha todos os campos (senha com 6+ caracteres).');
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await AuthService.instance.signUp(email, pass);
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Não foi possível criar a conta: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_sent) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 56,
                    color: isDark ? VantoPayTheme.paper : VantoPayTheme.ink),
                const SizedBox(height: 20),
                const Text('Verifique seu e-mail',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                  'Enviamos um link de confirmação para o endereço informado. '
                  'A conta é ativada após a verificação do e-mail.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70)),
                ),
                const SizedBox(height: 24),
                VPButton(
                  label: 'Voltar ao login',
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text('Crie sua conta VantoPay',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Informe seus dados. A verificação de e-mail é obrigatória.',
                  style: TextStyle(
                      color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
              const SizedBox(height: 24),
              VPButton(
                label: 'Criar conta',
                icon: Icons.person_add_outlined,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Já tenho uma conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
