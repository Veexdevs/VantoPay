import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(const VantoPayApp());

// ─── App with theme support ─────────────────────────────────────────────────

class VantoPayApp extends StatefulWidget {
  const VantoPayApp({super.key});

  @override
  State<VantoPayApp> createState() => _VantoPayAppState();
}

class _VantoPayAppState extends State<VantoPayApp> {
  bool _isDark = true;

  void toggleTheme() => setState(() => _isDark = !_isDark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VantoPay',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? _darkTheme : _lightTheme,
      home: const VantoPaySplash(),
    );
  }

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B5CF6),
      onPrimary: Colors.white,
      surface: Color(0xFF1C1C1E),
      onSurface: Colors.white,
    ),
    useMaterial3: true,
  );

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8B5CF6),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1C1C1E),
    ),
    useMaterial3: true,
  );
}

// ─── Elastic curve (Apple-style) ────────────────────────────────────────────

class ElasticOutCurve extends Curve {
  const ElasticOutCurve();
  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) return t;
    return (math.pow(2.0, -10 * t).toDouble() *
            math.sin((t - 0.075) * (2 * math.pi) / 0.3)) +
        1.0;
  }
}

// ─── Splash Screen ──────────────────────────────────────────────────────────

class VantoPaySplash extends StatefulWidget {
  const VantoPaySplash({super.key});

  @override
  State<VantoPaySplash> createState() => _VantoPaySplashState();
}

