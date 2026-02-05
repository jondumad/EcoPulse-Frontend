import 'package:flutter/material.dart';
import '../widgets/eco_pulse_widgets.dart';

class AuthErrorMessage extends StatelessWidget {
  final String? errorMessage;
  final bool isVisible;

  const AuthErrorMessage({
    super.key,
    required this.errorMessage,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isVisible && errorMessage != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Semantics(
                liveRegion: true,
                label: 'Error: $errorMessage',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: EcoColors.terracotta.withValues(alpha: 0.1),
                    border: Border.all(
                      color: EcoColors.terracotta.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: EcoColors.terracotta,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: EcoColors.terracotta,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
