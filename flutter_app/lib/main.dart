import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'screens/splash_screen.dart';

void main() {
  runApp(const VantoPayApp());
}

class VantoPayApp extends StatelessWidget {
  const VantoPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VantoPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
