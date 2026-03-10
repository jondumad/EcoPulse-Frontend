import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'eco_pulse_widgets.dart';

class EcoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final bool isTransparent;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final double? height;

  const EcoAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.isTransparent = false,
    this.actions,
    this.onBackPressed,
    this.height,
  }) : assert(
         title == null || titleWidget == null,
         'Cannot provide both title and titleWidget',
       );

  /// Standard AppBar for Authentication screens (transparent, back card, no title)
  factory EcoAppBar.auth({
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    return EcoAppBar(
      isTransparent: true,
      showBack: true,
      onBackPressed: onBackPressed,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? (titleWidget != null ? 100 : 80));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isTransparent
          ? null
          : const BoxDecoration(
              color: EcoColors.clay,
              border: Border(
                bottom: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.06), width: 1),
              ),
            ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              // Slot 1: Back Action
              if (showBack)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: EcoAppBarAction(
                    onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 16,
                  ),
                ),

              // Slot 2: Flexible Content Zone
              Expanded(
                child: titleWidget ??
                    (title != null
                        ? Text(
                            title!,
                            style: GoogleFonts.fraunces(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: EcoColors.ink,
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          )
                        : const SizedBox.shrink()),
              ),

              // Slot 3: Custom Actions Zone
              if (actions != null && actions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!.map((action) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: action,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized Action Button for Header Zone
class EcoAppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final String? tooltip;

  const EcoAppBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 18,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: EcoColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
