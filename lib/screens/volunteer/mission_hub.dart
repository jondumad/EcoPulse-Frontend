import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../components/mission_view_toggle.dart';
import 'mission_list_screen.dart';
import 'mission_map.dart';

class MissionHub extends StatefulWidget {
  const MissionHub({super.key});

  @override
  State<MissionHub> createState() => _MissionHubState();
}

class _MissionHubState extends State<MissionHub> {
  bool _showMap = true; // Default to map view per existing UX preference

  void _toggleView() {
    setState(() {
      _showMap = !_showMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, _) {
        final hasActiveMission = attendanceProvider.currentAttendance != null;

        return Stack(
          children: [
            // 1. Content Views (Stacked to preserve state)
            Positioned.fill(
              child: Stack(
                children: [
                  // Map View
                  IgnorePointer(
                    ignoring: !_showMap,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _showMap ? 1.0 : 0.0,
                      child: const MissionMap(key: ValueKey('map')),
                    ),
                  ),
                  // List View
                  IgnorePointer(
                    ignoring: _showMap,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _showMap ? 0.0 : 1.0,
                      child: const MissionListScreen(key: ValueKey('list')),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Floating Toggle
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: hasActiveMission
                  ? 180
                  : 100, // Positioned above the floating nav bar
              child: Center(
                child: MissionViewToggle(
                  showMap: _showMap,
                  onToggle: _toggleView,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
