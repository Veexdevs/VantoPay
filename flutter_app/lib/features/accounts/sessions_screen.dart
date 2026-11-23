import 'package:flutter/material.dart';

import '../../core/theme.dart';

import '../../core/utils.dart';
import '../../data/models/models.dart';
import '../../data/services/account_service.dart';
import '../../widgets/common.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<SessionInfo> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _sessions = await AccountService.instance.sessions());
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _revoke(SessionInfo s) async {
    try {
      await AccountService.instance.revokeSession(s.id);
      await _load();
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScreenScaffold(
      title: 'Sessões e dispositivos',
      subtitle: 'Dispositivos com acesso à sua conta',
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(),
            )
          : _sessions.isEmpty
              ? const EmptyState(message: 'Nenhuma sessão registrada.',
                  icon: Icons.devices_outlined)
              : VPCard(
                  child: Column(
                    children: [
                      for (final s in _sessions) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Icons.devices_outlined, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.deviceLabel,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Último acesso ${AppFormat.dateTime(s.lastSeenAt)}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70))),
                                  ],
                                ),
                              ),
                              if (s.revoked)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Text('Revogado',
                                      style: TextStyle(fontSize: 12)),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.logout_outlined),
                                  tooltip: 'Revogar sessão',
                                  onPressed: () => _revoke(s),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
