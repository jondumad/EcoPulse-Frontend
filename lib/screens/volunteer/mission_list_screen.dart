import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mission_provider.dart';
import '../../models/mission_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'mission_detail_screen.dart';

class MissionListScreen extends StatefulWidget {
  const MissionListScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Missions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _onFilterChanged(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search missions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onFilterChanged();
                      },
                    ),
                  ),
                  onSubmitted: (_) => _onFilterChanged(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(null, 'All'),
                      _buildCategoryChip('Environmental', '🌱 Eco'),
                      _buildCategoryChip('Social', '🤝 Social'),
                      _buildCategoryChip('Educational', '📚 Education'),
                      _buildCategoryChip('Health', '❤️ Health'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mission List
          Expanded(
            child: Consumer<MissionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.error}'),
                        const SizedBox(height: 16),
                        EcoPulseButton(
                          label: 'Retry',
                          onPressed: () => _onFilterChanged(),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.missions.isEmpty) {
                  return const Center(
                    child: Text('No missions found for these filters.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _onFilterChanged();
        },
        selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    return EcoPulseCard(
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
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (mission.isEmergency)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.textGrey,
              ),
              const SizedBox(width: 4),
              Text(
                mission.locationName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.textGrey,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, HH:mm').format(mission.startTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...mission.categories
                  .take(2)
                  .map((cat) => _CategoryTag(category: cat)),
              const Spacer(),
              Text(
                '+${mission.pointsValue} pts',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: mission.maxVolunteers != null
                ? mission.currentVolunteers / mission.maxVolunteers!
                : 1.0,
            backgroundColor: AppTheme.textMedium.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              mission.isEmergency ? Colors.redAccent : AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mission.currentVolunteers}${mission.maxVolunteers != null ? "/${mission.maxVolunteers}" : ""} joined',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
              if (mission.isRegistered)
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppTheme.primaryGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Registered',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
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
    final Color color = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            category.name,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
