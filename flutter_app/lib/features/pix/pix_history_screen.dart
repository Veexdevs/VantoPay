import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/pix_service.dart';
import '../../widgets/common.dart';

class PixHistoryScreen extends StatefulWidget {
  const PixHistoryScreen({super.key});

  @override
  State<PixHistoryScreen> createState() => _PixHistoryScreenState();
}

class _PixHistoryScreenState extends State<PixHistoryScreen> {
  List<Transaction> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await PixService.instance.history(limit: 100);
      setState(() => _items = items);
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
      title: 'Histórico PIX',
      subtitle: 'Envios e recebimentos',
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            )
          : _items.isEmpty
              ? const EmptyState(message: 'Nenhuma movimentação PIX.',
                  icon: Icons.history_outlined)
              : VPCard(
                  child: Column(
                    children: [
                      for (final tx in _items)
                        GestureDetector(
                          onTap: () =>
                              context.push('/pix/receipt/${tx.id}'),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? VantoPayTheme.surfaceAlt
                                        : const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                      tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tx.isCredit ? 'PIX recebido' : 'PIX enviado',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(tx.counterpartyName != null &&
                                              tx.counterpartyName!.isNotEmpty
                                          ? tx.counterpartyName!
                                          : '—',
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
                                    Text('${tx.isCredit ? '+' : '−'}${AppFormat.brlDecimal(tx.amount)}',
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(AppFormat.dateTime(tx.createdAt),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
