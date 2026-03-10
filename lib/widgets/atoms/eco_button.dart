import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum EcoButtonVariant { primary, secondary, outline, ghost }

class EcoPulseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EcoButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isSmall;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const EcoPulseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = EcoButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isSmall = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  // Factory for backwards compatibility with the "isPrimary" boolean
  factory EcoPulseButton.compat({
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = true,
    bool isLoading = false,
    IconData? icon,
    bool isSmall = false,
    Color? backgroundColor,
    Color? foregroundColor,
    double? width,
  }) {
    return EcoPulseButton(
      label: label,
      onPressed: onPressed,
      variant: isPrimary
          ? EcoButtonVariant.primary
          : EcoButtonVariant.secondary,
      isLoading: isLoading,
      icon: icon,
      isSmall: isSmall,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isLoading || onPressed == null;
    final double radius = isSmall ? 10 : 14;
    final double verticalPadding = isSmall ? 8 : 16;
    final double horizontalPadding = isSmall ? 12 : 24;

    Color bg;
    Color fg;
    BorderSide? border;

    // Resolve Colors based on variant
    switch (variant) {
      case EcoButtonVariant.primary:
        bg = backgroundColor ?? AppTheme.forest;
        fg = foregroundColor ?? Colors.white;
        border = null;
        break;
      case EcoButtonVariant.secondary:
        bg = backgroundColor ?? AppTheme.clay;
        fg = foregroundColor ?? AppTheme.ink;
        border = BorderSide(color: Colors.black.withValues(alpha: 0.06));
        break;
      case EcoButtonVariant.outline:
        bg = Colors.transparent;
        fg = foregroundColor ?? AppTheme.forest;
        border = BorderSide(color: fg, width: 2);
        break;
      case EcoButtonVariant.ghost:
        bg = Colors.transparent;
        fg = foregroundColor ?? AppTheme.ink;
        border = null;
        break;
    }

    return Semantics(
      button: true,
      enabled: !isDisabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        child: Material(
          color: isDisabled ? bg.withValues(alpha: 0.5) : bg,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
              decoration: BoxDecoration(
                border: border != null ? Border.fromBorderSide(border) : null,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Center(
                widthFactor: width == null ? 1.0 : null,
                heightFactor: 1.0,
                child: isLoading
                    ? SizedBox(
                        height: isSmall ? 14 : 20,
                        width: isSmall ? 14 : 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: isSmall ? 14 : 18, color: fg),
                            if (label.isNotEmpty) const SizedBox(width: 8),
                          ],
                          if (label.isNotEmpty)
                            Text(
                              label,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                fontSize: isSmall ? 12 : 15,
                                fontFamily: 'Inter',
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
