import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/mission_provider.dart';

import '../../models/mission_model.dart';
import '../../providers/auth_provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'check_in_screen.dart';
import '../coordinator/qr_display.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  late AnimationController _tiltController;

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _tiltController.dispose();
    super.dispose();
  }

  String _getCategoryIcon(Mission mission, String categoryName) {
    if (mission.categories.isNotEmpty) {
      final category = mission.categories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => mission.categories.first,
      );
      return category.icon;
    }
    return '📋';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final missionProvider = context.watch<MissionProvider>();

    // Try to get the latest mission data from the provider to ensure reactive updates
    final currentMission = missionProvider.missions.firstWhere(
      (m) => m.id == widget.mission.id,
      orElse: () => widget.mission,
    );

    final isFull =
        currentMission.maxVolunteers != null &&
        currentMission.currentVolunteers >= currentMission.maxVolunteers!;

    final isEnded = currentMission.endTime.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: Stack(
        children: [
          SafeArea(
            child: Stack(
              children: [
                // Scrollable Content
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 80, 16, 60),
                            child: Column(
                              children: [
                                if (isEnded) ...[
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.ink,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'This mission has ended. Actions are no longer available.',
                                            style: AppTheme
                                                .lightTheme
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else
                                  const SizedBox(height: 0),
                                _MissionCard(
                                  mission: currentMission,
                                  isDescriptionExpanded: _isDescriptionExpanded,
                                  onDescriptionToggle: () {
                                    setState(() {
                                      _isDescriptionExpanded =
                                          !_isDescriptionExpanded;
                                    });
                                  },
                                  categoryIcon: _getCategoryIcon(
                                    currentMission,
                                    currentMission.categories.isNotEmpty
                                        ? currentMission.categories.first.name
                                        : '',
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: _ActionButtons(
                              mission: currentMission,
                              userRole: user?.role,
                              isFull: isFull,
                              isEnded: isEnded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      _TopButton(
                        icon: Icons.share,
                        onPressed: () => _shareMission(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareMission(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Text('📤'),
            SizedBox(width: 12),
            Text('Share link copied!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.forest,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Top Button Widget
class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TopButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return EcoPulseButton(
      label: '',
      icon: icon,
      isPrimary: false,
      isSmall: true,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }
}

// Main Mission Card
class _MissionCard extends StatelessWidget {
  final Mission mission;
  final bool isDescriptionExpanded;
  final VoidCallback onDescriptionToggle;
  final String categoryIcon;

  const _MissionCard({
    required this.mission,
    required this.isDescriptionExpanded,
    required this.onDescriptionToggle,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmergency =
        mission.isEmergency ||
        mission.priority == 'Critical' ||
        mission.priority == 'High';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.06)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                offset: Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: [
              // Hero Section
              _HeroSection(icon: categoryIcon, title: mission.title),

              // Quick Stats Grid
              _QuickStatsGrid(mission: mission),

              // Info Items
              _InfoSection(mission: mission),

              // Map Quick View
              _MapQuickView(gps: mission.locationGps),

              // Description
              _ExpandableDescription(
                description: mission.description,
                isExpanded: isDescriptionExpanded,
                onToggle: onDescriptionToggle,
              ),
            ],
          ),
        ),

        // Emergency Indicator
        if (isEmergency)
          Positioned(
            left: 0,
            top: 40,
            bottom: 40,
            width: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.terracotta,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
              ),
            ),
          ),

        // Registered Status Stamp
        if (mission.isRegistered)
          Positioned(
            top: -20, // Slightly more offset for better "stamp" look
            right: -8,
            child: _StatusStamp(
              status: mission.registrationStatus ?? 'Registered',
            ),
          ),
      ],
    );
  }
}

// Hero Section
class _HeroSection extends StatelessWidget {
  final String icon;
  final String title;

  const _HeroSection({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.forest, Color(0xFF153827)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Status Stamp
class _StatusStamp extends StatelessWidget {
  final String status;
  const _StatusStamp({required this.status});

  @override
  Widget build(BuildContext context) {
    Color stampColor = AppTheme.forest;
    String displayStatus = 'REGIS-\nTERED';

    if (status == 'Waitlisted') {
      stampColor = AppTheme.violet;
      displayStatus = 'WAIT-\nLISTED';
    } else if (status == 'CheckedIn') {
      stampColor = AppTheme.violet;
      displayStatus = 'CHECKED\nIN';
    } else if (status == 'Completed') {
      stampColor = Colors.orange;
      displayStatus = 'COMPLE-\nTED';
    }

    return Transform.rotate(
      angle: 0.2,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: stampColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// Action Buttons
class _ExpandableActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onConfirm;
  final bool isPrimary;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const _ExpandableActionButton({
    required this.icon,
    required this.label,
    this.onConfirm,
    this.isPrimary = true,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<_ExpandableActionButton> createState() =>
      _ExpandableActionButtonState();
}

class _ExpandableActionButtonState extends State<_ExpandableActionButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return EcoPulseButton(
      label: _isExpanded ? widget.label : '',
      icon: widget.icon,
      isPrimary: widget.isPrimary,
      isLoading: widget.isLoading,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      onPressed: () {
        if (_isExpanded) {
          if (widget.onConfirm != null) {
            widget.onConfirm!();
          }
          setState(() => _isExpanded = false);
        } else {
          setState(() => _isExpanded = true);
        }
      },
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Mission mission;
  final String? userRole;
  final bool isFull;
  final bool isEnded;

  const _ActionButtons({
    required this.mission,
    required this.userRole,
    required this.isFull,
    this.isEnded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (userRole == 'Coordinator') {
      return _ExpandableActionButton(
        label: isEnded ? 'Mission Ended' : 'Confirm Show QR',
        icon: isEnded ? Icons.lock : Icons.qr_code,
        isPrimary: !isEnded,
        onConfirm: isEnded
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRDisplayScreen(
                      missionId: mission.id,
                      missionTitle: mission.title,
                      activeUntil: mission.endTime,
                    ),
                  ),
                );
              },
      );
    }

    if (userRole == 'Volunteer') {
      if (isEnded) {
        return _ExpandableActionButton(
          label: 'Mission Ended',
          icon: Icons.lock_clock,
          isPrimary: false,
          onConfirm: null, // Disabled
        );
      }

      if (mission.registrationStatus == 'Invited') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ExpandableActionButton(
              label: 'Accept Invite',
              icon: Icons.check_circle_outline,
              backgroundColor: EcoColors.forest,
              foregroundColor: Colors.white,
              onConfirm: () async {
                final provider = Provider.of<MissionProvider>(context, listen: false);
                try {
                  await provider.toggleRegistration(mission.id, false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitation accepted!'), backgroundColor: EcoColors.forest),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _ExpandableActionButton(
              label: 'Decline Invite',
              icon: Icons.cancel_outlined,
              isPrimary: false,
              backgroundColor: EcoColors.terracotta,
              foregroundColor: Colors.white,
              onConfirm: () async {
                final provider = Provider.of<MissionProvider>(context, listen: false);
                try {
                  await provider.declineInvitation(mission.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitation declined'), backgroundColor: EcoColors.terracotta),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
          ],
        );
      }

      if (mission.isRegistered) {
        final bool isCompleted = mission.registrationStatus == 'Completed';
        final bool isCheckedIn = mission.registrationStatus == 'CheckedIn';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Check In / Status Button
            _ExpandableActionButton(
              label: isCompleted
                  ? 'Completed'
                  : isCheckedIn
                  ? 'Checked In'
                  : 'Confirm Check In',
              icon: isCompleted ? Icons.verified : Icons.check_circle_outline,
              onConfirm: (isCompleted || isCheckedIn)
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckInScreen(
                            missionId: mission.id,
                            missionTitle: mission.title,
                            missionGps: mission.locationGps ?? '',
                          ),
                        ),
                      );
                    },
            ),
            // Cancel Button
            if (!isCompleted && !isCheckedIn) ...[
              const SizedBox(height: 12),
              _ExpandableActionButton(
                label: 'Confirm Cancel',
                icon: Icons.close_rounded,
                isPrimary: false,
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                onConfirm: () async {
                  final missionProvider = Provider.of<MissionProvider>(
                    context,
                    listen: false,
                  );
                  
                  try {
                    await missionProvider.toggleRegistration(
                      mission.id,
                      true,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],

            const SizedBox(height: 12),

            // Map Button (Icon Only)
            EcoPulseButton(
              label: '',
              icon: Icons.map_outlined,
              isPrimary: false,
              onPressed: () async {
                if (mission.locationGps != null &&
                    mission.locationGps!.contains(',')) {
                  final coords = mission.locationGps!.split(',');
                  final lat = coords[0].trim();
                  final lng = coords[1].trim();
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
            ),
          ],
        );
      } else {
        // Not registered - show register or join waitlist button
        return Consumer<MissionProvider>(
          builder: (context, provider, _) {
            final bool isWaitlisted =
                mission.registrationStatus == 'Waitlisted';

            if (isWaitlisted) {
              // User is on waitlist
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ExpandableActionButton(
                    label: 'On Waitlist',
                    icon: Icons.hourglass_empty,
                    isPrimary: false,
                    backgroundColor: AppTheme.violet,
                    foregroundColor: Colors.white,
                    onConfirm: null, // Just shows status
                  ),
                  const SizedBox(height: 12),
                  _ExpandableActionButton(
                    label: 'Confirm Leave Waitlist',
                    icon: Icons.close_rounded,
                    isPrimary: false,
                    backgroundColor: AppTheme.terracotta,
                    foregroundColor: Colors.white,
                    onConfirm: () async {
                      try {
                        await provider.toggleRegistration(mission.id, true);
                        if (context.mounted) {
                          await provider.fetchMissions();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  ),
                ],
              );
            }

            return _ExpandableActionButton(
              label: isFull ? 'Join Waitlist' : 'Confirm Register',
              icon: isFull ? Icons.queue : Icons.add_task,
              isLoading: provider.isLoading,
              backgroundColor: isFull ? AppTheme.violet : null,
              onConfirm: () async {
                try {
                  await provider.toggleRegistration(mission.id, false);
                  if (context.mounted) {
                    // Refresh missions to get updated data
                    await provider.fetchMissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFull
                                ? 'Added to waitlist!'
                                : 'Successfully registered!',
                          ),
                        ),
                      );
                      // Pop back to refresh the screen with updated data
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            );
          },
        );
      }
    }

    return const SizedBox.shrink();
  }
}

// Quick Stats Grid
class _QuickStatsGrid extends StatelessWidget {
  final Mission mission;

  const _QuickStatsGrid({required this.mission});

  @override
  Widget build(BuildContext context) {
    final duration = mission.endTime.toLocal().difference(
      mission.startTime.toLocal(),
    );
    final hours = duration.inHours;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('POINTS', '${mission.pointsValue}', Icons.star_border),
          _buildStatItem('DURATION', '$hours hrs', Icons.access_time),
          _buildStatItem(
            'SPOTS',
            '${mission.maxVolunteers != null ? mission.maxVolunteers! - mission.currentVolunteers : "Open"}',
            Icons.people_outline,
          ),
          _buildStatItem('PRIORITY', mission.priority, Icons.flag_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.forest, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.ink.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// Info Section
class _InfoSection extends StatelessWidget {
  final Mission mission;

  const _InfoSection({required this.mission});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today_outlined,
            dateFormat.format(mission.startTime.toLocal()),
            '${timeFormat.format(mission.startTime.toLocal())} - ${timeFormat.format(mission.endTime.toLocal())}',
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.location_on_outlined,
            mission.locationName,
            'Check map for exact location',
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.person_outline,
            mission.creatorName ?? 'EcoPulse Team',
            'Organizer',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.clay,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.forest, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Expandable Description
class _ExpandableDescription extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableDescription({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Simple heuristic for truncation: ~150 characters or multiple newlines
    final bool isLong =
        description.length > 150 || description.contains('\n\n');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.clay,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppTheme.forest,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About the Mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.ink.withValues(alpha: 0.8),
            ),
          ),
          if (isLong)
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                foregroundColor: AppTheme.forest,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isExpanded ? 'Read Less' : 'Read More'),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Map Quick View
class _MapQuickView extends StatelessWidget {
  final String? gps;

  const _MapQuickView({this.gps});

  @override
  Widget build(BuildContext context) {
    if (gps == null || !gps!.contains(',')) return const SizedBox.shrink();

    final coords = gps!.split(',');
    final lat = double.tryParse(coords[0].trim()) ?? 0;
    final lng = double.tryParse(coords[1].trim()) ?? 0;

    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: ll.LatLng(lat, lng),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecopulse.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: ll.LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
