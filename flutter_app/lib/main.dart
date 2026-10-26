import 'package:flutter/material.dart';

void main() => runApp(const VantoPayApp());

class VantoPayApp extends StatelessWidget {
  const VantoPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VantoPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.grey, scaffoldBackgroundColor: Colors.white, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: const Center(child: Text('VP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Olá, Bem-vindo', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      const Text('VantoPay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Stack(children: [
                    const Center(child: Icon(Icons.notifications_outlined, size: 22)),
                    Positioned(top: 10, right: 10, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                  ])),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 28),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _buildAction(Icons.qr_code, 'PIX'),
                      _buildAction(Icons.arrow_upward, 'Transferir'),
                      _buildAction(Icons.arrow_downward, 'Receber'),
                      _buildAction(Icons.add, 'Recarga'),
                    ]),
                    const SizedBox(height: 32),
                    const Text('Serviços', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildService(Icons.savings, 'Reservar', 'Economize')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildService(Icons.trending_up, 'Investir', 'Rendimento')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildService(Icons.bolt, 'PIX', 'Instantâneo')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildService(Icons.shield, 'Seguro', 'Proteção')),
                    ]),
                    const SizedBox(height: 32),
                    const Text('Transações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    _buildTransaction('Spotify Premium', -21.90, 'Entretenimento', '14:32', Icons.music_note),
                    _buildTransaction('Salário', 8500.00, 'Receita', '09:00', Icons.work),
                    _buildTransaction('iFood', -45.80, 'Alimentação', 'Ontem', Icons.restaurant),
                    _buildTransaction('Netflix', -39.90, 'Entretenimento', 'Ontem', Icons.play_arrow),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildNav(Icons.home, 'Início', true),
          _buildNav(Icons.credit_card, 'Cartões', false),
          _buildNav(Icons.swap_horiz, 'Transações', false),
          _buildNav(Icons.person, 'Perfil', false),
        ]),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Image.asset('assets/logo.png', width: 28, height: 28),
            const SizedBox(width: 10),
            Text('VIRTUAL • VANTO', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55), letterSpacing: 2)),
          ]),
          IconButton(onPressed: () => setState(() => _balanceVisible = !_balanceVisible), icon: Icon(_balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white.withOpacity(0.55), size: 20)),
        ]),
        const SizedBox(height: 20),
        Text('Saldo disponível', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55))),
        const SizedBox(height: 4),
        Text(_balanceVisible ? 'R\$ 12.847,30' : 'R\$ •••••••', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('•••• •••• •••• 4289', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.55), letterSpacing: 2)),
          Row(children: [Icon(Icons.credit_card, size: 18, color: Colors.white.withOpacity(0.55)), const SizedBox(width: 12), Icon(Icons.account_balance_wallet, size: 18, color: Colors.white.withOpacity(0.55))]),
        ]),
      ]),
    );
  }

  Widget _buildAction(IconData icon, String label) {
    return Expanded(child: Column(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey[200]!)), child: Icon(icon, size: 22)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _buildService(IconData icon, String label, String desc) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey[200]!)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!)), child: Icon(icon, size: 24)),
      const SizedBox(height: 10),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]));
  }

  Widget _buildTransaction(String name, double amount, String category, String time, IconData icon) {
    final isIncome = amount > 0;
    return Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: isIncome ? Colors.grey[200] : Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(category, style: TextStyle(fontSize: 12, color: Colors.grey[600]))])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${isIncome ? '+' : '-'} R\$ ${amount.abs().toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isIncome ? Colors.black : Colors.grey[700])), const SizedBox(height: 2), Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500]))]),
    ]));
  }

  Widget _buildNav(IconData icon, String label, bool active) {
    return Column(children: [
      if (active) Container(width: 24, height: 3, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
      Container(width: 44, height: 32, decoration: BoxDecoration(color: active ? Colors.grey[100] : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 22, color: active ? Colors.black : Colors.grey[500])),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? Colors.black : Colors.grey[500])),
    ]);
  }
}
