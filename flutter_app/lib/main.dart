import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

const muted = Color(0xFF99999F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  AuthService? auth;
  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, anonKey: key);
      auth = SupabaseAuthService(Supabase.instance.client, url: url, publicKey: key);
    } catch (_) {
      // The interface stays usable and reports a configuration error on submit.
    }
  }
  runApp(VantoPayApp(auth: auth));
}

class VantoPayApp extends StatelessWidget {
  const VantoPayApp({super.key, this.auth});
  final AuthService? auth;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VantoPay · Acesse sua conta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Color(0xFF111113),
            error: Color(0xFFFFB4AB),
          ),
          fontFamily: 'VantoSans',
          useMaterial3: true,
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.white,
            selectionColor: Color(0xFF505056),
            selectionHandleColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF101012),
            labelStyle: const TextStyle(color: muted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF333337)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.white),
            ),
          ),
        ),
        initialRoute: '/login',
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AuthPage(auth: auth),
        ),
      );
}

enum AccessStep { welcome, login, signup, verify, account }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.auth});
  final AuthService? auth;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AccessStep step = AccessStep.welcome;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  bool hidden = true;
  bool busy = false;
  String? error;
  String? notice;
  int resendIn = 0;
  Timer? resendTimer;
  StreamSubscription<bool>? subscription;

  @override
  void initState() {
    super.initState();
    if (widget.auth?.isSignedIn ?? false) {
      step = AccessStep.account;
    }
    subscription = widget.auth?.sessionChanges.listen((signedIn) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (signedIn) {
          step = AccessStep.account;
          password.clear();
          code.clear();
          error = null;
          notice = null;
        } else if (step == AccessStep.account) {
          step = AccessStep.welcome;
        }
      });
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    resendTimer?.cancel();
    for (final controller in [name, email, password, code]) {
      controller.dispose();
    }
    super.dispose();
  }

  void go(AccessStep next) {
    if (busy) {
      return;
    }
    setState(() {
      step = next;
      error = null;
      notice = null;
      password.clear();
      code.clear();
      hidden = true;
    });
  }

  void startCooldown() {
    resendTimer?.cancel();
    setState(() => resendIn = 60);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return timer.cancel();
      }
      setState(() => resendIn--);
      if (resendIn <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> perform(Future<void> Function(AuthService) action) async {
    if (busy) {
      return;
    }
    setState(() { busy = true; error = null; notice = null; });
    try {
      final auth = widget.auth;
      if (auth == null) {
        setState(() => error = 'O acesso está temporariamente indisponível. Tente novamente mais tarde.');
        return;
      }
      await action(auth);
    } catch (e) {
      if (mounted) {
        setState(() => error = friendlyAuthError(e));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    await perform((auth) async {
      switch (step) {
        case AccessStep.login:
          await auth.signIn(email.text.trim(), password.text);
          if (mounted && auth.isSignedIn) {
            setState(() => step = AccessStep.account);
          }
          break;
        case AccessStep.signup:
          final signedIn = await auth.signUp(name.text.trim(), email.text.trim(), password.text);
          if (!mounted) {
            return;
          }
          password.clear();
          setState(() => step = signedIn ? AccessStep.account : AccessStep.verify);
          if (!signedIn) startCooldown();
          break;
        case AccessStep.verify:
          await auth.verifyEmail(email.text.trim(), code.text.trim());
          if (mounted && auth.isSignedIn) {
            setState(() => step = AccessStep.account);
          }
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final welcome = step == AccessStep.welcome;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: RibbonPainter()))),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width < 600 ? 28 : 48),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: EdgeInsets.only(top: welcome ? 46 : 24, bottom: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!welcome && step != AccessStep.account)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: busy ? null : () => go(step == AccessStep.verify ? AccessStep.signup : AccessStep.welcome),
                                  tooltip: 'Voltar',
                                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                ),
                              ),
                            Semantics(
                              label: 'VantoPay', image: true,
                              child: Image.asset('assets/brand/logo.png',
                                width: welcome ? 238 : 146,
                                height: welcome ? 266 : 163,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                            SizedBox(height: welcome ? 48 : 30),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: KeyedSubtree(
                                key: ValueKey(step),
                                child: switch (step) {
                                  AccessStep.welcome => welcomeContent(),
                                  AccessStep.account => accountContent(),
                                  _ => formContent(),
                                },
                              ),
                            ),
                            SizedBox(height: welcome ? 46 : 34),
                            const Text('VantoPay', style: TextStyle(color: muted, fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            const Text('Pagamentos mais simples. Sempre.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget heading(String title, String subtitle) => Column(children: [
    Text(title, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 29, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.9)),
    const SizedBox(height: 10),
    Text(subtitle, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, color: muted, height: 1.5)),
  ]);

  Widget welcomeContent() => Column(children: [
    heading('Bem-vindo(a)!', 'Escolha como deseja acessar sua conta.'),
    const SizedBox(height: 32),
    AccessButton(label: 'Entrar', primary: true, onPressed: busy ? null : () => go(AccessStep.login)),
    const SizedBox(height: 16),
    AccessButton(label: 'Criar Conta', onPressed: busy ? null : () => go(AccessStep.signup)),
    separator(),
    googleButton(),
    messages(),
  ]);

  Widget separator() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 23, horizontal: 8),
    child: Row(children: [
      Expanded(child: Divider(color: Color(0xFF49494D))),
      Padding(padding: EdgeInsets.symmetric(horizontal: 23), child: Text('ou', style: TextStyle(color: muted, fontSize: 15))),
      Expanded(child: Divider(color: Color(0xFF49494D))),
    ]),
  );

  Widget googleButton() => AccessButton(
    label: 'Entrar com Google',
    google: true,
    loading: busy,
    onPressed: busy ? null : () => perform((auth) => auth.signInWithGoogle()),
  );

  Widget messages() => Column(children: [
    if (error != null)
      Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Semantics(liveRegion: true, child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF211819),
            border: Border.all(color: const Color(0xFF5A3638)),
            borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 19),
            const SizedBox(width: 10),
            Expanded(child: Text(error!, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white))),
          ]),
        )),
      ),
    if (notice != null)
      Padding(padding: const EdgeInsets.only(top: 16), child: Semantics(
        liveRegion: true, child: Text(notice!, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, height: 1.5)))),
  ]);

  Widget formContent() {
    final signup = step == AccessStep.signup;
    final verify = step == AccessStep.verify;
    return Form(
      key: formKey,
      child: AutofillGroup(child: Column(children: [
        heading(
          verify ? 'Verifique seu e-mail' : signup ? 'Crie sua conta' : 'Que bom ter você aqui.',
          verify ? 'Enviamos uma confirmação para\n${email.text.trim()}' : signup
            ? 'Seu próximo passo começa no VantoPay.' : 'Entre para acessar sua conta VantoPay.',
        ),
        const SizedBox(height: 28),
        if (verify) ...[
          const Icon(Icons.mark_email_read_outlined, size: 34, color: Colors.white),
          const SizedBox(height: 20),
          const Text('Use o código recebido ou abra o link de confirmação no e-mail.',
            textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5, fontSize: 14)),
          const SizedBox(height: 20),
          TextFormField(
            controller: code,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Código de verificação', prefixIcon: Icon(Icons.key_outlined, color: Colors.white)),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
            validator: (value) => RegExp(r'^\d{6,8}$').hasMatch(value ?? '') ? null : 'Digite o código de 6 a 8 dígitos.',
            onFieldSubmitted: (_) => busy ? null : submit(),
          ),
        ] else ...[
          if (signup) ...[
            TextFormField(
              controller: name, enabled: !busy,
              decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.white)),
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              validator: (value) => (value?.trim().length ?? 0) < 3 ? 'Informe seu nome completo.' : null,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: email, enabled: !busy,
            decoration: const InputDecoration(labelText: 'E-mail', hintText: 'voce@exemplo.com', prefixIcon: Icon(Icons.mail_outline_rounded, color: Colors.white)),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '') ? null : 'Informe um e-mail válido.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: password, enabled: !busy, obscureText: hidden,
            enableSuggestions: false, autocorrect: false,
            autofillHints: [signup ? AutofillHints.newPassword : AutofillHints.password],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Senha',
              helperText: signup ? 'Use pelo menos 8 caracteres.' : null,
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
              suffixIcon: IconButton(
                tooltip: hidden ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white, size: 21),
              ),
            ),
            validator: (value) => (value?.isEmpty ?? true) ? 'Informe sua senha.' : signup && value!.length < 8 ? 'Use pelo menos 8 caracteres.' : null,
            onFieldSubmitted: (_) => busy ? null : submit(),
          ),
        ],
        messages(),
        const SizedBox(height: 24),
        AccessButton(
          label: verify ? 'Verificar e-mail' : signup ? 'Criar conta' : 'Entrar',
          primary: true, loading: busy, onPressed: busy ? null : submit),
        if (verify) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: busy || resendIn > 0 ? null : () => perform((auth) async {
              await auth.resendCode(email.text.trim());
              if (!mounted) {
                return;
              }
              setState(() => notice = 'Confirmação reenviada. Confira também o spam.');
              startCooldown();
            }),
            child: Text(resendIn > 0 ? 'Reenviar em ${resendIn}s' : 'Reenviar confirmação'),
          ),
          TextButton(onPressed: busy ? null : () => go(AccessStep.login), child: const Text('Já confirmei, quero entrar')),
        ] else ...[
          separator(),
          googleButton(),
          const SizedBox(height: 18),
          Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(signup ? 'Já tem uma conta?' : 'Ainda não tem conta?', style: const TextStyle(color: muted, fontSize: 13)),
            TextButton(onPressed: busy ? null : () => go(signup ? AccessStep.login : AccessStep.signup), child: Text(signup ? 'Entrar' : 'Criar conta')),
          ]),
        ],
      ])),
    );
  }

  Widget accountContent() => Column(children: [
    const Icon(Icons.verified_user_outlined, color: Colors.white, size: 40),
    const SizedBox(height: 20),
    heading('Você está na sua conta.', 'Acesso realizado com segurança.'),
    const SizedBox(height: 16),
    Text(widget.auth?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
    const SizedBox(height: 28),
    AccessButton(label: 'Sair da conta', loading: busy, onPressed: busy ? null : () => perform((auth) async {
      await auth.signOut();
      if (mounted) go(AccessStep.welcome);
    })),
    messages(),
  ]);
}

