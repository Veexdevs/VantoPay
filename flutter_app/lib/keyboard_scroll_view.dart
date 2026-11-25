import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Keep keyboard avoidance in one place instead of resizing both the Scaffold
/// and its scroll view. The background remains full-screen while only the form
/// yields space to the keyboard.
class KeyboardScrollView extends StatefulWidget {
  const KeyboardScrollView({
    super.key,
    required this.padding,
    required this.builder,
  });

  final EdgeInsetsGeometry padding;
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  @override
  State<KeyboardScrollView> createState() => _KeyboardScrollViewState();
}

class _KeyboardScrollViewState extends State<KeyboardScrollView>
    with WidgetsBindingObserver {
  final scroll = ScrollController(keepScrollOffset: false);
  ui.FlutterView? view;
  double lastInset = 0;
  double offsetBeforeKeyboard = 0;
  double? restoreOffset;
  bool repairScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextView = View.of(context);
    if (nextView != view) {
      view = nextView;
      lastInset = nextView.viewInsets.bottom / nextView.devicePixelRatio;
    }
  }

  @override
  void didChangeMetrics() {
    final currentView = view;
    if (!mounted || currentView == null) return;
    final inset = currentView.viewInsets.bottom / currentView.devicePixelRatio;
    if (inset > 0 && lastInset == 0) {
      offsetBeforeKeyboard = scroll.hasClients ? scroll.offset : 0;
      restoreOffset = null;
    } else if (inset == 0 && lastInset > 0) {
      restoreOffset = offsetBeforeKeyboard;
    }
    lastInset = inset;
    if (repairScheduled) return;
    repairScheduled = true;
    // Metrics notifications arrive before MediaQuery/Scaffold have laid out the
    // new viewport. Repair against the NEW extents, never the keyboard's extents.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      repairScheduled = false;
      if (!mounted || !scroll.hasClients || !scroll.position.hasContentDimensions) return;
      final position = scroll.position;
      final target = (restoreOffset ?? position.pixels)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      restoreOffset = null;
      if ((position.pixels - target).abs() > 0.5) {
        // No animation competes with the browser/IME restoring its viewport.
        scroll.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const ValueKey('auth-scroll-view'),
              controller: scroll,
              padding: widget.padding,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const ClampingScrollPhysics(),
              child: widget.builder(context, constraints),
            ),
          ),
        ),
      );
}
