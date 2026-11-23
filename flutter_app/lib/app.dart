import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme.dart';

class VantoPayApp extends StatelessWidget {
  const VantoPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VantoPay',
      debugShowCheckedModeBanner: false,
      theme: VantoPayTheme.light(),
      darkTheme: VantoPayTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
