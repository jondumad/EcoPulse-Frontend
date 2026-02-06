import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../components/mission_view_toggle.dart';
import 'mission_detail_screen.dart';
import 'mission_list_screen.dart';
import 'mission_map.dart';
import '../../models/mission_model.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class MissionHub extends StatefulWidget {
  const MissionHub({super.key});

  @override
  State<MissionHub> createState() => _MissionHubState();
}

class _MissionHubState extends State<MissionHub> {
  final GlobalKey<MissionMapState> _mapKey = GlobalKey<MissionMapState>();
  bool _showMap = true; // Default to map view per existing UX preference
  Mission? _selectedMission;
  bool _showRegisteredOnly = false;
  bool _isLocating = false;

  void _toggleView() {
    setState(() {
      _showMap = !_showMap;
      _selectedMission = null; // Reset selection when switching views
    });
  }

  void _onMissionSelected(Mission? mission) {
    setState(() {
      _selectedMission = mission;
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
                      child: MissionMap(
                        key: _mapKey,
                        selectedMission: _selectedMission,
                        onMissionSelected: _onMissionSelected,
                        showRegisteredOnly: _showRegisteredOnly,
                      ),
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

            // 2. Floating Toolbar (Vertical Sidebar on Right)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              right: 20,
              bottom: hasActiveMission ? 180 : 100, // Anchored to the side
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Map-Specific Buttons (Grouped Capsule)
                  AnimatedScale(
                    scale: _showMap ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedOpacity(
                      opacity: _showMap ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: EcoColors.forest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: EcoColors.forest.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // My Location Button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isLocating
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: EcoColors.forest,
                                        ),
                                      )
                                    : Icon(
                                        Icons.my_location,
                                        size: 20,
                                        color: _isLocating
                                            ? EcoColors.forest
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                      ),
                                onPressed: _isLocating
                                    ? null
                                    : () async {
                                        setState(() => _isLocating = true);
                                        try {
                                          await _mapKey.currentState
                                              ?.triggerMyLocation();
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isLocating = false);
                                          }
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Registered Filter Button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _showRegisteredOnly
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _showRegisteredOnly
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 20,
                                  color: _showRegisteredOnly
                                      ? EcoColors.forest
                                      : Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showRegisteredOnly = !_showRegisteredOnly;
                                    _selectedMission = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // View Toggle
                  MissionViewToggle(showMap: _showMap, onToggle: _toggleView),
                ],
              ),
            ),

            // 3. High-Density Mission Detail (Packed Info)
            if (_selectedMission != null && _showMap)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                bottom: hasActiveMission ? 180 : 100,
                left: 20,
                right: 90,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MissionDetailScreen(mission: _selectedMission!),
                      ),
                    );
                  },
                  child: EcoPulseCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Condensed Icon Box
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: EcoColors.forest.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _selectedMission!.categories.firstOrNull?.icon ??
                                  '📍',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMission!.title,
                                style: EcoText.bodyBoldMD(context).copyWith(
                                  fontSize: 14,
                                  height: 1.1,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Location Row
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 10,
                                    color: EcoColors.ink.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      _selectedMission!.locationName,
                                      style: EcoText.bodySM(context).copyWith(
                                        fontSize: 10,
                                        color: EcoColors.ink.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Meta Row (Points + Slots)
                              Row(
                                children: [
                                  // Points Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EcoColors.forest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+${_selectedMission!.pointsValue} PTS',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Slots Indicator
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 11,
                                    color: EcoColors.ink.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${_selectedMission!.currentVolunteers}/${_selectedMission!.maxVolunteers ?? "∞"}',
                                    style: EcoText.bodySM(context).copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Date Indicator
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 10,
                                    color: EcoColors.ink.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${_selectedMission!.startTime.day}/${_selectedMission!.startTime.month}',
                                    style: EcoText.bodySM(context).copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Utility Column
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  setState(() => _selectedMission = null),
                            ),
                            const SizedBox(height: 12),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: EcoColors.ink.withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
