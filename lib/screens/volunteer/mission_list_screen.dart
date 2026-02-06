import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mission_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/mission_card.dart';
import '../../widgets/mission_filter_widgets.dart';
import '../../widgets/eco_pulse_widgets.dart'; // For EcoColors if needed, though used via AppTheme mostly

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
    Future.microtask(() {
      if (!mounted) return;
      final provider = Provider.of<MissionProvider>(context, listen: false);
      provider.fetchMissions();
      provider.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              MissionSearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  _onFilterChanged();
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                  _onFilterChanged();
                },
              ),

              const SizedBox(height: 16),

              // Category Filter Chips
              const EcoSectionHeader(title: 'FILTER BY CATEGORY'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Consumer<MissionProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      children: [
                        EcoFilterChip(
                          label: 'All',
                          isSelected: _selectedCategory == null,
                          onTap: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            _onFilterChanged();
                          },
                          color: AppTheme.forest,
                        ),
                        ...provider.categories.map(
                          (category) => EcoFilterChip(
                            label: category.name,
                            isSelected: _selectedCategory == category.name,
                            onTap: () {
                              setState(() {
                                _selectedCategory =
                                    _selectedCategory == category.name
                                    ? null
                                    : category.name;
                              });
                              _onFilterChanged();
                            },
                            color: AppTheme.forest,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'In Progress',
                    style: AppTheme.lightTheme.textTheme.displaySmall,
                  ),
                  Consumer<MissionProvider>(
                    builder: (context, provider, _) {
                      final activeCount = provider.missions
                          .where((m) => m.isRegistered)
                          .length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(0, 0, 0, 0.06),
                          ),
                        ),
                        child: Text(
                          '$activeCount active',
                          style: AppTheme.lightTheme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Mission List
              Consumer<MissionProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(child: Text('Error: ${provider.error}'));
                  }

                  if (provider.missions.isEmpty) {
                    return const Center(child: Text('No missions found.'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.missions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MissionCard(mission: provider.missions[index]),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 100), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }
}
