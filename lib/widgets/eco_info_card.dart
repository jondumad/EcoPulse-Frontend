import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'eco_pulse_widgets.dart';

enum InfoCardVariant {
  emergency,
  note,
  info,
}

class EcoInfoCard extends StatelessWidget {
  final String title;
  final String content;
  final InfoCardVariant variant;
  final IconData? icon;

  const EcoInfoCard({
    super.key,
    required this.title,
    required this.content,
    this.variant = InfoCardVariant.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _getAccentColor();
    final IconData displayIcon = icon ?? _getDefaultIcon();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  displayIcon,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: EcoText.monoSM(context).copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.ink.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColor() {
    switch (variant) {
      case InfoCardVariant.emergency:
        return AppTheme.terracotta;
      case InfoCardVariant.note:
        return AppTheme.violet;
      case InfoCardVariant.info:
        return AppTheme.forest;
    }
  }

  IconData _getDefaultIcon() {
    switch (variant) {
      case InfoCardVariant.emergency:
        return Icons.warning_amber_rounded;
      case InfoCardVariant.note:
        return Icons.edit_note_rounded;
      case InfoCardVariant.info:
        return Icons.info_outline_rounded;
    }
  }
}
