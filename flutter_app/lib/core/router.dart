import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/services/supabase_service.dart';
import '../features/accounts/account_screen.dart';
import '../features/accounts/sessions_screen.dart';
import '../features/accounts/settings_screen.dart';
import '../features/accounts/statement_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/pay_screen.dart';
import '../features/pix/pix_history_screen.dart';
import '../features/pix/pix_keys_screen.dart';
import '../features/pix/pix_receive_screen.dart';
import '../features/pix/pix_send_screen.dart';
import '../features/pix/pix_screen.dart';
import '../features/pix/receipt_screen.dart';
import '../features/transfers/transfer_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authed = AuthService.instance.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot');
      if (!authed && !isAuthRoute) return '/login';
      if (authed && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // ── Auth ───────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),

      // ── Authenticated shell ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: _BottomNav(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/pix', builder: (_, __) => const PixScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/transfer', builder: (_, __) => const TransferScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
            ],
          ),
        ],
      ),

      // ── Pushable routes (appear above the shell) ─────────────────────
      GoRoute(path: '/pix/send', builder: (_, __) => const PixSendScreen()),
      GoRoute(path: '/pix/receive', builder: (_, __) => const PixReceiveScreen()),
      GoRoute(path: '/pix/keys', builder: (_, __) => const PixKeysScreen()),
      GoRoute(path: '/pix/history', builder: (_, __) => const PixHistoryScreen()),
      GoRoute(
          path: '/pix/receipt/:id',
          builder: (_, __) => const ReceiptScreen()),
      GoRoute(path: '/pay', builder: (_, __) => const PayScreen()),
      GoRoute(path: '/statement', builder: (_, __) => const StatementScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
    ],
  );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (i) => navigationShell.goBranch(
        i,
        initialLocation: i == navigationShell.currentIndex,
      ),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Início'),
        NavigationDestination(
            icon: Icon(Icons.qr_code_outlined),
            selectedIcon: Icon(Icons.qr_code),
            label: 'PIX'),
        NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Transferir'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil'),
      ],
    );
  }
}
