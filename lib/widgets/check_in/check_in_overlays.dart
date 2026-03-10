import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/atoms/eco_button.dart';

class CheckInLoadingOverlay extends StatelessWidget {
  const CheckInLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OverlayWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: AppTheme.forest),
          SizedBox(height: 16),
          Text(
            'Triangulating Signal...',
            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CheckInErrorOverlay extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const CheckInErrorOverlay({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _OverlayWrapper(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off,
              size: 48,
              color: AppTheme.terracotta,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.ink),
            ),
            const SizedBox(height: 16),
            EcoPulseButton(
              label: 'RETRY POSITIONING',
              onPressed: onRetry,
              isSmall: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayWrapper extends StatelessWidget {
  final Widget child;
  const _OverlayWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.8),
      child: Center(child: child),
    );
  }
}
