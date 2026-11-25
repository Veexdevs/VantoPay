import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vantopay/auth_service.dart';
import 'package:vantopay/main.dart';

class FakeAuth implements AuthService {
  final controller = StreamController<bool>.broadcast();
  bool signedIn = false;
  bool pending = false;
  int googleCalls = 0;
  int signupCalls = 0;
  int loginCalls = 0;
  int verifyCalls = 0;
  Object? failure;
  @override
  bool get isSignedIn => signedIn;
  @override
  bool get needsVerification => pending;
  @override
  String? get email => signedIn || pending ? 'teste@example.com' : null;
  @override
  Stream<bool> get sessionChanges => controller.stream;
  @override
  Future<void> signIn(String email, String password) async {
    loginCalls++;
    if (failure != null) {
      throw failure!;
    }
    signedIn = !pending;
    controller.add(signedIn);
  }
  @override
  Future<bool> signUp(String name, String email, String password) async {
    signupCalls++;
    return false;
  }
  @override
  Future<void> signInWithGoogle() async { googleCalls++; }
  @override
  Future<void> verifyEmail(String email, String code) async {
    verifyCalls++;
    signedIn = true;
    controller.add(true);
  }
  @override
  Future<void> resendCode(String email) async {}
  @override
  Future<void> signOut() async {
    signedIn = false;
    controller.add(false);
  }
}

Future<void> launch(WidgetTester tester, {AuthService? auth, Size size = const Size(440, 1100)}) async {
  tester.view.resetPhysicalSize();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(VantoPayApp(auth: auth));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome uses full logo and provides all three access options', (tester) async {
    await launch(tester);
    expect(find.text('Bem-vindo(a)!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar Conta'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Pagamentos mais simples. Sempre.'), findsNothing);
    // Only the two lines around "ou" remain; no decorative footer line.
    expect(find.byType(Divider), findsNWidgets(2));
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/brand/logo.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen and large text can scroll without overflow', (tester) async {
    await launch(tester, size: const Size(320, 568));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: MediaQuery(data: const MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(1.5)),
        child: const AuthPage()),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Entrar com Google'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login validates locally before contacting auth', (tester) async {
    final auth = FakeAuth();
    await launch(tester, auth: auth);
    await tapText(tester, 'Entrar');
    await tapText(tester, 'Entrar');
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(auth.loginCalls, 0);
  });

  testWidgets('real service boundary signs in and signs out', (tester) async {
    final auth = FakeAuth();
    await launch(tester, auth: auth);
    await tapText(tester, 'Entrar');
    await tester.enterText(find.byType(TextFormField).at(0), 'teste@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senhaSegura123');
    await tapText(tester, 'Entrar');
    expect(auth.loginCalls, 1);
    expect(find.text('Você está na sua conta.'), findsOneWidget);
    await tapText(tester, 'Sair da conta');
    expect(find.text('Bem-vindo(a)!'), findsOneWidget);
  });

  testWidgets('invalid credentials show an error, never a success screen', (tester) async {
    final auth = FakeAuth()..failure = const AuthException('Invalid login credentials', code: 'invalid_credentials');
    await launch(tester, auth: auth);
    await tapText(tester, 'Entrar');
    await tester.enterText(find.byType(TextFormField).at(0), 'teste@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senhaerrada');
    await tapText(tester, 'Entrar');
    expect(find.text('E-mail ou senha incorretos. Confira seus dados.'), findsOneWidget);
    expect(find.text('Você está na sua conta.'), findsNothing);
  });

  testWidgets('signup requests confirmation, verifies code and authenticates', (tester) async {
    final auth = FakeAuth();
    await launch(tester, auth: auth);
    await tapText(tester, 'Criar Conta');
    expect(find.text('Nome de exibição'), findsOneWidget);
    expect(find.text('Nome completo'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), 'Pessoa Teste');
    await tester.enterText(find.byType(TextFormField).at(1), 'teste@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senhaSegura123');
    await tapText(tester, 'Criar conta');
    expect(auth.signupCalls, 1);
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(find.textContaining('Reenviar em '), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tapText(tester, 'Verificar e-mail');
    expect(auth.verifyCalls, 1);
    expect(find.text('Você está na sua conta.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('new device login waits for six-digit verification', (tester) async {
    final auth = FakeAuth();
    await launch(tester, auth: auth);
    await tapText(tester, 'Entrar');
    await tester.enterText(find.byType(TextFormField).at(0), 'teste@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'senhaSegura123');
    auth.pending = true;
    await tapText(tester, 'Entrar');
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(find.text('Você está na sua conta.'), findsNothing);
    await tester.enterText(find.byType(TextFormField), '12345');
    await tapText(tester, 'Verificar e-mail');
    expect(auth.verifyCalls, 0);
    expect(find.text('Digite o código de 6 dígitos.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tapText(tester, 'Verificar e-mail');
    expect(auth.verifyCalls, 1);
    expect(find.text('Você está na sua conta.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Google button delegates to OAuth without faking a session', (tester) async {
    final auth = FakeAuth();
    await launch(tester, auth: auth);
    await tapText(tester, 'Entrar com Google');
    expect(auth.googleCalls, 1);
    expect(auth.isSignedIn, isFalse);
    expect(find.text('Você está na sua conta.'), findsNothing);
  });

  testWidgets('missing backend config reports unavailable access', (tester) async {
    await launch(tester);
    await tapText(tester, 'Entrar com Google');
    expect(find.textContaining('temporariamente indisponível'), findsOneWidget);
  });

  testWidgets('existing sessions are restored', (tester) async {
    final auth = FakeAuth()..signedIn = true;
    await launch(tester, auth: auth);
    expect(find.text('Você está na sua conta.'), findsOneWidget);
  });
}
