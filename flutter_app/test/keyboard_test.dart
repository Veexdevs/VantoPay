import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantopay/keyboard_scroll_view.dart';
import 'package:vantopay/main.dart';
import 'package:vantopay/motion.dart';

const scrollKey = ValueKey('auth-scroll-view');

Future<void> mountAuth(WidgetTester tester, {bool signup = false}) async {
  tester.view.physicalSize = const Size(440, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(const VantoPayApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text(signup ? 'Criar Conta' : 'Entrar'));
  await tester.pumpAndSettle();
}

ScrollController controller(WidgetTester tester) =>
    tester.widget<SingleChildScrollView>(find.byKey(scrollKey)).controller!;

Future<void> keyboardInset(WidgetTester tester, double bottom) async {
  tester.view.viewInsets = FakeViewPadding(bottom: bottom);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dismissing the keyboard restores the full login viewport', (tester) async {
    await mountAuth(tester);
    final initialHeight = tester.getSize(find.byKey(scrollKey)).height;
    await tester.enterText(find.byType(TextFormField).first, 'teste@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'senha-preservada');
    await keyboardInset(tester, 320);
    expect(tester.getSize(find.byKey(scrollKey)).height, initialHeight - 320);
    expect(tester.getSize(find.byType(Scaffold)).height, 800,
        reason: 'The background must not shrink with the keyboard.');
    controller(tester).jumpTo(controller(tester).position.maxScrollExtent);
    await tester.pumpAndSettle();
    // Android's back button can dismiss the IME while the field keeps focus.
    tester.testTextInput.hide();
    await keyboardInset(tester, 0);
    expect(tester.getSize(find.byKey(scrollKey)).height, initialHeight);
    expect(controller(tester).offset, closeTo(0, 0.5));
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,
        'teste@example.com');
    expect(tester.widget<TextFormField>(find.byType(TextFormField).last).controller!.text,
        'senha-preservada');
    expect(tester.takeException(), isNull);
  });

  testWidgets('signup survives repeated keyboard height changes without replaying motion', (tester) async {
    await mountAuth(tester, signup: true);
    await tester.enterText(find.byType(TextFormField).at(0), 'Pessoa Teste');
    await tester.enterText(find.byType(TextFormField).at(1), 'teste@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha-preservada');
    final height = tester.getSize(find.byKey(scrollKey)).height;
    for (var i = 0; i < 3; i++) {
      await keyboardInset(tester, 300);
      await tester.ensureVisible(find.byType(TextFormField).last);
      await keyboardInset(tester, 220);
      await keyboardInset(tester, 0);
      expect(tester.getSize(find.byKey(scrollKey)).height, height);
      final position = controller(tester).position;
      expect(position.pixels, inInclusiveRange(position.minScrollExtent, position.maxScrollExtent));
      expect(tester.widget<TextFormField>(find.byType(TextFormField).at(0)).controller!.text,
          'Pessoa Teste');
      final reveal = find.byType(MotionReveal).first;
      final opacity = find.descendant(of: reveal, matching: find.byType(Opacity)).first;
      expect(tester.widget<Opacity>(opacity).opacity, 1);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('restores the prior valid scroll offset, not always the top', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      resizeToAvoidBottomInset: false,
      body: KeyboardScrollView(
        padding: EdgeInsets.zero,
        builder: (_, constraints) => const SizedBox(height: 1400, child: Text('Formulário longo')),
      ),
    )));
    await tester.pumpAndSettle();
    controller(tester).jumpTo(90);
    await keyboardInset(tester, 240);
    controller(tester).jumpTo(500);
    await keyboardInset(tester, 0);
    expect(controller(tester).offset, closeTo(90, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('browser viewport resizing without IME insets recovers completely', (tester) async {
    await mountAuth(tester);
    await tester.enterText(find.byType(TextFormField).first, 'teste@example.com');
    final originalHeight = tester.getSize(find.byKey(scrollKey)).height;
    final originalMaxExtent = controller(tester).position.maxScrollExtent;
    for (var i = 0; i < 2; i++) {
      // Mobile browsers can resize the layout viewport rather than send insets.
      tester.view.physicalSize = const Size(440, 460);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField).last);
      tester.view.physicalSize = const Size(440, 800);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(scrollKey)).height, originalHeight);
      final position = controller(tester).position;
      // A valid form can be taller than the screen. Restoring a browser resize
      // must restore its actual range, not assume every form has zero scroll.
      expect(position.maxScrollExtent, closeTo(originalMaxExtent, 0.5));
      expect(position.pixels, inInclusiveRange(position.minScrollExtent, position.maxScrollExtent));
      expect(tester.takeException(), isNull);
    }
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,
        'teste@example.com');
  });

  testWidgets('rotation with an open keyboard does not strand the form', (tester) async {
    await mountAuth(tester, signup: true);
    await tester.enterText(find.byType(TextFormField).first, 'Pessoa Teste');
    await keyboardInset(tester, 280);
    tester.view.physicalSize = const Size(800, 440);
    await keyboardInset(tester, 180);
    tester.view.physicalSize = const Size(440, 800);
    await keyboardInset(tester, 0);
    expect(tester.getSize(find.byKey(scrollKey)).height, 800);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,
        'Pessoa Teste');
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch outside the form dismisses field focus', (tester) async {
    await mountAuth(tester);
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    final editable = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(editable.focusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });
}
