import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../components/mission_view_toggle.dart';
import 'mission_detail_screen.dart';
import 'mission_list_screen.dart';
import 'mission_map.dart';
import '../../models/mission_model.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_card.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Consumer<AttendanceProvider>(
          builder: (context, attendanceProvider, _) {
            final hasActiveMission = attendanceProvider.currentAttendance != null;
            
            // --- Precise Safe Area Refactor: Obstruction Rects ---
            final List<Rect> mapObstructions = [];

            // 0. Navigation Bar Obstruction (Bottom Center)
            // Matches CustomNavigationBar: margin 16, maxWidth 420
            final double navWidth = screenWidth > 452 ? 420.0 : screenWidth - 32;
            final double navLeft = (screenWidth - navWidth) / 2;
            mapObstructions.add(Rect.fromLTRB(
              navLeft,
              screenHeight - 94, // Approx top of nav (24 margin + ~70 height)
              navLeft + navWidth,
              screenHeight - 12, // Bottom of nav area
            ));

            // 1. Unified Right-side obstruction (Buttons + Toggle)
            // Both are 52px wide and positioned at right: 20
            final double buttonsRight = screenWidth - 20;
            final double buttonsLeft = buttonsRight - 52;
            
            final double toggleBottom = hasActiveMission ? 180.0 : 100.0;
            final double fabBottom = hasActiveMission ? 280.0 : 200.0;

            // Group them into one single vertical rectangle to prevent indicators 
            // from trying to squeeze into the tiny gap between them.
            mapObstructions.add(Rect.fromLTRB(
              buttonsLeft, 
              screenHeight - fabBottom - 112, // Top of FABs
              buttonsRight, 
              screenHeight - toggleBottom     // Bottom of Toggle
            ));

            // 2. Selected Mission Card (if any)
            if (_selectedMission != null && _showMap) {
              final double cardBottom = hasActiveMission ? 180.0 : 100.0;
              // Card is from left: 20 to right: 90
              mapObstructions.add(Rect.fromLTRB(
                20, 
                screenHeight - cardBottom - 100, // Approx height
                screenWidth - 90, 
                screenHeight - cardBottom
              ));
            }

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
                            bottomPadding: 40.0, // Default minimal padding
                            rightPadding: 45.0,  // Default minimal padding
                            obstructions: mapObstructions,
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

                // 2a. Map-Specific Floating Buttons (Slide in/out)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  right: _showMap ? 20 : -80, // Slide in/out from right
                  bottom: hasActiveMission ? 280 : 200, // Above the toggle
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // My Location Button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isLocating
                                ? EcoColors.forest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _isLocating
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
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: _isLocating
                                      ? const SizedBox(
                                          key: ValueKey('loading'),
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          key: const ValueKey('icon'),
                                          Icons.my_location,
                                          size: 20,
                                          color: EcoColors.forest.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Registered Filter Button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _showRegisteredOnly
                                ? EcoColors.forest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  _showRegisteredOnly = !_showRegisteredOnly;
                                  _selectedMission = null;
                                });
                              },
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    key: ValueKey(_showRegisteredOnly),
                                    _showRegisteredOnly
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 20,
                                    color: _showRegisteredOnly
                                        ? Colors.white
                                        : EcoColors.forest.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2b. View Toggle (Always visible)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  right: 20,
                  bottom: hasActiveMission ? 180 : 100,
                  child: MissionViewToggle(
                    showMap: _showMap,
                    onToggle: _toggleView,
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
      },
    );
  }
}