class AccessButton extends StatelessWidget {
  const AccessButton({super.key, required this.label, this.primary = false,
    this.google = false, this.loading = false, this.onPressed});
  final String label;
  final bool primary;
  final bool google;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58 * math.max(1, MediaQuery.textScalerOf(context).scale(16) / 16),
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primary ? Colors.black : Colors.white,
        backgroundColor: primary ? Colors.white : Colors.transparent,
        disabledBackgroundColor: primary ? const Color(0xFFBBBBBB) : Colors.transparent,
        disabledForegroundColor: primary ? Colors.black54 : Colors.white54,
        side: BorderSide(color: primary ? Colors.white : const Color(0xFFEEEEF0), width: 1.4),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
      child: loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: primary ? Colors.black : Colors.white, semanticsLabel: 'Aguarde'))
        : Stack(alignment: Alignment.center, children: [
            if (google)
              const Align(alignment: Alignment.centerLeft, child: Row(mainAxisSize: MainAxisSize.min, children: [
                GoogleMark(),
                SizedBox(width: 16),
                SizedBox(height: 25, child: VerticalDivider(color: Color(0xFF77777C), width: 1)),
              ])),
            Padding(
              padding: EdgeInsets.only(left: google ? 42 : 0, right: google ? 0 : 24),
              child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: google ? 17 : 19, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
            ),
            if (!google)
              Align(alignment: Alignment.centerRight, child: Container(
                width: 29, height: 29,
                decoration: BoxDecoration(color: primary ? Colors.black : Colors.transparent, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 21),
              )),
          ]),
    ),
  );
}

