import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Dropzy brand icon tile — red rounded square with a truck (matches the app).
class DropzyIconTile extends StatelessWidget {
  const DropzyIconTile({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DropzyColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Logo lockup: truck tile + "Dropzy" wordmark.
class DropzyLogo extends StatelessWidget {
  const DropzyLogo({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropzyIconTile(size: size),
        SizedBox(width: size * 0.28),
        Text(
          'Dropzy',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            color: DropzyColors.ink,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: DropzyColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: DropzyColors.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: DropzyColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: DropzyColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: DropzyColors.ink)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DropzyColors.inkSoft, height: 1.4)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DropzyColors.primary,
                  side: const BorderSide(color: DropzyColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// White rounded card used across screens (soft shadow, no border).
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: DropzyColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
