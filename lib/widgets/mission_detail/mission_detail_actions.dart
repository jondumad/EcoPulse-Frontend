import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mission_model.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/atoms/eco_button.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../screens/volunteer/check_in_screen.dart';
import '../../screens/coordinator/qr_display.dart';
import '../../screens/coordinator/evaluation/volunteer_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Expandable Action Button
// ─────────────────────────────────────────────────────────────────────────────

/// A floating action button that shows only an icon on first tap, then expands
/// to show its label text and confirms the action on the second tap.
class MissionExpandableActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onConfirm;
  final EcoButtonVariant variant;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MissionExpandableActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onConfirm,
    this.variant = EcoButtonVariant.primary,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<MissionExpandableActionButton> createState() =>
      _MissionExpandableActionButtonState();
}

class _MissionExpandableActionButtonState
    extends State<MissionExpandableActionButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return EcoPulseButton(
      label: _isExpanded ? widget.label : '',
      icon: widget.icon,
      variant: widget.variant,
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

// ─────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the correct set of floating action buttons based on the user's role
/// and the current mission/registration state.
class MissionDetailActions extends StatelessWidget {
  final Mission mission;
  final String? userRole;
  final bool isFull;
  final bool isEnded;
  final bool isCheckedIn;
  final bool isCompleted;
  final bool isCheckingOut;
  final VoidCallback onCheckout;

  const MissionDetailActions({
    super.key,
    required this.mission,
    required this.userRole,
    required this.isFull,
    this.isEnded = false,
    required this.isCheckedIn,
    required this.isCompleted,
    required this.isCheckingOut,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    if (userRole == 'Coordinator' || userRole == 'SuperAdmin') {
      return _buildCoordinatorActions(context);
    }
    return _buildVolunteerActions(context);
  }

  Widget _buildCoordinatorActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MissionExpandableActionButton(
          label: isEnded ? 'Mission Ended' : 'Confirm Show QR',
          icon: isEnded ? Icons.lock : Icons.qr_code,
          variant: !isEnded ? EcoButtonVariant.primary : EcoButtonVariant.secondary,
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
        ),
        const SizedBox(height: 12),
        EcoPulseButton(
          label: 'Evaluate Volunteers',
          icon: Icons.rate_review_outlined,
          variant: EcoButtonVariant.secondary,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VolunteerListScreen(
                  missionId: mission.id,
                  missionTitle: mission.title,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVolunteerActions(BuildContext context) {
    if (isEnded) {
      return const MissionExpandableActionButton(
        label: 'Mission Ended',
        icon: Icons.lock_clock,
        variant: EcoButtonVariant.secondary,
      );
    }

    if (mission.registrationStatus == 'Invited') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MissionExpandableActionButton(
            label: 'Accept Invite',
            icon: Icons.check_circle_outline,
            backgroundColor: EcoColors.forest,
            foregroundColor: Colors.white,
            onConfirm: () async {
              final provider = Provider.of<MissionProvider>(
                context,
                listen: false,
              );
              try {
                await provider.toggleRegistration(mission.id, false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invitation accepted!'),
                      backgroundColor: EcoColors.forest,
                    ),
                  );
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
          const SizedBox(height: 12),
          MissionExpandableActionButton(
            label: 'Decline Invite',
            icon: Icons.cancel_outlined,
            variant: EcoButtonVariant.secondary,
            backgroundColor: EcoColors.terracotta,
            foregroundColor: Colors.white,
            onConfirm: () async {
              final provider = Provider.of<MissionProvider>(
                context,
                listen: false,
              );
              try {
                await provider.declineInvitation(mission.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invitation declined'),
                      backgroundColor: EcoColors.terracotta,
                    ),
                  );
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
      );
    }

    if (mission.isRegistered) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MissionExpandableActionButton(
            label: isCompleted
                ? 'Completed'
                : isCheckedIn
                ? 'Confirm Complete'
                : 'Confirm Check In',
            icon: isCompleted ? Icons.verified : Icons.check_circle_outline,
            isLoading: isCheckedIn && isCheckingOut,
            onConfirm: isCompleted
                ? null
                : isCheckedIn
                ? onCheckout
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
          if (!isCompleted && !isCheckedIn) ...[
            const SizedBox(height: 12),
            MissionExpandableActionButton(
              label: 'Confirm Cancel',
              icon: Icons.close_rounded,
              variant: EcoButtonVariant.secondary,
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
              onConfirm: () async {
                final missionProvider = Provider.of<MissionProvider>(
                  context,
                  listen: false,
                );
                try {
                  await missionProvider.toggleRegistration(mission.id, true);
                  if (context.mounted) Navigator.pop(context);
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
          EcoPulseButton(
            label: '',
            icon: Icons.map_outlined,
            variant: EcoButtonVariant.secondary,
            onPressed: () async {
              if (mission.locationGps != null &&
                  mission.locationGps!.contains(',')) {
                final coords = mission.locationGps!.split(',');
                final uri = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${coords[0].trim()},${coords[1].trim()}',
                );
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              }
            },
          ),
        ],
      );
    }

    return Consumer<MissionProvider>(
      builder: (context, provider, _) {
        final bool isWaitlisted = mission.registrationStatus == 'Waitlisted';
        if (isWaitlisted) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MissionExpandableActionButton(
                label: 'On Waitlist',
                icon: Icons.hourglass_empty,
                variant: EcoButtonVariant.secondary,
                backgroundColor: AppTheme.violet,
                foregroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              MissionExpandableActionButton(
                label: 'Confirm Leave Waitlist',
                icon: Icons.close_rounded,
                variant: EcoButtonVariant.secondary,
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                onConfirm: () async {
                  try {
                    await provider.toggleRegistration(mission.id, true);
                    if (context.mounted) {
                      await provider.fetchMissions();
                      if (context.mounted) Navigator.pop(context);
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

        return MissionExpandableActionButton(
          label: isFull ? 'Join Waitlist' : 'Confirm Register',
          icon: isFull ? Icons.queue : Icons.add_task,
          isLoading: provider.isLoading,
          backgroundColor: isFull ? AppTheme.violet : null,
          onConfirm: () async {
            try {
              await provider.toggleRegistration(mission.id, false);
              if (context.mounted) {
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
