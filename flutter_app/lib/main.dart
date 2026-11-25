import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'motion.dart';

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
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF29292D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
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
      if (signedIn) {
        resendTimer?.cancel();
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
          if (!signedIn) {
            startCooldown();
          }
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
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduceMotion(context) ? 1 : 0, end: 1),
                  duration: motionDuration(context, 1400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Opacity(
                    opacity: 0.45 + 0.15 * value,
                    child: CustomPaint(painter: RibbonPainter(entrance: value)),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width < 600 ? 20 : 48),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: EdgeInsets.only(top: welcome ? 36 : 20, bottom: 28),
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
                            MotionReveal(
                              child: Semantics(
                                label: 'VantoPay', image: true,
                                child: AnimatedContainer(
                                  duration: motionDuration(context, 420),
                                  curve: Curves.easeInOutCubic,
                                  width: welcome ? 154 : 104,
                                  height: welcome ? 172 : 116,
                                  child: Image.asset('assets/brand/logo.png',
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: motionDuration(context, 420),
                              height: welcome ? 36 : 26,
                            ),
                            AnimatedSize(
                              duration: motionDuration(context, 420),
                              curve: Curves.easeInOutCubic,
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
                            SizedBox(height: welcome ? 38 : 28),
                            const MotionReveal(
                              delay: 330,
                              child: Column(children: [
                                SizedBox(width: 22, child: Divider(color: Color(0xFF343439))),
                                SizedBox(height: 10),
                                Text('Pagamentos mais simples. Sempre.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted, fontSize: 11.5, letterSpacing: 0.1)),
                              ]),
                            ),
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
      style: const TextStyle(fontSize: 25, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.7)),
    const SizedBox(height: 9),
    Text(subtitle, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: muted, height: 1.6)),
  ]);

  Widget welcomeContent() => MotionColumn(children: [
    heading('Bem-vindo(a)!', 'Escolha como deseja acessar sua conta.'),
    const SizedBox(height: 28),
    AccessButton(label: 'Entrar', primary: true, onPressed: busy ? null : () => go(AccessStep.login)),
    const SizedBox(height: 12),
    AccessButton(label: 'Criar Conta', onPressed: busy ? null : () => go(AccessStep.signup)),
    separator(),
    googleButton(),
    messages(),
  ]);

  Widget separator() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 4),
    child: Row(children: [
      Expanded(child: Divider(color: Color(0xFF29292D))),
      Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('ou', style: TextStyle(color: muted, fontSize: 12))),
      Expanded(child: Divider(color: Color(0xFF29292D))),
    ]),
  );

  Widget googleButton() => AccessButton(
    label: 'Entrar com Google',
    google: true,
    loading: busy,
    onPressed: busy ? null : () => perform((auth) => auth.signInWithGoogle()),
  );

  Widget messages() => AnimatedSize(
    duration: motionDuration(context, 260),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: MotionReveal(
      key: ValueKey('$error|$notice'),
      child: Column(children: [
    if (error != null)
      Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Semantics(liveRegion: true, child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151517),
            border: Border.all(color: const Color(0xFF3A3A40)),
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
      ]),
    ),
  );

  Widget formContent() {
    final signup = step == AccessStep.signup;
    final verify = step == AccessStep.verify;
    return Form(
      key: formKey,
      child: AutofillGroup(child: MotionColumn(children: [
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
            style: const TextStyle(fontSize: 14),
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
            style: const TextStyle(fontSize: 14),
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
            style: const TextStyle(fontSize: 14),
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
            style: const TextStyle(fontSize: 14),
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

  Widget accountContent() => MotionColumn(children: [
    const Icon(Icons.verified_user_outlined, color: Colors.white, size: 40),
    const SizedBox(height: 20),
    heading('Você está na sua conta.', 'Acesso realizado com segurança.'),
    const SizedBox(height: 16),
    Text(widget.auth?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted)),
    const SizedBox(height: 28),
    AccessButton(label: 'Sair da conta', loading: busy, onPressed: busy ? null : () => perform((auth) async {
      await auth.signOut();
      if (mounted) {
        email.clear();
        name.clear();
        setState(() => step = AccessStep.welcome);
      }
    })),
    messages(),
  ]);
}

class AccessButton extends StatefulWidget {
  const AccessButton({super.key, required this.label, this.primary = false,
    this.google = false, this.loading = false, this.onPressed});
  final String label;
  final bool primary;
  final bool google;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  State<AccessButton> createState() => _AccessButtonState();
}

class _AccessButtonState extends State<AccessButton> {
  final states = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    states.addListener(refresh);
  }

  void refresh() {
    // Buttons also update disabled states during build. Defer those notifications
    // so an auth loading transition never calls setState during a child build.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    states.removeListener(refresh);
    states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final hover = enabled && states.value.contains(WidgetState.hovered);
    final focus = states.value.contains(WidgetState.focused);
    final pressed = enabled && states.value.contains(WidgetState.pressed);
    final primary = widget.primary;
    final google = widget.google;
    final foreground = primary ? Colors.black : Colors.white;
    final reduced = reduceMotion(context);
    return AnimatedScale(
      scale: reduced ? 1 : pressed ? 0.985 : hover ? 1.008 : 1,
      duration: motionDuration(context, 160),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: motionDuration(context, 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: focus ? 0.16 : hover ? 0.08 : 0),
              blurRadius: focus ? 0 : 24,
              spreadRadius: focus ? 3 : 0,
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          // Compact visually; never below a comfortable 48px touch target.
          height: 48 * math.max(1, MediaQuery.textScalerOf(context).scale(16) / 16),
          child: OutlinedButton(
            statesController: states,
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              backgroundColor: primary ? const Color(0xFFF4F4F5) : hover ? const Color(0xFF17171A) : const Color(0xFF080809),
              disabledBackgroundColor: primary ? const Color(0xFFBBBBBB) : const Color(0xFF080809),
              disabledForegroundColor: primary ? Colors.black54 : Colors.white54,
              side: BorderSide(color: primary ? const Color(0xFFF4F4F5) : focus ? Colors.white : hover ? const Color(0xFF88888F) : const Color(0xFF45454B)),
              shape: const StadiumBorder(),
              animationDuration: motionDuration(context, 180),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: AnimatedSwitcher(
              duration: motionDuration(context, 180),
              child: widget.loading
                ? SizedBox(key: const ValueKey('loading'), width: 18, height: 18,
                    child: reduced
                      ? Icon(Icons.hourglass_top_rounded, size: 18, color: foreground, semanticLabel: 'Aguarde')
                      : CircularProgressIndicator(strokeWidth: 1.7, color: foreground, semanticsLabel: 'Aguarde'))
                : Stack(key: const ValueKey('label'), alignment: Alignment.center, children: [
                    if (google)
                      const Align(alignment: Alignment.centerLeft, child: GoogleMark()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: google ? 30 : 26),
                      child: Text(widget.label, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                    ),
                    if (!google)
                      Align(alignment: Alignment.centerRight,
                        child: AnimatedSlide(
                          offset: reduced ? Offset.zero : Offset(hover ? 0.12 : 0, 0),
                          duration: motionDuration(context, 180),
                          child: Container(
                            width: 23, height: 23,
                            decoration: BoxDecoration(color: primary ? Colors.black : Colors.transparent, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

// A monochrome vector mark, not an emoji or a font-dependent character.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18, height: 18,
    child: CustomPaint(painter: GoogleMarkPainter()),
  );
}

class GoogleMarkPainter extends CustomPainter {
  const GoogleMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawArc(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), 0.15, math.pi * 1.76, false, paint);
    canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(size.width - 1, size.height / 2), paint);
    canvas.drawLine(Offset(size.width - 2, size.height / 2), Offset(size.width - 2, size.height * .72), paint);
  }
  @override
  bool shouldRepaint(GoogleMarkPainter oldDelegate) => false;
}

class RibbonPainter extends CustomPainter {
  const RibbonPainter({this.entrance = 1});
  final double entrance;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 440).clamp(0.8, 1.5);
    canvas.save();
    canvas.translate(-12 * (1 - entrance), -20 * (1 - entrance));
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
    canvas.translate(-12 * (1 - entrance), -20 * (1 - entrance));
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
  bool shouldRepaint(RibbonPainter oldDelegate) => oldDelegate.entrance != entrance;
}
