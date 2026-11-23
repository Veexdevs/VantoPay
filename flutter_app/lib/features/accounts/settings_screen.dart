import 'package:flutter/material.dart';

import '../../core/theme.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../data/services/api_client.dart';
import '../../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Account? _account;
  final _txLimitCtrl = TextEditingController();
  final _dailyLimitCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _saved;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _txLimitCtrl.dispose();
    _dailyLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final acc = await AccountService.instance.fetchAccount();
      setState(() {
        _account = acc;
        _txLimitCtrl.text = (acc.transactionLimit).toStringAsFixed(2);
        _dailyLimitCtrl.text = (acc.dailyLimit).toStringAsFixed(2);
      });
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final tx = double.tryParse(_txLimitCtrl.text.trim());
    final daily = double.tryParse(_dailyLimitCtrl.text.trim());
    if (tx == null || daily == null || tx < 0 || daily < 0) {
      setState(() => _error = 'Informe valores válidos (não negativos).');
      return;
    }
    setState(() {
      _error = null;
      _saved = null;
      _saving = true;
    });
    try {
      final acc = await AccountService.instance.updateLimits(
          transactionLimit: tx, dailyLimit: daily);
      setState(() {
        _account = acc;
        _saving = false;
        _saved = 'Limites atualizados.';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e is ApiException ? e.message : 'Erro ao atualizar limites.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Configurações',
      subtitle: 'Limites de transação',
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _txLimitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Limite por transação (R\$)',
                    prefixIcon: Icon(Icons.tune_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dailyLimitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Limite diário (R\$)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
                if (_saved != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(_saved!, style: const TextStyle(color: VantoPayTheme.paper)),
                  ),
                const SizedBox(height: 24),
                VPButton(
                  label: 'Salvar limites',
                  icon: Icons.save,
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
                const IntegrationNotice(
                  title: 'Segurança',
                  detail:
                      'O saldo é calculado pelo ledger no backend. Limites são validados server-side; o app nunca define saldos diretamente.',
                ),
              ],
            ),
    );
  }
}
