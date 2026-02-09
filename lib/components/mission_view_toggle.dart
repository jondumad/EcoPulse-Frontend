import 'package:flutter/material.dart';
import '../widgets/eco_pulse_widgets.dart';

class MissionViewToggle extends StatelessWidget {
  final bool showMap;
  final VoidCallback onToggle;

  const MissionViewToggle({
    super.key,
    required this.showMap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const itemHeight = 44.0;
    const spacing = 4.0;
    final selectedIndex = showMap ? 0 : 1;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: SizedBox(
          height: itemHeight * 2 + spacing,
          child: Stack(
            children: [
              // Animated background pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                top: selectedIndex * (itemHeight + spacing),
                left: 0,
                right: 0,
                height: itemHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: EcoColors.forest,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              // Buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToggleItem(
                    icon: Icons.map_outlined,
                    isSelected: showMap,
                    onTap: showMap ? null : onToggle,
                  ),
                  const SizedBox(height: spacing),
                  _ToggleItem(
                    icon: Icons.list_alt_rounded,
                    isSelected: !showMap,
                    onTap: !showMap ? null : onToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ToggleItem({required this.icon, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Colors.white
                : EcoColors.forest.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
