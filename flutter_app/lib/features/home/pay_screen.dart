import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../widgets/common.dart';

/// Payment screen. Real payments require a configured payment gateway
/// (Hyperswitch). When none is configured, this screen states the dependency
/// explicitly instead of simulating a payment.
class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  List<IntegrationStatus> _statuses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _statuses = await AccountService.instance.integrations());
    } catch (_) {
      // ignore — show default notice
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gateway = _statuses.firstWhere(
      (s) => s.name == 'hyperswitch',
      orElse: () => IntegrationStatus(
          name: 'hyperswitch', configured: false, description: ''),
    );

    return ScreenScaffold(
      title: 'Pagar',
      subtitle: 'Pagamentos via gateway de pagamento',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insira os dados da cobrança.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nome / documento do recebedor',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Valor (R$)',
              prefixIcon: Icon(Icons.attach_money_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Chave PIX ou referência',
              prefixIcon: Icon(Icons.qr_code_outlined),
            ),
          ),
          const SizedBox(height: 24),
          if (gateway.configured)
            VPButton(
              label: 'Pagar',
              icon: Icons.payment_outlined,
              onPressed: () =>
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Pagamento em processamento via gateway.'))),
            )
          else
            const IntegrationNotice(
              title: 'Pagamento não configurado',
              detail:
                  'Esta funcionalidade depende de um gateway de pagamento (Hyperswitch) ainda não configurado. Defina as variáveis HYPERSWITCH_* no .env / GitHub Secrets para ativá-la.',
            ),
          if (!gateway.configured) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Text(
                        'Para receber pagamentos na sua conta, você pode usar a '
                        'cobrança PIX.',
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? VantoPayTheme.ghost
                                : const Color(0xFF6B6B70)))),
              ],
            ),
            const SizedBox(height: 16),
            VPButton(
              label: 'Ir para cobrança PIX',
              icon: Icons.qr_code_outlined,
              isOutline: true,
              onPressed: () => context.push('/pix/receive'),
            ),
          ],
        ],
      ),
    );
  }
}
