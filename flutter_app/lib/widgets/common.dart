import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';

/// Displays the official VantoPay logo with a fallback glyph.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          AppConfig.logoAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.account_balance_wallet_outlined,
            size: size * 0.6,
            color: isDark ? VantoPayTheme.paper : VantoPayTheme.ink,
          ),
        ),
      ),
    );
  }
}

/// A minimalist surface card.
class VPCard extends StatelessWidget {
  const VPCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Card(child: Padding(
        padding: padding,
        child: child,
      ));
}

/// Primary filled action button.
class VPButton extends StatelessWidget {
  const VPButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutline = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutline;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    // When disabled (onPressed == null) the framework applies the disabled
    // state automatically from the theme.
    final button = isOutline
        ? OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: Theme.of(context).outlinedButtonTheme.style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
          )
        : FilledButton(
            onPressed: enabled ? onPressed : null,
            style: Theme.of(context).filledButtonTheme.style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) const SizedPaddedSpinningIndicator(),
                if (!loading && icon != null) Icon(icon, size: 20),
                if (!loading) ...[const SizedBox(width: 8), Text(label)],
              ],
            ),
          );
    return button;
  }
}

class SizedPaddedSpinningIndicator extends StatelessWidget {
  const SizedPaddedSpinningIndicator({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

/// A screen scaffold with consistent header treatment.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.body,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget body;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .appBarTheme
                          .foregroundColor
                          ?.withOpacity(0.6)),
                ),
              ),
          ],
        ),
        actions: [trailing ?? const SizedBox.shrink()],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: body,
      ),
    );
  }
}

/// Amount text that respects the monochrome palette (sign distinguishes flow).
class AmountText extends StatelessWidget {
  const AmountText(
      {super.key, required this.text, this.positive = false, this.size = 16});
  final String text;
  final bool positive;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? VantoPayTheme.paper
        : VantoPayTheme.ink;
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          if (action != null) action!,
        ],
      );
}

/// Honest notice shown when a feature depends on an external integration that
/// is not yet configured. Never fakes data.
class IntegrationNotice extends StatelessWidget {
  const IntegrationNotice({super.key, required this.title, this.detail});
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? VantoPayTheme.surfaceAlt : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? VantoPayTheme.line : VantoPayTheme.paperLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 20,
              color: isDark ? VantoPayTheme.ghost : const Color(0xFF6B6B70)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(detail!,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? VantoPayTheme.ghost
                                : const Color(0xFF6B6B70))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(icon,
                size: 40,
                color: isDark ? VantoPayTheme.ghost : const Color(0xFFB0B0B5)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark
                      ? VantoPayTheme.ghost
                      : const Color(0xFF6B6B70))),
        ],
      ),
    );
  }
}

/// A simple error banner.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: const BorderSide(color: VantoPayTheme.line),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_outlined, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 14, color: VantoPayTheme.paper))),
      ]),
    );
  }
}
