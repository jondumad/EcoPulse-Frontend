import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class EcoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool centerTitle;
  final double height;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const EcoAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.actions,
    this.backgroundColor,
    this.centerTitle = false,
    this.height = kToolbarHeight,
    this.onBackPressed,
    this.bottom,
  }) : assert(
         title == null || titleWidget == null,
         'Cannot provide both title and titleWidget',
       );

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false, // We handle leading manually
      systemOverlayStyle:
          SystemUiOverlayStyle.dark, // Keep status bar icons dark
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.ink),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              tooltip: 'Back',
            )
          : null,
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: centerTitle
                      ? const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20, // Slightly smaller for centered
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                          letterSpacing: -0.5,
                        )
                      : const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 28, // Large flush left
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                          letterSpacing: -1.0,
                        ),
                )
              : null),
      actions: actions,
      bottom: bottom,
    );
  }
}
