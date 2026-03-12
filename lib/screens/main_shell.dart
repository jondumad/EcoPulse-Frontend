import 'package:flutter/material.dart';
import 'package:frontend/providers/collaboration_provider.dart';
import '../providers/nav_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/eco_app_bar.dart';
import '../widgets/active_mission_tracker.dart';
import '../components/custom_navigation_bar.dart';
import 'volunteer_home_screen.dart';
import 'profile_screen.dart';
import 'volunteer/mission_hub.dart';
import 'coordinator/create_mission_screen.dart';
import 'coordinator/verification_screen.dart';
import 'coordinator/coordinator_mission_list.dart';
import 'coordinator/analytics_screen.dart';
import 'notification_inbox_screen.dart';
import '../components/coordinator_speed_dial.dart';
import '../widgets/compass_calibration_overlay.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../components/selection_pill_menu.dart';
import '../providers/mission_provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        // Refresh attendance status globally when entering the shell
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<AttendanceProvider>(context, listen: false).refresh();
          }
        });

        if (user.role == 'Volunteer') {
          // Schedule the navigation update after the current build frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Provider.of<NavProvider>(context, listen: false).setIndex(1);
            }
          });
        }
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavProvider>(context);
    final selectedIndex = nav.selectedIndex;
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const SizedBox.shrink();

    // Determine content based on role
    Widget content;
    List<IconData> navIcons;
    List<String> navLabels;

    if (user.role == 'Volunteer') {
      content = _buildVolunteerContent(selectedIndex);
      navIcons = [
        Icons.map_outlined,
        Icons.home_outlined,
        Icons.person_outline,
      ];
      navLabels = ['Map', 'Home', 'Profile'];
    } else {
      content = _buildCoordinatorContent(selectedIndex);
      navIcons = [
        Icons.groups_outlined,
        Icons.verified_user_outlined,
        Icons.analytics_outlined,
        Icons.person_outline,
      ];
      navLabels = ['Hub', 'Verify', 'Analytics', 'Profile'];
    }

    final String activeLabel = selectedIndex == navIcons.length - 1
        ? 'My Profile'
        : (user.role == 'Volunteer'
              ? (selectedIndex == 1 ? 'Home' : 'Active Missions')
              : (selectedIndex == 0
                    ? 'Mission Hub'
                    : selectedIndex == 1
                    ? 'Verification'
                    : 'Impact Analytics'));

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.clay,
      appBar: EcoAppBar(
        showBack: false,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEEE, MMM d · HH:mm').format(DateTime.now()),
              style: EcoText.monoSM(context).copyWith(
                color: AppTheme.ink.withValues(alpha: 0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              activeLabel,
              style: EcoText.displayLG(context).copyWith(
                fontSize: 28,
                color: AppTheme.ink,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          if (selectedIndex == navIcons.length - 1)
            EcoAppBarAction(
              icon: Icons.logout_outlined,
              tooltip: 'Logout',
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          EcoAppBarAction(
            icon: Icons.notifications_outlined,
            tooltip: 'Notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationInboxScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Content Wrapper (No bottom padding for true floating effect)
          Positioned.fill(child: content),

          // 3. Active Mission Tracker (Floating above content, below nav)
          if (user.role == 'Volunteer' && selectedIndex == 1)
            const Positioned(
              bottom: 90, // Just above nav
              left: 0,
              right: 0,
              child: ActiveMissionTracker(),
            ),

          // 4. Custom Floating Navigation
          CustomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => nav.setIndex(index),
            icons: navIcons,
            labels: navLabels,
          ),

          // 5. Coordinator Speed Dial (Positioned above nav)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            bottom: 110,
            right: (user.role == 'Coordinator' && selectedIndex == 0)
                ? 24
                : -400,
            child: CoordinatorSpeedDial(
              onNewMission: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMissionScreen(),
                  ),
                );
              },
            ),
          ),

          // 5.1 Batch Selection Pill (Only for Coordinator in selection mode)
          if (user.role == 'Coordinator' && selectedIndex == 0)
            const SelectionPillMenu(),

          // 6. Global Compass Calibration Overlay
          const CompassCalibrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildVolunteerContent(int index) {
    return IndexedStack(
      index: index,
      children: const [
        MissionHub(), // Map tab (contains the Map/List toggle)
        VolunteerHomeScreen(), // Home tab implemented
        ProfileScreen(),
      ],
    );
  }

  Widget _buildCoordinatorContent(int index) {
    return IndexedStack(
      index: index,
      children: const [
        CoordinatorMissionListScreen(),
        VerificationScreen(),
        CoordinatorAnalyticsScreen(),
        ProfileScreen(),
      ],
    );
  }
}
