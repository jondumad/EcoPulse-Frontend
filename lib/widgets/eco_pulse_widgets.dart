import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// --- Design System Typography Styles (Helpers) ---
class EcoText {
  static TextStyle displayXL(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.5,
    height: 1.1,
    color: AppTheme.ink,
  );

  static TextStyle displayLG(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
    color: AppTheme.ink,
  );

  static TextStyle displayMD(BuildContext context) => GoogleFonts.fraunces(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppTheme.ink,
  );

  static TextStyle bodyMD(BuildContext context) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppTheme.ink,
  );

  static TextStyle bodySM(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.ink.withValues(alpha: 0.6),
  );

  static TextStyle headerMD(BuildContext context) => displayMD(context);

  static TextStyle bodyBoldMD(BuildContext context) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppTheme.ink,
  );

  static TextStyle bodyBoldSM(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.ink,
  );

  static TextStyle h3(BuildContext context) => displayMD(context);

  static TextStyle monoSM(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: const Color.fromRGBO(26, 28, 30, 0.6),
  );

  static TextStyle monoBoldSM(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
    color: AppTheme.ink,
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
      backgroundColor: AppTheme.clay,
      appBar: appBar,
      body: Stack(
        children: [
          // Grain Overlay Simulation
          Container(decoration: const BoxDecoration(color: AppTheme.clay)),
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
    final bgColor = color ?? AppTheme.forest;

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
            color: AppTheme.forest.withValues(alpha: 0.6),
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
            color: AppTheme.forest.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class EcoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const EcoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppTheme.ink.withValues(alpha: 0.4),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: EcoText.bodySM(context).copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
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
    this.color = AppTheme.forest,
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
            color: AppTheme.ink.withValues(alpha: 0.5),
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
    this.color = AppTheme.forest,
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
            color: AppTheme.ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class EcoDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget child;
  final List<Widget>? actions;

  const EcoDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.actions,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? icon,
    required Widget child,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EcoDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        actions: actions,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        constraints: BoxConstraints(maxHeight: screenHeight * 0.45),
        decoration: const BoxDecoration(
          color: AppTheme.clay,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.violet.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconTheme(
                              data: const IconThemeData(size: 18),
                              child: icon!,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.fraunces(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.ink,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: TextStyle(
                                    color: AppTheme.ink.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    child,
                    if (actions != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: actions!
                            .map(
                              (a) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: a,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class EcoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? hint;
  final IconData? prefixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool obscureText;

  const EcoTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: EcoText.monoSM(context).copyWith(fontSize: 8),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppTheme.clay,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            validator: validator,
            obscureText: obscureText,
            style: EcoText.bodyBoldMD(context),
            decoration: InputDecoration(
              hintText: hintText ?? hint,
              hintStyle: EcoText.bodySM(
                context,
              ).copyWith(color: AppTheme.ink.withValues(alpha: 0.3)),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 20,
                      color: AppTheme.ink.withValues(alpha: 0.4),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
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
                AppTheme.clay,
                AppTheme.clay.withValues(alpha: 0.5),
                AppTheme.clay,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
