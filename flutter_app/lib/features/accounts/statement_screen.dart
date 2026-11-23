import 'package:flutter/material.dart';

import '../../core/theme.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../widgets/common.dart';

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  List<StatementEntry> _entries = [];
  Balance? _balance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _entries = await AccountService.instance.statement(limit: 200);
        _balance = await AccountService.instance.fetchBalance();
      });
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScreenScaffold(
      title: 'Extrato',
      subtitle: 'Movimentações registradas no ledger',
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VPCard(
                  child: Column(
                    children: [
                      const Text('Saldo atual',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(AppFormat.brlDecimal(_balance?.amount ?? 0),
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _entries.isEmpty
                    ? const EmptyState(message: 'Nenhuma movimentação.', icon: Icons.receipt_long_outlined)
                    : VPCard(
                        child: Column(
                          children: [
                            for (final e in _entries.reversed)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14, top: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.description,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Text(AppFormat.dateTime(e.createdAt),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${e.entryType == 'credit' ? '+' : '−'}${AppFormat.brlDecimal(e.amount)}',
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(AppFormat.brlDecimal(e.balanceAfter),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
              ],
            ),
    );
  }
}
