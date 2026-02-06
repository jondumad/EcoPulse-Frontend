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
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: EcoColors.forest,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: EcoColors.forest.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleItem(
                icon: Icons.map_outlined,
                isSelected: showMap,
                isVertical: true,
              ),
              const SizedBox(height: 4),
              _ToggleItem(
                icon: Icons.list_alt_rounded,
                isSelected: !showMap,
                isVertical: true,
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
  final bool isVertical;

  const _ToggleItem({
    required this.icon,
    required this.isSelected,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? EcoColors.forest
              : Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
