import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Account? _account;
  Balance? _balance;
  List<Transaction> _recent = [];
  bool _loading = true;
  bool _showBalance = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final acc = await AccountService.instance.fetchAccount();
      final bal = await AccountService.instance.fetchBalance();
      final txs = await AccountService.instance.transactions(limit: 5);
      setState(() {
        _account = acc;
        _balance = bal;
        _recent = txs;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar o saldo. Verifique a conectividade.';
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Boa noite';
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _account?.holderName ?? 'usuário';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Logo(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_greeting(),',
                            style: TextStyle(
                                color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    tooltip: _showBalance ? 'Ocultar saldo' : 'Mostrar saldo',
                    onPressed: () => setState(() => _showBalance = !_showBalance),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Balance card
              _buildBalanceCard(),
              const SizedBox(height: 20),

              // Quick actions
              VPCard(
                child: Column(
                  children: [
                    _QuickActionGrid(
                      onPix: () => context.push('/pix'),
                      onTransfer: () => context.push('/transfer'),
                      onDeposit: () => context.push('/pix/receive'),
                      onPay: () => context.push('/pay'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent activity
              Row(
                children: [
                  const Expanded(
                    child: SectionHeader(title: 'Últimas movimentações'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/statement'),
                    child: const Text('Extrato'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildActivity(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final b = _balance;
    return VPCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo disponível',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _showBalance ? AppFormat.brlDecimal(b?.amount ?? 0) : '••••••',
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _account?.currency ?? 'BRL',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? VantoPayTheme.ghost
                        : const Color(0xFF6B6B70)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Conta ${_account?.accountNumber ?? ''}',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? VantoPayTheme.ghost
                      : const Color(0xFF6B6B70))),
        ],
      ),
    );
  }

  Widget _buildActivity(bool isDark) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(),
      );
    }
    if (_recent.isEmpty) {
      return const EmptyState(message: 'Nenhuma movimentação recente.', icon: Icons.inbox_outlined);
    }
    return VPCard(
      child: Column(
        children: [
          for (final tx in _recent)
            Container(
              margin: const EdgeInsets.only(bottom: 16, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (isDark ? VantoPayTheme.surfaceAlt : const Color(0xFFF4F4F5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconFor(tx.kind), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_labelFor(tx),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(_sublabelFor(tx),
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? VantoPayTheme.ghost
                                    : const Color(0xFF6B6B70))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tx.isCredit ? '+' : '−'}${AppFormat.brlDecimal(tx.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(AppFormat.date(tx.createdAt),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? VantoPayTheme.ghost
                                  : const Color(0xFF6B6B70))),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'pix_receive':
        return Icons.qr_code_outlined;
      case 'pix_send':
        return Icons.send_outlined;
      case 'transfer_internal':
      case 'transfer_external':
        return Icons.swap_horiz;
      case 'deposit':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _labelFor(Transaction tx) {
    switch (tx.kind) {
      case 'pix_receive':
        return 'PIX recebido';
      case 'pix_send':
        return 'PIX enviado';
      case 'transfer_internal':
        return 'Transferência';
      case 'transfer_external':
        return 'Transferência externa';
      case 'deposit':
        return 'Depósito';
      default:
        return tx.kind;
    }
  }

  String _sublabelFor(Transaction tx) {
    final parts = <String>[];
    if (tx.counterpartyName != null && tx.counterpartyName!.isNotEmpty) {
      parts.add(tx.counterpartyName!);
    }
    if (tx.counterpartyInstitution != null &&
        tx.counterpartyInstitution!.isNotEmpty) {
      parts.add(tx.counterpartyInstitution!);
    }
    final who = parts.isEmpty ? 'VantoPay' : parts.join(' · ');
    return who;
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.onPix,
    required this.onTransfer,
    required this.onDeposit,
    required this.onPay,
  });
  final VoidCallback onPix;
  final VoidCallback onTransfer;
  final VoidCallback onDeposit;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? VantoPayTheme.surfaceAlt : const Color(0xFFF4F4F5);
    final foreground =
        isDark ? VantoPayTheme.paper : VantoPayTheme.ink;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _action(context, Icons.qr_code_outlined, 'PIX', onPix, surface, foreground),
        _action(context, Icons.swap_horiz, 'Transferir', onTransfer, surface, foreground),
        _action(context, Icons.add_circle_outline, 'Depositar', onDeposit, surface, foreground),
        _action(context, Icons.payment_outlined, 'Pagar', onPay, surface, foreground),
      ],
    );
  }

  Widget _action(BuildContext context, IconData icon, String label,
      VoidCallback onTap, Color surface, Color foreground) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: foreground, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: foreground)),
        ],
      ),
    );
  }
}
