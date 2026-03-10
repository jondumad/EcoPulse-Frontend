import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// The full-bleed gradient header displayed at the top of the Mission card.
/// Shows the mission category emoji icon and title on a forest-green gradient.
class MissionDetailHero extends StatelessWidget {
  final String icon;
  final String title;

  const MissionDetailHero({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.forest, Color(0xFF153827)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
