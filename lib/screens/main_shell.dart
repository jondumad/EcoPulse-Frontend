import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'volunteer/mission_list_screen.dart';
import 'coordinator/create_mission_screen.dart';

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

    if (user.role == 'Volunteer') {
      return _buildVolunteerShell(context);
    } else {
      return _buildAdminCoordinatorShell(context, user.role);
    }
  }

  Widget _buildVolunteerShell(BuildContext context) {
    final screens = [
      const MissionListScreen(),
      const Center(child: Text('Badges & Achievements (Coming Soon)')),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Badges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCoordinatorShell(BuildContext context, String role) {
    // Coordinators: Missions, Verify, Team
    // Admins: Dashboard, Users, Settings

    final bool isCoordinator = role == 'Coordinator';
    final List<Map<String, dynamic>> menuItems = isCoordinator
        ? [
            {
              'title': 'Missions',
              'icon': Icons.assignment_outlined,
              'screen': const CreateMissionScreen(),
            },
            {
              'title': 'Verify',
              'icon': Icons.verified_user_outlined,
              'screen': const Center(child: Text('Verification Tool')),
            },
            {
              'title': 'Team',
              'icon': Icons.groups_outlined,
              'screen': const Center(child: Text('Team Management')),
            },
            {
              'title': 'Profile',
              'icon': Icons.person_outline,
              'screen': const ProfileScreen(),
            },
          ]
        : [
            {
              'title': 'Dashboard',
              'icon': Icons.dashboard_outlined,
              'screen': const Center(child: Text('Admin Dashboard')),
            },
            {
              'title': 'Users',
              'icon': Icons.people_outline,
              'screen': const Center(child: Text('User Management')),
            },
            {
              'title': 'Settings',
              'icon': Icons.settings_outlined,
              'screen': const Center(child: Text('App Settings')),
            },
            {
              'title': 'Profile',
              'icon': Icons.person_outline,
              'screen': const ProfileScreen(),
            },
          ];

    return Scaffold(
      appBar: AppBar(title: Text(menuItems[_selectedIndex]['title'])),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryBlue),
              accountName: Text(
                role,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                Provider.of<AuthProvider>(context, listen: false).user?.email ??
                    '',
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  role[0],
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ...List.generate(menuItems.length, (index) {
              return ListTile(
                leading: Icon(
                  menuItems[index]['icon'],
                  color: _selectedIndex == index ? AppTheme.primaryBlue : null,
                ),
                title: Text(
                  menuItems[index]['title'],
                  style: TextStyle(
                    color: _selectedIndex == index
                        ? AppTheme.primaryBlue
                        : null,
                    fontWeight: _selectedIndex == index
                        ? FontWeight.bold
                        : null,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
                selected: _selectedIndex == index,
              );
            }),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: menuItems[_selectedIndex]['screen'],
    );
  }
}
