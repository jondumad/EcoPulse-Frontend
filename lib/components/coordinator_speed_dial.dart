import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/coordinator/create_mission_screen.dart';

class CoordinatorSpeedDial extends StatefulWidget {
  final VoidCallback? onNewMission;

  const CoordinatorSpeedDial({
    super.key,
    this.onNewMission,
  });

  @override
  State<CoordinatorSpeedDial> createState() => _CoordinatorSpeedDialState();
}

class _CoordinatorSpeedDialState extends State<CoordinatorSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _labelAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      curve: Curves.easeInOutCubic,
      parent: _controller,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _labelAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Reveal buttons when open
        if (_isOpen || _controller.isAnimating)
          _buildStep(
            icon: Icons.campaign_rounded,
            label: 'Broadcast',
            onTap: () {
              _toggle();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Broadcast feature coming soon')),
              );
            },
          ),
        if (_isOpen || _controller.isAnimating)
          _buildStep(
            icon: Icons.copy_all_rounded,
            label: 'Templates',
            onTap: () {
              _toggle();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Templates feature coming soon')),
              );
            },
          ),
        if (_isOpen || _controller.isAnimating)
          _buildStep(
            icon: Icons.add_task_rounded,
            label: 'New Mission',
            onTap: () {
              _toggle();
              if (widget.onNewMission != null) {
                widget.onNewMission!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMissionScreen(),
                  ),
                );
              }
            },
          ),
        const SizedBox(height: 8),
        // Main Toggle Button
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.forest,
              borderRadius: BorderRadius.circular(_isOpen ? 28 : 16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.forest.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _controller,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 4),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizeTransition(
                        sizeFactor: _labelAnimation,
                        axis: Axis.horizontal,
                        axisAlignment: -1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.clay,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppTheme.forest, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
