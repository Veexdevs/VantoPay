import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../data/services/api_client.dart';
import '../../data/services/pix_service.dart';
import '../../widgets/common.dart';

class PixSendScreen extends StatefulWidget {
  const PixSendScreen({super.key});

  @override
  State<PixSendScreen> createState() => _PixSendScreenState();
}

class _PixSendScreenState extends State<PixSendScreen> {
  final _modeCtrl = TextEditingController(text: 'key');
  final _keyCtrl = TextEditingController();
  final _payloadCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  List<PixKey> _keys = [];
  bool _providerConfigured = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _modeCtrl.dispose();
    _keyCtrl.dispose();
    _payloadCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final statuses = await AccountService.instance.integrations();
      final keys = await PixService.instance.keys();
      setState(() {
        _providerConfigured =
            statuses.any((s) => s.name == 'pix_provider' && s.configured);
        _keys = keys;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final amount = _amountCtrl.text.trim();
    if (amount.isEmpty) {
      setState(() => _error = 'Informe o valor.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final key = AppFormat.idempotencyKey('pix');
      if (_modeCtrl.text.trim() == 'payload') {
        final payload = _payloadCtrl.text.trim();
        if (payload.isEmpty) {
          setState(() {
            _submitting = false;
            _error = 'Cole o payload PIX (cópia e cola).';
          });
          return;
        }
        await PixService.instance.sendByPayload(
            payloadPix: payload, idempotencyKey: key);
      } else {
        final keyValue = _keyCtrl.text.trim();
        if (keyValue.isEmpty) {
          setState(() {
            _submitting = false;
            _error = 'Informe a chave PIX.';
          });
          return;
        }
        await PixService.instance.sendByKey(
            keyValue: keyValue,
            amount: Decimal.parse(amount),
            idempotencyKey: key);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIX enviado com sucesso.')));
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e is ApiException ? e.message : 'Erro ao enviar PIX.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Enviar PIX',
      subtitle: 'Por chave, QR Code ou cópia e cola',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'key', label: Text('Por chave')),
              ButtonSegment(value: 'payload', label: Text('Cópia e cola')),
            ],
            selected: {_modeCtrl.text},
            onSelectionChanged: (s) => setState(() => _modeCtrl.text = s.first),
          ),
          const SizedBox(height: 20),
          if (_modeCtrl.text.trim() == 'key')
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _keyCtrl.text.isEmpty ? null : _keyCtrl.text,
                  hintText: 'Selecione uma chave',
                  items: _keys.map((k) => DropdownMenuItem(
                          value: k.keyValue, child: Text(k.keyValue))).toList(),
                  onChanged: (v) => _keyCtrl.text = v ?? '',
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _keyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Chave PIX (CPF, e-mail, telefone ou aleatória)',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
              ],
            )
          else
            TextField(
              controller: _payloadCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Cole o payload PIX (cópia e cola)',
                prefixIcon: Icon(Icons.content_paste_outlined),
              ),
            ),
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
          if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
          const SizedBox(height: 24),
          if (!_providerConfigured)
            const IntegrationNotice(
              title: 'Envio de PIX não configurado',
              detail:
                  'Esta funcionalidade depende de uma instituição participante / provedor PIX ainda não configurada. Defina PIX_PROVIDER_* no .env / GitHub Secrets para ativá-la.',
            ),
          if (_providerConfigured)
            VPButton(
              label: 'Enviar PIX',
              icon: Icons.send,
              loading: _submitting,
              onPressed: _submit,
            ),
        ],
      ),
    );
  }
}
