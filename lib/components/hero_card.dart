import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HeroCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      clipBehavior: Clip.antiAlias, // Clip the blur effect
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 20),
            blurRadius: 40,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Purple Glow Accent
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.violet.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            // Blur overlay for the glow
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.violet.withValues(alpha: 0.5),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ],
      ),
    );
  }
}
