import 'package:flutter/material.dart';
import 'eco_pulse_widgets.dart';

class NetworkRetryOverlay extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onRetry;
  final String message;

  const NetworkRetryOverlay({
    super.key,
    required this.isVisible,
    required this.onRetry,
    this.message = 'Connection lost. Please check your internet.',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: EcoPulseCard(
        variant: CardVariant.paper,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: EcoColors.ink),
            const SizedBox(height: 16),
            Text('No Connection', style: EcoText.headerMD(context)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: EcoText.bodyMD(context),
            ),
            const SizedBox(height: 24),
            EcoPulseButton(label: 'Retry', onPressed: onRetry, isSmall: true),
          ],
        ),
      ),
    );
  }
}