// A monochrome vector mark, not an emoji or a font-dependent character.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 23, height: 23,
    child: CustomPaint(painter: GoogleMarkPainter()),
  );
}

class GoogleMarkPainter extends CustomPainter {
  const GoogleMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4;
    canvas.drawArc(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), 0.15, math.pi * 1.76, false, paint);
    canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(size.width - 1, size.height / 2), paint);
    canvas.drawLine(Offset(size.width - 2, size.height / 2), Offset(size.width - 2, size.height * .72), paint);
  }
  @override
  bool shouldRepaint(GoogleMarkPainter oldDelegate) => false;
}

class RibbonPainter extends CustomPainter {
  const RibbonPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 440).clamp(0.8, 1.5);
    canvas.save();
    canvas.scale(scale);
    final top = Path()
      ..moveTo(-80, -100)..lineTo(245, -100)
      ..cubicTo(285, 100, 137, 115, 26, 183)
      ..cubicTo(-30, 217, -29, 255, -40, 286)..close();
    canvas.drawPath(top, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF090909), Color(0xFF272727), Color(0xFF0A0A0A)],
    ).createShader(const Rect.fromLTWH(-60, -20, 320, 270)));
    final front = Path()..moveTo(-50, -50)..lineTo(153, -50)
      ..cubicTo(163, 68, 77, 65, -35, 134)..close();
    canvas.drawPath(front, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF474747), Color(0xFF121212)],
    ).createShader(const Rect.fromLTWH(0, 0, 170, 150)));
    canvas.restore();
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(math.pi);
    canvas.scale(scale);
    canvas.drawPath(top, Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF141414), Color(0xFF303030), Color(0xFF080808)],
    ).createShader(const Rect.fromLTWH(0, 0, 240, 250)));
    canvas.drawPath(front, Paint()..shader = const LinearGradient(
      colors: [Color(0xFF565656), Color(0xFF232323)],
    ).createShader(const Rect.fromLTWH(0, 0, 180, 170)));
    canvas.restore();
  }
  @override
  bool shouldRepaint(RibbonPainter oldDelegate) => false;
}
