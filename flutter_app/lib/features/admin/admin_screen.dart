import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/admin_service.dart';
import '../../data/services/api_client.dart';
import '../../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<SuspiciousEvent> _suspicious = [];
  List<AuditLog> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      setState(() {
        _accounts = [];
        _transactions = [];
        _suspicious = [];
        _logs = [];
      });
      _accounts = await AdminService.instance.accounts();
      _transactions = await AdminService.instance.transactions(limit: 50);
      _suspicious = await AdminService.instance.suspicious(limit: 50);
      _logs = await AdminService.instance.auditLogs(limit: 50);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Erro ao carregar o painel.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel administrativo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Contas'),
              Tab(text: 'Transações'),
              Tab(text: 'Suspeitas'),
              Tab(text: 'Logs'),
            ],
          ),
        ),
        body: _error != null
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ErrorBanner(message: _error!),
                    VPButton(
                      label: 'Recarregar',
                      isOutline: true,
                      onPressed: _loadAll,
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _accountsTab(),
                  _transactionsTab(),
                  _suspiciousTab(),
                  _logsTab(),
                ],
              ),
      ),
    );
  }

  Widget _accountsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        for (final a in _accounts)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(a.holderName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${a.accountNumber} · ${a.status}'),
                  if (a.isAdmin) const Text('Administrador'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (a.status != 'blocked')
                    IconButton(
                      icon: const Icon(Icons.lock_outlined),
                      tooltip: 'Bloquear',
                      onPressed: () async {
                        await AdminService.instance.blockAccount(a.id);
                        _loadAll();
                      },
                    ),
                  if (a.status == 'blocked')
                    IconButton(
                      icon: const Icon(Icons.lock_open_outlined),
                      tooltip: 'Liberar',
                      onPressed: () async {
                        await AdminService.instance.unblockAccount(a.id);
                        _loadAll();
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _transactionsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_transactions.isEmpty)
      return const EmptyState(message: 'Nenhuma transação.');
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        for (final t in _transactions)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(t.isCredit ? Icons.arrow_downward : Icons.arrow_upward),
              title: Text(_kindLabel(t.kind)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.isCredit ? '+' : '−'}${AppFormat.brlDecimal(t.amount)}'),
                  Text(t.counterpartyName ?? '—'),
                  Text(AppFormat.dateTime(t.createdAt)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _suspiciousTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_suspicious.isEmpty)
      return const EmptyState(message: 'Nenhuma atividade suspeita.');
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        for (final s in _suspicious)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text(s.reason),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pontuação: ${s.score}'),
                  Text(AppFormat.dateTime(s.createdAt)),
                ],
              ),
              trailing: s.resolved
                  ? const Text('Resolvido')
                  : IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Resolver',
                      onPressed: () async {
                        await AdminService.instance.resolveSuspicious(s.id);
                        _loadAll();
                      },
                    ),
            ),
          ),
      ],
    );
  }

  Widget _logsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) return const EmptyState(message: 'Nenhum log.');
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        for (final log in _logs)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.history_outlined),
              title: Text(log.action),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${log.actorRole} · ${log.target ?? '—'}'),
                  if (log.ipAddress != null) Text('IP: ${log.ipAddress}'),
                  Text(AppFormat.dateTime(log.createdAt)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'pix_receive':
        return 'PIX recebido';
      case 'pix_send':
        return 'PIX enviado';
      case 'transfer_internal':
        return 'Transferência';
      case 'transfer_external':
        return 'Transferência externa';
      default:
        return kind;
    }
  }
}
