import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VantoPayApp());
}

// =============================================
// APP ENTRY
// =============================================
class VantoPayApp extends StatefulWidget {
  const VantoPayApp({super.key});
  @override
  State<VantoPayApp> createState() => _VantoPayAppState();
}

class _VantoPayAppState extends State<VantoPayApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void setTheme(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VantoPay',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: const ColorScheme.light(primary: Color(0xFF0A0A0A)),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFFFFFFF)),
      ),
      home: VantoPayHome(setTheme: setTheme),
    );
  }
}

// =============================================
// SPLASH + HOME
// =============================================
class VantoPayHome extends StatefulWidget {
  final void Function(ThemeMode) setTheme;
  const VantoPayHome({super.key, required this.setTheme});
  @override
  State<VantoPayHome> createState() => _VantoPayHomeState();
}

class _VantoPayHomeState extends State<VantoPayHome>
    with TickerProviderStateMixin {
  late AnimationController _splashCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _actionsCtrl;
  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _splashCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400), vsync: this,
    );
    _cardCtrl = AnimationController(
      duration: const Duration(milliseconds: 700), vsync: this,
    );
    _actionsCtrl = AnimationController(
      duration: const Duration(milliseconds: 600), vsync: this,
    );
    _listCtrl = AnimationController(
      duration: const Duration(milliseconds: 500), vsync: this,
    );

    _splashCtrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _cardCtrl.forward();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _actionsCtrl.forward();
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _listCtrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _splashCtrl.dispose();
    _cardCtrl.dispose();
    _actionsCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _splashCtrl.isCompleted
            ? _buildDashboard(isDark)
            : _buildSplash(),
      ),
      bottomNavigationBar: _splashCtrl.isCompleted
          ? _buildBottomNav(isDark)
          : null,
    );
  }

  // ─── Splash ───────────────────────────────────────
  Widget _buildSplash() {
    return Container(
      key: const ValueKey('splash'),
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LogoAnimation(controller: _splashCtrl),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _splashCtrl,
                curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
              ),
              child: const Text(
                'VantoPay',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _splashCtrl,
                curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
              ),
              child: const Text(
                'SEU DINHEIRO, SEU RITMO',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dashboard ────────────────────────────────────
  Widget _buildDashboard(bool isDark) {
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFF8E8E93) : const Color(0xFF888888);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Container(
      key: const ValueKey('dashboard'),
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeader(isDark, textPrimary, textSecondary),
                    const SizedBox(height: 24),
                    _buildBalanceCard(
                      isDark, cardBg, textPrimary, textSecondary, borderColor,
                    ),
                    const SizedBox(height: 28),
                    _buildQuickActions(isDark, cardBg, textSecondary, borderColor),
                    const SizedBox(height: 32),
                    _buildActivitiesSection(
                      isDark, cardBg, textPrimary, textSecondary, borderColor,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────
  Widget _buildHeader(bool isDark, Color primary, Color secondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFF0A0A0A),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset('assets/logo.png', color: isDark ? Colors.white : Colors.white),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá, tudo bem?', style: TextStyle(fontSize: 13, color: secondary)),
                const SizedBox(height: 2),
                Text('user', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primary)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _IconCircle(isDark: isDark, child: const Icon(Icons.notifications_outlined, size: 20, color: Colors.white)),
            const SizedBox(width: 10),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              ),
              child: const Center(child: Text('US', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Balance Card ─────────────────────────────────
  Widget _buildBalanceCard(
    bool isDark, Color cardBg, Color primary, Color secondary, Color border,
  ) {
    bool visible = true;
    return StatefulBuilder(
      builder: (context, setState) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, scale, child) => Transform.scale(
            scale: _cardCtrl.isCompleted ? scale : 0.9,
            child: FadeTransition(
              opacity: _cardCtrl,
              child: child,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
              boxShadow: isDark
                  ? null
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saldo disponível', style: TextStyle(fontSize: 15, color: secondary, fontWeight: FontWeight.w400)),
                    GestureDetector(
                      onTap: () => setState(() => visible = !visible),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
                        ),
                        child: Icon(
                          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  visible ? 'R\$ 2.450,80' : 'R\$ ••••••',
                  style: TextStyle(
                    fontSize: 48, fontWeight: FontWeight.w700, color: primary,
                    letterSpacing: -2, height: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+3,2% este mês · fictício',
                    style: TextStyle(fontSize: 13, color: secondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Quick Actions ────────────────────────────────
  Widget _buildQuickActions(bool isDark, Color cardBg, Color secondary, Color border) {
    final actions = [
      (Icons.arrow_upward, 'Enviar Pix'),
      (Icons.arrow_downward, 'Receber Pix'),
      (Icons.copy_rounded, 'Copiar chave'),
      (Icons.shopping_bag_outlined, 'Pagar'),
      (Icons.list_rounded, 'Extrato'),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 30.0, end: 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, offset, child) => Transform.translate(
        offset: Offset(0, _actionsCtrl.isCompleted ? offset : 30),
        child: FadeTransition(
          opacity: _actionsCtrl,
          child: Row(
            children: actions.map((a) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                        ),
                        child: Icon(a.$1, size: 24, color: isDark ? Colors.white : const Color(0xFF0A0A0A)),
                      ),
                      const SizedBox(height: 8),
                      Text(a.$2, style: TextStyle(fontSize: 11, color: secondary, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── Activities ───────────────────────────────────
  Widget _buildActivitiesSection(
    bool isDark, Color cardBg, Color primary, Color secondary, Color border,
  ) {
    final activities = [
      _Activity(Icons.arrow_downward, 'Pix recebido', 'Ana Souza (fictícia) · 14:32', '+R\$ 180,00', true),
      _Activity(Icons.shopping_bag_outlined, 'Compra demonstrativa', 'Café Verde (fictício) · 09:15', '-R\$ 42,90', false),
      _Activity(Icons.arrow_upward, 'Pix enviado', 'Lucas Prado (fictício) · 19:48', '-R\$ 75,00', false),
      _Activity(Icons.arrow_downward, 'Pix recebido', 'Projeto Demo Ltda. · 11:02', '+R\$ 1.200,00', true),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 20.0, end: 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (_, offset, child) => Transform.translate(
        offset: Offset(0, _listCtrl.isCompleted ? offset : 20),
        child: FadeTransition(
          opacity: _listCtrl,
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Atividades recentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Dados fictícios', style: TextStyle(fontSize: 12, color: secondary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < activities.length; i++) ...[
                  _ActivityRow(activities[i], isDark, primary, secondary),
                  if (i < activities.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(height: 1, color: border),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Text(
                'Ver extrato completo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    final items = [
      (Icons.home_rounded, 'Início'),
      (Icons.diamond_outlined, 'Pix'),
      (Icons.credit_card, 'Cartões'),
      (Icons.list_rounded, 'Extrato'),
      (Icons.person_outline, 'Perfil'),
    ];
    int selected = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF),
            border: Border(
              top: BorderSide(color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((e) {
                  final idx = e.key;
                  final icon = e.value.$1;
                  final label = e.value.$2;
                  final active = idx == selected;
                  return GestureDetector(
                    onTap: () => setState(() => selected = idx),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: active ? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0)) : Colors.transparent,
                          ),
                          child: Icon(icon, size: 24, color: active ? primaryColor(isDark) : secondaryColor(isDark)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? primaryColor(isDark) : secondaryColor(isDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Helpers ─────────────────────────────────────────
Color primaryColor(bool isDark) => isDark ? Colors.white : const Color(0xFF0A0A0A);
Color secondaryColor(bool isDark) => isDark ? const Color(0xFF8E8E93) : const Color(0xFF888888);

class _IconCircle extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _IconCircle({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFF0A0A0A),
      ),
      child: child,
    );
  }
}

class _Activity {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
  _Activity(this.icon, this.title, this.subtitle, this.amount, this.isIncome);
}

class _ActivityRow extends StatelessWidget {
  final _Activity act;
  final bool isDark;
  final Color primary;
  final Color secondary;
  const _ActivityRow(this.act, this.isDark, this.primary, this.secondary);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(act.icon, size: 22, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(act.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary)),
                const SizedBox(height: 3),
                Text(act.subtitle, style: TextStyle(fontSize: 13, color: secondary)),
              ],
            ),
          ),
          Text(
            act.amount,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary),
          ),
        ],
      ),
    );
  }
}

// ─── Logo Animation ──────────────────────────────────
class _LogoAnimation extends StatefulWidget {
  final AnimationController controller;
  const _LogoAnimation({required this.controller});
  @override
  State<_LogoAnimation> createState() => _LogoAnimationState();
}

class _LogoAnimationState extends State<_LogoAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200), vsync: this,
    );
    widget.controller.addStatusListener((status) {
      if (status == AnimationStatus.forward) _rotateCtrl.forward();
    });
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final scale = CurvedAnimation(parent: widget.controller, curve: Curves.elasticOut).value;
        return Transform.scale(
          scale: scale * 0.85,
          child: child,
        );
      },
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 40, spreadRadius: 10)],
        ),
        padding: const EdgeInsets.all(16),
        child: Image.asset('assets/logo.png'),
      ),
    );
  }
}

// AnimatedBuilder is a built-in Flutter widget
