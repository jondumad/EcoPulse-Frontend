import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mission_provider.dart';
import '../../models/mission_model.dart';
import '../../theme/app_theme.dart';
import '../../components/paper_card.dart';
import '../../components/eco_pulse_buttons.dart';
import 'mission_detail_screen.dart';
import 'mission_map.dart';

class MissionListScreen extends StatefulWidget {
  final VoidCallback? onToggleView;
  const MissionListScreen({super.key, this.onToggleView});

  @override
  State<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends State<MissionListScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
    });
  }

  void _onFilterChanged() {
    Provider.of<MissionProvider>(context, listen: false).fetchMissions(
      category: _selectedCategory,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.clay,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.now()).toUpperCase(),
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.5),
                            ),
                      ),
                      const Spacer(),
                      // Maybe Avatar here if we had access to user provider easily without passing it down
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Field Operations',
                    style: AppTheme.lightTheme.textTheme.displayMedium,
                  ),
                ],
              ),
            ),

            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                    keyboardAppearance: Brightness.light,
                    decoration: const InputDecoration(
                      hintText: 'Search field logs...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.ink),
                      fillColor: AppTheme.clay,
                    ),
                    onSubmitted: (_) => _onFilterChanged(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        if (widget.onToggleView != null) {
                          widget.onToggleView!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MissionMap(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('View on Map'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.ink,
                        textStyle: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(null, 'ALL'),
                        _buildCategoryChip('Environmental', 'ECO'),
                        _buildCategoryChip('Social', 'SOCIAL'),
                        _buildCategoryChip('Educational', 'EDU'),
                        _buildCategoryChip('Health', 'HEALTH'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mission List
            Expanded(
              child: Consumer<MissionProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppTheme.terracotta,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sync Error: ${provider.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            EcoPulseButton(
                              label: 'Retry Sync',
                              onPressed: () => _onFilterChanged(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.missions.isEmpty) {
                    return Center(
                      child: Text(
                        'No active field logs found.',
                        style: AppTheme.lightTheme.textTheme.bodyLarge
                            ?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.5),
                            ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: provider.missions.length,
                    itemBuilder: (context, index) {
                      final mission = provider.missions[index];
                      return _MissionCard(mission: mission);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : category;
        });
        _onFilterChanged();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ink : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.ink
                : AppTheme.ink.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.ink,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontFamily: 'JetBrains Mono', // Direct font usage
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MissionDetailScreen(mission: mission),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
                    fontSize: 20,
                  ), // Slightly smaller for list
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (mission.isEmergency)
                Transform.rotate(
                  angle: 0.05,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      'URGENT',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.ink,
              ),
              const SizedBox(width: 4),
              Text(
                mission.locationName,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.ink,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, HH:mm').format(mission.startTime),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ...mission.categories
                  .take(2)
                  .map((cat) => _CategoryTag(category: cat)),
              const Spacer(),
              Text(
                '+${mission.pointsValue} PTS',
                style:
                    AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'JetBrains Mono',
                    ) ??
                    const TextStyle(
                      color: AppTheme.forest,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: mission.maxVolunteers != null
                  ? mission.currentVolunteers / mission.maxVolunteers!
                  : 0.1, // Show a bit if null
              backgroundColor: AppTheme.ink.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                mission.isEmergency ? AppTheme.terracotta : AppTheme.forest,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final Category category;

  const _CategoryTag({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.1)),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.ink,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }
}
