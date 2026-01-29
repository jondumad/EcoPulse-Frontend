import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../widgets/eco_pulse_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return EcoPulseLayout(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: EcoColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Date & Greeting)
                Text(
                  DateFormat('MMM dd, yyyy').format(now).toUpperCase(),
                  style: EcoText.monoSM(context),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Hello,\n${user.name.split(' ').first}',
                        style: EcoText.displayLG(context),
                      ),
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: EcoColors.forest,
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Hero Card (Profile & Role)
                EcoPulseCard(
                  variant: CardVariant.hero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.fingerprint, color: Colors.white54),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Volunteer Stats & Gamification
                if (user.role == 'Volunteer') ...[
                  Text('Field Statistics', style: EcoText.displayMD(context)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: EcoPulseCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL POINTS',
                                style: EcoText.monoSM(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${user.totalPoints}',
                                style: EcoText.displayMD(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: EcoPulseCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RANK', style: EcoText.monoSM(context)),
                              const SizedBox(height: 8),
                              Text(
                                _calculateLevel(user.totalPoints),
                                style: EcoText.displayMD(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress
                  EcoPulseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NEXT MILESTONE',
                              style: EcoText.monoSM(context),
                            ),
                            Text(
                              '${user.totalPoints} / 1000',
                              style: EcoText.monoSM(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: user.totalPoints / 1000,
                            minHeight: 8,
                            backgroundColor: EcoColors.clay,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              EcoColors.forest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Earn ${1000 - user.totalPoints} more points to reach Community Hero status.',
                          style: EcoText.bodyMD(context).copyWith(
                            color: EcoColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _calculateLevel(int points) {
    if (points < 100) return 'Newbie';
    if (points < 500) return 'Active';
    if (points < 1000) return 'Hero';
    return 'Legend';
  }
}
