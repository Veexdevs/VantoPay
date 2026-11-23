import 'package:flutter/material.dart';

import 'app.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Auth (email + Google OAuth). Safe to run before the
  // app builds so the auth stream is ready on the first frame.
  await AuthService.instance.initialize();

  runApp(const VantoPayApp());
}
