import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../components/grain_overlay.dart';
import '../../widgets/eco_app_bar.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clay,
      appBar: EcoAppBar(
        height: 60,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Badges',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: GrainOverlay()),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildRefinedStatsRow(context),
                      const SizedBox(height: 40),
                      Text(
                        'MILESTONE BADGES',
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(
                              letterSpacing: 2,
                              color: AppTheme.ink.withValues(alpha: 0.4),
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumBadgeGrid(context),
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

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.forest, Color(0xFF153827)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level 12',
                    style: AppTheme.lightTheme.textTheme.displayMedium
                        ?.copyWith(color: Colors.white, fontSize: 32),
                  ),
                  Text(
                    'FOREST GUARDIAN',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 3,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next: Level 13',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '2,450 / 3,100 XP',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.79,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.violet, Color(0xFFA370FF)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.violet.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildRefinedStatItem(
            'POINTS',
            '1,240',
            Icons.stars_rounded,
            AppTheme.terracotta,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRefinedStatItem(
            'STREAK',
            '12 Days',
            Icons.local_fire_department_rounded,
            const Color(0xFFF39C12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRefinedStatItem(
            'MISSIONS',
            '24',
            Icons.task_alt_rounded,
            AppTheme.forest,
          ),
        ),
      ],
    );
  }

  Widget _buildRefinedStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadgeGrid(BuildContext context) {
    final badges = [
      {
        'name': 'First Plant',
        'icon': Icons.eco,
        'unlocked': true,
        'desc': 'Planted your first tree',
      },
      {
        'name': 'Eco Warrior',
        'icon': Icons.shield,
        'unlocked': true,
        'desc': 'Completed 10 missions',
      },
      {
        'name': 'Local Hero',
        'icon': Icons.location_on,
        'unlocked': true,
        'desc': 'Participated in 5 local events',
      },
      {
        'name': 'Water Saver',
        'icon': Icons.water_drop,
        'unlocked': false,
        'desc': 'Lead a river cleanup',
      },
      {
        'name': 'Recycle King',
        'icon': Icons.recycling,
        'unlocked': false,
        'desc': 'Sorted 50kg of waste',
      },
      {
        'name': 'Team Leader',
        'icon': Icons.groups,
        'unlocked': false,
        'desc': 'Lead a mission group',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final bool unlocked = badge['unlocked'] as bool;

        return GestureDetector(
          onTap: () => _showEnhancedBadgeDetail(context, badge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: unlocked
                          ? AppTheme.violet.withValues(alpha: 0.1)
                          : AppTheme.paperShadow,
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? AppTheme.violet.withValues(alpha: 0.08)
                            : AppTheme.clay,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Opacity(
                      opacity: unlocked ? 1.0 : 0.2,
                      child: Icon(
                        badge['icon'] as IconData,
                        size: 32,
                        color: unlocked ? AppTheme.violet : AppTheme.ink,
                      ),
                    ),
                    if (unlocked)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.forest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (badge['name'] as String).toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: unlocked
                      ? AppTheme.ink
                      : AppTheme.ink.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEnhancedBadgeDetail(
    BuildContext context,
    Map<String, dynamic> badge,
  ) {
    final unlocked = badge['unlocked'] as bool;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppTheme.violet.withValues(alpha: 0.1)
                    : AppTheme.clay,
                shape: BoxShape.circle,
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: AppTheme.violet.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                badge['icon'] as IconData,
                size: 50,
                color: unlocked
                    ? AppTheme.violet
                    : AppTheme.ink.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              badge['name'] as String,
              style: AppTheme.lightTheme.textTheme.displayMedium,
            ),
            const SizedBox(height: 12),
            Text(
              badge['desc'] as String,
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            if (!unlocked)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.clay,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppTheme.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keep participating in missions to unlock this badge!',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: unlocked ? AppTheme.forest : AppTheme.ink,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text(unlocked ? 'AWESOME' : 'I\'LL WORK ON IT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
