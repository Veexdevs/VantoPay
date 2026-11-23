import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../data/services/pix_service.dart';
import '../../widgets/common.dart';

class PixScreen extends StatefulWidget {
  const PixScreen({super.key});

  @override
  State<PixScreen> createState() => _PixScreenState();
}

class _PixScreenState extends State<PixScreen> {
  List<PixKey> _keys = [];
  List<Transaction> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final keys = await PixService.instance.keys();
      final history = await PixService.instance.history(limit: 6);
      setState(() {
        _keys = keys;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('PIX')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text('Tudo sobre PIX',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              VPCard(
                child: Column(
                  children: [
                    _Entry(
                      icon: Icons.send_outlined,
                      title: 'Enviar PIX',
                      subtitle: 'Por chave, QR Code ou cópia e cola',
                      onTap: () => context.push('/pix/send'),
                    ),
                    const _DividerLine(),
                    _Entry(
                      icon: Icons.qr_code_outlined,
                      title: 'Receber PIX',
                      subtitle: 'Cobrança com QR Code e cópia e cola',
                      onTap: () => context.push('/pix/receive'),
                    ),
                    const _DividerLine(),
                    _Entry(
                      icon: Icons.key_outlined,
                      title: 'Chaves PIX',
                      subtitle: 'Gerenciar chaves cadastradas',
                      onTap: () => context.push('/pix/keys'),
                    ),
                    const _DividerLine(),
                    _Entry(
                      icon: Icons.history_outlined,
                      title: 'Histórico PIX',
                      subtitle: 'Envios, recebimentos e comprovantes',
                      onTap: () => context.push('/pix/history'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: SectionHeader(title: 'Chaves')),
                  TextButton(
                      onPressed: () => context.push('/pix/keys'),
                      child: const Text('Gerenciar')),
                ],
              ),
              const SizedBox(height: 8),
              _keys.isEmpty
                  ? const EmptyState(message: 'Nenhuma chave PIX cadastrada.',
                      icon: Icons.key_outlined)
                  : VPCard(
                      child: Column(
                        children: [
                          for (final k in _keys)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.key, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(k.keyValue,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(k.keyType,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? VantoPayTheme.ghost
                                                    : const Color(0xFF6B6B70))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: SectionHeader(title: 'Recentes')),
                ],
              ),
              const SizedBox(height: 8),
              _history.isEmpty
                  ? const EmptyState(message: 'Nenhuma movimentação PIX.')
                  : VPCard(
                      child: Column(
                        children: [
                          for (final tx in _history)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 4),
                              child: Row(
                                children: [
                                  Icon(tx.isCredit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                      size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(tx.isCredit ? 'PIX recebido' : 'PIX enviado',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            tx.counterpartyName ?? '—',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? VantoPayTheme.ghost
                                                    : const Color(0xFF6B6B70))),
                                      ],
                                    ),
                                  ),
                                  Text('${tx.isCredit ? '+' : '−'}${AppFormat.brlDecimal(tx.amount)}'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.icon, required this.title, required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? VantoPayTheme.surfaceAlt : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();
  @override
  Widget build(BuildContext context) => Divider(
        height: 24,
        color: Theme.of(context).brightness == Brightness.dark
            ? VantoPayTheme.line
            : VantoPayTheme.paperLine,
      );
}
