import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/eco_pulse_widgets.dart';
import 'mission_map.dart';
import '../../components/mission_card.dart';

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
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<MissionProvider>(context, listen: false).fetchMissions();
    });
  }

  void _onFilterChanged() {
    Provider.of<MissionProvider>(context, listen: false).fetchMissions(
      category: _selectedCategory,
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.clay,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FIELD LOGS',
                        style: AppTheme.lightTheme.textTheme.labelMedium
                            ?.copyWith(
                              fontFamily: 'JetBrains Mono',
                              letterSpacing: 2,
                            ),
                      ),
                      TextButton.icon(
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
                        label: const Text('VIEW ON MAP'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.forest,
                          textStyle: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: AppTheme.ink.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search missions...',
                        hintStyle: TextStyle(
                          color: AppTheme.ink.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _onFilterChanged(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(null, 'ALL'),
                        _buildCategoryChip('Environment', 'ECO'),
                        _buildCategoryChip('Social', 'SOCIAL'),
                        _buildCategoryChip('Infrastructure', 'INFRA'),
                        _buildCategoryChip('Education', 'EDU'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                      return MissionCard(mission: mission);
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
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }
}
