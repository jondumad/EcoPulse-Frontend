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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: EcoColors.forest,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: EcoColors.forest.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleItem(
                icon: Icons.map_outlined,
                label: 'Map',
                isSelected: showMap,
              ),
              _ToggleItem(
                icon: Icons.list_alt_rounded,
                label: 'List',
                isSelected: !showMap,
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
  final String label;
  final bool isSelected;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 20 : 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? EcoColors.forest : Colors.white60,
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: EcoColors.forest,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
