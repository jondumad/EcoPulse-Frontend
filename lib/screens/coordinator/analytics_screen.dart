import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';

class CoordinatorAnalyticsScreen extends StatelessWidget {
  const CoordinatorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: AppTheme.forest.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Impact Analytics',
            style: AppTheme.lightTheme.textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Detailed mission reports, volunteer retention data, and ecological impact metrics are coming soon.',
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          EcoPulseCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.violet),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This tab will provide data-driven insights to help you optimize mission planning.',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
