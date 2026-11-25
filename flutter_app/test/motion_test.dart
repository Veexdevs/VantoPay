import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantopay/main.dart';
import 'package:vantopay/motion.dart';

void main() {
  testWidgets('brand asset has real transparency, not a black rectangle', (tester) async {
    await tester.runAsync(() async {
    final bytes = await rootBundle.load('assets/brand/logo.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final pixels = (await frame.image.toByteData())!.buffer.asUint8List();
    expect(pixels[3], 0, reason: 'The corner must be transparent.');
    var transparent = 0;
    var opaque = 0;
    for (var i = 3; i < pixels.length; i += 4) {
      if (pixels[i] == 0) { transparent++; }
      if (pixels[i] == 255) { opaque++; }
    }
    expect(transparent, greaterThan(frame.image.width * frame.image.height ~/ 3));
    expect(opaque, greaterThan(1000), reason: 'Preserve the white logo.');
    frame.image.dispose();
    codec.dispose();
    });
  });

  testWidgets('compact logo and wider buttons fit a phone without scrolling', (tester) async {
    tester.view.physicalSize = const Size(440, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const VantoPayApp());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Image)).width, 154);
    final button = find.byType(OutlinedButton).first;
    expect(tester.getSize(button).height, 48);
    expect(tester.getSize(button).width, 400);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staggered reveal animates once and finishes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MotionReveal(delay: 100, child: Text('Motion')),
    )));
    final opacity = find.descendant(of: find.byType(MotionReveal), matching: find.byType(Opacity));
    expect(tester.widget<Opacity>(opacity).opacity, 0);
    await tester.pump(const Duration(milliseconds: 260));
    final halfway = tester.widget<Opacity>(opacity).opacity;
    expect(halfway, greaterThan(0));
    expect(halfway, lessThan(1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('system reduced motion disables reveals and layout animation', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: const AuthPage(),
    )));
    await tester.pump();
    for (final reveal in find.byType(MotionReveal).evaluate()) {
      final opacity = find.descendant(of: find.byWidget(reveal.widget), matching: find.byType(Opacity)).first;
      expect(tester.widget<Opacity>(opacity).opacity, 1);
    }
    for (final size in tester.widgetList<AnimatedSize>(find.byType(AnimatedSize))) {
      expect(size.duration, Duration.zero);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('button responds to hover and touch without duplicate activation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 300, child: AccessButton(label: 'Continuar', onPressed: () => calls++)),
    ))));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(OutlinedButton)));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.008);
    final press = await tester.startGesture(tester.getCenter(find.byType(OutlinedButton)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.985);
    await press.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
    await mouse.removePointer();
  });
}
