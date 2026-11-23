import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/api_client.dart';
import '../../data/services/pix_service.dart';
import '../../widgets/common.dart';

class PixReceiveScreen extends StatefulWidget {
  const PixReceiveScreen({super.key});

  @override
  State<PixReceiveScreen> createState() => _PixReceiveScreenState();
}

class _PixReceiveScreenState extends State<PixReceiveScreen> {
  final _amountCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  PixCharge? _charge;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final amount = _amountCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (amount.isEmpty || key.isEmpty) {
      setState(() => _error = 'Informe valor e chave PIX.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final charge = await PixService.instance.createCharge(
        Decimal.parse(amount),
        key,
      );
      setState(() {
        _charge = charge;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e is ApiException ? e.message : 'Erro ao criar cobrança.';
      });
    }
  }

  void _copy(String payload) {
    Clipboard.setData(ClipboardData(text: payload));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payload PIX copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Receber PIX',
      subtitle: 'Cobrança com QR Code e cópia e cola',
      trailing: TextButton(
        onPressed: () => context.go('/pix/keys'),
        child: const Text('Chaves'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            enabled: _charge == null,
            decoration: const InputDecoration(
              labelText: 'Valor (R$)',
              prefixIcon: Icon(Icons.attach_money_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            enabled: _charge == null,
            decoration: const InputDecoration(
              labelText: 'Chave PIX de cobrança',
              prefixIcon: Icon(Icons.key_outlined),
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
          const SizedBox(height: 24),
          VPButton(
            label: _charge == null ? 'Gerar cobrança' : 'Nova cobrança',
            icon: Icons.qr_code_outlined,
            loading: _submitting,
            onPressed: _charge == null ? _create : () => setState(() => _charge = null),
          ),
          if (_charge != null) ...[
            const SizedBox(height: 28),
            VPCard(
              child: Column(
                children: [
                  const Text('Comprovante PIX',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: _charge!.qrCodePayload ?? '',
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(AppFormat.brlDecimal(_charge!.amount),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Chave: ${_charge!.keyValue}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  VPButton(
                    label: 'Copiar payload',
                    icon: Icons.content_copy,
                    isOutline: true,
                    onPressed: () =>
                        _copy(_charge!.qrCodePayload ?? ''),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O recebimento do valor é confirmado pela instituição '
                    'responsável pelo processamento.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? VantoPayTheme.ghost
                            : const Color(0xFF6B6B70)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
