import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../models/mission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/eco_pulse_buttons.dart';
import '../../components/paper_card.dart';
import '../../components/grain_overlay.dart';
import 'check_in_screen.dart';
import '../coordinator/qr_display.dart';

class MissionDetailScreen extends StatelessWidget {
  final Mission mission;

  const MissionDetailScreen({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),

          CustomScrollView(
            slivers: [
              // Header with Image/Color block
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.clay,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppTheme.forest, // Fallback color
                      ),
                      Center(
                        child: Opacity(
                          opacity: 0.1,
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: List.generate(
                              20,
                              (index) => Icon(
                                mission.categories.isNotEmpty
                                    ? _getIconForCategory(
                                        mission.categories.first.name,
                                      )
                                    : Icons.volunteer_activism,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            mission.categories.isNotEmpty
                                ? _getIconForCategory(
                                    mission.categories.first.name,
                                  )
                                : Icons.volunteer_activism,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Gradient Overlay for text readability if needed
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title and Tags
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            mission.title,
                            style: AppTheme
                                .lightTheme
                                .textTheme
                                .displayMedium, // Fraunces 32
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.forest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+${mission.pointsValue}',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: mission.categories
                          .map((cat) => _CategoryTag(category: cat))
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    // Key Info Card - Paper Style
                    PaperCard(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            title: 'Date & Time',
                            subtitle: DateFormat(
                              'EEEE, MMM dd • HH:mm',
                            ).format(mission.startTime),
                          ),
                          const Divider(
                            height: 32,
                            color: AppTheme.borderSubtle,
                          ),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            subtitle: mission.locationName,
                          ),
                          const Divider(
                            height: 32,
                            color: AppTheme.borderSubtle,
                          ),
                          _InfoRow(
                            icon: Icons.people_outline,
                            title: 'Availability',
                            subtitle:
                                '${mission.currentVolunteers} / ${mission.maxVolunteers ?? "∞"} spots filled',
                          ),
                          const SizedBox(height: 24),
                          if (mission.locationGps != null &&
                              mission.locationGps!.contains(','))
                            _StaticMapPreview(gps: mission.locationGps!),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Description',
                      style: AppTheme
                          .lightTheme
                          .textTheme
                          .displaySmall, // Fraunces 22
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mission.description,
                      style:
                          AppTheme.lightTheme.textTheme.bodyLarge, // Inter 14
                    ),

                    const SizedBox(height: 32),

                    if (user?.role == 'Coordinator' ||
                        user?.role == 'SuperAdmin')
                      EcoPulseButton(
                        label: 'Show QR Code',
                        icon: Icons.qr_code,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QRDisplayScreen(
                                missionId: mission.id,
                                missionTitle: mission.title,
                              ),
                            ),
                          );
                        },
                      ),

                    if (user?.role == 'Volunteer' && mission.isRegistered) ...[
                      const SizedBox(height: 12),
                      EcoPulseButton(
                        label: 'Check In',
                        icon: Icons.login,
                        onPressed: () {
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
                    ],

                    const SizedBox(height: 120), // Space for bottom button/nav
                  ]),
                ),
              ),
            ],
          ),

          // Floating Action Button for Registration (Bottom Center or Custom)
          // Design guide implies sticky bottom actions are common.
        ],
      ),
      bottomSheet: Consumer<MissionProvider>(
        builder: (context, provider, _) {
          final isFull =
              mission.maxVolunteers != null &&
              mission.currentVolunteers >= mission.maxVolunteers!;

          if (user?.role != 'Volunteer') return const SizedBox.shrink();

          // Check styling for bottom sheet
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.paperShadow,
                  blurRadius: 0,
                  offset: Offset(0, -4),
                ),
              ],
              border: const Border(
                top: BorderSide(color: AppTheme.borderSubtle),
              ),
            ),
            child: SafeArea(
              child: EcoPulseButton(
                label: mission.isRegistered
                    ? 'Cancel Registration'
                    : (isFull ? 'Mission Full' : 'Register Now'),
                isSecondary: mission.isRegistered, // Use secondary for cancel
                isLoading:
                    false, // Provider doesn't expose loading state easily here?
                onPressed: isFull && !mission.isRegistered
                    ? null // Disabled
                    : () async {
                        try {
                          await provider.toggleRegistration(
                            mission.id,
                            mission.isRegistered,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  mission.isRegistered
                                      ? 'Registration cancelled'
                                      : 'Successfully registered!',
                                ),
                                backgroundColor: AppTheme.forest,
                              ),
                            );
                            Navigator.pop(context); // Go back to list
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.terracotta,
                              ),
                            );
                          }
                        }
                      },
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name) {
      case 'Environmental':
        return Icons.eco;
      case 'Social':
        return Icons.people;
      case 'Educational':
        return Icons.school;
      case 'Health':
        return Icons.medical_services;
      default:
        return Icons.volunteer_activism;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.clay, // Use wash color
            borderRadius: BorderRadius.circular(8),
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
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.ink.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final Category category;

  const _CategoryTag({required this.category});

  @override
  Widget build(BuildContext context) {
    // We can use the category color or override with theme
    return Transform.rotate(
      angle: -0.05, // Slight rotation for "stuck on" feel
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.terracotta, // Use terracotta for tags as per guide
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              offset: Offset(2, 2),
              blurRadius: 5,
            ),
          ],
          // border: Border.all(color: Colors.white, width: 2), // Sticker border?
        ),
        child: Text(
          category.name.toUpperCase(),
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StaticMapPreview extends StatelessWidget {
  final String gps;

  const _StaticMapPreview({required this.gps});

  ll.LatLng? _parseGps() {
    try {
      final parts = gps.split(',');
      if (parts.length != 2) return null;
      return ll.LatLng(
        double.parse(parts[0].trim()),
        double.parse(parts[1].trim()),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _parseGps();
    if (center == null) return const SizedBox.shrink();

    return Container(
      height: 150,
      margin: const EdgeInsets.only(top: 16, bottom: 0),
      decoration: BoxDecoration(
        color: AppTheme.clay,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            // Sepia/Desaturated matrix
            0.393, 0.769, 0.189, 0, 0,
            0.349, 0.686, 0.168, 0, 0,
            0.272, 0.534, 0.131, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.civic',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.black, // Dark contrast for sepia
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
