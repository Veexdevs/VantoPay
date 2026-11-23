import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/models.dart';
import '../../data/services/api_client.dart';
import '../../data/services/pix_service.dart';
import '../../widgets/common.dart';

class PixKeysScreen extends StatefulWidget {
  const PixKeysScreen({super.key});

  @override
  State<PixKeysScreen> createState() => _PixKeysScreenState();
}

class _PixKeysScreenState extends State<PixKeysScreen> {
  List<PixKey> _keys = [];
  final _typeCtrl = TextEditingController(text: 'cpf');
  final _valueCtrl = TextEditingController();
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
    _typeCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final keys = await PixService.instance.keys();
      setState(() => _keys = keys);
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final value = _valueCtrl.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Informe o valor da chave.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await PixService.instance.addKey(_typeCtrl.text.trim(), value);
      _valueCtrl.clear();
      await _load();
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e is ApiException ? e.message : 'Erro ao adicionar chave.';
      });
    }
  }

  Future<void> _remove(PixKey key) async {
    try {
      await PixService.instance.deleteKey(key.id);
      await _load();
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScreenScaffold(
      title: 'Chaves PIX',
      subtitle: 'Gerencie as chaves da sua conta',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'cpf', label: Text('CPF')),
              ButtonSegment(value: 'email', label: Text('E-mail')),
              ButtonSegment(value: 'phone', label: Text('Telefone')),
              ButtonSegment(value: 'random', label: Text('Aleatória')),
            ],
            selected: {_typeCtrl.text},
            onSelectionChanged: (s) => setState(() => _typeCtrl.text = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueCtrl,
            decoration: const InputDecoration(
              labelText: 'Valor da chave',
              prefixIcon: Icon(Icons.key_outlined),
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 16), ErrorBanner(message: _error!)],
          const SizedBox(height: 24),
          VPButton(
            label: 'Adicionar chave',
            icon: Icons.add,
            loading: _submitting,
            onPressed: _add,
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            )
          else if (_keys.isEmpty)
            const EmptyState(message: 'Nenhuma chave cadastrada.', icon: Icons.key_outlined)
          else
            VPCard(
              child: Column(
                children: [
                  for (final k in _keys) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.key, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(k.keyValue,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(k.keyType,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remover',
                            onPressed: () => _remove(k),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
