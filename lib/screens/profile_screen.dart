import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import './volunteer/mission_history_screen.dart';
import './volunteer/my_evaluations_screen.dart';
import 'volunteer/badges_modal.dart';

import '../models/mission_model.dart';
import '../models/user_model.dart';
import '../providers/mission_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final missionProvider = Provider.of<MissionProvider>(context);
    final user = auth.user;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildProfileHeader(user),
            const SizedBox(height: 32),
            _buildImpactStats(auth),
            const SizedBox(height: 32),
            _buildNavigationGrid(context, missionProvider.missions),
            const SizedBox(height: 32),
            _buildSettingsList(context),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.violet, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                foregroundImage: NetworkImage(
                  'https://api.dicebear.com/7.x/avataaars/png?seed=${user.name}',
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.forest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
          ),
        ),
        Text(
          user.email,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.ink.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.violet.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.role.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.violet,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactStats(AuthProvider auth) {
    final stats = auth.userStats;
    final points = auth.user?.totalPoints ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Points',
            value: points.toString(),
            icon: Icons.bolt_rounded,
            color: AppTheme.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatTile(
            label: 'Missions',
            value: (stats?['actionsCompleted'] ?? 0).toString(),
            icon: Icons.task_alt_rounded,
            color: AppTheme.forest,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationGrid(BuildContext context, List<Mission> missions) {
    return Column(
      children: [
        _buildNavCard(
          context,
          title: 'My Impact Profile',
          subtitle: 'View performance ratings and feedback.',
          icon: Icons.radar_rounded,
          color: AppTheme.violet,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyEvaluationsScreen()),
          ),
        ),
        const SizedBox(height: 16),
        _buildNavCard(
          context,
          title: 'Mission History',
          subtitle: 'Timeline of your past contributions.',
          icon: Icons.history_rounded,
          color: AppTheme.forest,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MissionHistoryScreen(missions: missions)),
          ),
        ),
        const SizedBox(height: 16),
        _buildNavCard(
          context,
          title: 'Achievement Badges',
          subtitle: 'Unlock rewards for your milestones.',
          icon: Icons.emoji_events_rounded,
          color: AppTheme.amber,
          onTap: () => BadgesModal.show(context),
        ),
      ],
    );
  }

  Widget _buildNavCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.ink.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'PREFERENCES',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
        ),
        _SettingsTile(
          label: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
        _SettingsTile(
          label: 'Privacy & Security',
          icon: Icons.shield_outlined,
          onTap: () {},
        ),
        _SettingsTile(
          label: 'Help & Support',
          icon: Icons.help_outline_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.inkSecondary),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.ink.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
