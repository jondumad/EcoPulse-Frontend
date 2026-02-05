import 'package:flutter/material.dart';
import 'package:frontend/widgets/eco_app_bar.dart';
import '../theme/app_theme.dart';

class LevelDetailsScreen extends StatelessWidget {
  const LevelDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EcoAppBar(title: 'Level Details'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: AppTheme.violet),
            const SizedBox(height: 16),
            Text(
              'Level Progress\nComing Soon',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.displayMedium,
            ),
          ],
        ),
      ),
    );
  }
}
