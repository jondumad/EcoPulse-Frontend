import 'package:flutter/material.dart';
import 'eco_pulse_widgets.dart';

/// A reusable search bar component for mission lists.
class MissionSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  const MissionSearchBar({
    super.key,
    this.hintText = 'Search missions...',
    this.onChanged,
    this.controller,
    this.onClear,
  });

  @override
  State<MissionSearchBar> createState() => _MissionSearchBarState();
}

class _MissionSearchBarState extends State<MissionSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.controller == null) {
      _controller.addListener(_onInternalControllerChanged);
    }
  }

  void _onInternalControllerChanged() {
    setState(() {}); // Trigger rebuild to show/hide clear icon
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.removeListener(_onInternalControllerChanged);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          30,
        ), // Matching existing search bar radius
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _controller.clear();
                    if (widget.onClear != null) {
                      widget.onClear!();
                    } else if (widget.onChanged != null) {
                      widget.onChanged!('');
                    }
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          // contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: EcoColors.ink.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

/// A filter chip tailored to EcoPulse design.
class EcoFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const EcoFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Using the custom container style from volunteer screen as it looks more flexible
    // but adapting it to support `FilterChip` behavior or just GestureDetector.
    // The volunteer implementation was GestureDetector-based.
    // The coordinator implementation was FilterChip-based.
    // Let's use the GestureDetector one for full control over the look (shadows etc).

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color.fromRGBO(0, 0, 0, 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : EcoColors.ink.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// A sort button popup menu.
class MissionSortButton extends StatelessWidget {
  final Function(String) onSelected;
  final List<String> sortOptions;
  final String currentSort;

  const MissionSortButton({
    super.key,
    required this.onSelected,
    this.sortOptions = const [
      'Date',
      'Volunteer fill rate',
      'Status',
      'Distance',
    ],
    required this.currentSort,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, color: EcoColors.ink),
      tooltip: 'Sort by',
      onSelected: onSelected,
      itemBuilder: (context) => sortOptions
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Text(option),
                  if (currentSort == option) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 16, color: EcoColors.forest),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
