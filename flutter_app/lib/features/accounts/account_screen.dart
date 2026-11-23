import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../data/services/api_client.dart';
import '../../data/services/supabase_service.dart';
import '../../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Account? _account;
  Balance? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final account = await AccountService.instance.fetchAccount();
      final balance = await AccountService.instance.fetchBalance();
      setState(() {
        _account = account;
        _balance = balance;
      });
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _blockOrClose(bool close) async {
    final msg = close ? 'Encerrar conta?' : 'Bloquear conta?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(msg),
        content: Text(close
            ? 'Esta ação encerra a conta. Confirme para continuar.'
            : 'A conta ficará temporariamente bloqueada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (close) {
        await AccountService.instance.close();
      } else {
        await AccountService.instance.block();
      }
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Erro na operação.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScreenScaffold(
      title: 'Perfil',
      trailing: IconButton(
        icon: const Icon(Icons.logout_outlined),
        onPressed: _signOut,
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? VantoPayTheme.surfaceAlt : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                          child: Text('VP',
                              style: TextStyle(fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_account?.holderName ?? '',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_account?.documentMasked ?? '',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                VPCard(
                  child: Column(
                    children: [
                      _info('Conta', _account?.accountNumber ?? ''),
                      const SizedBox(height: 8),
                      _info('Saldo', AppFormat.brlDecimal(_balance?.amount ?? 0)),
                      const SizedBox(height: 8),
                      _info('Status', _account?.status ?? ''),
                      const SizedBox(height: 8),
                      _info('Limite por operação', AppFormat.brlDecimal(_account?.transactionLimit ?? 0)),
                      const SizedBox(height: 8),
                      _info('Limite diário', AppFormat.brlDecimal(_account?.dailyLimit ?? 0)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _Link('Extrato', Icons.receipt_long_outlined, () => context.push('/statement')),
                _Link('Configurações', Icons.settings_outlined, () => context.push('/settings')),
                _Link('Sessões e dispositivos', Icons.devices_outlined, () => context.push('/sessions')),
                if (_account?.isAdmin ?? false)
                  _Link('Painel administrativo', Icons.admin_panel_settings_outlined,
                      () => context.push('/admin')),
                const SizedBox(height: 16),
                _Link('Bloquear conta', Icons.lock_outlined, () => _blockOrClose(false)),
                _Link('Encerrar conta', Icons.close, () => _blockOrClose(true)),
              ],
            ),
    );
  }

  Widget _info(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22,
          color: isDark ? VantoPayTheme.paper : VantoPayTheme.ink),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
