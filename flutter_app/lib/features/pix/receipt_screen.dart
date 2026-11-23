import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/api_client.dart';
import '../../data/services/pix_service.dart';
import '../../widgets/common.dart';

/// Displays a PIX transaction receipt (comprovante). Counterparty details are
/// shown only when provided by the processing institution; documents are always
/// masked.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Transaction? _tx;
  bool _loading = true;
  String? _error;

  String? get _id {
    final segments = GoRouterState.of(context).uri.pathSegments;
    return segments.isNotEmpty ? segments.last : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null) {
      setState(() => _error = 'Transação não encontrada.');
      return;
    }
    try {
      setState(() => _tx = await PixService.instance.transaction(id));
    } catch (e) {
      setState(() =>
          _error = e is ApiException ? e.message : 'Erro ao carregar comprovante.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = _tx;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprovante')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprovante')),
        body: Center(child: Text(_error ?? 'Transação não encontrada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Comprovante')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: VPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.isCredit ? 'PIX RECEBIDO' : 'PIX ENVIO',
                    style: const TextStyle(fontSize: 13, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(tx.isCredit ? '+${AppFormat.brlDecimal(tx.amount)}' : '−${AppFormat.brlDecimal(tx.amount)}',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(AppFormat.dateTime(tx.createdAt),
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                _Row(label: 'Tipo', value: tx.isCredit ? 'Recebimento' : 'Envio'),
                _Row(label: 'Status', value: tx.status),
                if (tx.counterpartyName != null && tx.counterpartyName!.isNotEmpty)
                  _Row(label: 'Origem', value: tx.counterpartyName!),
                if (tx.counterpartyInstitution != null &&
                    tx.counterpartyInstitution!.isNotEmpty)
                  _Row(label: 'Instituição', value: tx.counterpartyInstitution!),
                if (tx.counterpartyDocumentMasked != null)
                  _Row(label: 'Documento', value: tx.counterpartyDocumentMasked!),
                _Row(label: 'Referência', value: tx.externalReference ?? '—'),
                const SizedBox(height: 20),
                Text(
                  'Os dados do remetente são exibidos apenas quando disponibilizados '
                  'pela instituição de origem. Documentos e dados sensíveis são '
                  'mascarados.',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
