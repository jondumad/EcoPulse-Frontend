import 'package:flutter/material.dart';

// --- Design System Colors ---
class EcoColors {
  static const Color clay = Color(0xFFF4F1EE);
  static const Color forest = Color(0xFF1B4332);
  static const Color violet = Color(0xFF7F30FF);
  static const Color terracotta = Color(0xFFD66853);
  static const Color ink = Color(0xFF1A1C1E);
  static const Color paperShadow = Color.fromRGBO(0, 0, 0, 0.05);
}

// --- Design System Typography Styles (Helpers) ---
class EcoText {
  static TextStyle displayXL(BuildContext context) => const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: EcoColors.ink,
      );

  static TextStyle displayLG(BuildContext context) => const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: EcoColors.ink,
      );

  static TextStyle displayMD(BuildContext context) => const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: EcoColors.ink,
      );

  static TextStyle bodyMD(BuildContext context) => const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: EcoColors.ink,
      );

  static TextStyle monoSM(BuildContext context) => const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: EcoColors.ink,
      );
}

// --- Components ---

class EcoPulseLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const EcoPulseLayout({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.clay,
      appBar: appBar,
      body: Stack(
        children: [
          // Grain Overlay (Simulated with opacity/pattern if asset existed, 
          // using a subtle noise color blend for now)
          Container(
            decoration: BoxDecoration(
              color: EcoColors.clay,
              // Ideally use an image asset for grain
            ),
          ),
          SafeArea(child: child),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

class EcoPulseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;

  const EcoPulseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: EcoColors.forest.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
          borderRadius: BorderRadius.circular(40),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: EcoColors.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            elevation: 0, // Handled by Container
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(label),
                  ],
                ),
        ),
      );
    } else {
      // Secondary
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: EcoColors.forest,
          side: const BorderSide(color: EcoColors.forest, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      );
    }
  }
}

enum CardVariant { paper, hero }

class EcoPulseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final CardVariant variant;

  const EcoPulseCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.variant = CardVariant.paper,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == CardVariant.hero) {
      return Container(
        decoration: BoxDecoration(
          color: EcoColors.ink,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 20),
              blurRadius: 40,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
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
                    color: EcoColors.violet.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter:
                        const ColorFilter.mode(Colors.transparent, BlendMode.srcOver), 
                        // Flutter blur needs ImageFilter, simplified for now
                        // Real implementation would use ImageFilter.blur
                  ),
                ),
              ),
              // Content
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(24),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: Theme.of(context).textTheme.apply(
                            bodyColor: Colors.white,
                            displayColor: Colors.white,
                          ),
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Paper Variant (Default)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: EcoColors.paperShadow),
        borderRadius: BorderRadius.circular(2), // Almost sharp
        boxShadow: const [
          BoxShadow(
            color: EcoColors.paperShadow,
            offset: Offset(4, 4),
            blurRadius: 0, // Hard shadow
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class EcoPulseTag extends StatelessWidget {
  final String label;
  final bool isRotated;

  const EcoPulseTag({
    super.key,
    required this.label,
    this.isRotated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: isRotated ? 0.035 : 0, // ~2 degrees
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: EcoColors.terracotta,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(2, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class EcoPulseStamp extends StatelessWidget {
  final String label;

  const EcoPulseStamp({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.21, // ~ -12 degrees
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: EcoColors.forest.withValues(alpha: 0.6),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: EcoColors.forest.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