class _VantoPaySplashState extends State<VantoPaySplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const ElasticOutCurve()),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const VantoPayHome(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F2F7),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', width: 100, height: 100,
                    errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF8B5CF6))),
                const SizedBox(height: 20),
                Text('VantoPay',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
                const SizedBox(height: 8),
                Text('SEU DINHEIRO, SEU RITMO',
                    style: TextStyle(fontSize: 14, letterSpacing: 3,
                        color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF1C1C1E).withOpacity(0.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main Home / Dashboard ──────────────────────────────────────────────────

class VantoPayHome extends StatefulWidget {
  const VantoPayHome({super.key});

  @override
  State<VantoPayHome> createState() => _VantoPayHomeState();
}

class _VantoPayHomeState extends State<VantoPayHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _actionsFade;
  late Animation<double> _listFade;

  bool _showBalance = true;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _actionsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );
    _listFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 0.9, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F2F7);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final textSecondary = isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF1C1C1E).withOpacity(0.55);
    final accent = const Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.3, curve: Curves.easeOut))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset('assets/logo.png',
                          errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 22, color: Color(0xFF8B5CF6))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ola,', style: TextStyle(fontSize: 14, color: textSecondary)),
                          Text('Joao Silva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Icon(Icons.notifications_outlined, color: textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('JS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Scrollable content ───
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 20),

                  // ─── Balance card ───
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.15, 0.5, curve: ElasticOutCurve()))),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent,
                            accent.withOpacity(0.7),
                            const Color(0xFF6D28D9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 18),
                              const SizedBox(width: 8),
                              Text('Saldo disponivel', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _showBalance = !_showBalance),
                                child: Icon(_showBalance ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white.withOpacity(0.8), size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _showBalance ? 'R\$ 2.450,80' : 'R\$ ••••••',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('+3,2% este mes · ficticio',
                                style: TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Quick actions ───
                  FadeTransition(
                    opacity: _actionsFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickAction(icon: Icons.send_rounded, label: 'Enviar Pix', color: accent),
                        _QuickAction(icon: Icons.qr_code_rounded, label: 'Receber Pix', color: const Color(0xFF10B981)),
                        _QuickAction(icon: Icons.key_rounded, label: 'Copiar chave', color: const Color(0xFFF59E0B)),
                        _QuickAction(icon: Icons.receipt_long_rounded, label: 'Pagar', color: const Color(0xFFEF4444)),
                        _QuickAction(icon: Icons.list_alt_rounded, label: 'Extrato', color: const Color(0xFF3B82F6)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ─── Activities header ───
                  FadeTransition(
                    opacity: _listFade,
                    child: Row(
                      children: [
                        Text('Atividade recente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                        const Spacer(),
                        Text('Ver tudo', style: TextStyle(fontSize: 14, color: accent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ─── Activity list ───
                  FadeTransition(
                    opacity: _listFade,
                    child: Column(
                      children: [
                        _ActivityItem(
                          icon: Icons.arrow_upward_rounded,
                          iconBg: const Color(0xFFEF4444),
                          title: 'Transferencia enviada',
                          subtitle: 'Para Maria Santos · Pix',
                          amount: '- R\$ 120,00',
                          time: 'Hoje, 14:32',
                          isDark: isDark,
                        ),
                        _divider(border),
                        _ActivityItem(
                          icon: Icons.arrow_downward_rounded,
                          iconBg: const Color(0xFF10B981),
                          title: 'Deposito recebido',
                          subtitle: 'De Pedro Lima · Pix',
                          amount: '+ R\$ 450,00',
                          time: 'Hoje, 11:15',
                          isDark: isDark,
                        ),
                        _divider(border),
                        _ActivityItem(
                          icon: Icons.shopping_bag_rounded,
                          iconBg: const Color(0xFF3B82F6),
                          title: 'Pagamento',
                          subtitle: 'iFood · Cartao Virtual',
                          amount: '- R\$ 48,90',
                          time: 'Ontem, 20:05',
                          isDark: isDark,
                        ),
                        _divider(border),
                        _ActivityItem(
                          icon: Icons.credit_card_rounded,
                          iconBg: const Color(0xFFF59E0B),
                          title: 'Recarga',
                          subtitle: 'Vivo · R\$ 30,00',
                          amount: '- R\$ 30,00',
                          time: 'Ontem, 09:42',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Dados ficticios',
                          style: TextStyle(fontSize: 11, color: textSecondary)),
                    ),
                  ),

                  FadeTransition(
                    opacity: _listFade,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: border),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Ver extrato completo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accent)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ─── Bottom nav ───
            FadeTransition(
              opacity: _listFade,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: border)),
                ),
                padding: EdgeInsets.only(
                  left: 8, right: 8, top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavTab(icon: Icons.home_rounded, label: 'Inicio', active: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
                    _NavTab(icon: Icons.credit_card_rounded, label: 'Cartoes', active: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
                    _NavTab(icon: Icons.swap_horiz_rounded, label: 'Pix', active: _currentTab == 2, onTap: () => setState(() => _currentTab = 2), isAccent: true),
                    _NavTab(icon: Icons.bar_chart_rounded, label: 'Investir', active: _currentTab == 3, onTap: () => setState(() => _currentTab = 3)),
                    _NavTab(icon: Icons.person_rounded, label: 'Perfil', active: _currentTab == 4, onTap: () => setState(() => _currentTab = 4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(Color color) => Divider(height: 1, thickness: 0.5, color: color);
}

// ─── Quick Action Button ────────────────────────────────────────────────────

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAction({required this.icon, required this.label, required this.color});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(widget.label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF1C1C1E).withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}

// ─── Activity Item ──────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String amount;
  final String time;
  final bool isDark;

  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final textSecondary = isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF1C1C1E).withOpacity(0.55);
    final isPositive = amount.startsWith('+');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconBg, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isPositive ? const Color(0xFF10B981) : textPrimary,
              )),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Nav Tab ────────────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isAccent;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFF8B5CF6);
    final inactive = isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF1C1C1E).withOpacity(0.4);
    final color = active ? (isAccent ? accent : (isDark ? Colors.white : const Color(0xFF1C1C1E))) : inactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            if (active)
              Container(
                width: 4, height: 4,
                decoration: BoxDecoration(color: isAccent ? accent : color, shape: BoxShape.circle),
              )
            else
              const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
