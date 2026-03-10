import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static TextStyle displayXL(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.5,
    height: 1.1,
    color: EcoColors.ink,
  );

  static TextStyle displayLG(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
    color: EcoColors.ink,
  );

  static TextStyle displayMD(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: EcoColors.ink,
  );

  static TextStyle bodyMD(BuildContext context) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: EcoColors.ink,
  );

  static TextStyle bodySM(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: EcoColors.ink.withValues(alpha: 0.6),
  );

  static TextStyle headerMD(BuildContext context) => displayMD(context);

  static TextStyle bodyBoldMD(BuildContext context) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: EcoColors.ink,
  );

  static TextStyle monoSM(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: const Color.fromRGBO(26, 28, 30, 0.6),
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
          // Grain Overlay Simulation
          Container(decoration: const BoxDecoration(color: EcoColors.clay)),
          // Subtler texture if we had the asset, for now we rely on MainShell's GrainOverlay
          SafeArea(child: child),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

class EcoPulseTag extends StatelessWidget {
  final String label;
  final bool isRotated;
  final Color? color;

  const EcoPulseTag({
    super.key,
    required this.label,
    this.isRotated = false, // Default to flat for better map alignment
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? EcoColors.forest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30), // Pill shape for softness
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          height: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class EcoPulseStamp extends StatelessWidget {
  final String label;

  const EcoPulseStamp({super.key, required this.label});

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

class EcoSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const EcoSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: EcoColors.ink.withValues(alpha: 0.4),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EcoStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const EcoStatItem({
    super.key,
    required this.label,
    required this.value,
    this.color = EcoColors.forest,
  });

  @override
  Widget build(BuildContext context) {
    // If the value is a number, we can use the animated version automatically
    final double? numericValue = double.tryParse(value);
    if (numericValue != null) {
      return EcoAnimatedStatItem(
        label: label,
        value: numericValue,
        color: color,
        isInteger: !value.contains('.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.fraunces(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: EcoColors.ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class EcoAnimatedStatItem extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  final bool isInteger;

  const EcoAnimatedStatItem({
    super.key,
    required this.label,
    required this.value,
    this.color = EcoColors.forest,
    this.isInteger = true,
  });

  @override
  State<EcoAnimatedStatItem> createState() => _EcoAnimatedStatItemState();
}

class _EcoAnimatedStatItemState extends State<EcoAnimatedStatItem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _controller.forward();
  }

  @override
  void didUpdateWidget(EcoAnimatedStatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            String displayValue;
            if (widget.isInteger) {
              displayValue = _animation.value.toInt().toString();
            } else {
              displayValue = _animation.value.toStringAsFixed(1);
            }

            return Text(
              displayValue,
              style: GoogleFonts.fraunces(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: widget.color,
                height: 1,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: EcoColors.ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class EcoPulseSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;

  const EcoPulseSkeleton({
    super.key,
    this.width,
    this.height,
    this.radius = 12,
  });

  @override
  State<EcoPulseSkeleton> createState() => _EcoPulseSkeletonState();
}

class _EcoPulseSkeletonState extends State<EcoPulseSkeleton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, -1),
              end: Alignment(_animation.value + 1, 1),
              colors: [
                EcoColors.clay,
                EcoColors.clay.withValues(alpha: 0.5),
                EcoColors.clay,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
