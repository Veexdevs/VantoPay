import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/api_client.dart';
import '../../data/services/transfer_service.dart';
import '../../widgets/common.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  bool _internal = true;
  final _destCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _digitCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  bool _reviewing = false;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _destCtrl.dispose();
    _nameCtrl.dispose();
    _docCtrl.dispose();
    _bankCtrl.dispose();
    _digitCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  bool get _valid {
    final amount = _amountCtrl.text.trim();
    if (double.tryParse(amount)?.isNegative == true || double.tryParse(amount) == null) {
      return false;
    }
    if (_internal) return _destCtrl.text.trim().length == 8;
    return _nameCtrl.text.trim().isNotEmpty &&
        _docCtrl.text.trim().isNotEmpty &&
        _bankCtrl.text.trim().isNotEmpty &&
        _destCtrl.text.trim().isNotEmpty &&
        _digitCtrl.text.trim().isNotEmpty;
  }

  void _goReview() {
    if (!_valid) {
      setState(() => _error = 'Preencha todos os campos corretamente.');
      return;
    }
    setState(() {
      _error = null;
      _reviewing = true;
    });
  }

  Future<void> _confirm() async {
    final amount = Decimal.parse(_amountCtrl.text.trim());
    final key = AppFormat.idempotencyKey('tr');
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final result = _internal
          ? await TransferService.instance.internal(
              destinationAccountNumber: _destCtrl.text.trim(),
              amount: amount,
              idempotencyKey: key,
              reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
            )
          : await TransferService.instance.external(
              destinationName: _nameCtrl.text.trim(),
              destinationDocument: _docCtrl.text.trim(),
              destinationBankCode: _bankCtrl.text.trim(),
              destinationAccountNumber: _destCtrl.text.trim(),
              destinationAccountDigit: _digitCtrl.text.trim(),
              amount: amount,
              idempotencyKey: key,
              reference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
            );
      setState(() {
        _result = result;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _submitting = false;
        _reviewing = false;
        _error = e is ApiException
            ? e.message
            : 'Erro ao realizar a transferência.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _resultScreen();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScreenScaffold(
      title: 'Transferir',
      subtitle: _internal ? 'Entre contas VantoPay' : 'Para outro banco',
      body: _reviewing
          ? _reviewSection(isDark)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('VantoPay')),
                    ButtonSegment(value: false, label: Text('Outro banco')),
                  ],
                  selected: {_internal},
                  onSelectionChanged: (s) => setState(() => _internal = s.first),
                ),
                const SizedBox(height: 20),
                if (_internal)
                  TextField(
                    controller: _destCtrl,
                    keyboardType: TextInputType.number,
                    lengthLimitingTextInput: 8,
                    decoration: const InputDecoration(
                      labelText: 'Número da conta VantoPay',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _destCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Agência / conta',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _digitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dígito da conta',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bankCtrl,
                    keyboardType: TextInputType.number,
                    lengthLimitingTextInput: 3,
                    decoration: const InputDecoration(
                      labelText: 'Código do banco (3 dígitos)',
                      prefixIcon: Icon(Icons.bank_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do recebedor',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _docCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CPF/CNPJ do recebedor',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R$)',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    prefixIcon: Icon(Icons.note_outline),
                  ),
                ),
                if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
                const SizedBox(height: 24),
                VPButton(label: 'Continuar', icon: Icons.arrow_forward, onPressed: _goReview),
                if (!_internal)
                  const IntegrationNotice(
                    title: 'Transferência externa',
                    detail:
                        'Depende de um gateway de pagamento configurado. Sem credenciais, a operação não é realizada.',
                  ),
              ],
            ),
    );
  }

  Widget _reviewSection(bool isDark) {
    final label = _internal ? 'Conta VantoPay' : 'Conta externa';
    final value = _internal
        ? _destCtrl.text
        : '${_bankCtrl.text} · ${_destCtrl.text}/${_digitCtrl.text} · ${_nameCtrl.text}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirme a operação',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        VPCard(
          child: Column(
            children: [
              _reviewRow('Destino', label),
              const SizedBox(height: 8),
              _reviewRow('Conta', value),
              const SizedBox(height: 8),
              _reviewRow('Valor', AppFormat.brlDecimal(_amountCtrl.text)),
              if (_refCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _reviewRow('Observação', _refCtrl.text.trim()),
              ],
            ],
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
        const SizedBox(height: 24),
        VPButton(
          label: 'Confirmar envio',
          icon: Icons.check,
          loading: _submitting,
          onPressed: _confirm,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _reviewing = false),
          child: const Text('Voltar'),
        ),
        const SizedBox(height: 8),
        Text(
          'A operação é idempotente: o uso da mesma chave não duplica o débito.',
          style: TextStyle(
              fontSize: 12,
              color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70)),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? VantoPayTheme.ghost
                        : const Color(0xFF6B6B70))),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _resultScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Transferência')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 56,
                  color: isDark ? VantoPayTheme.paper : VantoPayTheme.ink),
              const SizedBox(height: 16),
              const Text('Operação concluída',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              VPCard(
                child: Column(
                  children: [
                    _reviewRow('Valor', AppFormat.brlDecimal(_result!['transaction']?['amount']?.toString() ?? '0')),
                    const SizedBox(height: 8),
                    _reviewRow('Saldo', AppFormat.brlDecimal(_result!['source_balance']?.toString() ?? '0')),
                    const SizedBox(height: 8),
                    _reviewRow('Status', _result!['status']?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              VPButton(
                label: 'Voltar ao início',
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
