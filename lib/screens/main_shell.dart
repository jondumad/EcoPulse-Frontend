import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/active_mission_tracker.dart';
import '../components/custom_navigation_bar.dart';
import '../components/grain_overlay.dart';
import 'profile_screen.dart';
import 'volunteer/mission_hub.dart';
import 'coordinator/create_mission_screen.dart';
import 'coordinator/verification_screen.dart';
import 'coordinator/coordinator_mission_list.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const SizedBox.shrink();

    // Determine content based on role
    Widget content;
    List<IconData> navItems;

    if (user.role == 'Volunteer') {
      content = _buildVolunteerContent();
      navItems = [
        Icons.map_outlined, // Map (Mission List)
        Icons.emoji_events_outlined, // Badges
        Icons.person_outline, // Profile
      ];
    } else {
      content = _buildCoordinatorContent();
      navItems = [
        Icons.assignment_outlined,
        Icons.verified_user_outlined,
        Icons.groups_outlined,
        Icons.person_outline,
      ];
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.clay,
      appBar: AppBar(
        title: Text(
          _selectedIndex == navItems.length - 1
              ? 'My Profile'
              : (user.role == 'Volunteer'
                    ? (_selectedIndex == 0 ? 'Field Logs' : 'Badges')
                    : (_selectedIndex == 0
                          ? 'Create Mission'
                          : _selectedIndex == 1
                          ? 'Verification'
                          : 'Team')),
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // TODO: Implement Notifications UI (Inbox) - See backend/src/controllers/attendanceController.js:254
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.ink),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Content Wrapper with Padding for Nav
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100), // Nav clearance
              child: content,
            ),
          ),

          // 2. Grain Overlay
          const Positioned.fill(child: GrainOverlay()),

          // 3. Active Mission Tracker (Floating above content, below nav)
          if (user.role == 'Volunteer')
            const Positioned(
              bottom: 90, // Just above nav
              left: 0,
              right: 0,
              child: ActiveMissionTracker(),
            ),

          // 4. Custom Floating Navigation
          CustomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: navItems,
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerContent() {
    final screens = [
      const MissionHub(),
      const Center(child: Text('Badges & Achievements (Coming Soon)')),
      const ProfileScreen(),
    ];
    return screens[_selectedIndex];
  }

  Widget _buildCoordinatorContent() {
    final screens = [
      const CreateMissionScreen(),
      const VerificationScreen(),
      // Current Missions Hub for Coordinators
      const CoordinatorMissionListScreen(),
      const ProfileScreen(),
    ];
    return screens[_selectedIndex];
  }
}
